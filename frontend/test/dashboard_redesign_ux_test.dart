import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homestock/core/network/api_client.dart';
import 'package:homestock/core/storage/secure_storage_service.dart';
import 'package:homestock/core/sync/sync_providers.dart';
import 'package:homestock/core/sync/sync_status.dart';
import 'package:homestock/core/theme/app_theme.dart';
import 'package:homestock/features/auth/auth_controller.dart';
import 'package:homestock/features/auth/auth_state.dart';
import 'package:homestock/features/dashboard/dashboard_controller.dart';
import 'package:homestock/features/dashboard/dashboard_model.dart';
import 'package:homestock/features/dashboard/dashboard_screen.dart';
import 'package:homestock/features/home_switcher/home_controller.dart';
import 'package:homestock/features/home_switcher/home_model.dart';
import 'package:homestock/features/home_switcher/home_repository.dart';
import 'package:homestock/features/inventory/category_model.dart';
import 'package:homestock/features/inventory/inventory_controller.dart';
import 'package:homestock/features/inventory/inventory_model.dart';
import 'package:homestock/features/notifications/notification_controller.dart';
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

  @override
  Future<void> loadHomes() async {}
}

class MockAuthController extends StateNotifier<AuthState>
    implements AuthController {
  MockAuthController(super.state);

  @override
  Future<void> ensureFcmTokenRegistered() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockDashboardController extends StateNotifier<DashboardState>
    implements DashboardController {
  MockDashboardController(super.state);

  @override
  Future<void> loadDashboard() async {}

  @override
  Future<void> loadRecommendations() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockInventoryController extends StateNotifier<InventoryState>
    implements InventoryController {
  MockInventoryController(super.state);

  @override
  Future<void> loadData() async {}

  @override
  void setFilterType(InventoryFilterType type) {
    state = state.copyWith(filterType: type);
  }

  @override
  void selectCategory(String? categoryId) {
    state = state.copyWith(selectedCategoryId: categoryId);
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

class MockNotificationController extends StateNotifier<NotificationState>
    implements NotificationController {
  MockNotificationController(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
      'DashboardScreen renders all senior-level UX psychology sections correctly',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final testHome = HomeModel(
      id: 'home-123',
      name: 'Valarmathi',
      inviteCode: 'VALAR123',
      currentUserRole: 'OWNER',
      memberCount: 4,
      createdAt: '2026-09-01T00:00:00Z',
    );

    final mockHomeCtrl = MockHomeController(
      HomeState(
        homes: [testHome],
        activeHome: testHome,
        isLoading: false,
      ),
    );

    final mockAuthCtrl = MockAuthController(
      AuthState(
        isAuthenticated: true,
        user: UserProfile(
          id: 'user-001',
          fullName: 'Gowtham Sekar',
          phoneNumber: '+91 93455 33912',
          email: 'gowtham@example.com',
        ),
      ),
    );

    final mockDashCtrl = MockDashboardController(
      DashboardState(
        summary: DashboardSummaryModel(
          homeName: 'Valarmathi',
          totalInventoryItems: 12,
          lowStockCount: 2,
          outOfStockCount: 0,
          pendingShoppingCount: 1,
          expiringSoonCount: 1,
          needsAttention: [
            NeedsAttentionModel(
              itemId: 'item-eggs',
              name: 'Eggs',
              categoryName: 'Kitchen',
              quantity: 24,
              unit: 'pcs',
              stockStatus: 'IN_STOCK',
              expiryStatus: 'EXPIRING_SOON',
              daysUntilExpiry: 3,
              reasonMessage: 'Expiring in 3 days',
            ),
            NeedsAttentionModel(
              itemId: 'item-milk',
              name: 'Milk',
              categoryName: 'Beverages',
              quantity: 0.5,
              unit: 'L',
              stockStatus: 'LOW_STOCK',
              expiryStatus: 'SAFE',
              daysUntilExpiry: 10,
              reasonMessage: 'Low stock: 0.5/2.0 L',
            ),
          ],
        ),
        recommendations: WhatDoINeedModel(
          urgent: [
            RecommendationModel(
              itemId: 'item-milk',
              name: 'Milk',
              categoryName: 'Beverages',
              currentQuantity: 0.5,
              recommendedQuantity: 2.0,
              unit: 'L',
              rationale: 'Based on your recent household usage',
            ),
          ],
          soon: [],
          optional: [],
        ),
      ),
    );

    final mockInvCtrl = MockInventoryController(
      InventoryState(
        items: [
          InventoryItemModel(
            id: 'item-eggs',
            homeId: 'home-123',
            name: 'Eggs',
            categoryName: 'Kitchen',
            categoryIcon: 'kitchen',
            categoryColor: '#FB923C',
            quantity: 24,
            unit: 'pcs',
            minimumQuantity: 6.0,
            stockStatus: 'IN_STOCK',
            expiryStatus: 'EXPIRING_SOON',
            daysUntilExpiry: 3,
          ),
          InventoryItemModel(
            id: 'item-milk',
            homeId: 'home-123',
            name: 'Milk',
            categoryName: 'Beverages',
            categoryIcon: 'local_drink',
            categoryColor: '#60A5FA',
            quantity: 1.0,
            unit: 'L',
            minimumQuantity: 2.0,
            stockStatus: 'IN_STOCK',
            expiryStatus: 'SAFE',
          ),
          InventoryItemModel(
            id: 'item-rice',
            homeId: 'home-123',
            name: 'Rice',
            categoryName: 'Kitchen',
            categoryIcon: 'rice_bowl',
            categoryColor: '#F59E0B',
            quantity: 2.0,
            unit: 'kg',
            minimumQuantity: 1.0,
            stockStatus: 'IN_STOCK',
            expiryStatus: 'SAFE',
          ),
          InventoryItemModel(
            id: 'item-bread',
            homeId: 'home-123',
            name: 'Bread',
            categoryName: 'Snacks',
            categoryIcon: 'bakery_dining',
            categoryColor: '#A78BFA',
            quantity: 1.0,
            unit: 'pc',
            minimumQuantity: 1.0,
            stockStatus: 'IN_STOCK',
            expiryStatus: 'SAFE',
          ),
        ],
        categories: [
          CategoryModel(id: 'cat-kitchen', homeId: 'home-123', name: 'Kitchen', icon: 'kitchen', colorHex: '#FB923C', displayOrder: 1),
          CategoryModel(id: 'cat-cleaning', homeId: 'home-123', name: 'Cleaning', icon: 'cleaning_services', colorHex: '#38BDF8', displayOrder: 2),
          CategoryModel(id: 'cat-beverages', homeId: 'home-123', name: 'Beverages', icon: 'local_drink', colorHex: '#60A5FA', displayOrder: 3),
          CategoryModel(id: 'cat-snacks', homeId: 'home-123', name: 'Snacks', icon: 'cookie', colorHex: '#A78BFA', displayOrder: 4),
        ],
      ),
    );

    final mockShopCtrl = MockShoppingController(
      const ShoppingState(),
    );

    final mockNotifCtrl = MockNotificationController(
      const NotificationState(unreadCount: 3),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeControllerProvider.overrideWith((ref) => mockHomeCtrl),
          authControllerProvider.overrideWith((ref) => mockAuthCtrl),
          dashboardControllerProvider.overrideWith((ref) => mockDashCtrl),
          inventoryControllerProvider.overrideWith((ref) => mockInvCtrl),
          shoppingControllerProvider.overrideWith((ref) => mockShopCtrl),
          notificationControllerProvider.overrideWith((ref) => mockNotifCtrl),
          syncStateProvider.overrideWith(
            (ref) => Stream.value(
              SyncState(
                syncStatus: SyncStatus.synced,
                status: NetworkStatus.online,
                lastSyncedAt: DateTime.now(),
              ),
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const DashboardScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // 1. TOP HEADER VERIFICATION
    expect(find.text('Gowtham 👋'), findsOneWidget);
    expect(find.text('Valarmathi'), findsOneWidget);
    expect(find.text('Synced just now'), findsOneWidget);
    expect(find.text('3'), findsOneWidget); // unread notifications badge

    // 2. "WHAT NEEDS ATTENTION TODAY" SECTION VERIFICATION
    expect(find.text('What needs your attention today?'), findsOneWidget);
    expect(find.text('Running low'), findsOneWidget);
    expect(find.text('Expiring soon'), findsOneWidget);
    expect(find.text('Items to buy'), findsOneWidget);

    // 3. FEATURED ATTENTION ITEM CARD (e.g. Eggs)
    expect(find.text('Eggs'), findsWidgets);
    expect(find.textContaining('Expiring in 3 days'), findsOneWidget);
    expect(find.textContaining('Consider using soon to avoid waste.'), findsOneWidget);
    expect(find.text('+ Add to List'), findsOneWidget);

    // Verify absence of meaningless "100%"
    expect(find.text('100%'), findsNothing);

    // 4. SEARCH / SCAN / VOICE VERIFICATION
    expect(find.text('Search "Milk, Rice, Eggs..."'), findsOneWidget);
    expect(find.text('Scan'), findsOneWidget);
    expect(find.text('Voice'), findsOneWidget);

    // 5. YOUR PANTRY VERIFICATION
    expect(find.text('Your Pantry'), findsOneWidget);
    expect(find.text('Smart Suggestions'), findsOneWidget);
    expect(find.text('See All'), findsNWidgets(2)); // Quick Access & Categories "See All"

    // 6. QUICK ACCESS ACTION SHORTCUTS
    expect(find.text('Quick Access'), findsOneWidget);
    expect(find.text('Low Stock'), findsNWidgets(2)); // Quick action + category pill
    expect(find.text('Expiring Soon'), findsOneWidget);
    expect(find.text('Shopping List'), findsOneWidget);
    expect(find.text('Categories'), findsOneWidget);

    // 7. PANTRY CATEGORIES
    expect(find.text('Pantry Categories'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Kitchen'), findsOneWidget);
    expect(find.text('Cleaning'), findsOneWidget);
    expect(find.text('Beverages'), findsOneWidget);
    expect(find.text('Snacks'), findsOneWidget);

    // 8. SMART PREDICTION VERIFICATION
    expect(find.text('Next up for your home'), findsOneWidget);
    expect(find.text('Based on your usage & stock levels'), findsOneWidget);
    expect(find.text('Milk may run out soon'), findsOneWidget);
    expect(find.text('View Suggestions'), findsOneWidget);

    // 9. INTERACTION TEST: Tap "+ Add to List" button
    await tester.tap(find.text('+ Add to List'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Added "Eggs" to Shopping List'), findsOneWidget);
  });

  testWidgets('DashboardScreen renders calm reassuring state when all supplies are stocked',
      (WidgetTester tester) async {
    final testHome = HomeModel(
      id: 'home-123',
      name: 'Valarmathi',
      inviteCode: 'VALAR123',
      currentUserRole: 'OWNER',
      memberCount: 4,
      createdAt: '2026-09-01T00:00:00Z',
    );

    final mockHomeCtrl = MockHomeController(
      HomeState(homes: [testHome], activeHome: testHome, isLoading: false),
    );

    final mockAuthCtrl = MockAuthController(
      AuthState(
        isAuthenticated: true,
        user: UserProfile(id: 'u1', fullName: 'Gowtham Sekar', email: 'gowtham@example.com'),
      ),
    );

    final mockDashCtrl = MockDashboardController(
      DashboardState(
        summary: DashboardSummaryModel(
          homeName: 'Valarmathi',
          totalInventoryItems: 10,
          lowStockCount: 0,
          outOfStockCount: 0,
          pendingShoppingCount: 0,
          expiringSoonCount: 0,
          needsAttention: [],
        ),
      ),
    );

    final mockInvCtrl = MockInventoryController(const InventoryState(items: []));
    final mockShopCtrl = MockShoppingController(const ShoppingState());
    final mockNotifCtrl = MockNotificationController(const NotificationState(unreadCount: 0));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeControllerProvider.overrideWith((ref) => mockHomeCtrl),
          authControllerProvider.overrideWith((ref) => mockAuthCtrl),
          dashboardControllerProvider.overrideWith((ref) => mockDashCtrl),
          inventoryControllerProvider.overrideWith((ref) => mockInvCtrl),
          shoppingControllerProvider.overrideWith((ref) => mockShopCtrl),
          notificationControllerProvider.overrideWith((ref) => mockNotifCtrl),
          syncStateProvider.overrideWith(
            (ref) => Stream.value(
              SyncState(
                syncStatus: SyncStatus.synced,
                status: NetworkStatus.online,
                lastSyncedAt: DateTime.now(),
              ),
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const DashboardScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify calm reassuring banner is displayed
    expect(find.text('Everything looks good'), findsOneWidget);
    expect(find.text('All household supplies are well stocked'), findsOneWidget);
    expect(find.text('Items to buy'), findsOneWidget);
  });
}
