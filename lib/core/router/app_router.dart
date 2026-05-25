import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/screens/add_user_screen.dart';
import '../../features/admin/presentation/screens/add_wallet_screen.dart';
import '../../features/admin/presentation/screens/admin_screen.dart';
import '../../features/auth/domain/services/role_permissions.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/bazar/domain/entities/bazar_entities.dart';
import '../../features/bazar/presentation/providers/bazar_providers.dart';
import '../../features/bazar/presentation/screens/add_item_screen.dart';
import '../../features/bazar/presentation/screens/bazar_detail_screen.dart';
import '../../features/bazar/presentation/screens/bazar_list_screen.dart';
import '../../features/bazar/presentation/screens/bazar_summary_screen.dart';
import '../../features/bazar/presentation/screens/new_bazar_screen.dart';
import '../../features/comments/presentation/screens/bazar_comments_screen.dart';
import '../../features/comments/presentation/screens/price_history_screen.dart';
import '../../features/money/presentation/screens/direct_expense_screen.dart';
import '../../features/money/presentation/screens/money_entry_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/reports/domain/entities/report_summary.dart';
import '../../features/reports/presentation/providers/report_providers.dart';
import '../../features/reports/presentation/screens/monthly_close_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/search/domain/entities/search_entities.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/settings/presentation/providers/settings_providers.dart';
import '../../features/settings/presentation/screens/more_screen.dart';
import '../../features/settings/presentation/screens/offline_queue_screen.dart';
import '../../features/settings/presentation/screens/profile_edit_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/wallet/domain/entities/wallet_summary.dart';
import '../../features/wallet/presentation/providers/wallet_providers.dart';
import '../../features/wallet/presentation/screens/assistant_ledger_screen.dart';
import '../../features/wallet/presentation/screens/balance_screen.dart';
import '../../features/wallet/presentation/screens/wallet_detail_screen.dart';
import '../../shared/models/app_enums.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/status_chip.dart';
import '../../shared/widgets/sync_badge.dart';
import '../sync/sync_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final currentUser = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: AppRoutes.home,
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == AppRoutes.login;
      final user = currentUser.valueOrNull;
      final isAuthenticated = user != null;

      if (!isAuthenticated && !isLoggingIn) {
        return AppRoutes.login;
      }

      if (isAuthenticated && isLoggingIn) {
        return AppRoutes.home;
      }

      if (user != null && !_canAccessRoute(state.matchedLocation, user.role)) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(
          location: state.uri.path,
          role: currentUser.valueOrNull?.role,
          child: child,
        ),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            builder: (context, state) => HomeDashboardScreen(
              onBazarTap: () => context.go(AppRoutes.bazarList),
              onNewBazarTap: () => context.push(AppRoutes.newBazar),
              onBalanceTap: () => context.go(AppRoutes.balance),
              onMoneyEntryTap: () => context.push(AppRoutes.moneyEntry),
              onDirectExpenseTap: () => context.push(AppRoutes.directExpense),
              onReportsTap: () => context.go(AppRoutes.reports),
            ),
          ),
          GoRoute(
            path: AppRoutes.bazarList,
            name: 'bazar-list',
            builder: (context, state) => BazarListScreen(
              onBazarTap: (id) => context.push(AppRoutes.bazarDetail(id)),
            ),
          ),
          GoRoute(
            path: AppRoutes.balance,
            name: 'balance',
            builder: (context, state) => BalanceScreen(
              onWalletTap: (id) => context.push(AppRoutes.walletDetail(id)),
              onMoneyEntryTap: () => context.push(AppRoutes.moneyEntry),
            ),
          ),
          GoRoute(
            path: AppRoutes.reports,
            name: 'reports',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: AppRoutes.more,
            name: 'more',
            builder: (context, state) => MoreScreen(
              user: currentUser.valueOrNull,
              onProfileEditTap: () => context.push(AppRoutes.profileEdit),
              onOfflineQueueTap: () => context.push(AppRoutes.offlineQueue),
              onMenuTap: (key) => _goFromMoreMenu(context, key),
              onLogoutTap: () async {
                await ref.read(loginControllerProvider.notifier).logout();
                if (context.mounted) {
                  context.go(AppRoutes.login);
                }
              },
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.newBazar,
        name: 'new-bazar',
        builder: (context, state) => NewBazarScreen(
          onBack: () => _popOrGo(context, AppRoutes.bazarList),
          onCreated: (bazarId) =>
              context.replace(AppRoutes.bazarDetail(bazarId)),
        ),
      ),
      GoRoute(
        path: AppRoutes.bazarDetailPath,
        name: 'bazar-detail',
        builder: (context, state) {
          final bazarId = state.pathParameters['bazarId']!;
          return BazarDetailScreen(
            bazarId: bazarId,
            onAddItemTap: () => context.push(AppRoutes.addItem(bazarId)),
            onCommentsTap: () => context.push(AppRoutes.bazarComments(bazarId)),
            onPriceHistoryTap: () =>
                context.push(AppRoutes.priceHistory(bazarId)),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.addItemPath,
        name: 'add-item',
        builder: (context, state) {
          final bazarId = state.pathParameters['bazarId']!;
          return AddItemScreen(
            bazarId: bazarId,
            onBack: () => _popOrGo(context, AppRoutes.bazarDetail(bazarId)),
            onDone: () => _popOrGo(context, AppRoutes.bazarDetail(bazarId)),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.directExpense,
        name: 'direct-expense',
        builder: (context, state) => DirectExpenseScreen(
          onBack: () => _popOrGo(context, AppRoutes.home),
          onSaved: () => _popOrGo(context, AppRoutes.home),
        ),
      ),
      GoRoute(
        path: AppRoutes.bazarSummaryPath,
        name: 'bazar-summary',
        builder: (context, state) =>
            BazarSummaryScreen(bazarId: state.pathParameters['bazarId']!),
      ),
      GoRoute(
        path: AppRoutes.moneyEntry,
        name: 'money-entry',
        builder: (context, state) => const MoneyEntryScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.walletDetailPath,
        name: 'wallet-detail',
        builder: (context, state) =>
            WalletDetailScreen(walletId: state.pathParameters['walletId']!),
      ),
      GoRoute(
        path: AppRoutes.monthlyClose,
        name: 'monthly-close',
        builder: (context, state) => const MonthlyCloseScreen(),
      ),
      GoRoute(
        path: AppRoutes.admin,
        name: 'admin',
        builder: (context, state) => AdminScreen(
          onAddUserTap: () => context.push(AppRoutes.addUser),
          onAddWalletTap: () => context.push(AppRoutes.addWallet),
          onEditWalletTap: (walletId) =>
              context.push(AppRoutes.editWallet(walletId)),
        ),
      ),
      GoRoute(
        path: AppRoutes.search,
        name: 'search',
        builder: (context, state) => SearchScreen(
          onResultTap: (result) => _openSearchResult(context, result),
        ),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => SettingsScreen(
          onBack: () => _popOrGo(context, AppRoutes.more),
          onOfflineQueueTap: () => context.push(AppRoutes.offlineQueue),
        ),
      ),
      GoRoute(
        path: AppRoutes.offlineQueue,
        name: 'offline-queue',
        builder: (context, state) => OfflineQueueScreen(
          onBack: () => _popOrGo(context, AppRoutes.settings),
        ),
      ),
      GoRoute(
        path: AppRoutes.profileEdit,
        name: 'profile-edit',
        builder: (context, state) =>
            ProfileEditScreen(onBack: () => _popOrGo(context, AppRoutes.more)),
      ),
      GoRoute(
        path: AppRoutes.addUser,
        name: 'add-user',
        builder: (context, state) => AddUserScreen(
          onUserCreated: () => _popOrGo(context, AppRoutes.admin),
          onCancel: () => _popOrGo(context, AppRoutes.admin),
        ),
      ),
      GoRoute(
        path: AppRoutes.addWallet,
        name: 'add-wallet',
        builder: (context, state) => AddWalletScreen(
          onWalletCreated: () => _popOrGo(context, AppRoutes.admin),
          onCancel: () => _popOrGo(context, AppRoutes.admin),
        ),
      ),
      GoRoute(
        path: AppRoutes.editWalletPath,
        name: 'edit-wallet',
        builder: (context, state) => AddWalletScreen(
          walletId: state.pathParameters['walletId']!,
          onWalletCreated: () => _popOrGo(context, AppRoutes.admin),
          onCancel: () => _popOrGo(context, AppRoutes.admin),
        ),
      ),
      GoRoute(
        path: AppRoutes.bazarCommentsPath,
        name: 'bazar-comments',
        builder: (context, state) {
          final bazarId = state.pathParameters['bazarId']!;
          return BazarCommentsScreen(
            onBack: () => _popOrGo(context, AppRoutes.bazarDetail(bazarId)),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.priceHistoryPath,
        name: 'price-history',
        builder: (context, state) {
          final bazarId = state.pathParameters['bazarId']!;
          return PriceHistoryScreen(
            onBack: () => _popOrGo(context, AppRoutes.bazarDetail(bazarId)),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.assistantLedgerPath,
        name: 'assistant-ledger',
        builder: (context, state) => AssistantLedgerScreen(
          walletId: state.pathParameters['walletId']!,
          assistantId: state.pathParameters['assistantId']!,
        ),
      ),
    ],
  );
});

class AppRoutes {
  const AppRoutes._();

  static const login = '/login';
  static const home = '/';
  static const bazarList = '/bazars';
  static const bazarDetailPath = '/bazars/:bazarId';
  static const newBazar = '/bazars/new';
  static const addItemPath = '/bazars/:bazarId/items/add';
  static const directExpense = '/money/direct-expense';
  static const bazarSummaryPath = '/bazars/:bazarId/summary';
  static const balance = '/balance';
  static const moneyEntry = '/money/entry';
  static const notifications = '/notifications';
  static const reports = '/reports';
  static const walletDetailPath = '/wallets/:walletId';
  static const monthlyClose = '/reports/monthly-close';
  static const admin = '/admin';
  static const search = '/search';
  static const settings = '/settings';
  static const offlineQueue = '/sync/offline-queue';
  static const more = '/more';
  static const profileEdit = '/profile/edit';
  static const addUser = '/admin/users/add';
  static const addWallet = '/admin/wallets/add';
  static const editWalletPath = '/admin/wallets/:walletId/edit';
  static const bazarCommentsPath = '/bazars/:bazarId/comments';
  static const priceHistoryPath = '/bazars/:bazarId/price-history';
  static const assistantLedgerPath =
      '/wallets/:walletId/assistant/:assistantId';

  static String bazarDetail(String bazarId) => '/bazars/$bazarId';
  static String addItem(String bazarId) => '/bazars/$bazarId/items/add';
  static String bazarSummary(String bazarId) => '/bazars/$bazarId/summary';
  static String walletDetail(String walletId) => '/wallets/$walletId';
  static String bazarComments(String bazarId) => '/bazars/$bazarId/comments';
  static String priceHistory(String bazarId) =>
      '/bazars/$bazarId/price-history';
  static String assistantLedger(String walletId, String assistantId) =>
      '/wallets/$walletId/assistant/$assistantId';
  static String editWallet(String walletId) => '/admin/wallets/$walletId/edit';
}

class MainShell extends StatelessWidget {
  const MainShell({
    required this.location,
    required this.child,
    this.role,
    super.key,
  });

  final String location;
  final Widget child;
  final UserRole? role;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (location != AppRoutes.home) {
          context.go(AppRoutes.home);
          return;
        }
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('App বন্ধ করবেন?'),
            content: const Text('আরেকবার confirm করুন।'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('না'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('হ্যাঁ'),
              ),
            ],
          ),
        );
        if (shouldExit == true && context.mounted) {
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: child,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex(location),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.text3,
          onTap: (index) => context.go(_destinationsForRole(role)[index].path),
          items: [
            for (final destination in _destinationsForRole(role))
              BottomNavigationBarItem(
                icon: Semantics(
                  label: destination.label,
                  button: true,
                  child: Icon(destination.icon),
                ),
                activeIcon: Semantics(
                  label: destination.label,
                  button: true,
                  selected: true,
                  child: Icon(destination.selectedIcon),
                ),
                label: destination.label,
                tooltip: destination.label,
              ),
          ],
        ),
      ),
    );
  }

  int _selectedIndex(String location) {
    final destinations = _destinationsForRole(role);
    final index = destinations.indexWhere((destination) {
      if (destination.path == AppRoutes.home) {
        return location == AppRoutes.home;
      }
      return location == destination.path ||
          location.startsWith('${destination.path}/');
    });
    return index < 0 ? 0 : index;
  }
}

