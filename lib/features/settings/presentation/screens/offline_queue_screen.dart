import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final sync = ref.watch(settingsSyncStatusProvider);
    final items = ref.watch(offlineQueueEntriesProvider);
    final failed = ref.watch(offlineQueueFailedCountProvider);
    return Scaffold(
      backgroundColor: AppColors.surface2,
      appBar: BazarAppBar(
        title: 'Sync Queue',
        subtitle: 'OFFLINE PENDING ITEMS',
        leading: BackButton(onPressed: onBack),
      ),
      body: ListView(
        children: [
          _StatusBanner(sync: sync, count: items.length, failed: failed),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
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
                      'সব Retry করুন',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(38),
                      backgroundColor: AppColors.surface,
                      side: const BorderSide(
                        color: AppColors.border,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Queue মুছুন'),
                  ),
                ),
              ],
            ),
          ),
          HSectionCard(
            margin: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            children: [
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
              'Internet এলে automatically sync হবে। এই page বন্ধ করলেও data নষ্ট হবে না।',
              style: AppTextStyles.bodySmall,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
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
                  offline ? 'Offline মোড — Internet নেই' : 'Sync হচ্ছে…',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${CurrencyFormatter.toBanglaDigits(count.toString())}টি item পাঠানো বাকি আছে',
                  style: AppTextStyles.bodySmall.copyWith(color: color),
                ),
              ],
            ),
          ),
          if (failed > 0)
            HPill(
              label: '$failed failed',
              backgroundColor: AppColors.negativeLight,
              foregroundColor: AppColors.negativeDark,
            ),
        ],
      ),
    );
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
                        ? '${entry.ageLabel} · ${entry.retryCount} retry'
                        : '${entry.ageLabel} · ${entry.operation}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.text3,
                    ),
                  ),
                ],
              ),
            ),
            HPill(
              label: failed ? 'failed' : 'pending',
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
