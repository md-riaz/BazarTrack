import 'package:bazar/core/database/app_database.dart';
import 'package:bazar/features/wallet/data/datasources/mock_wallet_remote_datasource.dart';
import 'package:bazar/features/wallet/data/datasources/wallet_local_datasource.dart';
import 'package:bazar/features/wallet/data/repositories/wallet_repository_impl.dart';
import 'package:bazar/features/wallet/domain/services/balance_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late WalletRepositoryImpl repository;

  setUp(() async {
    database = AppDatabase.forTesting();
    repository = WalletRepositoryImpl(
      walletDao: WalletDao(database),
      walletMemberDao: WalletMemberDao(database),
      walletSnapshotDao: WalletSnapshotDao(database),
      walletLedgerDao: WalletLedgerDao(database),
      balanceCalculator: BalanceCalculator(database),
      remoteDataSource: const MockWalletRemoteDataSource(),
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
        .into(database.wallets)
        .insert(
          WalletsCompanion.insert(
            id: 'w1',
            name: 'Office Wallet',
            type: 'shared',
            createdAt: now,
          ),
        );
    await database
        .into(database.walletMembers)
        .insert(
          WalletMembersCompanion.insert(
            id: 'wm1',
            walletId: 'w1',
            userId: 'u1',
            role: 'assistant',
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
            entryDate: now,
            createdAt: now,
            updatedAt: now,
          ),
        );
  });

  tearDown(() async {
    await database.close();
  });

  test('watches wallets from local Drift store', () async {
    final wallets = await repository.watchWallets().first;

    expect(wallets, hasLength(1));
    expect(wallets.first.id, 'w1');
    expect(wallets.first.name, 'Office Wallet');
  });

  test('watches balance through repository', () async {
    final balance = await repository.watchBalance(walletId: 'w1').first;

    expect(balance.confirmedBalance, 500);
    expect(balance.inProgressAmount, 0);
  });

  test('watches wallet members', () async {
    final members = await repository.watchMembers('w1').first;

    expect(members, hasLength(1));
    expect(members.first.userId, 'u1');
  });

  test('falls back to mock remote when local wallets are empty', () async {
    await database.delete(database.walletMembers).go();
    await database.delete(database.moneyEntries).go();
    await database.delete(database.wallets).go();

    final wallets = await repository.getWallets();

    expect(wallets.map((wallet) => wallet.id), containsAll(['w1', 'w2', 'w3']));
  });
}
