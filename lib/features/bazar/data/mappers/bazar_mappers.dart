import '../../../../core/database/app_database.dart' as db;
import '../../../../shared/models/app_enums.dart';
import '../../domain/entities/bazar_entities.dart' as domain;

extension DbBazarMapper on db.Bazar {
  domain.Bazar toDomain({
    String? walletName,
    String? assignedName,
    int itemCount = 0,
    double spent = 0,
  }) {
    return domain.Bazar(
      id: id,
      walletId: walletId,
      createdBy: createdBy,
      assignedTo: assignedTo,
      title: title,
      note: note,
      status: bazarStatusFromDb(status),
      bazarDate: bazarDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
      closedAt: closedAt,
      walletName: walletName,
      assignedName: assignedName,
      itemCount: itemCount,
      spent: spent,
    );
  }
}

extension DbBazarItemMapper on db.BazarItem {
  domain.BazarItem toDomain() {
    return domain.BazarItem(
      id: id,
      bazarId: bazarId,
      name: name,
      rawText: rawText,
      quantity: quantity,
      unit: unit,
      attributes: attributes,
      note: note,
      status: itemStatusFromDb(status),
      price: price,
      addedBy: addedBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

extension DbActivityLogMapper on db.ActivityLog {
  domain.ActivityEvent toDomain({String? userName}) {
    return domain.ActivityEvent(
      id: id,
      userId: userId,
      action: action,
      entityType: entityType,
      entityId: entityId,
      oldValue: oldValue,
      newValue: newValue,
      createdAt: createdAt,
      userName: userName,
    );
  }
}

String bazarStatusToDb(BazarStatus status) {
  switch (status) {
    case BazarStatus.draft:
      return 'draft';
    case BazarStatus.open:
      return 'open';
    case BazarStatus.closed:
      return 'closed';
    case BazarStatus.cancelled:
      return 'cancelled';
  }
}

BazarStatus bazarStatusFromDb(String status) {
  switch (status) {
    case 'draft':
      return BazarStatus.draft;
    case 'closed':
      return BazarStatus.closed;
    case 'cancelled':
      return BazarStatus.cancelled;
    case 'open':
    default:
      return BazarStatus.open;
  }
}

String itemStatusToDb(ItemStatus status) {
  switch (status) {
    case ItemStatus.pending:
      return 'pending';
    case ItemStatus.done:
      return 'done';
    case ItemStatus.notFound:
      return 'not_found';
    case ItemStatus.cancelled:
      return 'cancelled';
  }
}

ItemStatus itemStatusFromDb(String status) {
  switch (status) {
    case 'done':
      return ItemStatus.done;
    case 'not_found':
      return ItemStatus.notFound;
    case 'cancelled':
      return ItemStatus.cancelled;
    case 'pending':
    default:
      return ItemStatus.pending;
  }
}
