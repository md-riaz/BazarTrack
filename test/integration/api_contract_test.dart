import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _baseUrl = String.fromEnvironment('BAZAR_INTEGRATION_BASE_URL');

void main() {
  final enabled = _baseUrl.isNotEmpty;

  test(
    'health response keeps the data envelope contract',
    () async {
      final response = await _request('health', 'index');
      expect(response.statusCode, 200);
      expect(response.json['data'], isA<Map<String, dynamic>>());
      expect((response.json['data'] as Map<String, dynamic>)['ok'], isTrue);
    },
    skip: enabled ? false : _skipMessage,
  );

  test(
    'bearer token resolves auth/me and protected fund DTOs',
    () async {
      final login = await _login('owner');
      expect(login.user['role'], 'owner');
      expect(login.user['id'], isA<String>());
      expect(login.user['name'], isA<String>());

      final me = await _request('auth', 'me', token: login.token);
      expect(me.statusCode, 200);
      final currentUser = _dataMap(me);
      expect(currentUser['id'], login.user['id']);
      expect(currentUser['company_id'], isA<String>());
      expect(currentUser['is_active'], anyOf(1, true));

      final funds = await _request('funds', 'list', token: login.token);
      expect(funds.statusCode, 200);
      final fundRows = _dataList(funds);
      expect(fundRows, isNotEmpty);
      final fund = fundRows.first;
      expect(fund['id'], isA<String>());
      expect(fund['company_id'], isA<String>());
      expect(fund['name'], isA<String>());
      expect(fund['status'], 'active');

      final accounts = await _request('accounts', 'list', token: login.token);
      expect(accounts.statusCode, 200);
      final accountRows = _dataList(accounts);
      expect(accountRows, isNotEmpty);
      final account = accountRows.first;
      expect(account['id'], isA<String>());
      expect(account['fund_id'], fund['id']);
      expect(account['assistant_id'], isA<String>());
      expect(num.parse(account['current_balance'].toString()), isA<num>());

      final report = await _request(
        'reports',
        'summary',
        token: login.token,
        query: {
          'from': '2026-10-01',
          'to': '2026-10-31',
          'fundId': fund['id'].toString(),
          'accountId': account['id'].toString(),
        },
      );
      expect(report.statusCode, 200);
      final reportData = _dataMap(report);
      expect(reportData['summary'], isA<Map<String, dynamic>>());
      final summary = reportData['summary'] as Map<String, dynamic>;
      for (final key in [
        'fundGiven',
        'returnedConfirmed',
        'bazarSpent',
        'adjustments',
        'netBalanceChange',
      ]) {
        expect(num.parse(summary[key].toString()), isA<num>());
      }
    },
    skip: enabled ? false : _skipMessage,
  );

  test(
    'protected endpoint rejects missing and unknown bearer tokens',
    () async {
      final missing = await _request('funds', 'list');
      expect(missing.statusCode, 401);
      expect(missing.json['error'], isA<Map<String, dynamic>>());

      final unknown = await _request(
        'funds',
        'list',
        token: List.filled(64, 'f').join(),
      );
      expect(unknown.statusCode, 401);
      expect(unknown.json['error'], isA<Map<String, dynamic>>());
    },
    skip: enabled ? false : _skipMessage,
  );
}

const _skipMessage =
    'Set --dart-define=BAZAR_INTEGRATION_BASE_URL=http://127.0.0.1:18080/index.php and run the local seeded API.';

Future<_LoginResult> _login(String role) async {
  final response = await _request(
    'auth',
    'login',
    method: 'POST',
    body: {'phone': role, 'password': 'demo-pass'},
  );
  expect(response.statusCode, 200);
  final data = _dataMap(response);
  expect(data['token'], isA<String>());
  expect((data['token'] as String).length, 64);
  expect(data['tokenType'], 'Bearer');
  expect(data['user'], isA<Map<String, dynamic>>());
  return _LoginResult(
    data['token'] as String,
    data['user'] as Map<String, dynamic>,
  );
}

Map<String, dynamic> _dataMap(_ApiResponse response) {
  expect(response.json['data'], isA<Map<String, dynamic>>());
  return response.json['data'] as Map<String, dynamic>;
}

List<Map<String, dynamic>> _dataList(_ApiResponse response) {
  expect(response.json['data'], isA<List<dynamic>>());
  return (response.json['data'] as List<dynamic>).cast<Map<String, dynamic>>();
}

Future<_ApiResponse> _request(
  String command,
  String action, {
  String method = 'GET',
  Map<String, String> query = const {},
  Map<String, dynamic>? body,
  String? token,
}) async {
  final uri = Uri.parse(
    _baseUrl,
  ).replace(queryParameters: {'cmd': command, 'action': action, ...query});
  final client = HttpClient();
  try {
    final request = await client.openUrl(method, uri);
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    request.headers.set('X-Client-Id', 'flutter-contract-test');
    if (token != null) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    }
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
    }
    final response = await request.close();
    final text = await utf8.decoder.bind(response).join();
    return _ApiResponse(
      response.statusCode,
      jsonDecode(text) as Map<String, dynamic>,
    );
  } finally {
    client.close(force: true);
  }
}

class _LoginResult {
  const _LoginResult(this.token, this.user);

  final String token;
  final Map<String, dynamic> user;
}

class _ApiResponse {
  const _ApiResponse(this.statusCode, this.json);

  final int statusCode;
  final Map<String, dynamic> json;
}
