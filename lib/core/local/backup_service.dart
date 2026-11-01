import 'dart:io';

import 'package:flutter/foundation.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart' as sql;

import 'app_database.dart';
import 'db_paths.dart';

class BackupInfo {
  const BackupInfo({required this.file, required this.createdAt, required this.sizeBytes, required this.isAuto});

  final File file;
  final DateTime createdAt;
  final int sizeBytes;
  final bool isAuto;

  String get name => file.uri.pathSegments.last;
}

/// Backups use SQLite `VACUUM INTO`, which writes a consistent, compacted
/// snapshot even while the app is running.
///
/// - Automatic: one per day on app start, kept for [keepAutoBackups] days,
///   in the app's private backups folder.
/// - Mirror folder (optional): every backup is also copied to a folder the
///   owner picks, e.g. a USB drive or a Google Drive folder, so a dead hard
///   disk doesn't take the backups with it.
/// - Restore: staged next to the DB and swapped in on next launch, before
///   SQLite opens the file (see [DbPaths.applyPendingRestore]).
class BackupService {
  BackupService(this._db);

  final AppDatabase _db;

  static const keepAutoBackups = 14;
  static const _lastAutoKey = 'backup_last_auto_at';
  static const _mirrorKey = 'backup_mirror_folder';
  static const _lastAnyKey = 'backup_last_at';

  static const requiredTables = [
    'cached_materials',
    'cached_sales_bills',
    'cached_sale_line_items',
    'cached_inventory_stocks',
  ];

  Future<String?> mirrorFolder() => _db.getSetting(_mirrorKey);

  Future<void> setMirrorFolder(String? folder) async {
    if (folder == null || folder.isEmpty) {
      await _db.deleteSetting(_mirrorKey);
    } else {
      await _db.setSetting(_mirrorKey, folder);
    }
  }

  Future<DateTime?> lastBackupAt() async {
    final raw = await _db.getSetting(_lastAnyKey);
    return raw == null ? null : DateTime.tryParse(raw)?.toLocal();
  }

  /// Writes a backup into [targetFolder] (defaults to the app backups folder)
  /// and mirrors it if a mirror folder is configured. Returns the file.
  Future<File> backupNow({String? targetFolder, bool isAuto = false}) async {
    final folder = targetFolder ?? (await DbPaths.backupsDir()).path;
    await Directory(folder).create(recursive: true);

    final prefix = isAuto ? 'caskly_auto' : 'caskly_backup';
    var target = File(DbPaths.join(folder, '${prefix}_${DbPaths.timestamp()}.sqlite'));
    // VACUUM INTO refuses to overwrite; disambiguate same-second backups.
    var n = 1;
    while (await target.exists()) {
      target = File(DbPaths.join(folder, '${prefix}_${DbPaths.timestamp()}_${n++}.sqlite'));
    }

    await _db.customStatement('VACUUM INTO ?', [target.path]);
    await _db.setSetting(_lastAnyKey, DateTime.now().toUtc().toIso8601String());

    final mirror = await mirrorFolder();
    if (mirror != null && targetFolder == null) {
      try {
        final dir = Directory(mirror);
        if (await dir.exists()) {
          await target.copy(DbPaths.join(mirror, target.uri.pathSegments.last));
          await _prune(dir);
        }
      } catch (e) {
        debugPrint('Backup mirror copy failed: $e');
      }
    }
    return target;
  }

  /// Takes the daily automatic backup if one hasn't been taken in the last
  /// 20 hours. Safe to call on every launch. Never throws.
  Future<File?> autoBackupIfDue({DateTime? now}) async {
    try {
      final t = (now ?? DateTime.now()).toUtc();
      final last = DateTime.tryParse(await _db.getSetting(_lastAutoKey) ?? '');
      if (last != null && t.difference(last) < const Duration(hours: 20)) return null;

      final file = await backupNow(isAuto: true);
      await _db.setSetting(_lastAutoKey, t.toIso8601String());
      await _prune(await DbPaths.backupsDir());
      return file;
    } catch (e, st) {
      debugPrint('Auto backup failed: $e\n$st');
      return null;
    }
  }

  Future<List<BackupInfo>> listBackups() async {
    final dir = await DbPaths.backupsDir();
    final files = await dir
        .list()
        .where((e) => e is File && e.path.endsWith('.sqlite'))
        .cast<File>()
        .toList();
    final infos = <BackupInfo>[];
    for (final f in files) {
      final stat = await f.stat();
      infos.add(BackupInfo(
        file: f,
        createdAt: stat.modified,
        sizeBytes: stat.size,
        isAuto: f.uri.pathSegments.last.startsWith('caskly_auto'),
      ));
    }
    infos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return infos;
  }

  /// Keeps the newest [keepAutoBackups] automatic backups in [dir].
  /// Manual and pre-restore backups are never deleted automatically.
  Future<void> _prune(Directory dir) async {
    final autos = await dir
        .list()
        .where((e) => e is File && e.uri.pathSegments.last.startsWith('caskly_auto'))
        .cast<File>()
        .toList();
    if (autos.length <= keepAutoBackups) return;
    final withTime = <(File, DateTime)>[];
    for (final f in autos) {
      withTime.add((f, (await f.stat()).modified));
    }
    withTime.sort((a, b) => b.$2.compareTo(a.$2));
    for (final (f, _) in withTime.skip(keepAutoBackups)) {
      try {
        await f.delete();
      } catch (_) {}
    }
  }

  /// Checks that [file] is a healthy Caskly database. Returns an error
  /// message, or null if it is safe to restore.
  static String? validateBackup(File file) {
    if (!file.existsSync()) return 'File not found.';
    sql.Database? db;
    try {
      db = sql.sqlite3.open(file.path, mode: sql.OpenMode.readOnly);
      final check = db.select('PRAGMA quick_check');
      if (check.isEmpty || check.first.values.first != 'ok') {
        return 'The backup file is damaged (integrity check failed).';
      }
      final tables = db
          .select("SELECT name FROM sqlite_master WHERE type='table'")
          .map((r) => r['name'] as String)
          .toSet();
      final missing = requiredTables.where((t) => !tables.contains(t)).toList();
      if (missing.isNotEmpty) {
        return 'This is not a Caskly backup (missing: ${missing.join(', ')}).';
      }
      return null;
    } catch (e) {
      return 'Could not read the file as a database: $e';
    } finally {
      db?.close();
    }
  }

  /// Validates [backup] and stages it to replace the live database on the
  /// next launch. The caller should ask the user to restart Caskly.
  /// Before staging, a fresh safety backup of the current data is taken.
  Future<void> stageRestore(File backup) async {
    final error = validateBackup(backup);
    if (error != null) throw BackupException(error);

    await backupNow();
    final pending = await DbPaths.pendingRestoreFile();
    if (await pending.exists()) await pending.delete();
    await backup.copy(pending.path);
  }

  Future<bool> hasPendingRestore() async => (await DbPaths.pendingRestoreFile()).exists();

  Future<void> cancelPendingRestore() async {
    final pending = await DbPaths.pendingRestoreFile();
    if (await pending.exists()) await pending.delete();
  }
}

class BackupException implements Exception {
  const BackupException(this.message);
  final String message;
  @override
  String toString() => message;
}
