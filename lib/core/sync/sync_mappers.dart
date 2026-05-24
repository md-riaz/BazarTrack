import '../database/app_database.dart';

Map<String, dynamic> userToApi(User row) {
  return {
    'id': row.id,
    'name': row.name,
    'phone': row.phone,
    'email': row.email,
    'role': row.role,
    'is_active': row.isActive,
    'created_at': row.createdAt.toIso8601String(),
    'updated_at': row.updatedAt.toIso8601String(),
  };
}

Map<String, dynamic> walletToApi(Wallet row) {
  return {
    'id': row.id,
    'name': row.name,
    'type': row.type,
    'is_active': row.isActive,
    'created_by': row.createdBy,
    'created_at': row.createdAt.toIso8601String(),
  };
}

Map<String, dynamic> bazarToApi(Bazar row) {
  return {
    'id': row.id,
    'wallet_id': row.walletId,
    'created_by': row.createdBy,
    'assigned_to': row.assignedTo,
    'title': row.title,
    'note': row.note,
    'status': row.status,
    'bazar_date': row.bazarDate.toIso8601String(),
    'created_at': row.createdAt.toIso8601String(),
    'updated_at': row.updatedAt.toIso8601String(),
    'closed_at': row.closedAt?.toIso8601String(),
  };
}

Map<String, dynamic> bazarItemToApi(BazarItem row) {
  return {
    'id': row.id,
    'bazar_id': row.bazarId,
    'name': row.name,
    'raw_text': row.rawText,
    'quantity': row.quantity,
    'unit': row.unit,
    'attributes': row.attributes,
    'note': row.note,
    'status': row.status,
    'price': row.price,
    'added_by': row.addedBy,
    'created_at': row.createdAt.toIso8601String(),
    'updated_at': row.updatedAt.toIso8601String(),
  };
}

Map<String, dynamic> moneyEntryToApi(MoneyEntry row) {
  return {
    'id': row.id,
    'wallet_id': row.walletId,
    'assistant_id': row.assistantId,
    'bazar_id': row.bazarId,
    'type': row.type,
    'amount': row.amount,
    'note': row.note,
    'entry_date': row.entryDate.toIso8601String(),
    'created_by': row.createdBy,
    'created_at': row.createdAt.toIso8601String(),
    'updated_at': row.updatedAt.toIso8601String(),
    'is_locked': row.isLocked,
  };
}

Map<String, dynamic> directExpenseToApi(DirectExpense row) {
  return {
    'id': row.id,
    'wallet_id': row.walletId,
    'assistant_id': row.assistantId,
    'amount': row.amount,
    'note': row.note,
    'entry_date': row.entryDate.toIso8601String(),
    'receipt_url': row.receiptUrl,
    'created_by': row.createdBy,
    'created_at': row.createdAt.toIso8601String(),
    'is_locked': row.isLocked,
  };
}

Map<String, dynamic> walletSnapshotToApi(WalletSnapshot row) {
  return {
    'id': row.id,
    'wallet_id': row.walletId,
    'assistant_id': row.assistantId,
    'period_month': row.periodMonth,
    'opening_balance': row.openingBalance,
    'closing_balance': row.closingBalance,
    'snapshot_hash': row.snapshotHash,
    'closed_by': row.closedBy,
    'closed_at': row.closedAt.toIso8601String(),
    'notes': row.notes,
  };
}
