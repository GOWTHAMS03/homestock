import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homestock/core/database/app_database.dart';
import 'package:homestock/core/database/daos/inventory_dao.dart';
import 'package:homestock/core/database/daos/notification_dao.dart';
import 'package:homestock/core/notifications/local_notification_engine.dart';
import 'package:homestock/core/notifications/notification_service.dart';
import 'package:homestock/features/notifications/notification_model.dart';
import 'package:homestock/features/notifications/notification_preference_model.dart';

class MockNotificationService implements NotificationService {
  final List<Map<String, dynamic>> displayedNotifications = [];

  @override
  String? get fcmToken => null;

  @override
  bool get isFirebaseEnabled => false;

  @override
  Function(String p1)? onNavigate;

  @override
  Function(String p1)? onTokenRegistered;

  @override
  Future<void> initialize({
    Function(String route)? navigateCallback,
    Function(String token)? tokenCallback,
  }) async {}

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<bool> areNotificationsEnabled() async => true;

  @override
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? channelId,
    String? payload,
  }) async {
    displayedNotifications.add({
      'id': id,
      'title': title,
      'body': body,
      'channelId': channelId,
      'payload': payload,
    });
  }

  @override
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? channelId,
    String? payload,
  }) async {}

  @override
  Future<void> cancel(int id) async {}

  @override
  Future<void> cancelAll() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationModel Tests', () {
    test('parses all 12 types correctly from string', () {
      expect(NotificationType.fromString('LOW_STOCK'), NotificationType.lowStock);
      expect(NotificationType.fromString('OUT_OF_STOCK'), NotificationType.outOfStock);
      expect(NotificationType.fromString('EXPIRY_REMINDER'), NotificationType.expiryReminder);
      expect(NotificationType.fromString('SHOPPING_LIST_UPDATE'), NotificationType.shoppingListUpdate);
      expect(NotificationType.fromString('FAMILY_ACTIVITY'), NotificationType.familyActivity);
      expect(NotificationType.fromString('PURCHASE_RECORDED'), NotificationType.purchaseRecorded);
      expect(NotificationType.fromString('STOCK_UPDATED'), NotificationType.stockUpdated);
      expect(NotificationType.fromString('SMART_RESTOCK_SUGGESTION'), NotificationType.smartRestockSuggestion);
      expect(NotificationType.fromString('WEEKLY_INSIGHT'), NotificationType.weeklyInsight);
      expect(NotificationType.fromString('MONTHLY_REPORT'), NotificationType.monthlyReport);
      expect(NotificationType.fromString('SYNC_COMPLETED'), NotificationType.syncCompleted);
      expect(NotificationType.fromString('SYSTEM'), NotificationType.system);
    });

    test('backward compatibility aliases map to EXPIRY_REMINDER', () {
      expect(NotificationType.fromString('EXPIRING_SOON'), NotificationType.expiryReminder);
      expect(NotificationType.fromString('EXPIRED'), NotificationType.expiryReminder);
    });

    test('parses priority and payload correctly', () {
      final model = NotificationModel.fromJson({
        'id': 'notif-1',
        'homeId': 'home-1',
        'type': 'LOW_STOCK',
        'priority': 'HIGH',
        'title': 'Low Milk',
        'body': 'Only 1 liter left',
        'payloadJson': jsonEncode({'itemId': 'item-123', 'screen': 'inventory_detail'}),
        'isRead': false,
        'createdAt': DateTime.now().toIso8601String(),
      });

      expect(model.typedType, NotificationType.lowStock);
      expect(model.typedPriority, NotificationPriority.high);
      expect(model.targetItemId, 'item-123');
      expect(model.targetScreen, 'inventory_detail');
      expect(model.isRead, false);
    });
  });

  group('NotificationPreferenceModel Tests', () {
    test('default values are properly set', () {
      const prefs = NotificationPreferenceModel();
      expect(prefs.lowStockEnabled, true);
      expect(prefs.outOfStockEnabled, true);
      expect(prefs.expiryEnabled, true);
      expect(prefs.quietHoursEnabled, false);
      expect(prefs.startTimeOfDay, const TimeOfDay(hour: 22, minute: 0));
      expect(prefs.endTimeOfDay, const TimeOfDay(hour: 7, minute: 0));
    });

    test('toJson and fromJson preserve preferences', () {
      const original = NotificationPreferenceModel(
        lowStockEnabled: false,
        outOfStockEnabled: true,
        quietHoursEnabled: true,
        quietHoursStart: '23:30:00',
        quietHoursEnd: '06:15:00',
      );

      final json = original.toJson();
      final restored = NotificationPreferenceModel.fromJson(json);

      expect(restored.lowStockEnabled, false);
      expect(restored.outOfStockEnabled, true);
      expect(restored.quietHoursEnabled, true);
      expect(restored.startTimeOfDay, const TimeOfDay(hour: 23, minute: 30));
      expect(restored.endTimeOfDay, const TimeOfDay(hour: 6, minute: 15));
    });
  });

  group('NotificationDao SQLite Tests', () {
    late AppDatabase db;
    late NotificationDao dao;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      dao = NotificationDao(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('insert, fetch, count unread, mark read and delete', () async {
      expect(await dao.getUnreadCount(), 0);

      // Insert 2 notifications
      await dao.upsertNotification(
        LocalNotificationsCompanion(
          id: const drift.Value('n1'),
          userId: const drift.Value('user1'),
          title: const drift.Value('Low Rice'),
          message: const drift.Value('Only 1 kg left'),
          type: const drift.Value('LOW_STOCK'),
          isRead: const drift.Value(false),
          createdAt: drift.Value(DateTime.now()),
        ),
      );

      await dao.upsertNotification(
        LocalNotificationsCompanion(
          id: const drift.Value('n2'),
          userId: const drift.Value('user1'),
          title: const drift.Value('Milk Expired'),
          message: const drift.Value('Expired today'),
          type: const drift.Value('EXPIRY_REMINDER'),
          isRead: const drift.Value(false),
          createdAt: drift.Value(DateTime.now()),
        ),
      );

      expect(await dao.getUnreadCount(), 2);
      final list = await dao.getNotifications();
      expect(list.length, 2);

      // Mark n1 as read
      await dao.markAsRead('n1');
      expect(await dao.getUnreadCount(), 1);

      // Mark all as read
      await dao.markAllAsRead();
      expect(await dao.getUnreadCount(), 0);

      // Delete n2
      await dao.deleteNotification('n2');
      final remaining = await dao.getNotifications();
      expect(remaining.length, 1);
      expect(remaining.first.id, 'n1');
    });
  });

  group('LocalNotificationEngine Offline Detection Tests', () {
    late AppDatabase db;
    late InventoryDao invDao;
    late NotificationDao notifDao;
    late MockNotificationService mockService;
    late LocalNotificationEngine engine;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      invDao = InventoryDao(db);
      notifDao = NotificationDao(db);
      mockService = MockNotificationService();
      engine = LocalNotificationEngine(
        inventoryDao: invDao,
        notificationDao: notifDao,
        notificationService: mockService,
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('detects low stock and out of stock items offline', () async {
      const homeId = 'home-101';

      // Item 1: Out of stock (qty = 0)
      await db.into(db.localInventoryItems).insert(
        LocalInventoryItemsCompanion(
          id: const drift.Value('item-1'),
          homeId: const drift.Value(homeId),
          name: const drift.Value('Sugar'),
          quantity: const drift.Value(0.0),
          minimumQuantity: const drift.Value(2.0),
          unit: const drift.Value('kg'),
        ),
      );

      // Item 2: Low stock (qty = 1 <= min = 3)
      await db.into(db.localInventoryItems).insert(
        LocalInventoryItemsCompanion(
          id: const drift.Value('item-2'),
          homeId: const drift.Value(homeId),
          name: const drift.Value('Coffee'),
          quantity: const drift.Value(1.0),
          minimumQuantity: const drift.Value(3.0),
          unit: const drift.Value('can'),
        ),
      );

      // Item 3: Plentiful stock (qty = 10 > min = 2)
      await db.into(db.localInventoryItems).insert(
        LocalInventoryItemsCompanion(
          id: const drift.Value('item-3'),
          homeId: const drift.Value(homeId),
          name: const drift.Value('Rice'),
          quantity: const drift.Value(10.0),
          minimumQuantity: const drift.Value(2.0),
          unit: const drift.Value('kg'),
        ),
      );

      await engine.scanInventory(homeId);

      // Should have triggered 2 alerts (Sugar out of stock, Coffee low stock)
      expect(mockService.displayedNotifications.length, 2);

      final titles = mockService.displayedNotifications.map((n) => n['title'] as String).toList();
      expect(titles.any((t) => t.contains('Out of Stock: Sugar')), true);
      expect(titles.any((t) => t.contains('Low Stock: Coffee')), true);
      expect(titles.any((t) => t.contains('Rice')), false);

      // Also saved into local SQLite database for in-app viewing
      final localNotifs = await notifDao.getNotifications();
      expect(localNotifs.length, 2);
    });

    test('respects deduplication cooldowns', () async {
      const homeId = 'home-102';

      await db.into(db.localInventoryItems).insert(
        LocalInventoryItemsCompanion(
          id: const drift.Value('item-oil'),
          homeId: const drift.Value(homeId),
          name: const drift.Value('Olive Oil'),
          quantity: const drift.Value(0.0),
          minimumQuantity: const drift.Value(1.0),
          unit: const drift.Value('bottle'),
        ),
      );

      // First scan: alert fires
      await engine.scanInventory(homeId);
      expect(mockService.displayedNotifications.length, 1);

      // Second immediate scan: suppressed by cooldown
      await engine.scanInventory(homeId);
      expect(mockService.displayedNotifications.length, 1);

      // Reset cooldown and scan again: alert fires again
      engine.resetCooldowns();
      await engine.scanInventory(homeId);
      expect(mockService.displayedNotifications.length, 2);
    });

    test('detects expiring and expired items offline', () async {
      const homeId = 'home-103';
      final now = DateTime.now();
      final expiredDate = now.subtract(const Duration(days: 2)).toIso8601String().substring(0, 10);
      final expiringSoonDate = now.add(const Duration(days: 2)).toIso8601String().substring(0, 10);

      await db.into(db.localInventoryItems).insert(
        LocalInventoryItemsCompanion(
          id: const drift.Value('item-yogurt'),
          homeId: const drift.Value(homeId),
          name: const drift.Value('Greek Yogurt'),
          quantity: const drift.Value(2.0),
          minimumQuantity: const drift.Value(1.0),
          unit: const drift.Value('pack'),
          expiryDate: drift.Value(expiredDate),
        ),
      );

      await db.into(db.localInventoryItems).insert(
        LocalInventoryItemsCompanion(
          id: const drift.Value('item-bread'),
          homeId: const drift.Value(homeId),
          name: const drift.Value('Sourdough Bread'),
          quantity: const drift.Value(1.0),
          minimumQuantity: const drift.Value(1.0),
          unit: const drift.Value('loaf'),
          expiryDate: drift.Value(expiringSoonDate),
        ),
      );

      await engine.scanInventory(homeId);

      final titles = mockService.displayedNotifications.map((n) => n['title'] as String).toList();
      expect(titles.any((t) => t.contains('Expired: Greek Yogurt')), true);
      expect(titles.any((t) => t.contains('Expiring Soon: Sourdough Bread')), true);
    });
  });
}
