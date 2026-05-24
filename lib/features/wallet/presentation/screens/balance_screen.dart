import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/app_bar.dart';
import '../../../../shared/widgets/app_divider.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../domain/entities/wallet_summary.dart';
import '../providers/wallet_providers.dart';

class BalanceScreen extends ConsumerWidget {
  const BalanceScreen({super.key, this.onWalletTap, this.onMoneyEntryTap});

  final ValueChanged<String>? onWalletTap;
  final VoidCallback? onMoneyEntryTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaries = ref.watch(walletSummariesProvider);
    return Scaffold(
      backgroundColor: AppColors.surface2,
      appBar: const BazarAppBar(
        title: 'হিসাব / ব্যালেন্স',
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.calendar_month, color: Colors.white),
          ),
        ],
      ),
      body: summaries.when(
        data: (items) => _BalanceContent(
          summaries: items,
          onWalletTap: onWalletTap,
          onMoneyEntryTap: onMoneyEntryTap,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('ব্যালেন্স লোড করা যায়নি', style: AppTextStyles.body),
        ),
      ),
    );
  }
}

class _BalanceContent extends StatelessWidget {
  const _BalanceContent({
    required this.summaries,
    required this.onWalletTap,
    required this.onMoneyEntryTap,
  });

  final List<WalletSummary> summaries;
  final ValueChanged<String>? onWalletTap;
  final VoidCallback? onMoneyEntryTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 12),
        const _FilterChips(),
        const AppDivider(height: 12),
        for (final summary in summaries)
          _WalletBalanceCard(
            summary: summary,
            onTap: () => onWalletTap?.call(summary.wallet.id),
          ),
        PrimaryButton(
          label: '+ টাকার এন্ট্রি করুন',
          onPressed: onMoneyEntryTap,
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        ),
      ],
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips();

  @override
  Widget build(BuildContext context) {
    final labels = ['সব ওয়ালেট', 'Rahim', 'Karim'];
    return SizedBox(
      height: 34,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final selected = index == 0;
          return DecoratedBox(
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: Text(
                labels[index],
                style: AppTextStyles.bodySmall.copyWith(
                  color: selected ? Colors.white : AppColors.text3,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemCount: labels.length,
      ),
    );
  }
}

class _WalletBalanceCard extends StatelessWidget {
  const _WalletBalanceCard({required this.summary, required this.onTap});

  final WalletSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final balance = summary.balance;
    final cardColor = balance.isSettled
        ? AppColors.neutralCard
        : balance.isPositive
        ? AppColors.positiveCard
        : AppColors.negativeCard;
    return Semantics(
      button: true,
      label: '${summary.wallet.name} ${balance.label}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white24,
                    child: Text(
                      summary.wallet.shortName,
                      style: AppTextStyles.bodyStrong.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summary.wallet.name,
                          style: AppTextStyles.bodyStrong.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          balance.label,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white70),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                CurrencyFormatter.format(balance.estimatedBalance),
                style: AppTextStyles.walletAmount,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _AmountPill(
                      label: 'নিশ্চিত',
                      value: balance.confirmedBalance,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _AmountPill(
                      label: 'চলমান',
                      value: balance.inProgressAmount,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmountPill extends StatelessWidget {
  const _AmountPill({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 2),
          Text(
            CurrencyFormatter.format(value),
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
