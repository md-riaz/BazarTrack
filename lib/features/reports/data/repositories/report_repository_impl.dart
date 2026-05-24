import 'dart:async';

import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../../../shared/models/app_enums.dart';
import '../../../money/data/repositories/money_entry_repository_impl.dart';
import '../../../money/domain/entities/money_entry.dart';
import '../../domain/entities/report_summary.dart';
import '../../domain/repositories/report_repository.dart';

class ReportRepositoryImpl implements ReportRepository {
  ReportRepositoryImpl(this._db);

  final db.AppDatabase _db;

  @override
  Stream<ReportSummary> watchMonthlySummary(String periodMonth) {
    return Stream.periodic(
      const Duration(milliseconds: 250),
    ).asyncMap((_) => getMonthlySummary(periodMonth)).distinct(_summaryEquals);
  }

  Future<ReportSummary> getMonthlySummary(String periodMonth) async {
    final range = MonthRange.parse(periodMonth);
    final moneyRows =
        await (_db.select(_db.moneyEntries).join([
                leftOuterJoin(
                  _db.wallets,
                  _db.wallets.id.equalsExp(_db.moneyEntries.walletId),
                ),
              ])
              ..where(
                _db.moneyEntries.entryDate.isBiggerOrEqualValue(range.start),
              )
              ..where(_db.moneyEntries.entryDate.isSmallerThanValue(range.end)))
            .get();
    final directRows =
        await (_db.select(_db.directExpenses).join([
                leftOuterJoin(
                  _db.wallets,
                  _db.wallets.id.equalsExp(_db.directExpenses.walletId),
                ),
              ])
              ..where(
                _db.directExpenses.entryDate.isBiggerOrEqualValue(range.start),
              )
              ..where(
                _db.directExpenses.entryDate.isSmallerThanValue(range.end),
              ))
            .get();
    final bazarRows =
        await (_db.select(_db.bazarItems).join([
                innerJoin(
                  _db.bazars,
                  _db.bazars.id.equalsExp(_db.bazarItems.bazarId),
                ),
                leftOuterJoin(
                  _db.wallets,
                  _db.wallets.id.equalsExp(_db.bazars.walletId),
                ),
              ])
              ..where(_db.bazarItems.status.equals('done'))
              ..where(_db.bazars.bazarDate.isBiggerOrEqualValue(range.start))
              ..where(_db.bazars.bazarDate.isSmallerThanValue(range.end)))
            .get();

    var totalReceived = 0.0;
    var totalReturned = 0.0;
    var adjustmentTotal = 0.0;
    final walletStats = <String, _WalletAccumulator>{};

    for (final row in moneyRows) {
      final entry = row.readTable(_db.moneyEntries);
      final wallet = row.readTableOrNull(_db.wallets);
      final accumulator = walletStats.putIfAbsent(
        entry.walletId,
        () => _WalletAccumulator(entry.walletId, wallet?.name ?? 'ওয়ালেট'),
      );
      switch (entryTypeFromDb(entry.type)) {
        case EntryType.moneyReceived:
          totalReceived += entry.amount.abs();
          accumulator.received += entry.amount.abs();
        case EntryType.moneyReturned:
          totalReturned += entry.amount.abs();
          accumulator.returnedAmount += entry.amount.abs();
        case EntryType.adjustment:
          adjustmentTotal += entry.amount;
          accumulator.adjustment += entry.amount;
      }
    }

    var totalSpent = 0.0;
    for (final row in directRows) {
      final entry = row.readTable(_db.directExpenses);
      final wallet = row.readTableOrNull(_db.wallets);
      final accumulator = walletStats.putIfAbsent(
        entry.walletId,
        () => _WalletAccumulator(entry.walletId, wallet?.name ?? 'ওয়ালেট'),
      );
      totalSpent += entry.amount.abs();
      accumulator.spent += entry.amount.abs();
    }

    final itemStats = <String, _ItemAccumulator>{};
    for (final row in bazarRows) {
      final item = row.readTable(_db.bazarItems);
      final bazar = row.readTable(_db.bazars);
      final wallet = row.readTableOrNull(_db.wallets);
      final spent = (item.price ?? 0).abs();
      totalSpent += spent;
      final walletAccumulator = walletStats.putIfAbsent(
        bazar.walletId,
        () => _WalletAccumulator(bazar.walletId, wallet?.name ?? 'ওয়ালেট'),
      );
      walletAccumulator.spent += spent;
      final itemAccumulator = itemStats.putIfAbsent(
        item.name,
        () => _ItemAccumulator(item.name),
      );
      itemAccumulator
        ..quantity += 1
        ..totalSpent += spent;
    }

    final walletBreakdowns =
        walletStats.values
            .map(
              (wallet) => WalletBreakdown(
                walletId: wallet.walletId,
                walletName: wallet.walletName,
                received: wallet.received,
                spent: wallet.spent,
                returnedAmount: wallet.returnedAmount,
                netBalance:
                    wallet.received -
                    wallet.spent -
                    wallet.returnedAmount +
                    wallet.adjustment,
              ),
            )
            .toList(growable: false)
          ..sort((a, b) => b.netBalance.compareTo(a.netBalance));

    final topItems =
        itemStats.values
            .map(
              (item) => ItemPurchaseSummary(
                name: item.name,
                quantity: item.quantity,
                totalSpent: item.totalSpent,
              ),
            )
            .toList(growable: false)
          ..sort((a, b) => b.totalSpent.compareTo(a.totalSpent));

    return ReportSummary(
      periodMonth: periodMonth,
      totalReceived: totalReceived,
      totalSpent: totalSpent,
      totalReturned: totalReturned,
      adjustmentTotal: adjustmentTotal,
      netBalance: totalReceived - totalSpent - totalReturned + adjustmentTotal,
      walletBreakdowns: walletBreakdowns,
      topItems: topItems.take(5).toList(growable: false),
    );
  }

  bool _summaryEquals(ReportSummary previous, ReportSummary next) {
    return previous.totalReceived == next.totalReceived &&
        previous.totalSpent == next.totalSpent &&
        previous.totalReturned == next.totalReturned &&
        previous.adjustmentTotal == next.adjustmentTotal &&
        previous.netBalance == next.netBalance &&
        previous.walletBreakdowns.length == next.walletBreakdowns.length &&
        previous.topItems.length == next.topItems.length;
  }
}

class _WalletAccumulator {
  _WalletAccumulator(this.walletId, this.walletName);

  final String walletId;
  final String walletName;
  double received = 0;
  double spent = 0;
  double returnedAmount = 0;
  double adjustment = 0;
}

class _ItemAccumulator {
  _ItemAccumulator(this.name);

  final String name;
  int quantity = 0;
  double totalSpent = 0;
}
