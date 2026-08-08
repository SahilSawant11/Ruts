import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/local/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/badges/tag_pill.dart';
import '../../../../shared/widgets/buttons/named_buttons.dart';
import '../../../../shared/widgets/layout/app_card.dart';
import '../../data/sync_providers.dart';

class SyncCenterScreen extends ConsumerStatefulWidget {
  const SyncCenterScreen({super.key});

  @override
  ConsumerState<SyncCenterScreen> createState() => _SyncCenterScreenState();
}

class _SyncCenterScreenState extends ConsumerState<SyncCenterScreen> {
  bool _isSyncing = false;

  Future<void> _syncNow() async {
    setState(() => _isSyncing = true);
    try {
      await ref.read(syncRepositoryProvider).syncNow();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sync completed.'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync stopped: $e'), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final overviewAsync = ref.watch(syncOverviewProvider);
    final queueAsync = ref.watch(syncQueueItemsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sync Center', style: AppTypography.h1),
                    const SizedBox(height: 4),
                    Text('Review queued offline work, failures, and replay sync on demand.', style: AppTypography.bodyMuted),
                  ],
                ),
              ),
              PrimaryButton(
                label: _isSyncing ? 'Syncing…' : 'Sync Now',
                icon: Icons.sync_rounded,
                onPressed: _isSyncing ? null : _syncNow,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          overviewAsync.when(
            loading: () => const _OverviewSkeleton(),
            error: (error, _) => AppCard(child: Text('Could not load sync status: $error')),
            data: (overview) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _metricCard('Total queued', '${overview.total}', AppColors.primary)),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: _metricCard('Pending', '${overview.pending}', AppColors.warning)),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: _metricCard('Processing', '${overview.processing}', AppColors.primary)),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: _metricCard('Failed', '${overview.failed}', AppColors.danger)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: overviewAsync.when(
              loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
              error: (_, __) => const Text('Could not load sync breakdown.'),
              data: (overview) {
                if (overview.byEntityType.isEmpty) {
                  return const SectionHeader(title: 'Queue Breakdown', subtitle: 'Everything is synced.');
                }

                final entries = overview.byEntityType.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'Queue Breakdown', subtitle: 'Queued work by entity'),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final entry in entries)
                          TagPill(label: '${entry.key} · ${entry.value}', tone: _toneForEntity(entry.key)),
                      ],
                    ),
                    if (overview.lastActivityAt != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Last queue activity: ${_fmtDateTime(overview.lastActivityAt!)}',
                        style: AppTypography.caption,
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Queued Items', subtitle: 'Latest first'),
                const SizedBox(height: AppSpacing.sm),
                queueAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  error: (error, _) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Center(child: Text('Could not load queue: $error', style: AppTypography.bodyMuted)),
                  ),
                  data: (items) {
                    if (items.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        child: Center(child: Text('Queue is empty.', style: AppTypography.bodyMuted)),
                      );
                    }

                    return Column(
                      children: [
                        for (final item in items) _queueRow(item),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard(String label, String value, Color accent) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.bodyMuted),
          const SizedBox(height: 8),
          Text(value, style: AppTypography.h1.copyWith(color: accent)),
        ],
      ),
    );
  }

  Widget _queueRow(SyncQueueItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text('${item.entityType} · ${item.operation}', style: AppTypography.body.copyWith(fontWeight: FontWeight.w700)),
          ),
          Expanded(
            flex: 2,
            child: Text(item.entityId, style: AppTypography.mono.copyWith(fontSize: 12)),
          ),
          Expanded(
            flex: 1,
            child: TagPill(label: item.status, tone: _toneForStatus(item.status)),
          ),
          Expanded(
            flex: 3,
            child: Text(item.lastError ?? 'No error', style: AppTypography.caption),
          ),
          Expanded(
            flex: 2,
            child: Text(_fmtDateTime(item.updatedAt), textAlign: TextAlign.end, style: AppTypography.caption),
          ),
        ],
      ),
    );
  }

  TagPillTone _toneForStatus(String status) {
    switch (status) {
      case 'failed':
        return TagPillTone.danger;
      case 'processing':
        return TagPillTone.success;
      case 'pending':
      default:
        return TagPillTone.amber;
    }
  }

  TagPillTone _toneForEntity(String entity) {
    switch (entity) {
      case 'sale':
        return TagPillTone.success;
      case 'purchase':
        return TagPillTone.amber;
      case 'supplier':
      case 'material':
      default:
        return TagPillTone.neutral;
    }
  }

  String _fmtDateTime(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day.toString().padLeft(2, '0')}-${months[dt.month - 1]} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _OverviewSkeleton extends StatelessWidget {
  const _OverviewSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: AppCard(child: Text('—'))),
        SizedBox(width: AppSpacing.md),
        Expanded(child: AppCard(child: Text('—'))),
        SizedBox(width: AppSpacing.md),
        Expanded(child: AppCard(child: Text('—'))),
        SizedBox(width: AppSpacing.md),
        Expanded(child: AppCard(child: Text('—'))),
      ],
    );
  }
}
