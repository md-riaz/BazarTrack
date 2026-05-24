import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../domain/entities/direct_expense.dart' as domain;
import '../../domain/entities/money_entry.dart' as domain;

class MoneyEntryDao {
  MoneyEntryDao(this._db);

  final db.AppDatabase _db;

  Stream<List<domain.MoneyEntry>> watchMoneyEntries({
    String? walletId,
    String? assistantId,
    DateTime? from,
    DateTime? to,
  }) {
    return _moneyEntryQuery(
      walletId: walletId,
      assistantId: assistantId,
      from: from,
      to: to,
    ).watch().map((rows) => rows.map(_mapMoneyEntry).toList(growable: false));
  }

  Future<List<domain.MoneyEntry>> getMoneyEntries({
    String? walletId,
    String? assistantId,
    DateTime? from,
    DateTime? to,
  }) async {
    final rows = await _moneyEntryQuery(
      walletId: walletId,
      assistantId: assistantId,
      from: from,
      to: to,
    ).get();
    return rows.map(_mapMoneyEntry).toList(growable: false);
  }

  Future<domain.MoneyEntry> insertMoneyEntry({
    required String id,
    required String walletId,
    required String assistantId,
    required String type,
    required double amount,
    required DateTime entryDate,
    String? bazarId,
    String? note,
    String? createdBy,
  }) async {
    final now = DateTime.now();
    await _db
        .into(_db.moneyEntries)
        .insert(
          db.MoneyEntriesCompanion.insert(
            id: id,
            walletId: walletId,
            assistantId: assistantId,
            bazarId: bazarId == null ? const Value.absent() : Value(bazarId),
            type: type,
            amount: amount,
            note: note == null ? const Value.absent() : Value(note),
            entryDate: entryDate,
            createdBy: createdBy == null
                ? const Value.absent()
                : Value(createdBy),
            createdAt: now,
            updatedAt: now,
          ),
        );

    final created =
        await (_db.select(
          _db.moneyEntries,
        )..where((table) => table.id.equals(id))).join([
          leftOuterJoin(
            _db.wallets,
            _db.wallets.id.equalsExp(_db.moneyEntries.walletId),
          ),
          leftOuterJoin(
            _db.users,
            _db.users.id.equalsExp(_db.moneyEntries.assistantId),
          ),
        ]).getSingleOrNull();
    if (created == null) {
      throw StateError('Money entry was not created: $id');
    }
    return _mapMoneyEntry(created);
  }

  Future<void> lockPeriod({
    required String walletId,
    required DateTime from,
    required DateTime to,
    String? assistantId,
  }) async {
    await (_db.update(_db.moneyEntries)..where((table) {
          var predicate =
              table.walletId.equals(walletId) &
              table.entryDate.isBiggerOrEqualValue(from) &
              table.entryDate.isSmallerThanValue(to);
          if (assistantId != null) {
            predicate = predicate & table.assistantId.equals(assistantId);
          }
          return predicate;
        }))
        .write(const db.MoneyEntriesCompanion(isLocked: Value(true)));
  }

  JoinedSelectStatement<HasResultSet, dynamic> _moneyEntryQuery({
    String? walletId,
    String? assistantId,
    DateTime? from,
    DateTime? to,
  }) {
    final query = _db.select(_db.moneyEntries).join([
      leftOuterJoin(
        _db.wallets,
        _db.wallets.id.equalsExp(_db.moneyEntries.walletId),
      ),
      leftOuterJoin(
        _db.users,
        _db.users.id.equalsExp(_db.moneyEntries.assistantId),
      ),
    ]);
    if (walletId != null) {
      query.where(_db.moneyEntries.walletId.equals(walletId));
    }
    if (assistantId != null) {
      query.where(_db.moneyEntries.assistantId.equals(assistantId));
    }
    if (from != null) {
      query.where(_db.moneyEntries.entryDate.isBiggerOrEqualValue(from));
    }
    if (to != null) {
      query.where(_db.moneyEntries.entryDate.isSmallerThanValue(to));
    }
    query.orderBy([OrderingTerm.desc(_db.moneyEntries.entryDate)]);
    return query;
  }

  domain.MoneyEntry _mapMoneyEntry(TypedResult row) {
    final entry = row.readTable(_db.moneyEntries);
    final wallet = row.readTableOrNull(_db.wallets);
    final assistant = row.readTableOrNull(_db.users);
    return domain.MoneyEntry(
      id: entry.id,
      walletId: entry.walletId,
      walletName: wallet?.name,
      assistantId: entry.assistantId,
      assistantName: assistant?.name,
      bazarId: entry.bazarId,
      type: domain.entryTypeFromDb(entry.type),
      amount: entry.amount,
      note: entry.note,
      entryDate: entry.entryDate,
      createdBy: entry.createdBy,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
      isLocked: entry.isLocked,
    );
  }
}

