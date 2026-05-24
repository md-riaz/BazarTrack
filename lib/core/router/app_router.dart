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
      for (final route in AppRoutes.all.where(
        (route) => route.path != AppRoutes.login,
      ))
        GoRoute(
          path: route.path,
          name: route.name,
          builder: (context, state) => AppRouteScreen(route: route),
        ),
    ],
  );
});

class AppRouteSpec {
  const AppRouteSpec({
    required this.name,
    required this.path,
    required this.title,
    required this.description,
  });

  final String name;
  final String path;
  final String title;
  final String description;
}

class AppRoutes {
  const AppRoutes._();

  static const login = '/login';
  static const home = '/';
  static const bazarList = '/bazars';
  static const bazarDetail = '/bazars/detail';
  static const newBazar = '/bazars/new';
  static const addItem = '/bazars/items/add';
  static const directExpense = '/money/direct-expense';
  static const bazarSummary = '/bazars/summary';
  static const balance = '/balance';
  static const moneyEntry = '/money/entry';
  static const notifications = '/notifications';
  static const reports = '/reports';
  static const walletDetail = '/wallets/detail';
  static const monthlyClose = '/reports/monthly-close';
  static const admin = '/admin';
  static const search = '/search';
  static const settings = '/settings';
  static const offlineQueue = '/sync/offline-queue';
  static const more = '/more';
  static const profileEdit = '/profile/edit';
  static const addUser = '/admin/users/add';
  static const bazarComments = '/comments';
  static const priceHistory = '/items/price-history';
  static const assistantLedger = '/wallets/assistant-ledger';

  static const all = <AppRouteSpec>[
    AppRouteSpec(
      name: 'login',
      path: login,
      title: 'লগইন',
      description: 'Auth entry screen',
    ),
    AppRouteSpec(
      name: 'home',
      path: home,
      title: 'হোম',
      description: 'Dashboard shell and quick actions',
    ),
    AppRouteSpec(
      name: 'bazar-list',
      path: bazarList,
      title: 'বাজার তালিকা',
      description: 'All bazars with filters',
    ),
    AppRouteSpec(
      name: 'bazar-detail',
      path: bazarDetail,
      title: 'বাজার বিস্তারিত',
      description: 'Single bazar tracking view',
    ),
    AppRouteSpec(
      name: 'new-bazar',
      path: newBazar,
      title: 'নতুন বাজার',
      description: 'Create bazar request flow',
    ),
    AppRouteSpec(
      name: 'add-item',
      path: addItem,
      title: 'আইটেম যোগ',
      description: 'Item capture and parsing flow',
    ),
    AppRouteSpec(
      name: 'direct-expense',
      path: directExpense,
      title: 'সরাসরি খরচ',
      description: 'Direct expense entry flow',
    ),
    AppRouteSpec(
      name: 'bazar-summary',
      path: bazarSummary,
      title: 'বাজার সারাংশ',
      description: 'Closed bazar summary view',
    ),
    AppRouteSpec(
      name: 'balance',
      path: balance,
      title: 'ব্যালেন্স',
      description: 'Wallet and assistant balance board',
    ),
    AppRouteSpec(
      name: 'money-entry',
      path: moneyEntry,
      title: 'টাকা এন্ট্রি',
      description: 'Money receive/return/adjustment flow',
    ),
    AppRouteSpec(
      name: 'notifications',
      path: notifications,
      title: 'নোটিফিকেশন',
      description: 'Alerts and activity feed',
    ),
    AppRouteSpec(
      name: 'reports',
      path: reports,
      title: 'রিপোর্টস',
      description: 'Wallet reports and analytics',
    ),
    AppRouteSpec(
      name: 'wallet-detail',
      path: walletDetail,
      title: 'ওয়ালেট বিস্তারিত',
      description: 'Wallet ledger summary',
    ),
    AppRouteSpec(
      name: 'monthly-close',
      path: monthlyClose,
      title: 'মাসিক ক্লোজ',
      description: 'Snapshot and close flow',
    ),
    AppRouteSpec(
      name: 'admin',
      path: admin,
      title: 'অ্যাডমিন',
      description: 'Admin control panel',
    ),
    AppRouteSpec(
      name: 'search',
      path: search,
      title: 'সার্চ',
      description: 'Cross-wallet search view',
    ),
    AppRouteSpec(
      name: 'settings',
      path: settings,
      title: 'সেটিংস',
      description: 'Settings and preferences',
    ),
    AppRouteSpec(
      name: 'offline-queue',
      path: offlineQueue,
      title: 'অফলাইন কিউ',
      description: 'Sync backlog and conflict queue',
    ),
    AppRouteSpec(
      name: 'more',
      path: more,
      title: 'আরও',
      description: 'Secondary menu hub',
    ),
    AppRouteSpec(
      name: 'profile-edit',
      path: profileEdit,
      title: 'প্রোফাইল এডিট',
      description: 'User profile editing form',
    ),
    AppRouteSpec(
      name: 'add-user',
      path: addUser,
      title: 'ইউজার যোগ',
      description: 'Admin user creation form',
    ),
    AppRouteSpec(
      name: 'bazar-comments',
      path: bazarComments,
      title: 'বাজার কমেন্টস',
      description: 'Comment thread for bazar',
    ),
    AppRouteSpec(
      name: 'price-history',
      path: priceHistory,
      title: 'দাম ইতিহাস',
      description: 'Item price history timeline',
    ),
    AppRouteSpec(
      name: 'assistant-ledger',
      path: assistantLedger,
      title: 'অ্যাসিস্ট্যান্ট লেজার',
      description: 'Assistant-level ledger and balances',
    ),
  ];
}

