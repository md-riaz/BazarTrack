import 'package:bazar/features/notifications/data/datasources/mock_notification_datasource.dart';
import 'package:bazar/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:bazar/features/notifications/domain/entities/app_notification.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationRepositoryImpl', () {
    test('loads grouped prototype notifications', () async {
      final repository = NotificationRepositoryImpl(
        MockNotificationDataSource(),
      );

      final notifications = await repository.getNotifications();

      expect(notifications, hasLength(6));
      expect(notifications.first.title, 'Rahim CEO Personal বাজার শুরু করেছে');
      expect(notifications.first.group, NotificationGroup.today);
      expect(notifications.where((item) => !item.isRead), hasLength(3));
    });

    test('marks one notification as read', () async {
      final repository = NotificationRepositoryImpl(
        MockNotificationDataSource(),
      );

      final notifications = await repository.markRead('n1');
      final target = notifications.firstWhere((item) => item.id == 'n1');

      expect(target.isRead, isTrue);
      expect(notifications.where((item) => !item.isRead), hasLength(2));
    });

    test('marks all notifications as read', () async {
      final repository = NotificationRepositoryImpl(
        MockNotificationDataSource(),
      );

      final notifications = await repository.markAllRead();

      expect(notifications.every((item) => item.isRead), isTrue);
    });
  });
}
