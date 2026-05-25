import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../domain/entities/wallet.dart' as domain;
import '../../domain/entities/wallet_ledger_entry.dart';
import '../../domain/entities/wallet_member.dart' as domain;
import '../../domain/entities/wallet_snapshot.dart' as domain;

class WalletDao {
  WalletDao(this._database);

  final db.AppDatabase _database;

  Stream<List<domain.Wallet>> watchWallets() {
    return (_database.select(_database.wallets)
          ..orderBy([(table) => OrderingTerm.asc(table.createdAt)]))
        .watch()
        .map((rows) => rows.map(_mapWallet).toList(growable: false));
  }

  Future<List<domain.Wallet>> getWallets() async {
    final rows = await (_database.select(
      _database.wallets,
    )..orderBy([(table) => OrderingTerm.asc(table.createdAt)])).get();
    return rows.map(_mapWallet).toList(growable: false);
  }

  Stream<domain.Wallet?> watchWallet(String walletId) {
    return (_database.select(_database.wallets)
          ..where((table) => table.id.equals(walletId)))
        .watchSingleOrNull()
        .map((row) => row == null ? null : _mapWallet(row));
  }

  domain.Wallet _mapWallet(db.Wallet row) {
    return domain.Wallet(
      id: row.id,
      name: row.name,
      type: row.type,
      isActive: row.isActive,
      createdBy: row.createdBy,
      createdAt: row.createdAt,
    );
  }
}

class WalletMemberDao {
  WalletMemberDao(this._database);

  final db.AppDatabase _database;

  Stream<List<domain.WalletMember>> watchAllMembers() {
    return (_database.select(_database.walletMembers)
          ..orderBy([(table) => OrderingTerm.asc(table.createdAt)]))
        .watch()
        .map((rows) => rows.map(_mapMember).toList(growable: false));
  }

  Stream<List<domain.WalletMember>> watchMembers(String walletId) {
    return (_database.select(_database.walletMembers)
          ..where((table) => table.walletId.equals(walletId))
          ..orderBy([(table) => OrderingTerm.asc(table.createdAt)]))
        .watch()
        .map((rows) => rows.map(_mapMember).toList(growable: false));
  }

  domain.WalletMember _mapMember(db.WalletMember row) {
    return domain.WalletMember(
      id: row.id,
      walletId: row.walletId,
      userId: row.userId,
      role: row.role,
      createdAt: row.createdAt,
    );
  }
}

class WalletSnapshotDao {
  WalletSnapshotDao(this._database);

  final db.AppDatabase _database;

  Stream<List<domain.WalletSnapshot>> watchSnapshots({
    required String walletId,
    String? assistantId,
  }) {
    return (_database.select(_database.walletSnapshots)
          ..where((table) {
            final walletPredicate = table.walletId.equals(walletId);
            if (assistantId == null) {
              return walletPredicate;
            }
            return walletPredicate & table.assistantId.equals(assistantId);
          })
          ..orderBy([(table) => OrderingTerm.desc(table.closedAt)]))
        .watch()
        .map((rows) => rows.map(_mapSnapshot).toList(growable: false));
  }

