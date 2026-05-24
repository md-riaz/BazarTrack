import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/sync/sync_enqueue_service.dart';
import '../../../../core/sync/sync_types.dart';
import '../../../../features/wallet/domain/entities/wallet_snapshot.dart';
import '../../../../shared/models/app_enums.dart';
import '../../domain/entities/direct_expense.dart';
import '../../domain/entities/money_entry.dart';
import '../../domain/repositories/money_entry_repository.dart';
import '../datasources/mock_money_remote_datasource.dart';
import '../datasources/money_local_data_source.dart';

class MoneyEntryRepositoryImpl implements MoneyEntryRepository {
  MoneyEntryRepositoryImpl({
    required MoneyEntryDao moneyEntryDao,
    required DirectExpenseDao directExpenseDao,
    required MonthlyCloseDao monthlyCloseDao,
    required MoneyRemoteDataSource remoteDataSource,
    SyncEnqueueService? syncEnqueueService,
  }) : _moneyEntryDao = moneyEntryDao,
       _directExpenseDao = directExpenseDao,
       _monthlyCloseDao = monthlyCloseDao,
       _remoteDataSource = remoteDataSource,
       _syncEnqueueService = syncEnqueueService;

  final MoneyEntryDao _moneyEntryDao;
  final DirectExpenseDao _directExpenseDao;
  final MonthlyCloseDao _monthlyCloseDao;
  final MoneyRemoteDataSource _remoteDataSource;
  final SyncEnqueueService? _syncEnqueueService;
  final Uuid _uuid = const Uuid();

  @override
  Stream<List<MoneyEntry>> watchMoneyEntries({
    String? walletId,
    String? assistantId,
    DateTime? from,
    DateTime? to,
  }) {
    return _moneyEntryDao.watchMoneyEntries(
      walletId: walletId,
      assistantId: assistantId,
      from: from,
      to: to,
    );
  }

  @override
  Stream<List<DirectExpense>> watchDirectExpenses({
    String? walletId,
    String? assistantId,
    DateTime? from,
    DateTime? to,
  }) {
    return _directExpenseDao.watchDirectExpenses(
      walletId: walletId,
      assistantId: assistantId,
      from: from,
      to: to,
    );
  }

  @override
  Future<MoneyEntry> createMoneyEntry({
    required String walletId,
    required String assistantId,
    required EntryType type,
    required double amount,
    required DateTime entryDate,
    String? bazarId,
    String? note,
    String? createdBy,
  }) async {
    _validateAmount(amount);
    if (type == EntryType.adjustment && (note == null || note.trim().isEmpty)) {
      throw ArgumentError('Adjustment note is required');
    }

    final entry = await _moneyEntryDao.insertMoneyEntry(
      id: _uuid.v4(),
      walletId: walletId,
      assistantId: assistantId,
      type: entryTypeToDb(type),
      amount: type == EntryType.adjustment ? amount : amount.abs(),
      entryDate: entryDate,
      bazarId: bazarId,
      note: note,
      createdBy: createdBy,
    );
    await _enqueue(
      entityType: 'money_entry',
      entityId: entry.id,
      operation: SyncOperation.create,
      payload: {
        'id': entry.id,
        'wallet_id': entry.walletId,
        'assistant_id': entry.assistantId,
        'bazar_id': entry.bazarId,
        'type': entryTypeToDb(entry.type),
        'amount': entry.amount,
        'note': entry.note,
        'entry_date': entry.entryDate.toIso8601String(),
        'created_by': entry.createdBy,
        'created_at': entry.createdAt.toIso8601String(),
        'updated_at': entry.updatedAt.toIso8601String(),
        'is_locked': entry.isLocked,
      },
    );
    _remoteDataSource.publishMoneyEntry(entry).ignore();
    return entry;
  }

  @override
  Future<DirectExpense> createDirectExpense({
    required String walletId,
    required String assistantId,
    required double amount,
    required DateTime entryDate,
    String? note,
    String? receiptUrl,
    String? createdBy,
  }) async {
    _validateAmount(amount);
    final expense = await _directExpenseDao.insertDirectExpense(
      id: _uuid.v4(),
      walletId: walletId,
      assistantId: assistantId,
      amount: amount.abs(),
      entryDate: entryDate,
      note: note,
      receiptUrl: receiptUrl,
      createdBy: createdBy,
    );
    await _enqueue(
      entityType: 'direct_expense',
      entityId: expense.id,
      operation: SyncOperation.create,
      payload: {
        'id': expense.id,
        'wallet_id': expense.walletId,
        'assistant_id': expense.assistantId,
        'amount': expense.amount,
        'note': expense.note,
        'entry_date': expense.entryDate.toIso8601String(),
        'receipt_url': expense.receiptUrl,
        'created_by': expense.createdBy,
        'created_at': expense.createdAt.toIso8601String(),
        'is_locked': expense.isLocked,
      },
    );
    _remoteDataSource.publishDirectExpense(expense).ignore();
    return expense;
  }

