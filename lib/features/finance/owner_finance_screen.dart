import 'package:flutter/material.dart';
import 'package:BazarTrack/base/custom_button.dart';
import 'package:BazarTrack/features/finance/components/owners_finance_tile.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../util/input_decoration.dart';
import '../../../util/colors.dart';
import '../../base/custom_divider.dart';
import '../../base/empty_state.dart';
import '../../util/dimensions.dart';
import 'components/assistant_summary_card.dart';
import 'controller/finance_controller.dart';

class OwnerFinancePage extends StatefulWidget {
  const OwnerFinancePage({super.key});

  @override
  State<OwnerFinancePage> createState() => _OwnerFinancePageState();
}

class _OwnerFinancePageState extends State<OwnerFinancePage> {
  late final FinanceController ctrl;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    ctrl = Get.find<FinanceController>();

    _scrollController = ScrollController()..addListener(_onScroll);

    // Initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        ctrl.loadAssistants();
        ctrl.clearFilters();
      } catch (e) {
        debugPrint('OwnerFinancePage init error: $e');
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
    if (!_scrollController.hasClients) return;
    final threshold = 200.0;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;

    if (current >= maxScroll - threshold &&
        !ctrl.isLoadingMore.value &&
        ctrl.hasMore.value) {
      ctrl.loadMorePayments();
    }
  }

  Future<void> _onRefresh() async {
    try {
      await ctrl.loadAssistants();
      ctrl.clearFilters();

    } catch (e) {
      Get.snackbar(
        'Unable to refresh',
        'Check your internet connection and try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
      debugPrint('Refresh failed: $e');
    }
  }

  Future<void> _showFilterDialog(BuildContext context, FinanceController ctrl) async {
    final df = DateFormat('yyyy-MM-dd');
    int? selectedUser = ctrl.filterUserId.value;
    String? selectedType = ctrl.filterType.value;
    DateTime? fromDate = ctrl.filterFrom.value;
    DateTime? toDate = ctrl.filterTo.value;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const Icon(Icons.filter_list_outlined),
                  const Text('Filter Payments'),
                ],
              ),
              CustomDivider.defaultDivider,
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Assistant
              DropdownButtonFormField<int?>(
                initialValue: selectedUser,
                decoration: AppInputDecorations.generalInputDecoration(
                  label: 'Assistant',
                  prefixIcon: Icons.person_outline,
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All')),
                  ...ctrl.assistants.map(
                        (a) => DropdownMenuItem(
                      value: a.id,
                      child: Text(a.name, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => selectedUser = v),
              ),

              const SizedBox(height: 12),

              const SizedBox(height: 12),

              // Date range
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      decoration: AppInputDecorations.generalInputDecoration(
                        label: 'From',
                        prefixIcon: Icons.calendar_today,
                      ),
                      controller: TextEditingController(
                        text: fromDate != null ? df.format(fromDate!) : 'Any',
                      ),
                      onTap: () async {
                        final d = await showDatePicker(
                          context: ctx,
                          initialDate: fromDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (d != null) setState(() => fromDate = d);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      decoration: AppInputDecorations.generalInputDecoration(
                        label: 'To',
                        prefixIcon: Icons.calendar_today,
                      ),
                      controller: TextEditingController(
                        text: toDate != null ? df.format(toDate!) : 'Any',
                      ),
                      onTap: () async {
                        final d = await showDatePicker(
                          context: ctx,
                          initialDate: toDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (d != null) setState(() => toDate = d);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            CustomButton(
              btnColor: Colors.redAccent,
              height: MediaQuery.of(context).size.height * .04,
              width: MediaQuery.of(context).size.width * .25,
              onPressed: () => Navigator.pop(ctx),
              buttonText: 'Cancel',
            ),
            CustomButton(
              btnColor: AppColors.primary,
              height: MediaQuery.of(context).size.height * .04,
              width: MediaQuery.of(context).size.width * .25,
              onPressed: () {
                ctrl.setFilters(
                  userId: selectedUser,
                  type: selectedType,
                  from: fromDate,
                  to: toDate,
                );
                Navigator.pop(ctx);
              },
              buttonText: 'Apply',
            ),
          ],
          actionsAlignment: MainAxisAlignment.spaceAround,
        ),
      ),
    );
  }

  Future<void> _showCreditDialog(BuildContext context, FinanceController ctrl) async {
    final amtCtrl = TextEditingController();
    int selectedId = ctrl.assistants.isNotEmpty ? ctrl.assistants.first.id : 0;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimensions.inputFieldBorderRadius),
          ),
          title: Row(
            children: [
              const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Credit Assistant',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: selectedId,
                decoration: AppInputDecorations.generalInputDecoration(
                  label: 'Select Assistant',
                  prefixIcon: Icons.person,
                ),
                items: ctrl.assistants.map((a) => DropdownMenuItem(
                  value: a.id,
                  child: Text(a.name),
                )).toList(),
                onChanged: (v) => setState(() => selectedId = v!),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: amtCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: AppInputDecorations.generalInputDecoration(
                  label: 'Amount',
                  hint: 'Enter amount',
                  prefixText: '৳ ',
                ),
              ),
            ],
          ),
          actions: [
            CustomButton(
              btnColor: Colors.redAccent,
              shrink: true,
              onPressed: () => Navigator.pop(context),
              buttonText: 'Cancel',
            ),
            CustomButton(
              btnColor: AppColors.primary,
              shrink: true,
              onPressed: () {
                final amt = double.tryParse(amtCtrl.text.trim()) ?? 0.0;
                if (amt > 0) {
                  ctrl.addCreditForAssistant(selectedId, amt).then((_) => Navigator.pop(context));
                }
              },
              buttonText: 'Save',
            ),
          ],
          actionsAlignment: MainAxisAlignment.spaceAround,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Keep RefreshIndicator visible always. If everything is still loading and we have no items,
      // render a scrollable spinner so user can pull-to-refresh. Otherwise render the full list
      // and display a subtle loading overlay when initial reloads happen.
      final isInitial = ctrl.isInitialLoading.value || ctrl.isLoadingAssistants.value;
      final hasPayments = ctrl.payments.isNotEmpty;

      return Scaffold(
        appBar: AppBar(
          title: const Text('Assistant Wallets & Transactions'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh',
              onPressed: _onRefresh,
            ),
          ],
        ),
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _onRefresh,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Assistants Summary
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: AssistantSummaryCard(
                    assistants: ctrl.assistants,
                  ),
                ),
              ),

              // Transactions Header (Filter / Clear)
              SliverPersistentHeader(
                pinned: true,
                delegate: _HeaderDelegate(
                  height: 56,
                  child: _TransactionsHeader(
                    hasFilter: ctrl.hasActiveFilters,
                    onFilter: () => _showFilterDialog(context, ctrl),
                    onClear: ctrl.clearFilters,
                  ),
                ),
              ),

              // If initial & no items -> show an in-scroll spinner (so pull-to-refresh works)
              if (isInitial && !hasPayments)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 12),
                        Text('Loading transactions...'),
                      ],
                    ),
                  ),
                )

              // No items (but not initial) -> empty state (still scrollable)
              else if (!hasPayments)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.receipt_long,
                    message: 'No transactions yet.',
                  ),
                )

              // Items present -> list
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (_, i) {
                      final finance = ctrl.payments[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        child: OwnersFinanceTile(finance: finance),
                      );
                    },
                    childCount: ctrl.payments.length,
                  ),
                ),

              // Bottom loader for paging
              if (ctrl.isLoadingMore.value)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  ),
                ),

              // provide bottom spacing so last item is scrollable above FAB
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'owner_add',
          icon: const Icon(Icons.account_balance_wallet),
          label: const Text('Credit'),
          backgroundColor: AppColors.primary,
          onPressed: () => _showCreditDialog(context, ctrl),
        ),
      );
    });
  }
}

/// Delegate for a pinned header.
class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _HeaderDelegate({required this.child, this.height = 56});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      elevation: overlapsContent ? 4 : 0,
      child: SizedBox.expand(child: child),
    );
  }

  @override
  double get maxExtent => height;
  @override
  double get minExtent => height;
  @override
  bool shouldRebuild(covariant _HeaderDelegate old) =>
      child != old.child || height != old.height;
}

/// Header row with title, filter & clear icons.
class _TransactionsHeader extends StatelessWidget {
  final bool hasFilter;
  final VoidCallback onFilter;
  final VoidCallback onClear;

  const _TransactionsHeader({
    required this.hasFilter,
    required this.onFilter,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final ts = Theme.of(context).textTheme;
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Text('All Payments', style: ts.titleLarge),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: onFilter,
            tooltip: 'Filter',
          ),
          if (hasFilter)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: onClear,
              tooltip: 'Clear Filters',
            ),
        ],
      ),
    );
  }
}
