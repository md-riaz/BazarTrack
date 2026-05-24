import 'package:equatable/equatable.dart';

class BalanceResult extends Equatable {
  const BalanceResult({
    required this.walletId,
    required this.confirmedBalance,
    required this.inProgressAmount,
    this.assistantId,
    this.snapshotBase = 0,
  });

  final String walletId;
  final String? assistantId;
  final double confirmedBalance;
  final double inProgressAmount;
  final double snapshotBase;

  double get estimatedBalance => confirmedBalance + inProgressAmount;

  bool get isPositive => estimatedBalance > 0;

  bool get isNegative => estimatedBalance < 0;

  bool get isSettled => estimatedBalance == 0;

  String get label {
    if (isSettled) {
      return 'হিসাব মিলে গেছে ✓';
    }
    return isPositive ? 'হাতে আছে' : 'পাওনা আছে — দিতে হবে';
  }

  @override
  List<Object?> get props => [
    walletId,
    assistantId,
    confirmedBalance,
    inProgressAmount,
    snapshotBase,
  ];
}
