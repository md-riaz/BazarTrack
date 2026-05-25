import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../bootstrap.dart';
import '../../../../shared/models/app_enums.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
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
  final currentUser = ref.watch(currentUserProvider).valueOrNull;
  if (currentUser == null) {
    return Stream.value(const <Wallet>[]);
  }

  final walletStream = ref.watch(walletRepositoryProvider).watchWallets();
  if (currentUser.role == UserRole.admin) {
    return walletStream;
  }

  final memberStream = ref.watch(walletMemberDaoProvider).watchAllMembers();
  return _combineWalletsAndMembers(
    wallets: walletStream,
    members: memberStream,
    visibleWallets: (wallets, members) => _visibleWalletsForUser(
      wallets: wallets,
      members: members,
      userId: currentUser.id,
      role: currentUser.role,
    ),
  );
});

final walletSummariesProvider = StreamProvider<List<WalletSummary>>((ref) {
  final currentUser = ref.watch(currentUserProvider).valueOrNull;
  if (currentUser == null) {
    return Stream.value(const <WalletSummary>[]);
  }

  final summariesStream = ref
      .watch(walletRepositoryProvider)
      .watchWalletSummaries(
        assistantId: currentUser.role == UserRole.assistant
            ? currentUser.id
            : null,
      );
  if (currentUser.role == UserRole.admin) {
    return summariesStream;
  }

  final memberStream = ref.watch(walletMemberDaoProvider).watchAllMembers();
  return _combineSummariesAndMembers(
    summaries: summariesStream,
    members: memberStream,
    visibleSummaries: (summaries, members) {
      final visibleWalletIds = _visibleWalletsForUser(
        wallets: summaries.map((summary) => summary.wallet).toList(),
        members: members,
        userId: currentUser.id,
        role: currentUser.role,
      ).map((wallet) => wallet.id).toSet();
      return summaries
          .where((summary) => visibleWalletIds.contains(summary.wallet.id))
          .toList(growable: false);
    },
  );
});

final walletProvider = StreamProvider.family<Wallet?, String>((ref, walletId) {
  return ref.watch(walletRepositoryProvider).watchWallet(walletId);
});

final walletMembersProvider = StreamProvider.family<List<WalletMember>, String>(
  (ref, walletId) {
    return ref.watch(walletRepositoryProvider).watchMembers(walletId);
  },
);

Stream<List<Wallet>> _combineWalletsAndMembers({
  required Stream<List<Wallet>> wallets,
  required Stream<List<WalletMember>> members,
  required List<Wallet> Function(List<Wallet>, List<WalletMember>)
  visibleWallets,
}) {
  return Stream.multi((controller) {
    List<Wallet>? latestWallets;
    List<WalletMember>? latestMembers;

    void emit() {
      final wallets = latestWallets;
      final members = latestMembers;
      if (wallets == null || members == null) return;
      controller.add(visibleWallets(wallets, members));
    }

    final subscriptions = <StreamSubscription<dynamic>>[
      wallets.listen((nextWallets) {
        latestWallets = nextWallets;
        emit();
      }, onError: controller.addError),
      members.listen((nextMembers) {
        latestMembers = nextMembers;
        emit();
      }, onError: controller.addError),
    ];

    controller.onCancel = () async {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    };
  });
}

Stream<List<WalletSummary>> _combineSummariesAndMembers({
  required Stream<List<WalletSummary>> summaries,
  required Stream<List<WalletMember>> members,
  required List<WalletSummary> Function(List<WalletSummary>, List<WalletMember>)
  visibleSummaries,
}) {
  return Stream.multi((controller) {
    List<WalletSummary>? latestSummaries;
    List<WalletMember>? latestMembers;

    void emit() {
      final summaries = latestSummaries;
      final members = latestMembers;
      if (summaries == null || members == null) return;
      controller.add(visibleSummaries(summaries, members));
    }

    final subscriptions = <StreamSubscription<dynamic>>[
      summaries.listen((nextSummaries) {
        latestSummaries = nextSummaries;
        emit();
      }, onError: controller.addError),
      members.listen((nextMembers) {
        latestMembers = nextMembers;
        emit();
      }, onError: controller.addError),
    ];

    controller.onCancel = () async {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    };
  });
}

List<Wallet> _visibleWalletsForUser({
  required List<Wallet> wallets,
  required List<WalletMember> members,
  required String userId,
  required UserRole role,
}) {
  return switch (role) {
    UserRole.admin => wallets,
    UserRole.assistant =>
      wallets.where((wallet) => wallet.isActive).toList(growable: false),
    UserRole.owner =>
      wallets
          .where((wallet) {
            return members.any(
              (member) =>
                  member.walletId == wallet.id && member.userId == userId,
            );
          })
          .toList(growable: false),
  };
}

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
