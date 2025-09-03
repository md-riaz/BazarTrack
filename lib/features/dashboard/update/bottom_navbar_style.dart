import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_boilerplate/base/custom_app_bar.dart';
import 'package:flutter_boilerplate/features/auth/service/auth_service.dart';
import 'package:flutter_boilerplate/features/dashboard/assistant_dashboard_details_screen.dart';
import 'package:flutter_boilerplate/features/finance/assistant_finance_screen.dart';
import 'package:flutter_boilerplate/features/finance/model/assistant.dart';
import 'package:flutter_boilerplate/features/history/history_center_page.dart';
import 'package:flutter_boilerplate/features/orders/assistant_order_list_screen.dart';
import 'package:flutter_boilerplate/features/profile/profile_screen.dart';
import 'package:get/get.dart';

class AssistantDashboard extends StatefulWidget {
  const AssistantDashboard({super.key});

  @override
  State<AssistantDashboard> createState() => _AssistantDashboardState();
}

class _AssistantDashboardState extends State<AssistantDashboard> {
  int _currentIndex = 0;
  late final PageController _pageController;
  late final List<Widget> _screens;

  final List<String> _titles = [
    'assistants_dashboard',
    'view_orders',
    'finance',
    'history',
  ];

  final PageStorageBucket _bucket = PageStorageBucket();

  // Icon is a Widget so we can use Text for taka symbol
  final List<_NavItem> _navItems = [
    const _NavItem(icon: Icon(Icons.space_dashboard_rounded), label: 'Dashboard'),
    const _NavItem(icon: Icon(Icons.list_alt_rounded), label: 'Orders'),
    const _NavItem(icon: Text('৳', textAlign: TextAlign.center), label: 'Finance'),
    const _NavItem(icon: Icon(Icons.history), label: 'History'),
  ];

  @override
  void initState() {
    super.initState();
    final auth = Get.find<AuthService>();
    final uid = int.parse(auth.currentUser!.id);
    final Assistant assistant = Assistant(id: uid, name: auth.currentUser!.name);

    _screens = [
      AssistantDashboardDetails(assistant: assistant),
      const AssistantOrderListScreen(),
      AssistantFinancePage(assistant: assistant),
      const HistoryCenterPage(),
    ];

    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (index == _currentIndex) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: CustomAppBar(
        // using title string (matches original API)
        title: _titles[_currentIndex].tr,
        actions: [
          IconButton(
            tooltip: 'profile'.tr,
            icon: const Icon(CupertinoIcons.profile_circled),
            onPressed: () {
              Get.to(
                    () => ProfileScreen(),
                transition: Transition.cupertino,
                duration: const Duration(milliseconds: 400),
              );
            },
          ),
        ],
      ),

      body: SafeArea(
        child: PageStorage(
          bucket: _bucket,
          child: PageView(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (idx) => setState(() => _currentIndex = idx),
            children: _screens
                .asMap()
                .map(
                  (i, w) => MapEntry(
                i,
                KeyedSubtree(key: PageStorageKey('tab_$i'), child: w),
              ),
            )
                .values
                .toList(),
          ),
        ),
      ),

      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Material(
            color: colorScheme.surface,
            child: SizedBox(
              height: 68,
              child: Row(
                children: _navItems.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  final selected = idx == _currentIndex;

                  return Expanded(
                    child: InkWell(
                      onTap: () => _onTabSelected(idx),
                      splashColor: theme.primaryColor.withValues(alpha: 0.12),
                      highlightColor: Colors.transparent,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected ? theme.primaryColor.withValues(alpha: 0.10) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // icon (or text icon like taka) with scale animation
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 1.0, end: selected ? 1.12 : 1.0),
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOut,
                              builder: (context, scale, child) {
                                return Transform.scale(scale: scale, child: child);
                              },
                              child: IconTheme(
                                data: IconThemeData(
                                  color: selected ? theme.primaryColor : Colors.grey[600],
                                  size: selected ? 26 : 22,
                                ),
                                child: DefaultTextStyle(
                                  style: TextStyle(
                                    color: selected ? theme.primaryColor : Colors.grey[600],
                                    fontSize: selected ? 22 : 20,
                                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                                  ),
                                  child: item.icon,
                                ),
                              ),
                            ),

                            const SizedBox(height: 4),

                            // label below icon, constrained to avoid overflow
                            Flexible(
                              fit: FlexFit.loose,
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: selected
                                    ? theme.textTheme.bodySmall!.copyWith(color: theme.primaryColor, fontWeight: FontWeight.w700)
                                    : theme.textTheme.bodySmall!.copyWith(color: Colors.grey[600]),
                                child: Text(
                                  item.label.tr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// nav item holds an icon widget (so text/icons both supported)
class _NavItem {
  final Widget icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
