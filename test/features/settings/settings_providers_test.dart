import 'package:bazar/bootstrap.dart';
import 'package:bazar/core/database/app_database.dart';
import 'package:bazar/features/settings/domain/entities/offline_queue_entry.dart';
import 'package:bazar/features/settings/presentation/providers/settings_providers.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('settings providers', () {
    test('loads real sync queue entries with failed count', () async {
      final database = AppDatabase.forTesting();
      addTearDown(database.close);
      await _insertQueueRows(database);

      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
      );
      addTearDown(container.dispose);

      final entries = await container.read(offlineQueueEntriesProvider.future);
      final failed = container
          .read(offlineQueueFailedCountProvider)
          .requireValue;

      expect(entries, hasLength(2));
      expect(entries.first.entityLabel, 'দুধ ২ প্যাকেট');
      expect(entries.last.entityType, 'direct_expense');
      expect(failed, 1);
      expect(
        entries.where((entry) => entry.status == OfflineQueueStatus.failed),
        hasLength(1),
      );
    });

    test('keeps notification and language state mutable', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(settingsNotificationProvider), isTrue);
      expect(container.read(settingsSoundProvider), isFalse);
      expect(container.read(settingsBanglaProvider), isTrue);

      container.read(settingsNotificationProvider.notifier).state = false;
      container.read(settingsSoundProvider.notifier).state = true;
      container.read(settingsBanglaProvider.notifier).state = false;

      expect(container.read(settingsNotificationProvider), isFalse);
      expect(container.read(settingsSoundProvider), isTrue);
      expect(container.read(settingsBanglaProvider), isFalse);
    });
  });
}

Future<void> _insertQueueRows(AppDatabase database) async {
  await database
      .into(database.syncQueueItems)
      .insert(
        SyncQueueItemsCompanion.insert(
          entityType: 'bazar_item',
          entityId: 'i3',
          operation: 'update',
          payload: '{"name":"দুধ ২ প্যাকেট","status":"waiting"}',
          createdAt: DateTime(2026, 5, 24, 9),
        ),
      );
  await database
      .into(database.syncQueueItems)
      .insert(
        SyncQueueItemsCompanion.insert(
          entityType: 'direct_expense',
          entityId: 'd1',
          operation: 'create',
          payload: '{"entity":"সরাসরি খরচ — ৳ ৫০"}',
          createdAt: DateTime(2026, 5, 24, 9, 5),
          retryCount: const Value(1),
        ),
      );
}
