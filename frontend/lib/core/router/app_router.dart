import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/analytics/analytics_screen.dart';
import '../../features/auth/auth_controller.dart';
import '../../features/auth/auth_state.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/dashboard/attention_items_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/inventory/inventory_screen.dart';
import '../../features/inventory/item_detail_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/notifications/notification_preferences_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/shopping/shopping_screen.dart';
import '../../features/bill/screens/bill_scanner_screen.dart';
import '../../features/bill/screens/bill_confirmation_screen.dart';
import '../../features/bill/screens/expense_intelligence_screen.dart';
import '../../features/smart_shopping/nearby_grocery_shops_screen.dart';
import '../../features/shop_owner/screens/shop_onboarding_screen.dart';
import '../../features/shop_owner/screens/shop_dashboard_screen.dart';
import '../../features/shop_owner/screens/shop_products_screen.dart';
import '../../features/shop_owner/screens/shop_add_product_screen.dart';
import '../../features/shop_owner/screens/shop_deals_screen.dart';
import '../../features/shop_owner/screens/shop_settings_screen.dart';
import '../../features/shop_owner/screens/customer_demand_screen.dart';
import '../../features/discovery/screens/shop_profile_screen.dart';
import '../../features/discovery/screens/product_search_results_screen.dart';
import '../../features/admin/screens/admin_shops_screen.dart';
import '../widgets/splash_screen.dart';
import 'main_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
GlobalKey<NavigatorState> get rootNavigatorKey => _rootNavigatorKey;
final _dashboardNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'dashboard');
final _shoppingNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shopping');
final _inventoryNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'inventory');

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authControllerProvider,
      (previous, next) => notifyListeners(),
    );
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authControllerProvider);
    if (authState.isLoading) {
      return state.matchedLocation == '/splash' ? null : '/splash';
    }

    final isAuth = authState.isAuthenticated;
    final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/register';

    if (!isAuth) {
      return isAuthRoute ? null : '/login';
    }

    if (isAuth && (isAuthRoute || state.matchedLocation == '/splash')) {
      if (authState.user?.appRole == 'SHOP_OWNER') {
        if (state.matchedLocation == '/register') {
          return '/shop/onboarding';
        }
        return '/shop/dashboard';
      }
      return '/';
    }

    return null;
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    refreshListenable: notifier,
    initialLocation: '/splash',
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/splash',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/settings/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationPreferencesScreen(),
      ),
      GoRoute(
        path: '/analytics',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AnalyticsScreen(),
      ),
      GoRoute(
        path: '/analytics/expenses',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ExpenseIntelligenceScreen(),
      ),
      GoRoute(
        path: '/bills/scan',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const BillScannerScreen(),
      ),
      GoRoute(
        path: '/bills/confirm',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const BillConfirmationScreen(),
      ),
      GoRoute(
        path: '/attention',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AttentionItemsScreen(),
      ),
      GoRoute(
        path: '/inventory/detail/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final itemId = state.pathParameters['id'] ?? '';
          return ItemDetailScreen(itemId: itemId);
        },
      ),

      GoRoute(
        path: '/profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/shops/nearby',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NearbyGroceryShopsScreen(),
      ),

      // Shop Owner Routes
      GoRoute(
        path: '/shop/onboarding',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final lat = state.uri.queryParameters['lat'];
          final lon = state.uri.queryParameters['lon'];
          final area = state.uri.queryParameters['area'];
          final city = state.uri.queryParameters['city'];
          final postalCode = state.uri.queryParameters['postalCode'];
          final address = state.uri.queryParameters['address'];
          return ShopOnboardingScreen(
            initialLat: lat,
            initialLon: lon,
            initialArea: area,
            initialCity: city,
            initialPostalCode: postalCode,
            initialAddress: address,
          );
        },
      ),
      GoRoute(
        path: '/shop/dashboard',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ShopDashboardScreen(),
      ),
      GoRoute(
        path: '/shop/products',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ShopProductsScreen(),
      ),
      GoRoute(
        path: '/shop/products/add',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final initialName = state.uri.queryParameters['name'];
          return ShopAddProductScreen(initialName: initialName);
        },
      ),
      GoRoute(
        path: '/shop/deals',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ShopDealsScreen(),
      ),
      GoRoute(
        path: '/shop/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ShopSettingsScreen(),
      ),
      GoRoute(
        path: '/shop/demand',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CustomerDemandScreen(),
      ),

      // Customer Discovery Routes
      GoRoute(
        path: '/discovery/shop/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final shopId = state.pathParameters['id'] ?? '';
          return ShopProfileScreen(shopId: shopId);
        },
      ),
      GoRoute(
        path: '/discovery/search',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final q = state.uri.queryParameters['q'];
          return ProductSearchResultsScreen(initialQuery: q);
        },
      ),

      // Admin Routes
      GoRoute(
        path: '/admin/shops',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AdminShopsScreen(),
      ),

      // Floating 3-tab Bottom Navigation Shell (Home, Inventory, Shopping List)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScaffold(navigationShell: navigationShell);
        },
        branches: [
          // 0. Dashboard / Home Tab
          StatefulShellBranch(
            navigatorKey: _dashboardNavigatorKey,
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),

          // 1. Inventory Tab
          StatefulShellBranch(
            navigatorKey: _inventoryNavigatorKey,
            routes: [
              GoRoute(
                path: '/inventory',
                builder: (context, state) => const InventoryScreen(),
              ),
            ],
          ),

          // 2. Shopping List Tab
          StatefulShellBranch(
            navigatorKey: _shoppingNavigatorKey,
            routes: [
              GoRoute(
                path: '/shopping',
                builder: (context, state) => const ShoppingScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
