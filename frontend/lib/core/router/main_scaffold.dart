import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/shopping/shopping_controller.dart';
import '../constants/app_colors.dart';

class MainScaffold extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shoppingState = ref.watch(shoppingControllerProvider);
    final pendingCount = shoppingState.list?.pendingCount ?? 0;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.6), width: 0.8),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: navigationShell.currentIndex,
          backgroundColor: Colors.white,
          elevation: 0,
          onTap: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: AppColors.textSecondary,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5, letterSpacing: -0.2),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11.5, letterSpacing: -0.2),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 24),
              activeIcon: Icon(Icons.home_rounded, size: 24),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined, size: 23),
              activeIcon: Icon(Icons.inventory_2_rounded, size: 23),
              label: 'Inventory',
            ),
            BottomNavigationBarItem(
              icon: pendingCount > 0
                  ? Badge(
                      label: Text(
                        '$pendingCount',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 10, color: Colors.white),
                      ),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: const Icon(Icons.shopping_cart_outlined, size: 24),
                    )
                  : const Icon(Icons.shopping_cart_outlined, size: 24),
              activeIcon: pendingCount > 0
                  ? Badge(
                      label: Text(
                        '$pendingCount',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 10, color: Colors.white),
                      ),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: const Icon(Icons.shopping_cart_rounded, size: 24),
                    )
                  : const Icon(Icons.shopping_cart_rounded, size: 24),
              label: 'Shopping List',
            ),
          ],
        ),
      ),
    );
  }
}
