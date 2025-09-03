import 'package:flutter/material.dart';
import 'package:flutter_boilerplate/util/app_format.dart';
import 'package:flutter_boilerplate/util/colors.dart';
import 'package:get/get.dart';
import '../../../base/empty_state.dart';
import '../../../util/dimensions.dart';
import '../model/history_log.dart';
import '../model/history_log_item.dart';

/// Enhanced and more professional HistoryList widget.
/// Improvements made:
/// - Fixed 'load more' sentinel item and scrolling trigger.
/// - Cleaner, responsive header with colored badge and preserved expansion state.
/// - Improved DataTable layout and styling for readability.
/// - Small accessibility and overflow guards.
class HistoryList extends StatelessWidget {
  final RxBool loading;
  final RxBool loadingMore;
  final RxBool hasMore;
  final RxList<HistoryLog> logs;
  final VoidCallback onLoadMore;
  final VoidCallback onRefresh;

  const HistoryList({
    super.key,
    required this.loading,
    required this.loadingMore,
    required this.hasMore,
    required this.logs,
    required this.onLoadMore,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = AppFormats.appDateTimeFormat;

    return Obx(() {
      if (loading.value) {
        return const Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        );
      }

      if (logs.isEmpty) {
        return EmptyState(
          icon: Icons.history,
          message: 'No history entries.',
        );
      }

      // add 1 extra item for the loading indicator when there's more
      final itemCount = logs.length + (hasMore.value ? 1 : 0);

      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          onRefresh();
        },
        child: NotificationListener<ScrollNotification>(
          onNotification: (sn) {
            if (sn.metrics.pixels >= sn.metrics.maxScrollExtent - 100 &&
                hasMore.value &&
                !loadingMore.value) {
              onLoadMore();
            }
            return false;
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              // sentinel loading item at the end
              if (index == logs.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                );
              }

              final log = logs[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                ),
                clipBehavior: Clip.antiAlias,
                key: ValueKey('${log.entityType}_${log.id}'),
                child: Theme(
                  // make ExpansionTile use our card background for ripple
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    key: PageStorageKey('exp_${log.entityType}_${log.id}'),
                    initiallyExpanded: false,
                    tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    childrenPadding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                    collapsedBackgroundColor: Colors.white,
                    backgroundColor: Colors.white,
                    maintainState: true,
                    // Custom header content for a cleaner, professional look
                    title: Row(
                      children: [
                        _EntityBadge(type: log.entityType),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                log.action,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      log.changedByUserName,
                                      style: Theme.of(context).textTheme.bodySmall,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    fmt.format(log.timestamp),
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    expandedAlignment: Alignment.centerLeft,

                    children: [
                      _buildSnapshot(log.dataSnapshot),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
    });
  }

  Widget _buildSnapshot(Map<String, dynamic> snapshot) {
    if (snapshot.isEmpty) return const Text('No snapshot data');

    // keep a predictable order: show simple fields first (alphabetical)
    final rows = <DataRow>[];
    List<HistoryLogItem> items = [];

    final keys = snapshot.keys.toList()..sort();

    for (final key in keys) {
      final value = snapshot[key];

      if (key == 'items') {
        if (value is List) {
          items = value
              .whereType<Map<String, dynamic>>()
              .map((m) => HistoryLogItem.fromJson(m))
              .toList();
        }
      } else {
        rows.add(
          DataRow(
            cells: [
              DataCell(
                Text(key, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              DataCell(
                Text(': ${value ?? ''}', overflow: TextOverflow.visible),
              ),
            ],
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // wrap the table so it can compress on small screens
        SingleChildScrollView(
          key: PageStorageKey('history_items_table_scroll_${snapshot.length}'),
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 280),
            child: DataTable(
              dataRowHeight: 30,
              headingRowHeight: 34,
              horizontalMargin: 8,
              columnSpacing: 16,
              columns: const [
                DataColumn(
                  label: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Name', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                DataColumn(
                  label: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Value', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
              rows: rows,
            ),
          ),
        ),

        const SizedBox(height: 12),

        if (items.isNotEmpty) _buildItemsTable(items) else const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildItemsTable(List<HistoryLogItem> items) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('No items'),
      );
    }

    return SingleChildScrollView(
      key: PageStorageKey('history_items_table_scroll_${items.length}'),
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Text(
              "Items:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 420),
            child: DataTable(
              dataRowHeight: 30,
              headingRowHeight: 34,
              horizontalMargin: 8,
              columnSpacing: 16,
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
                  DataCell(Text(it.actualCost?.toStringAsFixed(2) ?? '-')),
                  DataCell(Text(it.status)),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

}

/// A small badge used on each tile showing entity type
class _EntityBadge extends StatelessWidget {
  final String type;
  const _EntityBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(type);
    final initial = (type.isEmpty ? '?' : type[0].toUpperCase());

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
    );
  }

  Color _colorFor(String t) {
    switch (t.toLowerCase()) {
      case 'order':
        return const Color(0xFF6D5DF6);
      case 'order_item':
        return const Color(0xFF2DBD7E);
      case 'payment':
        return const Color(0xFFFFA726);
      default:
        return const Color(0xFF9E9E9E);
    }
  }
}

