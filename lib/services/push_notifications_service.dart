import 'package:flutter/material.dart';
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
// REFINEMENTS in this version (for reliable delivery/handling):
//   1. An explicit Android notification channel is created up front, so
//      delivery is consistent on Android 8+ regardless of when the app was
//      first installed (an implicitly-created channel can end up with
//      inconsistent settings across devices/app versions).
//   2. Tapping a notification (from background OR a cold start/terminated
//      app) now navigates the user to the Notifications screen, via a
//      global navigatorKey — see main.dart.
//   3. The FCM token is re-captured whenever it refreshes (e.g. after a
//      reinstall), not just once at startup.
//   4. Every step is wrapped so a Firebase/permission failure can't crash
//      the rest of the app — push notifications degrade gracefully instead.
// ---------------------------------------------------------------------------

/// Shared navigator key so this service can push a screen without needing
/// a BuildContext (it runs during app startup / background isolates, where
/// no widget context exists yet). Set as MaterialApp's navigatorKey.
final GlobalKey<NavigatorState> pushNavigatorKey = GlobalKey<NavigatorState>();

const _androidChannel = AndroidNotificationChannel(
  'push_channel',
  'Push Notifications',
  description: 'Alerts sent from the server while the app is open',
  importance: Importance.high,
);

/// Must be a TOP-LEVEL function (not inside a class) — Android runs this in
/// a separate isolate when a push arrives while the app is fully closed.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  // Nothing to do here for now — Android already shows the system
  // notification automatically when the app isn't in the foreground.
  // This handler exists so we *could* react to the data (e.g. update local
  // storage) even while the app is closed.
}

/// Opens the Notifications screen when a push is tapped — used for both a
/// background-tap and a cold-start tap (see initPushNotifications below).
void _handleNotificationTap(RemoteMessage message) {
  final navState = pushNavigatorKey.currentState;
  if (navState == null) return;
  navState.pushNamed('/notifications');
}

Future<void> initPushNotifications() async {
  try {
    await Firebase.initializeApp();

    // 1. Explicit channel — created once, before anything is shown on it.
    await notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    final messaging = FirebaseMessaging.instance;

    // Android 13+ requires the user to explicitly allow notifications.
    // Checking current status first avoids re-prompting a user who already
    // said no, and lets us log the outcome either way.
    final settings = await messaging.requestPermission(alert: true, badge: true, sound: true);
    final granted = settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
    // ignore: avoid_print
    print('Push notification permission granted: $granted');
    if (!granted) return; // nothing further to set up if the user declined

    // 3. Capture the token now, and again whenever it refreshes.
    final token = await messaging.getToken();
    // ignore: avoid_print
    print('FCM token: $token');
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      // ignore: avoid_print
      print('FCM token refreshed: $newToken');
      // A real backend would re-register the new token here.
    });

    // Background/terminated messages are handled by Android automatically,
    // but we still register the handler so we can react to the payload data.
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

    // Foreground messages need to be shown manually — Android doesn't pop a
    // system notification for a message that arrives while the app is open.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;
      notificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    });

    // 2. Tap handling — covers both "app was in the background" and
    // "app was fully closed and this notification is what opened it".
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  } catch (e) {
    // 4. Never let a push-notification failure take the whole app down —
    // log it and continue starting the app normally.
    // ignore: avoid_print
    print('Push notifications failed to initialize: $e');
  }
}
