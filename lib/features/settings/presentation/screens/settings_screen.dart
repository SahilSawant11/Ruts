import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/app_user.dart';
import '../../../../core/auth/auth_controller.dart';
import '../../../../core/auth/auth_repository.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/licensing/license_service.dart';
import '../../../../core/local/backup_service.dart';
import '../../../../core/local/db_paths.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/sync/online_sync_service.dart';
import '../../../../core/sync/sync_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/font_scale_provider.dart';
import '../../../../core/theme/theme_mode_provider.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/badges/status_chip.dart';
import '../../../../shared/widgets/buttons/named_buttons.dart';
import '../../../../shared/widgets/inputs/app_dropdown.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/layout/app_card.dart';
import '../../data/settings_providers.dart';

enum _Section {
  account('Account', 'Your sign-in and password.', AppIcons.badge),
  appearance('Appearance', 'Theme and text size on this computer.', AppIcons.tune),
  users('Users', 'Who can sign in, and what they can open.', AppIcons.people),
  backup('Backup & restore', 'Daily backups, a safety copy folder, and restore.', AppIcons.download),
  online('Online sync', 'Connect this counter to a Caskly server. Optional.', AppIcons.sync),
  about('About', 'Version, licence and support details.', AppIcons.info);

  const _Section(this.label, this.description, this.icon);
  final String label;
  final String description;
  final AppIconData icon;
}

/// Remembers the open section while moving around the app.
final _openSectionProvider = StateProvider<_Section>((ref) => _Section.account);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    final sections = [
      _Section.account,
      _Section.appearance,
      if (Permissions.canManageUsers(user.role)) _Section.users,
      if (Permissions.canBackup(user.role)) _Section.backup,
      if (Permissions.canManageUsers(user.role)) _Section.online,
      _Section.about,
    ];
    final picked = ref.watch(_openSectionProvider);
    final current = sections.contains(picked) ? picked : sections.first;
    void open(_Section s) => ref.read(_openSectionProvider.notifier).state = s;

    final Widget body = switch (current) {
      _Section.account => _AccountCard(user: user),
      _Section.appearance => const _AppearanceCard(),
      _Section.users => _UsersCard(user: user),
      _Section.backup => _BackupCard(user: user),
      _Section.online => const _OnlineSyncCard(),
      _Section.about => _AboutCard(showLicence: user.role != UserRole.cashier),
    };

    final content = SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(current.label, style: AppTypography.h2For(context)),
              const SizedBox(height: 4),
              Text(current.description, style: AppTypography.bodyMutedFor(context)),
              const SizedBox(height: AppSpacing.lg),
              KeyedSubtree(key: ValueKey(current), child: body),
            ],
          ),
        ),
      ),
    );

    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 760) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
              child: Row(children: [
                for (final s in sections) _NavItem(section: s, selected: s == current, onTap: () => open(s)),
              ]),
            ),
            Expanded(child: content),
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 232,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(border: Border(right: BorderSide(color: AppColors.borderFor(context)))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  child: Text('SETTINGS', style: AppTypography.label.copyWith(color: AppColors.textMutedFor(context))),
                ),
                for (final s in sections) _NavItem(section: s, selected: s == current, onTap: () => open(s)),
              ],
            ),
          ),
          Expanded(child: content),
        ],
      );
    });
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.section, required this.selected, required this.onTap});
  final _Section section;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.textPrimaryFor(context) : AppColors.textSecondaryFor(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2, right: 4),
      child: Material(
        color: selected ? AppColors.primarySoftFor(context) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(section.icon, size: 18, color: selected ? AppColors.primaryInk : color),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    section.label,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body.copyWith(
                      color: color,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Helpers ────────────────────────────────────────────────────────────────

void _toast(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message, style: const TextStyle(color: Colors.white)),
    backgroundColor: error ? AppColors.danger : AppColors.success,
  ));
}

String _formatDateTime(DateTime? t) {
  if (t == null) return 'Never';
  String two(int v) => v.toString().padLeft(2, '0');
  final l = t.toLocal();
  return '${two(l.day)}-${two(l.month)}-${l.year} ${two(l.hour)}:${two(l.minute)}';
}

