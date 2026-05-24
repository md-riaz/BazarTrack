import 'package:uuid/uuid.dart';

import '../../../../shared/models/app_enums.dart';
import '../../domain/entities/bazar_entities.dart' as domain;
import '../../domain/repositories/bazar_repository.dart';
import '../datasources/bazar_local_data_source.dart';
import '../datasources/mock_bazar_remote_data_source.dart';
import '../mappers/bazar_mappers.dart';

class BazarRepositoryImpl implements BazarRepository {
  BazarRepositoryImpl({
    required BazarLocalDataSource localDataSource,
    required MockBazarRemoteDataSource remoteDataSource,
  }) : _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource;

  final BazarLocalDataSource _localDataSource;
  final MockBazarRemoteDataSource _remoteDataSource;
  final Uuid _uuid = const Uuid();

  @override
  Stream<List<domain.Bazar>> watchBazars({BazarStatus? status}) {
    return _localDataSource
        .watchBazars(status: status)
        .map(
          (rows) => rows
              .map(
                (row) => row.bazar.toDomain(
                  walletName: row.walletName,
                  assignedName: row.assignedName,
                  itemCount: row.itemCount,
                  spent: row.spent,
                ),
              )
              .toList(),
        );
  }

  @override
  Stream<domain.Bazar?> watchBazar(String bazarId) {
    return _localDataSource
        .watchBazar(bazarId)
        .map(
          (row) => row?.bazar.toDomain(
            walletName: row.walletName,
            assignedName: row.assignedName,
            itemCount: row.itemCount,
            spent: row.spent,
          ),
        );
  }

  @override
  Stream<List<domain.BazarItem>> watchBazarItems(String bazarId) {
    return _localDataSource
        .watchItems(bazarId)
        .map((items) => items.map((item) => item.toDomain()).toList());
  }

  @override
  Stream<List<domain.ActivityEvent>> watchActivity(String bazarId) {
    return _localDataSource
        .watchActivity(bazarId)
        .map(
          (rows) => rows
              .map((row) => row.activity.toDomain(userName: row.userName))
              .toList(),
        );
  }

  @override
  Future<List<domain.Bazar>> refreshBazars() {
    return _remoteDataSource.fetchBazars();
  }

  @override
  Future<domain.Bazar> createBazar(domain.CreateBazarInput input) async {
    final bazarId = _uuid.v4();
    final created = await _localDataSource.createBazar(
      id: bazarId,
      walletId: input.walletId,
      createdBy: input.createdBy,
      assignedTo: input.assignedTo,
      title: input.title,
      note: input.note,
      status: bazarStatusToDb(input.status),
      bazarDate: input.bazarDate,
    );

    for (final item in input.items) {
      await _localDataSource.insertItem(
        id: _uuid.v4(),
        bazarId: bazarId,
        name: item.name,
        rawText: item.rawText,
        quantity: item.quantity,
        unit: item.unit,
        attributes: item.attributes,
        note: item.note,
        addedBy: input.createdBy,
      );
    }

    await _localDataSource.insertActivity(
      action: 'bazar.created',
      entityType: 'bazar',
      entityId: bazarId,
      userId: input.createdBy,
      newValue: '{"items":${input.items.length}}',
    );

    final row = await _localDataSource.getHydratedBazar(bazarId);
    final domainBazar = row == null
        ? created.toDomain()
        : row.bazar.toDomain(
            walletName: row.walletName,
            assignedName: row.assignedName,
            itemCount: row.itemCount,
            spent: row.spent,
          );
    unawaitedPublishBazar(domainBazar);
    return domainBazar;
  }

