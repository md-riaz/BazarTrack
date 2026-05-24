import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_bar.dart';
import '../../domain/entities/app_notification.dart';
import '../providers/notification_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.surface2,
      appBar: BazarAppBar(
        title: 'Notifications',
        actions: [
          TextButton(
            onPressed: () => ref
                .read(notificationsControllerProvider.notifier)
                .markAllRead(),
            child: Text(
              'সব পড়া',
              style: AppTextStyles.sectionAction.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
      body: notifications.when(
        data: (items) => RefreshIndicator(
          onRefresh: () =>
              ref.read(notificationsControllerProvider.notifier).load(),
          child: ListView(
            children: [
              const SizedBox(height: 10),
              for (final group in NotificationGroup.values) ...[
                if (items.any((item) => item.group == group))
                  _NotificationGroupSection(
                    group: group,
                    notifications: items
                        .where((item) => item.group == group)
                        .toList(),
                    onTap: (id) => ref
                        .read(notificationsControllerProvider.notifier)
                        .markRead(id),
                  ),
              ],
              const SizedBox(height: 10),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('নোটিফিকেশন লোড করা যায়নি', style: AppTextStyles.body),
        ),
      ),
    );
  }
}

class _NotificationGroupSection extends StatelessWidget {
  const _NotificationGroupSection({
    required this.group,
    required this.notifications,
    required this.onTap,
  });

  final NotificationGroup group;
  final List<AppNotification> notifications;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
          child: Text(group.label, style: AppTextStyles.sectionTitle),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var index = 0; index < notifications.length; index++)
                _NotificationTile(
                  notification: notifications[index],
                  showDivider: index < notifications.length - 1,
                  onTap: () => onTap(notifications[index].id),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.showDivider,
    required this.onTap,
  });

  final AppNotification notification;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: notification.isRead
              ? AppColors.surface
              : AppColors.primaryLight.withValues(alpha: 0.36),
          border: showDivider
              ? const Border(
                  bottom: BorderSide(color: AppColors.surface3, width: 0.5),
                )
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: notification.backgroundColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(notification.icon, size: 18, color: AppColors.text2),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: AppTextStyles.bodyStrong.copyWith(
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (!notification.isRead) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 5),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notification.subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.text3,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(notification.timeLabel, style: AppTextStyles.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
