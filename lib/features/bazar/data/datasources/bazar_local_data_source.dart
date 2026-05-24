import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../../../shared/models/app_enums.dart';
import '../mappers/bazar_mappers.dart';

class LocalBazarRow {
  const LocalBazarRow({
    required this.bazar,
    required this.itemCount,
    required this.spent,
    this.walletName,
    this.assignedName,
  });

  final db.Bazar bazar;
  final String? walletName;
  final String? assignedName;
  final int itemCount;
  final double spent;
}

class LocalActivityRow {
  const LocalActivityRow({required this.activity, this.userName});

  final db.ActivityLog activity;
  final String? userName;
}

class BazarLocalDataSource {
  BazarLocalDataSource(this._db);

  final db.AppDatabase _db;

  Stream<List<LocalBazarRow>> watchBazars({BazarStatus? status}) {
    return _db.select(_db.bazars).watch().asyncMap((bazars) async {
      var rows = bazars;
      if (status != null) {
        final expected = bazarStatusToDb(status);
        rows = rows.where((bazar) => bazar.status == expected).toList();
      }
      rows.sort((a, b) => b.bazarDate.compareTo(a.bazarDate));
      return Future.wait(rows.map(_hydrateBazar));
    });
  }

  Stream<LocalBazarRow?> watchBazar(String bazarId) {
    return (_db.select(_db.bazars)..where((tbl) => tbl.id.equals(bazarId)))
        .watchSingleOrNull()
        .asyncMap((bazar) => bazar == null ? null : _hydrateBazar(bazar));
  }

