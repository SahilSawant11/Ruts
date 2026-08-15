import 'dart:convert';
import 'dart:io';

import '../network/api_exception.dart';
import 'app_user.dart';

class AuthRepository {
  Future<AppUser?> restoreSession() async {
    final file = await _sessionFile();
    if (!await file.exists()) return null;

    try {
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return null;
      return AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<AppUser> signIn({
    required String username,
    required String password,
  }) async {
    final normalizedUsername = username.trim().toLowerCase();
    final normalizedPassword = password.trim();

    final record = _defaultUsers.where((user) => user.username == normalizedUsername).firstOrNull;
    if (record == null || record.password != normalizedPassword) {
      throw const ApiException('Invalid username or password.');
    }

    final user = AppUser(
      username: record.username,
      displayName: record.displayName,
      roleLabel: record.roleLabel,
    );

    final file = await _sessionFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(user.toJson()));
    return user;
  }

  Future<void> signOut() async {
    final file = await _sessionFile();
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<File> _sessionFile() async {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    final root = home != null && home.isNotEmpty ? Directory(home) : Directory.current;
    return File('${root.path}${Platform.pathSeparator}.caskly${Platform.pathSeparator}session.json');
  }
}

class _SeedUser {
  const _SeedUser({
    required this.username,
    required this.password,
    required this.displayName,
    required this.roleLabel,
  });

  final String username;
  final String password;
  final String displayName;
  final String roleLabel;
}

const _defaultUsers = <_SeedUser>[
  _SeedUser(
    username: 'admin',
    password: 'admin123',
    displayName: 'Admin User',
    roleLabel: 'Store Manager',
  ),
  _SeedUser(
    username: 'owner',
    password: 'owner123',
    displayName: 'Store Owner',
    roleLabel: 'Business Owner',
  ),
  _SeedUser(
    username: 'cashier',
    password: 'cash123',
    displayName: 'Front Cashier',
    roleLabel: 'Cash Counter',
  ),
];
