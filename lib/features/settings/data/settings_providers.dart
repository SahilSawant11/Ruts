import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/app_user.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/local/backup_service.dart';
import '../../masters/data/masters_providers.dart';

final backupServiceProvider = Provider<BackupService>((ref) => BackupService(ref.watch(appDatabaseProvider)));

final backupListProvider = FutureProvider<List<BackupInfo>>((ref) => ref.watch(backupServiceProvider).listBackups());

final backupMirrorFolderProvider = FutureProvider<String?>((ref) => ref.watch(backupServiceProvider).mirrorFolder());

final lastBackupAtProvider = FutureProvider<DateTime?>((ref) => ref.watch(backupServiceProvider).lastBackupAt());

final pendingRestoreProvider = FutureProvider<bool>((ref) => ref.watch(backupServiceProvider).hasPendingRestore());

final usersListProvider = StreamProvider<List<AppUser>>((ref) => ref.watch(authRepositoryProvider).watchUsers());
