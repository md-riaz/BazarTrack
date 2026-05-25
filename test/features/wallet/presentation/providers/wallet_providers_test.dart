import 'package:bazar/bootstrap.dart';
import 'package:bazar/core/database/app_database.dart';
import 'package:bazar/features/auth/domain/entities/user.dart' as auth;
import 'package:bazar/features/auth/presentation/providers/auth_provider.dart';
import 'package:bazar/features/wallet/presentation/providers/wallet_providers.dart';
import 'package:bazar/shared/models/app_enums.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;

  setUp(() async {
    database = AppDatabase.forTesting();
    await _seedWalletData(database);
  });

  tearDown(() async {
    await database.close();
  });

  ProviderContainer containerFor(auth.User user) {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        currentUserProvider.overrideWith((ref) => Stream.value(user)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('admin wallet list provider emits every wallet', () async {
    final container = containerFor(_user('admin', UserRole.admin));
    await container.read(currentUserProvider.future);

    final wallets = await container.read(walletListProvider.future);

    expect(wallets.map((wallet) => wallet.id), ['w1', 'w2', 'w3']);
  });

  test('assistant wallet list provider emits all active wallets', () async {
    final container = containerFor(_user('assistant', UserRole.assistant));
    await container.read(currentUserProvider.future);

    final wallets = await container.read(walletListProvider.future);

    expect(wallets.map((wallet) => wallet.id), ['w1', 'w3']);
  });

  test('owner wallet list provider emits active member wallets only', () async {
    final container = containerFor(_user('owner', UserRole.owner));
    await container.read(currentUserProvider.future);

    final wallets = await container.read(walletListProvider.future);

    expect(wallets.map((wallet) => wallet.id), ['w3']);
  });

  test('admin wallet list still includes inactive wallets', () async {
    final container = containerFor(_user('admin', UserRole.admin));
    await container.read(currentUserProvider.future);

    final wallets = await container.read(walletListProvider.future);

    expect(wallets.map((wallet) => wallet.id), contains('w2'));
    expect(wallets.firstWhere((wallet) => wallet.id == 'w2').isActive, isFalse);
  });

  test('wallet balance provider emits calculated balance', () async {
    final container = containerFor(_user('admin', UserRole.admin));
    await container.read(currentUserProvider.future);

    final balance = await container.read(
      walletBalanceProvider(const WalletBalanceRequest(walletId: 'w1')).future,
    );

    expect(balance.confirmedBalance, 700);
  });
}

auth.User _user(String id, UserRole role) {
  return auth.User(id: id, name: id, role: role, isActive: true);
}

Future<void> _seedWalletData(AppDatabase database) async {
  final now = DateTime(2026, 5, 24);
  await database.batch((batch) {
    batch.insertAll(database.users, [
      UsersCompanion.insert(
        id: 'admin',
        name: 'Admin',
        role: 'admin',
        createdAt: now,
        updatedAt: now,
      ),
      UsersCompanion.insert(
        id: 'owner',
        name: 'Owner',
        role: 'owner',
        createdAt: now,
        updatedAt: now,
      ),
      UsersCompanion.insert(
        id: 'assistant',
        name: 'Assistant',
        role: 'assistant',
        createdAt: now,
        updatedAt: now,
      ),
    ]);
    batch.insertAll(database.wallets, [
      WalletsCompanion.insert(
        id: 'w1',
        name: 'Office Wallet',
        type: 'shared',
        isActive: const Value(true),
        createdAt: now,
      ),
      WalletsCompanion.insert(
        id: 'w2',
        name: 'Owner Wallet',
        type: 'personal',
        isActive: const Value(false),
        createdBy: const Value('owner'),
        createdAt: now,
      ),
      WalletsCompanion.insert(
        id: 'w3',
        name: 'Active Project Wallet',
        type: 'event',
        isActive: const Value(true),
        createdAt: now,
      ),
    ]);
    batch.insertAll(database.walletMembers, [
      WalletMembersCompanion.insert(
        id: 'wm-owner-w2',
        walletId: 'w2',
        userId: 'owner',
        role: 'owner',
        createdAt: Value(now),
      ),
      WalletMembersCompanion.insert(
        id: 'wm-owner-w3',
        walletId: 'w3',
        userId: 'owner',
        role: 'owner',
        createdAt: Value(now),
      ),
    ]);
    batch.insert(
      database.moneyEntries,
      MoneyEntriesCompanion.insert(
        id: 'm1',
        walletId: 'w1',
        assistantId: 'assistant',
        type: 'money_received',
        amount: 700,
        entryDate: now,
        createdAt: now,
        updatedAt: now,
      ),
    );
  });
}
