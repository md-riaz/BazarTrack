import 'package:equatable/equatable.dart';

import 'balance_result.dart';
import 'wallet.dart';

class WalletSummary extends Equatable {
  const WalletSummary({required this.wallet, required this.balance});

  final Wallet wallet;
  final BalanceResult balance;

  @override
  List<Object?> get props => [wallet, balance];
}
