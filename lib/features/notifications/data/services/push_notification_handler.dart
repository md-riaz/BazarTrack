import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> bazarFirebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await PushNotificationHandler.handleBackgroundMessage(message);
}

class PushNotificationHandler {
  PushNotificationHandler({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _localNotifications =
           localNotifications ?? FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;

  Future<void> initialize() async {
    await _messaging.requestPermission();
    FirebaseMessaging.onBackgroundMessage(
      bazarFirebaseMessagingBackgroundHandler,
    );
    FirebaseMessaging.onMessage.listen(handleForegroundMessage);
  }

  Future<String?> getDeviceToken() {
    return _messaging.getToken();
  }

  Future<void> handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) {
      return;
    }

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'bazar_updates',
          'বাজার আপডেট',
          channelDescription: 'বাজার, টাকা ও হিসাবের নোটিফিকেশন',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    return;
  }
}
