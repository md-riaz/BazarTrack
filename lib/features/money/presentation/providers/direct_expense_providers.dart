import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../bootstrap.dart';
import '../../../../core/database/app_database.dart' as db;
import '../../domain/entities/direct_expense.dart' as domain;
import '../../domain/repositories/money_entry_repository.dart';
import 'money_providers.dart';

final directExpenseLocalDataSourceProvider =
    Provider<DirectExpenseLocalDataSource>((ref) {
      return DirectExpenseLocalDataSource(ref.watch(appDatabaseProvider));
    });

final directExpenseControllerProvider =
    StateNotifierProvider<DirectExpenseController, AsyncValue<void>>((ref) {
      return DirectExpenseController(ref.watch(moneyEntryRepositoryProvider));
    });

class DirectExpenseLocalDataSource {
  DirectExpenseLocalDataSource(this._database);

  final db.AppDatabase _database;
  final Uuid _uuid = const Uuid();

  Future<domain.DirectExpense> createDirectExpense({
    required String walletId,
    required String assistantId,
    required double amount,
    required DateTime entryDate,
    String? note,
    String? receiptUrl,
    String? createdBy,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    await _database
        .into(_database.directExpenses)
        .insert(
          db.DirectExpensesCompanion.insert(
            id: id,
            walletId: walletId,
            assistantId: assistantId,
            amount: amount,
            note: note == null ? const Value.absent() : Value(note),
            entryDate: entryDate,
            receiptUrl: receiptUrl == null
                ? const Value.absent()
                : Value(receiptUrl),
            createdBy: createdBy == null
                ? const Value.absent()
                : Value(createdBy),
            createdAt: now,
          ),
        );
    await _database
        .into(_database.activityLogs)
        .insert(
          db.ActivityLogsCompanion.insert(
            id: 'act-${now.microsecondsSinceEpoch}',
            userId: createdBy == null ? const Value.absent() : Value(createdBy),
            action: 'direct_expense.created',
            entityType: 'direct_expense',
            entityId: id,
            newValue: Value('{"amount":$amount}'),
            createdAt: now,
          ),
        );
    final row = await (_database.select(
      _database.directExpenses,
    )..where((table) => table.id.equals(id))).getSingle();
    return _map(row);
  }

  domain.DirectExpense _map(db.DirectExpense row) {
    return domain.DirectExpense(
      id: row.id,
      walletId: row.walletId,
      assistantId: row.assistantId,
      amount: row.amount,
      note: row.note,
      entryDate: row.entryDate,
      receiptUrl: row.receiptUrl,
      createdBy: row.createdBy,
      createdAt: row.createdAt,
      isLocked: row.isLocked,
    );
  }
}

class DirectExpenseController extends StateNotifier<AsyncValue<void>> {
  DirectExpenseController(this._repository) : super(const AsyncData(null));

  final MoneyEntryRepository _repository;

  Future<domain.DirectExpense?> createDirectExpense({
    required String walletId,
    required String assistantId,
    required double amount,
    required DateTime entryDate,
    String? note,
    String? receiptUrl,
    String? createdBy,
  }) async {
    state = const AsyncLoading();
    try {
      final expense = await _repository.createDirectExpense(
        walletId: walletId,
        assistantId: assistantId,
        amount: amount,
        entryDate: entryDate,
        note: note,
        receiptUrl: receiptUrl,
        createdBy: createdBy,
      );
      state = const AsyncData(null);
      return expense;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }
}
