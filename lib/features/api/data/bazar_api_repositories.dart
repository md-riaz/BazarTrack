import '../../../core/api/bazar_api_client.dart';
import '../../../core/config/api_config.dart';
import '../../../shared/models/app_enums.dart';
import '../../bazar/domain/entities/bazar_entities.dart';
import '../../bazar/domain/repositories/bazar_repository.dart';
import '../../money/domain/entities/direct_expense.dart';
import '../../money/domain/entities/money_entry.dart';
import '../../money/domain/repositories/money_entry_repository.dart';
import '../../reports/domain/entities/report_summary.dart';
import '../../reports/domain/repositories/report_repository.dart';
import '../../wallet/domain/entities/balance_result.dart';
import '../../wallet/domain/entities/wallet.dart';
import '../../wallet/domain/entities/wallet_ledger_entry.dart';
import '../../wallet/domain/entities/wallet_member.dart';
import '../../wallet/domain/entities/wallet_snapshot.dart';
import '../../wallet/domain/entities/wallet_summary.dart';
import '../../wallet/domain/repositories/wallet_repository.dart';

class ApiWalletRepository implements WalletRepository {
  const ApiWalletRepository({
    required BazarApiClient client,
    required ApiConfig config,
  }) : _client = client,
       _config = config;

  final BazarApiClient _client;
  final ApiConfig _config;

  @override
  Future<List<Wallet>> getWallets() async {
    final data = await _client.get('funds', 'list');
    return _list(data).map(_walletFromFund).toList(growable: false);
  }

  @override
  Stream<List<Wallet>> watchWallets() => Stream.fromFuture(getWallets());

  @override
  Stream<Wallet?> watchWallet(String walletId) async* {
    final data = await _client.get('funds', 'show', query: {'id': walletId});
    yield _walletFromFund(data);
  }

  @override
  Stream<List<WalletMember>> watchMembers(String walletId) {
    return Stream.value([
      WalletMember(
        id: 'api-member-$walletId-${_config.defaultManagerId}',
        walletId: walletId,
        userId: _config.defaultManagerId,
        role: 'owner',
        createdAt: DateTime.now(),
      ),
    ]);
  }

  @override
  Stream<List<WalletSnapshot>> watchSnapshots({
    required String walletId,
    String? assistantId,
  }) => Stream.value(const <WalletSnapshot>[]);

  @override
  Stream<BalanceResult> watchBalance({
    required String walletId,
    String? assistantId,
  }) async* {
    final account = await _accountFor(
      walletId: walletId,
      assistantId: assistantId,
    );
    yield BalanceResult(
      walletId: walletId,
      assistantId: assistantId,
      confirmedBalance: _double(account['current_balance']),
      inProgressAmount: 0,
    );
  }

  @override
  Stream<List<WalletSummary>> watchWalletSummaries({
    String? assistantId,
  }) async* {
    final wallets = await getWallets();
    final accounts = await _accounts(assistantId: assistantId);
    yield wallets
        .map((wallet) {
          final account = accounts.cast<Map<String, dynamic>?>().firstWhere(
            (row) => row?['fund_id']?.toString() == wallet.id,
            orElse: () => null,
          );
          return WalletSummary(
            wallet: wallet,
            balance: BalanceResult(
              walletId: wallet.id,
              assistantId: assistantId,
              confirmedBalance: _double(account?['current_balance']),
              inProgressAmount: 0,
            ),
          );
        })
        .toList(growable: false);
  }

  @override
  Stream<List<WalletLedgerEntry>> watchLedgerEntries({
    required String walletId,
    String? assistantId,
  }) async* {
    final account = await _accountFor(
      walletId: walletId,
      assistantId: assistantId,
    );
    final data = await _client.get(
      'ledger',
      'list',
      query: {'accountId': account['id'] ?? _config.defaultAccountId},
    );
    yield _list(data).map(_ledgerFromJson).toList(growable: false);
  }

  Future<Map<String, dynamic>> _accountFor({
    required String walletId,
    String? assistantId,
  }) async {
    final accounts = await _accounts(assistantId: assistantId);
    return accounts.cast<Map<String, dynamic>?>().firstWhere(
          (row) => row?['fund_id']?.toString() == walletId,
          orElse: () => null,
        ) ??
        {
          'id': _config.defaultAccountId,
          'fund_id': walletId,
          'assistant_id': _apiActor(assistantId, _config),
          'current_balance': 0,
        };
  }

  Future<List<Map<String, dynamic>>> _accounts({String? assistantId}) async {
    final query = <String, dynamic>{};
    final apiAssistantId = _apiActor(assistantId, _config);
    if (apiAssistantId.isNotEmpty) query['assistantId'] = apiAssistantId;
    final data = await _client.get('accounts', 'list', query: query);
    return _list(data);
  }

