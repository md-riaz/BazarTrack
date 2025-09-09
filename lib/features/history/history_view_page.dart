import 'package:flutter/material.dart';
import 'package:bazar_track/base/custom_app_bar.dart';
import 'package:bazar_track/util/app_format.dart';
import 'package:get/get.dart';

import '../../base/empty_state.dart';
import '../../util/colors.dart';
import '../../util/dimensions.dart';
import 'controller/history_controller.dart';
import 'model/history_log.dart';
import 'model/history_log_item.dart';

/// Entity-specific History Page
/// Designed for: Order / OrderItem / Payment history timeline for a single entity
/// - Optimized: minimal, focused, and professional UI
/// - Usage: HistoryEntityPage(entity: 'order', entityId: 123)
class HistoryViewPage extends StatelessWidget {
  final String entity;
  final int entityId;

  const HistoryViewPage({super.key, required this.entity, required this.entityId});

  @override
  Widget build(BuildContext context) {
    final HistoryController ctrl = Get.find<HistoryController>();

    // load once on build (guarded by microtask)
    Future.microtask(() => ctrl.loadByEntityId(entity, entityId));

    return Scaffold(
      appBar: CustomAppBar(title: '${_titleFor(entity)} #$entityId'),
      body: SafeArea(
        child: Obx(() {
          if (ctrl.isLoading.value) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final logs = List<HistoryLog>.from(ctrl.logs.where((l) => l.entityId == entityId || l.entityType.toLowerCase() == entity.toLowerCase()));

          if (logs.isEmpty) {
            return const EmptyState(icon: Icons.history, message: 'No history found for this item.');
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => await ctrl.loadByEntityId(entity, entityId),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
              itemCount: logs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final log = logs[index];
                return _TimelineCard(log: log);
              },
            ),
          );
        }),
      ),
    );
  }

  String _titleFor(String raw) {
    final r = raw.replaceAll('_', ' ');
    return r[0].toUpperCase() + r.substring(1);
  }
}

/// Compact, professional timeline card for one history entry
class _TimelineCard extends StatefulWidget {
  final HistoryLog log;
  const _TimelineCard({Key? key, required this.log}) : super(key: key);

  @override
  State<_TimelineCard> createState() => _TimelineCardState();
}

class _TimelineCardState extends State<_TimelineCard> with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final log = widget.log;
    final actionColor = _actionColor(log.action);

    return Card(
      elevation: 1.8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  // colored icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: actionColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Icon(_iconFor(log.entityType), color: actionColor, size: 20),
                  ),

                  const SizedBox(width: 12),

                  // Main text area
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: Type on left, Action label on right (no nested Expanded inside SizedBox)
                        Row(
                          children: [
                            // Left: type label + entity (takes remaining space)
                            Expanded(
                              child: Row(
                                children: [
                                  Text('Type:', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700], fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(log.entityType, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Right: action text (compact) — placed outside the left Expanded to avoid layout conflicts
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: actionColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(log.action, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: actionColor, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // actor + timestamp row
                        Row(
                          children: [
                            Expanded(
                              child: Text('${log.action.capitalizeFirst} by ${log.changedByUserName}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[800])),
                            ),

                            const SizedBox(width: 8),

                            Text(AppFormats.appDateTimeFormat.format(log.timestamp), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // chevron
                  RotationTransition(
                    turns: Tween(begin: 0.0, end: 0.5).animate(_animController),
                    child: Icon(Icons.expand_more, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),

          // Divider
          const Divider(height: 1),

          // Expandable snapshot
          SizeTransition(
            sizeFactor: CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
            axisAlignment: -1.0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: _SnapshotView(log.dataSnapshot),
            ),
          ),
        ],
      ),
    );
  }
}

// Wherever you build the snapshot view, replace the items‐list case

Widget _SnapshotView(Map<String, dynamic> snapshot) {
  if (snapshot.isEmpty) return const Text('No snapshot data');

  final rows = <DataRow>[];
  List<HistoryLogItem> items = [];

  snapshot.forEach((key, value) {
    if (key == 'items') {
      if (value is List) {
        items = value
            .whereType<Map<String, dynamic>>()
            .map((m) => HistoryLogItem.fromJson(m))
            .toList();
      }
    } else {
      rows.add(
        DataRow(cells: [
          DataCell(Text(key, style: const TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text(': ${value ?? ''}')),
        ]),
      );
    }
  });

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Key/Value table (simple responsive layout)
      SingleChildScrollView(
          key: PageStorageKey('history_items_table_scroll_${snapshot.length}'),
          // scrollDirection: Axis.horizontal,
          child: DataTable(
            dataRowHeight: 25,
            headingRowHeight: 25,
            horizontalMargin: 0,
            columnSpacing: 10,
            columns: const [
              DataColumn(
                label: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Name'),
                ),
              ),
              DataColumn(
                label: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Value'),
                ),
              ),
            ],
            rows: rows,
          )
      ),

      const SizedBox(height: 16),

      // --- Items table (only if present) ---
      if (items.isNotEmpty)
        _buildItemsTable(items)
      else
        const Text(''),
    ],
  );
}

/// DataTable to show products with nullable costs
Widget _buildItemsTable(List<HistoryLogItem> items) {
  if (items.isEmpty) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Text('No items'),
    );
  }

  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Items:", style: TextStyle(fontWeight: FontWeight.bold),),
        DataTable(
          dataRowHeight: 25,
          headingRowHeight: 25,
          horizontalMargin: 0,
          columnSpacing: 10,
          columns: const [
            DataColumn(label: Text('Product')),
            DataColumn(label: Text('Qty')),
            DataColumn(label: Text('Unit')),
            DataColumn(label: Text('Est. Cost')),
            DataColumn(label: Text('Act. Cost')),
            DataColumn(label: Text('Status')),
          ],
          rows: items.map((it) {
            return DataRow(cells: [
              DataCell(Text(it.productName)),
              DataCell(Text(it.quantity.toString())),
              DataCell(Text(it.unit)),
              DataCell(Text(it.estimatedCost?.toStringAsFixed(2) ?? '-')),
              DataCell(Text(it.actualCost?.toStringAsFixed(2)    ?? '-')),
              DataCell(Text(it.status)),
            ]);
          }).toList(),
        ),
      ],
    ),
  );
}


// Helper functions
Color _actionColor(String action) {
  switch (action.toLowerCase()) {
    case 'created':
    case 'create':
    return Colors.orange;
    case 'completed':
    case 'complete':
    return const Color(0xFF08A840);
    case 'updated':
    case 'edit':
      return Colors.blue;
    case 'deleted':
    case 'remove':
      return Colors.red;
    default:
      return AppColors.primary;
  }
}

IconData _iconFor(String t) {
  switch (t.toLowerCase()) {
    case 'order':
      return Icons.receipt_long;
    case 'order_item':
    case 'orderitem':
    case 'order-item':
      return Icons.shopping_cart;
    case 'payment':
      return Icons.payment;
    case 'user':
      return Icons.person;
    case 'product':
      return Icons.inventory_2;
    default:
      return Icons.device_unknown;
  }
}
