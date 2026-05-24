import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/app_bar.dart';
import '../../../../shared/widgets/ghost_button.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../domain/entities/bazar_entities.dart';
import '../providers/bazar_providers.dart';
import '../widgets/bazar_status_widgets.dart';

class BazarSummaryScreen extends ConsumerWidget {
  const BazarSummaryScreen({required this.bazarId, super.key});

  final String bazarId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(bazarSummaryProvider(bazarId));

    return Scaffold(
      backgroundColor: AppColors.surface2,
      appBar: const BazarAppBar(title: 'বাজার সারাংশ'),
      body: summary.when(
        data: (summary) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.positive,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'বাজার শেষ হয়েছে!',
                    style: AppTextStyles.screenTitle.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _HeroMetric(
                        label: 'কেনা হয়েছে',
                        value: '${summary.purchasedCount}',
                      ),
                      _HeroMetric(
                        label: 'পাওয়া যায়নি',
                        value: '${summary.notFoundCount}',
                      ),
                      _HeroMetric(
                        label: 'মোট খরচ',
                        value: CurrencyFormatter.format(summary.totalSpent),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _BalanceCard(summary: summary),
            const SizedBox(height: 14),
            Text('আইটেম সারাংশ', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 8),
            ...summary.items.map(_SummaryItemTile.new),
          ],
        ),
        error: (error, _) => Center(child: Text(error.toString())),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PrimaryButton(
                label: '+ আরেকটি বাজার শুরু করুন',
                onPressed: () {},
              ),
              GhostButton(
                label: 'হোমে ফিরুন',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 3),
          Text(value, style: AppTextStyles.walletAmount),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.summary});

  final BazarSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _BalanceRow(label: 'আগের ব্যালেন্স', value: summary.previousBalance),
          _BalanceRow(label: 'এই বাজারের খরচ', value: -summary.totalSpent),
          const Divider(height: 22),
          _BalanceRow(
            label: 'নতুন ব্যালেন্স',
            value: summary.newBalance,
            strong: true,
          ),
        ],
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final double value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: strong ? AppTextStyles.bodyStrong : AppTextStyles.body,
            ),
          ),
          Text(
            CurrencyFormatter.format(value),
            style: strong ? AppTextStyles.bodyStrong : AppTextStyles.body,
          ),
        ],
      ),
    );
  }
}

class _SummaryItemTile extends StatelessWidget {
  const _SummaryItemTile(this.item);

  final BazarItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: AppTextStyles.bodyStrong),
                if (item.quantityLabel.isNotEmpty)
                  Text(item.quantityLabel, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          itemStatusChip(item.status),
          const SizedBox(width: 8),
          Text(
            CurrencyFormatter.format(item.price ?? 0),
            style: AppTextStyles.bodyStrong,
          ),
        ],
      ),
    );
  }
}
