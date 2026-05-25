import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/sync/sync_providers.dart';
import '../../domain/entities/offline_queue_entry.dart';

final settingsNotificationProvider = StateProvider<bool>((ref) => true);
final settingsSoundProvider = StateProvider<bool>((ref) => false);
final settingsBanglaProvider = StateProvider<bool>((ref) => true);

final offlineQueueEntriesProvider = StreamProvider<List<OfflineQueueEntry>>((
  ref,
) {
  return ref
      .watch(syncQueueDaoProvider)
      .watchPending()
      .map((items) => items.map(_mapQueueItem).toList(growable: false));
});

final offlineQueueFailedCountProvider = Provider<AsyncValue<int>>((ref) {
  return ref
      .watch(offlineQueueEntriesProvider)
      .whenData(
        (entries) => entries
            .where((entry) => entry.status == OfflineQueueStatus.failed)
            .length,
      );
});

final offlineQueueRetryControllerProvider =
    Provider<OfflineQueueRetryController>((ref) {
      return OfflineQueueRetryController(ref);
    });

class OfflineQueueRetryController {
  const OfflineQueueRetryController(this._ref);

  final Ref _ref;

  Future<void> retryAll() async {
    await _ref.read(syncStatusProvider.notifier).syncNow();
  }
}

OfflineQueueEntry _mapQueueItem(SyncQueueItem item) {
  return OfflineQueueEntry(
    id: item.id.toString(),
    entityType: item.entityType,
    operation: _operationLabel(item.operation),
    entityLabel: _entityLabel(item),
    ageLabel: _ageLabel(item.createdAt),
    retryCount: item.retryCount,
    status: item.retryCount > 0 || item.lastError != null
        ? OfflineQueueStatus.failed
        : OfflineQueueStatus.waiting,
  );
}

String _operationLabel(String operation) {
  return switch (operation) {
    'create' => 'তৈরি',
    'update' => 'আপডেট',
    'delete' => 'মুছুন',
    _ => operation,
  };
}

String _entityLabel(SyncQueueItem item) {
  final payload = _decodePayload(item.payload);
  final explicit = payload['entity'] ?? payload['name'] ?? payload['title'];
  if (explicit is String && explicit.trim().isNotEmpty) {
    return explicit;
  }

  final type = switch (item.entityType) {
    'bazar' => 'বাজার',
    'bazar_item' => 'বাজার আইটেম',
    'money_entry' => 'টাকা এন্ট্রি',
    'direct_expense' => 'সরাসরি খরচ',
    'wallet_snapshot' => 'মাসিক হিসাব',
    'comment' => 'কমেন্ট',
    _ => 'সিঙ্ক আইটেম',
  };
  return '$type — ${item.entityId}';
}

Map<String, dynamic> _decodePayload(String payload) {
  try {
    final decoded = jsonDecode(payload);
    return decoded is Map<String, dynamic>
        ? decoded
        : const <String, dynamic>{};
  } catch (_) {
    return const <String, dynamic>{};
  }
}

String _ageLabel(DateTime createdAt) {
  final minutes = DateTime.now().difference(createdAt).inMinutes;
  if (minutes < 1) return 'এখনই';
  if (minutes < 60) return '${_toBanglaDigits(minutes)} মিনিট আগে';
  final hours = minutes ~/ 60;
  if (hours < 24) return '${_toBanglaDigits(hours)} ঘণ্টা আগে';
  return '${_toBanglaDigits(hours ~/ 24)} দিন আগে';
}

String _toBanglaDigits(Object value) {
  return value
      .toString()
      .replaceAll('0', '০')
      .replaceAll('1', '১')
      .replaceAll('2', '২')
      .replaceAll('3', '৩')
      .replaceAll('4', '৪')
      .replaceAll('5', '৫')
      .replaceAll('6', '৬')
      .replaceAll('7', '৭')
      .replaceAll('8', '৮')
      .replaceAll('9', '৯');
}
