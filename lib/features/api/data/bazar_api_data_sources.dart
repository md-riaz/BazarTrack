import 'api_dtos.dart';
import '../../../core/api/bazar_api_client.dart';
import '../../../core/config/api_config.dart';
import '../../../shared/models/app_enums.dart';
import '../../admin/data/datasources/mock_admin_remote_datasource.dart';
import '../../admin/domain/entities/admin_entities.dart';
import '../../auth/data/datasources/auth_remote_datasource.dart';
import '../../auth/data/models/user_model.dart';
import '../../bazar/data/datasources/mock_bazar_remote_data_source.dart';
import '../../bazar/domain/entities/bazar_entities.dart';
import '../../money/data/datasources/mock_money_remote_datasource.dart';
import '../../money/domain/entities/direct_expense.dart';
import '../../money/domain/entities/money_entry.dart';
import '../../wallet/data/datasources/mock_wallet_remote_datasource.dart';
import '../../wallet/domain/entities/wallet.dart';

class ApiAuthRemoteDataSource implements AuthRemoteDataSource {
  const ApiAuthRemoteDataSource(this._client);

  final BazarApiClient _client;

  @override
  Future<AuthRemoteResponse> login({
    required String phone,
    required String password,
  }) async {
    final data = await _client.post(
      'auth',
      'login',
      body: {'phone': phone, 'password': password},
    );
    final dto = ApiLoginDto.fromJson(data);
    return AuthRemoteResponse(
      token: dto.token,
      user: _userFromDto(dto.user),
    );
  }

  @override
  Future<UserModel> getUserByToken(String token) async {
    final data = await _client.get('auth', 'me');
    return _userFromDto(ApiUserDto.fromJson(_asMap(data['user'] ?? data)));
  }

  @override
  Future<void> logout() async {
    await _client.post('auth', 'logout');
  }
}

class ApiAdminRemoteDataSource implements AdminRemoteDataSource {
  const ApiAdminRemoteDataSource(this._client);

  final BazarApiClient _client;

  @override
  Future<List<AdminUser>> getUsers() async {
    final data = await _client.get('users', 'list');
    return _list(data).map(_adminUserFromJson).toList(growable: false);
  }

  @override
  Future<List<AdminWallet>> getWallets() async {
    final data = await _client.get('funds', 'list');
    final funds = _list(data);
    return funds.map(_adminWalletFromFundJson).toList(growable: false);
  }

  @override
  Future<AdminUser> createUser(CreateAdminUserRequest request) async {
    final data = await _client.post(
      'users',
      'create',
      body: {
        'role': request.role.value,
        'name': request.name,
        'phone': request.phone,
      },
    );
    return _adminUserFromJson(data);
  }

  @override
  Future<AdminWallet> createWallet(CreateAdminWalletRequest request) async {
    final data = await _client.post(
      'funds',
      'create',
      body: {'name': request.name, 'type': _fundTypeFor(request.type)},
    );
    for (final ownerId in request.ownerIds) {
      await _client.post(
        'funds',
        'addManager',
        body: {'fundId': data['id'], 'userId': ownerId},
      );
    }
    return _adminWalletFromFundJson(data, ownerIds: request.ownerIds);
  }

  @override
  Future<AdminWallet> updateWallet(UpdateAdminWalletRequest request) {
    throw StateError('Fund account update is not available in API mode');
  }

  @override
  Future<void> setWalletActive({
    required String walletId,
    required bool isActive,
  }) {
    throw StateError('Fund account activation is not available in API mode');
  }
}

class ApiWalletRemoteDataSource implements WalletRemoteDataSource {
  const ApiWalletRemoteDataSource(this._client);

  final BazarApiClient _client;

  @override
  Future<List<Wallet>> fetchWallets() async {
    final data = await _client.get('funds', 'list');
    return _list(data).map(_walletFromFundJson).toList(growable: false);
  }
}

class ApiBazarRemoteDataSource extends MockBazarRemoteDataSource {
  ApiBazarRemoteDataSource({
    required BazarApiClient client,
    required ApiConfig config,
  }) : _client = client;

  final BazarApiClient _client;

  @override
  Future<List<Bazar>> fetchBazars() async {
    final data = await _client.get('bazars', 'list');
    return _list(data).map(_bazarFromJson).toList(growable: false);
  }

