import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homestock/core/network/api_client.dart';
import 'package:homestock/core/storage/secure_storage_service.dart';
import 'package:homestock/core/theme/app_theme.dart';
import 'package:homestock/features/auth/auth_controller.dart';
import 'package:homestock/features/auth/auth_state.dart';
import 'package:homestock/features/dashboard/dashboard_controller.dart';
import 'package:homestock/features/dashboard/dashboard_screen.dart';
import 'package:homestock/features/home_switcher/home_controller.dart';
import 'package:homestock/features/home_switcher/home_repository.dart';
import 'package:homestock/features/inventory/inventory_controller.dart';
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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockInventoryController extends StateNotifier<InventoryState>
    implements InventoryController {
  MockInventoryController(super.state);

  @override
  Future<void> loadData() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockShoppingController extends StateNotifier<ShoppingState>
    implements ShoppingController {
  MockShoppingController(super.state);

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
      'DashboardScreen empty home state renders world-class UI/UX with dual action cards and feature highlights',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockHomeCtrl = MockHomeController(
      const HomeState(
        homes: [],
        activeHome: null,
        isLoading: false,
      ),
    );

    final mockAuthCtrl = MockAuthController(
      AuthState(
        status: AuthStatus.authenticated,
        user: UserProfile(
          id: 'u1',
          email: 'test@example.com',
          fullName: 'Gowtham Sekar',
          username: 'gowtham',
          status: 'ACTIVE',
        ),
      ),
    );

    final mockDashCtrl = MockDashboardController(
      const DashboardState(isLoading: false),
    );

    final mockInvCtrl = MockInventoryController(
      const InventoryState(isLoading: false, items: []),
    );

    final mockShopCtrl = MockShoppingController(
      const ShoppingState(),
    );

    final mockNotifCtrl = MockNotificationController(
      const NotificationState(unreadCount: 0),
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
        ],
        child: MaterialApp(
          theme: AppTheme.onlineTheme,
          home: const DashboardScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Brand Header
    expect(find.text('HomeStock'), findsOneWidget);
    expect(find.text('Household & Inventory'), findsOneWidget);

    // 2. Welcome Hero Section
    expect(find.text('Welcome to HomeStock'), findsOneWidget);
    expect(find.byIcon(Icons.cottage_rounded), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);

    // 3. Dual Action Cards: Create and Join
    expect(find.text('Create a New Home'), findsOneWidget);
    expect(find.text('Join Existing Home'), findsOneWidget);
    expect(find.text('Code / QR'), findsOneWidget);

    // 4. Feature Bento Grid Highlights
    expect(find.text('HOW HOMESTOCK HELPS YOUR KITCHEN'), findsOneWidget);
    expect(find.text('Smart Pantry & Expiration Tracking'), findsOneWidget);
    expect(find.text('Real-Time Shared Shopping List'), findsOneWidget);
    expect(find.text('100% Offline-First Architecture'), findsOneWidget);

    // 5. Refresh / Invitations check
    expect(find.text('Already invited? Refresh status'), findsOneWidget);

    // 6. Test tapping "Create a New Home" displays CreateHomeDialog
    await tester.tap(find.text('Create a New Home'));
    await tester.pumpAndSettle();
    expect(find.text('Create New Home'), findsOneWidget);

    // Close dialog
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // 7. Test tapping "Join Existing Home" displays JoinHomeDialog
    await tester.tap(find.text('Join Existing Home'));
    await tester.pumpAndSettle();
    expect(find.text('Join Household'), findsOneWidget);
  });
}
