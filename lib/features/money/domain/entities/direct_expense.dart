class DirectExpense {
  const DirectExpense({
    required this.id,
    required this.walletId,
    required this.assistantId,
    required this.amount,
    required this.entryDate,
    required this.createdAt,
    this.walletName,
    this.assistantName,
    this.note,
    this.receiptUrl,
    this.createdBy,
    this.isLocked = false,
  });

  final String id;
  final String walletId;
  final String? walletName;
  final String assistantId;
  final String? assistantName;
  final double amount;
  final String? note;
  final DateTime entryDate;
  final String? receiptUrl;
  final String? createdBy;
  final DateTime createdAt;
  final bool isLocked;
}
