import '../../../../features/wallet/domain/entities/wallet_snapshot.dart';
import '../../../../shared/models/app_enums.dart';
import '../entities/direct_expense.dart';
import '../entities/money_entry.dart';

abstract class MoneyEntryRepository {
  Stream<List<MoneyEntry>> watchMoneyEntries({
    String? walletId,
    String? assistantId,
    DateTime? from,
    DateTime? to,
  });

  Stream<List<DirectExpense>> watchDirectExpenses({
    String? walletId,
    String? assistantId,
    DateTime? from,
    DateTime? to,
  });

  Future<MoneyEntry> createMoneyEntry({
    required String walletId,
    required String assistantId,
    required EntryType type,
    required double amount,
    required DateTime entryDate,
    String? bazarId,
    String? note,
    String? createdBy,
  });

  Future<DirectExpense> createDirectExpense({
    required String walletId,
    required String assistantId,
    required double amount,
    required DateTime entryDate,
    String? note,
    String? receiptUrl,
    String? createdBy,
  });

  Future<WalletSnapshot> closeMonthlyPeriod({
    required String walletId,
    required String periodMonth,
    String? assistantId,
    String? closedBy,
    String? notes,
  });
}
