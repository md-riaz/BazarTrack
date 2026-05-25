import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sync/sync_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/app_enums.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/domain/services/role_permissions.dart';
import '../../../../shared/widgets/app_bar.dart';
import '../../../../shared/widgets/ghost_button.dart';
import '../providers/settings_providers.dart';
import '../widgets/settings_widgets.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({
    super.key,
    this.user,
    this.onProfileEditTap,
    this.onOfflineQueueTap,
    this.onMenuTap,
    this.onLogoutTap,
  });

  final User? user;
  final VoidCallback? onProfileEditTap;
  final VoidCallback? onOfflineQueueTap;
  final ValueChanged<String>? onMenuTap;
  final VoidCallback? onLogoutTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(syncStatusProvider);
    final queueCount = ref
        .watch(offlineQueueEntriesProvider)
        .maybeWhen(data: (entries) => entries.length, orElse: () => 0);
    return Scaffold(
      backgroundColor: AppColors.surface2,
      appBar: const BazarAppBar(title: 'আরো'),
      body: ListView(
        children: [
          _ProfileCard(user: user, onProfileEditTap: onProfileEditTap),
          _SyncStatusCard(
            sync: sync,
            queueCount: queueCount,
            onOfflineQueueTap: onOfflineQueueTap,
          ),
          HSectionCard(
            children: [
              _menuRow('notifications', 'নোটিফিকেশন', Icons.notifications),
              if (user == null || RolePermissions.canAccessReports(user!.role))
                _menuRow('reports', 'রিপোর্ট', Icons.bar_chart),
              _menuRow(
                'walletDetail',
                'Wallet details',
                Icons.account_balance_wallet,
              ),
              if (user == null || RolePermissions.canAccessReports(user!.role))
                _menuRow('monthlyClose', 'Close হিসাব', Icons.calendar_month),
              _menuRow('search', 'খুঁজুন', Icons.search),
              if (user != null && RolePermissions.canSeeAdminMenu(user!.role))
                _menuRow(
                  'admin',
                  'অ্যাডমিন প্যানেল',
                  Icons.admin_panel_settings,
                ),
              HMenuRow(
                icon: Icons.settings,
                title: 'সেটিংস',
                subtitle: 'নোটিফিকেশন, ভাষা, ডাটা',
                showDivider: false,
                onTap: () => onMenuTap?.call('settings'),
              ),
            ],
          ),
          GhostButton(
            label: 'লগআউট',
            foregroundColor: AppColors.negative,
            borderColor: AppColors.negativeLight,
            onPressed: onLogoutTap,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  HMenuRow _menuRow(String routeKey, String title, IconData icon) {
    final subtitles = <String, String>{
      'notifications': '৩টি নতুন',
      'reports': 'মে ২০২৫',
      'walletDetail': 'ব্যালেন্স বিস্তারিত',
      'monthlyClose': 'মাসিক হিসাব বন্ধ',
      'search': 'বাজার, আইটেম, টাকা',
      'admin': 'ইউজার ও ওয়ালেট ম্যানেজ',
    };
    return HMenuRow(
      icon: icon,
      title: title,
      subtitle: subtitles[routeKey]!,
      onTap: () => onMenuTap?.call(routeKey),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user, required this.onProfileEditTap});

  final User? user;
  final VoidCallback? onProfileEditTap;

  @override
  Widget build(BuildContext context) {
    final displayName = user?.name ?? 'Demo User';
    final contact = user?.phone ?? user?.email ?? 'Demo account';
    return HSectionCard(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              HAvatar(label: _initials(displayName)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName, style: AppTextStyles.bodyStrong),
                    const SizedBox(height: 2),
                    Text(contact, style: AppTextStyles.bodySmall),
                    const SizedBox(height: 5),
                    HPill(
                      label: user == null
                          ? 'Demo'
                          : RolePermissions.label(user!.role),
                      backgroundColor: AppColors.positiveLight,
                      foregroundColor: AppColors.positiveDark,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onProfileEditTap,
                child: Text(
                  'Edit',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _initials(String name) {
    final parts = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return 'DU';
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }
}

class _SyncStatusCard extends StatelessWidget {
  const _SyncStatusCard({
    required this.sync,
    required this.queueCount,
    required this.onOfflineQueueTap,
  });

  final SyncStatus sync;
  final int queueCount;
  final VoidCallback? onOfflineQueueTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sync status', style: AppTextStyles.label),
          const SizedBox(height: 8),
          Row(
            children: [
              HPill(
                label: _syncLabel(sync),
                backgroundColor: _syncBackground(sync),
                foregroundColor: _syncForeground(sync),
              ),
              const Spacer(),
              TextButton(
                onPressed: onOfflineQueueTap,
                child: Text(
                  'Queue দেখুন',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: onOfflineQueueTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: queueCount > 0
                    ? AppColors.warningLight
                    : AppColors.positiveLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                queueCount > 0
                    ? '${_toBanglaDigits(queueCount)}টা item Sync queue-তে আছে। দেখুন →'
                    : 'সব ডাটা synced',
                style: AppTextStyles.bodySmall.copyWith(
                  color: queueCount > 0
                      ? AppColors.warningDark
                      : AppColors.positiveDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _syncLabel(SyncStatus status) {
  return switch (status) {
    SyncStatus.online => 'Synced',
    SyncStatus.syncing => 'Sync হচ্ছে',
    SyncStatus.offline => 'Offline',
    SyncStatus.failed => 'Sync failed',
  };
}

Color _syncBackground(SyncStatus status) {
  return switch (status) {
    SyncStatus.online => AppColors.positiveLight,
    SyncStatus.syncing => AppColors.primaryLight,
    SyncStatus.offline => AppColors.warningLight,
    SyncStatus.failed => AppColors.negativeLight,
  };
}

Color _syncForeground(SyncStatus status) {
  return switch (status) {
    SyncStatus.online => AppColors.positiveDark,
    SyncStatus.syncing => AppColors.primary,
    SyncStatus.offline => AppColors.warningDark,
    SyncStatus.failed => AppColors.negativeDark,
  };
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
