import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/offline_wifi_badge.dart';
import '../../core/widgets/skeleton_loader.dart';

import '../auth/auth_controller.dart';
import '../barcode/widgets/barcode_scanner_widget.dart';
import '../home_switcher/create_home_dialog.dart';
import '../home_switcher/home_controller.dart';
import '../home_switcher/join_home_dialog.dart';
import '../inventory/add_edit_item_screen.dart';
import '../inventory/inventory_controller.dart';
import '../inventory/inventory_model.dart';
import '../notifications/notification_controller.dart';
import '../shopping/shopping_controller.dart';
import '../shopping/shopping_model.dart';

import 'dashboard_controller.dart';
import 'dashboard_model.dart';

/// HomeStock Minimal Home Screen
///
/// Design Philosophy: "Less information. More usefulness."
/// Answers 3 fundamental questions:
/// 1. Is there anything I need to know? (Needs Attention)
/// 2. Is there anything I need to do? (Shopping)
/// 3. What is the fastest useful action? (Quick Actions)
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final homeState = ref.watch(homeControllerProvider);
    final dashboardState = ref.watch(dashboardControllerProvider);
    final notifState = ref.watch(notificationControllerProvider);
    final shoppingState = ref.watch(shoppingControllerProvider);
    final invState = ref.watch(inventoryControllerProvider);

    final activeHome = homeState.activeHome;
    final summary = dashboardState.summary;

    // 1. Initial Home Loading State
    if (homeState.isLoading && activeHome == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          title: const Text('HomeStock', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: const [
            SkeletonLoader(width: 180, height: 24),
            SizedBox(height: 8),
            SkeletonLoader(width: 240, height: 14),
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
          backgroundColor: AppColors.surface,
          elevation: 0,
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

    final attentionItems = _prioritizeAttentionItems(summary?.needsAttention ?? [], invState.items);
    final pendingShoppingItems = (shoppingState.list?.items ?? [])
        .where((i) => !i.isCompleted)
        .toList();
    final singleInsight = dashboardState.homeInsight?.insights.isNotEmpty == true
        ? dashboardState.homeInsight!.insights.first
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            await ref.read(dashboardControllerProvider.notifier).loadDashboard();
            await ref.read(inventoryControllerProvider.notifier).loadData();
            await ref.read(shoppingControllerProvider.notifier).loadShoppingList();
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
            children: [
              // 1. Calm Header
              _buildHeader(
                context,
                ref,
                activeHome,
                notifState.unreadCount,
                authState.user?.fullName,
              ),
              const SizedBox(height: AppSpacing.lg),

              // 2. Compact Quick Actions
              _buildQuickActions(context),
              const SizedBox(height: AppSpacing.xl),

              // 3. Main Intelligence: NEEDS ATTENTION (or Calm Empty State)
              _buildNeedsAttentionSection(context, ref, attentionItems),
              const SizedBox(height: AppSpacing.xl),

              // 4. Action-Focused: SHOPPING
              _buildShoppingSection(context, ref, pendingShoppingItems),

              // 5. Optional Small Insight (Section 8 & 29)
              if (singleInsight != null) ...[
                const SizedBox(height: AppSpacing.xl),
                _buildSingleInsight(context, singleInsight),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Calm Header answering: Greeting, Active Home, and Subtle Online/Offline Status
  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    dynamic activeHome,
    int unreadNotifications,
    String? fullName,
  ) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning 👋'
        : (hour < 17 ? 'Good afternoon 👋' : 'Good evening 👋');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 3),
              InkWell(
                onTap: () => _showHomeSwitcher(context, ref),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        activeHome?.name ?? 'My Home',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // Subtle Status Indicator: ● Online / ● Offline · Changes will sync automatically
              const SubtleStatusIndicator(showSyncNote: true),
            ],
          ),
        ),
        // Notification Icon (Quiet & Unbloated)
        IconButton(
          onPressed: () => context.push('/notifications'),
          tooltip: 'Notifications',
          icon: unreadNotifications > 0
              ? Badge(
                  label: Text(
                    '$unreadNotifications',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 10, color: Colors.white),
                  ),
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.notifications_outlined, size: 22, color: AppColors.textPrimary),
                )
              : const Icon(Icons.notifications_outlined, size: 22, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  /// Compact Quick Actions (Section 19: + Add Item, Scan, Shopping)
  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionButton(
            context,
            icon: Icons.add_rounded,
            label: 'Add Item',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddEditItemScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildQuickActionButton(
            context,
            icon: Icons.qr_code_scanner_rounded,
            label: 'Scan',
            onTap: () => BarcodeScannerWidget.open(context),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildQuickActionButton(
            context,
            icon: Icons.shopping_cart_outlined,
            label: 'Shopping',
            onTap: () => context.go('/shopping'),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.outline, width: 0.8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Smart prioritization of attention items (Section 11)
  /// 1. Out of stock
  /// 2. Critical low stock
  /// 3. Expiring soon
  List<NeedsAttentionModel> _prioritizeAttentionItems(
    List<NeedsAttentionModel> rawAttention,
    List<InventoryItemModel> inventoryItems,
  ) {
    final list = [...rawAttention];

    // Merge in any low stock / out of stock / expiring from inventory if summary list is light
    if (list.isEmpty) {
      for (final it in inventoryItems) {
        if (it.isOutOfStock || it.isLowStock || it.isExpiringSoon) {
          list.add(NeedsAttentionModel(
            itemId: it.id,
            name: it.name,
            categoryName: it.categoryName,
            stockStatus: it.stockStatus,
            expiryStatus: it.expiryStatus,
            quantity: it.quantity,
            unit: it.unit,
            reasonMessage: it.isOutOfStock
                ? 'Out of stock'
                : (it.isLowStock ? 'Running low' : 'Expiring soon'),
          ));
        }
      }
    }

    list.sort((a, b) {
      final aPriority = _urgencyPriority(a);
      final bPriority = _urgencyPriority(b);
      return aPriority.compareTo(bPriority);
    });

    return list;
  }

  int _urgencyPriority(NeedsAttentionModel item) {
    if (item.stockStatus == 'OUT_OF_STOCK' || item.quantity <= 0) return 1;
    if (item.stockStatus == 'LOW_STOCK') return 2;
    if (item.expiryStatus == 'EXPIRED') return 3;
    if (item.expiryStatus == 'EXPIRING_SOON') return 4;
    return 5;
  }

  /// Main Intelligence Section: NEEDS ATTENTION
  Widget _buildNeedsAttentionSection(
    BuildContext context,
    WidgetRef ref,
    List<NeedsAttentionModel> items,
  ) {
    // Empty Home State (Section 12)
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.outline, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.inStockBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.check_rounded, size: 14, color: AppColors.inStockText),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Everything looks good',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Your home is well stocked. Nothing needs your attention right now.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ],
        ),
      );
    }

    // Needs Attention List (Section 10)
    final previewItems = items.take(3).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.outline, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'NEEDS ATTENTION',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              InkWell(
                onTap: () => context.push('/attention'),
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'View all',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${items.length} ${items.length == 1 ? 'thing needs' : 'things need'} your attention',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),

          // Clean Bullet Rows
          ...previewItems.map((it) {
            final reason = _cleanReasonText(it);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  ', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary),
                        children: [
                          TextSpan(
                            text: _formatName(it.name),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(
                            text: ' — $reason',
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 14),
          // Clean Outlined View Button
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton(
              onPressed: () => context.push('/attention'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.outline),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
              ),
              child: const Text(
                'View',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _cleanReasonText(NeedsAttentionModel it) {
    if (it.stockStatus == 'OUT_OF_STOCK' || it.quantity <= 0) return 'out of stock';
    if (it.expiryStatus == 'EXPIRED') return 'expired';
    if (it.expiryStatus == 'EXPIRING_SOON') {
      return it.daysUntilExpiry != null
          ? (it.daysUntilExpiry! <= 1 ? 'expires tomorrow' : 'expires in ${it.daysUntilExpiry} days')
          : 'expiring soon';
    }
    if (it.reasonMessage.isNotEmpty) {
      return it.reasonMessage.toLowerCase();
    }
    return 'low stock';
  }

  /// SHOPPING Section (Section 8 & 21)
  Widget _buildShoppingSection(
    BuildContext context,
    WidgetRef ref,
    List<ShoppingItemModel> pendingItems,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.outline, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SHOPPING',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              if (pendingItems.isNotEmpty)
                Text(
                  '${pendingItems.length} items',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          if (pendingItems.isEmpty) ...[
            const Text(
              'Shopping list is clear',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Nothing to buy right now.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ] else ...[
            ...pendingItems.take(3).map((item) {
              final qtyStr = item.quantity > 0
                  ? ' — ${item.quantity == item.quantity.roundToDouble() ? item.quantity.toInt() : item.quantity.toStringAsFixed(1)} ${item.unit}'
                  : '';
              return InkWell(
                onTap: () {
                  ref.read(shoppingControllerProvider.notifier).toggleItem(item.id);
                },
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Checkbox(
                          value: item.isCompleted,
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          side: const BorderSide(color: AppColors.outline, width: 1.2),
                          onChanged: (_) {
                            ref.read(shoppingControllerProvider.notifier).toggleItem(item.id);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary),
                            children: [
                              TextSpan(
                                text: _formatName(item.itemName),
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              TextSpan(
                                text: qtyStr,
                                style: const TextStyle(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],

          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton(
              onPressed: () => context.go('/shopping'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.outline),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
              ),
              child: const Text(
                'Open Shopping List',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Optional Small Household Insight (Section 8, 9, 29: Quiet, human, no fake AI badges)
  Widget _buildSingleInsight(BuildContext context, String insight) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.outline, width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              insight,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Multi-Household Switcher Bottom Sheet
  void _showHomeSwitcher(BuildContext context, WidgetRef ref) {
    final homeState = ref.read(homeControllerProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
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
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.outline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                  'Switch Household',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.md),
                ...homeState.homes.map((h) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.cottage_rounded, color: AppColors.primary, size: 18),
                      ),
                      title: Text(h.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                      subtitle: Text('${h.memberCount} member(s)', style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                      trailing: h.id == homeState.activeHome?.id
                          ? const Icon(Icons.check_rounded, color: AppColors.primary, size: 18)
                          : null,
                      onTap: () {
                        ref.read(homeControllerProvider.notifier).switchHome(h);
                        Navigator.pop(context);
                      },
                    )),
                const Divider(height: 16, color: AppColors.outline),
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.add_home_rounded, color: AppColors.textPrimary, size: 18),
                  ),
                  title: const Text('Create New Home', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13.5)),
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(context: context, builder: (_) => const CreateHomeDialog());
                  },
                ),
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.textPrimary, size: 18),
                  ),
                  title: const Text('Join Home (Invite code)', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13.5)),
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

  String _formatName(String name) {
    if (name.isEmpty) return name;
    return name.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}

