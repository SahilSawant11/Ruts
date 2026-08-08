import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../features/sync/data/sync_providers.dart';

/// Thin dark strip fixed to the bottom of the app shell with session
/// info on the left and quick shortcut hints on the right.
class AppStatusBar extends ConsumerWidget {
  const AppStatusBar({super.key, required this.moduleName});

  final String moduleName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muted = AppTypography.caption.copyWith(
      color: AppColors.shellTextMutedFor(context),
    );
    final syncOverviewAsync = ref.watch(syncOverviewProvider);
    return Container(
      height: 34,
      color: AppColors.shellBackgroundFor(context),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          _dot(),
          const SizedBox(width: 6),
          Text(_syncStatusLabel(syncOverviewAsync), style: muted),
          const SizedBox(width: AppSpacing.md),
          Text('Module: $moduleName', style: muted),
          const SizedBox(width: AppSpacing.md),
          Icon(
            Icons.calendar_today_outlined,
            size: 12,
            color: AppColors.shellTextMutedFor(context),
          ),
          const SizedBox(width: 5),
          Text(_todayLabel(), style: muted),
          const Spacer(),
          Text(_queueHint(syncOverviewAsync), style: muted),
          const SizedBox(width: AppSpacing.md),
          _dot(),
          const SizedBox(width: 6),
          Text('Sync Center available', style: muted),
          const SizedBox(width: AppSpacing.md),
          Text('Caskly v8.4', style: muted),
        ],
      ),
    );
  }

  String _syncStatusLabel(AsyncValue syncOverviewAsync) {
    return syncOverviewAsync.when(
      loading: () => 'admin · checking sync',
      error: (_, __) => 'admin · sync unknown',
      data: (overview) {
        if (overview.failed > 0) return 'admin · ${overview.failed} sync failed';
        if (overview.total > 0) return 'admin · ${overview.total} queued';
        return 'admin · sync clean';
      },
    );
  }

  String _queueHint(AsyncValue syncOverviewAsync) {
    return syncOverviewAsync.when(
      loading: () => 'Sync status loading…',
      error: (_, __) => 'Open Sync Center for diagnostics',
      data: (overview) {
        if (overview.total == 0) return 'F2-F3 switch billing · Sync queue empty';
        return 'Sync Center · ${overview.pending} pending · ${overview.processing} processing';
      },
    );
  }

  String _todayLabel() {
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}-${months[now.month - 1]}-${now.year}, ${weekdays[now.weekday - 1]}';
  }

  Widget _dot() => Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
      );
}
