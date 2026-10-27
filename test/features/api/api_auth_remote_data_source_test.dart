import 'dart:convert';

import 'package:bazar/core/api/bazar_api_client.dart';
import 'package:bazar/core/config/api_config.dart';
import 'package:bazar/features/api/data/api_dtos.dart';
import 'package:bazar/features/api/data/bazar_api_data_sources.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses the camelCase tokenType returned by the PHP login API', () async {
    final client = BazarApiClient(
      config: _config(),
      dio: Dio()..httpClientAdapter = _LoginAdapter(),
    );

    final response = await ApiAuthRemoteDataSource(client).login(
      phone: '01000-ADMIN',
      password: 'demo-pass',
    );

    expect(response.token, 'server-token');
    expect(response.user.id, 'admin1');
    expect(response.user.isActive, isTrue);
  });

  test('preserves PHP login and user wire keys when serializing DTOs', () {
    final dto = ApiLoginDto.fromJson({
      'token': 'server-token',
      'tokenType': 'Bearer',
      'user': {
        'id': 'admin1',
        'company_id': 'company1',
        'role': 'admin',
        'name': 'System Admin',
        'is_active': 1,
      },
    });

    expect(dto.tokenType, 'Bearer');
    expect(dto.toJson(), containsPair('tokenType', 'Bearer'));
    expect(dto.toJson(), isNot(contains('token_type')));
    expect(dto.user.toJson(), containsPair('company_id', 'company1'));
    expect(dto.user.toJson(), containsPair('is_active', isTrue));
  });
}

ApiConfig _config() => ApiConfig(
  environment: AppEnvironment.test,
  enabled: true,
  baseUrl: 'http://api.example.test/index.php',
  defaultFundId: 'fund1',
  defaultAccountId: 'account1',
  defaultManagerId: 'manager1',
  defaultAssistantId: 'assistant1',
);

class _LoginAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode({
        'data': {
          'token': 'server-token',
          'tokenType': 'Bearer',
          'user': {
            'id': 'admin1',
            'company_id': 'company1',
            'role': 'admin',
            'name': 'System Admin',
            'is_active': 1,
          },
        },
      }),
      200,
      headers: {Headers.contentTypeHeader: ['application/json']},
    );
  }
}