class _ShellDestination {
  const _ShellDestination({
    required this.path,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const _homeDestination = _ShellDestination(
  path: AppRoutes.home,
  label: 'হোম',
  icon: Icons.home_outlined,
  selectedIcon: Icons.home,
);

const _bazarDestination = _ShellDestination(
  path: AppRoutes.bazarList,
  label: 'বাজার',
  icon: Icons.shopping_basket_outlined,
  selectedIcon: Icons.shopping_basket,
);

const _balanceDestination = _ShellDestination(
  path: AppRoutes.balance,
  label: 'হিসাব',
  icon: Icons.account_balance_wallet_outlined,
  selectedIcon: Icons.account_balance_wallet,
);

const _reportsDestination = _ShellDestination(
  path: AppRoutes.reports,
  label: 'রিপোর্ট',
  icon: Icons.bar_chart_outlined,
  selectedIcon: Icons.bar_chart,
);

const _moreDestination = _ShellDestination(
  path: AppRoutes.more,
  label: 'আরো',
  icon: Icons.more_horiz,
  selectedIcon: Icons.more,
);

List<_ShellDestination> _destinationsForRole(UserRole? role) {
  return [
    _homeDestination,
    _bazarDestination,
    _balanceDestination,
    if (role == null || RolePermissions.canSeeReportsTab(role))
      _reportsDestination,
    _moreDestination,
  ];
}

bool _canAccessRoute(String route, UserRole role) {
  if (route == AppRoutes.admin ||
      route == AppRoutes.addUser ||
      route == AppRoutes.addWallet ||
      route == AppRoutes.editWalletPath) {
    return RolePermissions.canAccessAdmin(role);
  }
  if (route == AppRoutes.reports || route == AppRoutes.monthlyClose) {
    return RolePermissions.canAccessReports(role);
  }
  if (route == AppRoutes.moneyEntry) {
    return RolePermissions.canRecordMoneyEntry(role);
  }
  if (route == AppRoutes.directExpense) {
    return RolePermissions.canAddDirectExpense(role);
  }
  return true;
}

String _goFromMoreMenu(BuildContext context, String key) {
  final destination = switch (key) {
    'notifications' => AppRoutes.notifications,
    'reports' => AppRoutes.reports,
    'walletDetail' => AppRoutes.balance,
    'monthlyClose' => AppRoutes.monthlyClose,
    'search' => AppRoutes.search,
    'admin' => AppRoutes.admin,
    'settings' => AppRoutes.settings,
    _ => AppRoutes.more,
  };
  if (_isTabRoute(destination)) {
    context.go(destination);
  } else {
    context.push(destination);
  }
  return destination;
}

bool _isTabRoute(String route) {
  return route == AppRoutes.home ||
      route == AppRoutes.bazarList ||
      route == AppRoutes.balance ||
      route == AppRoutes.reports ||
      route == AppRoutes.more;
}

void _popOrGo(BuildContext context, String fallback) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(fallback);
  }
}

void _openSearchResult(BuildContext context, SearchResultItem result) {
  final route = routeForSearchResult(result);
  if (_isTabRoute(route)) {
    context.go(route);
  } else {
    context.push(route);
  }
}

String routeForSearchResult(SearchResultItem result) {
  return switch (result.type) {
    SearchResultType.bazar =>
      result.bazarId != null
          ? AppRoutes.bazarDetail(result.bazarId!)
          : result.entityId != null
          ? AppRoutes.bazarDetail(result.entityId!)
          : AppRoutes.bazarList,
    SearchResultType.item =>
      result.bazarId != null
          ? AppRoutes.bazarDetail(result.bazarId!)
          : result.parentId != null
          ? AppRoutes.bazarDetail(result.parentId!)
          : AppRoutes.bazarList,
    SearchResultType.money =>
      result.walletId != null
          ? AppRoutes.walletDetail(result.walletId!)
          : AppRoutes.balance,
  };
}

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({
    required this.onBazarTap,
    required this.onNewBazarTap,
    required this.onBalanceTap,
    required this.onMoneyEntryTap,
    required this.onDirectExpenseTap,
    required this.onReportsTap,
    super.key,
  });

