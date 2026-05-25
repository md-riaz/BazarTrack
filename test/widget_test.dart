import 'package:bazar/app.dart';
import 'package:bazar/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:bazar/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:bazar/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ProviderScope buildApp({InMemoryAuthLocalDataSource? local}) {
    return ProviderScope(
      overrides: [
        authLocalDataSourceProvider.overrideWith(
          (ref) => local ?? InMemoryAuthLocalDataSource(),
        ),
        authRemoteDataSourceProvider.overrideWith(
          (ref) => const MockAuthRemoteDataSource(delay: Duration.zero),
        ),
      ],
      child: const BazarApp(),
    );
  }

  testWidgets('app boots to login when unauthenticated', (tester) async {
    await tester.pumpWidget(buildApp());

    await tester.pumpAndSettle();

    expect(find.text('সহজ বাজার খাতা'), findsOneWidget);
    expect(find.text('ফোন নম্বর'), findsWidgets);
    expect(find.text('লগইন করুন →'), findsOneWidget);
  });

  testWidgets('demo login navigates to home route', (tester) async {
    await tester.pumpWidget(buildApp());

    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText).first, '01700000000');
    await tester.enterText(find.byType(EditableText).at(1), 'demo-pass');
    await tester.tap(find.text('লগইন করুন →'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('সহজ বাজার খাতা'), findsOneWidget);
    expect(find.textContaining('স্বাগতম'), findsOneWidget);
    expect(find.text('Balance Summary'), findsOneWidget);
    expect(find.text('সাম্প্রতিক বাজার'), findsOneWidget);
    expect(find.text('দ্রুত কাজ'), findsOneWidget);
    expect(find.text('বাজার তালিকা'), findsOneWidget);
    expect(find.text('নতুন বাজার'), findsOneWidget);
    expect(find.text('হোম'), findsOneWidget);
    expect(find.text('বাজার'), findsOneWidget);
    expect(find.text('হিসাব'), findsWidgets);
    expect(find.text('রিপোর্ট'), findsWidgets);
    expect(find.text('আরো'), findsOneWidget);

    tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar)).onTap!(
      1,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('সাম্প্রতিক বাজার'), findsOneWidget);
  });

  testWidgets('authenticated state can logout back to login', (tester) async {
    final local = InMemoryAuthLocalDataSource();
    await local.saveSession(
      token: MockAuthRemoteDataSource.seededToken,
      userId: MockAuthRemoteDataSource.seededUser.id,
    );

    await tester.pumpWidget(buildApp(local: local));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('সহজ বাজার খাতা'), findsOneWidget);
    await tester.tap(find.text('আরো'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('লগআউট'), 300);
    await tester.tap(find.text('লগআউট'));
    await tester.pumpAndSettle();

    expect(find.text('লগইন করুন →'), findsOneWidget);
    expect(find.text('ফোন নম্বর'), findsWidgets);
  });
}
