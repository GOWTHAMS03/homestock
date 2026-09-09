import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:homestock/core/theme/app_theme.dart';
import 'package:homestock/core/theme/theme_provider.dart';
import 'package:homestock/core/widgets/homestock/homestock_app_bar.dart';
import 'package:homestock/core/widgets/offline_wifi_badge.dart';
import 'package:homestock/features/inventory/inventory_controller.dart';
import 'package:homestock/features/inventory/inventory_screen.dart';
import 'package:homestock/features/shopping/shopping_controller.dart';
import 'package:homestock/features/shopping/shopping_screen.dart';

class MockInventoryController extends StateNotifier<InventoryState>
    implements InventoryController {
  MockInventoryController(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockShoppingController extends StateNotifier<ShoppingState>
    implements ShoppingController {
  MockShoppingController(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Dynamic Connectivity Themes (Purple Online vs Warm Red Offline)', () {
    testWidgets('AppTheme.onlineTheme defines Royal Amethyst Purple and Near-White palette', (tester) async {
      final theme = AppTheme.onlineTheme;
      expect(theme.colorScheme.primary, equals(const Color(0xFF7C3AED)));
      expect(theme.scaffoldBackgroundColor, equals(const Color(0xFFFAF8FF)));
      expect(theme.colorScheme.primaryContainer, equals(const Color(0xFFF3E8FF)));

      final ext = theme.extension<HomeStockThemeColors>();
      expect(ext, isNotNull);
      expect(ext!.isOffline, isFalse);
      expect(ext.primary, equals(const Color(0xFF7C3AED)));
      expect(ext.headerGradientStart, equals(const Color(0xFFF3E8FF)));
      expect(ext.headerGradientEnd, equals(const Color(0xFFFAF8FF)));
    });

    testWidgets('AppTheme.offlineTheme defines Warm Crimson Rose Red and Warm Near-White palette', (tester) async {
      final theme = AppTheme.offlineTheme;
      expect(theme.colorScheme.primary, equals(const Color(0xFFE11D48)));
      expect(theme.scaffoldBackgroundColor, equals(const Color(0xFFFFF9F9)));
      expect(theme.colorScheme.primaryContainer, equals(const Color(0xFFFFE4E6)));

      final ext = theme.extension<HomeStockThemeColors>();
      expect(ext, isNotNull);
      expect(ext!.isOffline, isTrue);
      expect(ext.primary, equals(const Color(0xFFE11D48)));
      expect(ext.headerGradientStart, equals(const Color(0xFFFFE4E6)));
      expect(ext.headerGradientEnd, equals(const Color(0xFFFFF9F9)));
    });

    testWidgets('appThemeProvider dynamically switches MaterialApp theme between Online (Purple) and Offline (Red)',
        (WidgetTester tester) async {
      final onlineState = StateProvider<bool>((ref) => true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isOnlineProvider.overrideWith((ref) => ref.watch(onlineState)),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              final theme = ref.watch(appThemeProvider);
              return MaterialApp(
                theme: theme,
                home: Builder(
                  builder: (ctx) {
                    final primary = Theme.of(ctx).colorScheme.primary;
                    final isOff = ctx.hsColors.isOffline;
                    return Scaffold(
                      body: Text('PrimaryHex: ${primary.toARGB32().toRadixString(16)}, Offline: $isOff'),
                    );
                  },
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PrimaryHex: ff7c3aed, Offline: false'), findsOneWidget);

      // Now toggle to offline mode
      final element = tester.element(find.byType(Scaffold));
      final container = ProviderScope.containerOf(element);
      container.read(onlineState.notifier).state = false;
      await tester.pumpAndSettle();

      expect(find.text('PrimaryHex: ffe11d48, Offline: true'), findsOneWidget);
    });

    testWidgets('HomeStockAppBar renders without any Wi-Fi icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.onlineTheme,
          home: const Scaffold(
            appBar: HomeStockAppBar(title: 'Pantry Test'),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(OfflineWifiBadge), findsNothing);
      expect(find.byIcon(Icons.wifi_off_rounded), findsNothing);
    });

    testWidgets('InventoryScreen has zero Wi-Fi symbols in online and offline modes',
        (WidgetTester tester) async {
      final mockInv = MockInventoryController(
        const InventoryState(items: [], categories: [], isLoading: false),
      );

      // Offline mode
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            inventoryControllerProvider.overrideWith((ref) => mockInv),
          ],
          child: MaterialApp(
            theme: AppTheme.offlineTheme,
            home: const InventoryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OfflineWifiBadge), findsNothing);
      expect(find.byIcon(Icons.wifi_off_rounded), findsNothing);
      expect(find.byIcon(Icons.wifi_off), findsNothing);
    });

    testWidgets('ShoppingScreen has zero Wi-Fi symbols in online and offline modes',
        (WidgetTester tester) async {
      final mockInv = MockInventoryController(
        const InventoryState(items: [], categories: [], isLoading: false),
      );
      final mockShopping = MockShoppingController(
        const ShoppingState(list: null, isLoading: false),
      );

      // Offline mode
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            inventoryControllerProvider.overrideWith((ref) => mockInv),
            shoppingControllerProvider.overrideWith((ref) => mockShopping),
          ],
          child: MaterialApp(
            theme: AppTheme.offlineTheme,
            home: const ShoppingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OfflineWifiBadge), findsNothing);
      expect(find.byIcon(Icons.wifi_off_rounded), findsNothing);
      expect(find.byIcon(Icons.wifi_off), findsNothing);
    });
  });
}