  WalletLedgerEntry _ledgerFromJson(Map<String, dynamic> json) {
    return WalletLedgerEntry(
      id: json['id']?.toString() ?? '',
      walletId: json['fund_id']?.toString() ?? '',
      assistantId:
          json['paid_to']?.toString() ??
          json['returned_by']?.toString() ??
          _config.defaultAssistantId,
      type: _ledgerType(json['type']?.toString()),
      amount: _double(json['amount']),
      note: json['note']?.toString(),
      date: _dateTime(json['entry_date'] ?? json['created_at']),
      isLocked: false,
    );
  }
}

class ApiBazarRepository implements BazarRepository {
  const ApiBazarRepository({
    required BazarApiClient client,
    required ApiConfig config,
  }) : _client = client,
       _config = config;

  final BazarApiClient _client;
  final ApiConfig _config;

  @override
  Stream<List<Bazar>> watchBazars({BazarStatus? status}) async* {
    final data = await _client.get('bazars', 'list');
    final bazars = _list(data)
        .map(_bazarFromJson)
        .where((bazar) {
          return status == null || bazar.status == status;
        })
        .toList(growable: false);
    yield bazars;
  }

  @override
  Stream<Bazar?> watchBazar(String bazarId) async* {
    final data = await _client.get('bazars', 'show', query: {'id': bazarId});
    final bazar = _bazarFromJson(_asMap(data['bazar']));
    final items = _list({'items': data['items']});
    yield bazar.copyWith(
      itemCount: items.length,
      spent: items.fold<double>(0, (sum, item) => sum + _double(item['price'])),
    );
  }

  @override
  Stream<List<BazarItem>> watchBazarItems(String bazarId) async* {
    final data = await _client.get('bazars', 'show', query: {'id': bazarId});
    yield _list({
      'items': data['items'],
    }).map(_bazarItemFromJson).toList(growable: false);
  }

  @override
  Stream<List<ActivityEvent>> watchActivity(String bazarId) {
    return Stream.value(const <ActivityEvent>[]);
  }

  @override
  Future<List<Bazar>> refreshBazars() async {
    final data = await _client.get('bazars', 'list');
    return _list(data).map(_bazarFromJson).toList(growable: false);
  }

  @override
  Future<Bazar> createBazar(CreateBazarInput input) async {
    final data = await _client.post(
      'bazars',
      'create',
      body: {
        'fundId': _fundId(input.walletId),
        'accountId': _accountId(input.walletId),
        'title': input.title ?? 'আজকের বাজার',
        'createdBy': _apiActor(input.createdBy, _config),
        'assignedTo': _apiActor(input.assignedTo, _config),
        'status': _bazarStatusToApi(input.status),
        'bazarDate': _dateOnly(input.bazarDate),
        'items': input.items.map(_createItemToJson).toList(growable: false),
      }..removeWhere((_, value) => value == null),
    );
    return _bazarFromJson(
      _asMap(data['bazar']),
    ).copyWith(itemCount: _list({'items': data['items']}).length);
  }

  @override
  Future<BazarItem> addItem({
    required String bazarId,
    required CreateBazarItemInput item,
    String? userId,
  }) async {
    final data = await _client.post(
      'bazars',
      'addItem',
      body: {'bazarId': bazarId, ..._createItemToJson(item)},
    );
    return _bazarItemFromJson(data);
  }

  @override
  Future<BazarItem> updateItem({
    required String itemId,
    double? quantity,
    String? unit,
    double? price,
    String? note,
    ItemStatus? status,
    String? userId,
  }) async {
    final data = await _client.post(
      'bazars',
      'updateItem',
      body: {
        'id': itemId,
        'quantity': quantity,
        'price': price,
        'note': note,
        'status': status == null ? null : _itemStatusToApi(status),
      }..removeWhere((_, value) => value == null),
    );
    return _bazarItemFromJson(data);
  }

  @override
  Future<Bazar> closeBazar({required String bazarId, String? userId}) async {
    final data = await _client.post(
      'bazars',
      'close',
      body: {'id': bazarId, 'closedBy': _apiActor(userId, _config)},
    );
    return _bazarFromJson(_asMap(data['bazar']));
  }

  @override
  Future<BazarSummary> getSummary(String bazarId) async {
    final data = await _client.get('bazars', 'show', query: {'id': bazarId});
    final items = _list({
      'items': data['items'],
    }).map(_bazarItemFromJson).toList(growable: false);
    final spent = items.fold<double>(0, (sum, item) => sum + (item.price ?? 0));
    return BazarSummary(
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
      totalSpent: spent,
      previousBalance: 0,
      newBalance: -spent,
      items: items,
    );
  }

