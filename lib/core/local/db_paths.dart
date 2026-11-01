import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Central place for every on-disk location Caskly uses, plus the
/// startup steps that must run *before* SQLite opens the database file:
///
///  1. Move a legacy database out of Documents (Windows often syncs that
///     folder to OneDrive, which can corrupt a live SQLite file).
///  2. Apply a restore that was staged in the previous session.
abstract final class DbPaths {
  static const dbFileName = 'pos_app.sqlite';
  static const _legacyFileName = 'pos_app.sqlite.sqlite';
  static const _pendingRestoreSuffix = '.restore-pending';

  /// Demo transactions (fake sales history, sample materials) are only
  /// seeded in debug builds or when built with --dart-define=CASKLY_DEMO_DATA=true.
  static bool get seedDemoData => kDebugMode || const bool.fromEnvironment('CASKLY_DEMO_DATA');

  static Directory? _rootOverride;

  /// Tests can point every Caskly directory at a temp folder.
  @visibleForTesting
  static set rootOverride(Directory? dir) => _rootOverride = dir;

  static Future<Directory> root() async {
    final base = _rootOverride ?? await getApplicationSupportDirectory();
    return _ensure(Directory(_join(base.path, 'caskly')));
  }

  static Future<Directory> dataDir() async => _ensure(Directory(_join((await root()).path, 'data')));
  static Future<Directory> backupsDir() async => _ensure(Directory(_join((await root()).path, 'backups')));
  static Future<Directory> logsDir() async => _ensure(Directory(_join((await root()).path, 'logs')));

  static Future<File> databaseFile() async => File(_join((await dataDir()).path, dbFileName));

  static Future<File> pendingRestoreFile() async {
    final db = await databaseFile();
    return File('${db.path}$_pendingRestoreSuffix');
  }

  /// Used as drift's `databasePath` callback. Runs once, before the DB opens.
  static Future<String> prepareDatabaseFile() async {
    final db = await databaseFile();
    await _migrateLegacyLocation(db);
    await applyPendingRestore(db);
    return db.path;
  }

  /// Replaces the live DB with a staged restore file, keeping a safety copy
  /// of the previous DB in the backups folder. Must run while the DB is closed.
  static Future<bool> applyPendingRestore(File db) async {
    final pending = File('${db.path}$_pendingRestoreSuffix');
    if (!await pending.exists()) return false;

    if (await db.exists()) {
      final stamp = timestamp();
      final safety = File(_join((await backupsDir()).path, 'caskly_pre_restore_$stamp.sqlite'));
      await _moveWithSidecars(db, safety);
    }
    await _deleteSidecars(db);
    await pending.rename(db.path);
    return true;
  }

  static Future<void> _migrateLegacyLocation(File db) async {
    if (_rootOverride != null || await db.exists()) return;
    try {
      final docs = await getApplicationDocumentsDirectory();
      final legacy = File(_join(docs.path, _legacyFileName));
      if (await legacy.exists()) {
        await _moveWithSidecars(legacy, db);
      }
    } catch (e) {
      debugPrint('Legacy DB migration skipped: $e');
    }
  }

  static Future<void> _moveWithSidecars(File from, File to) async {
    await to.parent.create(recursive: true);
    for (final suffix in const ['', '-wal', '-shm']) {
      final src = File('${from.path}$suffix');
      if (!await src.exists()) continue;
      final dst = '${to.path}$suffix';
      try {
        await src.rename(dst);
      } on FileSystemException {
        // Cross-volume move: copy then delete.
        await src.copy(dst);
        await src.delete();
      }
    }
  }

  static Future<void> _deleteSidecars(File db) async {
    for (final suffix in const ['-wal', '-shm', '-journal']) {
      final f = File('${db.path}$suffix');
      if (await f.exists()) await f.delete();
    }
  }

  static Future<Directory> _ensure(Directory d) async {
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  static String _join(String a, String b) =>
      a.endsWith(Platform.pathSeparator) ? '$a$b' : '$a${Platform.pathSeparator}$b';

  static String join(String a, String b) => _join(a, b);

  /// Filesystem-safe local timestamp, e.g. 20261101-203015.
  static String timestamp([DateTime? at]) {
    final t = at ?? DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${t.year}${two(t.month)}${two(t.day)}-${two(t.hour)}${two(t.minute)}${two(t.second)}';
  }

  static final _rng = Random.secure();

  /// RFC 4122 v4 UUID. Globally unique, so records created offline on
  /// different devices never collide when they sync.
  static String newId() {
    final b = List<int>.generate(16, (_) => _rng.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }
}
