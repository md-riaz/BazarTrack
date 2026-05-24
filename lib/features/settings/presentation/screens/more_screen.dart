import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/app_enums.dart';
import '../../../../shared/widgets/app_bar.dart';
import '../../../../shared/widgets/ghost_button.dart';
import '../providers/settings_providers.dart';
import '../widgets/settings_widgets.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({
    super.key,
    this.onProfileEditTap,
    this.onOfflineQueueTap,
    this.onMenuTap,
    this.onLogoutTap,
  });

  final VoidCallback? onProfileEditTap;
  final VoidCallback? onOfflineQueueTap;
  final ValueChanged<String>? onMenuTap;
  final VoidCallback? onLogoutTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(settingsSyncStatusProvider);
    final queue = ref.watch(offlineQueueEntriesProvider);
    return Scaffold(
      backgroundColor: AppColors.surface2,
      appBar: const BazarAppBar(title: 'আরো'),
      body: ListView(
        children: [
          _ProfileCard(onProfileEditTap: onProfileEditTap),
          _SyncStatusCard(
            sync: sync,
            queueCount: queue.length,
            onChanged: (value) =>
                ref.read(settingsSyncStatusProvider.notifier).state = value,
            onOfflineQueueTap: onOfflineQueueTap,
          ),
          HSectionCard(
            children: [
              _menuRow('notifications', 'নোটিফিকেশন', Icons.notifications),
              _menuRow('reports', 'রিপোর্ট', Icons.bar_chart),
              _menuRow(
                'walletDetail',
                'ওয়ালেট ডিটেইল',
                Icons.account_balance_wallet,
              ),
              _menuRow('monthlyClose', 'হিসাব বন্ধ', Icons.calendar_month),
              _menuRow('search', 'খুঁজুন', Icons.search),
              _menuRow('admin', 'Admin Panel', Icons.admin_panel_settings),
              HMenuRow(
                icon: Icons.settings,
                title: 'সেটিংস',
                subtitle: 'Notification, Language, Data',
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
      'walletDetail': 'CEO Personal বিস্তারিত',
      'monthlyClose': 'মাসিক closing',
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
  const _ProfileCard({required this.onProfileEditTap});

  final VoidCallback? onProfileEditTap;

  @override
  Widget build(BuildContext context) {
    return HSectionCard(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const HAvatar(label: 'RU'),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rahim Uddin', style: AppTextStyles.bodyStrong),
                    const SizedBox(height: 2),
                    Text('01711-XXXXXX', style: AppTextStyles.bodySmall),
                    const SizedBox(height: 5),
                    const HPill(
                      label: 'assistant',
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
}

class _SyncStatusCard extends StatelessWidget {
  const _SyncStatusCard({
    required this.sync,
    required this.queueCount,
    required this.onChanged,
    required this.onOfflineQueueTap,
  });

  final SyncStatus sync;
  final int queueCount;
  final ValueChanged<SyncStatus> onChanged;
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
          Text('SYNC STATUS', style: AppTextStyles.label),
          const SizedBox(height: 8),
          Row(
            children: [
              _SyncChoice(
                label: 'Online',
                status: SyncStatus.online,
                selected: sync == SyncStatus.online,
                onTap: onChanged,
                color: AppColors.positive,
                bg: AppColors.positiveLight,
              ),
              const SizedBox(width: 8),
              _SyncChoice(
                label: 'Syncing',
                status: SyncStatus.syncing,
                selected: sync == SyncStatus.syncing,
                onTap: onChanged,
                color: AppColors.primary,
                bg: AppColors.primaryLight,
              ),
              const SizedBox(width: 8),
              _SyncChoice(
                label: 'Offline',
                status: SyncStatus.offline,
                selected: sync == SyncStatus.offline,
                onTap: onChanged,
                color: AppColors.warning,
                bg: AppColors.warningLight,
              ),
            ],
          ),
          if (sync == SyncStatus.offline) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: onOfflineQueueTap,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$queueCountটি item sync queue-এ। দেখুন →',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.warningDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SyncChoice extends StatelessWidget {
  const _SyncChoice({
    required this.label,
    required this.status,
    required this.selected,
    required this.onTap,
    required this.color,
    required this.bg,
  });

  final String label;
  final SyncStatus status;
  final bool selected;
  final ValueChanged<SyncStatus> onTap;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () => onTap(status),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(34),
          padding: EdgeInsets.zero,
          backgroundColor: selected ? bg : AppColors.surface,
          side: BorderSide(
            color: selected ? color : AppColors.border,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: selected ? color : AppColors.text4,
          ),
        ),
      ),
    );
  }
}