  @override
  Future<void> publishBazarCreate(Bazar bazar) async {
    await _client.post(
      'bazars',
      'create',
      body: {
        'id': bazar.id,
        'fundId': _fundIdFor(bazar.walletId),
        'accountId': _accountIdFor(bazar.walletId),
        'title': bazar.title ?? 'আজকের বাজার',
        'assignedTo': bazar.assignedTo,
        'status': _bazarStatusToApi(bazar.status),
        'bazarDate': _dateOnly(bazar.bazarDate),
      },
      idempotencyKey: 'bazar-create-${bazar.id}',
    );
  }

  @override
  Future<void> publishItemUpdate(BazarItem item) async {
    final body = {
      'id': item.id,
      'price': item.price,
      'status': _itemStatusToApi(item.status),
      'note': item.note,
      'quantity': item.quantity,
    }..removeWhere((_, value) => value == null);
    try {
      await _client.post('bazars', 'updateItem', body: body);
    } on Object {
      await _client.post(
        'bazars',
        'addItem',
        body: {
          'id': item.id,
          'bazarId': item.bazarId,
          'name': item.name,
          'quantity': item.quantity?.toString(),
          'price': item.price,
          'status': _itemStatusToApi(item.status),
          'note': item.note,
        }..removeWhere((_, value) => value == null),
      );
    }
  }

  @override
  Future<void> publishBazarClose(Bazar bazar) async {
    await _client.post(
      'bazars',
      'close',
      body: {'id': bazar.id},
      idempotencyKey: 'bazar-close-${bazar.id}',
    );
  }

  String _fundIdFor(String walletId) => walletId;
  String _accountIdFor(String walletId) => walletId;
}

class ApiMoneyRemoteDataSource implements MoneyRemoteDataSource {
  const ApiMoneyRemoteDataSource({
    required BazarApiClient client,
    required ApiConfig config,
  }) : _client = client;

  final BazarApiClient _client;

  @override
  Future<void> publishMoneyEntry(MoneyEntry entry) async {
    if (entry.type == EntryType.adjustment) return;
    if (entry.type == EntryType.moneyReceived) {
      await _client.post(
        'money',
        'give',
        body: {
          'id': entry.id,
          'accountId': _accountIdFor(entry.walletId),
          'amount': entry.amount.abs(),
          'note': entry.note,
          'entryDate': _dateOnly(entry.entryDate),
        }..removeWhere((_, value) => value == null),
        idempotencyKey: 'money-${entry.id}',
      );
      return;
    }

    await _client.post(
      'returns',
      'create',
      body: {
        'id': 'return-${entry.id}',
        'accountId': _accountIdFor(entry.walletId),
        'amount': entry.amount.abs(),
        'note': entry.note,
      }..removeWhere((_, value) => value == null),
      idempotencyKey: 'return-create-${entry.id}',
    );
  }

  @override
  Future<void> publishDirectExpense(DirectExpense expense) async {
    throw StateError('Direct expense is not available in API mode');
  }

  @override
  Future<void> publishMonthlyClose({
    required String walletId,
    required String periodMonth,
    String? assistantId,
  }) async {}

  @override
  Future<List<MoneyEntry>> fetchMoneyEntries() async {
    final data = await _client.get('money', 'list');
    return _list(data).map(_moneyEntryFromJson).toList(growable: false);
  }

  String _accountIdFor(String walletId) => walletId;
}

MoneyEntry _moneyEntryFromJson(Map<String, dynamic> json) {
  return MoneyEntry(
    id: json['id']?.toString() ?? '',
    walletId:
        json['account_id']?.toString() ?? json['fund_id']?.toString() ?? '',
    assistantId: json['assistant_id']?.toString() ?? '',
    type: _entryTypeFromApi(json['type']?.toString()),
    amount: _doubleFromApi(json['amount']),
    note: json['note']?.toString(),
    entryDate: _dateTime(json['entry_date']),
    createdBy: json['created_by']?.toString(),
    createdAt: _dateTime(json['created_at']),
    updatedAt: _dateTime(json['updated_at']),
  );
}

