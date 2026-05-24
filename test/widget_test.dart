import 'package:bazar/app.dart';
import 'package:bazar/shared/providers/foundation_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app boots to login when unauthenticated', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: BazarApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('সহজ বাজার খাতা'), findsOneWidget);
    expect(find.text('ফোন নম্বর'), findsOneWidget);
    expect(find.text('লগইন করুন →'), findsOneWidget);
  });

  testWidgets('demo login navigates to home route', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: BazarApp(),
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText).first, '01700000000');
    await tester.enterText(find.byType(EditableText).at(1), 'demo-pass');
    await tester.tap(find.text('লগইন করুন →'));
    await tester.pumpAndSettle();

    expect(find.text('হোম'), findsOneWidget);
    expect(find.textContaining('Dashboard shell and quick actions'), findsOneWidget);
    expect(find.text('লগআউট'), findsOneWidget);
  });

  testWidgets('authenticated state can logout back to login', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => const AuthState.demoAuthenticated()),
        ],
        child: const BazarApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('হোম'), findsOneWidget);
    await tester.tap(find.text('লগআউট'));
    await tester.pumpAndSettle();

    expect(find.text('লগইন করুন →'), findsOneWidget);
    expect(find.text('ফোন নম্বর'), findsOneWidget);
  });
}
