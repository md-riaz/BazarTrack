import 'package:equatable/equatable.dart';

import '../../../../shared/models/app_enums.dart';

class Bazar extends Equatable {
  const Bazar({
    required this.id,
    required this.walletId,
    required this.createdBy,
    required this.status,
    required this.bazarDate,
    required this.createdAt,
    required this.updatedAt,
    required this.itemCount,
    required this.spent,
    this.assignedTo,
    this.title,
    this.note,
    this.closedAt,
    this.walletName,
    this.assignedName,
  });

  final String id;
  final String walletId;
  final String createdBy;
  final String? assignedTo;
  final String? title;
  final String? note;
  final BazarStatus status;
  final DateTime bazarDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? closedAt;
  final String? walletName;
  final String? assignedName;
  final int itemCount;
  final double spent;

  bool get isClosed => status == BazarStatus.closed;

  Bazar copyWith({
    String? id,
    String? walletId,
    String? createdBy,
    String? assignedTo,
    String? title,
    String? note,
    BazarStatus? status,
    DateTime? bazarDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? closedAt,
    String? walletName,
    String? assignedName,
    int? itemCount,
    double? spent,
  }) {
    return Bazar(
      id: id ?? this.id,
      walletId: walletId ?? this.walletId,
      createdBy: createdBy ?? this.createdBy,
      assignedTo: assignedTo ?? this.assignedTo,
      title: title ?? this.title,
      note: note ?? this.note,
      status: status ?? this.status,
      bazarDate: bazarDate ?? this.bazarDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      closedAt: closedAt ?? this.closedAt,
      walletName: walletName ?? this.walletName,
      assignedName: assignedName ?? this.assignedName,
      itemCount: itemCount ?? this.itemCount,
      spent: spent ?? this.spent,
    );
  }

  @override
  List<Object?> get props => [
    id,
    walletId,
    createdBy,
    assignedTo,
    title,
    note,
    status,
    bazarDate,
    createdAt,
    updatedAt,
    closedAt,
    walletName,
    assignedName,
    itemCount,
    spent,
  ];
}

class BazarItem extends Equatable {
  const BazarItem({
    required this.id,
    required this.bazarId,
    required this.name,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.rawText,
    this.quantity,
    this.unit,
    this.attributes,
    this.note,
    this.price,
    this.addedBy,
  });

  final String id;
  final String bazarId;
  final String name;
  final String? rawText;
  final double? quantity;
  final String? unit;
  final String? attributes;
  final String? note;
  final ItemStatus status;
  final double? price;
  final String? addedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isDone => status == ItemStatus.done;
  bool get isNotFound => status == ItemStatus.notFound;

  String get quantityLabel {
    final qty = quantity == null ? '' : _trimNumber(quantity!);
    return [
      qty,
      unit,
    ].where((value) => value != null && value.isNotEmpty).join(' ');
  }

  BazarItem copyWith({
    String? id,
    String? bazarId,
    String? name,
    String? rawText,
    double? quantity,
    String? unit,
    String? attributes,
    String? note,
    ItemStatus? status,
    double? price,
    String? addedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BazarItem(
      id: id ?? this.id,
      bazarId: bazarId ?? this.bazarId,
      name: name ?? this.name,
      rawText: rawText ?? this.rawText,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      attributes: attributes ?? this.attributes,
      note: note ?? this.note,
      status: status ?? this.status,
      price: price ?? this.price,
      addedBy: addedBy ?? this.addedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    bazarId,
    name,
    rawText,
    quantity,
    unit,
    attributes,
    note,
    status,
    price,
    addedBy,
    createdAt,
    updatedAt,
  ];
}

class ActivityEvent extends Equatable {
  const ActivityEvent({
    required this.id,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.createdAt,
    this.userId,
    this.oldValue,
    this.newValue,
    this.userName,
  });

  final String id;
  final String? userId;
  final String action;
  final String entityType;
  final String entityId;
  final String? oldValue;
  final String? newValue;
  final DateTime createdAt;
  final String? userName;

  @override
  List<Object?> get props => [
    id,
    userId,
    action,
    entityType,
    entityId,
    oldValue,
    newValue,
    createdAt,
    userName,
  ];
}

class BazarSummary extends Equatable {
  const BazarSummary({
    required this.bazarId,
    required this.purchasedCount,
    required this.notFoundCount,
    required this.pendingCount,
    required this.totalSpent,
    required this.previousBalance,
    required this.newBalance,
    required this.items,
  });

  final String bazarId;
  final int purchasedCount;
  final int notFoundCount;
  final int pendingCount;
  final double totalSpent;
  final double previousBalance;
  final double newBalance;
  final List<BazarItem> items;

  @override
  List<Object?> get props => [
    bazarId,
    purchasedCount,
    notFoundCount,
    pendingCount,
    totalSpent,
    previousBalance,
    newBalance,
    items,
  ];
}

class CreateBazarItemInput extends Equatable {
  const CreateBazarItemInput({
    required this.name,
    this.rawText,
    this.quantity,
    this.unit,
    this.attributes,
    this.note,
  });

  final String name;
  final String? rawText;
  final double? quantity;
  final String? unit;
  final String? attributes;
  final String? note;

  @override
  List<Object?> get props => [name, rawText, quantity, unit, attributes, note];
}

class CreateBazarInput extends Equatable {
  const CreateBazarInput({
    required this.walletId,
    required this.createdBy,
    required this.status,
    required this.bazarDate,
    required this.items,
    this.assignedTo,
    this.title,
    this.note,
  });

  final String walletId;
  final String createdBy;
  final String? assignedTo;
  final String? title;
  final String? note;
  final BazarStatus status;
  final DateTime bazarDate;
  final List<CreateBazarItemInput> items;

  @override
  List<Object?> get props => [
    walletId,
    createdBy,
    assignedTo,
    title,
    note,
    status,
    bazarDate,
    items,
  ];
}

String _trimNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value.toString();
}
