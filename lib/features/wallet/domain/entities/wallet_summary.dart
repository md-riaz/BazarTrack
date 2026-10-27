import 'package:equatable/equatable.dart';

import 'balance_result.dart';
import 'wallet.dart';

class WalletSummary extends Equatable {
  const WalletSummary({
    required this.wallet,
    required this.balance,
    this.accountId,
    this.assistantId,
  });

  final Wallet wallet;
  final BalanceResult balance;
  final String? accountId;
  final String? assistantId;

  @override
  List<Object?> get props => [wallet, balance, accountId, assistantId];
}
