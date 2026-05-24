import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart' as db;
import '../entities/balance_result.dart';
import '../entities/wallet_snapshot.dart' as domain;

class BalanceCalculator {
  BalanceCalculator(this._database);

  final db.AppDatabase _database;

  Stream<BalanceResult> watchBalance({
    required String walletId,
    String? assistantId,
  }) {
    final moneyQuery = _database.select(_database.moneyEntries)
      ..where((table) => table.walletId.equals(walletId));
    final directQuery = _database.select(_database.directExpenses)
      ..where((table) => table.walletId.equals(walletId));
    final bazarQuery =
        _database.select(_database.bazars).join([
            innerJoin(
              _database.bazarItems,
              _database.bazarItems.bazarId.equalsExp(_database.bazars.id),
            ),
          ])
          ..where(_database.bazars.walletId.equals(walletId))
          ..where(_database.bazarItems.status.equals('done'));
    final snapshotQuery = _database.select(_database.walletSnapshots)
      ..where((table) {
        final walletPredicate = table.walletId.equals(walletId);
        if (assistantId == null) {
          return walletPredicate & table.assistantId.isNull();
        }
        return walletPredicate & table.assistantId.equals(assistantId);
      })
      ..orderBy([(table) => OrderingTerm.desc(table.closedAt)]);

    if (assistantId != null) {
      moneyQuery.where((table) => table.assistantId.equals(assistantId));
      directQuery.where((table) => table.assistantId.equals(assistantId));
      bazarQuery.where(_database.bazars.assignedTo.equals(assistantId));
    }

    return Stream.multi((controller) {
      var moneyEntries = const <db.MoneyEntry>[];
      var directExpenses = const <db.DirectExpense>[];
      var bazarRows = const <TypedResult>[];
      var snapshots = const <db.WalletSnapshot>[];

      void emit() {
        controller.add(
          calculate(
            walletId: walletId,
            assistantId: assistantId,
            moneyEntries: moneyEntries
                .map(
                  (entry) => MoneyBalanceEntry(
                    amount: entry.amount,
                    type: entry.type,
                    entryDate: entry.entryDate,
                  ),
                )
                .toList(growable: false),
            directExpenses: directExpenses
                .map(
                  (entry) => DirectExpenseBalanceEntry(
                    amount: entry.amount,
                    entryDate: entry.entryDate,
                  ),
                )
                .toList(growable: false),
            bazarItems: bazarRows
                .map((row) {
                  final bazar = row.readTable(_database.bazars);
                  final item = row.readTable(_database.bazarItems);
                  return BazarItemBalanceEntry(
                    price: item.price ?? 0,
                    status: bazar.status,
                    date: bazar.closedAt ?? bazar.bazarDate,
                  );
                })
                .toList(growable: false),
            snapshots: snapshots.map(_mapSnapshot).toList(growable: false),
          ),
        );
      }

      final subscriptions = [
        moneyQuery.watch().listen((rows) {
          moneyEntries = rows;
          emit();
        }),
        directQuery.watch().listen((rows) {
          directExpenses = rows;
          emit();
        }),
        bazarQuery.watch().listen((rows) {
          bazarRows = rows;
          emit();
        }),
        snapshotQuery.watch().listen((rows) {
          snapshots = rows;
          emit();
        }),
      ];

      controller.onCancel = () async {
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
      };
    });
  }

  BalanceResult calculate({
    required String walletId,
    required List<MoneyBalanceEntry> moneyEntries,
    required List<DirectExpenseBalanceEntry> directExpenses,
    required List<BazarItemBalanceEntry> bazarItems,
    required List<domain.WalletSnapshot> snapshots,
    String? assistantId,
  }) {
    final latestSnapshot = snapshots.isEmpty
        ? null
        : snapshots.reduce(
            (latest, next) =>
                latest.closedAt.isAfter(next.closedAt) ? latest : next,
          );
    final since = latestSnapshot?.closedAt;
    final snapshotBase = latestSnapshot?.closingBalance ?? 0;

    var confirmed = snapshotBase;
    var inProgress = 0.0;

    for (final entry in moneyEntries.where(
      (entry) => _isAfterSnapshot(entry.entryDate, since),
    )) {
      switch (entry.type) {
        case 'money_received':
          confirmed += entry.amount;
        case 'money_returned':
          confirmed -= entry.amount;
        case 'adjustment':
          confirmed += entry.amount;
        default:
          confirmed += entry.amount;
      }
    }

    for (final entry in directExpenses.where(
      (entry) => _isAfterSnapshot(entry.entryDate, since),
    )) {
      confirmed -= entry.amount;
    }

    for (final item in bazarItems.where(
      (item) => _isAfterSnapshot(item.date, since),
    )) {
      if (item.status == 'closed') {
        confirmed -= item.price;
      } else {
        inProgress -= item.price;
      }
    }

    return BalanceResult(
      walletId: walletId,
      assistantId: assistantId,
      confirmedBalance: confirmed,
      inProgressAmount: inProgress,
      snapshotBase: snapshotBase,
    );
  }

  bool _isAfterSnapshot(DateTime date, DateTime? snapshotAt) {
    return snapshotAt == null || date.isAfter(snapshotAt);
  }

  domain.WalletSnapshot _mapSnapshot(db.WalletSnapshot row) {
    return domain.WalletSnapshot(
      id: row.id,
      walletId: row.walletId,
      assistantId: row.assistantId,
      periodMonth: row.periodMonth,
      openingBalance: row.openingBalance,
      closingBalance: row.closingBalance,
      snapshotHash: row.snapshotHash,
      closedBy: row.closedBy,
      closedAt: row.closedAt,
      notes: row.notes,
    );
  }
}

class MoneyBalanceEntry {
  const MoneyBalanceEntry({
    required this.amount,
    required this.type,
    required this.entryDate,
  });

  final double amount;
  final String type;
  final DateTime entryDate;
}

class DirectExpenseBalanceEntry {
  const DirectExpenseBalanceEntry({
    required this.amount,
    required this.entryDate,
  });

  final double amount;
  final DateTime entryDate;
}

class BazarItemBalanceEntry {
  const BazarItemBalanceEntry({
    required this.price,
    required this.status,
    required this.date,
  });

  final double price;
  final String status;
  final DateTime date;
}