class DirectExpenseDao {
  DirectExpenseDao(this._db);

  final db.AppDatabase _db;

  Stream<List<domain.DirectExpense>> watchDirectExpenses({
    String? walletId,
    String? assistantId,
    DateTime? from,
    DateTime? to,
  }) {
    return _directExpenseQuery(
      walletId: walletId,
      assistantId: assistantId,
      from: from,
      to: to,
    ).watch().map(
      (rows) => rows.map(_mapDirectExpense).toList(growable: false),
    );
  }

  Future<List<domain.DirectExpense>> getDirectExpenses({
    String? walletId,
    String? assistantId,
    DateTime? from,
    DateTime? to,
  }) async {
    final rows = await _directExpenseQuery(
      walletId: walletId,
      assistantId: assistantId,
      from: from,
      to: to,
    ).get();
    return rows.map(_mapDirectExpense).toList(growable: false);
  }

  Future<domain.DirectExpense> insertDirectExpense({
    required String id,
    required String walletId,
    required String assistantId,
    required double amount,
    required DateTime entryDate,
    String? note,
    String? receiptUrl,
    String? createdBy,
  }) async {
    final now = DateTime.now();
    await _db
        .into(_db.directExpenses)
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

    final created =
        await (_db.select(
          _db.directExpenses,
        )..where((table) => table.id.equals(id))).join([
          leftOuterJoin(
            _db.wallets,
            _db.wallets.id.equalsExp(_db.directExpenses.walletId),
          ),
          leftOuterJoin(
            _db.users,
            _db.users.id.equalsExp(_db.directExpenses.assistantId),
          ),
        ]).getSingleOrNull();
    if (created == null) {
      throw StateError('Direct expense was not created: $id');
    }
    return _mapDirectExpense(created);
  }

  Future<void> lockPeriod({
    required String walletId,
    required DateTime from,
    required DateTime to,
    String? assistantId,
  }) async {
    await (_db.update(_db.directExpenses)..where((table) {
          var predicate =
              table.walletId.equals(walletId) &
              table.entryDate.isBiggerOrEqualValue(from) &
              table.entryDate.isSmallerThanValue(to);
          if (assistantId != null) {
            predicate = predicate & table.assistantId.equals(assistantId);
          }
          return predicate;
        }))
        .write(const db.DirectExpensesCompanion(isLocked: Value(true)));
  }

  JoinedSelectStatement<HasResultSet, dynamic> _directExpenseQuery({
    String? walletId,
    String? assistantId,
    DateTime? from,
    DateTime? to,
  }) {
    final query = _db.select(_db.directExpenses).join([
      leftOuterJoin(
        _db.wallets,
        _db.wallets.id.equalsExp(_db.directExpenses.walletId),
      ),
      leftOuterJoin(
        _db.users,
        _db.users.id.equalsExp(_db.directExpenses.assistantId),
      ),
    ]);
    if (walletId != null) {
      query.where(_db.directExpenses.walletId.equals(walletId));
    }
    if (assistantId != null) {
      query.where(_db.directExpenses.assistantId.equals(assistantId));
    }
    if (from != null) {
      query.where(_db.directExpenses.entryDate.isBiggerOrEqualValue(from));
    }
    if (to != null) {
      query.where(_db.directExpenses.entryDate.isSmallerThanValue(to));
    }
    query.orderBy([OrderingTerm.desc(_db.directExpenses.entryDate)]);
    return query;
  }

  domain.DirectExpense _mapDirectExpense(TypedResult row) {
    final entry = row.readTable(_db.directExpenses);
    final wallet = row.readTableOrNull(_db.wallets);
    final assistant = row.readTableOrNull(_db.users);
    return domain.DirectExpense(
      id: entry.id,
      walletId: entry.walletId,
      walletName: wallet?.name,
      assistantId: entry.assistantId,
      assistantName: assistant?.name,
      amount: entry.amount,
      note: entry.note,
      entryDate: entry.entryDate,
      receiptUrl: entry.receiptUrl,
      createdBy: entry.createdBy,
      createdAt: entry.createdAt,
      isLocked: entry.isLocked,
    );
  }
}