String _formatSize(int bytes) {
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

Future<void> _openFolder(String path) async {
  try {
    if (Platform.isWindows) {
      await Process.run('explorer', [path]);
    } else if (Platform.isMacOS) {
      await Process.run('open', [path]);
    } else {
      await Process.run('xdg-open', [path]);
    }
  } catch (e) {
    AppLogger.warn('Settings', 'Could not open folder $path: $e');
  }
}

class _Explain extends StatelessWidget {
  const _Explain(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: AppTypography.body.copyWith(height: 1.45, color: AppColors.textSecondaryFor(context)),
      );
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(label, style: AppTypography.body.copyWith(color: AppColors.textSecondaryFor(context))),
          ),
          Expanded(child: SelectableText(value, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

// ─── Account ────────────────────────────────────────────────────────────────

class _AccountCard extends ConsumerWidget {
  const _AccountCard({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            icon: AppIcons.badge,
            title: user.displayName,
            subtitle: 'Signed in on this computer',
            trailing: StatusChip(label: user.roleLabel, tone: StatusChipTone.neutral),
          ),
          const SizedBox(height: AppSpacing.md),
          _Row('Username', user.username),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: SecondaryButton(
              label: 'Change password',
              icon: AppIcons.lock,
              onPressed: () => showDialog<void>(context: context, builder: (_) => const _ChangePasswordDialog()),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangePasswordDialog extends ConsumerStatefulWidget {
  const _ChangePasswordDialog();

  @override
  ConsumerState<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<_ChangePasswordDialog> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_next.text != _confirm.text) {
      setState(() => _error = 'New passwords do not match.');
      return;
    }
    setState(() => _busy = true);
    final err = await ref
        .read(authControllerProvider.notifier)
        .changePassword(currentPassword: _current.text, newPassword: _next.text);
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _busy = false;
        _error = err;
      });
      return;
    }
    Navigator.of(context).pop();
    _toast(context, 'Password changed.');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change password'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(label: 'CURRENT PASSWORD', controller: _current, obscureText: true, autofocus: true),
            const SizedBox(height: AppSpacing.md),
            AppTextField(label: 'NEW PASSWORD', controller: _next, obscureText: true),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'CONFIRM NEW PASSWORD',
              controller: _confirm,
              obscureText: true,
              onSubmitted: (_) => _save(),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_error!, style: AppTypography.caption.copyWith(color: AppColors.danger)),
            ],
          ],
        ),
      ),
      actions: [
        SecondaryButton(label: 'Cancel', onPressed: () => Navigator.of(context).pop()),
        PrimaryButton(label: _busy ? 'Saving…' : 'Save', onPressed: _busy ? null : _save),
      ],
    );
  }
}

// ─── Backup & restore ───────────────────────────────────────────────────────

class _BackupCard extends ConsumerStatefulWidget {
  const _BackupCard({required this.user});
  final AppUser user;

  @override
  ConsumerState<_BackupCard> createState() => _BackupCardState();
}

class _BackupCardState extends ConsumerState<_BackupCard> {
  bool _busy = false;

  void _refresh() {
    ref.invalidate(backupListProvider);
    ref.invalidate(lastBackupAtProvider);
    ref.invalidate(backupMirrorFolderProvider);
    ref.invalidate(pendingRestoreProvider);
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e, st) {
      AppLogger.error('Backup', e, st);
      if (mounted) _toast(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
      _refresh();
    }
  }

  Future<void> _backupNow() => _run(() async {
        final file = await ref.read(backupServiceProvider).backupNow();
        if (mounted) _toast(context, 'Backup saved: ${file.uri.pathSegments.last}');
      });

  Future<void> _backupToFolder() async {
    final folder = await getDirectoryPath(confirmButtonText: 'Save Backup Here');
    if (folder == null) return;
    await _run(() async {
      final file = await ref.read(backupServiceProvider).backupNow(targetFolder: folder);
      if (mounted) _toast(context, 'Backup saved to ${file.path}');
    });
  }