  @override
  Future<WalletSnapshot> closeMonthlyPeriod({
    required String walletId,
    required String periodMonth,
    String? assistantId,
    String? closedBy,
    String? notes,
  }) async {
    final range = MonthRange.parse(periodMonth);
    final moneyEntries = await _moneyEntryDao.getMoneyEntries(
      walletId: walletId,
      assistantId: assistantId,
      from: range.start,
      to: range.end,
    );
    final directExpenses = await _directExpenseDao.getDirectExpenses(
      walletId: walletId,
      assistantId: assistantId,
      from: range.start,
      to: range.end,
    );
    final bazarItems = await _monthlyCloseDao.getClosedBazarItems(
      walletId: walletId,
      assistantId: assistantId,
      from: range.start,
      to: range.end,
    );

    final closingBalance = _calculatePeriodBalance(
      moneyEntries: moneyEntries,
      directExpenses: directExpenses,
      bazarSpent: bazarItems.fold<double>(
        0,
        (sum, item) => sum + (item.price ?? 0),
      ),
    );
    const openingBalance = 0.0;
    final closedAt = DateTime.now();
    final hash = _hashSnapshot(
      walletId: walletId,
      assistantId: assistantId,
      periodMonth: periodMonth,
      openingBalance: openingBalance,
      closingBalance: closingBalance,
      entries: moneyEntries.length + directExpenses.length + bazarItems.length,
    );

    final snapshotRow = await _monthlyCloseDao.upsertSnapshot(
      id: _uuid.v4(),
      walletId: walletId,
      assistantId: assistantId,
      periodMonth: periodMonth,
      openingBalance: openingBalance,
      closingBalance: closingBalance,
      snapshotHash: hash,
      closedBy: closedBy,
      closedAt: closedAt,
      notes: notes,
    );

    await _moneyEntryDao.lockPeriod(
      walletId: walletId,
      assistantId: assistantId,
      from: range.start,
      to: range.end,
    );
    await _directExpenseDao.lockPeriod(
      walletId: walletId,
      assistantId: assistantId,
      from: range.start,
      to: range.end,
    );
    await _monthlyCloseDao.lockClosedBazars(
      walletId: walletId,
      assistantId: assistantId,
      from: range.start,
      to: range.end,
    );

    await _enqueue(
      entityType: 'wallet_snapshot',
      entityId: snapshotRow.id,
      operation: SyncOperation.create,
      payload: {
        'id': snapshotRow.id,
        'wallet_id': snapshotRow.walletId,
        'assistant_id': snapshotRow.assistantId,
        'period_month': snapshotRow.periodMonth,
        'opening_balance': snapshotRow.openingBalance,
        'closing_balance': snapshotRow.closingBalance,
        'snapshot_hash': snapshotRow.snapshotHash,
        'closed_by': snapshotRow.closedBy,
        'closed_at': snapshotRow.closedAt.toIso8601String(),
        'notes': snapshotRow.notes,
      },
    );
    _remoteDataSource
        .publishMonthlyClose(
          walletId: walletId,
          periodMonth: periodMonth,
          assistantId: assistantId,
        )
        .ignore();
    return WalletSnapshot(
      id: snapshotRow.id,
      walletId: snapshotRow.walletId,
      assistantId: snapshotRow.assistantId,
      periodMonth: snapshotRow.periodMonth,
      openingBalance: snapshotRow.openingBalance,
      closingBalance: snapshotRow.closingBalance,
      snapshotHash: snapshotRow.snapshotHash,
      closedBy: snapshotRow.closedBy,
      closedAt: snapshotRow.closedAt,
      notes: snapshotRow.notes,
    );
  }

  double _calculatePeriodBalance({
    required List<MoneyEntry> moneyEntries,
    required List<DirectExpense> directExpenses,
    required double bazarSpent,
  }) {
    final moneyTotal = moneyEntries.fold<double>(
      0,
      (sum, entry) => sum + entry.signedAmount,
    );
    final directTotal = directExpenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount.abs(),
    );
    return moneyTotal - directTotal - bazarSpent;
  }

  String _hashSnapshot({
    required String walletId,
    required String periodMonth,
    required double openingBalance,
    required double closingBalance,
    required int entries,
    String? assistantId,
  }) {
    final payload = jsonEncode({
      'walletId': walletId,
      'assistantId': assistantId,
      'periodMonth': periodMonth,
      'openingBalance': openingBalance,
      'closingBalance': closingBalance,
      'entries': entries,
    });
    return sha256.convert(utf8.encode(payload)).toString();
  }

  Future<void> _enqueue({
    required String entityType,
    required String entityId,
    required SyncOperation operation,
    required Map<String, dynamic> payload,
  }) async {
    final enqueueService = _syncEnqueueService;
    if (enqueueService == null) return;
    await enqueueService.enqueue(
      entityType: entityType,
      entityId: entityId,
      operation: operation,
      payload: payload,
    );
  }

  void _validateAmount(double amount) {
    if (amount == 0) {
      throw ArgumentError('Amount must not be zero');
    }
  }
}

class MonthRange {
  const MonthRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  static MonthRange parse(String periodMonth) {
    final parts = periodMonth.split('-');
    if (parts.length != 2) {
      throw ArgumentError('Invalid period month: $periodMonth');
    }
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    return MonthRange(
      start: DateTime(year, month),
      end: DateTime(year, month + 1),
    );
  }
}
