import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BazarTrack/base/custom_app_bar.dart';
import 'package:BazarTrack/features/auth/service/auth_service.dart';
import 'package:BazarTrack/features/dashboard/controller/assistant_analytics_controller.dart';
import 'package:BazarTrack/features/dashboard/repository/analytics_repo.dart';
import 'package:BazarTrack/features/finance/model/assistant.dart';
import 'package:BazarTrack/features/orders/repository/order_repo.dart';
import '../../util/colors.dart';
import '../auth/model/role.dart';
import 'components/assistant_reports_chart.dart';
import 'components/assistant_stats_summary.dart';
import 'components/recent_orders.dart';

class AssistantDashboardDetails extends StatefulWidget {
  final Assistant assistant;

  const AssistantDashboardDetails({super.key, required this.assistant});

  @override
  State<AssistantDashboardDetails> createState() =>
      _AssistantDashboardDetailsState();
}

class _AssistantDashboardDetailsState extends State<AssistantDashboardDetails> {
  late final AssistantAnalyticsController ctrl;
  late final bool isOwner;

  @override
  void initState() {
    super.initState();
    ctrl = Get.put(
      AssistantAnalyticsController(
        analyticsRepo: Get.find<AnalyticsRepo>(),
        orderRepo: Get.find<OrderRepo>(),
        authService: Get.find(),
        assistantId: widget.assistant.id,
      ),
      tag: 'assistant_${widget.assistant.id}',
    );
    isOwner = Get.find<AuthService>().currentUser?.role == UserRole.owner;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const spacer = SizedBox(height: 8);

    return Scaffold(
      appBar: isOwner
          ? CustomAppBar(title: "${widget.assistant.name}'s Dashboard")
          : null,
      body: Obx(() {
        final data = ctrl.analytics.value;
        final loading = ctrl.isLoading.value;
        //
        // if (loading && data == null) {
        //   return const Center(
        //     child: CircularProgressIndicator(color: AppColors.primary),
        //   );
        // }

        // Case 2: Not loading and still no data (e.g., no internet) → empty state with pull-to-refresh
        if (loading && data == null) {
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: ctrl.refreshAll,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: const Center(
                  child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                ),
              ),
            ),
          );
        }

        // Case 3: Data available → show content, with pull-to-refresh
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: ctrl.refreshAll,
          child: Stack(
            children: [
              SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    AssistantStatsSummary(
                      totalOrders: data!.totalOrders,
                      totalExpense: data.totalExpense,
                      theme: theme,
                    ),
                    spacer,
                    AssistantReportsChart(data: data, theme: theme),
                    const SizedBox(height: 12),
                    RecentOrdersList(
                      isOwner: false,
                      recentOrders: ctrl.recentOrders,
                      isLoadingRecent: ctrl.isLoadingRecent,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              // Non-blocking spinner overlay while refreshing
              if (loading)
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: const Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}
