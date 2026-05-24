import 'package:drift/drift.dart';

import '../database/app_database.dart';

class SyncQueueDao {
  const SyncQueueDao(this._database);

  final AppDatabase _database;

  Future<int> enqueue({
    required String entityType,
    required String entityId,
    required String operation,
    required String payload,
    DateTime? createdAt,
  }) {
    return _database
        .into(_database.syncQueueItems)
        .insert(
          SyncQueueItemsCompanion.insert(
            entityType: entityType,
            entityId: entityId,
            operation: operation,
            payload: payload,
            createdAt: createdAt ?? DateTime.now(),
          ),
        );
  }

  Future<List<SyncQueueItem>> pending({int limit = 25}) {
    return (_database.select(_database.syncQueueItems)
          ..where((row) => row.isSynced.equals(false))
          ..orderBy([
            (row) =>
                OrderingTerm(expression: row.createdAt, mode: OrderingMode.asc),
            (row) => OrderingTerm(expression: row.id, mode: OrderingMode.asc),
          ])
          ..limit(limit))
        .get();
  }

  Stream<List<SyncQueueItem>> watchPending() {
    return (_database.select(_database.syncQueueItems)
          ..where((row) => row.isSynced.equals(false))
          ..orderBy([
            (row) =>
                OrderingTerm(expression: row.createdAt, mode: OrderingMode.asc),
            (row) => OrderingTerm(expression: row.id, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  Future<int> pendingCount() async {
    final count = _database.syncQueueItems.id.count();
    final query = _database.selectOnly(_database.syncQueueItems)
      ..addColumns([count])
      ..where(_database.syncQueueItems.isSynced.equals(false));
    return (await query.getSingle()).read(count) ?? 0;
  }

  Future<void> markSynced(int id) async {
    await (_database.update(
      _database.syncQueueItems,
    )..where((row) => row.id.equals(id))).write(
      const SyncQueueItemsCompanion(
        isSynced: Value(true),
        lastError: Value(null),
      ),
    );
  }

  Future<void> markFailed(int id, Object error) async {
    final row = await (_database.select(
      _database.syncQueueItems,
    )..where((item) => item.id.equals(id))).getSingle();

    await (_database.update(
      _database.syncQueueItems,
    )..where((item) => item.id.equals(id))).write(
      SyncQueueItemsCompanion(
        retryCount: Value(row.retryCount + 1),
        lastError: Value(error.toString()),
      ),
    );
  }
}
