import 'package:bazar/core/database/app_database.dart';
import 'package:bazar/features/wallet/domain/entities/wallet_snapshot.dart'
    as domain;
import 'package:bazar/features/wallet/domain/services/balance_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late BalanceCalculator calculator;

  setUp(() {
    database = AppDatabase.forTesting();
    calculator = BalanceCalculator(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('calculates positive balance from received money and expenses', () {
    final result = calculator.calculate(
      walletId: 'w1',
      moneyEntries: [
        MoneyBalanceEntry(
          amount: 1000,
          type: 'money_received',
          entryDate: DateTime(2026, 5, 1),
        ),
      ],
      directExpenses: [
        DirectExpenseBalanceEntry(amount: 100, entryDate: DateTime(2026, 5, 1)),
      ],
      bazarItems: [
        BazarItemBalanceEntry(
          price: 250,
          status: 'closed',
          date: DateTime(2026, 5, 1),
        ),
      ],
      snapshots: const [],
    );

    expect(result.confirmedBalance, 650);
    expect(result.inProgressAmount, 0);
    expect(result.estimatedBalance, 650);
    expect(result.label, 'হাতে আছে');
  });

  test('calculates negative balance when spending exceeds received money', () {
    final result = calculator.calculate(
      walletId: 'w1',
      moneyEntries: [
        MoneyBalanceEntry(
          amount: 200,
          type: 'money_received',
          entryDate: DateTime(2026, 5, 1),
        ),
      ],
      directExpenses: [
        DirectExpenseBalanceEntry(amount: 300, entryDate: DateTime(2026, 5, 1)),
      ],
      bazarItems: [
        BazarItemBalanceEntry(
          price: 150,
          status: 'closed',
          date: DateTime(2026, 5, 1),
        ),
      ],
      snapshots: const [],
    );

    expect(result.confirmedBalance, -250);
    expect(result.estimatedBalance, -250);
    expect(result.label, 'পাওনা আছে — দিতে হবে');
  });

  test('calculates zero balance as settled', () {
    final result = calculator.calculate(
      walletId: 'w1',
      moneyEntries: [
        MoneyBalanceEntry(
          amount: 500,
          type: 'money_received',
          entryDate: DateTime(2026, 5, 1),
        ),
      ],
      directExpenses: const [],
      bazarItems: [
        BazarItemBalanceEntry(
          price: 500,
          status: 'closed',
          date: DateTime(2026, 5, 1),
        ),
      ],
      snapshots: const [],
    );

    expect(result.confirmedBalance, 0);
    expect(result.estimatedBalance, 0);
    expect(result.label, 'হিসাব মিলে গেছে ✓');
  });

  test('keeps open bazar spending in in-progress amount', () {
    final result = calculator.calculate(
      walletId: 'w1',
      moneyEntries: [
        MoneyBalanceEntry(
          amount: 1000,
          type: 'money_received',
          entryDate: DateTime(2026, 5, 1),
        ),
      ],
      directExpenses: const [],
      bazarItems: [
        BazarItemBalanceEntry(
          price: 200,
          status: 'open',
          date: DateTime(2026, 5, 1),
        ),
      ],
      snapshots: const [],
    );

    expect(result.confirmedBalance, 1000);
    expect(result.inProgressAmount, -200);
    expect(result.estimatedBalance, 800);
  });

  test('starts from latest snapshot and ignores previous entries', () {
    final snapshotAt = DateTime(2026, 5, 10);
    final result = calculator.calculate(
      walletId: 'w1',
      moneyEntries: [
        MoneyBalanceEntry(
          amount: 10000,
          type: 'money_received',
          entryDate: DateTime(2026, 5, 1),
        ),
        MoneyBalanceEntry(
          amount: 300,
          type: 'money_received',
          entryDate: DateTime(2026, 5, 11),
        ),
      ],
      directExpenses: [
        DirectExpenseBalanceEntry(amount: 50, entryDate: DateTime(2026, 5, 11)),
      ],
      bazarItems: const [],
      snapshots: [
        domain.WalletSnapshot(
          id: 's1',
          walletId: 'w1',
          periodMonth: '2026-05',
          openingBalance: 0,
          closingBalance: 800,
          closedAt: snapshotAt,
        ),
      ],
    );

    expect(result.snapshotBase, 800);
    expect(result.confirmedBalance, 1050);
    expect(result.estimatedBalance, 1050);
  });
}