  final VoidCallback onBazarTap;
  final VoidCallback onNewBazarTap;
  final VoidCallback onBalanceTap;
  final VoidCallback onMoneyEntryTap;
  final VoidCallback onDirectExpenseTap;
  final VoidCallback onReportsTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final syncStatus = ref.watch(syncStatusProvider);
    final offlineQueue = ref.watch(offlineQueueEntriesProvider);
    final bazars = ref.watch(bazarsProvider);
    final walletSummaries = ref.watch(walletSummariesProvider);
    final report = ref.watch(monthlyReportProvider(currentPeriodMonth()));

    return Scaffold(
      backgroundColor: AppColors.surface2,
      appBar: BazarAppBar(
        title: 'সহজ বাজার খাতা',
        subtitle: currentUser == null
            ? 'Dashboard'
            : '${currentUser.name} — ${_roleLabel(currentUser.role)}',
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _HomeHeroCard(
            userName: currentUser?.name,
            syncStatus: syncStatus,
            pendingCount: offlineQueue.valueOrNull?.length,
          ),
          const SizedBox(height: 14),
          _WalletOverviewCard(
            summaries: walletSummaries,
            report: report,
            onTap: onBalanceTap,
          ),
          SectionHeader(
            title: 'সাম্প্রতিক বাজার',
            action: 'সব দেখুন',
            onAction: onBazarTap,
          ),
          _RecentBazarList(bazars: bazars, onBazarTap: onBazarTap),
          SectionHeader(title: 'দ্রুত কাজ'),
          _HomeActionGrid(
            actions: _homeActionsForRole(
              role: currentUser?.role,
              onBazarTap: onBazarTap,
              onNewBazarTap: onNewBazarTap,
              onBalanceTap: onBalanceTap,
              onMoneyEntryTap: onMoneyEntryTap,
              onDirectExpenseTap: onDirectExpenseTap,
              onReportsTap: onReportsTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeHeroCard extends StatelessWidget {
  const _HomeHeroCard({
    required this.syncStatus,
    required this.pendingCount,
    this.userName,
  });

  final String? userName;
  final SyncStatus syncStatus;
  final int? pendingCount;

  @override
  Widget build(BuildContext context) {
    final queueLabel = pendingCount == null
        ? 'Offline কাজ চেক হচ্ছে'
        : pendingCount == 0
        ? 'সব কাজ synced'
        : '${_toBanglaDigits(pendingCount!)}টা কাজ pending';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(21, 101, 192, 0.22),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'স্বাগতম, ${userName ?? 'টিম'}',
            style: AppTextStyles.appBarTitle,
          ),
          const SizedBox(height: 8),
          Text(
            'আজকের বাজার, টাকা আর Sync status একসাথে দেখুন।',
            style: AppTextStyles.body.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SyncBadge(status: syncStatus),
              StatusChip(
                label: queueLabel,
                backgroundColor: Colors.white.withValues(alpha: 0.16),
                foregroundColor: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WalletOverviewCard extends StatelessWidget {
  const _WalletOverviewCard({
    required this.summaries,
    required this.report,
    required this.onTap,
  });

  final AsyncValue<List<WalletSummary>> summaries;
  final AsyncValue<ReportSummary> report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final walletSummaries = summaries.valueOrNull ?? const <WalletSummary>[];
    final walletCount = walletSummaries.length;
    final estimatedTotal = walletSummaries.fold<double>(
      0,
      (total, summary) => total + summary.balance.estimatedBalance,
    );
    final inProgressTotal = walletSummaries.fold<double>(
      0,
      (total, summary) => total + summary.balance.inProgressAmount,
    );
    final monthlySpent = report.valueOrNull?.totalSpent;

    return Semantics(
      button: true,
      label: 'Balance Summary',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Balance Summary',
                      style: AppTextStyles.screenTitle,
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.text3,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _DashboardMetric(
                      label: 'ওয়ালেট',
                      value: _toBanglaDigits(walletCount),
                    ),
                  ),
                  Expanded(
                    child: _DashboardMetric(
                      label: 'Estimated Balance',
                      value: _money(estimatedTotal),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _DashboardMetric(
                      label: 'চলমান খরচ',
                      value: _money(inProgressTotal),
                    ),
                  ),
                  Expanded(
                    child: _DashboardMetric(
                      label: 'মাসিক খরচ',
                      value: monthlySpent == null
                          ? 'Loading...'
                          : _money(monthlySpent),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardMetric extends StatelessWidget {
  const _DashboardMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 3),
        Text(value, style: AppTextStyles.bodyStrong),
      ],
    );
  }
}

class _RecentBazarList extends StatelessWidget {
  const _RecentBazarList({required this.bazars, required this.onBazarTap});

  final AsyncValue<List<Bazar>> bazars;
  final VoidCallback onBazarTap;

  @override
  Widget build(BuildContext context) {
    return bazars.when(
      data: (items) {
        final recent = items.take(3).toList(growable: false);
        if (recent.isEmpty) {
          return _EmptyDashboardCard(
            title: 'এখনও বাজার নেই',
            subtitle: 'নতুন বাজার তৈরি করলে এখানে দেখা যাবে।',
            actionLabel: 'নতুন বাজার',
            onTap: onBazarTap,
          );
        }
        return Column(
          children: [
            for (final bazar in recent) ...[
              _RecentBazarCard(bazar: bazar, onTap: onBazarTap),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
      loading: () => const _LoadingDashboardCard(label: 'বাজার লোড হচ্ছে'),
      error: (error, stackTrace) => _EmptyDashboardCard(
        title: 'বাজার দেখা যাচ্ছে না',
        subtitle: 'তালিকা খুলে আবার চেষ্টা করুন।',
        actionLabel: 'বাজার তালিকা',
        onTap: onBazarTap,
      ),
    );
  }
}

class _RecentBazarCard extends StatelessWidget {
  const _RecentBazarCard({required this.bazar, required this.onTap});

  final Bazar bazar;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: bazar.title ?? 'বাজার',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.shopping_basket,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bazar.title ?? 'নামহীন বাজার',
                      style: AppTextStyles.bodyStrong,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_toBanglaDigits(bazar.itemCount)}টি আইটেম • ${_money(bazar.spent)}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              StatusChip(
                label: _bazarStatusLabel(bazar.status),
                backgroundColor: _bazarStatusBackground(bazar.status),
                foregroundColor: _bazarStatusForeground(bazar.status),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyDashboardCard extends StatelessWidget {
  const _EmptyDashboardCard({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.bodyStrong),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTextStyles.bodySmall),
          const SizedBox(height: 12),
          PrimaryButton(
            label: actionLabel,
            onPressed: onTap,
            margin: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

class _LoadingDashboardCard extends StatelessWidget {
  const _LoadingDashboardCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(label, style: AppTextStyles.body),
        ],
      ),
    );
  }
}

List<_HomeAction> _homeActionsForRole({
  required UserRole? role,
  required VoidCallback onBazarTap,
  required VoidCallback onNewBazarTap,
  required VoidCallback onBalanceTap,
  required VoidCallback onMoneyEntryTap,
  required VoidCallback onDirectExpenseTap,
  required VoidCallback onReportsTap,
}) {
  return [
    _HomeAction('বাজার তালিকা', Icons.shopping_basket, onBazarTap),
    _HomeAction('নতুন বাজার', Icons.add_shopping_cart, onNewBazarTap),
    _HomeAction('হিসাব', Icons.account_balance_wallet, onBalanceTap),
    if (role == null || RolePermissions.canRecordMoneyEntry(role))
      _HomeAction('টাকা এন্ট্রি', Icons.payments, onMoneyEntryTap),
    if (role == null || RolePermissions.canAddDirectExpense(role))
      _HomeAction('সরাসরি খরচ', Icons.receipt_long, onDirectExpenseTap),
    if (role == null || RolePermissions.canAccessReports(role))
      _HomeAction('রিপোর্ট', Icons.bar_chart, onReportsTap),
  ];
}

class _HomeAction {
  const _HomeAction(this.label, this.icon, this.onTap);

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class _HomeActionGrid extends StatelessWidget {
  const _HomeActionGrid({required this.actions});

  final List<_HomeAction> actions;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.55,
      children: [
        for (final action in actions)
          Semantics(
            button: true,
            label: action.label,
            child: InkWell(
              onTap: action.onTap,
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(action.icon, color: AppColors.primary, size: 24),
                    Text(action.label, style: AppTextStyles.bodyStrong),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

String _roleLabel(UserRole role) {
  return switch (role) {
    UserRole.owner => 'মালিক',
    UserRole.admin => 'অ্যাডমিন',
    UserRole.assistant => 'সহকারী',
  };
}

String _bazarStatusLabel(BazarStatus status) {
  return switch (status) {
    BazarStatus.draft => 'খসড়া',
    BazarStatus.open => 'চলমান',
    BazarStatus.closed => 'শেষ',
    BazarStatus.cancelled => 'বাতিল',
  };
}

Color _bazarStatusBackground(BazarStatus status) {
  return switch (status) {
    BazarStatus.draft => AppColors.warningLight,
    BazarStatus.open => AppColors.primaryLight,
    BazarStatus.closed => AppColors.positiveLight,
    BazarStatus.cancelled => AppColors.negativeLight,
  };
}

Color _bazarStatusForeground(BazarStatus status) {
  return switch (status) {
    BazarStatus.draft => AppColors.warningDark,
    BazarStatus.open => AppColors.primary,
    BazarStatus.closed => AppColors.positiveDark,
    BazarStatus.cancelled => AppColors.negativeDark,
  };
}

String _money(double value) {
  final sign = value < 0 ? '-' : '';
  final amount = value.abs();
  final text = amount == amount.roundToDouble()
      ? amount.toInt().toString()
      : amount.toStringAsFixed(2);
  return '$sign৳ ${_toBanglaDigits(text)}';
}

String _toBanglaDigits(Object value) {
  return value
      .toString()
      .replaceAll('0', '০')
      .replaceAll('1', '১')
      .replaceAll('2', '২')
      .replaceAll('3', '৩')
      .replaceAll('4', '৪')
      .replaceAll('5', '৫')
      .replaceAll('6', '৬')
      .replaceAll('7', '৭')
      .replaceAll('8', '৮')
      .replaceAll('9', '৯');
}
