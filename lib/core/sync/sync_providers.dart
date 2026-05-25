import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bootstrap.dart';
import '../../shared/models/app_enums.dart';
import 'connectivity_service.dart';
import 'sync_api_client.dart';
import 'sync_engine.dart';
import 'sync_enqueue_service.dart';
import 'sync_queue_dao.dart';

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityPlusService();
});

final syncQueueDaoProvider = Provider<SyncQueueDao>((ref) {
  return SyncQueueDao(ref.watch(appDatabaseProvider));
});

final syncEnqueueServiceProvider = Provider<SyncEnqueueService>((ref) {
  return SyncEnqueueService(ref.watch(syncQueueDaoProvider));
});

final syncApiClientProvider = Provider<SyncApiClient>((ref) {
  return SinkSyncApiClient();
});

final syncEngineProvider = Provider<SyncEngine>((ref) {
  return SyncEngine(
    queueDao: ref.watch(syncQueueDaoProvider),
    apiClient: ref.watch(syncApiClientProvider),
    connectivityService: ref.watch(connectivityServiceProvider),
  );
});

final syncStatusProvider =
    StateNotifierProvider<SyncStatusNotifier, SyncStatus>((ref) {
      final notifier = SyncStatusNotifier(
        queueDao: ref.watch(syncQueueDaoProvider),
        syncEngine: ref.watch(syncEngineProvider),
      );
      notifier.start();
      return notifier;
    });

class SyncStatusNotifier extends StateNotifier<SyncStatus> {
  SyncStatusNotifier({
    required SyncQueueDao queueDao,
    required SyncEngine syncEngine,
  }) : _queueDao = queueDao,
       _syncEngine = syncEngine,
       super(SyncStatus.online);

  final SyncQueueDao _queueDao;
  final SyncEngine _syncEngine;
  StreamSubscription<bool>? _onlineSubscription;

  Future<void> start() async {
    _onlineSubscription = _syncEngine.onlineChanges.listen((isOnline) {
      if (!mounted) return;
      if (!isOnline) {
        state = SyncStatus.offline;
        return;
      }
      unawaited(syncNow());
    });
    await syncNow();
  }

  Future<void> syncNow() async {
    if (!mounted) return;
    state = SyncStatus.syncing;
    final result = await _syncEngine.syncPending();
    if (!mounted) return;
    if (result.offline) {
      state = SyncStatus.offline;
    } else if (result.failed > 0) {
      state = SyncStatus.failed;
    } else {
      final pending = await _queueDao.pendingCount();
      if (!mounted) return;
      state = pending > 0 ? SyncStatus.failed : SyncStatus.online;
    }
  }

  @override
  void dispose() {
    unawaited(_onlineSubscription?.cancel());
    super.dispose();
  }
}
