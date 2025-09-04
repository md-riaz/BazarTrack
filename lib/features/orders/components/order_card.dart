import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../helper/route_helper.dart';
import '../../../util/colors.dart';
import '../../../util/dimensions.dart';

class OrderCard extends StatelessWidget {
  final order;
  const OrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt.toLocal());
    final statusRaw = order.status.toString().split('.').last;
    final statusLabel = statusRaw.capitalizeFirst ?? statusRaw;
    final statusColor = _statusColor(statusRaw);
    final assigned = order.assignedUserName ?? order.assignedTo;
    final createdBy = order.createdUserName ?? order.createdBy;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      child: IntrinsicHeight( // keeps left accent aligned with card height
        child: Row(
          children: [

            // Card (expanded)
            Expanded(
              child: Material(
                elevation: 1.5,
                borderRadius: BorderRadius.circular(Dimensions.inputFieldBorderRadius),
                child: InkWell(
                  borderRadius: BorderRadius.circular(Dimensions.inputFieldBorderRadius),
                  onTap: () {
                    if (order.orderId != null) {
                      Get.toNamed(RouteHelper.getOrderDetailRoute(order.orderId!));
                    }
                  },
                  child: Container(
                    // Reduced vertical padding for slimmer cards
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Icon square (compact)
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            _statusIcon(statusRaw),
                            color: statusColor,
                            size: 20,
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Main info column
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title row: Order # + small status chip
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Order #${order.orderId ?? '—'}',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  // status chip (compact)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 7,
                                          height: 7,
                                          decoration: BoxDecoration(
                                            color: statusColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          statusLabel,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11,
                                            color: statusColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 6),

                              // Secondary row: created by + assigned (compact icons)
                              Row(
                                children: [
                                  // Created by
                                  Flexible(
                                    child: Row(
                                      children: [
                                        const Icon(Icons.person, size: 13),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            createdBy ?? 'Unknown',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              fontSize: 12,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  if (assigned != null && assigned.isNotEmpty) ...[
                                    const SizedBox(width: 10),
                                    Row(
                                      children: [
                                        const Icon(Icons.person_outline, size: 13),
                                        const SizedBox(width: 6),
                                        Text(
                                          assigned,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            fontSize: 12,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),

                              // Small gap before bottom row
                              const SizedBox(height: 8),

                              // Bottom row: date on bottom-left, chevron on bottom-right
                              Row(
                                children: [
                                  // Left: date with calendar icon
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 13),
                                      const SizedBox(width: 6),
                                      Text(
                                        date,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const Spacer(),

                                  // Right: chevron to indicate navigation
                                  Icon(
                                    Icons.chevron_right,
                                    size: 20,
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Map status (raw string) to a friendly color
  Color _statusColor(String raw) {
    switch (raw.toLowerCase()) {
      case 'pending':
        return AppColors.primary; // amber/orange
      case 'in_progress':
      case 'inprogress':
      case 'processing':
      case 'assigned':
        return AppColors.tertiary; // blue
      case 'completed':
      case 'done':
        return const Color(0xFF08C677); // green
      case 'cancelled':
      case 'canceled':
        return const Color(0xFFC62828); // red
      default:
        return const Color(0xFF616161); // grey
    }
  }

  // Small icon to visually augment the status
  IconData _statusIcon(String raw) {
    switch (raw.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'in_progress':
      case 'inprogress':
      case 'processing':
      case 'assigned':
        return Icons.work;
      case 'completed':
      case 'done':
        return Icons.check_circle;
      case 'cancelled':
      case 'canceled':
        return Icons.cancel;
      default:
        return Icons.receipt_long;
    }
  }
}
