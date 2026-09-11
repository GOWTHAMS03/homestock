import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/shopping/shopping_controller.dart';

/// Floating Pill Navigation Bar
/// Strictly matches user requirements:
/// - Only 3 menus in exact order: 1. Home, 2. Inventory, 3. Shopping List
/// - Dynamic Offline & Online Theme Colors:
///   - Online: Royal Amethyst Purple pill & circle from Theme.of(context).colorScheme
///   - Offline: Warm Crimson Red pill & circle from Theme.of(context).colorScheme
/// - Selected Tab: Expanded capsule pill with solid circle badge, white icon, and bold label
/// - Unselected Tabs: Sleek outline icons only
class MainScaffold extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shoppingState = ref.watch(shoppingControllerProvider);
    final pendingCount = shoppingState.list?.pendingCount ?? 0;
    final currentIndex = navigationShell.currentIndex;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(36),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  spreadRadius: 0,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // 0. Home Tab
                _buildNavItem(
                  context: context,
                  index: 0,
                  currentIndex: currentIndex,
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home_outlined,
                  label: 'Home',
                ),

                // 1. Inventory Tab
                _buildNavItem(
                  context: context,
                  index: 1,
                  currentIndex: currentIndex,
                  icon: Icons.inventory_2_outlined,
                  selectedIcon: Icons.inventory_2_outlined,
                  label: 'Inventory',
                ),

                // 2. Shopping List Tab
                _buildNavItem(
                  context: context,
                  index: 2,
                  currentIndex: currentIndex,
                  icon: Icons.shopping_cart_outlined,
                  selectedIcon: Icons.shopping_cart_outlined,
                  label: 'Shopping',
                  badgeCount: pendingCount,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required int currentIndex,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    int badgeCount = 0,
  }) {
    final isSelected = index == currentIndex;

    // Dynamic Online / Offline Colors from the active Theme:
    final theme = Theme.of(context);
    final activePillBg = theme.colorScheme.primaryContainer;
    final activeCircleColor = theme.colorScheme.primary;
    final activeTextColor = theme.colorScheme.primary;
    const inactiveIconColor = Color(0xFF64748B);

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        );
      },
      borderRadius: BorderRadius.circular(30),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInOutCubic,
        height: 48,
        padding: isSelected
            ? const EdgeInsets.only(left: 5, top: 4, bottom: 4, right: 14)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activePillBg : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              // Solid circle badge with White Icon (matches theme primary color: online purple, offline red)
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: activeCircleColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    selectedIcon,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Bold Tab Title in theme color
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: activeTextColor,
                  letterSpacing: -0.2,
                ),
              ),
            ] else ...[
              // Unselected: Sleek Outline Icon only (with optional badge)
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(
                    icon,
                    size: 24,
                    color: inactiveIconColor,
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      top: -4,
                      right: -7,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                        child: Center(
                          child: Text(
                            badgeCount > 99 ? '99+' : '$badgeCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