  Future<void> _chooseMirror() async {
    final folder = await getDirectoryPath(confirmButtonText: 'Use This Folder');
    if (folder == null) return;
    await _run(() async {
      await ref.read(backupServiceProvider).setMirrorFolder(folder);
      await ref.read(backupServiceProvider).backupNow();
      if (mounted) _toast(context, 'Backups will also be copied to $folder');
    });
  }

  Future<void> _restore(File file) async {
    final error = BackupService.validateBackup(file);
    if (error != null) {
      _toast(context, error, error: true);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore this backup?'),
        content: Text(
          'All current data will be replaced with the data in\n${file.uri.pathSegments.last}.\n\n'
          'A safety backup of the current data is taken first. Caskly must be restarted to finish.',
        ),
        actions: [
          SecondaryButton(label: 'Cancel', onPressed: () => Navigator.of(ctx).pop(false)),
          DangerButton(label: 'Restore', onPressed: () => Navigator.of(ctx).pop(true)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _run(() async {
      await ref.read(backupServiceProvider).stageRestore(file);
      AppLogger.info('Backup', 'Restore staged from ${file.path} by ${widget.user.username}');
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Restart to finish restore'),
          content: const Text('Caskly will now close. Open it again to load the restored data.'),
          actions: [PrimaryButton(label: 'Close Caskly', onPressed: () => exit(0))],
        ),
      );
    });
  }

  Future<void> _restoreFromFile() async {
    final picked = await openFile(acceptedTypeGroups: const [
      XTypeGroup(label: 'Caskly backup', extensions: ['sqlite', 'db']),
    ]);
    if (picked == null) return;
    await _restore(File(picked.path));
  }

  @override
  Widget build(BuildContext context) {
    final canRestore = Permissions.canRestoreBackup(widget.user.role);
    final last = ref.watch(lastBackupAtProvider).valueOrNull;
    final mirror = ref.watch(backupMirrorFolderProvider).valueOrNull;
    final pending = ref.watch(pendingRestoreProvider).valueOrNull ?? false;
    final backups = ref.watch(backupListProvider);

    final actions = AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(icon: AppIcons.download, title: 'Backups'),
          const SizedBox(height: AppSpacing.xs),
          const _Explain(
            'An automatic backup is taken every day when Caskly starts; the last '
            '${BackupService.keepAutoBackups} are kept. Set a copy folder on a USB drive or cloud folder so '
            'a failed hard disk doesn\'t take the backups with it.',
          ),
          const SizedBox(height: AppSpacing.md),
          _Row('Last backup', _formatDateTime(last)),
          _Row('Copy backups to', mirror ?? 'Not set — choose a USB drive or cloud folder for safety'),
          if (pending)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                'A restore is waiting. Close and reopen Caskly to finish it.',
                style: AppTypography.body.copyWith(color: AppColors.warning, fontWeight: FontWeight.w600),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              PrimaryButton(label: 'Back up now', icon: AppIcons.save, onPressed: _busy ? null : _backupNow),
              SecondaryButton(
                  label: 'Back up to folder…', icon: AppIcons.download, onPressed: _busy ? null : _backupToFolder),
              SecondaryButton(
                label: mirror == null ? 'Set copy folder…' : 'Change copy folder…',
                icon: AppIcons.uploadFile,
                onPressed: _busy ? null : _chooseMirror,
              ),
              if (mirror != null)
                SecondaryButton(
                  label: 'Stop copying',
                  icon: AppIcons.close,
                  onPressed: _busy ? null : () => _run(() => ref.read(backupServiceProvider).setMirrorFolder(null)),
                ),
              if (canRestore)
                SecondaryButton(
                    label: 'Restore from file…', icon: AppIcons.upload, onPressed: _busy ? null : _restoreFromFile),
              SecondaryButton(
                label: 'Open backups folder',
                icon: AppIcons.openInNew,
                onPressed: () async => _openFolder((await DbPaths.backupsDir()).path),
              ),
            ],
          ),
        ],
      ),
    );

    final recent = AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(icon: AppIcons.time, title: 'Recent backups'),
          const SizedBox(height: AppSpacing.sm),
          backups.when(
            loading: () => const LinearProgressIndicator(minHeight: 2),
            error: (e, _) => Text('Could not list backups: $e'),
            data: (list) => list.isEmpty
                ? Text('No backups yet.',
                    style: AppTypography.body.copyWith(color: AppColors.textSecondaryFor(context)))
                : Column(
                    children: [
                      for (final b in list.take(10))
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: AppIcon(b.isAuto ? AppIcons.time : AppIcons.save, size: 18),
                          title: Text(b.name, style: AppTypography.body),
                          subtitle: Text('${_formatDateTime(b.createdAt)} · ${_formatSize(b.sizeBytes)}'
                              '${b.isAuto ? ' · automatic' : ''}'),
                          trailing: canRestore
                              ? TextButton(
                                  onPressed: _busy ? null : () => _restore(b.file), child: const Text('Restore'))
                              : null,
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [actions, const SizedBox(height: AppSpacing.lg), recent],
    );
  }
}

