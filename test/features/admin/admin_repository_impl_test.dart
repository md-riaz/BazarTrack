import 'package:bazar/core/database/app_database.dart';
import 'package:bazar/features/admin/data/datasources/admin_local_datasource.dart';
import 'package:bazar/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:bazar/features/admin/domain/entities/admin_entities.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late AdminRepositoryImpl repository;

  setUp(() async {
    database = AppDatabase.forTesting();
    repository = AdminRepositoryImpl(AdminLocalDataSource(database));
    await _seedAdminData(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('loads users and wallets from Drift', () async {
    final users = await repository.getUsers();
    final wallets = await repository.getWallets();

    expect(users.map((user) => user.id), [
      'admin',
      'owner',
      'owner2',
      'assistant',
    ]);
    expect(users.first.role, AdminRole.admin);
    expect(wallets.map((wallet) => wallet.id), ['w1', 'w2']);
    expect(wallets.first.ownerIds, ['owner']);
    expect(wallets.first.owners, ['Owner']);
  });

  test('creates owner user and wallet memberships', () async {
    final created = await repository.createUser(
      const CreateAdminUserRequest(
        name: 'New Owner',
        phone: '01700-000000',
        role: AdminRole.owner,
        walletIds: ['w1', 'w2'],
      ),
    );

    final users = await repository.getUsers();
    final memberships = await (database.select(
      database.walletMembers,
    )..where((table) => table.userId.equals(created.id))).get();

    expect(created.name, 'New Owner');
    expect(users.map((user) => user.id), contains(created.id));
    expect(memberships.map((member) => member.walletId), ['w1', 'w2']);
    expect(memberships.every((member) => member.role == 'owner'), isTrue);
  });

  test('creates wallet and owner memberships', () async {
    final created = await repository.createWallet(
      const CreateAdminWalletRequest(
        name: 'Project Wallet',
        type: 'shared',
        ownerIds: ['owner', 'owner2'],
      ),
    );

    final wallet = await (database.select(
      database.wallets,
    )..where((table) => table.id.equals(created.id))).getSingle();
    final memberships = await (database.select(
      database.walletMembers,
    )..where((table) => table.walletId.equals(created.id))).get();

    expect(wallet.name, 'Project Wallet');
    expect(created.ownerIds, ['owner', 'owner2']);
    expect(memberships.map((member) => member.userId), ['owner', 'owner2']);
  });

  test('rejects invalid wallet owner ids', () async {
    expect(
      () => repository.createWallet(
        const CreateAdminWalletRequest(
          name: 'Project Wallet',
          type: 'shared',
          ownerIds: ['assistant'],
        ),
      ),
      throwsArgumentError,
    );
    expect(
      () => repository.createWallet(
        const CreateAdminWalletRequest(
          name: 'Project Wallet',
          type: 'shared',
          ownerIds: ['missing'],
        ),
      ),
      throwsArgumentError,
    );
  });

  test('updates wallet and replaces owner memberships', () async {
    final updated = await repository.updateWallet(
      const UpdateAdminWalletRequest(
        id: 'w1',
        name: 'Updated Wallet',
        type: 'event',
        ownerIds: ['owner2'],
      ),
    );

    final memberships = await (database.select(
      database.walletMembers,
    )..where((table) => table.walletId.equals('w1'))).get();

    expect(updated.name, 'Updated Wallet');
    expect(updated.type, 'event');
    expect(updated.ownerIds, ['owner2']);
    expect(memberships.map((member) => member.userId), ['owner2']);
  });

  test('soft deactivates wallet without deleting row', () async {
    await repository.setWalletActive(walletId: 'w1', isActive: false);

    final wallet = await (database.select(
      database.wallets,
    )..where((table) => table.id.equals('w1'))).getSingle();
    final wallets = await repository.getWallets();

    expect(wallet.isActive, isFalse);
    expect(wallets.firstWhere((item) => item.id == 'w1').isActive, isFalse);
  });
}

Future<void> _seedAdminData(AppDatabase database) async {
  final now = DateTime(2026, 5, 25);
  await database.batch((batch) {
    batch.insertAll(database.users, [
      UsersCompanion.insert(
        id: 'admin',
        name: 'Admin',
        phone: const Value('01000-ADMIN'),
        role: 'admin',
        createdAt: now,
        updatedAt: now,
      ),
      UsersCompanion.insert(
        id: 'owner',
        name: 'Owner',
        phone: const Value('01900-000000'),
        role: 'owner',
        createdAt: now,
        updatedAt: now,
      ),
      UsersCompanion.insert(
        id: 'owner2',
        name: 'Owner Two',
        phone: const Value('01901-000000'),
        role: 'owner',
        createdAt: now,
        updatedAt: now,
      ),
      UsersCompanion.insert(
        id: 'assistant',
        name: 'Assistant',
        phone: const Value('01700-000000'),
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
        isActive: const Value(true),
        createdAt: now,
      ),
    ]);
    batch.insert(
      database.walletMembers,
      WalletMembersCompanion.insert(
        id: 'wm-owner-w1',
        walletId: 'w1',
        userId: 'owner',
        role: 'owner',
        createdAt: Value(now),
      ),
    );
  });
}
