import 'dart:math';

import '../../../../shared/models/app_enums.dart';
import '../../domain/entities/bazar_entities.dart';

class MockBazarRemoteDataSource {
  MockBazarRemoteDataSource({Random? random}) : _random = random ?? Random();

  final Random _random;

  Future<List<Bazar>> fetchBazars() async {
    await _delay();
    final now = DateTime(2025, 5, 23, 12);
    final yesterday = now.subtract(const Duration(days: 1));
    return [
      Bazar(
        id: 'b1',
        walletId: 'w2',
        createdBy: 'u3',
        assignedTo: 'u1',
        title: 'CEO Personal বাজার',
        note: 'আজকের বাজার',
        status: BazarStatus.open,
        bazarDate: now,
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now,
        walletName: 'CEO Personal',
        assignedName: 'Rahim Uddin',
        itemCount: 4,
        spent: 180,
      ),
      Bazar(
        id: 'b2',
        walletId: 'w1',
        createdBy: 'u4',
        title: 'Office Wallet বাজার',
        note: 'যে কেউ নিতে পারবে',
        status: BazarStatus.draft,
        bazarDate: now,
        createdAt: now.subtract(const Duration(hours: 1)),
        updatedAt: now,
        walletName: 'Office Wallet',
        itemCount: 0,
        spent: 0,
      ),
      Bazar(
        id: 'b3',
        walletId: 'w3',
        createdBy: 'u4',
        assignedTo: 'u2',
        title: 'CTO Personal বাজার',
        note: 'গতকালের বাজার',
        status: BazarStatus.closed,
        bazarDate: yesterday,
        createdAt: yesterday.subtract(const Duration(hours: 3)),
        updatedAt: yesterday,
        closedAt: yesterday.add(const Duration(hours: 4)),
        walletName: 'CTO Personal',
        assignedName: 'Karim Sheikh',
        itemCount: 0,
        spent: 0,
      ),
    ];
  }

  Future<void> publishItemUpdate(BazarItem item) async {
    await _delay();
  }

  Future<void> publishBazarClose(Bazar bazar) async {
    await _delay();
  }

  Future<void> publishBazarCreate(Bazar bazar) async {
    await _delay();
  }

  Future<void> _delay() async {
    await Future<void>.delayed(
      Duration(milliseconds: 300 + _random.nextInt(201)),
    );
  }
}
