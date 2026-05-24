import 'package:bazar/core/database/app_database.dart';
import 'package:bazar/features/reports/data/repositories/report_repository_impl.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late ReportRepositoryImpl repository;

  setUp(() async {
    database = AppDatabase.forTesting();
    repository = ReportRepositoryImpl(database);

    final now = DateTime(2026, 5, 24);
    await database
        .into(database.users)
        .insert(
          UsersCompanion.insert(
            id: 'u1',
            name: 'Rahim',
            role: 'assistant',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await database
        .into(database.users)
        .insert(
          UsersCompanion.insert(
            id: 'u2',
            name: 'Owner',
            role: 'owner',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await database
        .into(database.wallets)
        .insert(
          WalletsCompanion.insert(
            id: 'w1',
            name: 'Office Wallet',
            type: 'shared',
            createdBy: const Value('u2'),
            createdAt: now,
          ),
        );
    await database
        .into(database.bazars)
        .insert(
          BazarsCompanion.insert(
            id: 'b1',
            walletId: 'w1',
            createdBy: 'u2',
            assignedTo: const Value('u1'),
            status: 'closed',
            bazarDate: DateTime(2026, 5, 15),
            createdAt: now,
            updatedAt: now,
            closedAt: Value(now),
          ),
        );
    await database
        .into(database.bazarItems)
        .insert(
          BazarItemsCompanion.insert(
            id: 'i1',
            bazarId: 'b1',
            name: 'ডিম',
            status: 'done',
            price: const Value(120),
            createdAt: now,
            updatedAt: now,
          ),
        );
    await database
        .into(database.moneyEntries)
        .insert(
          MoneyEntriesCompanion.insert(
            id: 'm1',
            walletId: 'w1',
            assistantId: 'u1',
            type: 'money_received',
            amount: 500,
            entryDate: DateTime(2026, 5, 10),
            createdAt: now,
            updatedAt: now,
          ),
        );
    await database
        .into(database.moneyEntries)
        .insert(
          MoneyEntriesCompanion.insert(
            id: 'm2',
            walletId: 'w1',
            assistantId: 'u1',
            type: 'money_returned',
            amount: 50,
            entryDate: DateTime(2026, 5, 11),
            createdAt: now,
            updatedAt: now,
          ),
        );
    await database
        .into(database.directExpenses)
        .insert(
          DirectExpensesCompanion.insert(
            id: 'd1',
            walletId: 'w1',
            assistantId: 'u1',
            amount: 30,
            entryDate: DateTime(2026, 5, 12),
            createdAt: now,
          ),
        );
  });

  tearDown(() async {
    await database.close();
  });

  test('derives monthly report summary from local Drift rows', () async {
    final summary = await repository.getMonthlySummary('2026-05');

    expect(summary.totalReceived, 500);
    expect(summary.totalReturned, 50);
    expect(summary.totalSpent, 150);
    expect(summary.netBalance, 300);
    expect(summary.walletBreakdowns.single.walletName, 'Office Wallet');
    expect(summary.topItems.single.name, 'ডিম');
  });
}
