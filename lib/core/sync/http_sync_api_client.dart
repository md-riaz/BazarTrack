import '../api/bazar_api_client.dart';
import 'sync_api_client.dart';
import 'sync_types.dart';

class HttpSyncApiClient implements SyncApiClient {
  const HttpSyncApiClient({required BazarApiClient apiClient, Object? config})
    : _apiClient = apiClient;

  final BazarApiClient _apiClient;

  @override
  Future<void> send(SyncRequest request) async {
    switch (request.entityType) {
      case 'bazar':
        await _sendBazar(request);
      case 'bazar_item':
        await _sendBazarItem(request);
      case 'money_entry':
        await _sendMoneyEntry(request);
      case 'money_return_request':
        await _sendReturnRequest(request);
      case 'direct_expense':
        throw const SyncFailure('Direct expense is not supported by fund API');
      default:
        throw SyncFailure('Unsupported sync entity: ${request.entityType}');
    }
  }

  Future<void> _sendBazar(SyncRequest request) async {
    final payload = request.payload;
    final closed =
        payload['status'] == 'closed' || payload['closed_at'] != null;
    if (closed || request.operation == SyncOperation.update) {
      await _apiClient.post(
        'bazars',
        'close',
        body: {'id': request.entityId},
        idempotencyKey: 'sync-bazar-close-${request.entityId}',
      );
      return;
    }

    await _apiClient.post(
      'bazars',
      'create',
      body: {
        'id': request.entityId,
        'fundId': payload['fund_id'] ?? payload['wallet_id'],
        'accountId': payload['account_id'],
        'title': payload['title'] ?? 'আজকের বাজার',
        'assignedTo': payload['assigned_to'],
        'status': payload['status'] ?? 'open',
        'bazarDate': _dateOnly(payload['bazar_date']),
      }..removeWhere((_, value) => value == null),
      idempotencyKey: 'sync-bazar-create-${request.entityId}',
    );
  }

  Future<void> _sendBazarItem(SyncRequest request) async {
    final payload = request.payload;
    final body = {
      'id': request.entityId,
      'bazarId': payload['bazar_id'],
      'name': payload['name'],
      'quantity': payload['quantity']?.toString(),
      'price': payload['price'],
      'status': _itemStatus(payload['status']),
      'note': payload['note'],
    }..removeWhere((_, value) => value == null);

    if (request.operation == SyncOperation.create) {
      await _apiClient.post(
        'bazars',
        'addItem',
        body: body,
        idempotencyKey: 'sync-item-create-${request.entityId}',
      );
      return;
    }

    await _apiClient.post(
      'bazars',
      'updateItem',
      body: body,
      idempotencyKey: 'sync-item-update-${request.entityId}',
    );
  }

  Future<void> _sendMoneyEntry(SyncRequest request) async {
    final payload = request.payload;
    final type = payload['type']?.toString();
    if (type == 'money_returned') {
      final returnId = 'return-${request.entityId}';
      await _apiClient.post(
        'returns',
        'create',
        body: {
          'id': returnId,
          'accountId': payload['account_id'] ?? payload['wallet_id'],
          'amount': payload['amount'],
          'note': payload['note'],
        }..removeWhere((_, value) => value == null),
        idempotencyKey: 'sync-return-create-${request.entityId}',
      );
      return;
    }

    await _apiClient.post(
      'money',
      'give',
      body: {
        'id': request.entityId,
        'accountId': payload['account_id'] ?? payload['wallet_id'],
        'amount': payload['amount'],
        'note': payload['note'],
        'entryDate': _dateOnly(payload['entry_date']),
      }..removeWhere((_, value) => value == null),
      idempotencyKey: 'sync-money-${request.entityId}',
    );
  }

  Future<void> _sendReturnRequest(SyncRequest request) async {
    final payload = request.payload;
    await _apiClient.post(
      'returns',
      'create',
      body: {
        'id': request.entityId,
        'accountId': payload['account_id'] ?? payload['wallet_id'],
        'amount': payload['amount'],
        'note': payload['note'],
      }..removeWhere((_, value) => value == null),
      idempotencyKey: 'sync-return-request-${request.entityId}',
    );
  }

  String? _dateOnly(Object? value) {
    final text = value?.toString();
    if (text == null || text.isEmpty) return null;
    return text.split('T').first.split(' ').first;
  }

  String? _itemStatus(Object? value) {
    return switch (value?.toString()) {
      'notFound' || 'not_found' => 'not_found',
      final text => text,
    };
  }
}