// ─── Users (owner only) ─────────────────────────────────────────────────────

class _UsersCard extends ConsumerWidget {
  const _UsersCard({required this.user});
  final AppUser user;

  Future<void> _deactivate(BuildContext context, WidgetRef ref, AppUser target) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove ${target.displayName}?'),
        content: const Text('They will no longer be able to sign in. Their past bills are kept.'),
        actions: [
          SecondaryButton(label: 'Cancel', onPressed: () => Navigator.of(ctx).pop(false)),
          DangerButton(label: 'Remove', onPressed: () => Navigator.of(ctx).pop(true)),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(authRepositoryProvider).deactivateUser(target.id, actingUserId: user.id);
    } on ApiException catch (e) {
      if (context.mounted) _toast(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(usersListProvider);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            icon: AppIcons.people,
            title: 'People',
            trailing: PrimaryButton(
              label: 'Add user',
              icon: AppIcons.add,
              dense: true,
              onPressed: () => showDialog<void>(context: context, builder: (_) => const _UserDialog()),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const _Explain(
            'Cashiers can open Sales, Sales Return and Inventory. Managers can open everything except '
            'user management and restore. Owners can do everything.',
          ),
          const SizedBox(height: AppSpacing.md),
          users.when(
            loading: () => const LinearProgressIndicator(minHeight: 2),
            error: (e, _) => Text('$e'),
            data: (list) => Column(
              children: [
                for (final u in list)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primarySoftFor(context),
                      child: Text(u.initials, style: AppTypography.label.copyWith(color: AppColors.primaryInk)),
                    ),
                    title: Text('${u.displayName}${u.id == user.id ? '  (you)' : ''}', style: AppTypography.body),
                    subtitle: Text('${u.username} · ${u.roleLabel}'
                        '${u.mustChangePassword ? ' · must set new password' : ''}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () => showDialog<void>(context: context, builder: (_) => _UserDialog(resetFor: u)),
                          child: const Text('Reset password'),
                        ),
                        if (u.id != user.id)
                          TextButton(
                            onPressed: () => _deactivate(context, ref, u),
                            child: const Text('Remove', style: TextStyle(color: AppColors.danger)),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Add-user dialog, or (with [resetFor]) set a temporary password.
class _UserDialog extends ConsumerStatefulWidget {
  const _UserDialog({this.resetFor});
  final AppUser? resetFor;

  @override
  ConsumerState<_UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends ConsumerState<_UserDialog> {
  final _username = TextEditingController();
  final _name = TextEditingController();
  final _password = TextEditingController();
  UserRole _role = UserRole.cashier;
  String? _error;
  bool _busy = false;

  bool get _isReset => widget.resetFor != null;

  @override
  void dispose() {
    _username.dispose();
    _name.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = ref.read(authRepositoryProvider);
      if (_isReset) {
        await repo.resetPassword(widget.resetFor!.id, _password.text);
      } else {
        await repo.createUser(username: _username.text, displayName: _name.text, role: _role, password: _password.text);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      _toast(context, _isReset ? 'Temporary password set.' : 'User added.');
    } on ApiException catch (e) {
      setState(() {
        _busy = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isReset ? 'Reset password for ${widget.resetFor!.displayName}' : 'Add user'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isReset) ...[
              AppTextField(label: 'USERNAME', controller: _username, autofocus: true),
              const SizedBox(height: AppSpacing.md),
              AppTextField(label: 'DISPLAY NAME', controller: _name),
              const SizedBox(height: AppSpacing.md),
              AppDropdown<UserRole>(
                label: 'ROLE',
                items: UserRole.values,
                value: _role,
                itemLabel: (r) => r.label,
                onChanged: (r) => setState(() => _role = r ?? _role),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            AppTextField(
              label: _isReset ? 'TEMPORARY PASSWORD' : 'PASSWORD',
              controller: _password,
              obscureText: true,
              autofocus: _isReset,
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'At least ${AuthRepository.minPasswordLength} characters. They will be asked to change it at first sign-in.',
              style: AppTypography.caption.copyWith(color: AppColors.textSecondaryFor(context)),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_error!, style: AppTypography.caption.copyWith(color: AppColors.danger)),
            ],
          ],
        ),
      ),
      actions: [
        SecondaryButton(label: 'Cancel', onPressed: () => Navigator.of(context).pop()),
        PrimaryButton(label: _busy ? 'Saving…' : 'Save', onPressed: _busy ? null : _save),
      ],
    );
  }
}

// ─── Online sync (owner, optional) ─────────────────────────────────────────

class _OnlineSyncCard extends ConsumerStatefulWidget {
  const _OnlineSyncCard();

  @override
  ConsumerState<_OnlineSyncCard> createState() => _OnlineSyncCardState();
}

class _OnlineSyncCardState extends ConsumerState<_OnlineSyncCard> {
  final _url = TextEditingController();
  final _store = TextEditingController();
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _url.dispose();
    _store.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final service = ref.read(onlineSyncServiceProvider);
      await service.connect(serverUrl: _url.text, storeName: _store.text, enrollmentCode: _code.text);
      final r = await service.syncNow();
      if (mounted) _toast(context, 'Connected. ${r.toString()}', error: !r.ok);
    } on SyncException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
      ref.invalidate(onlineSyncStatusProvider);
    }
  }

  Future<void> _syncNow() async {
    setState(() => _busy = true);
    final r = await ref.read(onlineSyncServiceProvider).syncNow();
    if (mounted) {
      setState(() => _busy = false);
      _toast(context, r.toString(), error: !r.ok);
    }
    ref.invalidate(onlineSyncStatusProvider);
  }

  Future<void> _disconnect() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disconnect from server?'),
        content: const Text('This counter keeps working offline. Bills not yet sent stay queued until you reconnect.'),
        actions: [
          SecondaryButton(label: 'Cancel', onPressed: () => Navigator.of(ctx).pop(false)),
          DangerButton(label: 'Disconnect', onPressed: () => Navigator.of(ctx).pop(true)),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(onlineSyncServiceProvider).disconnect();
    ref.invalidate(onlineSyncStatusProvider);
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(onlineSyncStatusProvider).valueOrNull;
    final connected = status?.connected ?? false;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            icon: AppIcons.sync,
            title: 'Server connection',
            trailing: StatusChip(
              label: connected ? 'Connected' : 'Offline only',
              tone: connected ? StatusChipTone.success : StatusChipTone.neutral,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const _Explain(
            'Optional. Connect this counter to a Caskly server to combine several counters and see the store '
            'from anywhere. Billing never waits for the server — bills are sent in the background every few minutes.',
          ),
          const SizedBox(height: AppSpacing.md),
          if (connected) ...[
            _Row('Server', status?.url ?? ''),
            _Row('Store', status?.store ?? ''),
            _Row('Last sync', _formatDateTime(status?.lastAt)),
            if (status?.lastResult != null) _Row('Result', status!.lastResult!),
            const SizedBox(height: AppSpacing.md),
            Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
              PrimaryButton(
                  label: _busy ? 'Syncing…' : 'Sync now', icon: AppIcons.sync, onPressed: _busy ? null : _syncNow),
              SecondaryButton(label: 'Disconnect', icon: AppIcons.close, onPressed: _busy ? null : _disconnect),
            ]),
          ] else ...[
            AppTextField(label: 'SERVER ADDRESS', hint: 'e.g. 192.168.1.10:5080', controller: _url),
            const SizedBox(height: AppSpacing.md),
            AppTextField(label: 'STORE NAME', controller: _store),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
                label: 'ENROLLMENT CODE', controller: _code, obscureText: true, onSubmitted: (_) => _connect()),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_error!, style: AppTypography.caption.copyWith(color: AppColors.danger)),
            ],
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: PrimaryButton(
                  label: _busy ? 'Connecting…' : 'Connect', icon: AppIcons.sync, onPressed: _busy ? null : _connect),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Appearance ─────────────────────────────────────────────────────────────

class _AppearanceCard extends ConsumerWidget {
  const _AppearanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(appThemeModeProvider);
    final scale = AppFontScale.fromScale(ref.watch(appFontScaleProvider));
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(icon: AppIcons.lightMode, title: 'Theme'),
          const SizedBox(height: AppSpacing.md),
          _Choice<ThemeMode>(
            value: mode,
            options: const {ThemeMode.light: 'Light', ThemeMode.dark: 'Dark', ThemeMode.system: 'Match Windows'},
            onChanged: (m) => ref.read(appThemeModeProvider.notifier).state = m,
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(icon: AppIcons.fontSize, title: 'Text size'),
          const SizedBox(height: AppSpacing.md),
          _Choice<AppFontScale>(
            value: scale,
            options: {for (final p in AppFontScale.values) p: p.label},
            onChanged: (p) => ref.read(appFontScaleProvider.notifier).setPreset(p),
          ),
          const SizedBox(height: AppSpacing.sm),
          _Explain('${scale.description}. Saved on this computer; the header buttons change the same settings.'),
        ],
      ),
    );
  }
}

