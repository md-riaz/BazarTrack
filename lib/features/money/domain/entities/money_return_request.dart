class MoneyReturnRequest {
  const MoneyReturnRequest({
    required this.id,
    required this.accountId,
    required this.assistantId,
    required this.amount,
    required this.status,
    required this.requestedAt,
    this.note,
  });

  final String id;
  final String accountId;
  final String assistantId;
  final double amount;
  final String status;
  final DateTime requestedAt;
  final String? note;
}
