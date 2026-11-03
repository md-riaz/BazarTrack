import 'dart:convert';

import 'package:bazar/core/api/bazar_api_client.dart';
import 'package:bazar/core/config/api_config.dart';
import 'package:bazar/features/admin/domain/entities/admin_entities.dart';
import 'package:bazar/features/api/data/bazar_api_data_sources.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('login maps must_change_password and change password updates user', () async {
    final adapter = _LifecycleAdapter();
    final source = ApiAuthRemoteDataSource(_client(adapter));

    final login = await source.login(phone: '01700000000', password: 'Temp1234');
    expect(login.user.mustChangePassword, isTrue);

    final changed = await source.changePassword(
      currentPassword: 'Temp1234',
      newPassword: 'Permanent1234',
    );
    expect(adapter.lastBody, {
      'currentPassword': 'Temp1234',
      'newPassword': 'Permanent1234',
    });
    expect(changed.mustChangePassword, isFalse);
  });

  test('admin create submits password and setActive payload', () async {
    final adapter = _LifecycleAdapter();
    final source = ApiAdminRemoteDataSource(_client(adapter));

    await source.createUser(
      const CreateAdminUserRequest(
        name: 'New User',
        phone: '01700000000',
        password: 'Temp1234',
        role: AdminRole.assistant,
      ),
    );
    expect(adapter.lastBody?['password'], 'Temp1234');

    await source.setUserActive(userId: 'user-1', isActive: false);
    expect(adapter.lastBody, {'id': 'user-1', 'isActive': false});
  });
}

BazarApiClient _client(HttpClientAdapter adapter) => BazarApiClient(
  config: ApiConfig(
    environment: AppEnvironment.test,
    enabled: true,
    baseUrl: 'https://example.test/index.php',
    defaultFundId: 'f',
    defaultAccountId: 'a',
    defaultManagerId: 'm',
    defaultAssistantId: 's',
  ),
  dio: Dio()..httpClientAdapter = adapter,
);

class _LifecycleAdapter implements HttpClientAdapter {
  Map<String, dynamic>? lastBody;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastBody = options.data is Map ? Map<String, dynamic>.from(options.data as Map) : null;
    final action = options.queryParameters['action'];
    final user = {
      'id': 'user-1',
      'company_id': 'company-1',
      'role': 'assistant',
      'name': 'New User',
      'phone': '01700000000',
      'is_active': 1,
      'must_change_password': action == 'login' ? 1 : 0,
    };
    final data = action == 'login'
        ? {'token': 'token', 'tokenType': 'Bearer', 'user': user}
        : action == 'changePassword'
            ? {'user': user}
            : user;
    return ResponseBody.fromString(
      jsonEncode({'data': data}),
      200,
      headers: {Headers.contentTypeHeader: ['application/json']},
    );
  }

  @override
  void close({bool force = false}) {}
}
