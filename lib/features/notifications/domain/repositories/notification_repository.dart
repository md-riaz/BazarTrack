import '../entities/app_notification.dart';

abstract class NotificationRepository {
  Future<List<AppNotification>> getNotifications();
  Future<List<AppNotification>> markAllRead();
  Future<List<AppNotification>> markRead(String id);
}
