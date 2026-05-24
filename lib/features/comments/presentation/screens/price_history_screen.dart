import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/app_bar.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../domain/entities/comment_thread_entry.dart';
import '../providers/comments_providers.dart';

class PriceHistoryScreen extends ConsumerWidget {
  const PriceHistoryScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(priceHistoryProvider);
    return Scaffold(
      backgroundColor: AppColors.surface2,
      appBar: BazarAppBar(
        title: '${history.itemName} — দামের ইতিহাস',
        subtitle: 'ITEM PRICE HISTORY',
        leading: BackButton(onPressed: onBack),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                _StatCard(
                  label: 'সর্বশেষ দাম',
                  value: CurrencyFormatter.format(history.latestPrice),
                  color: AppColors.text1,
                  bg: AppColors.surface,
                ),
                const SizedBox(width: 10),
                _StatCard(
                  label: 'গড় দাম/টা',
                  value: CurrencyFormatter.format(history.averagePerUnit),
                  color: AppColors.primary,
                  bg: AppColors.primaryLight,
                ),
                const SizedBox(width: 10),
                _StatCard(
                  label: 'মোট কেনা',
                  value:
                      '${CurrencyFormatter.toBanglaDigits(history.entries.length.toString())}বার',
                  color: AppColors.positive,
                  bg: AppColors.positiveLight,
                ),
              ],
            ),
          ),
          const SectionHeader(title: 'দামের প্রবণতা (Chart)'),
          _PriceChart(history),
          const SectionHeader(title: 'ক্রয়ের বিস্তারিত'),
          _HistoryList(entries: history.entries),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
  });

  final String label;
  final String value;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(color: color),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyStrong.copyWith(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceChart extends StatelessWidget {
  const _PriceChart(this.history);

  final PriceHistorySummary history;

  @override
  Widget build(BuildContext context) {
    final reversed = history.entries.reversed.toList();
    final max = history.maxPrice == 0 ? 1 : history.maxPrice;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 104,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var index = 0; index < reversed.length; index++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: (reversed[index].price / max * 70).clamp(
                              4,
                              70,
                            ),
                            decoration: BoxDecoration(
                              color: index == reversed.length - 1
                                  ? AppColors.positive
                                  : AppColors.primary.withValues(alpha: 0.6),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            reversed[index].dateLabel
                                .split(' ')
                                .take(2)
                                .join('\n'),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption.copyWith(fontSize: 8),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('এপ্রিল', style: AppTextStyles.caption),
              Text(
                'আজকে: ${CurrencyFormatter.format(history.latestPrice)}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.positive,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.entries});

  final List<PriceHistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            for (var index = 0; index < entries.length; index++)
              _HistoryRow(
                entry: entries[index],
                latest: index == 0,
                showDivider: index < entries.length - 1,
              ),
          ],
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.entry,
    required this.latest,
    required this.showDivider,
  });

  final PriceHistoryEntry entry;
  final bool latest;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.surface3))
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  entry.dateLabel,
                  style: AppTextStyles.bodyStrong.copyWith(fontSize: 12),
                ),
                Text(
                  CurrencyFormatter.format(entry.price),
                  style: AppTextStyles.bodyStrong.copyWith(
                    color: latest ? AppColors.positive : AppColors.text1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Flexible(
                  child: Text(
                    entry.quantityLabel,
                    style: AppTextStyles.bodySmall,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    'প্রতিটা ${CurrencyFormatter.format(entry.perUnit)}',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(entry.bazarName, style: AppTextStyles.bodySmall),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(entry.buyerName, style: AppTextStyles.caption),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
