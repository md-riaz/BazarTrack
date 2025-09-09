// File: lib/features/orders/screens/assistant_order_list_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bazar_track/util/colors.dart';
import 'package:bazar_track/util/dimensions.dart';
import 'package:bazar_track/features/auth/controller/auth_controller.dart';
import 'package:bazar_track/features/orders/controller/order_controller.dart';
import 'package:bazar_track/base/empty_state.dart';
import 'components/filter_bar.dart';
import 'components/order_card.dart';

class AssistantOrderListScreen extends StatefulWidget {
  const AssistantOrderListScreen({Key? key}) : super(key: key);

  @override
  _AssistantOrderListScreenState createState() =>
      _AssistantOrderListScreenState();
}

class _AssistantOrderListScreenState extends State<AssistantOrderListScreen>
    with SingleTickerProviderStateMixin {
  late final OrderController orderCtrl;
  late final AuthController authCtrl;
  late final TabController tabCtrl;

  // separate scroll controllers for each tab view
  late final ScrollController _myOrdersScrollCtrl;
  late final ScrollController _unassignedScrollCtrl;

  @override
  void initState() {
    super.initState();
    orderCtrl = Get.find<OrderController>();
    authCtrl = Get.find<AuthController>();

    tabCtrl = TabController(length: 2, vsync: this)
      ..addListener(_onTabChanged);

    _myOrdersScrollCtrl = ScrollController()..addListener(() => _onScroll(_myOrdersScrollCtrl));
    _unassignedScrollCtrl = ScrollController()..addListener(() => _onScroll(_unassignedScrollCtrl));

    // initial setup: get assistants and default filter (my orders)
    // wrap in postFrame to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      orderCtrl.getAllAssistants();
      orderCtrl.setMyOrdersFilter();
      orderCtrl.loadInitial();
    });
  }

  @override
  void dispose() {
    tabCtrl.removeListener(_onTabChanged);
    tabCtrl.dispose();
    _myOrdersScrollCtrl.removeListener(() => _onScroll(_myOrdersScrollCtrl));
    _unassignedScrollCtrl.removeListener(() => _onScroll(_unassignedScrollCtrl));
    _myOrdersScrollCtrl.dispose();
    _unassignedScrollCtrl.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    // respond once when the tab selection starts changing
    if (!tabCtrl.indexIsChanging) return;

    if (tabCtrl.index == 0) {
      orderCtrl.setMyOrdersFilter();
    } else {
      orderCtrl.setUnassignedFilter();
    }
    // reload the list for the newly selected filter
    orderCtrl.loadInitial();
  }

  void _onScroll(ScrollController sc) {
    if (!sc.hasClients) return;

    final threshold = 200.0;
    final maxScroll = sc.position.maxScrollExtent;
    final current = sc.position.pixels;

    if (current >= maxScroll - threshold &&
        !orderCtrl.isLoadingMore.value &&
        orderCtrl.hasMore.value) {
      orderCtrl.loadMore();
    }
  }

  Future<void> _onRefresh() async {
    try {
      await orderCtrl.getAllAssistants();
      await orderCtrl.loadInitial();
    } catch (e) {
      Get.snackbar(
        'Unable to refresh',
        'Check your internet connection and try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ─── Custom TabBar at Top ───
          SafeArea(
            bottom: false,
            child: Material(
              color: Colors.white,
              child: TabBar(
                controller: tabCtrl,
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(text: 'My Orders'),
                  Tab(text: 'Unassigned'),
                ],
              ),
            ),
          ),

          // ─── TabBarView Content ───
          Expanded(
            child: TabBarView(
              controller: tabCtrl,
              children: [
                // My Orders tab
                Column(
                  children: [
                    FilterBar(ctrl: orderCtrl, isOwner: false),
                    Expanded(
                      child: _buildOrderList(scrollController: _myOrdersScrollCtrl),
                    ),
                  ],
                ),

                // Unassigned tab
                Column(
                  children: [
                    // keep same FilterBar for consistency (or hide as desired)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: FilterBar(ctrl: orderCtrl, isOwner: false),
                    ),
                    Expanded(
                      child: _buildOrderList(scrollController: _unassignedScrollCtrl),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a refreshable order list that:
  /// - always supports pull-to-refresh (even when empty or initially loading)
  /// - shows a non-blocking spinner when loading, allowing pull
  Widget _buildOrderList({required ScrollController scrollController}) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _onRefresh,
      child: Obx(() {
        final isInitialLoading = orderCtrl.isInitialLoading.value;
        final orders = orderCtrl.orders;

        // 1) If initial loading and no items yet -> show a scrollable area so pull-to-refresh works.
        if (isInitialLoading && orders.isEmpty) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          );
        }

        // 2) No data -> show empty state but still allow pull-to-refresh
        if (orders.isEmpty) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: const Center(
                child: EmptyState(
                  icon: Icons.inbox,
                  message: 'No orders found.',
                ),
              ),
            ),
          );
        }

        // 3) Data present -> ListView with pagination support and AlwaysScrollablePhysics
        return ListView.separated(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.scaffoldPadding, vertical: 8),
          itemCount: orders.length + (orderCtrl.hasMore.value ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, index) {
            if (index >= orders.length) {
              // bottom loader
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              );
            }
            return OrderCard(order: orders[index]);
          },
        );
      }),
    );
  }
}
