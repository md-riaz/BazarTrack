import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/app_bar.dart';
import '../../domain/entities/wallet_ledger_entry.dart';
import '../providers/wallet_providers.dart';

class AssistantLedgerScreen extends ConsumerWidget {
  const AssistantLedgerScreen({
    required this.walletId,
    required this.assistantId,
    super.key,
  });

  final String walletId;
  final String assistantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = WalletBalanceRequest(
      walletId: walletId,
      assistantId: assistantId,
    );
    final ledger = ref.watch(walletLedgerProvider(request));
    final balance = ref.watch(walletBalanceProvider(request));

    return Scaffold(
      backgroundColor: AppColors.surface2,
      appBar: BazarAppBar(
        title: 'সহকারী লেজার',
        subtitle: 'ডাবল-এন্ট্রি হিসাব',
        leading: Navigator.canPop(context)
            ? IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              )
            : null,
      ),
      body: ledger.when(
        data: (entries) => balance.when(
          data: (value) => _AssistantLedgerContent(
            entries: entries,
            balance: value.estimatedBalance,
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => const _LedgerError(),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const _LedgerError(),
      ),
    );
  }
}

class _AssistantLedgerContent extends StatelessWidget {
  const _AssistantLedgerContent({required this.entries, required this.balance});

  final List<WalletLedgerEntry> entries;
  final double balance;

  @override
  Widget build(BuildContext context) {
    var runningBalance = 0.0;
    final chronological = entries.reversed.toList(growable: false);
    final rows = <_LedgerRow>[];
    for (final entry in chronological) {
      runningBalance += entry.amount;
      rows.add(_LedgerRow(entry: entry, runningBalance: runningBalance));
    }
    final displayRows = rows.reversed.toList(growable: false);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.account_balance_wallet,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'বর্তমান ব্যালেন্স',
                  style: AppTextStyles.bodyStrong,
                ),
              ),
              Text(
                CurrencyFormatter.format(balance),
                style: AppTextStyles.bodyStrong.copyWith(
                  color: balance < 0 ? AppColors.negative : AppColors.positive,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              const _TableHeader(),
              if (displayRows.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('লেনদেন নেই', style: AppTextStyles.body),
                )
              else
                for (final row in displayRows) _TableRow(row: row),
            ],
          ),
        ),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('বিবরণ', style: AppTextStyles.label)),
          Expanded(
            child: Text(
              'ডেবিট',
              style: AppTextStyles.label,
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            child: Text(
              'ক্রেডিট',
              style: AppTextStyles.label,
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            child: Text(
              'ব্যালেন্স',
              style: AppTextStyles.label,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({required this.row});

  final _LedgerRow row;

  @override
  Widget build(BuildContext context) {
    final entry = row.entry;
    final debit = entry.amount < 0 ? entry.amount.abs() : 0;
    final credit = entry.amount > 0 ? entry.amount : 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.label, style: AppTextStyles.bodyStrong),
                const SizedBox(height: 2),
                Text(
                  [entry.note, entry.assistantName]
                      .where((value) => value != null && value.isNotEmpty)
                      .join(' • '),
                  style: AppTextStyles.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              debit == 0
                  ? '—'
                  : CurrencyFormatter.format(debit, includeSymbol: false),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.negative,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            child: Text(
              credit == 0
                  ? '—'
                  : CurrencyFormatter.format(credit, includeSymbol: false),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.positive,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            child: Text(
              CurrencyFormatter.format(
                row.runningBalance,
                includeSymbol: false,
              ),
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _LedgerRow {
  const _LedgerRow({required this.entry, required this.runningBalance});

  final WalletLedgerEntry entry;
  final double runningBalance;
}

class _LedgerError extends StatelessWidget {
  const _LedgerError();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('লেজার লোড করা যায়নি', style: AppTextStyles.body),
    );
  }
}
