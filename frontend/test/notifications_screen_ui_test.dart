import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homestock/core/network/api_client.dart';
import 'package:homestock/core/storage/secure_storage_service.dart';
import 'package:homestock/core/theme/app_theme.dart';
import 'package:homestock/features/home_switcher/home_controller.dart';
import 'package:homestock/features/home_switcher/home_model.dart';
import 'package:homestock/features/home_switcher/home_repository.dart';
import 'package:homestock/features/notifications/notification_controller.dart';
import 'package:homestock/features/notifications/notification_model.dart';
import 'package:homestock/features/notifications/notifications_screen.dart';
import 'package:homestock/features/shopping/shopping_controller.dart';

class MockHomeRepo extends HomeRepository {
  MockHomeRepo()
      : super(
          apiClient: ApiClient(secureStorage: SecureStorageService()),
          storage: SecureStorageService(),
        );
}

class MockHomeController extends HomeController {
  MockHomeController(HomeState initial)
      : super(MockHomeRepo(), SecureStorageService()) {
    state = initial;
  }
}

class MockNotificationController extends StateNotifier<NotificationState>
    implements NotificationController {
  MockNotificationController(super.state);

  @override
  Future<void> loadNotifications() async {}

  @override
  Future<void> markAsRead(String id) async {
    final updated = state.notifications.map((n) {
      if (n.id == id) return n.copyWith(isRead: true);
      return n;
    }).toList();
    state = state.copyWith(notifications: updated, unreadCount: 0);
  }

  @override
  Future<void> markAllAsRead() async {
    final updated = state.notifications.map((n) => n.copyWith(isRead: true)).toList();
    state = state.copyWith(notifications: updated, unreadCount: 0);
  }

  @override
  Future<void> deleteNotification(String id) async {
    final updated = state.notifications.where((n) => n.id != id).toList();
    final unread = updated.where((n) => !n.isRead).length;
    state = state.copyWith(notifications: updated, unreadCount: unread);
  }

  @override
  Future<void> clearAllNotifications() async {
    state = state.copyWith(notifications: [], unreadCount: 0);
  }

  @override
  Future<void> restoreNotification(NotificationModel notif) async {
    final updated = [notif, ...state.notifications];
    final unread = updated.where((n) => !n.isRead).length;
    state = state.copyWith(notifications: updated, unreadCount: unread);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockShoppingController extends StateNotifier<ShoppingState>
    implements ShoppingController {
  MockShoppingController(super.state);

  @override
  Future<bool> addItem({
    String? inventoryItemId,
    required String itemName,
    String? categoryId,
    String? categoryName,
    String? categoryIcon,
    String? categoryColor,
    required double quantity,
    String unit = 'pcs',
    String? notes,
  }) async {
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('NotificationsScreen renders senior-level UX, allows deleting and clearing notifications with undo',
      (WidgetTester tester) async {
    final testHome = HomeModel(
      id: 'home-123',
      name: 'Valarmathi',
      inviteCode: 'VALAR123',
      currentUserRole: 'OWNER',
      memberCount: 3,
      createdAt: '2026-09-01T00:00:00Z',
    );

    final mockHomeCtrl = MockHomeController(
      HomeState(homes: [testHome], activeHome: testHome, isLoading: false),
    );

    final testNotifications = [
      NotificationModel(
        id: 'notif-1',
        homeId: 'home-123',
        title: 'Low stock: Milk',
        body: 'Only 0.5 L remaining in refrigerator.',
        type: 'LOW_STOCK',
        priority: 'HIGH',
        createdAt: DateTime.now().toIso8601String(),
        isRead: false,
        entityId: 'item-milk',
      ),
      NotificationModel(
        id: 'notif-2',
        homeId: 'home-123',
        title: 'Eggs Expiring Soon',
        body: '24 pcs of Eggs will expire in 3 days.',
        type: 'EXPIRY_REMINDER',
        priority: 'MEDIUM',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        isRead: true,
        entityId: 'item-eggs',
      ),
    ];

    final mockNotifCtrl = MockNotificationController(
      NotificationState(
        notifications: testNotifications,
        unreadCount: 1,
      ),
    );

    final mockShopCtrl = MockShoppingController(const ShoppingState());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeControllerProvider.overrideWith((ref) => mockHomeCtrl),
          notificationControllerProvider.overrideWith((ref) => mockNotifCtrl),
          shoppingControllerProvider.overrideWith((ref) => mockShopCtrl),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const NotificationsScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 1. Verify Header & Unread Pill Badge
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('1 new'), findsOneWidget);

    // 2. Verify Summary & Quick Actions Card
    expect(find.text('Alerts Center'), findsOneWidget);
    expect(find.text('2 total • 1 unread'), findsOneWidget);
    expect(find.text('Mark read'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);

    // 3. Verify Filter Pills
    expect(find.text('All (2)'), findsOneWidget);
    expect(find.text('Unread (1)'), findsOneWidget);
    expect(find.text('Stock (1)'), findsOneWidget);
    expect(find.text('Expiry (1)'), findsOneWidget);

    // 4. Verify Cards Content
    expect(find.text('Low stock: Milk'), findsOneWidget);
    expect(find.text('Eggs Expiring Soon'), findsOneWidget);
    expect(find.text('+ Add to Shopping'), findsOneWidget);
    expect(find.text('Inspect Item'), findsOneWidget);

    // 5. Test Deleting an Individual Notification via Direct Delete Button
    // Tap the delete button on the first card
    final closeIcons = find.byIcon(Icons.close_rounded);
    expect(closeIcons, findsNWidgets(2));

    await tester.tap(closeIcons.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Undo SnackBar appears
    expect(find.textContaining('Deleted "Low stock: Milk"'), findsOneWidget);
    expect(find.text('UNDO'), findsOneWidget);
    // Card should be deleted
    expect(find.text('Low stock: Milk'), findsNothing);

    // 6. Test Undo Functionality
    await tester.tap(find.text('UNDO'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Card should be restored!
    expect(find.text('Low stock: Milk'), findsOneWidget);

    // 7. Test Clear All Confirmation Sheet
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    // Verify modal appears
    expect(find.text('Clear All Notifications?'), findsOneWidget);
    expect(find.text('Clear All'), findsOneWidget);

    // Confirm Clear All
    await tester.tap(find.text('Clear All'));
    await tester.pumpAndSettle();

    // Verify Empty State is shown
    expect(find.text('All caught up!'), findsOneWidget);
    expect(find.text('Manage Preferences'), findsOneWidget);
  });
}
