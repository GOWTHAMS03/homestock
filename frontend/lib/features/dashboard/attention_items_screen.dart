import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/household_staples.dart';
import '../home_switcher/home_controller.dart';
import '../inventory/inventory_controller.dart';
import '../inventory/inventory_model.dart';
import '../inventory/smart_confirmation_sheet.dart';
import '../shopping/shopping_controller.dart';
import '../shopping/shopping_model.dart';
import 'dashboard_controller.dart';
import 'dashboard_model.dart';

/// Tab filter options for Attention Items screen
enum _AttentionFilterTab {
  all,
  lowStock,
  expiringSoon,
  outOfStock,
  expired,
}

/// Sort options for Attention Items screen
enum _AttentionSortOption {
  urgency,
  stockLevel,
  expiryDate,
  name,
}

/// Dedicated full screen for maintaining all household products that require attention.
class AttentionItemsScreen extends ConsumerStatefulWidget {
  const AttentionItemsScreen({super.key});

  @override
  ConsumerState<AttentionItemsScreen> createState() => _AttentionItemsScreenState();
}

class _AttentionItemsScreenState extends ConsumerState<AttentionItemsScreen> {
  _AttentionFilterTab _selectedTab = _AttentionFilterTab.all;
  _AttentionSortOption _selectedSort = _AttentionSortOption.urgency;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isBulkAdding = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invState = ref.watch(inventoryControllerProvider);
    final dashState = ref.watch(dashboardControllerProvider);
    final homeState = ref.watch(homeControllerProvider);
    final activeHome = homeState.activeHome;

    // Build unified attention list from inventory items and dashboard summary
    final allAttentionItems = _buildUnifiedAttentionList(invState.items, dashState.summary?.needsAttention);

    // Filter by tab
    final tabFilteredItems = allAttentionItems.where((item) {
      switch (_selectedTab) {
        case _AttentionFilterTab.all:
          return true;
        case _AttentionFilterTab.lowStock:
          return item.isLowStock && !item.isOutOfStock;
        case _AttentionFilterTab.expiringSoon:
          return item.isExpiringSoon && !item.isExpired;
        case _AttentionFilterTab.outOfStock:
          return item.isOutOfStock;
        case _AttentionFilterTab.expired:
          return item.isExpired;
      }
    }).toList();

    // Filter by search query (checks English name, Tamil name, and category)
    final searchFilteredItems = tabFilteredItems.where((item) {
      if (_searchQuery.isEmpty) return true;
      final staple = findStapleForName(item.name);
      final tamilName = staple?.tamilName?.toLowerCase() ?? '';
      return item.name.toLowerCase().contains(_searchQuery) ||
          item.categoryName.toLowerCase().contains(_searchQuery) ||
          tamilName.contains(_searchQuery);
    }).toList();

    // Sort items
    final sortedItems = _sortAttentionItems(searchFilteredItems, _selectedSort);

