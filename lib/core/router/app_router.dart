import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../shared/providers/foundation_providers.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/primary_button.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.home,
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == AppRoutes.login;
      final isAuthenticated = authState.isAuthenticated;

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
      for (final route in AppRoutes.all.where((route) => route.path != AppRoutes.login))
        GoRoute(
          path: route.path,
          name: route.name,
          builder: (context, state) => RoutePlaceholderScreen(route: route),
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
    AppRouteSpec(name: 'login', path: login, title: 'লগইন', description: 'Auth entry screen'),
    AppRouteSpec(name: 'home', path: home, title: 'হোম', description: 'Dashboard shell and quick actions'),
    AppRouteSpec(name: 'bazar-list', path: bazarList, title: 'বাজার তালিকা', description: 'All bazars with filters'),
    AppRouteSpec(name: 'bazar-detail', path: bazarDetail, title: 'বাজার বিস্তারিত', description: 'Single bazar tracking view'),
    AppRouteSpec(name: 'new-bazar', path: newBazar, title: 'নতুন বাজার', description: 'Create bazar request flow'),
    AppRouteSpec(name: 'add-item', path: addItem, title: 'আইটেম যোগ', description: 'Item capture and parsing flow'),
    AppRouteSpec(name: 'direct-expense', path: directExpense, title: 'সরাসরি খরচ', description: 'Direct expense entry flow'),
    AppRouteSpec(name: 'bazar-summary', path: bazarSummary, title: 'বাজার সারাংশ', description: 'Closed bazar summary view'),
    AppRouteSpec(name: 'balance', path: balance, title: 'ব্যালেন্স', description: 'Wallet and assistant balance board'),
    AppRouteSpec(name: 'money-entry', path: moneyEntry, title: 'টাকা এন্ট্রি', description: 'Money receive/return/adjustment flow'),
    AppRouteSpec(name: 'notifications', path: notifications, title: 'নোটিফিকেশন', description: 'Alerts and activity feed'),
    AppRouteSpec(name: 'reports', path: reports, title: 'রিপোর্টস', description: 'Wallet reports and analytics'),
    AppRouteSpec(name: 'wallet-detail', path: walletDetail, title: 'ওয়ালেট বিস্তারিত', description: 'Wallet ledger summary'),
    AppRouteSpec(name: 'monthly-close', path: monthlyClose, title: 'মাসিক ক্লোজ', description: 'Snapshot and close flow'),
    AppRouteSpec(name: 'admin', path: admin, title: 'অ্যাডমিন', description: 'Admin control panel'),
    AppRouteSpec(name: 'search', path: search, title: 'সার্চ', description: 'Cross-wallet search view'),
    AppRouteSpec(name: 'settings', path: settings, title: 'সেটিংস', description: 'Settings and preferences'),
    AppRouteSpec(name: 'offline-queue', path: offlineQueue, title: 'অফলাইন কিউ', description: 'Sync backlog and conflict queue'),
    AppRouteSpec(name: 'more', path: more, title: 'আরও', description: 'Secondary menu hub'),
    AppRouteSpec(name: 'profile-edit', path: profileEdit, title: 'প্রোফাইল এডিট', description: 'User profile editing form'),
    AppRouteSpec(name: 'add-user', path: addUser, title: 'ইউজার যোগ', description: 'Admin user creation form'),
    AppRouteSpec(name: 'bazar-comments', path: bazarComments, title: 'বাজার কমেন্টস', description: 'Comment thread for bazar'),
    AppRouteSpec(name: 'price-history', path: priceHistory, title: 'দাম ইতিহাস', description: 'Item price history timeline'),
    AppRouteSpec(name: 'assistant-ledger', path: assistantLedger, title: 'অ্যাসিস্ট্যান্ট লেজার', description: 'Assistant-level ledger and balances'),
  ];
}

class RoutePlaceholderScreen extends ConsumerWidget {
  const RoutePlaceholderScreen({required this.route, super.key});

  final AppRouteSpec route;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: BazarAppBar(
        title: route.title,
        subtitle: authState.isAuthenticated ? 'FOUNDATION READY' : 'AUTH REQUIRED',
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(route.description, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 12),
            Text('Route: ${route.path}', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            Text('Name: ${route.name}', style: Theme.of(context).textTheme.bodySmall),
            const Spacer(),
            PrimaryButton(
              label: 'লগআউট',
              onPressed: () {
                ref.read(authStateProvider.notifier).state = const AuthState.unauthenticated();
              },
              margin: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}
