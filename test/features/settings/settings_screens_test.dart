import 'package:bazar/core/theme/app_theme.dart';
import 'package:bazar/features/settings/presentation/screens/more_screen.dart';
import 'package:bazar/features/settings/presentation/screens/offline_queue_screen.dart';
import 'package:bazar/features/settings/presentation/screens/profile_edit_screen.dart';
import 'package:bazar/features/settings/presentation/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return ProviderScope(
    child: MaterialApp(theme: AppTheme.light, home: child),
  );
}

void main() {
  group('Agent H settings screens', () {
    testWidgets('MoreScreen renders profile, menu, and sync controls', (
      tester,
    ) async {
      String? tappedRoute;

      await tester.pumpWidget(
        _wrap(
          MoreScreen(
            onMenuTap: (route) => tappedRoute = route,
            onOfflineQueueTap: () => tappedRoute = 'offlineQueue',
          ),
        ),
      );

      expect(find.text('আরো'), findsOneWidget);
      expect(find.text('Rahim Uddin'), findsOneWidget);
      expect(find.text('নোটিফিকেশন'), findsOneWidget);
      expect(find.text('সেটিংস'), findsOneWidget);

      await tester.tap(find.text('Offline'));
      await tester.pumpAndSettle();
      expect(find.text('5টি item sync queue-এ। দেখুন →'), findsOneWidget);

      await tester.tap(find.text('5টি item sync queue-এ। দেখুন →'));
      expect(tappedRoute, 'offlineQueue');

      await tester.tap(find.text('নোটিফিকেশন'));
      expect(tappedRoute, 'notifications');
    });

    testWidgets('SettingsScreen toggles language and notification controls', (
      tester,
    ) async {
      var queueTapped = false;

      await tester.pumpWidget(
        _wrap(SettingsScreen(onOfflineQueueTap: () => queueTapped = true)),
      );

      expect(find.text('সেটিংস'), findsOneWidget);
      expect(find.text('Push Notification'), findsOneWidget);
      expect(find.text('ভাষা / Language'), findsOneWidget);
      expect(find.text('Version'), findsOneWidget);

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sync Queue দেখুন'));
      expect(queueTapped, isTrue);
    });

    testWidgets('OfflineQueueScreen renders pending and failed queue items', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const OfflineQueueScreen()));

      expect(find.text('Sync Queue'), findsOneWidget);
      expect(find.text('OFFLINE PENDING ITEMS'), findsOneWidget);
      expect(find.text('৫টি item পাঠানো বাকি আছে'), findsOneWidget);
      expect(find.text('1 failed'), findsOneWidget);
      expect(find.text('দুধ ২ প্যাকেট — price: ১৩০'), findsOneWidget);
      expect(find.text('টাকা নিলাম — ৳ ৩,০০০'), findsOneWidget);
      expect(find.text('সব Retry করুন'), findsOneWidget);
      expect(find.text('Queue মুছুন'), findsOneWidget);
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
