import 'dart:convert';

import '../database/app_database.dart';

enum SyncOperation { create, update, delete }

extension SyncOperationWire on SyncOperation {
  String get wireName => switch (this) {
    SyncOperation.create => 'create',
    SyncOperation.update => 'update',
    SyncOperation.delete => 'delete',
  };

  static SyncOperation parse(String value) {
    return switch (value) {
      'create' => SyncOperation.create,
      'update' => SyncOperation.update,
      'delete' => SyncOperation.delete,
      _ => throw FormatException('Unknown sync operation: $value'),
    };
  }
}

class SyncRequest {
  const SyncRequest({
    required this.queueId,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payload,
    required this.createdAt,
    required this.retryCount,
  });

  final int queueId;
  final String entityType;
  final String entityId;
  final SyncOperation operation;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retryCount;

  factory SyncRequest.fromQueueItem(SyncQueueItem item) {
    final decoded = jsonDecode(item.payload);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Sync queue payload must be a JSON object');
    }

    return SyncRequest(
      queueId: item.id,
      entityType: item.entityType,
      entityId: item.entityId,
      operation: SyncOperationWire.parse(item.operation),
      payload: decoded,
      createdAt: item.createdAt,
      retryCount: item.retryCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'queue_id': queueId,
      'entity_type': entityType,
      'entity_id': entityId,
      'operation': operation.wireName,
      'payload': payload,
      'created_at': createdAt.toIso8601String(),
      'retry_count': retryCount,
    };
  }
}

class SyncRunResult {
  const SyncRunResult({
    required this.attempted,
    required this.synced,
    required this.failed,
    required this.offline,
  });

  final int attempted;
  final int synced;
  final int failed;
  final bool offline;

  bool get isComplete => !offline && failed == 0;
}

class SyncFailure implements Exception {
  const SyncFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