class MonthlyCloseDao {
  MonthlyCloseDao(this._db);

  final db.AppDatabase _db;

  Future<db.WalletSnapshot?> getSnapshot({
    required String walletId,
    required String periodMonth,
    String? assistantId,
  }) {
    final query = _db.select(_db.walletSnapshots)
      ..where((table) {
        final base =
            table.walletId.equals(walletId) &
            table.periodMonth.equals(periodMonth);
        if (assistantId == null) {
          return base & table.assistantId.isNull();
        }
        return base & table.assistantId.equals(assistantId);
      });
    return query.getSingleOrNull();
  }

  Future<db.WalletSnapshot> upsertSnapshot({
    required String id,
    required String walletId,
    required String periodMonth,
    required double openingBalance,
    required double closingBalance,
    required DateTime closedAt,
    String? assistantId,
    String? snapshotHash,
    String? closedBy,
    String? notes,
  }) async {
    final existing = await getSnapshot(
      walletId: walletId,
      periodMonth: periodMonth,
      assistantId: assistantId,
    );

    if (existing == null) {
      await _db
          .into(_db.walletSnapshots)
          .insert(
            db.WalletSnapshotsCompanion.insert(
              id: id,
              walletId: walletId,
              assistantId: assistantId == null
                  ? const Value.absent()
                  : Value(assistantId),
              periodMonth: periodMonth,
              openingBalance: openingBalance,
              closingBalance: closingBalance,
              snapshotHash: snapshotHash == null
                  ? const Value.absent()
                  : Value(snapshotHash),
              closedBy: closedBy == null
                  ? const Value.absent()
                  : Value(closedBy),
              closedAt: closedAt,
              notes: notes == null ? const Value.absent() : Value(notes),
            ),
          );
      final created = await getSnapshot(
        walletId: walletId,
        periodMonth: periodMonth,
        assistantId: assistantId,
      );
      if (created == null) {
        throw StateError('Monthly snapshot was not created: $id');
      }
      return created;
    }

    await (_db.update(
      _db.walletSnapshots,
    )..where((table) => table.id.equals(existing.id))).write(
      db.WalletSnapshotsCompanion(
        openingBalance: Value(openingBalance),
        closingBalance: Value(closingBalance),
        snapshotHash: snapshotHash == null
            ? const Value.absent()
            : Value(snapshotHash),
        closedBy: closedBy == null ? const Value.absent() : Value(closedBy),
        closedAt: Value(closedAt),
        notes: notes == null ? const Value.absent() : Value(notes),
      ),
    );
    final updated = await getSnapshot(
      walletId: walletId,
      periodMonth: periodMonth,
      assistantId: assistantId,
    );
    if (updated == null) {
      throw StateError('Monthly snapshot was not updated: ${existing.id}');
    }
    return updated;
  }

  Future<List<db.BazarItem>> getClosedBazarItems({
    required String walletId,
    DateTime? from,
    DateTime? to,
    String? assistantId,
  }) async {
    final query =
        _db.select(_db.bazarItems).join([
            innerJoin(
              _db.bazars,
              _db.bazars.id.equalsExp(_db.bazarItems.bazarId),
            ),
          ])
          ..where(_db.bazars.walletId.equals(walletId))
          ..where(_db.bazarItems.status.equals('done'))
          ..where(_db.bazars.status.equals('closed'));
    if (assistantId != null) {
      query.where(_db.bazars.assignedTo.equals(assistantId));
    }
    if (from != null) {
      query.where(_db.bazars.bazarDate.isBiggerOrEqualValue(from));
    }
    if (to != null) {
      query.where(_db.bazars.bazarDate.isSmallerThanValue(to));
    }
    final rows = await query.get();
    return rows
        .map((row) => row.readTable(_db.bazarItems))
        .toList(growable: false);
  }

  Future<void> lockClosedBazars({
    required String walletId,
    required DateTime from,
    required DateTime to,
    String? assistantId,
  }) async {
    await (_db.update(_db.bazars)..where((table) {
          var predicate =
              table.walletId.equals(walletId) &
              table.status.equals('closed') &
              table.bazarDate.isBiggerOrEqualValue(from) &
              table.bazarDate.isSmallerThanValue(to);
          if (assistantId != null) {
            predicate = predicate & table.assignedTo.equals(assistantId);
          }
          return predicate;
        }))
        .write(db.BazarsCompanion(updatedAt: Value(DateTime.now())));
  }

  db.WalletSnapshot mapSnapshot(db.WalletSnapshot row) => row;
}
