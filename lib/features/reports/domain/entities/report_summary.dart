class ReportSummary {
  const ReportSummary({
    required this.periodMonth,
    required this.totalReceived,
    required this.totalSpent,
    required this.totalReturned,
    required this.adjustmentTotal,
    required this.netBalance,
    required this.walletBreakdowns,
    required this.topItems,
  });

  final String periodMonth;
  final double totalReceived;
  final double totalSpent;
  final double totalReturned;
  final double adjustmentTotal;
  final double netBalance;
  final List<WalletBreakdown> walletBreakdowns;
  final List<ItemPurchaseSummary> topItems;
}

class WalletBreakdown {
  const WalletBreakdown({
    required this.walletId,
    required this.walletName,
    required this.received,
    required this.spent,
    required this.returnedAmount,
    required this.netBalance,
  });

  final String walletId;
  final String walletName;
  final double received;
  final double spent;
  final double returnedAmount;
  final double netBalance;
}

class ItemPurchaseSummary {
  const ItemPurchaseSummary({
    required this.name,
    required this.quantity,
    required this.totalSpent,
  });

  final String name;
  final int quantity;
  final double totalSpent;
}