  String _fundId(String walletId) =>
      walletId == _config.defaultAccountId || walletId.startsWith('w')
      ? _config.defaultFundId
      : walletId;
  String _accountId(String walletId) =>
      walletId == _config.defaultFundId || walletId.startsWith('w')
      ? _config.defaultAccountId
      : walletId;
}

class ApiMoneyEntryRepository implements MoneyEntryRepository {
  const ApiMoneyEntryRepository({
    required BazarApiClient client,
    required ApiConfig config,
  }) : _client = client,
       _config = config;

  final BazarApiClient _client;
  final ApiConfig _config;

  @override
  Stream<List<MoneyEntry>> watchMoneyEntries({
    String? walletId,
    String? assistantId,
    DateTime? from,
    DateTime? to,
  }) async* {
    final data = await _client.get('money', 'list');
    final entries = _list(data)
        .map(_moneyEntryFromJson)
        .where((entry) {
          final walletMatches =
              walletId == null ||
              entry.walletId == walletId ||
              entry.walletId == _config.defaultAccountId;
          final assistantMatches =
              assistantId == null ||
              entry.assistantId == assistantId ||
              entry.assistantId == _config.defaultAssistantId;
          final fromMatches = from == null || !entry.entryDate.isBefore(from);
          final toMatches = to == null || entry.entryDate.isBefore(to);
          return walletMatches && assistantMatches && fromMatches && toMatches;
        })
        .toList(growable: false);
    yield entries;
  }

  @override
  Stream<List<DirectExpense>> watchDirectExpenses({
    String? walletId,
    String? assistantId,
    DateTime? from,
    DateTime? to,
  }) => Stream.value(const <DirectExpense>[]);

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
    if (type == EntryType.adjustment) {
      throw UnsupportedError('Adjustment API is not available yet');
    }
    final accountId =
        walletId == _config.defaultFundId || walletId.startsWith('w')
        ? _config.defaultAccountId
        : walletId;
    if (type == EntryType.moneyReceived) {
      final data = await _client.post(
        'money',
        'give',
        body: {
          'accountId': accountId,
          'amount': amount.abs(),
          'createdBy': _apiActor(createdBy, _config),
          'paidBy': _apiActor(createdBy, _config),
          'note': note,
          'entryDate': _dateOnly(entryDate),
        }..removeWhere((_, value) => value == null),
      );
      return _moneyEntryFromJson(_asMap(data['entry']));
    }

    final request = await _client.post(
      'returns',
      'create',
      body: {
        'accountId': accountId,
        'amount': amount.abs(),
        'requestedBy': _apiActor(assistantId, _config),
        'expectedReceiverId': _apiActor(createdBy, _config),
        'note': note,
      }..removeWhere((_, value) => value == null),
    );
    final requestId = _asMap(request['request'])['id']?.toString() ?? '';
    await _client.post(
      'returns',
      'confirm',
      body: {
        'id': requestId,
        'confirmedBy': _apiActor(createdBy, _config),
        'receivedBy': _apiActor(createdBy, _config),
        'entryDate': _dateOnly(entryDate),
      },
    );
    return MoneyEntry(
      id: requestId,
      walletId: accountId,
      assistantId: _apiActor(assistantId, _config),
      type: EntryType.moneyReturned,
      amount: amount.abs(),
      note: note,
      entryDate: entryDate,
      createdBy: _apiActor(createdBy, _config),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
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
  }) {
    throw UnsupportedError(
      'Direct expense is not supported by fund account API',
    );
  }

  @override
  Future<WalletSnapshot> closeMonthlyPeriod({
    required String walletId,
    required String periodMonth,
    String? assistantId,
    String? closedBy,
    String? notes,
  }) {
    throw UnsupportedError('Monthly close is not exposed for fund account API');
  }
}

class ApiReportRepository implements ReportRepository {
  const ApiReportRepository({required BazarApiClient client})
    : _client = client;

  final BazarApiClient _client;

  @override
  Stream<ReportSummary> watchMonthlySummary(String periodMonth) async* {
    final start = DateTime.parse('$periodMonth-01');
    final end = DateTime(start.year, start.month + 1, 0);
    final data = await _client.get(
      'reports',
      'summary',
      query: {'from': _dateOnly(start), 'to': _dateOnly(end)},
    );
    final summary = _asMap(data['summary']);
    yield ReportSummary(
      periodMonth: periodMonth,
      totalReceived: _double(summary['fundGiven']),
      totalSpent: _double(summary['bazarSpent']),
      totalReturned: _double(summary['returnedConfirmed']),
      adjustmentTotal: _double(summary['adjustments']),
      netBalance: _double(summary['netBalanceChange']),
      walletBreakdowns: const <WalletBreakdown>[],
      topItems: const <ItemPurchaseSummary>[],
    );
  }
}

