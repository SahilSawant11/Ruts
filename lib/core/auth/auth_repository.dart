import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';

import '../local/app_database.dart';
import '../local/db_paths.dart';
import '../logging/app_logger.dart';
import '../network/api_exception.dart';
import 'app_user.dart';
import 'password_hasher.dart';

/// Local user accounts backed by the `app_users` table.
///
/// The session file stores only the user id; role and status are always
/// re-read from the database, so editing the file can't grant a higher role.
class AuthRepository {
  AuthRepository(this._db);

  final AppDatabase _db;

  static const minPasswordLength = 6;
  static const _maxFailures = 5;
  static const _lockout = Duration(seconds: 30);

  int _failures = 0;
  DateTime? _lockedUntil;

  /// Creates the three default accounts on a fresh install. Same logins
  /// as before, but each must set a new password on first sign-in.
  Future<void> ensureDefaultUsers() async {
    final existing = await (_db.selectOnly(_db.appUsers)..addColumns([_db.appUsers.id.count()])).getSingle();
    if ((existing.read(_db.appUsers.id.count()) ?? 0) > 0) return;

    const defaults = [
      ('owner', 'owner123', 'Store Owner', UserRole.owner),
      ('admin', 'admin123', 'Admin User', UserRole.manager),
      ('cashier', 'cash123', 'Front Cashier', UserRole.cashier),
    ];
    for (final (username, password, name, role) in defaults) {
      await _db.into(_db.appUsers).insert(AppUsersCompanion.insert(
            id: DbPaths.newId(),
            username: username,
            displayName: name,
            role: role.name,
            passwordHash: await PasswordHasher.hash(password),
            mustChangePassword: const Value(true),
          ));
    }
  }

  Future<AppUser?> restoreSession() async {
    final file = await _sessionFile();
    if (!await file.exists()) return null;
    try {
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final id = json['userId'] as String?;
      if (id == null) return null;
      final row = await (_db.select(_db.appUsers)..where((t) => t.id.equals(id))).getSingleOrNull();
      if (row == null || !row.isActive) return null;
      return _toUser(row);
    } catch (_) {
      return null;
    }
  }

