import '../../../../shared/models/app_enums.dart';

class MoneyEntry {
  const MoneyEntry({
    required this.id,
    required this.walletId,
    required this.assistantId,
    required this.type,
    required this.amount,
    required this.entryDate,
    required this.createdAt,
    required this.updatedAt,
    this.walletName,
    this.assistantName,
    this.bazarId,
    this.note,
    this.createdBy,
    this.isLocked = false,
  });

  final String id;
  final String walletId;
  final String? walletName;
  final String assistantId;
  final String? assistantName;
  final String? bazarId;
  final EntryType type;
  final double amount;
  final String? note;
  final DateTime entryDate;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isLocked;

  String get label {
    return switch (type) {
      EntryType.moneyReceived => 'টাকা নিলাম',
      EntryType.moneyReturned => 'টাকা ফেরত দিলাম',
      EntryType.adjustment => 'সমন্বয়',
    };
  }

  double get signedAmount {
    return switch (type) {
      EntryType.moneyReceived => amount.abs(),
      EntryType.moneyReturned => -amount.abs(),
      EntryType.adjustment => amount,
    };
  }
}

String entryTypeToDb(EntryType type) {
  return switch (type) {
    EntryType.moneyReceived => 'money_received',
    EntryType.moneyReturned => 'money_returned',
    EntryType.adjustment => 'adjustment',
  };
}

EntryType entryTypeFromDb(String value) {
  return switch (value) {
    'money_returned' => EntryType.moneyReturned,
    'adjustment' => EntryType.adjustment,
    _ => EntryType.moneyReceived,
  };
}
