import 'dart:convert';

import 'package:bazar/core/api/bazar_api_client.dart';
import 'package:bazar/core/config/api_config.dart';
import 'package:bazar/features/api/data/admin_audit_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads ledger and reconciliation then reverses with a reason', () async {
    final adapter = _AuditAdapter();
    final api = AdminAuditApi(
      BazarApiClient(config: _config(), dio: Dio()..httpClientAdapter = adapter),
    );

    final entries = await api.listEntries();
    final reconciliation = await api.reconcile();
    await api.reverse(entryId: 'ledger-1', reason: 'Duplicate cash entry');

    expect(entries.single.id, 'ledger-1');
    expect(entries.single.balanceAfter, 1000);
    expect(reconciliation.consistent, isTrue);
    expect(adapter.reverseBody, {
      'originalLedgerEntryId': 'ledger-1',
      'reason': 'Duplicate cash entry',
    });
    expect(adapter.reverseIdempotencyKey, startsWith('ledger-reverse-ledger-1-'));
  });
}

ApiConfig _config() => ApiConfig(
  environment: AppEnvironment.test,
  enabled: true,
  baseUrl: 'https://example.test/index.php',
  defaultFundId: 'fund',
  defaultAccountId: 'account',
  defaultManagerId: 'manager',
  defaultAssistantId: 'assistant',
);

class _AuditAdapter implements HttpClientAdapter {
  Map<String, dynamic>? reverseBody;
  String? reverseIdempotencyKey;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final action = options.queryParameters['action'];
    if (action == 'list') {
      return _json({
        'data': [
          {
            'id': 'ledger-1',
            'type': 'fund_gave_money',
            'amount': 1000,
            'signed_amount': 1000,
            'balance_before': 0,
            'balance_after': 1000,
            'created_at': '2026-11-03 12:00:00',
            'entry_date': '2026-11-03',
          },
        ],
      });
    }
    if (action == 'reconcile' && options.method == 'GET') {
      return _json({'data': {'consistent': true, 'accounts': [], 'mismatches': []}});
    }
    if (action == 'reverse') {
      reverseBody = Map<String, dynamic>.from(options.data as Map);
      reverseIdempotencyKey = options.headers['Idempotency-Key']?.toString();
      return _json({'data': {'reversal': {'id': 'ledger-2'}}});
    }
    throw StateError('Unexpected request: $action');
  }
}

ResponseBody _json(Object data) => ResponseBody.fromString(
  jsonEncode(data),
  200,
  headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
);
