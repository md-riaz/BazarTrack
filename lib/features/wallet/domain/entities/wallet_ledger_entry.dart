import 'package:equatable/equatable.dart';

enum WalletLedgerEntryType {
  moneyReceived,
  bazarExpense,
  directExpense,
  moneyReturned,
  adjustment,
}

class WalletLedgerEntry extends Equatable {
  const WalletLedgerEntry({
    required this.id,
    required this.walletId,
    required this.assistantId,
    required this.type,
    required this.amount,
    required this.date,
    required this.isLocked,
    this.bazarId,
    this.assistantName,
    this.note,
  });

  final String id;
  final String walletId;
  final String assistantId;
  final String? assistantName;
  final String? bazarId;
  final WalletLedgerEntryType type;
  final double amount;
  final String? note;
  final DateTime date;
  final bool isLocked;

  String get label {
    return switch (type) {
      WalletLedgerEntryType.moneyReceived => 'টাকা নিলাম',
      WalletLedgerEntryType.bazarExpense => 'বাজার খরচ',
      WalletLedgerEntryType.directExpense => 'সরাসরি খরচ',
      WalletLedgerEntryType.moneyReturned => 'ফেরত দিলাম',
      WalletLedgerEntryType.adjustment => 'সমন্বয়',
    };
  }

  @override
  List<Object?> get props => [
    id,
    walletId,
    assistantId,
    assistantName,
    bazarId,
    type,
    amount,
    note,
    date,
    isLocked,
  ];
}