  Future<AppUser> signIn({required String username, required String password}) async {
    final locked = _lockedUntil;
    if (locked != null && DateTime.now().isBefore(locked)) {
      final secs = locked.difference(DateTime.now()).inSeconds + 1;
      throw ApiException('Too many attempts. Try again in $secs seconds.');
    }

    final normalized = username.trim().toLowerCase();
    final row = await (_db.select(_db.appUsers)..where((t) => t.username.equals(normalized))).getSingleOrNull();
    final ok = row != null && row.isActive && await PasswordHasher.verify(password, row.passwordHash);
    if (!ok) {
      _failures++;
      AppLogger.warn('Auth', 'Failed sign-in for "$normalized" ($_failures)');
      if (_failures >= _maxFailures) {
        _lockedUntil = DateTime.now().add(_lockout);
        _failures = 0;
      }
      throw const ApiException('Invalid username or password.');
    }
    _failures = 0;
    _lockedUntil = null;

    await (_db.update(_db.appUsers)..where((t) => t.id.equals(row.id)))
        .write(AppUsersCompanion(lastLoginAt: Value(DateTime.now().toUtc())));

    final file = await _sessionFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode({'userId': row.id}));
    AppLogger.info('Auth', 'Signed in: ${row.username} (${row.role})');
    return _toUser(row);
  }

  Future<void> signOut() async {
    final file = await _sessionFile();
    if (await file.exists()) await file.delete();
  }

  Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final row = await (_db.select(_db.appUsers)..where((t) => t.id.equals(userId))).getSingleOrNull();
    if (row == null || !await PasswordHasher.verify(currentPassword, row.passwordHash)) {
      throw const ApiException('Current password is incorrect.');
    }
    _validateNewPassword(newPassword, username: row.username);
    if (await PasswordHasher.verify(newPassword, row.passwordHash)) {
      throw const ApiException('New password must be different from the current one.');
    }
    await _writePassword(userId, newPassword, mustChange: false);
  }

  // ── Owner-only user management ─────────────────────────────────────

  Stream<List<AppUser>> watchUsers() {
    return (_db.select(_db.appUsers)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.role), (t) => OrderingTerm.asc(t.username)]))
        .watch()
        .map((rows) => rows.map(_toUser).toList());
  }

  Future<void> createUser({
    required String username,
    required String displayName,
    required UserRole role,
    required String password,
  }) async {
    final normalized = username.trim().toLowerCase();
    if (!RegExp(r'^[a-z0-9._-]{3,32}$').hasMatch(normalized)) {
      throw const ApiException('Username must be 3–32 characters: letters, numbers, . _ -');
    }
    if (displayName.trim().isEmpty) throw const ApiException('Display name is required.');
    _validateNewPassword(password, username: normalized);

    final clash = await (_db.select(_db.appUsers)..where((t) => t.username.equals(normalized))).getSingleOrNull();
    if (clash != null) {
      if (clash.isActive) throw ApiException('Username "$normalized" is already taken.');
      // Re-activate a previously removed account with fresh details.
      await (_db.update(_db.appUsers)..where((t) => t.id.equals(clash.id))).write(AppUsersCompanion(
            displayName: Value(displayName.trim()),
            role: Value(role.name),
            isActive: const Value(true),
            passwordHash: Value(await PasswordHasher.hash(password)),
            mustChangePassword: const Value(true),
            updatedAt: Value(DateTime.now().toUtc()),
          ));
      return;
    }

    await _db.into(_db.appUsers).insert(AppUsersCompanion.insert(
          id: DbPaths.newId(),
          username: normalized,
          displayName: displayName.trim(),
          role: role.name,
          passwordHash: await PasswordHasher.hash(password),
          mustChangePassword: const Value(true),
        ));
  }

  /// Owner sets a temporary password; the user must change it at next sign-in.
  Future<void> resetPassword(String userId, String temporaryPassword) async {
    final row = await (_db.select(_db.appUsers)..where((t) => t.id.equals(userId))).getSingle();
    _validateNewPassword(temporaryPassword, username: row.username);
    await _writePassword(userId, temporaryPassword, mustChange: true);
  }

  Future<void> deactivateUser(String userId, {required String actingUserId}) async {
    if (userId == actingUserId) throw const ApiException('You cannot remove your own account.');
    final row = await (_db.select(_db.appUsers)..where((t) => t.id.equals(userId))).getSingle();
    if (row.role == UserRole.owner.name) {
      final owners = await (_db.select(_db.appUsers)
            ..where((t) => t.role.equals(UserRole.owner.name) & t.isActive.equals(true)))
          .get();
      if (owners.length <= 1) throw const ApiException('There must be at least one owner account.');
    }
    await (_db.update(_db.appUsers)..where((t) => t.id.equals(userId)))
        .write(AppUsersCompanion(isActive: const Value(false), updatedAt: Value(DateTime.now().toUtc())));
  }

  void _validateNewPassword(String password, {required String username}) {
    if (password.length < minPasswordLength) {
      throw const ApiException('Password must be at least $minPasswordLength characters.');
    }
    if (password.toLowerCase() == username.toLowerCase()) {
      throw const ApiException('Password cannot be the same as the username.');
    }
  }

  Future<void> _writePassword(String userId, String password, {required bool mustChange}) async {
    await (_db.update(_db.appUsers)..where((t) => t.id.equals(userId))).write(AppUsersCompanion(
          passwordHash: Value(await PasswordHasher.hash(password)),
          mustChangePassword: Value(mustChange),
          updatedAt: Value(DateTime.now().toUtc()),
        ));
  }

  AppUser _toUser(AppUserRow row) => AppUser(
        id: row.id,
        username: row.username,
        displayName: row.displayName,
        role: UserRole.parse(row.role),
        mustChangePassword: row.mustChangePassword,
      );

  Future<File> _sessionFile() async => File(DbPaths.join((await DbPaths.root()).path, 'session.json'));
}
