import '../../../helper/date_converter.dart';

class Advance {
  final double amount;
  final DateTime? date;
  final String givenBy;
  final String receivedBy;

  Advance({
    required this.amount,
    this.date,
    required this.givenBy,
    required this.receivedBy,
  });

  factory Advance.fromJson(Map<String, dynamic> json) => Advance(
    amount: _parseDouble(json['amount']),
    date: DateConverter.parseApiDate(json['date'] ?? json['created_at'] ?? json['createdAt']),
    givenBy: (json['givenBy'] ?? json['given_by'] ?? json['given_by_name'] ?? '').toString(),
    receivedBy: (json['receivedBy'] ?? json['received_by'] ?? json['received_by_name'] ?? '').toString(),
  );

  Map<String, dynamic> toJson() => {
    'amount': amount,
    'date': date != null ? DateConverter.formatApiDate(date!) : null,
    'givenBy': givenBy,
    'receivedBy': receivedBy,
  };

  // helper
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    final s = value.toString();
    return double.tryParse(s) ?? 0.0;
  }
}
