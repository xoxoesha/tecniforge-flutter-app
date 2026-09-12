import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notifications_service.dart';

// ---------------------------------------------------------------------------
// TecniForge — Firebase Cloud Messaging (FCM)
//
// Handles:
// 1. Firebase initialization
// 2. Notification permission
// 3. FCM token + token refresh
// 4. Background messages
// 5. Foreground notifications
// 6. Notification taps from background
// 7. Notification taps that launch the app from a terminated state
// 8. Android notification channel
// 9. Graceful error handling
// ---------------------------------------------------------------------------

/// Global navigator key used when a notification is tapped.
final GlobalKey<NavigatorState> pushNavigatorKey =
GlobalKey<NavigatorState>();

/// Android notification channel used by FCM foreground notifications.
const AndroidNotificationChannel pushNotificationChannel =
AndroidNotificationChannel(
  'push_channel',
  'Push Notifications',
  description: 'Notifications received from Firebase Cloud Messaging',
  importance: Importance.high,
);

/// Background FCM handler.
///
/// This MUST be a top-level function because Firebase can execute it
/// in a separate background isolate.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  try {
    // Firebase must be initialized inside the background isolate.
    await Firebase.initializeApp();

    debugPrint(
      'Background FCM message received: ${message.messageId}',
    );

    debugPrint(
      'Background notification title: ${message.notification?.title}',
    );

    debugPrint(
      'Background notification body: ${message.notification?.body}',
    );

    debugPrint(
      'Background data: ${message.data}',
    );
  } catch (e) {
    debugPrint('Background FCM handler error: $e');
  }
}

/// Navigate to the Notifications screen when a push notification is tapped.
void _handleNotificationTap(RemoteMessage message) {
  debugPrint(
    'Notification tapped. Message ID: ${message.messageId}',
  );

  final navigator = pushNavigatorKey.currentState;

  if (navigator == null) {
    debugPrint('Navigator is not ready yet.');
    return;
  }

  navigator.pushNamed('/notifications');
}

/// Initializes Firebase Cloud Messaging.
Future<void> initPushNotifications() async {
  try {
    // -----------------------------------------------------------------------
    // 1. Initialize Firebase
    // -----------------------------------------------------------------------

    await Firebase.initializeApp();

    debugPrint('Firebase initialized successfully.');

    final messaging = FirebaseMessaging.instance;

    // -----------------------------------------------------------------------
    // 2. Create Android notification channel
    // -----------------------------------------------------------------------

    final androidPlugin = notificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(
      pushNotificationChannel,
    );

    // -----------------------------------------------------------------------
    // 3. Request notification permission
    // -----------------------------------------------------------------------

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint(
      'FCM authorization status: ${settings.authorizationStatus}',
    );

    final permissionGranted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;

    if (!permissionGranted) {
      debugPrint('FCM notification permission was not granted.');
      return;
    }

    // -----------------------------------------------------------------------
    // 4. Get current FCM token
    // -----------------------------------------------------------------------

    try {
      final token = await messaging.getToken();

      debugPrint('FCM device token: $token');
    } catch (e) {
      debugPrint('Unable to get FCM token: $e');
    }

    // -----------------------------------------------------------------------
    // 5. Handle token refresh
    // -----------------------------------------------------------------------

    FirebaseMessaging.instance.onTokenRefresh.listen(
          (newToken) {
        debugPrint('FCM token refreshed: $newToken');

        // In a production application, the refreshed token should
        // be sent to the application's backend/server here.
      },
      onError: (error) {
        debugPrint('FCM token refresh error: $error');
      },
    );

    // -----------------------------------------------------------------------
    // 6. Register background message handler
    // -----------------------------------------------------------------------

    FirebaseMessaging.onBackgroundMessage(
      firebaseBackgroundHandler,
    );

    // -----------------------------------------------------------------------
    // 7. Handle messages received while app is OPEN
    // -----------------------------------------------------------------------

    FirebaseMessaging.onMessage.listen(
          (RemoteMessage message) {
        debugPrint(
          'Foreground FCM message received: ${message.messageId}',
        );

        debugPrint(
          'Foreground data: ${message.data}',
        );

        final notification = message.notification;

        if (notification == null) {
          debugPrint(
            'Foreground message contains data only.',
          );
          return;
        }

        // Android does not automatically display the notification
        // while the Flutter app is in the foreground, so we display
        // it ourselves using flutter_local_notifications.

        notificationsPlugin.show(
          notification.hashCode,
          notification.title ?? 'TecniForge',
          notification.body ?? '',
          NotificationDetails(
            android: AndroidNotificationDetails(
              pushNotificationChannel.id,
              pushNotificationChannel.name,
              channelDescription:
              pushNotificationChannel.description,
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
              playSound: true,
            ),
          ),
          payload: message.data.toString(),
        );
      },
      onError: (error) {
        debugPrint('Foreground FCM listener error: $error');
      },
    );

    // -----------------------------------------------------------------------
    // 8. Handle notification tap when app is in background
    // -----------------------------------------------------------------------

    FirebaseMessaging.onMessageOpenedApp.listen(
          (RemoteMessage message) {
        debugPrint(
          'App opened from background notification.',
        );

        _handleNotificationTap(message);
      },
      onError: (error) {
        debugPrint(
          'Notification-open listener error: $error',
        );
      },
    );

    // -----------------------------------------------------------------------
    // 9. Handle notification tap when app was completely closed
    // -----------------------------------------------------------------------

    try {
      final initialMessage = await messaging.getInitialMessage();

      if (initialMessage != null) {
        debugPrint(
          'App launched from terminated-state notification.',
        );

        // Give Flutter a moment to finish building the navigator.
        WidgetsBinding.instance.addPostFrameCallback(
              (_) {
            _handleNotificationTap(initialMessage);
          },
        );
      }
    } catch (e) {
      debugPrint(
        'Unable to read initial FCM message: $e',
      );
    }

    debugPrint('FCM initialization completed successfully.');
  } catch (e) {
    // FCM failure should NOT prevent the rest of the app from starting.
    debugPrint(
      'FCM initialization failed: $e',
    );
  }
}