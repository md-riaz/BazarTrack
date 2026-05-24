import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../bootstrap.dart';
import '../../../../shared/models/app_enums.dart';
import '../../data/datasources/mock_money_remote_datasource.dart';
import '../../data/datasources/money_local_data_source.dart';
import '../../data/repositories/money_entry_repository_impl.dart';
import '../../domain/entities/direct_expense.dart';
import '../../domain/entities/money_entry.dart';
import '../../domain/repositories/money_entry_repository.dart';

final moneyRemoteDataSourceProvider = Provider<MoneyRemoteDataSource>((ref) {
  return const MockMoneyRemoteDataSource();
});

final moneyEntryDaoProvider = Provider<MoneyEntryDao>((ref) {
  return MoneyEntryDao(ref.watch(appDatabaseProvider));
});

final directExpenseDaoProvider = Provider<DirectExpenseDao>((ref) {
  return DirectExpenseDao(ref.watch(appDatabaseProvider));
});

final monthlyCloseDaoProvider = Provider<MonthlyCloseDao>((ref) {
  return MonthlyCloseDao(ref.watch(appDatabaseProvider));
});

final moneyEntryRepositoryProvider = Provider<MoneyEntryRepository>((ref) {
  return MoneyEntryRepositoryImpl(
    moneyEntryDao: ref.watch(moneyEntryDaoProvider),
    directExpenseDao: ref.watch(directExpenseDaoProvider),
    monthlyCloseDao: ref.watch(monthlyCloseDaoProvider),
    remoteDataSource: ref.watch(moneyRemoteDataSourceProvider),
  );
});

class MoneyEntryFilter {
  const MoneyEntryFilter({this.walletId, this.assistantId, this.from, this.to});

  final String? walletId;
  final String? assistantId;
  final DateTime? from;
  final DateTime? to;

  @override
  bool operator ==(Object other) {
    return other is MoneyEntryFilter &&
        other.walletId == walletId &&
        other.assistantId == assistantId &&
        other.from == from &&
        other.to == to;
  }

  @override
  int get hashCode => Object.hash(walletId, assistantId, from, to);
}

final moneyEntriesProvider =
    StreamProvider.family<List<MoneyEntry>, MoneyEntryFilter>((ref, filter) {
      return ref
          .watch(moneyEntryRepositoryProvider)
          .watchMoneyEntries(
            walletId: filter.walletId,
            assistantId: filter.assistantId,
            from: filter.from,
            to: filter.to,
          );
    });

final directExpensesProvider =
    StreamProvider.family<List<DirectExpense>, MoneyEntryFilter>((ref, filter) {
      return ref
          .watch(moneyEntryRepositoryProvider)
          .watchDirectExpenses(
            walletId: filter.walletId,
            assistantId: filter.assistantId,
            from: filter.from,
            to: filter.to,
          );
    });

class CreateMoneyEntryRequest {
  const CreateMoneyEntryRequest({
    required this.walletId,
    required this.assistantId,
    required this.type,
    required this.amount,
    required this.entryDate,
    this.bazarId,
    this.note,
    this.createdBy,
  });

  final String walletId;
  final String assistantId;
  final EntryType type;
  final double amount;
  final DateTime entryDate;
  final String? bazarId;
  final String? note;
  final String? createdBy;
}

final createMoneyEntryProvider = FutureProvider.autoDispose
    .family<MoneyEntry, CreateMoneyEntryRequest>((ref, request) {
      return ref
          .watch(moneyEntryRepositoryProvider)
          .createMoneyEntry(
            walletId: request.walletId,
            assistantId: request.assistantId,
            type: request.type,
            amount: request.amount,
            entryDate: request.entryDate,
            bazarId: request.bazarId,
            note: request.note,
            createdBy: request.createdBy,
          );
    });