Wallet _walletFromFund(Map<String, dynamic> json) {
  return Wallet(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    type: _walletType(json['type']?.toString()),
    isActive: (json['status']?.toString() ?? 'active') == 'active',
    createdBy: json['created_by']?.toString(),
    createdAt: _dateTime(json['created_at']),
  );
}

Bazar _bazarFromJson(Map<String, dynamic> json) {
  return Bazar(
    id: json['id']?.toString() ?? '',
    walletId:
        json['fund_id']?.toString() ?? json['account_id']?.toString() ?? '',
    createdBy: json['created_by']?.toString() ?? '',
    assignedTo: json['assigned_to']?.toString(),
    title: json['title']?.toString(),
    status: _bazarStatus(json['status']?.toString()),
    bazarDate: _dateTime(json['bazar_date']),
    createdAt: _dateTime(json['created_at']),
    updatedAt: _dateTime(json['updated_at']),
    closedAt: json['closed_at'] == null ? null : _dateTime(json['closed_at']),
    itemCount: 0,
    spent: 0,
  );
}

BazarItem _bazarItemFromJson(Map<String, dynamic> json) {
  return BazarItem(
    id: json['id']?.toString() ?? '',
    bazarId: json['bazar_id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    quantity: _nullableDouble(json['quantity']),
    note: json['note']?.toString(),
    status: _itemStatus(json['status']?.toString()),
    price: _nullableDouble(json['price']),
    createdAt: _dateTime(json['created_at']),
    updatedAt: _dateTime(json['updated_at']),
  );
}

MoneyEntry _moneyEntryFromJson(Map<String, dynamic> json) {
  return MoneyEntry(
    id: json['id']?.toString() ?? '',
    walletId:
        json['account_id']?.toString() ?? json['fund_id']?.toString() ?? '',
    assistantId: json['assistant_id']?.toString() ?? '',
    type: _entryType(json['type']?.toString()),
    amount: _double(json['amount']),
    note: json['note']?.toString(),
    entryDate: _dateTime(json['entry_date']),
    createdBy: json['created_by']?.toString(),
    createdAt: _dateTime(json['created_at']),
    updatedAt: _dateTime(json['updated_at']),
  );
}

Map<String, dynamic> _createItemToJson(CreateBazarItemInput item) {
  return {
    'name': item.name,
    'quantity': item.quantity?.toString(),
    'note': item.note,
  }..removeWhere((_, value) => value == null);
}

List<Map<String, dynamic>> _list(Map<String, dynamic> data) {
  final raw = data['items'];
  if (raw is List) {
    return raw.map((item) => _asMap(item)).toList(growable: false);
  }
  return const <Map<String, dynamic>>[];
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const <String, dynamic>{};
}

String _apiActor(String? localId, ApiConfig config) {
  return switch (localId) {
    null || '' => config.defaultManagerId,
    'u0' => 'admin1',
    'u1' => config.defaultAssistantId,
    'u3' => config.defaultManagerId,
    _ => localId,
  };
}

BazarStatus _bazarStatus(String? value) {
  return switch (value) {
    'closed' => BazarStatus.closed,
    'cancelled' => BazarStatus.cancelled,
    'draft' => BazarStatus.draft,
    _ => BazarStatus.open,
  };
}

String _bazarStatusToApi(BazarStatus status) => status.name;

ItemStatus _itemStatus(String? value) {
  return switch (value) {
    'done' => ItemStatus.done,
    'not_found' || 'notFound' => ItemStatus.notFound,
    'cancelled' => ItemStatus.cancelled,
    _ => ItemStatus.pending,
  };
}

String _itemStatusToApi(ItemStatus status) {
  return switch (status) {
    ItemStatus.notFound => 'not_found',
    _ => status.name,
  };
}

EntryType _entryType(String? value) {
  return switch (value) {
    'assistant_return_confirmed' || 'money_returned' => EntryType.moneyReturned,
    'adjustment' => EntryType.adjustment,
    _ => EntryType.moneyReceived,
  };
}

WalletLedgerEntryType _ledgerType(String? value) {
  return switch (value) {
    'bazar_spend' => WalletLedgerEntryType.bazarExpense,
    'assistant_return_confirmed' => WalletLedgerEntryType.moneyReturned,
    'adjustment' => WalletLedgerEntryType.adjustment,
    _ => WalletLedgerEntryType.moneyReceived,
  };
}

String _walletType(String? value) {
  return switch (value) {
    'office_bazar' || null || '' => 'shared',
    _ => value,
  };
}

DateTime _dateTime(Object? value) {
  final text = value?.toString();
  if (text == null || text.isEmpty) return DateTime.now();
  return DateTime.tryParse(text) ?? DateTime.now();
}

String _dateOnly(DateTime date) => date.toIso8601String().split('T').first;

double _double(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double? _nullableDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
