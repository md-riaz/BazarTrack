import 'dart:convert';

import 'package:bazar/core/api/bazar_api_client.dart';
import 'package:bazar/core/config/api_config.dart';
import 'package:bazar/features/api/data/bazar_api_repositories.dart';
import 'package:bazar/features/auth/domain/entities/user.dart';
import 'package:bazar/features/auth/domain/services/role_permissions.dart';
import 'package:bazar/features/auth/presentation/providers/auth_provider.dart';
import 'package:bazar/features/money/domain/entities/money_return_request.dart';
import 'package:bazar/features/money/domain/repositories/money_entry_repository.dart';
import 'package:bazar/features/money/presentation/providers/money_providers.dart';
import 'package:bazar/features/money/presentation/widgets/pending_return_requests.dart';
import 'package:bazar/shared/models/app_enums.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'role permissions separate assistant request from manager confirmation',
    () {
      expect(RolePermissions.canRequestMoneyReturn(UserRole.assistant), isTrue);
      expect(
        RolePermissions.canConfirmMoneyReturn(UserRole.assistant),
        isFalse,
      );
      expect(RolePermissions.canConfirmMoneyReturn(UserRole.owner), isTrue);
      expect(RolePermissions.canConfirmMoneyReturn(UserRole.admin), isTrue);
    },
  );

  test(
    'return request maps ActiveRecord requested_at and confirms separately',
    () async {
      final adapter = _ReturnAdapter();
      final repository = ApiMoneyEntryRepository(
        client: BazarApiClient(
          config: _config(),
          dio: Dio()..httpClientAdapter = adapter,
        ),
        config: _config(),
      );

      final pending = await repository.getPendingReturnRequests();
      final confirmed = await repository.confirmReturnRequest(
        pending.single.id,
      );

      expect(
        pending.single.requestedAt,
        DateTime.parse('2026-10-26 07:00:00.000000'),
      );
      expect(confirmed.status, 'confirmed');
      expect(adapter.confirmBody, {'id': 'return-1'});
    },
  );

  testWidgets('assistant cannot see manager confirmation controls', (
    tester,
  ) async {
    await tester.pumpWidget(_app(UserRole.assistant));
    await tester.pumpAndSettle();
    expect(find.text('নিশ্চিত করুন'), findsNothing);
  });

  testWidgets('manager sees and confirms pending return request', (
    tester,
  ) async {
    final repository = _FakeReturnRepository();
    await tester.pumpWidget(_app(UserRole.owner, repository: repository));
    await tester.pumpAndSettle();
    expect(find.text('নিশ্চিত করুন'), findsOneWidget);
    await tester.tap(find.text('নিশ্চিত করুন'));
    await tester.pumpAndSettle();
    expect(repository.confirmedIds, ['return-1']);
  });
}

Widget _app(UserRole role, {MoneyEntryRepository? repository}) {
  const users = {
    UserRole.admin: User(
      id: 'a',
      name: 'Admin',
      role: UserRole.admin,
      isActive: true,
    ),
    UserRole.owner: User(
      id: 'm',
      name: 'Manager',
      role: UserRole.owner,
      isActive: true,
    ),
    UserRole.assistant: User(
      id: 's',
      name: 'Assistant',
      role: UserRole.assistant,
      isActive: true,
    ),
  };
  return ProviderScope(
    overrides: [
      currentUserProvider.overrideWith((ref) => Stream.value(users[role]!)),
      if (repository != null)
        moneyEntryRepositoryProvider.overrideWithValue(repository),
    ],
    child: const MaterialApp(home: Scaffold(body: PendingReturnRequests())),
  );
}

class _FakeReturnRepository implements MoneyEntryRepository {
  final confirmedIds = <String>[];
  final request = MoneyReturnRequest(
    id: 'return-1',
    accountId: 'account-1',
    assistantId: 'assistant-1',
    amount: 100,
    status: 'pending',
    requestedAt: DateTime(2026),
  );
  @override
  Future<List<MoneyReturnRequest>> getPendingReturnRequests() async => [
    request,
  ];
  @override
  Future<MoneyReturnRequest> confirmReturnRequest(String requestId) async {
    confirmedIds.add(requestId);
    return MoneyReturnRequest(
      id: request.id,
      accountId: request.accountId,
      assistantId: request.assistantId,
      amount: request.amount,
      status: 'confirmed',
      requestedAt: request.requestedAt,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ReturnAdapter implements HttpClientAdapter {
  Map<String, dynamic>? confirmBody;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final confirmed = options.queryParameters['action'] == 'confirm';
    if (confirmed) confirmBody = Map<String, dynamic>.from(options.data as Map);
    final request = {
      'id': 'return-1',
      'account_id': 'account-1',
      'assistant_id': 'assistant-1',
      'amount': '100.00',
      'status': confirmed ? 'confirmed' : 'pending',
      'requested_at': {'date': '2026-10-26 07:00:00.000000'},
    };
    return _json({
      'data': confirmed ? {'request': request} : [request],
    });
  }

  @override
  void close({bool force = false}) {}
}

ApiConfig _config() => ApiConfig(
  environment: AppEnvironment.test,
  enabled: true,
  baseUrl: 'https://example.test/index.php',
  defaultFundId: 'unused-f',
  defaultAccountId: 'unused-a',
  defaultManagerId: 'unused-m',
  defaultAssistantId: 'unused-s',
);
ResponseBody _json(Object body) => ResponseBody.fromString(
  jsonEncode(body),
  200,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);
