import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/app_bar.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../domain/entities/report_summary.dart';
import '../providers/report_providers.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _periodMonth = currentPeriodMonth();

  @override
  Widget build(BuildContext context) {
    final report = ref.watch(monthlyReportProvider(_periodMonth));
    return Scaffold(
      backgroundColor: AppColors.surface2,
      appBar: BazarAppBar(
        title: 'রিপোর্ট',
        leading: Navigator.canPop(context)
            ? IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              )
            : null,
        actions: [
          TextButton(
            onPressed: () {},
            child: Text(
              'Export ↓',
              style: AppTextStyles.bodyStrong.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
      body: report.when(
        data: (summary) => _ReportContent(
          summary: summary,
          selectedMonth: _periodMonth,
          onMonthChanged: (value) => setState(() => _periodMonth = value),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const _ReportError(),
      ),
    );
  }
}

class _ReportContent extends StatelessWidget {
  const _ReportContent({
    required this.summary,
    required this.selectedMonth,
    required this.onMonthChanged,
  });

  final ReportSummary summary;
  final String selectedMonth;
  final ValueChanged<String> onMonthChanged;

  @override
  Widget build(BuildContext context) {
    final months = _monthOptions();
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Wrap(
            spacing: 8,
            children: months
                .map(
                  (month) => ChoiceChip(
                    label: Text(month.label),
                    selected: selectedMonth == month.value,
                    selectedColor: AppColors.primaryLight,
                    onSelected: (_) => onMonthChanged(month.value),
                  ),
                )
                .toList(),
          ),
        ),
        const SectionHeader(title: 'মাসের সারসংক্ষেপ'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.45,
            children: [
              _StatCard(
                label: 'মোট প্রাপ্তি',
                value: summary.totalReceived,
                color: AppColors.positive,
                icon: Icons.south_west,
              ),
              _StatCard(
                label: 'মোট খরচ',
                value: summary.totalSpent,
                color: AppColors.negative,
                icon: Icons.shopping_basket,
              ),
              _StatCard(
                label: 'ফেরত দেওয়া',
                value: summary.totalReturned,
                color: AppColors.warning,
                icon: Icons.keyboard_return,
              ),
              _StatCard(
                label: 'নিট ব্যালেন্স',
                value: summary.netBalance,
                color: summary.netBalance >= 0
                    ? AppColors.positive
                    : AppColors.negative,
                icon: Icons.account_balance_wallet,
              ),
            ],
          ),
        ),
        const SectionHeader(title: 'ওয়ালেট বিভাজন'),
        if (summary.walletBreakdowns.isEmpty)
          const _EmptyCard(message: 'এই মাসে কোনো ওয়ালেট লেনদেন নেই')
        else
          for (final wallet in summary.walletBreakdowns)
            _WalletBreakdownTile(wallet),
        const SectionHeader(title: 'বেশি কেনা আইটেম'),
        if (summary.topItems.isEmpty)
          const _EmptyCard(message: 'এই মাসে কোনো কেনা আইটেম নেই')
        else
          for (final item in summary.topItems) _TopItemTile(item),
      ],
    );
  }

  List<_MonthOption> _monthOptions() {
    final now = DateTime.now();
    return List.generate(3, (index) {
      final date = DateTime(now.year, now.month - (2 - index));
      return _MonthOption(
        _monthLabel(date),
        '${date.year}-${date.month.toString().padLeft(2, '0')}',
      );
    });
  }

  String _monthLabel(DateTime date) {
    const names = [
      'জানুয়ারি',
      'ফেব্রুয়ারি',
      'মার্চ',
      'এপ্রিল',
      'মে',
      'জুন',
      'জুলাই',
      'আগস্ট',
      'সেপ্টেম্বর',
      'অক্টোবর',
      'নভেম্বর',
      'ডিসেম্বর',
    ];
    return '${names[date.month - 1]} ${_bn(date.year)}';
  }

  String _bn(int value) {
    const digits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    return value
        .toString()
        .split('')
        .map((char) => digits[int.parse(char)])
        .join();
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final double value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const Spacer(),
          Text(label, style: AppTextStyles.bodySmall),
          Text(
            CurrencyFormatter.format(value),
            style: AppTextStyles.bodyStrong.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _WalletBreakdownTile extends StatelessWidget {
  const _WalletBreakdownTile(this.wallet);

  final WalletBreakdown wallet;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(wallet.walletName, style: AppTextStyles.bodyStrong),
                Text(
                  'প্রাপ্তি ${CurrencyFormatter.format(wallet.received)} • খরচ ${CurrencyFormatter.format(wallet.spent)}',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.format(wallet.netBalance),
            style: AppTextStyles.bodyStrong.copyWith(
              color: wallet.netBalance >= 0
                  ? AppColors.positive
                  : AppColors.negative,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopItemTile extends StatelessWidget {
  const _TopItemTile(this.item);

  final ItemPurchaseSummary item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_grocery_store, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(item.name, style: AppTextStyles.bodyStrong)),
          Text(
            '${item.quantity} বার • ${CurrencyFormatter.format(item.totalSpent)}',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(message, style: AppTextStyles.body),
    );
  }
}

class _ReportError extends StatelessWidget {
  const _ReportError();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('রিপোর্ট লোড করা যায়নি', style: AppTextStyles.body),
    );
  }
}

class _MonthOption {
  const _MonthOption(this.label, this.value);

  final String label;
  final String value;
}
