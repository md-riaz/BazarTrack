import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/api_config.dart';
import 'bazar_api_client.dart';

final bazarApiClientProvider = Provider<BazarApiClient>((ref) {
  return BazarApiClient(config: ref.watch(apiConfigProvider));
});
