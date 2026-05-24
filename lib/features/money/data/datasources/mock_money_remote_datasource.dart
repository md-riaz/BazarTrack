import '../../../../shared/models/app_enums.dart';
import '../../domain/entities/direct_expense.dart';
import '../../domain/entities/money_entry.dart';

abstract class MoneyRemoteDataSource {
  Future<void> publishMoneyEntry(MoneyEntry entry);
  Future<void> publishDirectExpense(DirectExpense expense);
  Future<void> publishMonthlyClose({
    required String walletId,
    required String periodMonth,
    String? assistantId,
  });
  Future<List<MoneyEntry>> fetchMoneyEntries();
}

class MockMoneyRemoteDataSource implements MoneyRemoteDataSource {
  const MockMoneyRemoteDataSource();

  @override
  Future<void> publishMoneyEntry(MoneyEntry entry) async {}

  @override
  Future<void> publishDirectExpense(DirectExpense expense) async {}

  @override
  Future<void> publishMonthlyClose({
    required String walletId,
    required String periodMonth,
    String? assistantId,
  }) async {}

  @override
  Future<List<MoneyEntry>> fetchMoneyEntries() async {
    final now = DateTime(2025, 5, 23, 12);
    return [
      MoneyEntry(
        id: 'mock-money-1',
        walletId: 'w2',
        walletName: 'CEO Personal',
        assistantId: 'u1',
        assistantName: 'Rahim',
        type: EntryType.moneyReceived,
        amount: 5000,
        note: 'মাসের advance',
        entryDate: now,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}
