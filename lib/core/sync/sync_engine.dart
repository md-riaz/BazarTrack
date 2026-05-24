import 'connectivity_service.dart';
import 'sync_api_client.dart';
import 'sync_queue_dao.dart';
import 'sync_types.dart';

class SyncEngine {
  SyncEngine({
    required SyncQueueDao queueDao,
    required SyncApiClient apiClient,
    required ConnectivityService connectivityService,
  }) : _queueDao = queueDao,
       _apiClient = apiClient,
       _connectivityService = connectivityService;

  final SyncQueueDao _queueDao;
  final SyncApiClient _apiClient;
  final ConnectivityService _connectivityService;

  Stream<bool> get onlineChanges => _connectivityService.isOnlineStream;

  Future<SyncRunResult> syncPending({int limit = 25}) async {
    if (!await _connectivityService.isOnline) {
      return const SyncRunResult(
        attempted: 0,
        synced: 0,
        failed: 0,
        offline: true,
      );
    }

    final items = await _queueDao.pending(limit: limit);
    var synced = 0;
    var failed = 0;

    for (final item in items) {
      try {
        await _apiClient.send(SyncRequest.fromQueueItem(item));
        await _queueDao.markSynced(item.id);
        synced += 1;
      } catch (error) {
        await _queueDao.markFailed(item.id, error);
        failed += 1;
      }
    }

    return SyncRunResult(
      attempted: items.length,
      synced: synced,
      failed: failed,
      offline: false,
    );
  }
}