class AppRouteScreen extends ConsumerWidget {
  const AppRouteScreen({required this.route, super.key});

  final AppRouteSpec route;

  static const _defaultBazarId = 'b1';
  static const _defaultWalletId = 'w2';
  static const _defaultAssistantId = 'u1';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (route.path) {
      AppRoutes.home => const RoutePlaceholderScreen(
        title: 'হোম',
        description: 'Dashboard shell and quick actions',
      ),
      AppRoutes.bazarList => BazarListScreen(
        onBazarTap: (id) => context.go(AppRoutes.bazarDetail),
      ),
      AppRoutes.bazarDetail => const BazarDetailScreen(
        bazarId: _defaultBazarId,
      ),
      AppRoutes.newBazar => NewBazarScreen(
        onBack: () => context.go(AppRoutes.bazarList),
        onCreated: (_) => context.go(AppRoutes.bazarDetail),
      ),
      AppRoutes.addItem => AddItemScreen(
        bazarId: _defaultBazarId,
        onBack: () => context.go(AppRoutes.bazarDetail),
        onDone: () => context.go(AppRoutes.bazarDetail),
      ),
      AppRoutes.directExpense => DirectExpenseScreen(
        onBack: () => context.go(AppRoutes.home),
        onSaved: () => context.go(AppRoutes.home),
      ),
      AppRoutes.bazarSummary => const BazarSummaryScreen(
        bazarId: _defaultBazarId,
      ),
      AppRoutes.balance => BalanceScreen(
        onWalletTap: (_) => context.go(AppRoutes.walletDetail),
        onMoneyEntryTap: () => context.go(AppRoutes.moneyEntry),
      ),
      AppRoutes.moneyEntry => const MoneyEntryScreen(),
      AppRoutes.notifications => const NotificationsScreen(),
      AppRoutes.reports => const ReportsScreen(),
      AppRoutes.walletDetail => const WalletDetailScreen(
        walletId: _defaultWalletId,
        assistantId: _defaultAssistantId,
      ),
      AppRoutes.monthlyClose => const MonthlyCloseScreen(),
      AppRoutes.admin => AdminScreen(
        onAddUserTap: () => context.go(AppRoutes.addUser),
      ),
      AppRoutes.search => SearchScreen(
        onResultTap: (_) => context.go(AppRoutes.bazarDetail),
      ),
      AppRoutes.settings => SettingsScreen(
        onBack: () => context.go(AppRoutes.more),
        onOfflineQueueTap: () => context.go(AppRoutes.offlineQueue),
      ),
      AppRoutes.offlineQueue => OfflineQueueScreen(
        onBack: () => context.go(AppRoutes.settings),
      ),
      AppRoutes.more => MoreScreen(
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
      AppRoutes.profileEdit => ProfileEditScreen(
        onBack: () => context.go(AppRoutes.more),
      ),
      AppRoutes.addUser => AddUserScreen(
        onUserCreated: () => context.go(AppRoutes.admin),
        onCancel: () => context.go(AppRoutes.admin),
      ),
      AppRoutes.bazarComments => BazarCommentsScreen(
        onBack: () => context.go(AppRoutes.bazarDetail),
      ),
      AppRoutes.priceHistory => PriceHistoryScreen(
        onBack: () => context.go(AppRoutes.bazarDetail),
      ),
      AppRoutes.assistantLedger => const AssistantLedgerScreen(
        walletId: _defaultWalletId,
        assistantId: _defaultAssistantId,
      ),
      _ => RoutePlaceholderScreen(
        title: route.title,
        description: route.description,
      ),
    };
  }

  void _goFromMoreMenu(BuildContext context, String key) {
    final destination = switch (key) {
      'notifications' => AppRoutes.notifications,
      'reports' => AppRoutes.reports,
      'walletDetail' => AppRoutes.walletDetail,
      'monthlyClose' => AppRoutes.monthlyClose,
      'search' => AppRoutes.search,
      'admin' => AppRoutes.admin,
      'settings' => AppRoutes.settings,
      _ => AppRoutes.more,
    };
    context.go(destination);
  }
}

class RoutePlaceholderScreen extends ConsumerWidget {
  const RoutePlaceholderScreen({
    required this.title,
    required this.description,
    super.key,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      appBar: BazarAppBar(
        title: title,
        subtitle: currentUser == null
            ? 'AUTH REQUIRED'
            : 'লগইন: ${currentUser.name}',
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description, style: Theme.of(context).textTheme.bodyLarge),
            const Spacer(),
            PrimaryButton(
              label: 'লগআউট',
              onPressed: () async {
                await ref.read(loginControllerProvider.notifier).logout();
                if (context.mounted) {
                  context.go(AppRoutes.login);
                }
              },
              margin: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}