  @override
  Future<domain.BazarItem> addItem({
    required String bazarId,
    required domain.CreateBazarItemInput item,
    String? userId,
  }) async {
    final bazar = await _localDataSource.getBazar(bazarId);
    if (bazar == null) {
      throw StateError('Bazar not found: $bazarId');
    }

    final created = await _localDataSource.insertItem(
      id: _uuid.v4(),
      bazarId: bazarId,
      name: item.name,
      rawText: item.rawText,
      quantity: item.quantity,
      unit: item.unit,
      attributes: item.attributes,
      note: item.note,
      addedBy: userId,
    );

    await _localDataSource.insertActivity(
      action: 'item.created',
      entityType: 'bazar_item',
      entityId: created.id,
      userId: userId,
      newValue: '{"name":"${created.name}"}',
    );

    final domainItem = created.toDomain();
    unawaitedPublishItem(domainItem);
    return domainItem;
  }

  @override
  Future<domain.BazarItem> updateItem({
    required String itemId,
    double? quantity,
    String? unit,
    double? price,
    String? note,
    ItemStatus? status,
    String? userId,
  }) async {
    final previous = await _localDataSource.getItem(itemId);
    if (previous == null) {
      throw StateError('Bazar item not found: $itemId');
    }

    final nextStatus = _resolveStatus(price: price, status: status);
    final updated = await _localDataSource.updateItem(
      itemId: itemId,
      quantity: quantity,
      unit: unit,
      price: price,
      note: note,
      status: nextStatus,
    );

    await _localDataSource.insertActivity(
      action: nextStatus == ItemStatus.notFound
          ? 'item.not_found'
          : nextStatus == ItemStatus.done
          ? 'item.purchased'
          : 'item.updated',
      entityType: 'bazar_item',
      entityId: itemId,
      userId: userId,
      oldValue:
          '{"status":"${previous.status}","price":${previous.price ?? 0}}',
      newValue:
          '{"status":"${itemStatusToDb(nextStatus)}","price":${updated.price ?? 0}}',
    );

    final domainItem = updated.toDomain();
    unawaitedPublishItem(domainItem);
    return domainItem;
  }

  @override
  Future<domain.Bazar> closeBazar({
    required String bazarId,
    String? userId,
  }) async {
    final updated = await _localDataSource.closeBazar(bazarId);
    await _localDataSource.insertActivity(
      action: 'bazar.closed',
      entityType: 'bazar',
      entityId: bazarId,
      userId: userId,
      newValue: '{"status":"closed"}',
    );
    final row = await _localDataSource.watchBazar(bazarId).first;
    final domainBazar = row == null
        ? updated.toDomain()
        : row.bazar.toDomain(
            walletName: row.walletName,
            assignedName: row.assignedName,
            itemCount: row.itemCount,
            spent: row.spent,
          );
    unawaitedPublishBazar(domainBazar);
    return domainBazar;
  }

  @override
  Future<domain.BazarSummary> getSummary(String bazarId) async {
    final items = (await _localDataSource.getItems(
      bazarId,
    )).map((item) => item.toDomain()).toList();
    final totalSpent = items.fold<double>(
      0,
      (sum, item) => sum + (item.price ?? 0),
    );
    final previousBalance = await _localDataSource.walletBalanceBeforeBazar(
      bazarId,
    );
    return domain.BazarSummary(
      bazarId: bazarId,
      purchasedCount: items
          .where((item) => item.status == ItemStatus.done)
          .length,
      notFoundCount: items
          .where((item) => item.status == ItemStatus.notFound)
          .length,
      pendingCount: items
          .where((item) => item.status == ItemStatus.pending)
          .length,
      totalSpent: totalSpent,
      previousBalance: previousBalance,
      newBalance: previousBalance - totalSpent,
      items: items,
    );
  }

  ItemStatus _resolveStatus({double? price, ItemStatus? status}) {
    if (price != null && price > 0) {
      return ItemStatus.done;
    }
    return status ?? ItemStatus.pending;
  }

  void unawaitedPublishItem(domain.BazarItem item) {
    _remoteDataSource.publishItemUpdate(item).ignore();
  }

  void unawaitedPublishBazar(domain.Bazar bazar) {
    if (bazar.isClosed) {
      _remoteDataSource.publishBazarClose(bazar).ignore();
    } else {
      _remoteDataSource.publishBazarCreate(bazar).ignore();
    }
  }
}