    // Counts for tabs
    final lowStockCount = allAttentionItems.where((i) => i.isLowStock && !i.isOutOfStock).length;
    final expiringSoonCount = allAttentionItems.where((i) => i.isExpiringSoon && !i.isExpired).length;
    final outOfStockCount = allAttentionItems.where((i) => i.isOutOfStock).length;
    final expiredCount = allAttentionItems.where((i) => i.isExpired).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Things Needing Attention',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFDE68A), width: 0.8),
                  ),
                  child: Text(
                    '${allAttentionItems.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFB45309),
                    ),
                  ),
                ),
              ],
            ),
            if (activeHome != null)
              Text(
                activeHome.name,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        actions: [
          // Bulk Action: Add all low/out of stock items to shopping list
          if (lowStockCount > 0 || outOfStockCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                onPressed: _isBulkAdding
                    ? null
                    : () => _addAllToShoppingList(
                          context,
                          ref,
                          allAttentionItems.where((i) => i.isLowStock || i.isOutOfStock).toList(),
                        ),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFEDE9FE),
                  foregroundColor: const Color(0xFF6D28D9),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  visualDensity: VisualDensity.compact,
                ),
                icon: _isBulkAdding
                    ? const SizedBox(
                        width: 13,
                        height: 13,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6D28D9)),
                      )
                    : const Icon(Icons.playlist_add_check_rounded, size: 16),
                label: const Text(
                  '+ Buy All',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(inventoryControllerProvider.notifier).loadData();
          await ref.read(dashboardControllerProvider.notifier).loadDashboard();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            // 1. Metric Overview Ribbon
            SliverToBoxAdapter(
              child: _buildMetricRibbon(
                totalCount: allAttentionItems.length,
                lowStockCount: lowStockCount,
                expiringSoonCount: expiringSoonCount,
                outOfStockCount: outOfStockCount,
                expiredCount: expiredCount,
              ),
            ),

            // 2. Search & Sort Controls
            SliverToBoxAdapter(
              child: _buildSearchAndSortBar(),
            ),

            // 3. Filter Tabs
            SliverToBoxAdapter(
              child: _buildFilterTabs(
                totalCount: allAttentionItems.length,
                lowStockCount: lowStockCount,
                expiringSoonCount: expiringSoonCount,
                outOfStockCount: outOfStockCount,
                expiredCount: expiredCount,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // 4. Attention Items List
            if (sortedItems.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(allAttentionItems.isEmpty),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = sortedItems[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _AttentionItemCard(
                          item: item,
                          onRefresh: () => ref.read(dashboardControllerProvider.notifier).reloadLocalSummary(),
                        ),
                      );
                    },
                    childCount: sortedItems.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  /// Horizontal ribbon with high-level count metrics
  Widget _buildMetricRibbon({
    required int totalCount,
    required int lowStockCount,
    required int expiringSoonCount,
    required int outOfStockCount,
    required int expiredCount,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildRibbonTile('Low Stock', '$lowStockCount', const Color(0xFFD97706), '🔋'),
          Container(width: 1, height: 26, color: Colors.grey.shade200),
          _buildRibbonTile('Expiring', '$expiringSoonCount', const Color(0xFFEA580C), '⏳'),
          Container(width: 1, height: 26, color: Colors.grey.shade200),
          _buildRibbonTile('Out of Stock', '$outOfStockCount', const Color(0xFFDC2626), '🚨'),
          if (expiredCount > 0) ...[
            Container(width: 1, height: 26, color: Colors.grey.shade200),
            _buildRibbonTile('Expired', '$expiredCount', const Color(0xFF991B1B), '⚠️'),
          ],
        ],
      ),
    );
  }

  Widget _buildRibbonTile(String label, String count, Color color, String emoji) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 4),
            Text(
              count,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  /// Search bar + Sorting dropdown
  Widget _buildSearchAndSortBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
      child: Row(
        children: [
          // Search Input
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outline),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, size: 19, color: AppColors.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(
                        hintText: 'Search by English or தமிழ் name...',
                        hintStyle: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () => _searchController.clear(),
                      child: const Icon(Icons.close_rounded, size: 17, color: AppColors.textMuted),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Sort Dropdown
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outline),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<_AttentionSortOption>(
                value: _selectedSort,
                icon: const Icon(Icons.sort_rounded, size: 18, color: AppColors.primary),
                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                borderRadius: BorderRadius.circular(12),
                items: const [
                  DropdownMenuItem(
                    value: _AttentionSortOption.urgency,
                    child: Text('Urgency'),
                  ),
                  DropdownMenuItem(
                    value: _AttentionSortOption.stockLevel,
                    child: Text('Lowest Stock'),
                  ),
                  DropdownMenuItem(
                    value: _AttentionSortOption.expiryDate,
                    child: Text('Soonest Expiry'),
                  ),
                  DropdownMenuItem(
                    value: _AttentionSortOption.name,
                    child: Text('Name (A-Z)'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedSort = val);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Filter tabs for All, Low Stock, Expiring, Out of Stock, Expired
  Widget _buildFilterTabs({
    required int totalCount,
    required int lowStockCount,
    required int expiringSoonCount,
    required int outOfStockCount,
    required int expiredCount,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
      child: Row(
        children: [
          _buildFilterChip(_AttentionFilterTab.all, 'All', totalCount, const Color(0xFF6366F1)),
          _buildFilterChip(_AttentionFilterTab.lowStock, 'Low Stock 🔋', lowStockCount, const Color(0xFFD97706)),
          _buildFilterChip(_AttentionFilterTab.expiringSoon, 'Expiring Soon ⏳', expiringSoonCount, const Color(0xFFEA580C)),
          _buildFilterChip(_AttentionFilterTab.outOfStock, 'Out of Stock 🚨', outOfStockCount, const Color(0xFFDC2626)),
          if (expiredCount > 0)
            _buildFilterChip(_AttentionFilterTab.expired, 'Expired ⚠️', expiredCount, const Color(0xFF991B1B)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(_AttentionFilterTab tab, String title, int count, Color activeColor) {
    final isSelected = _selectedTab == tab;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => setState(() => _selectedTab = tab),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6.5),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? activeColor : AppColors.outline,
              width: isSelected ? 1.2 : 0.8,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.25) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Empty state when no items need attention or filter matches nothing
  Widget _buildEmptyState(bool isCompletelyEmpty) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🌿', style: TextStyle(fontSize: 34)),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              isCompletelyEmpty ? 'All Good! Everything is Stocked' : 'No items match your filter',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              isCompletelyEmpty
                  ? 'Your household inventory is in healthy shape. No items are expiring or depleted.'
                  : 'Try selecting a different tab or clearing your search.',
              style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () => context.pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Back to Dashboard', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  /// Batch add low stock & out of stock items to the shopping list
  Future<void> _addAllToShoppingList(
    BuildContext context,
    WidgetRef ref,
    List<InventoryItemModel> itemsToAdd,
  ) async {
    if (itemsToAdd.isEmpty) return;
    setState(() => _isBulkAdding = true);

    int addedCount = 0;
    for (final item in itemsToAdd) {
      final neededQty = item.minimumQuantity > 0 ? (item.minimumQuantity - item.quantity).clamp(1.0, 99.0) : 1.0;
      final ok = await ref.read(shoppingControllerProvider.notifier).addItem(
            inventoryItemId: item.id,
            itemName: item.name,
            quantity: neededQty,
            unit: item.unit,
          );
      if (ok) addedCount++;
    }

    setState(() => _isBulkAdding = false);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Text('🛒', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Added $addedCount item${addedCount > 1 ? 's' : ''} to your Shopping List!'),
              ),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Construct unified list from Inventory and Dashboard needsAttention
  List<InventoryItemModel> _buildUnifiedAttentionList(
    List<InventoryItemModel> inventoryItems,
    List<NeedsAttentionModel>? dashboardNeedsAttention,
  ) {
    final Map<String, InventoryItemModel> map = {};

    // 1. Gather all inventory items matching attention criteria
    for (final it in inventoryItems) {
      if (it.isOutOfStock || it.isLowStock || it.isExpiringSoon || it.isExpired) {
        map[it.id] = it;
      }
    }

    // 2. Augment with dashboard summary attention items if any are not yet in map
    if (dashboardNeedsAttention != null) {
      for (final att in dashboardNeedsAttention) {
        if (!map.containsKey(att.itemId)) {
          final matched = inventoryItems.cast<InventoryItemModel?>().firstWhere(
                (i) => i?.id == att.itemId,
                orElse: () => null,
              );
          map[att.itemId] = matched ??
              InventoryItemModel(
                id: att.itemId,
                homeId: '',
                categoryName: att.categoryName,
                categoryIcon: 'inventory',
                categoryColor: '#F59E0B',
                name: att.name,
                quantity: att.quantity,
                unit: att.unit,
                minimumQuantity: 1.0,
                stockStatus: att.stockStatus,
                expiryStatus: att.expiryStatus,
                daysUntilExpiry: att.daysUntilExpiry,
              );
        }
      }
    }

    return map.values.toList();
  }

  /// Sort attention items based on selected criteria
  List<InventoryItemModel> _sortAttentionItems(
    List<InventoryItemModel> list,
    _AttentionSortOption option,
  ) {
    final items = List<InventoryItemModel>.from(list);
    switch (option) {
      case _AttentionSortOption.urgency:
        items.sort((a, b) {
          int weightA = _getUrgencyWeight(a);
          int weightB = _getUrgencyWeight(b);
          return weightB.compareTo(weightA); // Highest urgency first
        });
        break;
      case _AttentionSortOption.stockLevel:
        items.sort((a, b) => a.quantity.compareTo(b.quantity));
        break;
      case _AttentionSortOption.expiryDate:
        items.sort((a, b) {
          final dayA = a.daysUntilExpiry ?? 999;
          final dayB = b.daysUntilExpiry ?? 999;
          return dayA.compareTo(dayB);
        });
        break;
      case _AttentionSortOption.name:
        items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
    }
    return items;
  }

  int _getUrgencyWeight(InventoryItemModel item) {
    if (item.isExpired) return 100;
    if (item.isOutOfStock) return 90;
    if (item.daysUntilExpiry != null && item.daysUntilExpiry! <= 1) return 80;
    if (item.isExpiringSoon) return 70;
    if (item.isLowStock) return 60;
    return 10;
  }
}

/// Rich Attention Product Card with Animated Battery Gauge, Expiry countdown, and Contextual Actions
class _AttentionItemCard extends ConsumerWidget {
  final InventoryItemModel item;
  final VoidCallback onRefresh;

  const _AttentionItemCard({
    required this.item,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staple = findStapleForName(item.name);
    final emoji = staple?.emoji ?? '📦';
    final tamilName = staple?.tamilName;

    final shoppingList = ref.watch(shoppingControllerProvider).list;
    final pendingShoppingItem = shoppingList?.items.cast<ShoppingItemModel?>().firstWhere(
      (s) => !s!.isCompleted &&
             ((s.inventoryItemId != null && s.inventoryItemId == item.id) ||
              s.itemName.toLowerCase().trim() == item.name.toLowerCase().trim()),
      orElse: () => null,
    );
    final isAlreadyOnShoppingList = pendingShoppingItem != null;

    final isOut = item.isOutOfStock;
    final isLow = item.isLowStock && !isOut;
    final isExpiring = item.isExpiringSoon && !item.isExpired;
    final isExpired = item.isExpired;

    // Reference capacity
    final refCap = (item.maximumQuantity != null && item.maximumQuantity! > 0)
        ? item.maximumQuantity!
        : (item.minimumQuantity > 0 ? item.minimumQuantity * 2.0 : (item.quantity > 0 ? item.quantity * 1.5 : 2.0));
    final stockRatio = refCap > 0 ? (item.quantity / refCap).clamp(0.0, 1.0) : 0.0;
    final stockPercent = (stockRatio * 100).round();

    // Theme colors based on urgency
    final Color cardBorder;
    final Color cardBg;
    if (isExpired || isOut) {
      cardBorder = const Color(0xFFFECDD3);
      cardBg = const Color(0xFFFFFBFB);
    } else if (isExpiring) {
      cardBorder = const Color(0xFFFED7AA);
      cardBg = const Color(0xFFFFFDF8);
    } else {
      cardBorder = const Color(0xFFFDE68A);
      cardBg = Colors.white;
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder, width: 1.3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ──── ROW 1: Emoji, Titles (English + Tamil), Category, Urgency Badge ────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Emoji Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isOut
                      ? const Color(0xFFFEE2E2)
                      : (isExpiring ? const Color(0xFFFFEDD5) : const Color(0xFFFEF3C7)),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: isOut
                        ? const Color(0xFFFECDD3)
                        : (isExpiring ? const Color(0xFFFED7AA) : const Color(0xFFFDE68A)),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),

              // Names and Category
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (tamilName != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE9FE),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              tamilName,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF6D28D9),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          item.categoryName,
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                        ),
                        if (item.storageLocation != null && item.storageLocation!.isNotEmpty) ...[
                          const Text(' · ', style: TextStyle(color: Colors.grey)),
                          Text(
                            item.storageLocation!,
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Urgency Badge & Shopping Status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildUrgencyPill(isOut, isLow, isExpiring, isExpired, item),
                  if (isAlreadyOnShoppingList) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFD8B4FE), width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🛒', style: TextStyle(fontSize: 10)),
                          const SizedBox(width: 3),
                          Text(
                            'On List (${pendingShoppingItem.quantity % 1 == 0 ? pendingShoppingItem.quantity.toInt() : pendingShoppingItem.quantity} ${pendingShoppingItem.unit})',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF7E22CE),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ──── ROW 2: Scenario-Specific Details & Animated Battery Meter ────
          if (isOut || isLow)
            _buildLowStockBatterySection(isOut, item, stockRatio, stockPercent)
          else if (isExpiring || isExpired)
            _buildExpiryDetailSection(isExpired, item),

          const SizedBox(height: 12),

          // ──── ROW 3: Contextual Action Buttons ────
          _buildActionButtons(
            context,
            ref,
            isOut,
            isLow,
            isExpiring,
            isExpired,
            isAlreadyOnShoppingList: isAlreadyOnShoppingList,
          ),
        ],
      ),
    );
  }

  /// Urgency status pill badge
  Widget _buildUrgencyPill(bool isOut, bool isLow, bool isExpiring, bool isExpired, InventoryItemModel item) {
    if (isExpired) {
      final days = item.daysUntilExpiry != null ? -item.daysUntilExpiry! : 0;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          days > 0 ? 'Expired $days d ago' : 'Expired',
          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFFB91C1C)),
        ),
      );
    }

    if (isOut) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🚨', style: TextStyle(fontSize: 10)),
            SizedBox(width: 3),
            Text(
              'Out of Stock',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFFB91C1C)),
            ),
          ],
        ),
      );
    }

    if (isExpiring) {
      final days = item.daysUntilExpiry ?? 0;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEDD5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⏳', style: TextStyle(fontSize: 10)),
            const SizedBox(width: 3),
            Text(
              days == 0 ? 'Expires Today!' : 'Expires in $days d',
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFFC2410C)),
            ),
          ],
        ),
      );
    }

    // Low stock
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🔋', style: TextStyle(fontSize: 10)),
          SizedBox(width: 3),
          Text(
            'Low Stock',
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
          ),
        ],
      ),
    );
  }

  /// Low Stock and Out of Stock details featuring the Animated Battery Widget
  Widget _buildLowStockBatterySection(bool isOut, InventoryItemModel item, double stockRatio, int stockPercent) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isOut ? const Color(0xFFFFF1F2) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOut ? const Color(0xFFFECDD3) : const Color(0xFFFDE68A),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          // Animated Battery Gauge
          _AnimatedBatteryGauge(
            ratio: stockRatio,
            isOutOfStock: isOut,
          ),
          const SizedBox(width: 12),

          // Stock Metrics & Capacity Progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isOut
                          ? '0 ${item.unit} remaining'
                          : '${item.quantity == item.quantity.roundToDouble() ? item.quantity.toInt() : item.quantity.toStringAsFixed(1)} of ${item.minimumQuantity.toInt()} ${item.unit} min',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isOut ? const Color(0xFFB91C1C) : const Color(0xFF92400E),
                      ),
                    ),
                    Text(
                      '$stockPercent%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isOut ? const Color(0xFFB91C1C) : const Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: stockRatio,
                    minHeight: 5,
                    backgroundColor: isOut ? Colors.red.shade100 : Colors.amber.shade100,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isOut ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Expiry Soon & Expired details with countdown and meal recommendation
  Widget _buildExpiryDetailSection(bool isExpired, InventoryItemModel item) {
    final days = item.daysUntilExpiry ?? 0;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isExpired ? const Color(0xFFFFF1F2) : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpired ? const Color(0xFFFECDD3) : const Color(0xFFFFEDD5),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isExpired ? Icons.warning_amber_rounded : Icons.schedule_rounded,
                size: 16,
                color: isExpired ? const Color(0xFFDC2626) : const Color(0xFFEA580C),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isExpired
                      ? 'Expired on ${item.expiryDate ?? 'recent date'}. Check quality before using.'
                      : (days == 0
                          ? 'Item expires today! Recommended to consume immediately.'
                          : 'Expires in $days days (${item.expiryDate ?? ''})'),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isExpired ? const Color(0xFFB91C1C) : const Color(0xFF9A3412),
                  ),
                ),
              ),
            ],
          ),
          if (!isExpired) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const SizedBox(width: 22),
                Expanded(
                  child: Text(
                    '💡 Meal Tip: Great to cook or prep in today\'s dinner recipes.',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Action buttons contextual to the scenario
  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    bool isOut,
    bool isLow,
    bool isExpiring,
    bool isExpired, {
    bool isAlreadyOnShoppingList = false,
  }) {
    return Row(
      children: [
        // Primary Action: Add to Shopping List or Navigate to Shopping List
        if (isOut || isLow)
          if (isAlreadyOnShoppingList)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push('/shopping'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF7E22CE),
                  side: const BorderSide(color: Color(0xFFD8B4FE), width: 1.2),
                  backgroundColor: const Color(0xFFFAF5FF),
                  padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 14, color: Color(0xFF7E22CE)),
                label: const Text(
                  'In Shopping List →',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
              ),
            )
          else
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final neededQty = item.minimumQuantity > 0 ? (item.minimumQuantity - item.quantity).clamp(1.0, 99.0) : 1.0;
                  final success = await ref.read(shoppingControllerProvider.notifier).addItem(
                        inventoryItemId: item.id,
                        itemName: item.name,
                        quantity: neededQty,
                        unit: item.unit,
                      );
                  if (context.mounted && success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Text('🛒', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text('Added "${item.name}" ($neededQty ${item.unit}) to Shopping List'),
                            ),
                          ],
                        ),
                        backgroundColor: AppColors.primary,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.add_shopping_cart_rounded, size: 14),
                label: const Text(
                  '+ Add to Buy',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
              ),
            )
        else if (isExpiring)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                // Quick consume: reduce 1 unit or mark consumed
                final consumeQty = item.quantity >= 1.0 ? 1.0 : item.quantity;
                final ok = await ref.read(inventoryControllerProvider.notifier).updateStock(
                      item.id,
                      'CONSUME',
                      consumeQty,
                      'Consumed before expiry',
                    );
                if (context.mounted && ok) {
                  onRefresh();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Marked "$consumeQty ${item.unit}" of ${item.name} as consumed 👍'),
                      backgroundColor: const Color(0xFF059669),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEA580C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              icon: const Icon(Icons.restaurant_rounded, size: 14),
              label: const Text(
                'Consume / Use',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
              ),
            ),
          )
        else if (isExpired)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                // Discard / zero out stock
                final ok = await ref.read(inventoryControllerProvider.notifier).updateStock(
                      item.id,
                      'DISCARD',
                      item.quantity,
                      'Expired discard',
                    );
                if (context.mounted && ok) {
                  onRefresh();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Cleared expired stock of ${item.name} 🗑️'),
                      backgroundColor: Colors.grey.shade800,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              icon: const Icon(Icons.delete_outline_rounded, size: 14),
              label: const Text(
                'Discard Stock',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
              ),
            ),
          ),

        const SizedBox(width: 8),

        // Secondary Action: Quick Confirm / Level Check
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => SmartConfirmationSheet.show(context, item),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.check_circle_outline_rounded, size: 14, color: AppColors.primary),
            label: const Text(
              'Quick Confirm',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

/// Animated Battery Gauge with breathing/pulsing charge bars
class _AnimatedBatteryGauge extends StatefulWidget {
  final double ratio; // 0.0 to 1.0
  final bool isOutOfStock;

  const _AnimatedBatteryGauge({
    required this.ratio,
    required this.isOutOfStock,
  });

  @override
  State<_AnimatedBatteryGauge> createState() => _AnimatedBatteryGaugeState();
}

class _AnimatedBatteryGaugeState extends State<_AnimatedBatteryGauge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Battery colors
    final Color borderColor;
    final Color barColor;

    if (widget.isOutOfStock || widget.ratio <= 0.05) {
      borderColor = const Color(0xFFEF4444);
      barColor = const Color(0xFFDC2626);
    } else if (widget.ratio <= 0.35) {
      borderColor = const Color(0xFFF59E0B);
      barColor = const Color(0xFFEA580C);
    } else {
      borderColor = const Color(0xFF10B981);
      barColor = const Color(0xFF059669);
    }

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        // Breathing pulse when low or out of stock
        final pulseVal = _pulseController.value;
        final glowAlpha = 0.2 + (pulseVal * 0.35);

        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Main Battery Body
            Container(
              width: 38,
              height: 20,
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: borderColor, width: 1.6),
                boxShadow: [
                  BoxShadow(
                    color: borderColor.withValues(alpha: glowAlpha),
                    blurRadius: 4,
                    spreadRadius: 0.5,
                  ),
                ],
              ),
              child: widget.isOutOfStock
                  ? Center(
                      child: Text(
                        '!',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: borderColor,
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        // Segmented Animated Bars
                        _buildBatterySegment(0, widget.ratio, barColor, pulseVal),
                        const SizedBox(width: 1.5),
                        _buildBatterySegment(1, widget.ratio, barColor, pulseVal),
                        const SizedBox(width: 1.5),
                        _buildBatterySegment(2, widget.ratio, barColor, pulseVal),
                      ],
                    ),
            ),

            // Battery Terminal Notch
            Container(
              width: 2.8,
              height: 8,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(2)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBatterySegment(int segmentIndex, double ratio, Color color, double pulse) {
    // 3 segments total: 0-33%, 34-66%, 67-100%
    final segmentThreshold = (segmentIndex + 1) / 3.0;
    final isFilled = ratio >= (segmentThreshold - 0.2);

    if (!isFilled) {
      return Expanded(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
      );
    }

    // Segment is active: pulse intensity
    final activeColor = color.withValues(alpha: 0.75 + (pulse * 0.25));

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: activeColor,
          borderRadius: BorderRadius.circular(1.5),
        ),
      ),
    );
  }
}

