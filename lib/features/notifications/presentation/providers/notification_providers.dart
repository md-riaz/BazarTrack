import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/mock_notification_datasource.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../data/services/push_notification_handler.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';

final notificationDataSourceProvider = Provider<NotificationDataSource>((ref) {
  return MockNotificationDataSource();
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(ref.watch(notificationDataSourceProvider));
});

final pushNotificationHandlerProvider = Provider<PushNotificationHandler>((
  ref,
) {
  return PushNotificationHandler();
});

class NotificationsController
    extends StateNotifier<AsyncValue<List<AppNotification>>> {
  NotificationsController(this._repository)
    : super(const AsyncValue.loading()) {
    load();
  }

  final NotificationRepository _repository;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repository.getNotifications);
  }

  Future<void> markAllRead() async {
    state = await AsyncValue.guard(_repository.markAllRead);
  }

  Future<void> markRead(String id) async {
    state = await AsyncValue.guard(() => _repository.markRead(id));
  }
}

final notificationsControllerProvider =
    StateNotifierProvider<
      NotificationsController,
      AsyncValue<List<AppNotification>>
    >((ref) {
      return NotificationsController(ref.watch(notificationRepositoryProvider));
    });
