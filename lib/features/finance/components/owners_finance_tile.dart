import 'package:flutter/material.dart';
import 'package:BazarTrack/base/price_format.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../helper/route_helper.dart';
import '../../../util/dimensions.dart';
import '../model/finance.dart';

class OwnersFinanceTile extends StatelessWidget {
  final Finance finance;
  const OwnersFinanceTile({super.key, required this.finance});

  @override
  Widget build(BuildContext context) {
    final isCredit = finance.amount > 0;
    final color = isCredit ? Colors.red : Colors.green;
    final icon = isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
    final typeLabel = isCredit ? 'Credit' : 'Refund';

    final dateStr = DateFormat('d MMM yyyy, h:mma').format(finance.createdAt);
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 6), // smaller gap between cards
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.inputFieldBorderRadius),
      ),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(Dimensions.inputFieldBorderRadius),
        onTap: () {
          Get.toNamed(RouteHelper.getEntityHistoryRoute('Payment', finance.id.toString()));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // reduced height
          child: Row(
            children: [
              // Compact circular icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),

              // Main Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount & Type
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formatPrice(finance.amount),
                          style: textTheme.titleMedium?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            typeLabel,
                            style: textTheme.bodySmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Assistant + Date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "${isCredit ? "To" : "From"} ${finance.assistantName ?? "-"}",
                            style: textTheme.bodySmall?.copyWith(
                              color: Colors.grey[800],
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          dateStr,
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
