import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../auth/auth_controller.dart';
import '../home_switcher/create_home_dialog.dart';
import '../home_switcher/home_controller.dart';
import '../home_switcher/join_home_dialog.dart';
import '../inventory/inventory_controller.dart';
import '../notifications/notification_controller.dart';
import '../shopping/shopping_controller.dart';
import 'dashboard_controller.dart';
import 'dashboard_model.dart';
import 'what_do_i_need_sheet.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final homeState = ref.watch(homeControllerProvider);
    final dashboardState = ref.watch(dashboardControllerProvider);
    final notifState = ref.watch(notificationControllerProvider);

    final userName = authState.user?.fullName.split(' ').first ?? 'Friend';
    final activeHome = homeState.activeHome;
    final summary = dashboardState.summary;

    // 1. Initial Home Loading State with Layout-Stable Skeletons
    if (homeState.isLoading || (dashboardState.isLoading && summary == null)) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('HomeStock', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: const [
            SkeletonLoader(width: 180, height: 24),
            SizedBox(height: 8),
            SkeletonLoader(width: 240, height: 14),
            SizedBox(height: AppSpacing.lg),
            SkeletonMetricsRow(),
            SizedBox(height: AppSpacing.lg),
            SkeletonItemCard(),
            SizedBox(height: AppSpacing.sm),
            SkeletonItemCard(),
          ],
        ),
      );
    }

    // 2. Empty Home Configuration State
    if (homeState.homes.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('HomeStock', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        body: EmptyStateView(
          icon: Icons.cottage_outlined,
          title: 'No Home Configured',
          message: 'Create a new household inventory or join an existing home using an invite code.',
          actionLabel: 'Create a Home',
          onAction: () => showDialog(
            context: context,
            builder: (_) => const CreateHomeDialog(),
          ),
        ),
      );
    }

    // 3. Main Dashboard Content
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          onTap: () => _showHomeSwitcher(context, ref),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    activeHome?.name ?? 'My Home',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded),
                tooltip: 'Notifications',
                onPressed: () => context.push('/notifications'),
              ),
              if (notifState.unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.outOfStockText,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${notifState.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(dashboardControllerProvider.notifier).loadDashboard();
          await ref.read(inventoryControllerProvider.notifier).loadData();
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // Friendly Greeting & Smart Action Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_getGreeting()}, $userName 👋',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Household overview for today',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // "What Do I Need?" Smart Action Button
                InkWell(
                  onTap: () {
                    ref.read(dashboardControllerProvider.notifier).loadRecommendations();
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const WhatDoINeedSheet(),
                    );
                  },
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome_rounded, size: 15, color: AppColors.primary),
                        SizedBox(width: 5),
                        Text(
                          'What I Need',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Shared Shopping List Hero Card (Calm, high-contrast, actionable)
            GestureDetector(
              onTap: () => context.go('/shopping'),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Shared Shopping List',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            (summary?.pendingShoppingCount ?? 0) > 0
                                ? '${summary!.pendingShoppingCount} item(s) pending restock'
                                : 'All items stocked up!',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 18),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Interactive Inventory Metric Cards
            Row(
              children: [
                Expanded(
                  child: _buildInteractiveMetricCard(
                    context: context,
                    title: 'Total Items',
                    value: '${summary?.totalInventoryItems ?? 0}',
                    icon: Icons.inventory_2_outlined,
                    iconColor: AppColors.primary,
                    bgColor: AppColors.primaryContainer,
                    onTap: () {
                      ref.read(inventoryControllerProvider.notifier).setFilterType(InventoryFilterType.all);
                      context.go('/inventory');
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildInteractiveMetricCard(
                    context: context,
                    title: 'Low Stock',
                    value: '${summary?.lowStockCount ?? 0}',
                    icon: Icons.warning_amber_rounded,
                    iconColor: AppColors.lowStockText,
                    bgColor: AppColors.lowStockBg,
                    onTap: () {
                      ref.read(inventoryControllerProvider.notifier).setFilterType(InventoryFilterType.lowStock);
                      context.go('/inventory');
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildInteractiveMetricCard(
                    context: context,
                    title: 'Out of Stock',
                    value: '${summary?.outOfStockCount ?? 0}',
                    icon: Icons.cancel_outlined,
                    iconColor: AppColors.outOfStockText,
                    bgColor: AppColors.outOfStockBg,
                    onTap: () {
                      ref.read(inventoryControllerProvider.notifier).setFilterType(InventoryFilterType.outOfStock);
                      context.go('/inventory');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Needs Attention Section with 1-Tap "+ Add to Shopping"
            if (summary != null && summary.needsAttention.isNotEmpty) ...[
              SectionHeader(
                title: 'Needs Attention',
                subtitle: 'Items requiring restock or nearing expiry',
                actionLabel: 'View All',
                onAction: () {
                  ref.read(inventoryControllerProvider.notifier).setFilterType(InventoryFilterType.lowStock);
                  context.go('/inventory');
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              ...summary.needsAttention.map((item) {
                return _buildAttentionCard(context, ref, item);
              }),
              const SizedBox(height: AppSpacing.xl),
            ],

            // Quick Category Jumps
            const SectionHeader(
              title: 'Explore Categories',
              subtitle: 'Browse inventory by category',
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildCategoryRow(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveMetricCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                  child: Icon(icon, size: 15, color: iconColor),
                ),
                const Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.textMuted),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 1),
            Text(
              title,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttentionCard(BuildContext context, WidgetRef ref, NeedsAttentionModel item) {
    final isOut = item.stockStatus == 'OUT_OF_STOCK';
    final isLow = item.stockStatus == 'LOW_STOCK';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isOut
                    ? AppColors.outOfStockBg
                    : (isLow ? AppColors.lowStockBg : AppColors.expiringSoonBg),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(
                isOut
                    ? Icons.cancel_outlined
                    : (isLow ? Icons.warning_amber_rounded : Icons.access_time_rounded),
                size: 20,
                color: isOut
                    ? AppColors.outOfStockText
                    : (isLow ? AppColors.lowStockText : AppColors.expiringSoonText),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.reasonMessage,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Quick 1-Tap "+ Add to Shopping List"
            InkWell(
              onTap: () async {
                final success = await ref.read(shoppingControllerProvider.notifier).addItem(
                      inventoryItemId: item.itemId,
                      itemName: item.name,
                      quantity: 1.0,
                    );
                if (context.mounted && success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added "${item.name}" to shopping list'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_shopping_cart_rounded, size: 14, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text(
                      'Add',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryRow(BuildContext context, WidgetRef ref) {
    final invState = ref.watch(inventoryControllerProvider);
    final categories = invState.categories;

    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final cat = categories[index];
          return InkWell(
            onTap: () {
              ref.read(inventoryControllerProvider.notifier).selectCategory(cat.id);
              context.go('/inventory');
            },
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Container(
              width: 90,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(cat.iconData, size: 22, color: cat.color),
                  const SizedBox(height: 5),
                  Text(
                    cat.name,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showHomeSwitcher(BuildContext context, WidgetRef ref) {
    final homeState = ref.read(homeControllerProvider);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Switch Household',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.md),
                ...homeState.homes.map((h) {
                  final isSelected = h.id == homeState.activeHome?.id;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryContainer : AppColors.surfaceVariant,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.cottage_rounded,
                        size: 20,
                        color: isSelected ? AppColors.primary : AppColors.textMuted,
                      ),
                    ),
                    title: Text(
                      h.name,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text('${h.memberCount} member(s) • ${h.currentUserRole}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Copy Invite Code Shortcut
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.textSecondary),
                          tooltip: 'Copy Invite Code',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: h.inviteCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Copied invite code: ${h.inviteCode}'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                      ],
                    ),
                    onTap: () {
                      ref.read(homeControllerProvider.notifier).switchHome(h);
                      ref.read(dashboardControllerProvider.notifier).loadDashboard();
                      ref.read(inventoryControllerProvider.notifier).loadData();
                      Navigator.pop(context);
                    },
                  );
                }),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.add_home_rounded, color: AppColors.primary),
                  title: const Text('Create New Home', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(context: context, builder: (_) => const CreateHomeDialog());
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.group_add_rounded, color: AppColors.primary),
                  title: const Text('Join Home with Invite Code', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(context: context, builder: (_) => const JoinHomeDialog());
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