UserModel _userFromDto(ApiUserDto dto) {
  return UserModel(
    id: dto.id,
    name: dto.name,
    role: _userRoleFromApi(dto.role),
    isActive: dto.isActive,
    phone: dto.phone,
    email: dto.email,
  );
}


AdminUser _adminUserFromJson(Map<String, dynamic> json) {
  return AdminUser(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    phone: json['phone']?.toString() ?? '',
    role: _adminRoleFromApi(json['role']?.toString()),
    isActive: _boolFromApi(json['is_active'] ?? json['isActive']),
  );
}

Wallet _walletFromFundJson(Map<String, dynamic> json) {
  return Wallet(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    type: _walletTypeFromApi(json['type']?.toString()),
    isActive: (json['status']?.toString() ?? 'active') == 'active',
    createdBy: json['created_by']?.toString(),
    createdAt: _dateTime(json['created_at']),
  );
}

AdminWallet _adminWalletFromFundJson(
  Map<String, dynamic> json, {
  List<String> ownerIds = const [],
}) {
  return AdminWallet(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    type: _walletTypeFromApi(json['type']?.toString()),
    owners: ownerIds,
    ownerIds: ownerIds,
    balance: 0,
    isActive: (json['status']?.toString() ?? 'active') == 'active',
  );
}

Bazar _bazarFromJson(Map<String, dynamic> json) {
  return Bazar(
    id: json['id']?.toString() ?? '',
    walletId:
        json['account_id']?.toString() ?? json['fund_id']?.toString() ?? '',
    createdBy: json['created_by']?.toString() ?? '',
    assignedTo: json['assigned_to']?.toString(),
    title: json['title']?.toString(),
    status: _bazarStatusFromApi(json['status']?.toString()),
    bazarDate: _dateTime(json['bazar_date']),
    createdAt: _dateTime(json['created_at']),
    updatedAt: _dateTime(json['updated_at']),
    closedAt: json['closed_at'] == null ? null : _dateTime(json['closed_at']),
    itemCount: 0,
    spent: 0,
  );
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

UserRole _userRoleFromApi(String? value) {
  return switch (value) {
    'admin' => UserRole.admin,
    'owner' => UserRole.owner,
    _ => UserRole.assistant,
  };
}

AdminRole _adminRoleFromApi(String? value) {
  return switch (value) {
    'admin' => AdminRole.admin,
    'owner' => AdminRole.owner,
    _ => AdminRole.assistant,
  };
}

BazarStatus _bazarStatusFromApi(String? value) {
  return switch (value) {
    'closed' => BazarStatus.closed,
    'cancelled' => BazarStatus.cancelled,
    'draft' => BazarStatus.draft,
    _ => BazarStatus.open,
  };
}

String _bazarStatusToApi(BazarStatus status) => status.name;

String _itemStatusToApi(ItemStatus status) {
  return switch (status) {
    ItemStatus.notFound => 'not_found',
    _ => status.name,
  };
}

String _walletTypeFromApi(String? value) {
  return switch (value) {
    'office_bazar' => 'shared',
    null || '' => 'shared',
    _ => value,
  };
}

String _fundTypeFor(String value) => value == 'shared' ? 'office_bazar' : value;

EntryType _entryTypeFromApi(String? value) {
  return switch (value) {
    'assistant_return_confirmed' || 'money_returned' => EntryType.moneyReturned,
    'adjustment' => EntryType.adjustment,
    _ => EntryType.moneyReceived,
  };
}

double _doubleFromApi(Object? value) {
  if (value is num) return value.toDouble();
  final parsed = double.tryParse(value?.toString() ?? '');
  if (parsed == null) {
    throw const FormatException('API returned invalid number');
  }
  return parsed;
}

bool _boolFromApi(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  return value?.toString() != '0';
}

DateTime _dateTime(Object? value) {
  final normalized = _activeRecordDateText(value);
  final parsed = normalized == null ? null : DateTime.tryParse(normalized);
  if (parsed == null) {
    throw const FormatException('API returned an invalid date');
  }
  return parsed;
}

String? _activeRecordDateText(Object? value) {
  if (value == null) return null;
  if (value is Map) {
    final mapped = _asMap(value);
    return (mapped['date'] ?? mapped['value'])?.toString();
  }
  return value.toString();
}

String _dateOnly(DateTime date) => date.toIso8601String().split('T').first;
