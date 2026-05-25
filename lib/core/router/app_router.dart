import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/screens/add_user_screen.dart';
import '../../features/admin/presentation/screens/admin_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
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
import '../../features/reports/presentation/screens/monthly_close_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/search/domain/entities/search_entities.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/settings/presentation/screens/more_screen.dart';
import '../../features/settings/presentation/screens/offline_queue_screen.dart';
import '../../features/settings/presentation/screens/profile_edit_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/wallet/presentation/screens/assistant_ledger_screen.dart';
import '../../features/wallet/presentation/screens/balance_screen.dart';
import '../../features/wallet/presentation/screens/wallet_detail_screen.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/primary_button.dart';
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
        builder: (context, state) =>
            AdminScreen(onAddUserTap: () => context.go(AppRoutes.addUser)),
      ),
      GoRoute(
        path: AppRoutes.search,
        name: 'search',
        builder: (context, state) => SearchScreen(
          onResultTap: (result) => context.go(_routeForSearchResult(result)),
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
    'walletDetail' => AppRoutes.walletDetail('w2'),
    'monthlyClose' => AppRoutes.monthlyClose,
    'search' => AppRoutes.search,
    'admin' => AppRoutes.admin,
    'settings' => AppRoutes.settings,
    _ => AppRoutes.more,
  };
  context.go(destination);
  return destination;
}

String _routeForSearchResult(SearchResultItem result) {
  return switch (result.type) {
    SearchResultType.bazar || SearchResultType.item => AppRoutes.bazarDetail(
      result.title.contains('Office Lunch') ? 'b2' : 'b1',
    ),
    SearchResultType.money => AppRoutes.walletDetail('w2'),
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

    return Scaffold(
      backgroundColor: AppColors.surface2,
      appBar: BazarAppBar(
        title: 'সহজ বাজার খাতা',
        subtitle: currentUser == null
            ? 'ড্যাশবোর্ড'
            : 'লগইন: ${currentUser.name}',
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
          const _HomeHeroCard(),
          const SizedBox(height: 16),
          Text('দ্রুত কাজ', style: AppTextStyles.screenTitle),
          const SizedBox(height: 10),
          _HomeActionGrid(
            actions: [
              _HomeAction('বাজার তালিকা', Icons.shopping_basket, onBazarTap),
              _HomeAction('নতুন বাজার', Icons.add_shopping_cart, onNewBazarTap),
              _HomeAction(
                'ব্যালেন্স',
                Icons.account_balance_wallet,
                onBalanceTap,
              ),
              _HomeAction('টাকা এন্ট্রি', Icons.payments, onMoneyEntryTap),
              _HomeAction('সরাসরি খরচ', Icons.receipt_long, onDirectExpenseTap),
              _HomeAction('রিপোর্টস', Icons.bar_chart, onReportsTap),
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
  const _HomeHeroCard();

  @override
  Widget build(BuildContext context) {
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
          Text('আজকের বাজার ও টাকা', style: AppTextStyles.appBarTitle),
          const SizedBox(height: 8),
          Text(
            'বাজারের তালিকা, খরচ, আর টাকা কার কাছে কত আছে — সব এক জায়গায়।',
            style: AppTextStyles.body.copyWith(color: Colors.white70),
          ),
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
