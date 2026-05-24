import '../../shared/models/app_enums.dart';
import 'currency_formatter.dart';

class BalancePresentation {
  const BalancePresentation({
    required this.label,
    required this.amountText,
    required this.status,
  });

  final String label;
  final String amountText;
  final SyncStatus status;
}

class BalanceFormatter {
  BalanceFormatter._();

  static BalancePresentation format(num balance, {num inProgress = 0}) {
    if (balance == 0 && inProgress == 0) {
      return const BalancePresentation(
        label: 'হিসাব মিলে গেছে ✓',
        amountText: '৳ ০',
        status: SyncStatus.online,
      );
    }

    if (balance > 0) {
      return BalancePresentation(
        label: 'হাতে আছে',
        amountText: CurrencyFormatter.format(balance),
        status: inProgress == 0 ? SyncStatus.online : SyncStatus.syncing,
      );
    }

    return BalancePresentation(
      label: 'পাওনা আছে',
      amountText: CurrencyFormatter.format(balance),
      status: inProgress == 0 ? SyncStatus.failed : SyncStatus.offline,
    );
  }
}
