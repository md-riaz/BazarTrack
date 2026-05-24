import 'package:flutter/material.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.timeLabel,
    required this.group,
    required this.icon,
    required this.backgroundColor,
    required this.isRead,
  });

  final String id;
  final String title;
  final String subtitle;
  final String timeLabel;
  final NotificationGroup group;
  final IconData icon;
  final Color backgroundColor;
  final bool isRead;

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      subtitle: subtitle,
      timeLabel: timeLabel,
      group: group,
      icon: icon,
      backgroundColor: backgroundColor,
      isRead: isRead ?? this.isRead,
    );
  }
}

enum NotificationGroup {
  today('আজকে'),
  yesterday('গতকাল'),
  older('আগে');

  const NotificationGroup(this.label);

  final String label;
}
