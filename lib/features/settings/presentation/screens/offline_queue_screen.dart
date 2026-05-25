import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sync/sync_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/models/app_enums.dart';
import '../../../../shared/widgets/app_bar.dart';
import '../../domain/entities/offline_queue_entry.dart';
import '../providers/settings_providers.dart';
import '../widgets/settings_widgets.dart';

class OfflineQueueScreen extends ConsumerWidget {
  const OfflineQueueScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(syncStatusProvider);
    final items = ref.watch(offlineQueueEntriesProvider);
    return Scaffold(
      backgroundColor: AppColors.surface2,
      appBar: BazarAppBar(
        title: 'Sync queue',
        subtitle: 'Offline items',
        leading: BackButton(onPressed: onBack),
      ),
      body: items.when(
        data: (entries) => _OfflineQueueContent(sync: sync, items: entries),
        error: (error, _) => Center(child: Text(error.toString())),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _OfflineQueueContent extends ConsumerWidget {
  const _OfflineQueueContent({required this.sync, required this.items});

  final SyncStatus sync;
  final List<OfflineQueueEntry> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final failed = items
        .where((entry) => entry.status == OfflineQueueStatus.failed)
        .length;
    return ListView(
      children: [
        _StatusBanner(sync: sync, count: items.length, failed: failed),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: sync == SyncStatus.syncing
                      ? null
                      : () => ref
                            .read(offlineQueueRetryControllerProvider)
                            .retryAll(),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(38),
                    backgroundColor: AppColors.primaryLight,
                    side: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    sync == SyncStatus.syncing ? 'Sync হচ্ছে...' : 'Retry all',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        HSectionCard(
          margin: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          children: items.isEmpty
              ? [
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text('Sync queue empty', style: AppTextStyles.body),
                  ),
                ]
              : [
                  for (var index = 0; index < items.length; index++)
                    _QueueRow(
                      entry: items[index],
                      showDivider: index < items.length - 1,
                    ),
                ],
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface3,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Internet এলে ডাটা sync হবে। Page বন্ধ করলেও ডাটা থাকবে।',
            style: AppTextStyles.bodySmall,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.sync,
    required this.count,
    required this.failed,
  });

  final SyncStatus sync;
  final int count;
  final int failed;

  @override
  Widget build(BuildContext context) {
    final offline = sync == SyncStatus.offline;
    final color = offline ? AppColors.warningDark : AppColors.primaryText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: offline ? AppColors.warningLight : AppColors.primaryLight,
      child: Row(
        children: [
          Icon(
            offline ? Icons.wifi_off : Icons.sync,
            color: offline ? AppColors.warning : AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _syncLabel(sync),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${CurrencyFormatter.toBanglaDigits(count.toString())}টি আইটেম পাঠানো বাকি আছে',
                  style: AppTextStyles.bodySmall.copyWith(color: color),
                ),
              ],
            ),
          ),
          if (failed > 0)
            HPill(
              label:
                  '${CurrencyFormatter.toBanglaDigits(failed.toString())} ব্যর্থ',
              backgroundColor: AppColors.negativeLight,
              foregroundColor: AppColors.negativeDark,
            ),
        ],
      ),
    );
  }

  String _syncLabel(SyncStatus status) {
    return switch (status) {
      SyncStatus.online => 'Synced',
      SyncStatus.syncing => 'Sync হচ্ছে…',
      SyncStatus.offline => 'Offline mode — internet নেই',
      SyncStatus.failed => 'Sync failed',
    };
  }
}

class _QueueRow extends StatelessWidget {
  const _QueueRow({required this.entry, required this.showDivider});

  final OfflineQueueEntry entry;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final failed = entry.status == OfflineQueueStatus.failed;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.surface3))
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: failed
                    ? AppColors.negativeLight
                    : AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_iconFor(entry.entityType), size: 17),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.entityLabel,
                    style: AppTextStyles.bodyStrong.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.retryCount > 0
                        ? '${entry.ageLabel} · ${CurrencyFormatter.toBanglaDigits(entry.retryCount.toString())} চেষ্টা'
                        : '${entry.ageLabel} · ${entry.operation}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.text3,
                    ),
                  ),
                ],
              ),
            ),
            HPill(
              label: failed ? 'ব্যর্থ' : 'Pending',
              backgroundColor: failed
                  ? AppColors.negativeLight
                  : AppColors.warningLight,
              foregroundColor: failed
                  ? AppColors.negativeDark
                  : AppColors.warningDark,
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String type) {
    return switch (type) {
      'bazar_item' => Icons.shopping_cart,
      'direct_expense' => Icons.receipt_long,
      'money_entry' => Icons.payments,
      'comment' => Icons.chat_bubble_outline,
      _ => Icons.sync,
    };
  }
}
