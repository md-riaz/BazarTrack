import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/app_bar.dart';
import '../../../../shared/widgets/ghost_button.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../money/presentation/providers/money_providers.dart';
import '../providers/report_providers.dart';

class MonthlyCloseScreen extends ConsumerStatefulWidget {
  const MonthlyCloseScreen({
    super.key,
    this.walletId = 'w2',
    this.assistantId = 'u1',
    this.closedBy = 'u3',
  });

  final String walletId;
  final String? assistantId;
  final String closedBy;

  @override
  ConsumerState<MonthlyCloseScreen> createState() => _MonthlyCloseScreenState();
}

class _MonthlyCloseScreenState extends ConsumerState<MonthlyCloseScreen> {
  int _step = 0;
  bool _isClosing = false;
  String _periodMonth = currentPeriodMonth();

  @override
  Widget build(BuildContext context) {
    final report = ref.watch(monthlyReportProvider(_periodMonth));
    return Scaffold(
      backgroundColor: AppColors.surface2,
      appBar: BazarAppBar(
        title: 'হিসাব বন্ধ',
        subtitle: _monthLabel(_periodMonth),
        leading: Navigator.canPop(context)
            ? IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              )
            : null,
      ),
      body: report.when(
        data: (summary) => ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _StepIndicator(step: _step),
            _MonthSelector(
              value: _periodMonth,
              onChanged: (value) => setState(() => _periodMonth = value),
            ),
            if (_step == 0) _ReviewStep(netBalance: summary.netBalance),
            if (_step == 1) const _ConfirmStep(),
            if (_step == 2) _DoneStep(periodMonth: _periodMonth),
            const SizedBox(height: 12),
            if (_step == 0)
              PrimaryButton(
                label: 'পরবর্তী ধাপ →',
                onPressed: () => setState(() => _step = 1),
              ),
            if (_step == 1) ...[
              PrimaryButton(
                label: _isClosing
                    ? 'হিসাব বন্ধ হচ্ছে...'
                    : '✓ ${_monthLabel(_periodMonth)} হিসাব বন্ধ করুন',
                color: AppColors.negative,
                onPressed: _isClosing ? null : _closeMonth,
              ),
              GhostButton(
                label: '← ফিরে যান',
                onPressed: () => setState(() => _step = 0),
              ),
            ],
            if (_step == 2)
              PrimaryButton(label: 'রিপোর্ট দেখুন', onPressed: () {}),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const _MonthlyCloseError(),
      ),
    );
  }

  Future<void> _closeMonth() async {
    setState(() => _isClosing = true);
    try {
      await ref
          .read(moneyEntryRepositoryProvider)
          .closeMonthlyPeriod(
            walletId: widget.walletId,
            assistantId: widget.assistantId,
            periodMonth: _periodMonth,
            closedBy: widget.closedBy,
            notes: '${_monthLabel(_periodMonth)} হিসাব বন্ধ',
          );
      setState(() => _step = 2);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('হিসাব বন্ধ করা যায়নি')));
      }
    } finally {
      if (mounted) {
        setState(() => _isClosing = false);
      }
    }
  }

  String _monthLabel(String periodMonth) {
    final parts = periodMonth.split('-');
    final month = int.parse(parts[1]);
    final year = int.parse(parts[0]);
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
    return '${names[month - 1]} ${_bn(year)}';
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

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    const labels = ['রিভিউ', 'নিশ্চিত', 'সম্পন্ন'];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(labels.length, (index) {
          final active = index <= step;
          return Expanded(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: active
                      ? AppColors.primary
                      : AppColors.surface3,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: active ? Colors.white : AppColors.text3,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(labels[index], style: AppTextStyles.bodySmall),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = List.generate(
      3,
      (index) => DateTime(now.year, now.month - index),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: const InputDecoration(labelText: 'মাস'),
        items: months
            .map(
              (month) => DropdownMenuItem(
                value:
                    '${month.year}-${month.month.toString().padLeft(2, '0')}',
                child: Text('${month.month}/${month.year}'),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) {
            onChanged(value);
          }
        },
      ),
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({required this.netBalance});

  final double netBalance;

  @override
  Widget build(BuildContext context) {
    return _CloseCard(
      icon: Icons.fact_check,
      title: 'রিভিউ',
      message: 'সব টাকা এন্ট্রি, সরাসরি খরচ এবং বন্ধ বাজারের হিসাব দেখে নিন।',
      footer: 'নিট ব্যালেন্স ${CurrencyFormatter.format(netBalance)}',
    );
  }
}

class _ConfirmStep extends StatelessWidget {
  const _ConfirmStep();

  @override
  Widget build(BuildContext context) {
    return const _CloseCard(
      icon: Icons.lock,
      title: 'নিশ্চিত করুন',
      message:
          'এই মাস বন্ধ হলে এই মাসের সব entry permanently lock হবে। কেউ আর edit করতে পারবে না।',
      footer: 'বন্ধ করার আগে সব এন্ট্রি যাচাই করুন।',
      danger: true,
    );
  }
}

class _DoneStep extends StatelessWidget {
  const _DoneStep({required this.periodMonth});

  final String periodMonth;

  @override
  Widget build(BuildContext context) {
    return const _CloseCard(
      icon: Icons.check_circle,
      title: 'সম্পন্ন',
      message: 'মাসের হিসাব বন্ধ হয়েছে এবং এন্ট্রিগুলো লক হয়েছে।',
      footer: 'রিপোর্ট থেকে snapshot দেখা যাবে।',
    );
  }
}

class _CloseCard extends StatelessWidget {
  const _CloseCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.footer,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String footer;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.negative : AppColors.primary;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: danger ? AppColors.negativeLight : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: danger ? AppColors.negative : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(title, style: AppTextStyles.screenTitle),
          const SizedBox(height: 8),
          Text(message, style: AppTextStyles.body),
          const SizedBox(height: 16),
          Text(footer, style: AppTextStyles.bodyStrong.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _MonthlyCloseError extends StatelessWidget {
  const _MonthlyCloseError();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'হিসাব বন্ধ স্ক্রিন লোড করা যায়নি',
        style: AppTextStyles.body,
      ),
    );
  }
}
