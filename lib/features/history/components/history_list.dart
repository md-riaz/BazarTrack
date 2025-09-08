import 'package:flutter/material.dart';
import 'package:BazarTrack/base/price_format.dart';
import 'package:BazarTrack/util/app_format.dart';
import 'package:BazarTrack/util/colors.dart';
import 'package:get/get.dart';
import '../../../util/dimensions.dart';
import '../model/history_log.dart';
import '../model/history_log_item.dart';

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
          child: CircularProgressIndicator(color: AppColors.primary),
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
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12), // standard outer padding
            itemCount: itemCount,
            itemBuilder: (context, index) {
              // sentinel loading item at the end
              if (index == logs.length) {
                return Center(
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final log = logs[index];
              final tileUniqueId = '${log.entityType}_${log.id}_$index';
              final actionColor = _actionColor(log.action);

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                elevation: 1.8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                ),
                clipBehavior: Clip.antiAlias,
                key: ValueKey('history_tile_$tileUniqueId'),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // content (ExpansionTile) with professional padding
                    Expanded(
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                          listTileTheme: ListTileThemeData(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        child: ExpansionTile(
                          key: PageStorageKey('exp_$tileUniqueId'),
                          initiallyExpanded: false,
                          backgroundColor: Colors.white,
                          collapsedBackgroundColor: Colors.white,
                          maintainState: true,

                          childrenPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),

                          // leading: proper icon colored by action
                          leading: _EntityIcon(
                            type: log.entityType,
                            size: 36,
                            color: actionColor,
                          ),


                          // Title: 'type:' (raw) followed by neutral entity text (no material pill)
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  "Type: ${log.entityType.capitalizeFirst}",
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: Colors.grey[800],                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: actionColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  log.action.capitalizeFirst!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                    color: actionColor,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    log.changedByUserName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                      color: Colors.grey[700],
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  fmt.format(log.timestamp),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          children: [
                            _buildSnapshot(log.dataSnapshot, id: tileUniqueId),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    });
  }

  Widget _buildSnapshot(Map<String, dynamic> snapshot,
      {required String id}) {
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
                Text(key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
              ),
              DataCell(
                Text(': ${value ?? ''}', overflow: TextOverflow.visible,style: TextStyle(fontSize: 12)),
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
          // include the tile id in the PageStorageKey to avoid duplicate key collisions
          key: PageStorageKey(
              'history_items_table_scroll_${id}_${snapshot.length}'),
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 280),
            child: DataTable(
              dataRowHeight: 24,
              headingRowHeight: 24,
              horizontalMargin: 0,
              columnSpacing: 10,
              columns: const [
                DataColumn(
                  label: Align(
                    alignment: Alignment.centerLeft,
                    child:
                    Text('Name', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ),
                DataColumn(
                  label: Align(
                    alignment: Alignment.centerLeft,
                    child:
                    Text('Value', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ),
              ],
              rows: rows,
            ),
          ),
        ),

        const SizedBox(height: 10),

        if (items.isNotEmpty)
          _buildItemsTable(items, id: id)
        else
          const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildItemsTable(List<HistoryLogItem> items, {required String id}) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('No items'),
      );
    }

    return SingleChildScrollView(
      // include the tile id here too to keep this key unique
      key: PageStorageKey(
          'history_items_table_scroll_items_${id}_${items.length}'),
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Text(
              "Items:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          DataTable(
            dataRowHeight: 24,
            headingRowHeight: 24,
            horizontalMargin: 0,
            columnSpacing: 10,
            columns: const [
              DataColumn(label: Text('Product', style: TextStyle(fontSize: 12))),
              DataColumn(label: Text('Qty',style: TextStyle(fontSize: 12))),
              DataColumn(label: Text('Unit',style: TextStyle(fontSize: 12)),),
              DataColumn(label: Text('Est. Cost',style: TextStyle(fontSize: 12))),
              DataColumn(label: Text('Act. Cost',style: TextStyle(fontSize: 12))),
              DataColumn(
                label: Text('Status',style: TextStyle(fontSize: 12)),
                headingRowAlignment: MainAxisAlignment.end,
              ),
            ],
            rows: items.map((it) {
              return DataRow(
                cells: [
                  DataCell(Text(it.productName,style: TextStyle(fontSize: 12))),
                  DataCell(Text(it.quantity.toString(),style: TextStyle(fontSize: 12))),
                  DataCell(Text(it.unit,style: TextStyle(fontSize: 12))),
                  DataCell(Text(formatPrice(it.estimatedCost),style: TextStyle(fontSize: 12))),
                  DataCell(Text(formatPrice(it.actualCost),style: TextStyle(fontSize: 12))),
                  DataCell(Text(it.status,style: TextStyle(fontSize: 12))),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _actionColor(String action) {
    switch (action.toLowerCase()) {
      case 'created':
      case 'create':
        return Colors.green;
      case 'updated':
      case 'edit':
        return Colors.blue;
      case 'deleted':
      case 'remove':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}

/// Icon widget for entity type (colored by action)
class _EntityIcon extends StatelessWidget {
  final String type;
  final double size;
  final Color color;
  const _EntityIcon({required this.type, this.size = 36, required this.color});

  @override
  Widget build(BuildContext context) {
    final icon = _iconFor(type);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        color: color,
      ),
    );
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
}

