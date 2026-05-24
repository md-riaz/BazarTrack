import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/app_enums.dart';
import '../../data/datasources/settings_mock_data_source.dart';
import '../../domain/entities/offline_queue_entry.dart';

final settingsMockDataSourceProvider = Provider<SettingsMockDataSource>((ref) {
  return const SettingsMockDataSource();
});

final settingsNotificationProvider = StateProvider<bool>((ref) => true);
final settingsSoundProvider = StateProvider<bool>((ref) => false);
final settingsBanglaProvider = StateProvider<bool>((ref) => true);
final settingsSyncStatusProvider = StateProvider<SyncStatus>((ref) {
  return SyncStatus.online;
});

final offlineQueueEntriesProvider = Provider<List<OfflineQueueEntry>>((ref) {
  return ref.watch(settingsMockDataSourceProvider).offlineQueueEntries();
});

final offlineQueueFailedCountProvider = Provider<int>((ref) {
  return ref
      .watch(offlineQueueEntriesProvider)
      .where((entry) => entry.status == OfflineQueueStatus.failed)
      .length;
});