/// Flat segmented choice: ink border, gold fill on the chosen option.
class _Choice<T> extends StatelessWidget {
  const _Choice({required this.value, required this.options, required this.onChanged});
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final e in options.entries)
          Material(
            color: e.key == value ? AppColors.primary : Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: e.key == value ? AppColors.primary : AppColors.borderFor(context)),
            ),
            child: InkWell(
              onTap: () => onChanged(e.key),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                child: Text(
                  e.value,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: e.key == value ? AppColors.textOnPrimary : AppColors.textPrimaryFor(context),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── About ──────────────────────────────────────────────────────────────────

class _AboutCard extends ConsumerWidget {
  const _AboutCard({required this.showLicence});
  final bool showLicence;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(licenseStatusProvider).valueOrNull;
    final data = status?.data;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeader(icon: AppIcons.store, title: 'Caskly'),
              const SizedBox(height: AppSpacing.sm),
              const _Row('Version', AppConfig.version),
              _Row('Machine ID', status?.machineId ?? '…'),
            ],
          ),
        ),
        if (showLicence) ...[
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionHeader(icon: AppIcons.exciseSeal, title: 'Licence'),
                const SizedBox(height: AppSpacing.sm),
                if (status?.state == LicenseState.notEnforced)
                  const _Row('Licence', 'Not checked in development builds'),
                if (data != null) ...[
                  _Row('Licensed to', data.licensedTo),
                  _Row('Licence ID', data.licenseId),
                  _Row('Valid until',
                      data.expiresAt == null ? 'Perpetual' : _formatDateTime(data.expiresAt).split(' ').first),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeader(icon: AppIcons.openInNew, title: 'Support'),
              const SizedBox(height: AppSpacing.xs),
              const _Explain('If something goes wrong, send the newest file from the error logs folder to support, '
                  'along with the Machine ID above.'),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerLeft,
                child: SecondaryButton(
                  label: 'Open error logs folder',
                  icon: AppIcons.openInNew,
                  onPressed: () async => _openFolder((await DbPaths.logsDir()).path),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
