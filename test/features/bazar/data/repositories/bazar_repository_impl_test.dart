import 'package:bazar/core/database/app_database.dart';
import 'package:bazar/core/mock/mock_seed.dart';
import 'package:bazar/features/bazar/data/datasources/bazar_local_data_source.dart';
import 'package:bazar/features/bazar/data/datasources/mock_bazar_remote_data_source.dart';
import 'package:bazar/features/bazar/data/repositories/bazar_repository_impl.dart';
import 'package:bazar/shared/models/app_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late BazarRepositoryImpl repository;

  setUp(() async {
    database = AppDatabase.forTesting();
    await database.customStatement('PRAGMA foreign_keys = OFF');
    await MockSeed.seed(database);
    repository = BazarRepositoryImpl(
      localDataSource: BazarLocalDataSource(database),
      remoteDataSource: MockBazarRemoteDataSource(),
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('watches seeded bazars from local Drift first', () async {
    final bazars = await repository.watchBazars().first;

    expect(bazars, hasLength(3));
    expect(bazars.first.title, 'CEO Personal বাজার');
    expect(bazars.first.itemCount, 4);
    expect(bazars.first.spent, 180);
  });

  test('price greater than zero transitions item to done', () async {
    final updated = await repository.updateItem(
      itemId: 'i3',
      price: 220,
      userId: 'u1',
    );

    expect(updated.status, ItemStatus.done);
    expect(updated.price, 220);

    final events = await repository.watchActivity('b1').first;
    expect(events.any((event) => event.action == 'item.purchased'), isTrue);
  });

  test('explicit not found status writes activity log', () async {
    final updated = await repository.updateItem(
      itemId: 'i4',
      status: ItemStatus.notFound,
      note: 'বাজারে নেই',
      userId: 'u1',
    );

    expect(updated.status, ItemStatus.notFound);
    expect(updated.note, 'বাজারে নেই');

    final events = await repository.watchActivity('b1').first;
    expect(events.any((event) => event.action == 'item.not_found'), isTrue);
  });

  test('summary calculates counts and balance', () async {
    await repository.updateItem(itemId: 'i3', price: 220, userId: 'u1');

    final summary = await repository.getSummary('b1');

    expect(summary.purchasedCount, 2);
    expect(summary.notFoundCount, 1);
    expect(summary.pendingCount, 1);
    expect(summary.totalSpent, 400);
    expect(summary.newBalance, summary.previousBalance - 400);
  });

  test('close bazar stores closed status and activity', () async {
    final closed = await repository.closeBazar(bazarId: 'b1', userId: 'u1');

    expect(closed.status, BazarStatus.closed);
    expect(closed.closedAt, isNotNull);

    final events = await repository.watchActivity('b1').first;
    expect(events.any((event) => event.action == 'bazar.closed'), isTrue);
  });
}
