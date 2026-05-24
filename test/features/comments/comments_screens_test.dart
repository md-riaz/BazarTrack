import 'package:bazar/core/theme/app_theme.dart';
import 'package:bazar/features/comments/presentation/providers/comments_providers.dart';
import 'package:bazar/features/comments/presentation/screens/bazar_comments_screen.dart';
import 'package:bazar/features/comments/presentation/screens/price_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {ProviderContainer? container}) {
  return UncontrolledProviderScope(
    container: container ?? ProviderContainer(),
    child: MaterialApp(theme: AppTheme.light, home: child),
  );
}

void main() {
  group('Agent H comments screens', () {
    testWidgets(
      'BazarCommentsScreen renders comments and clears draft on send',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          _wrap(const BazarCommentsScreen(), container: container),
        );

        expect(find.text('মন্তব্য'), findsOneWidget);
        expect(find.text('CEO PERSONAL বাজার'), findsOneWidget);
        expect(find.textContaining('অডিট নোট'), findsOneWidget);
        expect(find.text('CEO'), findsNWidgets(2));
        expect(find.text('Rahim'), findsNWidgets(2));
        expect(find.textContaining('Aarong full cream'), findsOneWidget);
        expect(
          find.textContaining('চিকেন ১.৫ কেজি নেওয়া হয়েছে'),
          findsOneWidget,
        );

        await tester.enterText(find.byType(TextField), 'নতুন মন্তব্য');
        await tester.pumpAndSettle();
        expect(container.read(draftCommentProvider), 'নতুন মন্তব্য');

        await tester.tap(find.byIcon(Icons.arrow_upward));
        await tester.pumpAndSettle();
        expect(container.read(draftCommentProvider), '');
      },
    );

    testWidgets('PriceHistoryScreen renders chart stats and purchase details', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const PriceHistoryScreen()));

      expect(find.text('ডিম — দামের ইতিহাস'), findsOneWidget);
      expect(find.text('ITEM PRICE HISTORY'), findsOneWidget);
      expect(find.text('সর্বশেষ দাম'), findsOneWidget);
      expect(find.text('৳ ২১০'), findsAtLeastNWidgets(2));
      expect(find.text('গড় দাম/টা'), findsOneWidget);
      expect(find.text('৳ ৬.৫৩'), findsOneWidget);
      expect(find.text('মোট কেনা'), findsOneWidget);
      expect(find.text('৬বার'), findsOneWidget);
      expect(find.text('দামের প্রবণতা (Chart)'), findsOneWidget);
      expect(find.text('ক্রয়ের বিস্তারিত'), findsOneWidget);
      expect(find.text('২৩ মে ২০২৫'), findsOneWidget);
      expect(find.text('Office Lunch'), findsWidgets);
      expect(find.text('Karim'), findsWidgets);
    });
  });
}
