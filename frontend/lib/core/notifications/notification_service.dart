import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Style configuration for custom notification card preview in system tray
class NotificationCardStyle {
  final String emoji;
  final String badgeText;
  final Color accentColor;
  final String groupKey;
  final int groupSummaryId;
  final String groupTitle;
  final String channelId;
  final String channelName;
  final String channelDescription;
  final Importance importance;
  final Priority priority;
  final List<AndroidNotificationAction> actions;

  const NotificationCardStyle({
    required this.emoji,
    required this.badgeText,
    required this.accentColor,
    required this.groupKey,
    required this.groupSummaryId,
    required this.groupTitle,
    required this.channelId,
    required this.channelName,
    required this.channelDescription,
    required this.importance,
    required this.priority,
    required this.actions,
  });
}

/// Helper that resolves notification card preview styling and grouping
/// matching the signature HomeStock theme.
class NotificationCardStyler {
  static const String groupStockExpiry = 'homestock_group_stock_expiry';
  static const String groupActivity = 'homestock_group_activity';
  static const String groupInsights = 'homestock_group_insights';

  static const int groupStockExpirySummaryId = 9901;
  static const int groupActivitySummaryId = 9902;
  static const int groupInsightsSummaryId = 9903;

  /// Resolve styling, category badges, accent colors, emojis, and actions
  static NotificationCardStyle resolve({
    String? type,
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) {
    final effectiveType = (type ?? payload?['type']?.toString() ?? 'SYSTEM').toUpperCase();
    final lowerContent = '$title $body'.toLowerCase();

    // 1. Food / item emoji detection
    String emoji = '📦';
    if (payload?['emoji'] != null && payload!['emoji'].toString().isNotEmpty) {
      emoji = payload['emoji'].toString();
    } else if (lowerContent.contains('milk') || lowerContent.contains('பால்')) {
      emoji = '🥛';
    } else if (lowerContent.contains('egg') || lowerContent.contains('முட்டை')) {
      emoji = '🥚';
    } else if (lowerContent.contains('onion') || lowerContent.contains('வெங்காயம்')) {
      emoji = '🧅';
    } else if (lowerContent.contains('rice') || lowerContent.contains('அரிசி')) {
      emoji = '🍚';
    } else if (lowerContent.contains('cheese')) {
      emoji = '🧀';
    } else if (lowerContent.contains('bread') || lowerContent.contains('ரொட்டி')) {
      emoji = '🍞';
    } else if (lowerContent.contains('oil') || lowerContent.contains('எண்ணெய்')) {
      emoji = '🌻';
    } else if (lowerContent.contains('atta') || lowerContent.contains('flour') || lowerContent.contains('மாவு')) {
      emoji = '🌾';
    } else if (lowerContent.contains('tomato') || lowerContent.contains('தக்காளி')) {
      emoji = '🍅';
    } else if (lowerContent.contains('apple') || lowerContent.contains('fruit')) {
      emoji = '🍎';
    } else if (lowerContent.contains('banana')) {
      emoji = '🍌';
    } else if (lowerContent.contains('coffee') || lowerContent.contains('tea')) {
      emoji = '☕';
    } else if (lowerContent.contains('soap') || lowerContent.contains('detergent')) {
      emoji = '🧼';
    }

    final isDigest = payload?['isDigest']?.toString().toLowerCase() == 'true' ||
        (payload?['itemCount'] != null && int.tryParse(payload!['itemCount'].toString()) != null && int.parse(payload['itemCount'].toString()) > 1) ||
        lowerContent.contains('items may run out') ||
        lowerContent.contains('restock digest');

    // 2. Map category, badges, colors, and actions
    switch (effectiveType) {
      case 'OUT_OF_STOCK':
        return NotificationCardStyle(
          emoji: emoji == '📦' ? '🔴' : emoji,
          badgeText: payload?['badge']?.toString() ?? '🔴 OUT OF STOCK',
          accentColor: const Color(0xFFDC2626),
          groupKey: groupStockExpiry,
          groupSummaryId: groupStockExpirySummaryId,
          groupTitle: 'Stock & Expiry Alerts',
          channelId: NotificationService.channelImportant,
          channelName: 'Important Alerts',
          channelDescription: 'Critical notifications: low stock, out of stock, expiring products',
          importance: Importance.max,
          priority: Priority.high,
          actions: const [
            AndroidNotificationAction('action_shopping', '+ Add to Shopping', showsUserInterface: true),
            AndroidNotificationAction('action_inspect', 'Inspect Item', showsUserInterface: true),
          ],
        );

      case 'LOW_STOCK':
        return NotificationCardStyle(
          emoji: emoji == '📦' ? '⚠️' : emoji,
          badgeText: payload?['badge']?.toString() ?? '⚠️ LOW STOCK',
          accentColor: const Color(0xFFD97706),
          groupKey: groupStockExpiry,
          groupSummaryId: groupStockExpirySummaryId,
          groupTitle: 'Stock & Expiry Alerts',
          channelId: NotificationService.channelImportant,
          channelName: 'Important Alerts',
          channelDescription: 'Critical notifications: low stock, out of stock, expiring products',
          importance: Importance.max,
          priority: Priority.high,
          actions: const [
            AndroidNotificationAction('action_shopping', '+ Add to Shopping', showsUserInterface: true),
            AndroidNotificationAction('action_inspect', 'Inspect Item', showsUserInterface: true),
          ],
        );

      case 'EXPIRING_SOON':
      case 'EXPIRY_REMINDER':
        return NotificationCardStyle(
          emoji: emoji == '📦' ? '⏳' : emoji,
          badgeText: payload?['badge']?.toString() ?? '⏳ EXPIRING SOON',
          accentColor: const Color(0xFFEA580C),
          groupKey: groupStockExpiry,
          groupSummaryId: groupStockExpirySummaryId,
          groupTitle: 'Stock & Expiry Alerts',
          channelId: NotificationService.channelImportant,
          channelName: 'Important Alerts',
          channelDescription: 'Critical notifications: low stock, out of stock, expiring products',
          importance: Importance.max,
          priority: Priority.high,
          actions: const [
            AndroidNotificationAction('action_inspect', 'Inspect Item', showsUserInterface: true),
            AndroidNotificationAction('action_shopping', '+ Add to Shopping', showsUserInterface: true),
          ],
        );

      case 'EXPIRED':
        return NotificationCardStyle(
          emoji: emoji == '📦' ? '⏰' : emoji,
          badgeText: payload?['badge']?.toString() ?? '⏰ EXPIRED',
          accentColor: const Color(0xFFDC2626),
          groupKey: groupStockExpiry,
          groupSummaryId: groupStockExpirySummaryId,
          groupTitle: 'Stock & Expiry Alerts',
          channelId: NotificationService.channelImportant,
          channelName: 'Important Alerts',
          channelDescription: 'Critical notifications: low stock, out of stock, expiring products',
          importance: Importance.max,
          priority: Priority.high,
          actions: const [
            AndroidNotificationAction('action_inspect', 'Inspect Item', showsUserInterface: true),
          ],
        );

      case 'SHOPPING_LIST_UPDATE':
        return NotificationCardStyle(
          emoji: '🛒',
          badgeText: payload?['badge']?.toString() ?? '🛒 SHOPPING LIST',
          accentColor: const Color(0xFF7C3AED),
          groupKey: groupActivity,
          groupSummaryId: groupActivitySummaryId,
          groupTitle: 'Household Activity',
          channelId: NotificationService.channelGeneral,
          channelName: 'General Activity',
          channelDescription: 'Family activity, shopping list updates, purchases',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          actions: const [
            AndroidNotificationAction('action_shopping', 'View Shopping List', showsUserInterface: true),
          ],
        );

      case 'STOCK_UPDATED':
      case 'PURCHASE_RECORDED':
        return NotificationCardStyle(
          emoji: '✓',
          badgeText: payload?['badge']?.toString() ?? '✓ RESTOCKED',
          accentColor: const Color(0xFF16A34A),
          groupKey: groupActivity,
          groupSummaryId: groupActivitySummaryId,
          groupTitle: 'Household Activity',
          channelId: NotificationService.channelGeneral,
          channelName: 'General Activity',
          channelDescription: 'Family activity, shopping list updates, purchases',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          actions: const [
            AndroidNotificationAction('action_inspect', 'View Item', showsUserInterface: true),
          ],
        );

      case 'SYNC_COMPLETED':
        return NotificationCardStyle(
          emoji: '☁️',
          badgeText: payload?['badge']?.toString() ?? '☁️ SYNCED',
          accentColor: const Color(0xFF16A34A),
          groupKey: groupActivity,
          groupSummaryId: groupActivitySummaryId,
          groupTitle: 'Household Activity',
          channelId: NotificationService.channelGeneral,
          channelName: 'General Activity',
          channelDescription: 'Family activity, shopping list updates, purchases',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          actions: const [],
        );

      case 'SMART_RESTOCK_SUGGESTION':
        if (isDigest) {
          return NotificationCardStyle(
            emoji: '🛒',
            badgeText: payload?['badge']?.toString() ?? '🛒 RESTOCK DIGEST',
            accentColor: const Color(0xFF6366F1),
            groupKey: groupInsights,
            groupSummaryId: groupInsightsSummaryId,
            groupTitle: 'Smart Insights & Digests',
            channelId: NotificationService.channelInsights,
            channelName: 'Insights & Reports',
            channelDescription: 'Smart restock recommendations, weekly insights, monthly reports',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            actions: const [
              AndroidNotificationAction('action_shopping', 'View Shopping List', showsUserInterface: true),
            ],
          );
        }
        return NotificationCardStyle(
          emoji: '✨',
          badgeText: payload?['badge']?.toString() ?? '✨ SMART INSIGHT',
          accentColor: const Color(0xFF6366F1),
          groupKey: groupInsights,
          groupSummaryId: groupInsightsSummaryId,
          groupTitle: 'Smart Insights & Digests',
          channelId: NotificationService.channelInsights,
          channelName: 'Insights & Reports',
          channelDescription: 'Smart restock recommendations, weekly insights, monthly reports',
          importance: Importance.low,
          priority: Priority.low,
          actions: const [
            AndroidNotificationAction('action_shopping', '+ Add to Shopping', showsUserInterface: true),
            AndroidNotificationAction('action_insights', 'View Insights', showsUserInterface: true),
          ],
        );

      case 'WEEKLY_INSIGHT':
      case 'MONTHLY_REPORT':
        return NotificationCardStyle(
          emoji: '📊',
          badgeText: payload?['badge']?.toString() ?? '📊 REPORT',
          accentColor: const Color(0xFF6366F1),
          groupKey: groupInsights,
          groupSummaryId: groupInsightsSummaryId,
          groupTitle: 'Smart Insights & Digests',
          channelId: NotificationService.channelInsights,
          channelName: 'Insights & Reports',
          channelDescription: 'Smart restock recommendations, weekly insights, monthly reports',
          importance: Importance.low,
          priority: Priority.low,
          actions: const [
            AndroidNotificationAction('action_insights', 'View Report', showsUserInterface: true),
          ],
        );

      case 'FAMILY_ACTIVITY':
      case 'SYSTEM':
      default:
        return NotificationCardStyle(
          emoji: '🏠',
          badgeText: payload?['badge']?.toString() ?? '🏠 HOUSEHOLD',
          accentColor: const Color(0xFF0284C7),
          groupKey: groupActivity,
          groupSummaryId: groupActivitySummaryId,
          groupTitle: 'Household Activity',
          channelId: NotificationService.channelGeneral,
          channelName: 'General Activity',
          channelDescription: 'Family activity, shopping list updates, purchases',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          actions: const [
            AndroidNotificationAction('action_open', 'Open HomeStock', showsUserInterface: true),
          ],
        );
    }
  }
}

/// Background FCM message handler (must be a top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FirebaseMessaging] Background message received: ${message.messageId}');
  try {
    final type = message.data['type']?.toString().toUpperCase() ?? 'SYSTEM';
    if (type == 'HOME_CHANGED' || type == 'SILENT_SYNC') {
      return; // Silent sync handled separately
    }

    // When message is data-only (or notification not automatically shown by OS),
    // render our signature card preview notification!
    if (message.notification == null) {
      final plugin = FlutterLocalNotificationsPlugin();
      const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initializationSettingsDarwin = DarwinInitializationSettings();
      await plugin.initialize(const InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      ));

      final title = message.data['title']?.toString() ?? 'HomeStock Alert';
      final body = message.data['body']?.toString() ?? 'Your stock was updated.';
      final payload = jsonEncode(message.data);
      final id = message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch;

      final style = NotificationCardStyler.resolve(
        type: type,
        title: title,
        body: body,
        payload: message.data,
      );

      final styledTitle = '${style.emoji} $title';
      final bigTextStyle = BigTextStyleInformation(
        body,
        contentTitle: styledTitle,
        summaryText: style.badgeText,
      );

      final androidDetails = AndroidNotificationDetails(
        style.channelId,
        style.channelName,
        channelDescription: style.channelDescription,
        importance: style.importance,
        priority: style.priority,
        color: style.accentColor,
        styleInformation: bigTextStyle,
        groupKey: style.groupKey,
        setAsGroupSummary: false,
        actions: style.actions,
      );

      await plugin.show(
        id,
        styledTitle,
        body,
        NotificationDetails(android: androidDetails),
        payload: payload,
      );
    }
  } catch (e) {
    debugPrint('[FirebaseMessaging] Background message error: $e');
  }
}

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  bool _firebaseEnabled = false;
  String? _fcmToken;

  // Track recent alert titles per group for expandable inbox group summaries
  final Map<String, List<String>> _groupRecentLines = {};

  Function(String route)? onNavigate;
  Function(String token)? onTokenRegistered;

  /// Called when a HOME_CHANGED silent data push arrives.
  /// The callback receives the homeId to sync.
  Function(String homeId)? onSilentSyncTriggered;

  /// Called when a notification is tapped (foreground, background, terminated).
  /// Receives the raw payload map for the NotificationRouter to handle.
  Function(Map<String, dynamic> payload)? onPayloadTapped;

  /// Called when a foreground notification is received from Firebase
  /// to display the interactive in-app notification card matching the project theme.
  Function(String title, String body, Map<String, dynamic> data)? onForegroundNotificationReceived;

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
    Function(String homeId)? silentSyncCallback,
    Function(Map<String, dynamic> payload)? payloadTapCallback,
    Function(String title, String body, Map<String, dynamic> data)? foregroundNotificationCallback,
  }) async {
    if (_isInitialized) return;

    onNavigate = navigateCallback;
    onTokenRegistered = tokenCallback;
    onSilentSyncTriggered = silentSyncCallback;
    onPayloadTapped = payloadTapCallback;
    onForegroundNotificationReceived = foregroundNotificationCallback;

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
        _handleNotificationResponse(response);
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
    try {
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
    } catch (_) {}

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
    try {
      final androidImpl = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        return await androidImpl.areNotificationsEnabled() ?? false;
      }
    } catch (_) {}
    return true;
  }

  /// Display a notification styled with signature notification card preview
  /// (semantic pill badge, category accent color, food emoji, action buttons,
  /// and expandable Android notification group summary).
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? channelId,
    String? payload,
    String? type,
  }) async {
    Map<String, dynamic>? payloadMap;
    if (payload != null && payload.isNotEmpty) {
      try {
        payloadMap = jsonDecode(payload) as Map<String, dynamic>;
      } catch (_) {}
    }

    final style = NotificationCardStyler.resolve(
      type: type ?? payloadMap?['type']?.toString(),
      title: title,
      body: body,
      payload: payloadMap,
    );

    final styledTitle = '${style.emoji} $title';

    // Rich BigTextStyle representing the in-app notification card preview
    final bigTextStyle = BigTextStyleInformation(
      body,
      contentTitle: styledTitle,
      summaryText: style.badgeText,
      htmlFormatContentTitle: false,
      htmlFormatBigText: false,
      htmlFormatSummaryText: false,
    );

    final selectedChannelId = channelId ?? style.channelId;

    final androidDetails = AndroidNotificationDetails(
      selectedChannelId,
      style.channelName,
      channelDescription: style.channelDescription,
      importance: style.importance,
      priority: style.priority,
      color: style.accentColor,
      styleInformation: bigTextStyle,
      groupKey: style.groupKey,
      setAsGroupSummary: false,
      actions: style.actions,
      showWhen: true,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      subtitle: style.badgeText,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id,
      styledTitle,
      body,
      notificationDetails,
      payload: payload,
    );

    // Update active Android group summary notification with inbox stack
    await _updateGroupSummaryNotification(style);
  }

  /// Update the active Android group summary notification with an expandable inbox stack
  Future<void> _updateGroupSummaryNotification(NotificationCardStyle style) async {
    try {
      final list = _groupRecentLines.putIfAbsent(style.groupKey, () => []);
      list.add('${style.emoji} ${style.badgeText}');
      if (list.length > 7) {
        list.removeAt(0);
      }

      final inboxStyle = InboxStyleInformation(
        list,
        contentTitle: style.groupTitle,
        summaryText: '${list.length} active alerts',
      );

      final summaryAndroid = AndroidNotificationDetails(
        style.channelId,
        style.channelName,
        channelDescription: style.channelDescription,
        importance: style.importance,
        priority: style.priority,
        color: style.accentColor,
        styleInformation: inboxStyle,
        groupKey: style.groupKey,
        setAsGroupSummary: true,
      );

      await _localNotifications.show(
        style.groupSummaryId,
        style.groupTitle,
        '${list.length} active alerts',
        NotificationDetails(android: summaryAndroid),
      );
    } catch (e) {
      debugPrint('[NotificationService] Group summary update notice: $e');
    }
  }

  /// Schedule a local notification offline using timezone.
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? channelId,
    String? payload,
    String? type,
  }) async {
    final tzScheduled = tz.TZDateTime.from(scheduledDate, tz.local);
    if (tzScheduled.isBefore(tz.TZDateTime.now(tz.local))) return;

    Map<String, dynamic>? payloadMap;
    if (payload != null && payload.isNotEmpty) {
      try {
        payloadMap = jsonDecode(payload) as Map<String, dynamic>;
      } catch (_) {}
    }

    final style = NotificationCardStyler.resolve(
      type: type ?? payloadMap?['type']?.toString(),
      title: title,
      body: body,
      payload: payloadMap,
    );

    final styledTitle = '${style.emoji} $title';
    final bigTextStyle = BigTextStyleInformation(
      body,
      contentTitle: styledTitle,
      summaryText: style.badgeText,
    );

    final selectedChannelId = channelId ?? style.channelId;
    final androidDetails = AndroidNotificationDetails(
      selectedChannelId,
      style.channelName,
      importance: style.importance,
      priority: style.priority,
      color: style.accentColor,
      styleInformation: bigTextStyle,
      groupKey: style.groupKey,
      setAsGroupSummary: false,
      actions: style.actions,
    );

    const iosDetails = DarwinNotificationDetails();

    await _localNotifications.zonedSchedule(
      id,
      styledTitle,
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
    _groupRecentLines.clear();
    await _localNotifications.cancelAll();
  }

  void _showForegroundFcmNotification(RemoteMessage message) {
    final notification = message.notification;
    final type = message.data['type']?.toString().toUpperCase() ?? 'SYSTEM';
    final homeId = message.data['homeId']?.toString();

    // Trigger sync for home change events (strictly silent background event)
    if (type == 'HOME_CHANGED' || type == 'SILENT_SYNC') {
      if (homeId != null && homeId.isNotEmpty) {
        debugPrint('[NotificationService] Silent background sync triggered for home: $homeId');
        onSilentSyncTriggered?.call(homeId);
      }
      return; // NEVER show a notification banner or card for background sync
    }

    final title = notification?.title ?? message.data['title'] ?? 'HomeStock';
    final body = notification?.body ?? message.data['body'] ?? 'Your household stock was updated.';

    final payload = jsonEncode(message.data);
    final id = message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch;

    // Show system notification matching the signature card preview style
    showNotification(
      id: id,
      title: title,
      body: body,
      payload: payload,
      type: type,
    );

    // Present the in-app foreground notification card matching the project theme
    onForegroundNotificationReceived?.call(title, body, message.data);
  }

  void _handleFcmData(Map<String, dynamic> data) {
    // Handle silent sync data-only messages
    final type = data['type']?.toString().toUpperCase() ?? '';
    if (type == 'HOME_CHANGED' || type == 'SILENT_SYNC') {
      final homeId = data['homeId']?.toString();
      if (homeId != null && homeId.isNotEmpty) {
        onSilentSyncTriggered?.call(homeId);
      }
      return;
    }

    // Prefer structured payload routing via NotificationRouter
    if (onPayloadTapped != null) {
      onPayloadTapped!(data);
      return;
    }

    // Legacy fallback
    final payload = jsonEncode(data);
    _handlePayload(payload);
  }

  void _handleNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    final actionId = response.actionId;

    if (payload == null || payload.isEmpty) {
      if (actionId == 'action_shopping') {
        onNavigate?.call('/shopping');
      } else {
        onNavigate?.call('/notifications');
      }
      return;
    }

    try {
      final map = jsonDecode(payload) as Map<String, dynamic>;
      if (actionId != null && actionId.isNotEmpty) {
        map['actionId'] = actionId;
      }

      if (onPayloadTapped != null) {
        onPayloadTapped!(map);
        return;
      }

      _handlePayloadMap(map, actionId);
    } catch (_) {
      onNavigate?.call('/notifications');
    }
  }

  void _handlePayload(String? payload) {
    if (payload == null || payload.isEmpty) {
      onNavigate?.call('/notifications');
      return;
    }

    try {
      final map = jsonDecode(payload) as Map<String, dynamic>;
      if (onPayloadTapped != null) {
        onPayloadTapped!(map);
        return;
      }
      _handlePayloadMap(map, null);
    } catch (_) {
      onNavigate?.call('/notifications');
    }
  }

  void _handlePayloadMap(Map<String, dynamic> map, String? actionId) {
    final entityId = map['entityId']?.toString() ?? map['itemId']?.toString();
    final screen = map['screen']?.toString();
    final type = (map['type']?.toString() ?? '').toUpperCase();

    if (actionId == 'action_shopping') {
      onNavigate?.call('/shopping');
      return;
    } else if (actionId == 'action_inspect' && entityId != null && entityId.isNotEmpty) {
      onNavigate?.call('/inventory/detail/$entityId');
      return;
    }

    if (entityId != null && entityId.isNotEmpty &&
        (type.contains('STOCK') || type.contains('EXPIR') || type == 'SMART_RESTOCK_SUGGESTION')) {
      onNavigate?.call('/inventory/detail/$entityId');
    } else if (screen == 'shopping' || type == 'SHOPPING_LIST_UPDATE') {
      onNavigate?.call('/shopping');
    } else if (screen == 'analytics' || type.contains('INSIGHT') || type.contains('REPORT')) {
      onNavigate?.call('/analytics');
    } else {
      onNavigate?.call('/notifications');
    }
  }
}
