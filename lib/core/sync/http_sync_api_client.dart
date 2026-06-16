import '../api/bazar_api_client.dart';
import 'sync_api_client.dart';
import '../config/api_config.dart';
import 'sync_types.dart';

class HttpSyncApiClient implements SyncApiClient {
  const HttpSyncApiClient({
    required BazarApiClient apiClient,
    required ApiConfig config,
  }) : _apiClient = apiClient,
       _config = config;

  final BazarApiClient _apiClient;
  final ApiConfig _config;

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
        body: {
          'id': request.entityId,
          'closedBy': _actorId(payload['assigned_to'] ?? payload['created_by']),
        },
        idempotencyKey: 'sync-bazar-close-${request.entityId}',
      );
      return;
    }

    await _apiClient.post(
      'bazars',
      'create',
      body: {
        'id': request.entityId,
        'fundId': _fundId(payload['wallet_id']),
        'accountId': _accountId(payload['wallet_id']),
        'title': payload['title'] ?? 'আজকের বাজার',
        'createdBy': _actorId(payload['created_by']),
        'assignedTo': _actorId(payload['assigned_to']),
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
          'accountId': _accountId(payload['wallet_id']),
          'amount': payload['amount'],
          'requestedBy': _actorId(payload['assistant_id']),
          'expectedReceiverId': _actorId(payload['created_by']),
          'note': payload['note'],
        }..removeWhere((_, value) => value == null),
        idempotencyKey: 'sync-return-create-${request.entityId}',
      );
      await _apiClient.post(
        'returns',
        'confirm',
        body: {
          'id': returnId,
          'confirmedBy': _actorId(payload['created_by']),
          'receivedBy': _actorId(payload['created_by']),
          'entryDate': _dateOnly(payload['entry_date']),
        },
        idempotencyKey: 'sync-return-confirm-${request.entityId}',
      );
      return;
    }

    await _apiClient.post(
      'money',
      'give',
      body: {
        'id': request.entityId,
        'accountId': _accountId(payload['wallet_id']),
        'amount': payload['amount'],
        'createdBy': _actorId(payload['created_by']),
        'paidBy': _actorId(payload['created_by']),
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
        'accountId': _accountId(payload['wallet_id'] ?? payload['account_id']),
        'amount': payload['amount'],
        'requestedBy': _actorId(
          payload['requested_by'] ?? payload['assistant_id'],
        ),
        'expectedReceiverId': _actorId(payload['expected_receiver_id']),
        'note': payload['note'],
      }..removeWhere((_, value) => value == null),
      idempotencyKey: 'sync-return-request-${request.entityId}',
    );
  }

  String _fundId(Object? localWalletId) {
    final walletId = localWalletId?.toString();
    if (walletId == null ||
        walletId.isEmpty ||
        walletId == _config.defaultAccountId) {
      return _config.defaultFundId;
    }
    return walletId;
  }

  String _accountId(Object? localWalletId) {
    final walletId = localWalletId?.toString();
    if (walletId == null ||
        walletId.isEmpty ||
        walletId == _config.defaultFundId ||
        walletId.startsWith('w')) {
      return _config.defaultAccountId;
    }
    return walletId;
  }

  String _actorId(Object? localId) {
    return switch (localId?.toString()) {
      null || '' => _config.defaultManagerId,
      'u0' => 'admin1',
      'u1' => _config.defaultAssistantId,
      'u3' => _config.defaultManagerId,
      final value => value,
    };
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
