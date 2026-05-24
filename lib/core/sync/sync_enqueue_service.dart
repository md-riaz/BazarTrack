import 'dart:convert';

import 'sync_queue_dao.dart';
import 'sync_types.dart';

class SyncEnqueueService {
  const SyncEnqueueService(this._queueDao);

  final SyncQueueDao _queueDao;

  Future<int> enqueue({
    required String entityType,
    required String entityId,
    required SyncOperation operation,
    required Map<String, dynamic> payload,
    DateTime? createdAt,
  }) {
    return _queueDao.enqueue(
      entityType: entityType,
      entityId: entityId,
      operation: operation.wireName,
      payload: jsonEncode(payload),
      createdAt: createdAt,
    );
  }
}
