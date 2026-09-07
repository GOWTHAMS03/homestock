import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/analytics/analytics_screen.dart';
import '../../features/auth/auth_controller.dart';
import '../../features/auth/auth_state.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/inventory/inventory_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/shopping/shopping_screen.dart';
import '../widgets/splash_screen.dart';
import 'main_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _dashboardNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'dashboard');
final _inventoryNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'inventory');
final _shoppingNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shopping');
final _analyticsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'analytics');
final _profileNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'profile');

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

      // Main 5-tab Bottom Navigation Shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScaffold(navigationShell: navigationShell);
        },
        branches: [
          // 1. Dashboard Tab
          StatefulShellBranch(
            navigatorKey: _dashboardNavigatorKey,
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),

          // 2. Inventory Tab
          StatefulShellBranch(
            navigatorKey: _inventoryNavigatorKey,
            routes: [
              GoRoute(
                path: '/inventory',
                builder: (context, state) => const InventoryScreen(),
              ),
            ],
          ),

          // 3. Shopping Tab
          StatefulShellBranch(
            navigatorKey: _shoppingNavigatorKey,
            routes: [
              GoRoute(
                path: '/shopping',
                builder: (context, state) => const ShoppingScreen(),
              ),
            ],
          ),

          // 4. Analytics Tab
          StatefulShellBranch(
            navigatorKey: _analyticsNavigatorKey,
            routes: [
              GoRoute(
                path: '/analytics',
                builder: (context, state) => const AnalyticsScreen(),
              ),
            ],
          ),

          // 5. Profile Tab
          StatefulShellBranch(
            navigatorKey: _profileNavigatorKey,
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