  Future<domain.WalletSnapshot?> latestSnapshot({
    required String walletId,
    String? assistantId,
  }) async {
    final query = _database.select(_database.walletSnapshots)
      ..where((table) {
        final walletPredicate = table.walletId.equals(walletId);
        if (assistantId == null) {
          return walletPredicate & table.assistantId.isNull();
        }
        return walletPredicate & table.assistantId.equals(assistantId);
      })
      ..orderBy([(table) => OrderingTerm.desc(table.closedAt)])
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row == null ? null : _mapSnapshot(row);
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

class WalletLedgerDao {
  WalletLedgerDao(this._database);

  final db.AppDatabase _database;

  Stream<List<WalletLedgerEntry>> watchLedgerEntries({
    required String walletId,
    String? assistantId,
    DateTime? since,
  }) {
    final moneyQuery = _database.select(_database.moneyEntries).join([
      leftOuterJoin(
        _database.users,
        _database.users.id.equalsExp(_database.moneyEntries.assistantId),
      ),
    ])..where(_database.moneyEntries.walletId.equals(walletId));
    if (assistantId != null) {
      moneyQuery.where(_database.moneyEntries.assistantId.equals(assistantId));
    }
    if (since != null) {
      moneyQuery.where(
        _database.moneyEntries.entryDate.isBiggerThanValue(since),
      );
    }

    final directQuery = _database.select(_database.directExpenses).join([
      leftOuterJoin(
        _database.users,
        _database.users.id.equalsExp(_database.directExpenses.assistantId),
      ),
    ])..where(_database.directExpenses.walletId.equals(walletId));
    if (assistantId != null) {
      directQuery.where(
        _database.directExpenses.assistantId.equals(assistantId),
      );
    }
    if (since != null) {
      directQuery.where(
        _database.directExpenses.entryDate.isBiggerThanValue(since),
      );
    }

    final bazarQuery =
        _database.select(_database.bazars).join([
            innerJoin(
              _database.bazarItems,
              _database.bazarItems.bazarId.equalsExp(_database.bazars.id),
            ),
            leftOuterJoin(
              _database.users,
              _database.users.id.equalsExp(_database.bazars.assignedTo),
            ),
          ])
          ..where(_database.bazars.walletId.equals(walletId))
          ..where(_database.bazarItems.status.equals('done'));
    if (assistantId != null) {
      bazarQuery.where(_database.bazars.assignedTo.equals(assistantId));
    }
    if (since != null) {
      bazarQuery.where(_database.bazars.bazarDate.isBiggerThanValue(since));
    }

    return Stream.multi((controller) {
      var moneyRows = const <TypedResult>[];
      var directRows = const <TypedResult>[];
      var bazarRows = const <TypedResult>[];

      void emit() {
        final entries = [
          ...moneyRows.map(_mapMoneyEntry),
          ...directRows.map(_mapDirectExpense),
          ...bazarRows.map(_mapBazarExpense),
        ]..sort((a, b) => b.date.compareTo(a.date));
        controller.add(entries);
      }

      final subscriptions = [
        moneyQuery.watch().listen((rows) {
          moneyRows = rows;
          emit();
        }),
        directQuery.watch().listen((rows) {
          directRows = rows;
          emit();
        }),
        bazarQuery.watch().listen((rows) {
          bazarRows = rows;
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

  WalletLedgerEntry _mapMoneyEntry(TypedResult row) {
    final entry = row.readTable(_database.moneyEntries);
    final user = row.readTableOrNull(_database.users);
    final isReturn = entry.type == 'money_returned';
    return WalletLedgerEntry(
      id: entry.id,
      walletId: entry.walletId,
      assistantId: entry.assistantId,
      assistantName: user?.name,
      bazarId: entry.bazarId,
      type: isReturn
          ? WalletLedgerEntryType.moneyReturned
          : WalletLedgerEntryType.moneyReceived,
      amount: isReturn ? -entry.amount.abs() : entry.amount.abs(),
      note: entry.note,
      date: entry.entryDate,
      isLocked: entry.isLocked,
    );
  }

  WalletLedgerEntry _mapDirectExpense(TypedResult row) {
    final entry = row.readTable(_database.directExpenses);
    final user = row.readTableOrNull(_database.users);
    return WalletLedgerEntry(
      id: entry.id,
      walletId: entry.walletId,
      assistantId: entry.assistantId,
      assistantName: user?.name,
      type: WalletLedgerEntryType.directExpense,
      amount: -entry.amount.abs(),
      note: entry.note,
      date: entry.entryDate,
      isLocked: entry.isLocked,
    );
  }

  WalletLedgerEntry _mapBazarExpense(TypedResult row) {
    final bazar = row.readTable(_database.bazars);
    final item = row.readTable(_database.bazarItems);
    final user = row.readTableOrNull(_database.users);
    return WalletLedgerEntry(
      id: item.id,
      walletId: bazar.walletId,
      assistantId: bazar.assignedTo ?? bazar.createdBy,
      assistantName: user?.name,
      bazarId: bazar.id,
      type: WalletLedgerEntryType.bazarExpense,
      amount: -(item.price ?? 0).abs(),
      note: item.name,
      date: bazar.closedAt ?? bazar.bazarDate,
      isLocked: bazar.status == 'closed',
    );
  }
}
