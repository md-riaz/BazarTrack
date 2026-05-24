import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/mock_notification_datasource.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  const NotificationRepositoryImpl(this._dataSource);

  final NotificationDataSource _dataSource;

  @override
  Future<List<AppNotification>> getNotifications() {
    return _dataSource.getNotifications();
  }

  @override
  Future<List<AppNotification>> markAllRead() {
    return _dataSource.markAllRead();
  }

  @override
  Future<List<AppNotification>> markRead(String id) {
    return _dataSource.markRead(id);
  }
}
