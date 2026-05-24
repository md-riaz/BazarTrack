import '../../domain/entities/balance_result.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/entities/wallet_ledger_entry.dart';
import '../../domain/entities/wallet_member.dart';
import '../../domain/entities/wallet_snapshot.dart';
import '../../domain/entities/wallet_summary.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../../domain/services/balance_calculator.dart';
import '../datasources/mock_wallet_remote_datasource.dart';
import '../datasources/wallet_local_datasource.dart';

class WalletRepositoryImpl implements WalletRepository {
  WalletRepositoryImpl({
    required WalletDao walletDao,
    required WalletMemberDao walletMemberDao,
    required WalletSnapshotDao walletSnapshotDao,
    required WalletLedgerDao walletLedgerDao,
    required BalanceCalculator balanceCalculator,
    required WalletRemoteDataSource remoteDataSource,
  }) : _walletDao = walletDao,
       _walletMemberDao = walletMemberDao,
       _walletSnapshotDao = walletSnapshotDao,
       _walletLedgerDao = walletLedgerDao,
       _balanceCalculator = balanceCalculator,
       _remoteDataSource = remoteDataSource;

  final WalletDao _walletDao;
  final WalletMemberDao _walletMemberDao;
  final WalletSnapshotDao _walletSnapshotDao;
  final WalletLedgerDao _walletLedgerDao;
  final BalanceCalculator _balanceCalculator;
  final WalletRemoteDataSource _remoteDataSource;

  @override
  Future<List<Wallet>> getWallets() async {
    final localWallets = await _walletDao.getWallets();
    if (localWallets.isNotEmpty) {
      return localWallets;
    }
    return _remoteDataSource.fetchWallets();
  }

  @override
  Stream<List<Wallet>> watchWallets() {
    return _walletDao.watchWallets();
  }

  @override
  Stream<Wallet?> watchWallet(String walletId) {
    return _walletDao.watchWallet(walletId);
  }

  @override
  Stream<List<WalletMember>> watchMembers(String walletId) {
    return _walletMemberDao.watchMembers(walletId);
  }

  @override
  Stream<List<WalletSnapshot>> watchSnapshots({
    required String walletId,
    String? assistantId,
  }) {
    return _walletSnapshotDao.watchSnapshots(
      walletId: walletId,
      assistantId: assistantId,
    );
  }

  @override
  Stream<BalanceResult> watchBalance({
    required String walletId,
    String? assistantId,
  }) {
    return _balanceCalculator.watchBalance(
      walletId: walletId,
      assistantId: assistantId,
    );
  }

  @override
  Stream<List<WalletSummary>> watchWalletSummaries({String? assistantId}) {
    return Stream.multi((controller) {
      var wallets = const <Wallet>[];
      final balanceSubscriptions = <String, dynamic>{};
      final balances = <String, BalanceResult>{};

      void emit() {
        controller.add(
          wallets
              .map(
                (wallet) => WalletSummary(
                  wallet: wallet,
                  balance:
                      balances[wallet.id] ??
                      BalanceResult(
                        walletId: wallet.id,
                        assistantId: assistantId,
                        confirmedBalance: 0,
                        inProgressAmount: 0,
                      ),
                ),
              )
              .toList(growable: false),
        );
      }

      final walletSubscription = watchWallets().listen((nextWallets) {
        wallets = nextWallets;
        final walletIds = wallets.map((wallet) => wallet.id).toSet();
        final staleIds = balanceSubscriptions.keys
            .where((walletId) => !walletIds.contains(walletId))
            .toList(growable: false);
        for (final walletId in staleIds) {
          balanceSubscriptions.remove(walletId)?.cancel();
          balances.remove(walletId);
        }
        for (final wallet in wallets) {
          if (balanceSubscriptions.containsKey(wallet.id)) {
            continue;
          }
          balanceSubscriptions[wallet.id] =
              watchBalance(
                walletId: wallet.id,
                assistantId: assistantId,
              ).listen((balance) {
                balances[wallet.id] = balance;
                emit();
              });
        }
        emit();
      });

      controller.onCancel = () async {
        await walletSubscription.cancel();
        for (final subscription in balanceSubscriptions.values) {
          await subscription.cancel();
        }
      };
    });
  }

  @override
  Stream<List<WalletLedgerEntry>> watchLedgerEntries({
    required String walletId,
    String? assistantId,
  }) {
    return _walletLedgerDao.watchLedgerEntries(
      walletId: walletId,
      assistantId: assistantId,
    );
  }
}
