import 'package:bazar/app.dart';
import 'package:bazar/bootstrap.dart';
import 'package:bazar/core/database/app_database.dart';
import 'package:bazar/core/sync/connectivity_service.dart';
import 'package:bazar/core/sync/sync_providers.dart';
import 'package:bazar/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:bazar/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:bazar/features/auth/presentation/providers/auth_provider.dart';
import 'package:bazar/features/bazar/domain/entities/bazar_entities.dart'
    as bazar_entities;
import 'package:bazar/features/bazar/presentation/providers/bazar_providers.dart';
import 'package:bazar/features/reports/domain/entities/report_summary.dart';
import 'package:bazar/features/reports/presentation/providers/report_providers.dart';
import 'package:bazar/features/settings/domain/entities/offline_queue_entry.dart';
import 'package:bazar/features/settings/presentation/providers/settings_providers.dart';
import 'package:bazar/features/wallet/domain/entities/wallet_summary.dart';
import 'package:bazar/features/wallet/presentation/providers/wallet_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const settleDuration = Duration(milliseconds: 500);

  ProviderScope buildApp({
    required AppDatabase database,
    required AuthLocalDataSource local,
    required ManualConnectivityService connectivity,
  }) {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        authLocalDataSourceProvider.overrideWith((ref) => local),
        authRemoteDataSourceProvider.overrideWith(
          (ref) => const MockAuthRemoteDataSource(delay: Duration.zero),
        ),
        connectivityServiceProvider.overrideWithValue(connectivity),
        offlineQueueEntriesProvider.overrideWith(
          (ref) => Stream.value(const <OfflineQueueEntry>[]),
        ),
        bazarsProvider.overrideWith(
          (ref) => Stream.value(const <bazar_entities.Bazar>[]),
        ),
        walletSummariesProvider.overrideWith(
          (ref) => Stream.value(const <WalletSummary>[]),
        ),
        monthlyReportProvider.overrideWith(
          (ref, periodMonth) => Stream.value(_emptyReport(periodMonth)),
        ),
      ],
      child: const BazarApp(),
    );
  }

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final database = AppDatabase.forTesting();
    final connectivity = ManualConnectivityService(isOnline: false);
    final local = InMemoryAuthLocalDataSource();
    addTearDown(database.close);
    addTearDown(connectivity.dispose);

    await tester.pumpWidget(
      buildApp(database: database, local: local, connectivity: connectivity),
    );
    await tester.pump(settleDuration);
  }

  Future<void> tapDemoRole(WidgetTester tester, String label) async {
    final button = find.text(label);
    await tester.ensureVisible(button);
    await tester.pump();
    await tester.tap(button, warnIfMissed: false);
    await tester.pump();
    await tester.pump(settleDuration);
  }

  void expectHomeShell() {
    expect(find.text('সহজ বাজার খাতা'), findsOneWidget);
    expect(find.textContaining('স্বাগতম'), findsOneWidget);
    expect(find.text('Balance Summary'), findsOneWidget);
    expect(find.text('সাম্প্রতিক বাজার'), findsOneWidget);
    expect(find.text('দ্রুত কাজ'), findsOneWidget);
    expect(find.text('হোম'), findsOneWidget);
    expect(find.text('বাজার'), findsOneWidget);
    expect(find.text('হিসাব'), findsWidgets);
    expect(find.text('আরো'), findsOneWidget);
  }

  testWidgets(
    'app boots to login with demo role buttons when unauthenticated',
    (tester) async {
      await pumpApp(tester);

      expect(find.text('সহজ বাজার খাতা'), findsOneWidget);
      expect(find.text('ফোন নম্বর'), findsWidgets);
      expect(find.text('লগইন করুন →'), findsOneWidget);
      expect(find.text('Login as Admin'), findsOneWidget);
      expect(find.text('Login as Owner'), findsOneWidget);
      expect(find.text('Login as Assistant'), findsOneWidget);
    },
  );

  testWidgets(
    'assistant demo role login reaches home and hides restricted shell actions',
    (tester) async {
      await pumpApp(tester);
      await tapDemoRole(tester, 'Login as Assistant');

      expectHomeShell();
      expect(find.text('Rahim Uddin — সহকারী'), findsOneWidget);
      expect(find.text('বাজার তালিকা'), findsOneWidget);
      expect(find.text('নতুন বাজার'), findsOneWidget);
      expect(find.text('রিপোর্ট'), findsNothing);
      expect(find.text('টাকা এন্ট্রি'), findsNothing);
      expect(find.text('অ্যাডমিন প্যানেল'), findsNothing);

      tester
          .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
          .onTap!(3);
      await tester.pump();
      await tester.pump(settleDuration);

      expect(find.text('Rahim Uddin'), findsOneWidget);
      expect(find.text('Assistant'), findsOneWidget);
      expect(find.text('রিপোর্ট'), findsNothing);
      expect(find.text('Close হিসাব'), findsNothing);
      expect(find.text('অ্যাডমিন প্যানেল'), findsNothing);
    },
  );

  testWidgets(
    'owner demo role login reaches reports and hides direct expense',
    (tester) async {
      await pumpApp(tester);
      await tapDemoRole(tester, 'Login as Owner');

      expectHomeShell();
      expect(find.text('Mr. CEO — মালিক'), findsOneWidget);
      expect(find.text('রিপোর্ট'), findsWidgets);
      expect(find.text('টাকা এন্ট্রি'), findsOneWidget);
      expect(find.text('সরাসরি খরচ'), findsNothing);

      tester
          .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
          .onTap!(3);
      await tester.pump();
      await tester.pump(settleDuration);

      expect(find.text('Export ↓'), findsOneWidget);
      expect(find.text('মাসের সারসংক্ষেপ'), findsOneWidget);
    },
  );

  testWidgets('admin demo role login reaches reports and admin menu', (
    tester,
  ) async {
    await pumpApp(tester);
    await tapDemoRole(tester, 'Login as Admin');

    expectHomeShell();
    expect(find.text('Admin User — অ্যাডমিন'), findsOneWidget);
    expect(find.text('রিপোর্ট'), findsWidgets);

    tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar)).onTap!(
      3,
    );
    await tester.pump();
    await tester.pump(settleDuration);

    expect(find.text('Export ↓'), findsOneWidget);
    expect(find.text('মাসের সারসংক্ষেপ'), findsOneWidget);

    tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar)).onTap!(
      4,
    );
    await tester.pump();
    await tester.pump(settleDuration);

    expect(find.text('Admin User'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
    expect(find.text('অ্যাডমিন প্যানেল'), findsOneWidget);
  });
}

ReportSummary _emptyReport(String periodMonth) {
  return ReportSummary(
    periodMonth: periodMonth,
    totalReceived: 0,
    totalSpent: 0,
    totalReturned: 0,
    adjustmentTotal: 0,
    netBalance: 0,
    walletBreakdowns: const [],
    topItems: const [],
  );
}
