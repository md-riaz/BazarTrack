import 'package:bazar/bootstrap.dart';
import 'package:bazar/core/database/app_database.dart' show AppDatabase;
import 'package:bazar/core/mock/mock_seed.dart';
import 'package:bazar/features/auth/domain/entities/user.dart';
import 'package:bazar/features/auth/presentation/providers/auth_provider.dart';
import 'package:bazar/features/bazar/presentation/screens/add_item_screen.dart';
import 'package:bazar/features/bazar/presentation/screens/new_bazar_screen.dart';
import 'package:bazar/features/money/presentation/screens/direct_expense_screen.dart';
import 'package:bazar/features/wallet/domain/entities/wallet.dart';
import 'package:bazar/features/wallet/presentation/providers/wallet_providers.dart';
import 'package:bazar/shared/models/app_enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;

  setUp(() async {
    database = AppDatabase.forTesting();
    await database.customStatement('PRAGMA foreign_keys = OFF');
    await MockSeed.seed(database);
  });

  tearDown(() async {
    await database.close();
  });

  final wallets = [
    Wallet(
      id: 'w1',
      name: 'Office Wallet',
      type: 'shared',
      isActive: true,
      createdAt: DateTime(2026, 5, 24),
    ),
  ];
  const currentUser = User(
    id: 'u1',
    name: 'Rahim Uddin',
    role: UserRole.assistant,
    isActive: true,
  );

  testWidgets(
    'NewBazarScreen starts in manual mode with optional fields collapsed',
    (tester) async {
      await tester.pumpWidget(
        _testApp(database, const NewBazarScreen(), wallets, currentUser),
      );
      await tester.pump(const Duration(milliseconds: 1));

      expect(find.text('নতুন বাজার'), findsOneWidget);
      expect(find.text('একে একে'), findsOneWidget);
      expect(find.text('পরিমাণ / ব্র্যান্ড (optional)'), findsOneWidget);
      expect(find.text('পরিমাণ'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 1));
    },
  );

  testWidgets('AddItemScreen keeps optional item fields collapsed by default', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        database,
        const AddItemScreen(bazarId: 'b1'),
        wallets,
        currentUser,
      ),
    );
    await tester.pump(const Duration(milliseconds: 1));

    expect(find.text('আইটেম যোগ করুন'), findsOneWidget);
    expect(
      find.text('পরিমাণ, ইউনিট, ব্র্যান্ড যোগ করুন (optional)'),
      findsOneWidget,
    );
    expect(find.text('পরিমাণ'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('DirectExpenseScreen renders direct expense form', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(database, const DirectExpenseScreen(), wallets, currentUser),
    );
    await tester.pump(const Duration(milliseconds: 1));

    expect(find.text('সরাসরি খরচ'), findsOneWidget);
    expect(find.text('এটি Bazar তালিকা ছাড়া সরাসরি খরচ।'), findsOneWidget);
    expect(find.text('টাকার পরিমাণ'), findsOneWidget);
    expect(find.text('সংরক্ষণ করুন'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
  });
}

Widget _testApp(
  AppDatabase database,
  Widget child,
  List<Wallet> wallets,
  User currentUser,
) {
  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(database),
      walletListProvider.overrideWith((ref) => Stream.value(wallets)),
      currentUserProvider.overrideWith((ref) => Stream.value(currentUser)),
    ],
    child: MaterialApp(home: child),
  );
}
