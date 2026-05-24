import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/app_bar.dart';
import '../../domain/entities/balance_result.dart';
import '../../domain/entities/wallet.dart' as wallet_domain;
import '../../domain/entities/wallet_ledger_entry.dart';
import '../providers/wallet_providers.dart';

class WalletDetailScreen extends ConsumerWidget {
  const WalletDetailScreen({
    required this.walletId,
    super.key,
    this.assistantId,
  });

  final String walletId;
  final String? assistantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider(walletId));
    final balance = ref.watch(
      walletBalanceProvider(
        WalletBalanceRequest(walletId: walletId, assistantId: assistantId),
      ),
    );
    final ledger = ref.watch(
      walletLedgerProvider(
        WalletBalanceRequest(walletId: walletId, assistantId: assistantId),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.surface2,
      appBar: BazarAppBar(
        title: wallet.maybeWhen(
          data: (value) => value?.name ?? 'ওয়ালেট',
          orElse: () => 'ওয়ালেট',
        ),
        leading: Navigator.canPop(context)
            ? IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              )
            : null,
      ),
      body: wallet.when(
        data: (walletValue) => balance.when(
          data: (balanceValue) => ledger.when(
            data: (entries) => _WalletDetailContent(
              wallet: walletValue,
              balance: balanceValue,
              entries: entries,
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => const _WalletError(),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => const _WalletError(),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const _WalletError(),
      ),
    );
  }
}

class _WalletDetailContent extends StatelessWidget {
  const _WalletDetailContent({
    required this.wallet,
    required this.balance,
    required this.entries,
  });

  final wallet_domain.Wallet? wallet;
  final BalanceResult balance;
  final List<WalletLedgerEntry> entries;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _BalanceHeader(wallet: wallet, balance: balance),
        const SizedBox(height: 16),
        Row(
          children: [
            Text('লেনদেন', style: AppTextStyles.screenTitle),
            const Spacer(),
            Text('লকড এন্ট্রি বদলানো যাবে না', style: AppTextStyles.bodySmall),
          ],
        ),
        const SizedBox(height: 10),
        if (entries.isEmpty)
          const _EmptyLedger()
        else
          for (final entry in entries) _LedgerTile(entry: entry),
      ],
    );
  }
}

class _BalanceHeader extends StatelessWidget {
  const _BalanceHeader({required this.wallet, required this.balance});

  final wallet_domain.Wallet? wallet;
  final BalanceResult balance;

  @override
  Widget build(BuildContext context) {
    final cardColor = balance.isSettled
        ? AppColors.neutralCard
        : balance.isPositive
        ? AppColors.positiveCard
        : AppColors.negativeCard;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            wallet?.name ?? 'ওয়ালেট',
            style: AppTextStyles.bodyStrong.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            balance.label,
            style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 18),
          Text(
            CurrencyFormatter.format(balance.estimatedBalance),
            style: AppTextStyles.walletAmount,
          ),
          const SizedBox(height: 12),
          Text(
            'নিশ্চিত ${CurrencyFormatter.format(balance.confirmedBalance)}  •  চলমান ${CurrencyFormatter.format(balance.inProgressAmount)}',
            style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _LedgerTile extends StatelessWidget {
  const _LedgerTile({required this.entry});

  final WalletLedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = _entryColors(entry.type);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colors.background,
              shape: BoxShape.circle,
            ),
            child: Icon(colors.icon, color: colors.foreground, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(entry.label, style: AppTextStyles.bodyStrong),
                    ),
                    if (entry.isLocked) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.lock, size: 14, color: AppColors.text4),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  [entry.assistantName, entry.note]
                      .where((value) => value != null && value.isNotEmpty)
                      .join(' • '),
                  style: AppTextStyles.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            CurrencyFormatter.format(entry.amount),
            style: AppTextStyles.bodyStrong.copyWith(color: colors.foreground),
          ),
        ],
      ),
    );
  }

  _EntryColors _entryColors(WalletLedgerEntryType type) {
    return switch (type) {
      WalletLedgerEntryType.moneyReceived => const _EntryColors(
        AppColors.positive,
        AppColors.positiveLight,
        Icons.payments,
      ),
      WalletLedgerEntryType.bazarExpense => const _EntryColors(
        AppColors.negative,
        AppColors.negativeLight,
        Icons.shopping_basket,
      ),
      WalletLedgerEntryType.directExpense => const _EntryColors(
        AppColors.negative,
        AppColors.negativeLight,
        Icons.receipt_long,
      ),
      WalletLedgerEntryType.moneyReturned => const _EntryColors(
        AppColors.warning,
        AppColors.warningLight,
        Icons.keyboard_return,
      ),
      WalletLedgerEntryType.adjustment => const _EntryColors(
        AppColors.primary,
        AppColors.primaryLight,
        Icons.tune,
      ),
    };
  }
}

class _EntryColors {
  const _EntryColors(this.foreground, this.background, this.icon);

  final Color foreground;
  final Color background;
  final IconData icon;
}

class _EmptyLedger extends StatelessWidget {
  const _EmptyLedger();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Text('এখনও কোনো লেনদেন নেই', style: AppTextStyles.body),
    );
  }
}

class _WalletError extends StatelessWidget {
  const _WalletError();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('ওয়ালেট লোড করা যায়নি', style: AppTextStyles.body),
    );
  }
}
