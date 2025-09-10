// File: lib/features/history/ui/history_center_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../base/custom_snackbar.dart';
import '../../base/empty_state.dart';
import '../../util/colors.dart';
import 'components/history_list.dart';
import 'controller/history_controller.dart';
import 'model/history_log.dart';

class HistoryCenterPage extends StatefulWidget {
  const HistoryCenterPage({super.key});

  @override
  State<HistoryCenterPage> createState() => _HistoryCenterPageState();
}

class _HistoryCenterPageState extends State<HistoryCenterPage>
    with SingleTickerProviderStateMixin {
  late final HistoryController ctrl;
  late final TabController tabController;

  @override
  void initState() {
    super.initState();
    ctrl = Get.find<HistoryController>();
    tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  Widget _buildTab({
    required BuildContext context,
    required RxBool loading,
    required RxList<HistoryLog> logs,
    required RxBool loadingMore,
    required RxBool hasMore,
    required Future<void> Function() onRefresh,
    required VoidCallback onLoadMore,
  }) {
    final bool isInitialLoading = loading.value && logs.isEmpty;
    final bool isEmptyNotLoading = !loading.value && logs.isEmpty;

    Future<void> _safeRefresh() async {
      try {
        await onRefresh();
      } catch (e) {
        showCustomSnackBar(isError: true,title: 'Unable to refresh', 'Please check your internet connection and try again.');
      }
    }

    // 1) Initial loading with no items: show a scrollable spinner so pull-to-refresh works.
    if (isInitialLoading) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _safeRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
        ),
      );
    }

    // 2) No items and NOT loading: show empty state (still scrollable so pull works).
    if (isEmptyNotLoading) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _safeRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: const Center(
              child: EmptyState(
                icon: Icons.history,
                message: 'No history entries.',
              ),
            ),
          ),
        ),
      );
    }

    // 3) Otherwise: we have items (or we are loading more while items exist).
    // Wrap the real list so pull-to-refresh always works.
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _safeRefresh,
      child: HistoryList(
        loading: loading,
        logs: logs,
        loadingMore: loadingMore,
        hasMore: hasMore,
        onLoadMore: onLoadMore,
        onRefresh: onRefresh,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // outer scaffold kept for consistency with other pages
      body: SafeArea(
        child: Column(
          children: [
            // Stylish tab bar container
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 12, 16, 0),
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: TabBar(
                    controller: tabController,
                    indicator: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    indicatorPadding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 4,
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor:
                    Theme.of(context).textTheme.bodyLarge?.color,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                    unselectedLabelStyle:
                    const TextStyle(fontWeight: FontWeight.w600),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                    tabs: const [
                      Tab(text: 'All'),
                      Tab(text: 'Orders'),
                      Tab(text: 'Items'),
                      Tab(text: 'Payments'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: tabController,
                children: [
                  Obx(
                        () => _buildTab(
                      context: context,
                      loading: ctrl.isLoadingAll,
                      logs: ctrl.allLogs,
                      loadingMore: ctrl.allLoadingMore,
                      hasMore: ctrl.allHasMore,
                      onLoadMore: ctrl.loadMoreAll,
                      onRefresh: ctrl.refreshAll,
                    ),
                  ),
                  Obx(
                        () => _buildTab(
                      context: context,
                      loading: ctrl.isLoadingOrder,
                      logs: ctrl.orderLogs,
                      loadingMore: ctrl.orderLoadingMore,
                      hasMore: ctrl.orderHasMore,
                      onLoadMore: ctrl.loadMoreOrders,
                      onRefresh: ctrl.refreshOrders,
                    ),
                  ),
                  Obx(
                        () => _buildTab(
                      context: context,
                      loading: ctrl.isLoadingItem,
                      logs: ctrl.itemLogs,
                      loadingMore: ctrl.itemLoadingMore,
                      hasMore: ctrl.itemHasMore,
                      onLoadMore: ctrl.loadMoreItems,
                      onRefresh: ctrl.refreshItems,
                    ),
                  ),
                  Obx(
                        () => _buildTab(
                      context: context,
                      loading: ctrl.isLoadingPayment,
                      logs: ctrl.paymentLogs,
                      loadingMore: ctrl.paymentLoadingMore,
                      hasMore: ctrl.paymentHasMore,
                      onLoadMore: ctrl.loadMorePayments,
                      onRefresh: ctrl.refreshPayments,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
