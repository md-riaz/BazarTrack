import 'package:bazar/core/api/bazar_api_client.dart';
import 'package:bazar/core/config/api_config.dart';
import 'package:bazar/features/admin/presentation/screens/admin_audit_screen.dart';
import 'package:bazar/features/api/data/admin_audit_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('requires a reason before enabling reversal confirmation', (tester) async {
    final api = _FakeAuditApi();
    await tester.pumpWidget(MaterialApp(home: AdminAuditScreen(api: api)));
    await tester.pumpAndSettle();

    expect(find.text('অডিট লগ'), findsOneWidget);
    final reverse = find.text('লেনদেন রিভার্স করুন');
    expect(reverse, findsOneWidget);
    await tester.tap(reverse);
    await tester.pumpAndSettle();
    expect(find.text('কারণ লিখুন'), findsOneWidget);
    final confirm = find.ancestor(
      of: find.text('রিভার্স নিশ্চিত করুন'),
      matching: find.byType(FilledButton),
    );
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'Duplicate cash entry');
    await tester.pump();
    await tester.tap(find.text('রিভার্স নিশ্চিত করুন'));
    await tester.pumpAndSettle();

    expect(api.reversedEntryId, 'entry-1');
    expect(api.reason, 'Duplicate cash entry');
  });
}

class _FakeAuditApi extends AdminAuditApi {
  _FakeAuditApi() : super(_unusedClient);

  static final _unusedClient = BazarApiClient(
    config: ApiConfig(
      environment: AppEnvironment.test,
      enabled: true,
      baseUrl: 'https://example.test/index.php',
      defaultFundId: 'fund',
      defaultAccountId: 'account',
      defaultManagerId: 'manager',
      defaultAssistantId: 'assistant',
    ),
  );
  String? reversedEntryId;
  String? reason;

  @override
  Future<List<AdminAuditEntry>> listEntries() async => const [
    AdminAuditEntry(
      id: 'entry-1',
      type: 'fund_gave_money',
      amount: 1000,
      signedAmount: 1000,
      balanceBefore: 0,
      balanceAfter: 1000,
      createdAt: '2026-11-03 12:00:00',
      entryDate: '2026-11-03',
    ),
  ];

  @override
  Future<AdminAuditReconciliation> reconcile() async =>
      const AdminAuditReconciliation(consistent: true, mismatches: []);

  @override
  Future<void> reverse({required String entryId, required String reason}) async {
    reversedEntryId = entryId;
    this.reason = reason;
  }
}
