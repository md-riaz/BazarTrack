import 'package:bazar/core/database/app_database.dart';
import 'package:bazar/core/sync/sync_enqueue_service.dart';
import 'package:bazar/core/sync/sync_queue_dao.dart';
import 'package:bazar/features/money/data/datasources/mock_money_remote_datasource.dart';
import 'package:bazar/features/money/data/datasources/money_local_data_source.dart';
import 'package:bazar/features/money/data/repositories/money_entry_repository_impl.dart';
import 'package:bazar/shared/models/app_enums.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late MoneyEntryRepositoryImpl repository;

  setUp(() async {
    database = AppDatabase.forTesting();
    repository = MoneyEntryRepositoryImpl(
      moneyEntryDao: MoneyEntryDao(database),
      directExpenseDao: DirectExpenseDao(database),
      monthlyCloseDao: MonthlyCloseDao(database),
      remoteDataSource: const MockMoneyRemoteDataSource(),
      syncEnqueueService: SyncEnqueueService(SyncQueueDao(database)),
    );

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
  });

  tearDown(() async {
    await database.close();
  });

  test('creates money entry in local Drift before publish seam', () async {
    final created = await repository.createMoneyEntry(
      walletId: 'w1',
      assistantId: 'u1',
      type: EntryType.moneyReceived,
      amount: 500,
      entryDate: DateTime(2026, 5, 24),
      note: 'advance',
      createdBy: 'u2',
    );

    final watched = await repository.watchMoneyEntries(walletId: 'w1').first;

    final pending = await SyncQueueDao(database).pending();

    expect(created.amount, 500);
    expect(watched, hasLength(1));
    expect(watched.first.walletName, 'Office Wallet');
    expect(watched.first.assistantName, 'Rahim');
    expect(pending, hasLength(1));
    expect(pending.single.entityType, 'money_entry');
    expect(pending.single.entityId, created.id);
    expect(pending.single.payload, contains('"amount":500'));
  });

  test('requires note for adjustment entry', () async {
    expect(
      () => repository.createMoneyEntry(
        walletId: 'w1',
        assistantId: 'u1',
        type: EntryType.adjustment,
        amount: 10,
        entryDate: DateTime(2026, 5, 24),
      ),
      throwsArgumentError,
    );
  });

  test('creates direct expense locally', () async {
    final created = await repository.createDirectExpense(
      walletId: 'w1',
      assistantId: 'u1',
      amount: 75,
      entryDate: DateTime(2026, 5, 24),
      note: 'transport',
      createdBy: 'u1',
    );

    final watched = await repository.watchDirectExpenses(walletId: 'w1').first;

    final pending = await SyncQueueDao(database).pending();

    expect(created.amount, 75);
    expect(watched, hasLength(1));
    expect(watched.first.note, 'transport');
    expect(pending, hasLength(1));
    expect(pending.single.entityType, 'direct_expense');
    expect(pending.single.entityId, created.id);
  });

  test('monthly close creates snapshot and locks period entries', () async {
    await repository.createMoneyEntry(
      walletId: 'w1',
      assistantId: 'u1',
      type: EntryType.moneyReceived,
      amount: 1000,
      entryDate: DateTime(2026, 5, 10),
      createdBy: 'u2',
    );
    await repository.createMoneyEntry(
      walletId: 'w1',
      assistantId: 'u1',
      type: EntryType.moneyReturned,
      amount: 200,
      entryDate: DateTime(2026, 5, 11),
      createdBy: 'u1',
    );
    await repository.createDirectExpense(
      walletId: 'w1',
      assistantId: 'u1',
      amount: 50,
      entryDate: DateTime(2026, 5, 12),
      createdBy: 'u1',
    );

    final snapshot = await repository.closeMonthlyPeriod(
      walletId: 'w1',
      assistantId: 'u1',
      periodMonth: '2026-05',
      closedBy: 'u2',
    );
    final money = await repository.watchMoneyEntries(walletId: 'w1').first;
    final direct = await repository.watchDirectExpenses(walletId: 'w1').first;

    expect(snapshot.closingBalance, 750);
    expect(snapshot.snapshotHash, isNotEmpty);
    expect(money.every((entry) => entry.isLocked), isTrue);
    expect(direct.every((entry) => entry.isLocked), isTrue);
  });
}
