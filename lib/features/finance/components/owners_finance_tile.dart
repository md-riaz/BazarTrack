import 'package:flutter/material.dart';
import 'package:flutter_boilerplate/base/price_format.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../helper/route_helper.dart';
import '../../../util/dimensions.dart';
import '../model/finance.dart';

class OwnersFinanceTile extends StatelessWidget {
  final Finance finance;
  const OwnersFinanceTile({super.key, required this.finance,});

  @override
  Widget build(BuildContext context) {
    final color = finance.amount > 0 ? Colors.red : Colors.green;
    final dateStr = DateFormat('d MMM yyyy h:mma').format(finance.createdAt);

    // Get TextTheme (make sure Get.context is not null in your app)
    final textTheme = Theme.of(Get.context!).textTheme;
    return  Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.inputFieldBorderRadius)),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(Dimensions.inputFieldBorderRadius),
        onTap: () {
          Get.toNamed(RouteHelper.getEntityHistoryRoute('Payment', finance.id.toString()));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(Dimensions.inputFieldBorderRadius),
                ),
                child: Icon(
                  finance.amount > 0 ? Icons.arrow_downward : Icons.arrow_upward,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatPrice(finance.amount),
                      style: textTheme.titleMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dateStr,
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  finance.amount > 0 ? 'Credit' : 'Refund',
                  // credit ? 'Credit' : 'Debit',
                  style: textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

