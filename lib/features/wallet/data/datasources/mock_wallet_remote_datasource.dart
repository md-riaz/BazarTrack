import '../../domain/entities/wallet.dart';

abstract class WalletRemoteDataSource {
  Future<List<Wallet>> fetchWallets();
}

class MockWalletRemoteDataSource implements WalletRemoteDataSource {
  const MockWalletRemoteDataSource();

  @override
  Future<List<Wallet>> fetchWallets() async {
    final now = DateTime(2025, 5, 23, 12);
    return [
      Wallet(
        id: 'w1',
        name: 'Office Wallet',
        type: 'shared',
        isActive: true,
        createdBy: 'u4',
        createdAt: now,
      ),
      Wallet(
        id: 'w2',
        name: 'CEO Personal',
        type: 'personal',
        isActive: true,
        createdBy: 'u3',
        createdAt: now,
      ),
      Wallet(
        id: 'w3',
        name: 'CTO Personal',
        type: 'personal',
        isActive: true,
        createdBy: 'u4',
        createdAt: now,
      ),
    ];
  }
}
