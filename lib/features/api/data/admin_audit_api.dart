import 'dart:math';

import '../../../core/api/bazar_api_client.dart';

class AdminAuditApi {
  const AdminAuditApi(this._client);

  final BazarApiClient _client;

  Future<List<AdminAuditEntry>> listEntries() async {
    final data = await _client.get('ledger', 'list', query: {'limit': 100});
    final items = data['items'];
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((item) => AdminAuditEntry.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  Future<AdminAuditReconciliation> reconcile() async {
    final data = await _client.get('ledger', 'reconcile');
    return AdminAuditReconciliation.fromJson(data);
  }

  Future<void> reverse({required String entryId, required String reason}) async {
    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) {
      throw ArgumentError.value(reason, 'reason', 'A reversal reason is required');
    }
    await _client.post(
      'ledger',
      'reverse',
      body: {'originalLedgerEntryId': entryId, 'reason': trimmedReason}, 
      idempotencyKey: 'ledger-reverse-$entryId-${_nonce()}',
    );
  }

  String _nonce() => '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}';
}

class AdminAuditEntry {
  const AdminAuditEntry({
    required this.id,
    required this.type,
    required this.amount,
    required this.signedAmount,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.createdAt,
    required this.entryDate,
    this.note,
    this.reversesLedgerEntryId,
  });

  factory AdminAuditEntry.fromJson(Map<String, dynamic> json) => AdminAuditEntry(
    id: json['id']?.toString() ?? '',
    type: json['type']?.toString() ?? 'unknown',
    amount: _number(json['amount']),
    signedAmount: _number(json['signed_amount']),
    balanceBefore: _number(json['balance_before']),
    balanceAfter: _number(json['balance_after']),
    createdAt: json['created_at']?.toString() ?? '',
    entryDate: json['entry_date']?.toString() ?? '',
    note: json['note']?.toString(),
    reversesLedgerEntryId: json['reverses_ledger_entry_id']?.toString(),
  );

  final String id;
  final String type;
  final double amount;
  final double signedAmount;
  final double balanceBefore;
  final double balanceAfter;
  final String createdAt;
  final String entryDate;
  final String? note;
  final String? reversesLedgerEntryId;

  bool get isReversal => reversesLedgerEntryId != null;
}

class AdminAuditReconciliation {
  const AdminAuditReconciliation({required this.consistent, required this.mismatches});

  factory AdminAuditReconciliation.fromJson(Map<String, dynamic> json) =>
      AdminAuditReconciliation(
        consistent: json['consistent'] == true,
        mismatches: json['mismatches'] is List
            ? List<Map<String, dynamic>>.unmodifiable(
                (json['mismatches'] as List)
                    .whereType<Map>()
                    .map((item) => Map<String, dynamic>.from(item)),
              )
            : const [],
      );

  final bool consistent;
  final List<Map<String, dynamic>> mismatches;
}

double _number(Object? value) => switch (value) {
  num number => number.toDouble(),
  String text => double.tryParse(text) ?? 0,
  _ => 0,
};
