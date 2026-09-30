import '../local/app_database.dart';

/// Minimal backup service using SQLite `VACUUM INTO`.
class BackupService {
  const BackupService(this._db);

  final AppDatabase _db;

  /// Creates a full backup of the database at [targetFolder]/caskly_backup_<timestamp>.sqlite.
  ///
  /// Uses `VACUUM INTO` which runs outside any transaction and writes a
  /// consistent snapshot to a new file. The target path must not already exist.
  ///
  /// Returns the full path of the created backup file.
  Future<String> backupNow(String targetFolder) async {
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '').replaceAll('-', '').split('.').first;
    final backupPath = '$targetFolder/caskly_backup_$timestamp.sqlite';

    await _db.customStatement("VACUUM INTO '$backupPath'");

    return backupPath;
  }
}
