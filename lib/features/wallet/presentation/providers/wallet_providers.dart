import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../bootstrap.dart';
import '../../data/datasources/mock_wallet_remote_datasource.dart';
import '../../data/datasources/wallet_local_datasource.dart';
import '../../data/repositories/wallet_repository_impl.dart';
import '../../domain/entities/balance_result.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/entities/wallet_ledger_entry.dart';
import '../../domain/entities/wallet_member.dart';
import '../../domain/entities/wallet_snapshot.dart';
import '../../domain/entities/wallet_summary.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../../domain/services/balance_calculator.dart';

final walletRemoteDataSourceProvider = Provider<WalletRemoteDataSource>((ref) {
  return const MockWalletRemoteDataSource();
});

final walletDaoProvider = Provider<WalletDao>((ref) {
  return WalletDao(ref.watch(appDatabaseProvider));
});

final walletMemberDaoProvider = Provider<WalletMemberDao>((ref) {
  return WalletMemberDao(ref.watch(appDatabaseProvider));
});

final walletSnapshotDaoProvider = Provider<WalletSnapshotDao>((ref) {
  return WalletSnapshotDao(ref.watch(appDatabaseProvider));
});

final walletLedgerDaoProvider = Provider<WalletLedgerDao>((ref) {
  return WalletLedgerDao(ref.watch(appDatabaseProvider));
});

final balanceCalculatorProvider = Provider<BalanceCalculator>((ref) {
  return BalanceCalculator(ref.watch(appDatabaseProvider));
});

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepositoryImpl(
    walletDao: ref.watch(walletDaoProvider),
    walletMemberDao: ref.watch(walletMemberDaoProvider),
    walletSnapshotDao: ref.watch(walletSnapshotDaoProvider),
    walletLedgerDao: ref.watch(walletLedgerDaoProvider),
    balanceCalculator: ref.watch(balanceCalculatorProvider),
    remoteDataSource: ref.watch(walletRemoteDataSourceProvider),
  );
});

final walletListProvider = StreamProvider<List<Wallet>>((ref) {
  return ref.watch(walletRepositoryProvider).watchWallets();
});

final walletSummariesProvider = StreamProvider<List<WalletSummary>>((ref) {
  return ref.watch(walletRepositoryProvider).watchWalletSummaries();
});

final walletProvider = StreamProvider.family<Wallet?, String>((ref, walletId) {
  return ref.watch(walletRepositoryProvider).watchWallet(walletId);
});

final walletMembersProvider = StreamProvider.family<List<WalletMember>, String>(
  (ref, walletId) {
    return ref.watch(walletRepositoryProvider).watchMembers(walletId);
  },
);

class WalletBalanceRequest {
  const WalletBalanceRequest({required this.walletId, this.assistantId});

  final String walletId;
  final String? assistantId;

  @override
  bool operator ==(Object other) {
    return other is WalletBalanceRequest &&
        other.walletId == walletId &&
        other.assistantId == assistantId;
  }

  @override
  int get hashCode => Object.hash(walletId, assistantId);
}

final walletBalanceProvider =
    StreamProvider.family<BalanceResult, WalletBalanceRequest>((ref, request) {
      return ref
          .watch(walletRepositoryProvider)
          .watchBalance(
            walletId: request.walletId,
            assistantId: request.assistantId,
          );
    });

final walletSnapshotsProvider =
    StreamProvider.family<List<WalletSnapshot>, WalletBalanceRequest>((
      ref,
      request,
    ) {
      return ref
          .watch(walletRepositoryProvider)
          .watchSnapshots(
            walletId: request.walletId,
            assistantId: request.assistantId,
          );
    });

final walletLedgerProvider =
    StreamProvider.family<List<WalletLedgerEntry>, WalletBalanceRequest>((
      ref,
      request,
    ) {
      return ref
          .watch(walletRepositoryProvider)
          .watchLedgerEntries(
            walletId: request.walletId,
            assistantId: request.assistantId,
          );
    });
