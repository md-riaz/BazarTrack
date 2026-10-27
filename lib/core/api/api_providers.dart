import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/api_config.dart';
import 'api_session.dart';
import 'bazar_api_client.dart';
import 'bearer_auth_interceptor.dart';

final apiSecureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final apiSessionStoreProvider = Provider<ApiSessionStore>((ref) {
  return ApiSessionStore(ref.watch(apiSecureStorageProvider));
});

final apiSessionEventsProvider = Provider<ApiSessionEvents>((ref) {
  final events = ApiSessionEvents();
  ref.onDispose(events.dispose);
  return events;
});

final bazarApiClientProvider = Provider<BazarApiClient>((ref) {
  return BazarApiClient(
    config: ref.watch(apiConfigProvider),
    interceptors: [
      BearerAuthInterceptor(
        sessionStore: ref.watch(apiSessionStoreProvider),
        sessionEvents: ref.watch(apiSessionEventsProvider),
      ),
    ],
  );
});
