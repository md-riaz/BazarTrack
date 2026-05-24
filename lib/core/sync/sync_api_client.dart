import 'sync_types.dart';

abstract class SyncApiClient {
  Future<void> send(SyncRequest request);
}

class SinkSyncApiClient implements SyncApiClient {
  SinkSyncApiClient({List<SyncRequest>? sent}) : sent = sent ?? <SyncRequest>[];

  final List<SyncRequest> sent;

  @override
  Future<void> send(SyncRequest request) async {
    sent.add(request);
  }
}
