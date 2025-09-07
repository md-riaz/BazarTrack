// File: lib/features/wallet/model/wallet_transaction.dart

import '../../../helper/date_converter.dart';

enum TransactionType { credit, debit }

class WalletTransaction {
  final double amount;
  final TransactionType type;
  final DateTime? createdAt;
  final String description;

  WalletTransaction({
    required this.amount,
    required this.type,
    this.createdAt,
    required this.description,
  });

  WalletTransaction.fromJson(Map<String, dynamic> json)
      : amount = _parseDouble(json['amount']),
        type = _parseType(json['type']),
        createdAt = DateConverter.parseApiDate(
          json['created_at'] ??
              json['createdAt'] ??
              json['date'] ??
              json['timestamp'],
        ),
        description = (json['description'] ?? json['note'] ?? '').toString();

  Map<String, dynamic> toJson() => {
    'amount': amount,
    'type': type == TransactionType.debit ? 'debit' : 'credit',
    'created_at': createdAt != null ? DateConverter.formatApiDate(createdAt!) : null,
    'description': description,
  };

  // helpers
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    final s = value.toString();
    return double.tryParse(s) ?? 0.0;
  }

  static TransactionType _parseType(dynamic value) {
    if (value == null) return TransactionType.credit;
    final s = value.toString().toLowerCase().trim();
    if (s == 'debit' || s == 'd') return TransactionType.debit;
    return TransactionType.credit;
  }
}
