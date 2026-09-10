import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Background FCM message handler (must be a top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Gracefully handle background messages
  debugPrint('[FirebaseMessaging] Background message received: ${message.messageId}');
}

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  bool _firebaseEnabled = false;
  String? _fcmToken;

  Function(String route)? onNavigate;
  Function(String token)? onTokenRegistered;

  // Android Notification Channels
  static const String channelImportant = 'home_stock_important';
  static const String channelGeneral = 'home_stock_general';
  static const String channelInsights = 'home_stock_insights';

  static const AndroidNotificationChannel _channelImportantDef = AndroidNotificationChannel(
    channelImportant,
    'Important Alerts',
    description: 'Critical notifications: low stock, out of stock, expiring products',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static const AndroidNotificationChannel _channelGeneralDef = AndroidNotificationChannel(
    channelGeneral,
    'General Activity',
    description: 'Family activity, shopping list updates, purchases',
    importance: Importance.defaultImportance,
    playSound: true,
  );

  static const AndroidNotificationChannel _channelInsightsDef = AndroidNotificationChannel(
    channelInsights,
    'Insights & Reports',
    description: 'Smart restock recommendations, weekly insights, monthly reports',
    importance: Importance.low,
    playSound: false,
  );

  String? get fcmToken => _fcmToken;
  bool get isFirebaseEnabled => _firebaseEnabled;

  /// Initialize local notification channels and plugins.
  Future<void> initialize({
    Function(String route)? navigateCallback,
    Function(String token)? tokenCallback,
  }) async {
    if (_isInitialized) return;

    onNavigate = navigateCallback;
    onTokenRegistered = tokenCallback;

    try {
      tz.initializeTimeZones();
    } catch (e) {
      debugPrint('[NotificationService] Timezone init warning: $e');
    }

    // 1. Setup Flutter Local Notifications
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsDarwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handlePayload(response.payload);
      },
    );

    // 2. Create Android Channels
    final androidImplementation = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(_channelImportantDef);
      await androidImplementation.createNotificationChannel(_channelGeneralDef);
      await androidImplementation.createNotificationChannel(_channelInsightsDef);
    }

    // 3. Graceful Firebase Cloud Messaging Initialization
    await _initializeFirebase();

    _isInitialized = true;
    debugPrint('[NotificationService] Initialized successfully. Firebase enabled: $_firebaseEnabled');
  }

  Future<void> _initializeFirebase() async {
    try {
      // Check if Firebase is already initialized or can be initialized
      if (Firebase.apps.isEmpty) {
        // Will throw if google-services / config is missing on the platform
        await Firebase.initializeApp();
      }

      _firebaseEnabled = true;

      // Setup background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Listen to foreground FCM messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[NotificationService] Foreground FCM message: ${message.notification?.title}');
        _showForegroundFcmNotification(message);
      });

      // Handle notification opened app
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[NotificationService] Notification opened app: ${message.data}');
        _handleFcmData(message.data);
      });

      // Check if app was opened from a terminated notification state
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _handleFcmData(initialMessage.data);
      }

      // Fetch FCM Token
      _fcmToken = await FirebaseMessaging.instance.getToken();
      if (_fcmToken != null) {
        debugPrint('[NotificationService] FCM Token acquired: ${_fcmToken!.substring(0, 10)}...');
        onTokenRegistered?.call(_fcmToken!);
      }

      // Listen for token refreshes
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        onTokenRegistered?.call(newToken);
      });
    } catch (e) {
      _firebaseEnabled = false;
      debugPrint('[Firebase] Service account not configured. Operating in mock/local mode: $e');
    }
  }

  /// Request runtime notification permissions from user (Android 13+ & iOS).
  Future<bool> requestPermissions() async {
    bool granted = false;

    // Local notifications permission (Android 13+)
    final androidImpl = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      final androidGranted = await androidImpl.requestNotificationsPermission();
      granted = androidGranted ?? false;
    }

    // iOS local notification permissions
    final iosImpl = _localNotifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosImpl != null) {
      final iosGranted = await iosImpl.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      granted = iosGranted ?? false;
    }

    // Firebase Messaging permissions (if available)
    if (_firebaseEnabled) {
      try {
        final settings = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );
        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          granted = true;
        }
      } catch (_) {}
    }

    return granted;
  }

  /// Check whether notification permissions are currently enabled.
  Future<bool> areNotificationsEnabled() async {
    final androidImpl = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      return await androidImpl.areNotificationsEnabled() ?? false;
    }
    return true;
  }

  /// Display a local heads-up notification immediately.
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? channelId,
    String? payload,
  }) async {
    final selectedChannelId = channelId ?? channelImportant;

    AndroidNotificationDetails androidDetails;
    if (selectedChannelId == channelImportant) {
      androidDetails = const AndroidNotificationDetails(
        channelImportant,
        'Important Alerts',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      );
    } else if (selectedChannelId == channelInsights) {
      androidDetails = const AndroidNotificationDetails(
        channelInsights,
        'Insights & Reports',
        importance: Importance.low,
        priority: Priority.low,
        showWhen: true,
      );
    } else {
      androidDetails = const AndroidNotificationDetails(
        channelGeneral,
        'General Activity',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        showWhen: true,
      );
    }

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Schedule a local notification offline using timezone.
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? channelId,
    String? payload,
  }) async {
    final tzScheduled = tz.TZDateTime.from(scheduledDate, tz.local);
    if (tzScheduled.isBefore(tz.TZDateTime.now(tz.local))) return;

    final selectedChannelId = channelId ?? channelGeneral;
    final androidDetails = AndroidNotificationDetails(
      selectedChannelId,
      selectedChannelId == channelImportant
          ? 'Important Alerts'
          : selectedChannelId == channelInsights
              ? 'Insights & Reports'
              : 'General Activity',
      importance: selectedChannelId == channelImportant ? Importance.max : Importance.defaultImportance,
      priority: selectedChannelId == channelImportant ? Priority.high : Priority.defaultPriority,
    );

    const iosDetails = DarwinNotificationDetails();

    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      tzScheduled,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  /// Cancel a specific notification by ID.
  Future<void> cancel(int id) async {
    await _localNotifications.cancel(id);
  }

  /// Cancel all scheduled notifications.
  Future<void> cancelAll() async {
    await _localNotifications.cancelAll();
  }

  void _showForegroundFcmNotification(RemoteMessage message) {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] ?? 'HomeStock';
    final body = notification?.body ?? message.data['body'] ?? '';
    final type = message.data['type']?.toString().toUpperCase() ?? 'SYSTEM';

    String channel = channelGeneral;
    if (type.contains('STOCK') || type.contains('EXPIR')) {
      channel = channelImportant;
    } else if (type.contains('INSIGHT') || type.contains('REPORT') || type.contains('RESTOCK')) {
      channel = channelInsights;
    }

    final payload = jsonEncode(message.data);
    final id = message.messageId.hashCode;

    showNotification(
      id: id,
      title: title,
      body: body,
      channelId: channel,
      payload: payload,
    );
  }

  void _handleFcmData(Map<String, dynamic> data) {
    final payload = jsonEncode(data);
    _handlePayload(payload);
  }

  void _handlePayload(String? payload) {
    if (payload == null || payload.isEmpty) {
      onNavigate?.call('/notifications');
      return;
    }

    try {
      final map = jsonDecode(payload) as Map<String, dynamic>;
      final itemId = map['itemId']?.toString();
      final screen = map['screen']?.toString();

      if (itemId != null && itemId.isNotEmpty) {
        onNavigate?.call('/inventory/detail/$itemId');
      } else if (screen == 'shopping') {
        onNavigate?.call('/shopping');
      } else if (screen == 'analytics') {
        onNavigate?.call('/analytics');
      } else {
        onNavigate?.call('/notifications');
      }
    } catch (_) {
      onNavigate?.call('/notifications');
    }
  }
}
