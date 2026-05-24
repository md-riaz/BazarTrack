import 'package:bazar/features/settings/domain/entities/offline_queue_entry.dart';
import 'package:bazar/features/settings/presentation/providers/settings_providers.dart';
import 'package:bazar/shared/models/app_enums.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('settings providers', () {
    test('loads prototype offline queue with failed count', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final entries = container.read(offlineQueueEntriesProvider);
      final failed = container.read(offlineQueueFailedCountProvider);

      expect(entries, hasLength(5));
      expect(entries.first.entityLabel, 'দুধ ২ প্যাকেট — price: ১৩০');
      expect(entries.last.entityType, 'comment');
      expect(failed, 1);
      expect(
        entries.where((entry) => entry.status == OfflineQueueStatus.failed),
        hasLength(1),
      );
    });

    test('keeps notification, language, and sync state mutable', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(settingsNotificationProvider), isTrue);
      expect(container.read(settingsSoundProvider), isFalse);
      expect(container.read(settingsBanglaProvider), isTrue);
      expect(container.read(settingsSyncStatusProvider), SyncStatus.online);

      container.read(settingsNotificationProvider.notifier).state = false;
      container.read(settingsSoundProvider.notifier).state = true;
      container.read(settingsBanglaProvider.notifier).state = false;
      container.read(settingsSyncStatusProvider.notifier).state =
          SyncStatus.offline;

      expect(container.read(settingsNotificationProvider), isFalse);
      expect(container.read(settingsSoundProvider), isTrue);
      expect(container.read(settingsBanglaProvider), isFalse);
      expect(container.read(settingsSyncStatusProvider), SyncStatus.offline);
    });
  });
}
