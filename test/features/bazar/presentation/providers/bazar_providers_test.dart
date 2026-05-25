import 'package:bazar/bootstrap.dart';
import 'package:bazar/core/database/app_database.dart';
import 'package:bazar/core/mock/mock_seed.dart';
import 'package:bazar/features/auth/domain/entities/user.dart' as auth;
import 'package:bazar/features/auth/presentation/providers/auth_provider.dart';
import 'package:bazar/features/bazar/presentation/providers/bazar_providers.dart';
import 'package:bazar/features/wallet/presentation/providers/wallet_providers.dart';
import 'package:bazar/shared/models/app_enums.dart';
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

  test('frequentItemsProvider exposes seeded frequent items', () {
    final container = containerFor(_user('u1', UserRole.assistant));

    expect(container.read(frequentItemsProvider), MockSeed.frequentItems);
  });

  test('admin bazar list provider emits every bazar', () async {
    final container = containerFor(_user('admin', UserRole.admin));
    await container.read(currentUserProvider.future);

    final bazars = await container.read(bazarsProvider.future);

    expect(bazars.map((bazar) => bazar.id), ['b1', 'b2', 'b3']);
  });

  test('owner bazar list provider emits bazars for visible wallets', () async {
    final container = containerFor(_user('u3', UserRole.owner));
    await container.read(currentUserProvider.future);
    await container.read(walletListProvider.future);

    final bazars = await container.read(bazarsProvider.future);

    expect(bazars.map((bazar) => bazar.id), ['b1']);
  });

  test(
    'assistant bazar list provider emits unassigned and assigned bazars',
    () async {
      final container = containerFor(_user('u1', UserRole.assistant));
      await container.read(currentUserProvider.future);

      final bazars = await container.read(bazarsProvider.future);

      expect(bazars.map((bazar) => bazar.id), ['b1', 'b2']);
    },
  );

  test('bazar status filter remains applied after role scoping', () async {
    final container = containerFor(_user('u1', UserRole.assistant));
    await container.read(currentUserProvider.future);
    container.read(selectedBazarStatusProvider.notifier).state =
        BazarStatus.draft;

    final bazars = await container.read(bazarsProvider.future);

    expect(bazars.map((bazar) => bazar.id), ['b2']);
  });
}

auth.User _user(String id, UserRole role) {
  return auth.User(id: id, name: id, role: role, isActive: true);
}
