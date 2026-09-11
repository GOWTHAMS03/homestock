import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:homestock/core/router/main_scaffold.dart';
import 'package:homestock/core/theme/app_theme.dart';
import 'package:homestock/features/shopping/shopping_controller.dart';
import 'package:homestock/features/shopping/shopping_model.dart';

class FakeShoppingController extends StateNotifier<ShoppingState> implements ShoppingController {
  FakeShoppingController(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('MainScaffold renders floating pill nav bar with only 3 tabs (Home, Inventory, Shopping) and dynamic colors', (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => MainScaffold(navigationShell: navigationShell),
          branches: [
            // 0. Home
            StatefulShellBranch(
              routes: [GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Center(child: Text('Home Screen'))))],
            ),
            // 1. Inventory
            StatefulShellBranch(
              routes: [GoRoute(path: '/inventory', builder: (_, _) => const Scaffold(body: Center(child: Text('Inventory Screen'))))],
            ),
            // 2. Shopping
            StatefulShellBranch(
              routes: [GoRoute(path: '/shopping', builder: (_, _) => const Scaffold(body: Center(child: Text('Shopping Screen'))))],
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shoppingControllerProvider.overrideWith(
            (ref) => FakeShoppingController(
              ShoppingState(
                list: ShoppingListModel(
                  id: 'list-1',
                  homeId: 'home-1',
                  name: 'Groceries',
                  isDefault: true,
                  pendingCount: 2,
                  completedCount: 1,
                  items: [],
                ),
              ),
            ),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.onlineTheme,
          routerConfig: router,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify Home Screen is active
    expect(find.text('Home Screen'), findsOneWidget);

    // 2. Active tab is "Home": expanded pill with label "Home"
    expect(find.text('Home'), findsOneWidget);

    // 3. Inactive tabs do NOT show text labels (clean icon-only buttons)
    expect(find.text('Inventory'), findsNothing);
    expect(find.text('Shopping'), findsNothing);

    // 4. Inactive icons are present (Inventory box, Cart). Profile is NOT in the nav bar
    expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);
    expect(find.byIcon(Icons.person_outline_rounded), findsNothing);

    // 5. Shopping pending badge is displayed on the shopping icon (2 pending)
    expect(find.text('2'), findsOneWidget);

    // 6. Verify colors:
    // Online theme primary circular container for active item (0xFF7C3AED)
    final circleContainers = tester.widgetList<Container>(find.byType(Container)).where((c) {
      final dec = c.decoration;
      return dec is BoxDecoration && dec.color == AppTheme.onlineTheme.colorScheme.primary;
    });
    expect(circleContainers, isNotEmpty);

    // 7. Tap the Inventory tab (index 1)
    await tester.tap(find.byIcon(Icons.inventory_2_outlined));
    await tester.pumpAndSettle();

    // Verify Inventory Screen is now active
    expect(find.text('Inventory Screen'), findsOneWidget);
    expect(find.text('Inventory'), findsOneWidget);
    expect(find.text('Home'), findsNothing);

    // 8. Tap the Shopping tab (index 2)
    await tester.tap(find.byIcon(Icons.shopping_cart_outlined));
    await tester.pumpAndSettle();

    // Verify Shopping Screen is active and "Shopping" label is shown
    expect(find.text('Shopping Screen'), findsOneWidget);
    expect(find.text('Shopping'), findsOneWidget);
    expect(find.text('Inventory'), findsNothing);
  });
}
