import 'package:equatable/equatable.dart';

class WalletSnapshot extends Equatable {
  const WalletSnapshot({
    required this.id,
    required this.walletId,
    required this.periodMonth,
    required this.openingBalance,
    required this.closingBalance,
    required this.closedAt,
    this.assistantId,
    this.snapshotHash,
    this.closedBy,
    this.notes,
  });

  final String id;
  final String walletId;
  final String? assistantId;
  final String periodMonth;
  final double openingBalance;
  final double closingBalance;
  final String? snapshotHash;
  final String? closedBy;
  final DateTime closedAt;
  final String? notes;

  @override
  List<Object?> get props => [
    id,
    walletId,
    assistantId,
    periodMonth,
    openingBalance,
    closingBalance,
    snapshotHash,
    closedBy,
    closedAt,
    notes,
  ];
}
