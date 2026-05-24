import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/app_notification.dart';

abstract class NotificationDataSource {
  Future<List<AppNotification>> getNotifications();
  Future<List<AppNotification>> markAllRead();
  Future<List<AppNotification>> markRead(String id);
}

class MockNotificationDataSource implements NotificationDataSource {
  MockNotificationDataSource() : _notifications = List.of(_seedNotifications);

  final List<AppNotification> _notifications;

  static const _seedNotifications = <AppNotification>[
    AppNotification(
      id: 'n1',
      title: 'Rahim CEO Personal বাজার শুরু করেছে',
      subtitle: '৪টি item যোগ করা হয়েছে',
      timeLabel: '১০ মিনিট আগে',
      group: NotificationGroup.today,
      icon: Icons.shopping_basket_outlined,
      backgroundColor: AppColors.warningLight,
      isRead: false,
    ),
    AppNotification(
      id: 'n2',
      title: 'গরুর মাংস পাওয়া যায়নি',
      subtitle: 'CEO Personal বাজার · Rahim',
      timeLabel: '১৫ মিনিট আগে',
      group: NotificationGroup.today,
      icon: Icons.close,
      backgroundColor: AppColors.negativeLight,
      isRead: false,
    ),
    AppNotification(
      id: 'n3',
      title: 'Accounts Rahim-কে ৳ ৫,০০০ দিয়েছে',
      subtitle: 'Office Wallet · Karim (Accounts)',
      timeLabel: '১ ঘণ্টা আগে',
      group: NotificationGroup.today,
      icon: Icons.payments_outlined,
      backgroundColor: AppColors.positiveLight,
      isRead: false,
    ),
    AppNotification(
      id: 'n4',
      title: 'Rahim Office Wallet বাজার শেষ করেছে',
      subtitle: 'মোট খরচ ৳ ৩,২০০',
      timeLabel: 'গতকাল ১১:৩০ AM',
      group: NotificationGroup.yesterday,
      icon: Icons.check,
      backgroundColor: AppColors.positiveLight,
      isRead: true,
    ),
    AppNotification(
      id: 'n5',
      title: 'এপ্রিলের হিসাব বন্ধ হয়েছে',
      subtitle: 'Accounts Officer · Balance: ৳ ৮০০',
      timeLabel: '৩০ এপ্রিল',
      group: NotificationGroup.older,
      icon: Icons.calendar_month_outlined,
      backgroundColor: AppColors.primaryLight,
      isRead: true,
    ),
    AppNotification(
      id: 'n6',
      title: 'CEO Personal ব্যালেন্স নেগেটিভ হয়েছে',
      subtitle: 'Rahim পাবে ৳ ১,২০০',
      timeLabel: '২২ মে',
      group: NotificationGroup.older,
      icon: Icons.warning_amber_rounded,
      backgroundColor: AppColors.negativeLight,
      isRead: true,
    ),
  ];

  @override
  Future<List<AppNotification>> getNotifications() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return List<AppNotification>.unmodifiable(_notifications);
  }

  @override
  Future<List<AppNotification>> markAllRead() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    for (var index = 0; index < _notifications.length; index++) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    }
    return List<AppNotification>.unmodifiable(_notifications);
  }

  @override
  Future<List<AppNotification>> markRead(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final index = _notifications.indexWhere((item) => item.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    }
    return List<AppNotification>.unmodifiable(_notifications);
  }
}
