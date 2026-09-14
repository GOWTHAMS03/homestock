import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:homestock/core/capabilities/capability_provider.dart';
import 'package:homestock/core/capabilities/feature_capability.dart';
import 'package:homestock/core/network/api_client.dart';
import 'package:homestock/core/storage/secure_storage_service.dart';
import 'package:homestock/core/sync/sync_providers.dart';
import 'package:homestock/core/sync/sync_status.dart';
import 'package:homestock/core/theme/app_theme.dart';
import 'package:homestock/features/auth/auth_controller.dart';
import 'package:homestock/features/auth/auth_state.dart';
import 'package:homestock/features/dashboard/dashboard_controller.dart';
import 'package:homestock/features/dashboard/dashboard_screen.dart';
import 'package:homestock/features/home_switcher/home_controller.dart';
import 'package:homestock/features/home_switcher/home_model.dart';
import 'package:homestock/features/home_switcher/home_repository.dart';
import 'package:homestock/features/inventory/inventory_controller.dart';
import 'package:homestock/features/notifications/notification_controller.dart';
import 'package:homestock/features/shopping/shopping_controller.dart';
import 'package:homestock/features/shopping/shopping_model.dart';
import 'package:homestock/features/shopping/shopping_screen.dart';

void main() {
  group('Capability System - Core Rules & Architecture', () {
    test('Rule 2 (Offline): Returns ONLY features that work offline', () {
      final container = ProviderContainer(
        overrides: [
          networkStatusProvider.overrideWith(
            (ref) => Stream.value(NetworkStatus.offline),
          ),
          isOnlineProvider.overrideWithValue(false),
        ],
      );
      addTearDown(container.dispose);

      final available = container.read(availableCapabilitiesProvider);

      // Offline-supported features MUST be available
      expect(available.contains(FeatureCapability.inventory), isTrue);
      expect(available.contains(FeatureCapability.shoppingList), isTrue);
      expect(available.contains(FeatureCapability.history), isTrue);
      expect(available.contains(FeatureCapability.reminders), isTrue);
      expect(available.contains(FeatureCapability.manualAddEdit), isTrue);

      // Online-only features MUST NOT be available (Strict UX rule: hide completely)
      expect(available.contains(FeatureCapability.voice), isFalse);
      expect(available.contains(FeatureCapability.billScan), isFalse);
      expect(available.contains(FeatureCapability.deals), isFalse);
      expect(available.contains(FeatureCapability.nearbyShops), isFalse);
      expect(available.contains(FeatureCapability.onlineSearch), isFalse);
      expect(available.contains(FeatureCapability.sync), isFalse);
    });

    test('Rule 1 (Online): Shows online-supported features that are available', () {
      final container = ProviderContainer(
        overrides: [
          networkStatusProvider.overrideWith(
            (ref) => Stream.value(NetworkStatus.online),
          ),
          isOnlineProvider.overrideWithValue(true),
        ],
      );
      addTearDown(container.dispose);

      final available = container.read(availableCapabilitiesProvider);

      // Online-supported features are available
      expect(available.contains(FeatureCapability.voice), isTrue);
      expect(available.contains(FeatureCapability.billScan), isTrue);
      expect(available.contains(FeatureCapability.deals), isTrue);
      expect(available.contains(FeatureCapability.nearbyShops), isTrue);
      expect(available.contains(FeatureCapability.onlineSearch), isTrue);
      expect(available.contains(FeatureCapability.sync), isTrue);

      // Offline-supported features also remain available
      expect(available.contains(FeatureCapability.inventory), isTrue);
      expect(available.contains(FeatureCapability.shoppingList), isTrue);
      expect(available.contains(FeatureCapability.history), isTrue);
      expect(available.contains(FeatureCapability.reminders), isTrue);
      expect(available.contains(FeatureCapability.manualAddEdit), isTrue);
    });

    test('Rule 3 (Service Unavailability): If a service is down, treat feature as unavailable', () {
      final container = ProviderContainer(
        overrides: [
          isOnlineProvider.overrideWithValue(true),
        ],
      );
      addTearDown(container.dispose);

      // Initially everything online is available
      expect(container.read(isCapabilityAvailableProvider(FeatureCapability.billScan)), isTrue);
      expect(container.read(isCapabilityAvailableProvider(FeatureCapability.voice)), isTrue);

      // Mark OCR service as down (e.g. 503 or circuit-breaker open)
      container.read(serviceHealthProvider.notifier).markServiceUnavailable('ocr');

      // Bill scan capability should immediately become unavailable
      expect(container.read(isCapabilityAvailableProvider(FeatureCapability.billScan)), isFalse);
      // Other services should remain unaffected
      expect(container.read(isCapabilityAvailableProvider(FeatureCapability.voice)), isTrue);
      expect(container.read(isCapabilityAvailableProvider(FeatureCapability.deals)), isTrue);

      // Mark voice service as down
      container.read(serviceHealthProvider.notifier).markServiceUnavailable('voice');
      expect(container.read(isCapabilityAvailableProvider(FeatureCapability.voice)), isFalse);
    });

    test('Rule 4 (Dynamic Re-appearance): Automatically restores visibility without restart', () {
      final container = ProviderContainer(
        overrides: [
          isOnlineProvider.overrideWithValue(true),
        ],
      );
      addTearDown(container.dispose);

      // Mark deals service unavailable
      container.read(serviceHealthProvider.notifier).markServiceUnavailable('deals');
      expect(container.read(isCapabilityAvailableProvider(FeatureCapability.deals)), isFalse);

      // Service recovers and becomes available again
      container.read(serviceHealthProvider.notifier).markServiceAvailable('deals');
      expect(container.read(isCapabilityAvailableProvider(FeatureCapability.deals)), isTrue);
    });

    test('Home Screen Capabilities: Prioritizes capabilities based on online vs offline', () {
      final offlineContainer = ProviderContainer(
        overrides: [
          isOnlineProvider.overrideWithValue(false),
        ],
      );
      addTearDown(offlineContainer.dispose);

      final offlineCaps = offlineContainer.read(activeHomeCapabilitiesProvider);
      expect(offlineCaps.map((d) => d.capability).toList(), [
        FeatureCapability.inventory,
        FeatureCapability.shoppingList,
        FeatureCapability.history,
        FeatureCapability.reminders,
        FeatureCapability.manualAddEdit,
      ]);

      final onlineContainer = ProviderContainer(
        overrides: [
          isOnlineProvider.overrideWithValue(true),
        ],
      );
      addTearDown(onlineContainer.dispose);

      final onlineCaps = onlineContainer.read(activeHomeCapabilitiesProvider);
      expect(onlineCaps.map((d) => d.capability).toList(), [
        FeatureCapability.voice,
        FeatureCapability.billScan,
        FeatureCapability.deals,
        FeatureCapability.nearbyShops,
        FeatureCapability.onlineSearch,
      ]);
    });
  });

  group('CapabilityAware Widget Tests', () {
    testWidgets('Renders child when capability is available', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isOnlineProvider.overrideWithValue(true),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CapabilityAware(
                capability: FeatureCapability.voice,
                child: Text('Voice Button Active'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Voice Button Active'), findsOneWidget);
    });

    testWidgets('Completely hides child (renders fallback/empty) when capability is unavailable',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isOnlineProvider.overrideWithValue(false),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CapabilityAware(
                capability: FeatureCapability.voice,
                child: Text('Voice Button Active'),
              ),
            ),
          ),
        ),
      );

      // MUST NOT RENDER CHILD
      expect(find.text('Voice Button Active'), findsNothing);
      // No disabled cards or greyed-out widgets
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('Dynamically switches when connection state toggles without restart',
        (tester) async {
      final stateProvider = StateProvider<bool>((ref) => false);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isOnlineProvider.overrideWith((ref) => ref.watch(stateProvider)),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              return MaterialApp(
                home: Scaffold(
                  body: Column(
                    children: [
                      const CapabilityAware(
                        capability: FeatureCapability.deals,
                        child: Text('Smart Deals Card'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(stateProvider.notifier).state = true;
                        },
                        child: const Text('Go Online'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );

      // Initially offline: Deals card must not exist
      expect(find.text('Smart Deals Card'), findsNothing);

      // Tap to go online
      await tester.tap(find.text('Go Online'));
      await tester.pumpAndSettle();

      // Deals card dynamically appears without app restart!
      expect(find.text('Smart Deals Card'), findsOneWidget);
    });
  });

  group('Dashboard Screen - Dynamic Capability UI Rendering', () {
    testWidgets('Offline: Hides all online-only features and renders offline capabilities',
        (tester) async {
      final mockHomeCtrl = _MockHomeController(
        HomeState(
          homes: [
            HomeModel(
              id: 'home-1',
              name: 'My Kitchen',
              inviteCode: 'INV123',
              currentUserRole: 'ADMIN',
              memberCount: 1,
            ),
          ],
          activeHome: HomeModel(
            id: 'home-1',
            name: 'My Kitchen',
            inviteCode: 'INV123',
            currentUserRole: 'ADMIN',
            memberCount: 1,
          ),
        ),
      );

      final mockAuthCtrl = _MockAuthController(
        const AuthState(isAuthenticated: true),
      );

      final mockDashCtrl = _MockDashboardController(
        const DashboardState(),
      );

      final mockInvCtrl = _MockInventoryController(
        const InventoryState(items: []),
      );

      final mockShopCtrl = _MockShoppingController(
        const ShoppingState(),
      );

      final mockNotifCtrl = _MockNotificationController(
        const NotificationState(unreadCount: 0),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isOnlineProvider.overrideWithValue(false),
            homeControllerProvider.overrideWith((ref) => mockHomeCtrl),
            authControllerProvider.overrideWith((ref) => mockAuthCtrl),
            dashboardControllerProvider.overrideWith((ref) => mockDashCtrl),
            inventoryControllerProvider.overrideWith((ref) => mockInvCtrl),
            shoppingControllerProvider.overrideWith((ref) => mockShopCtrl),
            notificationControllerProvider.overrideWith((ref) => mockNotifCtrl),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const DashboardScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Rule 2: Online-only features MUST be completely hidden when offline
      expect(find.text('Homie'), findsNothing); // Voice AI button in search bar
      expect(find.text('Smart Deals'), findsNothing);
      expect(find.text('Nearby Shops'), findsNothing);
      expect(find.text('Online Search'), findsNothing);
      expect(find.text('Bill Scan'), findsNothing);

      // Rule 2: Offline capabilities MUST be rendered
      expect(find.text('Offline Capabilities'), findsOneWidget);
      expect(find.text('Pantry Inventory'), findsOneWidget);
      expect(find.text('Shopping List'), findsOneWidget);
      expect(find.text('Purchase History'), findsOneWidget);
      expect(find.text('Expiry Alerts'), findsOneWidget);
      expect(find.text('Manual Add'), findsOneWidget);

      // No disabled buttons, no greyed-out placeholders
      expect(find.text('Internet required'), findsNothing);
    });

    testWidgets('Online: Renders online features dynamically', (tester) async {
      final mockHomeCtrl = _MockHomeController(
        HomeState(
          homes: [
            HomeModel(
              id: 'home-1',
              name: 'My Kitchen',
              inviteCode: 'INV123',
              currentUserRole: 'ADMIN',
              memberCount: 1,
            ),
          ],
          activeHome: HomeModel(
            id: 'home-1',
            name: 'My Kitchen',
            inviteCode: 'INV123',
            currentUserRole: 'ADMIN',
            memberCount: 1,
          ),
        ),
      );

      final mockAuthCtrl = _MockAuthController(
        const AuthState(isAuthenticated: true),
      );

      final mockDashCtrl = _MockDashboardController(
        const DashboardState(),
      );

      final mockInvCtrl = _MockInventoryController(
        const InventoryState(items: []),
      );

      final mockShopCtrl = _MockShoppingController(
        const ShoppingState(),
      );

      final mockNotifCtrl = _MockNotificationController(
        const NotificationState(unreadCount: 0),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isOnlineProvider.overrideWithValue(true),
            homeControllerProvider.overrideWith((ref) => mockHomeCtrl),
            authControllerProvider.overrideWith((ref) => mockAuthCtrl),
            dashboardControllerProvider.overrideWith((ref) => mockDashCtrl),
            inventoryControllerProvider.overrideWith((ref) => mockInvCtrl),
            shoppingControllerProvider.overrideWith((ref) => mockShopCtrl),
            notificationControllerProvider.overrideWith((ref) => mockNotifCtrl),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const DashboardScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Rule 1: Online-supported features MUST be rendered
      expect(find.text('Homie'), findsOneWidget); // Voice AI button in search bar
      expect(find.text('Available Features'), findsOneWidget);
      expect(find.text('Homie Voice'), findsOneWidget);
      expect(find.text('Bill Scan'), findsOneWidget);
      expect(find.text('Smart Deals'), findsOneWidget);
      expect(find.text('Nearby Shops'), findsOneWidget);
      expect(find.text('Online Search'), findsOneWidget);
    });
  });

  group('Shopping Screen - Dynamic Capability UI Rendering', () {
    testWidgets('Offline: Hides Deals banner, Nearby Shops shortcut, and Voice input',
        (tester) async {
      final mockShoppingCtrl = _MockShoppingController(
        ShoppingState(
          list: ShoppingListModel(
            id: 'list-1',
            homeId: 'home-1',
            name: 'Shared Shopping List',
            isDefault: true,
            pendingCount: 0,
            completedCount: 0,
            items: [],
          ),
        ),
      );

      final mockInvCtrl = _MockInventoryController(
        const InventoryState(items: []),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isOnlineProvider.overrideWithValue(false),
            shoppingControllerProvider.overrideWith((ref) => mockShoppingCtrl),
            inventoryControllerProvider.overrideWith((ref) => mockInvCtrl),
          ],
          child: const MaterialApp(
            home: ShoppingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Rule 2: Online-only features MUST NOT render on Shopping Screen
      expect(find.text('Best prices for your list'), findsNothing);
      expect(find.text('Nearby Grocery Shops'), findsNothing);
      expect(find.text('Price Deals'), findsNothing);
      expect(find.byIcon(Icons.mic), findsNothing);

      // Offline-working features MUST render
      expect(find.text('Shop Mode'), findsOneWidget);
      expect(find.text('Restocked'), findsOneWidget);
      expect(find.text('Shopping List'), findsOneWidget);
    });
  });
}

// ── Test Mocks ──
class _MockHomeRepo extends HomeRepository {
  _MockHomeRepo()
      : super(
          apiClient: ApiClient(secureStorage: SecureStorageService()),
          storage: SecureStorageService(),
        );
}

class _MockHomeController extends HomeController {
  _MockHomeController(HomeState initial)
      : super(_MockHomeRepo(), SecureStorageService()) {
    state = initial;
  }

  @override
  Future<void> loadHomes() async {}
}

class _MockAuthController extends StateNotifier<AuthState>
    implements AuthController {
  _MockAuthController(super.state);

  @override
  Future<void> ensureFcmTokenRegistered() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockDashboardController extends StateNotifier<DashboardState>
    implements DashboardController {
  _MockDashboardController(super.state);

  @override
  Future<void> loadDashboard() async {}

  @override
  Future<void> loadRecommendations() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockInventoryController extends StateNotifier<InventoryState>
    implements InventoryController {
  _MockInventoryController(super.state);

  @override
  Future<void> loadData() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockShoppingController extends StateNotifier<ShoppingState>
    implements ShoppingController {
  _MockShoppingController(super.state);

  @override
  Future<void> loadShoppingList({bool forceRemote = false}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockNotificationController extends StateNotifier<NotificationState>
    implements NotificationController {
  _MockNotificationController(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