  Stream<List<db.BazarItem>> watchItems(String bazarId) {
    final query = _db.select(_db.bazarItems)
      ..where((tbl) => tbl.bazarId.equals(bazarId))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]);
    return query.watch();
  }

  Future<List<db.BazarItem>> getItems(String bazarId) {
    final query = _db.select(_db.bazarItems)
      ..where((tbl) => tbl.bazarId.equals(bazarId))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]);
    return query.get();
  }

  Future<db.BazarItem?> getItem(String itemId) {
    final query = _db.select(_db.bazarItems)
      ..where((tbl) => tbl.id.equals(itemId));
    return query.getSingleOrNull();
  }

  Future<db.Bazar?> getBazar(String bazarId) {
    final query = _db.select(_db.bazars)
      ..where((tbl) => tbl.id.equals(bazarId));
    return query.getSingleOrNull();
  }

  Future<LocalBazarRow?> getHydratedBazar(String bazarId) async {
    final bazar = await getBazar(bazarId);
    return bazar == null ? null : _hydrateBazar(bazar);
  }

  Future<db.Bazar> createBazar({
    required String id,
    required String walletId,
    required String createdBy,
    required String status,
    required DateTime bazarDate,
    String? assignedTo,
    String? title,
    String? note,
  }) async {
    final now = DateTime.now();
    await _db
        .into(_db.bazars)
        .insert(
          db.BazarsCompanion.insert(
            id: id,
            walletId: walletId,
            createdBy: createdBy,
            assignedTo: assignedTo == null
                ? const Value.absent()
                : Value(assignedTo),
            title: title == null ? const Value.absent() : Value(title),
            note: note == null ? const Value.absent() : Value(note),
            status: status,
            bazarDate: bazarDate,
            createdAt: now,
            updatedAt: now,
          ),
        );
    final created = await getBazar(id);
    if (created == null) {
      throw StateError('Bazar was not created: $id');
    }
    return created;
  }

  Future<db.BazarItem> insertItem({
    required String id,
    required String bazarId,
    required String name,
    String? rawText,
    double? quantity,
    String? unit,
    String? attributes,
    String? note,
    String? addedBy,
  }) async {
    final now = DateTime.now();
    await _db
        .into(_db.bazarItems)
        .insert(
          db.BazarItemsCompanion.insert(
            id: id,
            bazarId: bazarId,
            name: name,
            rawText: rawText == null ? const Value.absent() : Value(rawText),
            quantity: quantity == null ? const Value.absent() : Value(quantity),
            unit: unit == null ? const Value.absent() : Value(unit),
            attributes: attributes == null
                ? const Value.absent()
                : Value(attributes),
            note: note == null ? const Value.absent() : Value(note),
            status: 'pending',
            addedBy: addedBy == null ? const Value.absent() : Value(addedBy),
            createdAt: now,
            updatedAt: now,
          ),
        );
    final created = await getItem(id);
    if (created == null) {
      throw StateError('Bazar item was not created: $id');
    }
    return created;
  }

  Future<double> walletBalanceBeforeBazar(String bazarId) async {
    final bazar = await getBazar(bazarId);
    if (bazar == null) {
      return 0;
    }

    final moneyRows = await (_db.select(
      _db.moneyEntries,
    )..where((tbl) => tbl.walletId.equals(bazar.walletId))).get();
    final directExpenseRows = await (_db.select(
      _db.directExpenses,
    )..where((tbl) => tbl.walletId.equals(bazar.walletId))).get();
    final itemRows = await (_db.select(_db.bazarItems).join([
      innerJoin(_db.bazars, _db.bazars.id.equalsExp(_db.bazarItems.bazarId)),
    ])..where(_db.bazars.walletId.equals(bazar.walletId))).get();

    final moneyBalance = moneyRows.fold<double>(0, (sum, entry) {
      if (entry.type == 'money_returned') {
        return sum - entry.amount;
      }
      return sum + entry.amount;
    });
    final directSpent = directExpenseRows.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );
    final bazarSpent = itemRows.fold<double>(0, (sum, row) {
      final item = row.readTable(_db.bazarItems);
      if (item.bazarId == bazarId) {
        return sum;
      }
      return sum + (item.price ?? 0);
    });

    return moneyBalance - directSpent - bazarSpent;
  }

  Future<db.BazarItem> updateItem({
    required String itemId,
    double? quantity,
    String? unit,
    double? price,
    String? note,
    required ItemStatus status,
  }) async {
    final now = DateTime.now();
    final companion = db.BazarItemsCompanion(
      quantity: quantity == null ? const Value.absent() : Value(quantity),
      unit: unit == null ? const Value.absent() : Value(unit),
      price: price == null ? const Value.absent() : Value(price),
      note: note == null ? const Value.absent() : Value(note),
      status: Value(itemStatusToDb(status)),
      updatedAt: Value(now),
    );

    await (_db.update(
      _db.bazarItems,
    )..where((tbl) => tbl.id.equals(itemId))).write(companion);
    final updated = await getItem(itemId);
    if (updated == null) {
      throw StateError('Bazar item not found: $itemId');
    }
    return updated;
  }

  Future<db.Bazar> closeBazar(String bazarId) async {
    final now = DateTime.now();
    await (_db.update(
      _db.bazars,
    )..where((tbl) => tbl.id.equals(bazarId))).write(
      db.BazarsCompanion(
        status: const Value('closed'),
        updatedAt: Value(now),
        closedAt: Value(now),
      ),
    );
    final updated = await getBazar(bazarId);
    if (updated == null) {
      throw StateError('Bazar not found: $bazarId');
    }
    return updated;
  }

  Future<void> insertActivity({
    required String action,
    required String entityType,
    required String entityId,
    String? userId,
    String? oldValue,
    String? newValue,
  }) async {
    final now = DateTime.now();
    await _db
        .into(_db.activityLogs)
        .insert(
          db.ActivityLogsCompanion.insert(
            id: 'act-${now.microsecondsSinceEpoch}',
            userId: userId == null ? const Value.absent() : Value(userId),
            action: action,
            entityType: entityType,
            entityId: entityId,
            oldValue: oldValue == null ? const Value.absent() : Value(oldValue),
            newValue: newValue == null ? const Value.absent() : Value(newValue),
            createdAt: now,
          ),
        );
  }

  Stream<List<LocalActivityRow>> watchActivity(String bazarId) {
    return _db.select(_db.activityLogs).watch().asyncMap((logs) async {
      final itemIds = (await getItems(bazarId)).map((item) => item.id).toSet();
      final filtered = logs.where((log) {
        return (log.entityType == 'bazar' && log.entityId == bazarId) ||
            (log.entityType == 'bazar_item' && itemIds.contains(log.entityId));
      }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return Future.wait(
        filtered.map((log) async {
          String? userName;
          if (log.userId != null) {
            final user = await (_db.select(
              _db.users,
            )..where((tbl) => tbl.id.equals(log.userId!))).getSingleOrNull();
            userName = user?.name;
          }
          return LocalActivityRow(activity: log, userName: userName);
        }),
      );
    });
  }

  Future<LocalBazarRow> _hydrateBazar(db.Bazar bazar) async {
    final wallet = await (_db.select(
      _db.wallets,
    )..where((tbl) => tbl.id.equals(bazar.walletId))).getSingleOrNull();
    final assigned = bazar.assignedTo == null
        ? null
        : await (_db.select(_db.users)
                ..where((tbl) => tbl.id.equals(bazar.assignedTo!)))
              .getSingleOrNull();
    final items = await getItems(bazar.id);
    final spent = items.fold<double>(0, (sum, item) => sum + (item.price ?? 0));
    return LocalBazarRow(
      bazar: bazar,
      walletName: wallet?.name,
      assignedName: assigned?.name,
      itemCount: items.length,
      spent: spent,
    );
  }
}
