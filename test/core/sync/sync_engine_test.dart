import 'package:bazar/core/database/app_database.dart';
import 'package:bazar/core/sync/connectivity_service.dart';
import 'package:bazar/core/sync/sync_api_client.dart';
import 'package:bazar/core/sync/sync_engine.dart';
import 'package:bazar/core/sync/sync_enqueue_service.dart';
import 'package:bazar/core/sync/sync_mappers.dart';
import 'package:bazar/core/sync/sync_queue_dao.dart';
import 'package:bazar/core/sync/sync_types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late SyncQueueDao queueDao;
  late ManualConnectivityService connectivity;
  late SinkSyncApiClient apiClient;
  late SyncEngine engine;

  setUp(() {
    database = AppDatabase.forTesting();
    queueDao = SyncQueueDao(database);
    connectivity = ManualConnectivityService();
    apiClient = SinkSyncApiClient();
    engine = SyncEngine(
      queueDao: queueDao,
      apiClient: apiClient,
      connectivityService: connectivity,
    );
  });

  tearDown(() async {
    await connectivity.dispose();
    await database.close();
  });

  test('enqueue service persists JSON operation in sync_queue', () async {
    final enqueue = SyncEnqueueService(queueDao);

    await enqueue.enqueue(
      entityType: 'money_entry',
      entityId: 'm1',
      operation: SyncOperation.create,
      payload: {'id': 'm1', 'amount': 500},
      createdAt: DateTime(2026, 5, 24),
    );

    final pending = await queueDao.pending();

    expect(pending, hasLength(1));
    expect(pending.first.entityType, 'money_entry');
    expect(pending.first.operation, 'create');
    expect(pending.first.payload, contains('"amount":500'));
    expect(pending.first.isSynced, isFalse);
  });

  test('sync engine leaves queue pending while offline', () async {
    connectivity.setOnline(false);
    await queueDao.enqueue(
      entityType: 'bazar',
      entityId: 'b1',
      operation: 'create',
      payload: '{"id":"b1"}',
      createdAt: DateTime(2026, 5, 24),
    );

    final result = await engine.syncPending();

    expect(result.offline, isTrue);
    expect(result.attempted, 0);
    expect(apiClient.sent, isEmpty);
    expect(await queueDao.pendingCount(), 1);
  });

  test('sync engine sends pending items and marks them synced', () async {
    await queueDao.enqueue(
      entityType: 'bazar_item',
      entityId: 'i1',
      operation: 'update',
      payload: '{"id":"i1","price":120}',
      createdAt: DateTime(2026, 5, 24),
    );

    final result = await engine.syncPending();

    expect(result.attempted, 1);
    expect(result.synced, 1);
    expect(result.failed, 0);
    expect(apiClient.sent.single.entityType, 'bazar_item');
    expect(apiClient.sent.single.operation, SyncOperation.update);
    expect(apiClient.sent.single.payload['price'], 120);
    expect(await queueDao.pendingCount(), 0);
  });

  test('sync engine records failure and increments retry count', () async {
    final failingEngine = SyncEngine(
      queueDao: queueDao,
      apiClient: _FailingSyncApiClient(),
      connectivityService: connectivity,
    );
    await queueDao.enqueue(
      entityType: 'direct_expense',
      entityId: 'd1',
      operation: 'create',
      payload: '{"id":"d1"}',
      createdAt: DateTime(2026, 5, 24),
    );

    final result = await failingEngine.syncPending();
    final pending = await queueDao.pending();

    expect(result.failed, 1);
    expect(pending.single.retryCount, 1);
    expect(pending.single.lastError, contains('network down'));
  });

  test('drift rows map to API payloads with server field names', () async {
    final now = DateTime(2026, 5, 24, 9, 30);
    final money = MoneyEntry(
      id: 'm1',
      walletId: 'w1',
      assistantId: 'u1',
      bazarId: 'b1',
      type: 'money_received',
      amount: 1000,
      note: 'advance',
      entryDate: now,
      createdBy: 'u2',
      createdAt: now,
      updatedAt: now,
      isLocked: false,
    );
    final item = BazarItem(
      id: 'i1',
      bazarId: 'b1',
      name: 'চাল',
      rawText: null,
      quantity: 2,
      unit: 'kg',
      attributes: null,
      note: null,
      status: 'done',
      price: 140,
      addedBy: 'u1',
      createdAt: now,
      updatedAt: now,
    );

    expect(moneyEntryToApi(money), containsPair('assistant_id', 'u1'));
    expect(
      moneyEntryToApi(money),
      containsPair('entry_date', now.toIso8601String()),
    );
    expect(bazarItemToApi(item), containsPair('bazar_id', 'b1'));
    expect(bazarItemToApi(item), containsPair('price', 140));
  });
}

class _FailingSyncApiClient implements SyncApiClient {
  @override
  Future<void> send(SyncRequest request) async {
    throw const SyncFailure('network down');
  }
}
