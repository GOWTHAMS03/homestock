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
