import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/screens/add_user_screen.dart';
import '../../features/admin/presentation/screens/add_wallet_screen.dart';
import '../../features/admin/presentation/screens/admin_screen.dart';
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
      final isAuthenticated = currentUser.maybeWhen(
        data: (user) => user != null,
        orElse: () => false,
      );

      if (!isAuthenticated && !isLoggingIn) {
        return AppRoutes.login;
      }

      if (isAuthenticated && isLoggingIn) {
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
        builder: (context, state, child) =>
            MainShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            builder: (context, state) => HomeDashboardScreen(
              onBazarTap: () => context.go(AppRoutes.bazarList),
              onNewBazarTap: () => context.go(AppRoutes.newBazar),
              onBalanceTap: () => context.go(AppRoutes.balance),
              onMoneyEntryTap: () => context.go(AppRoutes.moneyEntry),
              onDirectExpenseTap: () => context.go(AppRoutes.directExpense),
              onReportsTap: () => context.go(AppRoutes.reports),
              onMoreTap: () => context.go(AppRoutes.more),
            ),
          ),
          GoRoute(
            path: AppRoutes.bazarList,
            name: 'bazar-list',
            builder: (context, state) => BazarListScreen(
              onBazarTap: (id) => context.go(AppRoutes.bazarDetail(id)),
            ),
          ),
          GoRoute(
            path: AppRoutes.balance,
            name: 'balance',
            builder: (context, state) => BalanceScreen(
              onWalletTap: (id) => context.go(AppRoutes.walletDetail(id)),
              onMoneyEntryTap: () => context.go(AppRoutes.moneyEntry),
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
              onProfileEditTap: () => context.go(AppRoutes.profileEdit),
              onOfflineQueueTap: () => context.go(AppRoutes.offlineQueue),
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
        path: AppRoutes.bazarDetailPath,
        name: 'bazar-detail',
        builder: (context, state) {
          final bazarId = state.pathParameters['bazarId']!;
          return BazarDetailScreen(
            bazarId: bazarId,
            onAddItemTap: () => context.go(AppRoutes.addItem(bazarId)),
            onCommentsTap: () => context.go(AppRoutes.bazarComments(bazarId)),
            onPriceHistoryTap: () =>
                context.go(AppRoutes.priceHistory(bazarId)),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.newBazar,
        name: 'new-bazar',
        builder: (context, state) => NewBazarScreen(
          onBack: () => context.go(AppRoutes.bazarList),
          onCreated: (bazarId) => context.go(AppRoutes.bazarDetail(bazarId)),
        ),
      ),
      GoRoute(
        path: AppRoutes.addItemPath,
        name: 'add-item',
        builder: (context, state) {
          final bazarId = state.pathParameters['bazarId']!;
          return AddItemScreen(
            bazarId: bazarId,
            onBack: () => context.go(AppRoutes.bazarDetail(bazarId)),
            onDone: () => context.go(AppRoutes.bazarDetail(bazarId)),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.directExpense,
        name: 'direct-expense',
        builder: (context, state) => DirectExpenseScreen(
          onBack: () => context.go(AppRoutes.home),
          onSaved: () => context.go(AppRoutes.home),
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
          onAddUserTap: () => context.go(AppRoutes.addUser),
          onAddWalletTap: () => context.go(AppRoutes.addWallet),
        ),
      ),
      GoRoute(
        path: AppRoutes.search,
        name: 'search',
        builder: (context, state) => SearchScreen(
          onResultTap: (result) => context.go(routeForSearchResult(result)),
        ),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => SettingsScreen(
          onBack: () => context.go(AppRoutes.more),
          onOfflineQueueTap: () => context.go(AppRoutes.offlineQueue),
        ),
      ),
      GoRoute(
        path: AppRoutes.offlineQueue,
        name: 'offline-queue',
        builder: (context, state) =>
            OfflineQueueScreen(onBack: () => context.go(AppRoutes.settings)),
      ),
      GoRoute(
        path: AppRoutes.profileEdit,
        name: 'profile-edit',
        builder: (context, state) =>
            ProfileEditScreen(onBack: () => context.go(AppRoutes.more)),
      ),
      GoRoute(
        path: AppRoutes.addUser,
        name: 'add-user',
        builder: (context, state) => AddUserScreen(
          onUserCreated: () => context.go(AppRoutes.admin),
          onCancel: () => context.go(AppRoutes.admin),
        ),
      ),
      GoRoute(
        path: AppRoutes.addWallet,
        name: 'add-wallet',
        builder: (context, state) => AddWalletScreen(
          onWalletCreated: () => context.go(AppRoutes.admin),
          onCancel: () => context.go(AppRoutes.admin),
        ),
      ),
      GoRoute(
        path: AppRoutes.bazarCommentsPath,
        name: 'bazar-comments',
        builder: (context, state) {
          final bazarId = state.pathParameters['bazarId']!;
          return BazarCommentsScreen(
            onBack: () => context.go(AppRoutes.bazarDetail(bazarId)),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.priceHistoryPath,
        name: 'price-history',
        builder: (context, state) {
          final bazarId = state.pathParameters['bazarId']!;
          return PriceHistoryScreen(
            onBack: () => context.go(AppRoutes.bazarDetail(bazarId)),
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
}

class MainShell extends StatelessWidget {
  const MainShell({required this.location, required this.child, super.key});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex(location),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.text3,
        onTap: (index) => context.go(_destinations[index].path),
        items: [
          for (final destination in _destinations)
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
    );
  }

  int _selectedIndex(String location) {
    final index = _destinations.indexWhere((destination) {
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

const _destinations = <_ShellDestination>[
  _ShellDestination(
    path: AppRoutes.home,
    label: 'হোম',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
  ),
  _ShellDestination(
    path: AppRoutes.bazarList,
    label: 'বাজার',
    icon: Icons.shopping_basket_outlined,
    selectedIcon: Icons.shopping_basket,
  ),
  _ShellDestination(
    path: AppRoutes.balance,
    label: 'হিসাব',
    icon: Icons.account_balance_wallet_outlined,
    selectedIcon: Icons.account_balance_wallet,
  ),
  _ShellDestination(
    path: AppRoutes.reports,
    label: 'রিপোর্ট',
    icon: Icons.bar_chart_outlined,
    selectedIcon: Icons.bar_chart,
  ),
  _ShellDestination(
    path: AppRoutes.more,
    label: 'আরো',
    icon: Icons.more_horiz,
    selectedIcon: Icons.more,
  ),
];

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
  context.go(destination);
  return destination;
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
    required this.onMoreTap,
    super.key,
  });

  final VoidCallback onBazarTap;
  final VoidCallback onNewBazarTap;
  final VoidCallback onBalanceTap;
  final VoidCallback onMoneyEntryTap;
  final VoidCallback onDirectExpenseTap;
  final VoidCallback onReportsTap;
  final VoidCallback onMoreTap;

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
            ? 'ড্যাশবোর্ড'
            : '${currentUser.name} — ${_roleLabel(currentUser.role)}',
        actions: [
          IconButton(
            tooltip: 'আরো',
            onPressed: onMoreTap,
            icon: const Icon(Icons.menu, color: AppColors.surface),
          ),
        ],
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
            actions: [
              _HomeAction('বাজার তালিকা', Icons.shopping_basket, onBazarTap),
              _HomeAction('নতুন বাজার', Icons.add_shopping_cart, onNewBazarTap),
              _HomeAction('হিসাব', Icons.account_balance_wallet, onBalanceTap),
              _HomeAction('টাকা এন্ট্রি', Icons.payments, onMoneyEntryTap),
              _HomeAction('সরাসরি খরচ', Icons.receipt_long, onDirectExpenseTap),
              _HomeAction('রিপোর্ট', Icons.bar_chart, onReportsTap),
            ],
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'আরো মেনু খুলুন',
            icon: const Icon(Icons.more_horiz),
            onPressed: onMoreTap,
            margin: EdgeInsets.zero,
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
        ? 'অফলাইন কাজ দেখা হচ্ছে'
        : pendingCount == 0
        ? 'সব কাজ সিঙ্ক হয়েছে'
        : '${_toBanglaDigits(pendingCount!)}টি কাজ অপেক্ষায়';

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
            'আজকের বাজার, টাকা আর সিঙ্ক অবস্থা এক নজরে দেখুন।',
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
      label: 'হিসাবের সারাংশ',
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
                      'হিসাবের সারাংশ',
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
                      label: 'আনুমানিক টাকা',
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
                          ? 'লোড হচ্ছে'
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
