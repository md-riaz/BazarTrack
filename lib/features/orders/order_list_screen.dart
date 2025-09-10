// File: lib/features/orders/screens/order_list_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bazar_track/util/dimensions.dart';
import 'package:bazar_track/util/colors.dart';
import 'package:bazar_track/features/auth/controller/auth_controller.dart';
import 'package:bazar_track/features/orders/controller/order_controller.dart';
import 'package:bazar_track/features/orders/model/order_status.dart';
import 'package:bazar_track/features/auth/model/role.dart';
import '../../base/custom_snackbar.dart';
import '../../base/empty_state.dart';
import '../../helper/route_helper.dart';
import 'components/filter_bar.dart';
import 'components/order_card.dart';

class OrderListScreen extends StatefulWidget {
  final OrderStatus? initialStatus;
  final int? initialAssignedTo;

  const OrderListScreen({
    super.key,
    this.initialStatus,
    this.initialAssignedTo,
  });

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  late final OrderController orderCtrl;
  late final AuthController authController;
  late final ScrollController _scrollController;
  bool _didApplyInitialFilters = false;

  @override
  void initState() {
    super.initState();

    orderCtrl = Get.find<OrderController>();
    orderCtrl.isOwner = true;

    authController = Get.find<AuthController>();

    // Scroll controller used for infinite scroll detection
    _scrollController = ScrollController()..addListener(_onScroll);

    // Perform one-time loads and apply incoming filters.
    // Use addPostFrameCallback so any dependent widget/context is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // apply initial filters without triggering loadInitial immediately
      if (!_didApplyInitialFilters) {
        if (widget.initialStatus != null) {
          orderCtrl.filterStatus.value = widget.initialStatus;
        }
        if (widget.initialAssignedTo != null) {
          orderCtrl.filterAssignedTo.value = widget.initialAssignedTo;
        }
        _didApplyInitialFilters = true;
      }

      // load assistants and the initial page (await so flags are correct)
      try {
        await orderCtrl.getAllAssistants();
        await orderCtrl.loadInitial();
      } catch (e) {
        debugPrint('OrderList init error: $e');
        // optionally show a non-blocking message
        showCustomSnackBar(
          isError: true,
          title: 'Unable to load orders',
          'Please check your internet connection.',
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // When user scrolls near the bottom, load more if allowed
    if (!_scrollController.hasClients) return;

    final threshold = 200.0; // pixels from bottom to trigger load
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;

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
      // optional: return success
    } catch (e) {
      // show friendly feedback
      showCustomSnackBar(
        isError: true,
        title: 'Unable to refresh',
        'Check your internet connection and try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = authController.user.value?.role == UserRole.owner;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _onRefresh,
        child: Obx(() {
          // We still show the filter bar even if content is loading.
          return CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _FilterBarDelegate(
                  child: FilterBar(ctrl: orderCtrl, isOwner: isOwner),
                  height: 72,
                ),
              ),

              // initial loading: show a tall loading area, but keep it inside the scroll view
              if (orderCtrl.isInitialLoading.value)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 12),
                        Text('Loading orders...'),
                      ],
                    ),
                  ),
                )

              // no data: show friendly empty state (still inside scroll view so pull-to-refresh works)
              else if (orderCtrl.orders.isEmpty)
                const SliverFillRemaining(
                  child: EmptyState(
                    icon: Icons.inbox,
                    message: 'No orders found.\nPull down to refresh.',
                  ),
                )

              // data present: show list
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final order = orderCtrl.orders[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.scaffoldPadding,
                        ),
                        child: OrderCard(order: order),
                      );
                    },
                    childCount: orderCtrl.orders.length,
                  ),
                ),

              // bottom loader for pagination
              if (orderCtrl.isLoadingMore.value)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  ),
                ),
              // small bottom padding so the last card is scrollable above FAB
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );
        }),
      ),

      floatingActionButton: isOwner
          ? FloatingActionButton.extended(
        heroTag: 'add_order',
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('New Order'),
        onPressed: () {
          // call the controller method (don't just reference it)
          try {
            orderCtrl.onCreateOrderTapped();
          } catch (_) {}
          Get.toNamed(RouteHelper.orderCreate);
        },
      )
          : null,
    );
  }
}

class _FilterBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _FilterBarDelegate({required this.child, required this.height});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    return Material(
      elevation: overlaps ? 4 : 0,
      color: AppColors.background,
      child: SizedBox.expand(child: child),
    );
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant _FilterBarDelegate old) {
    return child != old.child || height != old.height;
  }
}
