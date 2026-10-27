import 'dart:convert';
import 'dart:typed_data';

import 'package:bazar/core/api/bazar_api_client.dart';
import 'package:bazar/core/config/api_config.dart';
import 'package:bazar/features/api/data/bazar_api_repositories.dart';
import 'package:bazar/features/bazar/domain/entities/bazar_entities.dart';
import 'package:bazar/shared/models/app_enums.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('create resolves server account then close uses created bazar id', () async {
    final adapter = _JourneyAdapter();
    final client = BazarApiClient(
      config: _config(),
      dio: Dio()..httpClientAdapter = adapter,
    );
    final repository = ApiBazarRepository(client: client, config: _config());

    final created = await repository.createBazar(
      CreateBazarInput(
        walletId: 'fund-server-1',
        createdBy: 'manager-server-1',
        actorId: 'manager-server-1',
        assignedTo: 'assistant-server-1',
        status: BazarStatus.open,
        bazarDate: DateTime.utc(2026, 10, 26),
        items: const [CreateBazarItemInput(name: 'Rice')],
      ),
    );
    final closed = await repository.closeBazar(bazarId: created.id);

    expect(adapter.createBody?['fundId'], 'fund-server-1');
    expect(adapter.createBody?['accountId'], 'account-server-1');
    expect(adapter.createBody?['accountId'], isNot(adapter.createBody?['fundId']));
    expect(adapter.closeBody, {'id': 'bazar-server-1'});
    expect(closed.status, BazarStatus.closed);
  });

  test('uploads a receipt and maps its persisted URL on the item', () async {
    final adapter = _ReceiptAdapter();
    final repository = ApiBazarRepository(
      client: BazarApiClient(
        config: _config(),
        dio: Dio()..httpClientAdapter = adapter,
      ),
      config: _config(),
    );

    final receiptUrl = await repository.uploadReceipt(
      itemId: 'item-server-1',
      imageBytes: Uint8List.fromList([0xff, 0xd8, 0xff, 0xd9]),
    );
    final items = await repository.watchBazarItems('bazar-server-1').first;

    expect(adapter.uploadBody?['id'], 'item-server-1');
    expect(adapter.uploadBody?['imageBase64'], isNotEmpty);
    expect(receiptUrl, 'https://example.test/index.php?cmd=bazars&action=receipt&id=item-server-1');
    expect(
      items.single.receiptUrl,
      'https://example.test/index.php?cmd=bazars&action=receipt&id=item-server-1',
    );
  });

  test('ActiveRecord date objects map without DateTime.now fallback', () async {
    final repository = ApiBazarRepository(
      client: BazarApiClient(
        config: _config(),
        dio: Dio()..httpClientAdapter = _DateAdapter(),
      ),
      config: _config(),
    );

    final bazars = await repository.watchBazars().first;

    expect(bazars.single.createdAt, DateTime.parse('2026-10-26 07:00:00.000000'));
  });
}

ApiConfig _config() => ApiConfig(
  environment: AppEnvironment.test,
  enabled: true,
  baseUrl: 'https://example.test/index.php',
  defaultFundId: 'unused-fund',
  defaultAccountId: 'unused-account',
  defaultManagerId: 'unused-manager',
  defaultAssistantId: 'unused-assistant',
);

class _JourneyAdapter implements HttpClientAdapter {
  Map<String, dynamic>? createBody;
  Map<String, dynamic>? closeBody;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? requestStream, Future<void>? cancelFuture) async {
    final action = options.queryParameters['action'];
    if (action == 'list') return _json({'data': [{'id': 'account-server-1', 'fund_id': 'fund-server-1'}]});
    if (action == 'create') {
      createBody = Map<String, dynamic>.from(options.data as Map);
      return _json({'data': {'bazar': _bazar('open'), 'items': []}});
    }
    closeBody = Map<String, dynamic>.from(options.data as Map);
    return _json({'data': {'bazar': _bazar('closed')}});
  }

  @override
  void close({bool force = false}) {}
}

class _ReceiptAdapter implements HttpClientAdapter {
  Map<String, dynamic>? uploadBody;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? requestStream, Future<void>? cancelFuture) async {
    final action = options.queryParameters['action'];
    if (action == 'uploadReceipt') {
      uploadBody = Map<String, dynamic>.from(options.data as Map);
      return _json({'data': {'receiptUrl': 'storage/uploads/receipts/a.jpg'}});
    }
    return _json({
      'data': {
        'bazar': _bazar('open'),
        'items': [
          {
            'id': 'item-server-1',
            'bazar_id': 'bazar-server-1',
            'name': 'Rice',
            'status': 'done',
            'price': 200,
            'receipt_url': 'storage/uploads/receipts/a.jpg',
            'created_at': '2026-10-26 07:00:00',
            'updated_at': '2026-10-26 07:00:00',
          },
        ],
      },
    });
  }

  @override
  void close({bool force = false}) {}
}

class _DateAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? requestStream, Future<void>? cancelFuture) async {
    final bazar = _bazar('open')
      ..['created_at'] = {'date': '2026-10-26 07:00:00.000000'}
      ..['updated_at'] = {'date': '2026-10-26 07:00:00.000000'};
    return _json({'data': [bazar]});
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _bazar(String status) => {
  'id': 'bazar-server-1',
  'fund_id': 'fund-server-1',
  'account_id': 'account-server-1',
  'created_by': 'manager-server-1',
  'assigned_to': 'assistant-server-1',
  'title': 'Office bazar',
  'status': status,
  'bazar_date': '2026-10-26',
  'created_at': '2026-10-26 07:00:00',
  'updated_at': '2026-10-26 07:00:00',
  if (status == 'closed') 'closed_at': '2026-10-26 08:00:00',
};

ResponseBody _json(Object body) => ResponseBody.fromString(
  jsonEncode(body),
  200,
  headers: {Headers.contentTypeHeader: ['application/json']},
);
