import 'package:bazar/bootstrap.dart';
import 'package:bazar/core/database/app_database.dart';
import 'package:bazar/features/wallet/presentation/providers/wallet_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late ProviderContainer container;

  setUp(() async {
    database = AppDatabase.forTesting();
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
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
        .into(database.moneyEntries)
        .insert(
          MoneyEntriesCompanion.insert(
            id: 'm1',
            walletId: 'w1',
            assistantId: 'u1',
            type: 'money_received',
            amount: 700,
            entryDate: now,
            createdAt: now,
            updatedAt: now,
          ),
        );
  });

  tearDown(() async {
    container.dispose();
    await database.close();
  });

  test('wallet list provider emits Drift wallets', () async {
    final wallets = await container.read(walletListProvider.future);

    expect(wallets, hasLength(1));
    expect(wallets.first.name, 'Office Wallet');
  });

  test('wallet balance provider emits calculated balance', () async {
    final balance = await container.read(
      walletBalanceProvider(const WalletBalanceRequest(walletId: 'w1')).future,
    );

    expect(balance.confirmedBalance, 700);
  });
}
