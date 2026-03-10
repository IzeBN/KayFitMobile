import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../api/api_client.dart';

// ---------------------------------------------------------------------------
// Background message handler — must be a top-level function
// ---------------------------------------------------------------------------

/// Handles messages received when the app is in the background / terminated.
/// Firebase displays the notification automatically; we only need to ensure
/// Firebase is initialised so the isolate can process data payloads if needed.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM] background message: ${message.messageId}');
}

// ---------------------------------------------------------------------------
// Notification channel constants
// ---------------------------------------------------------------------------

const _kChannelId = 'kayfit_channel';
const _kChannelName = 'Kayfit';
const _kChannelDescription = 'Kayfit notifications';

// ---------------------------------------------------------------------------
// NotificationService
// ---------------------------------------------------------------------------

/// Centralised push-notification service.
///
/// Call [NotificationService.init] once from [main] after
/// [WidgetsFlutterBinding.ensureInitialized].  The service is intentionally
/// written as a collection of static helpers so it does not need to be
/// injected via DI — it is infrastructure-level code called at app start.
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  // Navigation callback — set by the app shell when the router is ready.
  static void Function(String route)? _onNavigate;

  /// Register a callback that the service uses to navigate when the user taps
  /// a notification.  Call this once the [GoRouter] instance is available.
  static void setNavigationCallback(void Function(String route) cb) {
    _onNavigate = cb;
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Initialises Firebase, requests permissions, registers the FCM token with
  /// the backend, and wires up all message handlers.
  ///
  /// Wrapped in try-catch so a missing `google-services.json` /
  /// `GoogleService-Info.plist` does NOT crash the app during development.
  static Future<void> init() async {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      await _initLocalNotifications();
      await _requestPermissions();
      _setupForegroundHandler();
      _setupNotificationTapHandler();
      _setupTokenRefresh();

      debugPrint('[FCM] NotificationService initialised');
    } catch (e) {
      // Firebase not configured (missing config files) — continue without push.
      debugPrint('[FCM] init skipped (Firebase not configured): $e');
    }
  }

  /// Registers the FCM token with the backend.
  /// Call this after a successful login when the auth token is already stored.
  static Future<void> registerTokenAfterLogin() async {
    try {
      await _registerToken();
    } catch (e) {
      debugPrint('[FCM] registerTokenAfterLogin error (ignored): $e');
    }
  }

  /// Unregisters the FCM token from the backend and deletes it locally.
  /// Call this during logout so the user stops receiving notifications.
  static Future<void> unregisterToken() async {
    try {
      await apiDio.delete('/api/devices/token');
      await FirebaseMessaging.instance.deleteToken();
      debugPrint('[FCM] token unregistered');
    } catch (e) {
      debugPrint('[FCM] unregisterToken error (ignored): $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static Future<void> _requestPermissions() async {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] permission status: ${settings.authorizationStatus}');

    // Android 13+ (API 33) POST_NOTIFICATIONS — flutter_local_notifications
    // handles the runtime permission request when showing the first notification.
    if (Platform.isAndroid) {
      await _localNotif
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  static Future<void> _registerToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _sendTokenToBackend(token);
    }
  }

  static void _setupTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen(
      _sendTokenToBackend,
      onError: (e) => debugPrint('[FCM] onTokenRefresh error: $e'),
    );
  }

  static Future<void> _sendTokenToBackend(String token) async {
    try {
      await apiDio.post('/api/devices/register', data: {
        'token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
      });
      debugPrint('[FCM] token registered with backend');
    } catch (e) {
      // Silently fail — will retry on next app start / token rotation.
      debugPrint('[FCM] token registration failed (ignored): $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Local notifications setup
  // ---------------------------------------------------------------------------

  static Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // we handle this via FirebaseMessaging
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotif.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // Create the high-importance Android notification channel.
    const channel = AndroidNotificationChannel(
      _kChannelId,
      _kChannelName,
      description: _kChannelDescription,
      importance: Importance.high,
    );
    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // ---------------------------------------------------------------------------
  // Message handlers
  // ---------------------------------------------------------------------------

  static void _setupForegroundHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;

      _showLocalNotification(
        title: notification.title ?? '',
        body: notification.body ?? '',
        data: message.data,
      );
    });
  }

  /// Handles taps on notifications that opened / resumed the app.
  static void _setupNotificationTapHandler() {
    // App opened from a terminated state via notification.
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null) {
        _handleNotificationTap(message.data);
      }
    });

    // App resumed from background via notification.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message.data);
    });
  }

  static void _onLocalNotificationTap(NotificationResponse response) {
    final type = response.payload;
    _handleNotificationTap({'type': type ?? ''});
  }

  static void _handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'] as String? ?? '';
    final route = switch (type) {
      'daily_reminder' => '/',
      'streak' => '/',
      'weekly_summary' => '/journal',
      _ => '/',
    };
    _onNavigate?.call(route);
  }

  // ---------------------------------------------------------------------------
  // Show local notification (foreground)
  // ---------------------------------------------------------------------------

  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _kChannelId,
      _kChannelName,
      channelDescription: _kChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotif.show(
      // Use a stable ID — collisions replace the previous notification which
      // is acceptable for simple reminder-style messages.
      data['type'].hashCode,
      title,
      body,
      details,
      payload: data['type'] as String?,
    );
  }
}
