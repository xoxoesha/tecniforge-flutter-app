import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notifications_service.dart'; // reuses `notificationsPlugin` from Fix 3

// ---------------------------------------------------------------------------
// PUSH NOTIFICATIONS — Firebase Cloud Messaging (FCM).
//
// Different from notifications_service.dart (Fix 3), which SCHEDULES alerts
// from inside the app itself (zonedSchedule) — no server or internet needed.
//
// This file receives messages sent FROM a server (or the Firebase Console,
// for testing) TO this specific device, over the internet, even while the
// app is closed. That's what makes it "push" — the message is pushed to the
// device, not scheduled locally.
//
// Android quirk this file handles: when the app is OPEN (foreground), FCM
// does NOT automatically show a system notification — it just hands the
// message to onMessage. So we take that message and display it ourselves
// using the same flutter_local_notifications plugin from Fix 3. When the
// app is in the background or closed, Android shows the system notification
// for us automatically.
// ---------------------------------------------------------------------------

/// Must be a TOP-LEVEL function (not inside a class) — Android runs this in
/// a separate isolate when a push arrives while the app is fully closed.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  // Nothing to do here for now — Android already shows the system
  // notification automatically when the app isn't in the foreground.
  // This handler exists so we *could* react to the data (e.g. update local
  // storage) even while the app is closed.
}

Future<void> initPushNotifications() async {
  await Firebase.initializeApp();

  final messaging = FirebaseMessaging.instance;

  // Android 13+ requires the user to explicitly allow notifications.
  await messaging.requestPermission(alert: true, badge: true, sound: true);

  // This token uniquely identifies this device+app install to FCM — a
  // server (or the Firebase Console's "Send test message") uses it to
  // target a push at this exact phone. Printed for now so it can be copied
  // out of `flutter run`'s console during testing.
  final token = await messaging.getToken();
  // ignore: avoid_print
  print('FCM token: $token');

  // Background/terminated messages are handled by Android automatically,
  // but we still register the handler so we can react to the payload data.
  FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

  // Foreground messages need to be shown manually (see note above).
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    notificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'push_channel',
          'Push Notifications',
          channelDescription: 'Alerts sent from the server while the app is open',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  });
}
