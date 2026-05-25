import 'package:bazar/bootstrap.dart';
import 'package:bazar/core/database/app_database.dart';
import 'package:bazar/core/sync/connectivity_service.dart';
import 'package:bazar/core/sync/sync_providers.dart';
import 'package:bazar/core/theme/app_theme.dart';
import 'package:bazar/features/auth/domain/entities/user.dart' as auth;
import 'package:bazar/features/settings/presentation/screens/more_screen.dart';
import 'package:bazar/shared/models/app_enums.dart';
import 'package:drift/drift.dart';
import 'package:bazar/features/settings/presentation/screens/offline_queue_screen.dart';
import 'package:bazar/features/settings/presentation/screens/profile_edit_screen.dart';
import 'package:bazar/features/settings/presentation/screens/settings_screen.dart';
import 'package:bazar/features/settings/presentation/widgets/settings_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(
  Widget child, {
  AppDatabase? database,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: [
      if (database != null) appDatabaseProvider.overrideWithValue(database),
      ...overrides,
    ],
    child: MaterialApp(theme: AppTheme.light, home: child),
  );
}

void main() {
  group('Agent H settings screens', () {
    testWidgets('MoreScreen shows assistant profile and role-limited menu', (
      tester,
    ) async {
      String? tappedRoute;
      final database = AppDatabase.forTesting();
      addTearDown(database.close);
      final connectivity = ManualConnectivityService(isOnline: false);
      addTearDown(connectivity.dispose);
      await _insertQueueRows(database);

      await tester.pumpWidget(
        _wrap(
          MoreScreen(
            user: const auth.User(
              id: 'u1',
              name: 'Rahim Uddin',
              role: UserRole.assistant,
              isActive: true,
              phone: '01711-XXXXXX',
              email: 'rahim@example.com',
            ),
            onMenuTap: (route) => tappedRoute = route,
            onOfflineQueueTap: () => tappedRoute = 'offlineQueue',
          ),
          database: database,
          overrides: [
            connectivityServiceProvider.overrideWithValue(connectivity),
          ],
        ),
      );
      await tester.pump();

      expect(find.text('আরো'), findsOneWidget);
      expect(find.text('Rahim Uddin'), findsOneWidget);
      expect(find.text('01711-XXXXXX'), findsOneWidget);
      expect(find.text('Assistant'), findsOneWidget);
      expect(find.text('নোটিফিকেশন'), findsOneWidget);
      expect(find.text('Wallet details'), findsOneWidget);
      expect(find.text('খুঁজুন'), findsOneWidget);
      expect(find.text('সেটিংস'), findsOneWidget);
      expect(find.text('রিপোর্ট'), findsNothing);
      expect(find.text('Close হিসাব'), findsNothing);
      expect(find.text('অ্যাডমিন প্যানেল'), findsNothing);

      expect(find.text('Sync status'), findsOneWidget);
      expect(find.text('২টা item Sync queue-তে আছে। দেখুন →'), findsOneWidget);

      await tester.tap(find.text('২টা item Sync queue-তে আছে। দেখুন →'));
      expect(tappedRoute, 'offlineQueue');

      await tester.tap(find.text('নোটিফিকেশন'));
      expect(tappedRoute, 'notifications');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
    });

    testWidgets('MoreScreen shows owner reports and monthly close only', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(MoreScreen(user: _user(role: UserRole.owner))),
      );
      await tester.pump();

      expect(find.text('Rahim Uddin'), findsOneWidget);
      expect(find.text('Owner'), findsOneWidget);
      expect(find.text('রিপোর্ট'), findsOneWidget);
      expect(find.text('Close হিসাব'), findsOneWidget);
      expect(find.text('অ্যাডমিন প্যানেল'), findsNothing);
    });

    testWidgets('MoreScreen shows admin panel for admin user', (tester) async {
      await tester.pumpWidget(
        _wrap(MoreScreen(user: _user(role: UserRole.admin))),
      );
      await tester.pump();

      expect(find.text('Rahim Uddin'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);
      expect(find.text('রিপোর্ট'), findsOneWidget);
      expect(find.text('Close হিসাব'), findsOneWidget);
      expect(find.text('অ্যাডমিন প্যানেল'), findsOneWidget);
    });

    testWidgets('SettingsScreen toggles language and notification controls', (
      tester,
    ) async {
      var queueTapped = false;

      await tester.pumpWidget(
        _wrap(SettingsScreen(onOfflineQueueTap: () => queueTapped = true)),
      );

      expect(find.text('সেটিংস'), findsOneWidget);
      expect(find.text('পুশ নোটিফিকেশন'), findsOneWidget);
      expect(find.text('ভাষা / Language'), findsOneWidget);
      expect(find.text('Version'), findsOneWidget);

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sync queue দেখুন'));
      expect(queueTapped, isTrue);
    });

    testWidgets('HSwitch exposes semantic role, label, and 48dp tap target', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        _wrap(
          Center(
            child: HSwitch(
              semanticLabel: 'Push Notification',
              value: true,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(
        tester.getSemantics(find.byType(HSwitch)),
        matchesSemantics(
          label: 'Push Notification',
          hasTapAction: true,
          hasToggledState: true,
          isToggled: true,
          isButton: true,
        ),
      );
      expect(tester.getSize(find.byType(HSwitch)), const Size(48, 48));
      semantics.dispose();
    });

    testWidgets('OfflineQueueScreen renders pending and failed queue items', (
      tester,
    ) async {
      final database = AppDatabase.forTesting();
      addTearDown(database.close);
      final connectivity = ManualConnectivityService(isOnline: false);
      addTearDown(connectivity.dispose);
      await _insertQueueRows(database);

      await tester.pumpWidget(
        _wrap(
          const OfflineQueueScreen(),
          database: database,
          overrides: [
            connectivityServiceProvider.overrideWithValue(connectivity),
          ],
        ),
      );
      await tester.pump();

      expect(find.text('Sync queue'), findsOneWidget);
      expect(find.text('Offline items'), findsOneWidget);
      expect(find.text('২টি আইটেম পাঠানো বাকি আছে'), findsOneWidget);
      expect(find.text('১ ব্যর্থ'), findsOneWidget);
      expect(find.text('দুধ ২ প্যাকেট'), findsOneWidget);
      expect(find.text('সরাসরি খরচ — ৳ ৫০'), findsOneWidget);
      expect(find.text('Retry all'), findsOneWidget);
      expect(find.text('Queue মুছুন'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
    });

    testWidgets('ProfileEditScreen validates password and shows save state', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const ProfileEditScreen()));

      expect(find.text('প্রোফাইল সম্পাদনা'), findsOneWidget);
      expect(find.text('Rahim Uddin'), findsOneWidget);
      expect(find.text('01711-XXXXXX'), findsOneWidget);
      expect(find.text('assistant'), findsOneWidget);

      await tester.enterText(find.byType(TextField).last, 'short');
      await tester.pumpAndSettle();
      expect(find.text('পাসওয়ার্ড কমপক্ষে ৮ অক্ষর হতে হবে'), findsOneWidget);

      await tester.enterText(find.byType(TextField).last, 'longpass123');
      await tester.pumpAndSettle();
      expect(find.text('পাসওয়ার্ড কমপক্ষে ৮ অক্ষর হতে হবে'), findsNothing);

      await tester.tap(find.text('সংরক্ষণ করুন'));
      await tester.pumpAndSettle();
      expect(find.text('প্রোফাইল সংরক্ষিত হয়েছে'), findsOneWidget);
    });
  });
}

auth.User _user({required UserRole role}) {
  return auth.User(
    id: 'u-${role.name}',
    name: 'Rahim Uddin',
    role: role,
    isActive: true,
    phone: '01711-XXXXXX',
    email: 'rahim@example.com',
  );
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
