import '../entities/balance_result.dart';
import '../entities/wallet.dart';
import '../entities/wallet_ledger_entry.dart';
import '../entities/wallet_member.dart';
import '../entities/wallet_snapshot.dart';
import '../entities/wallet_summary.dart';

abstract class WalletRepository {
  Stream<List<Wallet>> watchWallets();

  Future<List<Wallet>> getWallets();

  Stream<Wallet?> watchWallet(String walletId);

  Stream<List<WalletMember>> watchMembers(String walletId);

  Stream<List<WalletSnapshot>> watchSnapshots({
    required String walletId,
    String? assistantId,
  });

  Stream<BalanceResult> watchBalance({
    required String walletId,
    String? assistantId,
  });

  Stream<List<WalletSummary>> watchWalletSummaries({String? assistantId});

  Stream<List<WalletLedgerEntry>> watchLedgerEntries({
    required String walletId,
    String? assistantId,
  });
}
