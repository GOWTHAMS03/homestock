import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/household_staples.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../voice/widgets/voice_input_button.dart';
import '../voice/widgets/voice_bottom_sheet.dart';
import '../barcode/widgets/barcode_scanner_widget.dart';
import '../notifications/notifications_screen.dart';
import '../shopping/shopping_controller.dart';
import '../shopping/shopping_model.dart';
import 'add_edit_item_screen.dart';
import 'category_model.dart';
import 'inventory_controller.dart';
import 'inventory_model.dart';
import 'item_detail_screen.dart';
import 'stock_update_dialog.dart';
import 'staple_quantity_details_sheet.dart';

enum InventorySortOption {
  defaultOrder,
  nameAsc,
  quantityAsc,
  quantityDesc,
  expiringSoon,
}

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _searchController = TextEditingController();
  bool _isSelectionMode = false;
  final Set<String> _selectedItemIds = {};
  InventorySortOption _currentSort = InventorySortOption.defaultOrder;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openQuickStockOut(InventoryItemModel item) {
    showDialog(
      context: context,
      builder: (_) => StockUpdateDialog(
        item: item,
        transactionType: 'STOCK_OUT',
        onConfirm: (qty, reason) async {
          return await ref
              .read(inventoryControllerProvider.notifier)
              .updateStock(item.id, 'STOCK_OUT', qty, reason);
        },
      ),
    );
  }

  Future<void> _handleDecrement(InventoryItemModel item) async {
    HapticFeedback.lightImpact();
    if (item.quantity <= 1.0) {
      _openQuickStockOut(item);
    } else {
      final success = await ref
          .read(inventoryControllerProvider.notifier)
          .updateStock(item.id, 'STOCK_OUT', 1.0, 'Consumed / Used');
      if (mounted && success) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Used 1 ${item.unit} of ${_formatName(item.name)}'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Details',
              onPressed: () => _openQuickStockOut(item),
            ),
          ),
        );
      }
    }
  }

  void _handleIncrement(InventoryItemModel item) {
    HapticFeedback.lightImpact();
    ref
        .read(inventoryControllerProvider.notifier)
        .updateStock(item.id, 'STOCK_IN', 1.0, 'Restocked');
  }

  String _formatName(String raw) {
    if (raw.trim().isEmpty) return '';
    final words = raw.trim().split(RegExp(r'\s+'));
    return words.map((w) {
      if (w.isEmpty) return '';
      return '${w[0].toUpperCase()}${w.substring(1)}';
    }).join(' ');
  }

  String _getItemEmoji(String name, String? category) {
    final staple = findStapleForName(name, category);
    if (staple != null && staple.emoji.isNotEmpty) {
      return staple.emoji;
    }
    final lower = name.toLowerCase().trim();
    if (lower.contains('milk')) return '🥛';
    if (lower.contains('cheese') || lower.contains('paneer')) return '🧀';
    if (lower.contains('rice')) return '🍚';
    if (lower.contains('onion')) return '🧅';
    if (lower.contains('egg')) return '🥚';
    if (lower.contains('oil') || lower.contains('ghee')) return '🫒';
    if (lower.contains('bread') || lower.contains('toast')) return '🍞';
    if (lower.contains('butter')) return '🧈';
    if (lower.contains('tomato')) return '🍅';
    if (lower.contains('potato') || lower.contains('aloo')) return '🥔';
    if (lower.contains('garlic')) return '🧄';
    if (lower.contains('ginger')) return '🫚';
    if (lower.contains('apple')) return '🍎';
    if (lower.contains('banana')) return '🍌';
    if (lower.contains('sugar')) return '🍬';
    if (lower.contains('salt')) return '🧂';
    if (lower.contains('tea') || lower.contains('chai')) return '🍵';
    if (lower.contains('coffee')) return '☕';
    if (lower.contains('flour') || lower.contains('atta') || lower.contains('maida')) return '🌾';
    if (lower.contains('dhal') || lower.contains('dal') || lower.contains('lentil')) return '🥣';
    if (lower.contains('biscuit') || lower.contains('cookie') || lower.contains('snack')) return '🍪';
    if (lower.contains('soap') || lower.contains('wash')) return '🧼';
    if (lower.contains('shampoo')) return '🧴';
    if (lower.contains('detergent') || lower.contains('clean')) return '🧹';
    if (lower.contains('water') || lower.contains('juice')) return '🧃';
    if (lower.contains('chicken') || lower.contains('meat')) return '🍗';
    if (lower.contains('fish')) return '🐟';

    final cat = (category ?? '').toLowerCase();
    if (cat.contains('kitchen')) return '🍳';
    if (cat.contains('clean')) return '🧼';
    if (cat.contains('personal')) return '🧴';
    if (cat.contains('snack')) return '🍪';
    return '📦';
  }

  void _openStapleQuantityAndDetails(HouseholdStaple staple) {
    HapticFeedback.lightImpact();
    final invState = ref.read(inventoryControllerProvider);
    final existing = invState.items.cast<InventoryItemModel?>().firstWhere(
          (item) => item?.name.trim().toLowerCase() == staple.name.trim().toLowerCase(),
          orElse: () => null,
        );

    StapleQuantityDetailsSheet.show(
      context,
      staple: staple,
      existingItem: existing,
    );
  }

  Future<void> _addItemToShoppingList(InventoryItemModel item, [double? quantity]) async {
    HapticFeedback.lightImpact();
    final neededQty = quantity ?? (item.minimumQuantity > item.quantity
        ? (item.minimumQuantity - item.quantity)
        : 1.0);

    final success = await ref.read(shoppingControllerProvider.notifier).addItem(
          inventoryItemId: item.id,
          itemName: item.name,
          quantity: neededQty,
          unit: item.unit,
          categoryId: item.categoryId,
          categoryName: item.categoryName,
          categoryIcon: item.categoryIcon,
          categoryColor: item.categoryColor,
        );

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (success) {
        final qtyStr = '${neededQty.toStringAsFixed(neededQty.truncateToDouble() == neededQty ? 0 : 1)} ${item.unit}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Added ${_formatName(item.name)} ($qtyStr) to shopping list!',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF0F172A),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        final error = ref.read(shoppingControllerProvider).errorMessage ??
            'Could not add ${_formatName(item.name)} to shopping list';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _addSelectedToShoppingList(List<InventoryItemModel> allItems) async {
    final selectedItems = allItems.where((i) => _selectedItemIds.contains(i.id)).toList();
    if (selectedItems.isEmpty) return;

    int addedCount = 0;
    for (final item in selectedItems) {
      final neededQty = item.minimumQuantity > item.quantity
          ? (item.minimumQuantity - item.quantity)
          : 1.0;
      final ok = await ref.read(shoppingControllerProvider.notifier).addItem(
            inventoryItemId: item.id,
            itemName: item.name,
            quantity: neededQty,
            unit: item.unit,
            categoryId: item.categoryId,
            categoryName: item.categoryName,
            categoryIcon: item.categoryIcon,
            categoryColor: item.categoryColor,
          );
      if (ok) addedCount++;
    }

    if (mounted) {
      setState(() {
        _isSelectionMode = false;
        _selectedItemIds.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added $addedCount created items to shopping list 🛒'),
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showAllEssentialsBottomSheet(BuildContext context, List<InventoryItemModel> existingItems) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AllEssentialsModal(
        existingItems: existingItems,
        onSelectStaple: (staple) {
          Navigator.of(ctx).pop();
          _openStapleQuantityAndDetails(staple);
        },
        onAddToShoppingList: _addItemToShoppingList,
      ),
    );
  }

  List<InventoryItemModel> _applySorting(List<InventoryItemModel> items) {
    final list = List<InventoryItemModel>.from(items);
    switch (_currentSort) {
      case InventorySortOption.defaultOrder:
        return list;
      case InventorySortOption.nameAsc:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        return list;
      case InventorySortOption.quantityAsc:
        list.sort((a, b) => a.quantity.compareTo(b.quantity));
        return list;
      case InventorySortOption.quantityDesc:
        list.sort((a, b) => b.quantity.compareTo(a.quantity));
        return list;
      case InventorySortOption.expiringSoon:
        list.sort((a, b) {
          if (a.daysUntilExpiry == null && b.daysUntilExpiry == null) return 0;
          if (a.daysUntilExpiry == null) return 1;
          if (b.daysUntilExpiry == null) return -1;
          return a.daysUntilExpiry!.compareTo(b.daysUntilExpiry!);
        });
        return list;
    }
  }

  void _showSortBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Sort Inventory Items',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E1B4B),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildSortTile(
                title: 'Default Order',
                option: InventorySortOption.defaultOrder,
                icon: Icons.sort_rounded,
              ),
              _buildSortTile(
                title: 'Name (A to Z)',
                option: InventorySortOption.nameAsc,
                icon: Icons.sort_by_alpha_rounded,
              ),
              _buildSortTile(
                title: 'Quantity (Low to High)',
                option: InventorySortOption.quantityAsc,
                icon: Icons.trending_up_rounded,
              ),
              _buildSortTile(
                title: 'Quantity (High to Low)',
                option: InventorySortOption.quantityDesc,
                icon: Icons.trending_down_rounded,
              ),
              _buildSortTile(
                title: 'Expiring Soonest',
                option: InventorySortOption.expiringSoon,
                icon: Icons.access_time_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortTile({
    required String title,
    required InventorySortOption option,
    required IconData icon,
  }) {
    final isSelected = _currentSort == option;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF64748B),
        size: 20,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
          color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF6366F1), size: 20)
          : null,
      onTap: () {
        setState(() => _currentSort = option);
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final invState = ref.watch(inventoryControllerProvider);
    final displayedItems = _applySorting(invState.filteredItems);

    final rawCategories = invState.categories.isNotEmpty
        ? invState.categories
        : CategoryModel.defaultCategories();

    final uniqueCategories = <CategoryModel>[];
    final seenNames = <String>{};
    for (final cat in rawCategories) {
      final norm = cat.name.trim().toLowerCase();
      if (!seenNames.contains(norm)) {
        seenNames.add(norm);
        uniqueCategories.add(cat);
      }
    }

    final lowStockCount = invState.items
        .where((i) => i.stockStatus == 'LOW_STOCK' || i.stockStatus == 'OUT_OF_STOCK')
        .length;
    final expiringCount = invState.items
        .where((i) => i.expiryStatus == 'EXPIRING_SOON' || i.expiryStatus == 'EXPIRED')
        .length;
    final needsAttentionCount = lowStockCount + expiringCount;

    final attentionItems = invState.items
        .where((i) =>
            i.stockStatus == 'LOW_STOCK' ||
            i.stockStatus == 'OUT_OF_STOCK' ||
            i.expiryStatus == 'EXPIRING_SOON' ||
            i.expiryStatus == 'EXPIRED')
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => ref.read(inventoryControllerProvider.notifier).loadData(),
          color: const Color(0xFF6366F1),
          child: CustomScrollView(
            slivers: [
              // 1. Top Header
              SliverToBoxAdapter(
                child: _buildTopHeader(context, invState, needsAttentionCount),
              ),

              // 2. Search Bar
              SliverToBoxAdapter(
                child: _buildSearchBar(context),
              ),

              // 3. Status Filter Row (3 horizontal pills)
              SliverToBoxAdapter(
                child: _buildStatusFilterRow(
                  context,
                  invState,
                  invState.items.length,
                  lowStockCount,
                  expiringCount,
                ),
              ),

              // 4. Category Square Tiles
              SliverToBoxAdapter(
                child: _buildCategorySquareTiles(
                  context,
                  invState,
                  uniqueCategories,
                ),
              ),

              // 5. Quick Add Staples Card
              SliverToBoxAdapter(
                child: _buildQuickAddStaplesCard(context, invState.items),
              ),

              // 6. Needs Attention Card (if any urgent items)
              if (attentionItems.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildNeedsAttentionSection(
                    context,
                    attentionItems,
                    lowStockCount,
                    expiringCount,
                  ),
                ),

              // 7. "All Items (N)" Section Header
              SliverToBoxAdapter(
                child: _buildAllItemsHeader(context, displayedItems.length),
              ),

              // 8. Inventory Items List or Empty/Skeleton State
              if (invState.isLoading && invState.items.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: SkeletonItemCard(),
                      ),
                      childCount: 4,
                    ),
                  ),
                )
              else if (displayedItems.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: EmptyStateView(
                      icon: Icons.inventory_2_outlined,
                      title: 'No items found',
                      message: invState.searchQuery.isNotEmpty
                          ? 'No products matched "${invState.searchQuery}".'
                          : (invState.filterType != InventoryFilterType.all
                              ? 'No items match the active status filter.'
                              : 'Your household inventory is empty. Add your first item!'),
                      actionLabel: invState.searchQuery.isEmpty &&
                              invState.filterType == InventoryFilterType.all
                          ? 'Add First Item'
                          : 'Reset Filters',
                      onAction: () {
                        if (invState.searchQuery.isNotEmpty ||
                            invState.filterType != InventoryFilterType.all) {
                          _searchController.clear();
                          ref.read(inventoryControllerProvider.notifier).setSearchQuery('');
                          ref.read(inventoryControllerProvider.notifier).setFilterType(InventoryFilterType.all);
                          ref.read(inventoryControllerProvider.notifier).selectCategory(null);
                        } else {
                          _showAddItemMenu(context, invState.items);
                        }
                      },
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = displayedItems[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildItemCard(context, item),
                        );
                      },
                      childCount: displayedItems.length,
                    ),
                  ),
                ),

              // Bottom spacing for floating bottom navigation bar
              const SliverToBoxAdapter(
                child: SizedBox(height: 120),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 75),
        child: FloatingActionButton.extended(
          onPressed: () => _showAddItemMenu(context, invState.items),
          icon: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
          label: const Text(
            'Add Item',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Colors.white),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        ),
      ),
      bottomNavigationBar: _isSelectionMode
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    offset: const Offset(0, -3),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedItemIds.isEmpty
                                ? 'Tap items to select'
                                : '${_selectedItemIds.length} item(s) selected',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                              color: Color(0xFF1E1B4B),
                            ),
                          ),
                          const Text(
                            'Add to your shopping list with 1 tap',
                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    if (_selectedItemIds.isEmpty)
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _selectedItemIds.addAll(displayedItems.map((i) => i.id));
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Select All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: () => _addSelectedToShoppingList(invState.items),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                        label: Text(
                          'Add to Shopping List (${_selectedItemIds.length})',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                        ),
                      ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  // ==========================================
  // SECTION 1: TOP HEADER
  // ==========================================
  Widget _buildTopHeader(BuildContext context, InventoryState invState, int needsAttentionCount) {
    return Padding(
      padding: const EdgeInsets.only(left: 18, right: 18, top: 12, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // House outline icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE0E7FF), width: 1.2),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.home_outlined,
              color: Color(0xFF6366F1),
              size: 26,
            ),
          ),
          const SizedBox(width: 12),

          // Title + Dynamic Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'Household Inventory',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E1B4B),
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${invState.items.length} ${invState.items.length == 1 ? "item" : "items"} tracked',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Text(
                        '  •  ',
                        style: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                      ),
                      Text(
                        needsAttentionCount > 0
                            ? '$needsAttentionCount needs attention'
                            : 'All stocked',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: needsAttentionCount > 0 ? const Color(0xFFD97706) : const Color(0xFF16A34A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Notification Bell with Red Badge
          InkWell(
            onTap: () {
              try {
                context.push('/notifications');
              } catch (_) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                );
              }
            },
            borderRadius: BorderRadius.circular(50),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: Color(0xFF1E293B),
                    size: 22,
                  ),
                ),
                Positioned(
                  top: 7,
                  right: 8,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
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

  // ==========================================
  // SECTION 2: SEARCH BAR
  // ==========================================
  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) => ref.read(inventoryControllerProvider.notifier).setSearchQuery(val),
          style: const TextStyle(fontSize: 13.5, color: Color(0xFF1E293B)),
          decoration: InputDecoration(
            hintText: 'Search anything... (pantry, fridge, spice...)',
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            prefixIcon: const Icon(Icons.search_rounded, size: 21, color: Color(0xFF6366F1)),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 13),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF94A3B8)),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(inventoryControllerProvider.notifier).setSearchQuery('');
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 20, color: Color(0xFF6366F1)),
                  tooltip: 'Scan Barcode',
                  onPressed: () => BarcodeScannerWidget.open(context),
                ),
                const VoiceInputButton(size: 20, color: Color(0xFF6366F1), tooltip: 'Voice search'),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SECTION 3: STATUS FILTER ROW (3 PILLS)
  // ==========================================
  Widget _buildStatusFilterRow(
    BuildContext context,
    InventoryState invState,
    int totalCount,
    int lowStockCount,
    int expiringCount,
  ) {
    final isAll = invState.filterType == InventoryFilterType.all;
    final isLow = invState.filterType == InventoryFilterType.lowStock;
    final isExpiring = invState.filterType == InventoryFilterType.expiringSoon;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pill 1: All
          _buildStatusPill(
            label: 'All',
            count: totalCount,
            isSelected: isAll,
            activeBg: primaryColor,
            activeFg: Colors.white,
            badgeActiveBg: primaryColor.withValues(alpha: 0.7),
            badgeActiveFg: Colors.white,
            badgeInactiveBg: const Color(0xFFF1F5F9),
            badgeInactiveFg: const Color(0xFF64748B),
            onTap: () => ref.read(inventoryControllerProvider.notifier).setFilterType(InventoryFilterType.all),
          ),
          const SizedBox(width: 8),

          // Pill 2: Low Stock
          _buildStatusPill(
            label: 'Low Stock',
            count: lowStockCount,
            icon: Icons.warning_amber_rounded,
            iconColor: const Color(0xFFEA580C),
            isSelected: isLow,
            activeBg: const Color(0xFFFFF1F2),
            activeBorder: const Color(0xFFFDA4AF),
            activeFg: const Color(0xFFE11D48),
            badgeActiveBg: const Color(0xFFFEE2E2),
            badgeActiveFg: const Color(0xFFDC2626),
            badgeInactiveBg: const Color(0xFFFEE2E2),
            badgeInactiveFg: const Color(0xFFDC2626),
            onTap: () => ref.read(inventoryControllerProvider.notifier).setFilterType(
              isLow ? InventoryFilterType.all : InventoryFilterType.lowStock,
            ),
          ),
          const SizedBox(width: 8),

          // Pill 3: Expiring
          _buildStatusPill(
            label: 'Expiring',
            count: expiringCount,
            icon: Icons.access_time_rounded,
            iconColor: const Color(0xFF10B981),
            isSelected: isExpiring,
            activeBg: const Color(0xFFFFFBEB),
            activeBorder: const Color(0xFFFCD34D),
            activeFg: const Color(0xFFD97706),
            badgeActiveBg: const Color(0xFFFEF3C7),
            badgeActiveFg: const Color(0xFFD97706),
            badgeInactiveBg: const Color(0xFFFEF3C7),
            badgeInactiveFg: const Color(0xFFD97706),
            onTap: () => ref.read(inventoryControllerProvider.notifier).setFilterType(
              isExpiring ? InventoryFilterType.all : InventoryFilterType.expiringSoon,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill({
    required String label,
    required int count,
    IconData? icon,
    Color? iconColor,
    required bool isSelected,
    required Color activeBg,
    Color? activeBorder,
    required Color activeFg,
    required Color badgeActiveBg,
    required Color badgeActiveFg,
    required Color badgeInactiveBg,
    required Color badgeInactiveFg,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isSelected ? activeBg : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isSelected
                  ? (activeBorder ?? activeBg)
                  : const Color(0xFFE2E8F0),
              width: isSelected ? 1.4 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? activeBg.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: isSelected ? activeFg : iconColor),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? activeFg : const Color(0xFF334155),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected ? badgeActiveBg : badgeInactiveBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? badgeActiveFg : badgeInactiveFg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SECTION 4: CATEGORY SQUARE TILES
  // ==========================================
  Widget _buildCategorySquareTiles(
    BuildContext context,
    InventoryState invState,
    List<CategoryModel> categories,
  ) {
    final standardTiles = [
      _CategoryTileData(
        id: null,
        name: 'All',
        icon: Icons.grid_view_rounded,
        color: const Color(0xFF6366F1),
      ),
      _CategoryTileData(
        id: 'Kitchen',
        name: 'Kitchen',
        icon: Icons.restaurant_rounded,
        color: const Color(0xFFF59E0B),
      ),
      _CategoryTileData(
        id: 'Cleaning',
        name: 'Cleaning',
        icon: Icons.cleaning_services_rounded,
        color: const Color(0xFF3B82F6),
      ),
      _CategoryTileData(
        id: 'Personal',
        name: 'Personal',
        icon: Icons.face_rounded,
        color: const Color(0xFFA855F7),
      ),
      _CategoryTileData(
        id: 'Snacks',
        name: 'Snacks',
        icon: Icons.cookie_rounded,
        color: const Color(0xFFF97316),
      ),
    ];

    // Check for custom categories beyond the standard ones, excluding any named 'Others' or 'Other'
    final extraTiles = <_CategoryTileData>[];
    _CategoryTileData? dbOthersTile;

    for (final cat in categories) {
      final norm = cat.name.trim().toLowerCase();
      if (norm == 'others' || norm == 'other') {
        dbOthersTile = _CategoryTileData(
          id: cat.id,
          name: cat.name,
          icon: cat.iconData,
          color: cat.color,
        );
        continue;
      }
      final matchesStandard = standardTiles.any(
        (t) => t.name.toLowerCase() == norm,
      );
      if (!matchesStandard) {
        extraTiles.add(
          _CategoryTileData(
            id: cat.id,
            name: cat.name,
            icon: cat.iconData,
            color: cat.color,
          ),
        );
      }
    }

    // Always place 'Others' tile at the VERY END of the list
    final allTiles = [
      ...standardTiles,
      ...extraTiles,
      dbOthersTile ??
          const _CategoryTileData(
            id: 'Others',
            name: 'Others',
            icon: Icons.more_horiz_rounded,
            color: Color(0xFF64748B),
          ),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: SizedBox(
        height: 76,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: allTiles.length,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final tile = allTiles[index];
            final isAllTile = tile.id == null;

            final isSelected = isAllTile
                ? invState.selectedCategoryId == null
                : (invState.selectedCategoryId != null &&
                    (invState.selectedCategoryId == tile.id ||
                        categories.any((c) =>
                            c.id == invState.selectedCategoryId &&
                            c.name.toLowerCase() == tile.name.toLowerCase())));

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (isAllTile) {
                    ref.read(inventoryControllerProvider.notifier).selectCategory(null);
                  } else {
                    final matchedCat = categories.cast<CategoryModel?>().firstWhere(
                          (c) => c?.name.toLowerCase() == tile.name.toLowerCase(),
                          orElse: () => null,
                        );
                    final catId = matchedCat?.id ?? tile.id;
                    ref.read(inventoryControllerProvider.notifier).selectCategory(catId);
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 62,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFF5F3FF) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF6366F1)
                          : const Color(0xFFE2E8F0),
                      width: isSelected ? 1.5 : 0.9,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? const Color(0xFF6366F1).withValues(alpha: 0.12)
                            : Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        tile.icon,
                        size: 24,
                        color: isSelected ? const Color(0xFF6366F1) : tile.color,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        tile.name,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? const Color(0xFF6366F1)
                              : const Color(0xFF334155),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ==========================================
  // SECTION 5: QUICK ADD STAPLES CARD
  // ==========================================
  Widget _buildQuickAddStaplesCard(BuildContext context, List<InventoryItemModel> existingItems) {
    final topStaples = [
      kHouseholdStaples.firstWhere((s) => s.name.toLowerCase() == 'milk', orElse: () => kHouseholdStaples[0]),
      kHouseholdStaples.firstWhere((s) => s.name.toLowerCase() == 'eggs', orElse: () => kHouseholdStaples[1]),
      kHouseholdStaples.firstWhere((s) => s.name.toLowerCase() == 'rice', orElse: () => kHouseholdStaples[2]),
      kHouseholdStaples.firstWhere((s) => s.name.toLowerCase().contains('oil'), orElse: () => kHouseholdStaples[3]),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Bolt Icon + Quick Add Staples + 650+ items + Chevron
            InkWell(
              onTap: () => _showAllEssentialsBottomSheet(context, existingItems),
              borderRadius: BorderRadius.circular(10),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFFD97706)),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Quick Add Staples',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF78350F),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '650+ items',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: Color(0xFFB45309),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Chips Row: Milk, Eggs, Rice, Oil, Explore ➔
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final staple in topStaples) ...[
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      child: InkWell(
                        onTap: () => _openStapleQuantityAndDetails(staple),
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(staple.emoji, style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 5),
                              Text(
                                staple.name,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Explore ➔ chip
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    child: InkWell(
                      onTap: () => _showAllEssentialsBottomSheet(context, existingItems),
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Explore',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFB45309),
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded, size: 13, color: Color(0xFFB45309)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // SECTION 6: NEEDS ATTENTION CARD
  // ==========================================
  Widget _buildNeedsAttentionSection(
    BuildContext context,
    List<InventoryItemModel> attentionItems,
    int lowStockCount,
    int expiringCount,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFECDD3)),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Red Bell Icon + Title + Subtitle + View all >
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE4E6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    size: 18,
                    color: Color(0xFFE11D48),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Needs Attention',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFBE123C),
                        ),
                      ),
                      Text(
                        '$lowStockCount low stock  •  $expiringCount expiring soon',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () {
                    try {
                      context.push('/attention');
                    } catch (_) {
                      ref.read(inventoryControllerProvider.notifier).setFilterType(InventoryFilterType.lowStock);
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View all',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF6366F1)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Mini Cards Grid / Horizontal Scroll
            SizedBox(
              height: 124,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: attentionItems.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final item = attentionItems[index];
                  final isLow = item.isLowStock || item.isOutOfStock;
                  final emoji = _getItemEmoji(item.name, item.categoryName);

                  return Container(
                    width: 180,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isLow ? const Color(0xFFFECDD3) : const Color(0xFFFDE68A),
                        width: 0.9,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Mini card Top: Emoji + Name + Badge
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isLow ? const Color(0xFFFFF1F2) : const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(emoji, style: const TextStyle(fontSize: 18)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatName(item.name),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1E293B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: isLow ? const Color(0xFFFFE4E6) : const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      isLow
                                          ? (item.isOutOfStock ? 'Out of Stock' : 'Low Stock')
                                          : (item.daysUntilExpiry != null
                                              ? 'Expires in ${item.daysUntilExpiry}d'
                                              : 'Expiring'),
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: isLow ? const Color(0xFFE11D48) : const Color(0xFFD97706),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Mini card Subtext: "X kg left  •  Min: Y kg"
                        Text(
                          '${item.quantity == item.quantity.roundToDouble() ? item.quantity.toInt() : item.quantity} ${item.unit} left  •  Min: ${item.minimumQuantity == item.minimumQuantity.roundToDouble() ? item.minimumQuantity.toInt() : item.minimumQuantity} ${item.unit}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // Mini card Button: [ 🛒 Add to Shopping List ]
                        Material(
                          color: isLow ? const Color(0xFFFFF1F2) : const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            onTap: () => _addItemToShoppingList(item),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              height: 28,
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isLow ? const Color(0xFFFDA4AF) : const Color(0xFFFDE68A),
                                  width: 0.8,
                                ),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.shopping_cart_outlined,
                                      size: 11,
                                      color: isLow ? const Color(0xFFE11D48) : const Color(0xFFD97706),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Add to Shopping List',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: isLow ? const Color(0xFFE11D48) : const Color(0xFFD97706),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // SECTION 7: "ALL ITEMS (N)" HEADER
  // ==========================================
  Widget _buildAllItemsHeader(BuildContext context, int count) {
    return Padding(
      padding: const EdgeInsets.only(left: 18, right: 18, top: 12, bottom: 4),
      child: Row(
        children: [
          const Icon(
            Icons.qr_code_scanner_rounded,
            size: 18,
            color: Color(0xFF6366F1),
          ),
          const SizedBox(width: 8),
          Text(
            'All Items ($count)',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: () => _showSortBottomSheet(context),
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swap_vert_rounded, size: 16, color: Color(0xFF6366F1)),
                  SizedBox(width: 4),
                  Text(
                    'Sort',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SECTION 8: ITEM CARD
  // ==========================================
  Widget _buildItemCard(BuildContext context, InventoryItemModel item) {
    final isLow = item.isLowStock;
    final isOut = item.isOutOfStock;
    final formattedName = _formatName(item.name);
    final emoji = _getItemEmoji(item.name, item.categoryName);
    final isSelected = _selectedItemIds.contains(item.id);

    final shoppingList = ref.watch(shoppingControllerProvider).list;
    final pendingShoppingItem = shoppingList?.items.cast<ShoppingItemModel?>().firstWhere(
          (s) =>
              !s!.isCompleted &&
              ((s.inventoryItemId != null && s.inventoryItemId == item.id) ||
                  s.itemName.toLowerCase().trim() == item.name.toLowerCase().trim()),
          orElse: () => null,
        );
    final isOnShoppingList = pendingShoppingItem != null;

    final locationLine = item.storageLocation != null && item.storageLocation!.isNotEmpty
        ? '${item.categoryName} • ${item.storageLocation}'
        : item.categoryName;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFF1F5F9),
          width: isSelected ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSelectionMode
              ? () {
                  setState(() {
                    if (_selectedItemIds.contains(item.id)) {
                      _selectedItemIds.remove(item.id);
                    } else {
                      _selectedItemIds.add(item.id);
                    }
                  });
                }
              : () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: item.id)),
                  );
                  ref.read(inventoryControllerProvider.notifier).loadData();
                },
          onLongPress: () {
            HapticFeedback.mediumImpact();
            setState(() {
              _isSelectionMode = true;
              _selectedItemIds.add(item.id);
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Selection Checkbox if in selection mode
                if (_isSelectionMode) ...[
                  Checkbox(
                    value: isSelected,
                    activeColor: const Color(0xFF6366F1),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedItemIds.add(item.id);
                        } else {
                          _selectedItemIds.remove(item.id);
                        }
                      });
                    },
                  ),
                  const SizedBox(width: 6),
                ],

                // Food Emoji Container (Large rounded square with soft pastel fill)
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
                const SizedBox(width: 12),

                // Middle Info: Name, Location, Status Badge
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formattedName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        locationLine,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),

                      // Status Badge (In Stock / Low Stock / Out of Stock)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isOut
                              ? const Color(0xFFFFE4E6)
                              : (isLow ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isOut
                              ? 'Out of Stock'
                              : (isLow ? 'Low Stock' : 'In Stock'),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isOut
                                ? const Color(0xFFE11D48)
                                : (isLow ? const Color(0xFFD97706) : const Color(0xFF16A34A)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Right Column: Stepper Capsule Pill on top, Add to List + Menu below
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Stepper Capsule Pill: [ - ] 1 L [ + ]
                    Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => _handleDecrement(item),
                            borderRadius: BorderRadius.circular(15),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.remove_rounded, size: 15, color: Color(0xFF334155)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '${item.quantity == item.quantity.roundToDouble() ? item.quantity.toInt() : item.quantity} ${item.unit}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => _handleIncrement(item),
                            borderRadius: BorderRadius.circular(15),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.add_rounded, size: 15, color: Color(0xFF334155)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Action Row: [ 🛒 Add to List ] + [ ⋮ ]
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () => _addItemToShoppingList(item),
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isOnShoppingList
                                      ? Icons.check_circle_rounded
                                      : Icons.shopping_cart_outlined,
                                  size: 13,
                                  color: isOnShoppingList
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFF6366F1),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isOnShoppingList ? 'On List' : 'Add to List',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: isOnShoppingList
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFF6366F1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Popup Menu ⋮
                        PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert_rounded,
                            size: 18,
                            color: Color(0xFF64748B),
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 140),
                          onSelected: (val) async {
                            if (val == 'details') {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: item.id)),
                              );
                            } else if (val == 'edit') {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => AddEditItemScreen(initialItem: item)),
                              );
                            } else if (val == 'stock_out') {
                              _openQuickStockOut(item);
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 16, color: Color(0xFF64748B)),
                                  SizedBox(width: 8),
                                  Text('Edit Item', style: TextStyle(fontSize: 13)),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'stock_out',
                              child: Row(
                                children: [
                                  Icon(Icons.remove_circle_outline_rounded, size: 16, color: Color(0xFF64748B)),
                                  SizedBox(width: 8),
                                  Text('Stock Out', style: TextStyle(fontSize: 13)),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'details',
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF64748B)),
                                  SizedBox(width: 8),
                                  Text('Details', style: TextStyle(fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddItemMenu(BuildContext context, List<InventoryItemModel> existingItems) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Add to Inventory',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E1B4B),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.bolt_rounded, color: Color(0xFFD97706)),
                  ),
                  title: const Text('Quick Staples', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('1-tap create Milk, Bread, Rice, Salt, and 650+ staples', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _showAllEssentialsBottomSheet(context, existingItems);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_note_rounded, color: Color(0xFF6366F1)),
                  ),
                  title: const Text('Add Manually', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Enter name, category, quantity, and expiry', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AddEditItemScreen()),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF3B82F6)),
                  ),
                  title: const Text('Scan Barcode', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Instant camera scan with product recognition', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    BarcodeScannerWidget.open(context);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.mic_rounded, color: Color(0xFF8B5CF6)),
                  ),
                  title: const Text('Voice Input', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Say "Add 2 packets of milk to inventory"', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    VoiceBottomSheet.show(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryTileData {
  final String? id;
  final String name;
  final IconData icon;
  final Color color;

  const _CategoryTileData({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

/// Comprehensive sheet modal displaying all 650+ categorized household essentials
class _AllEssentialsModal extends StatefulWidget {
  final List<InventoryItemModel> existingItems;
  final void Function(HouseholdStaple staple) onSelectStaple;
  final Future<void> Function(InventoryItemModel item) onAddToShoppingList;

  const _AllEssentialsModal({
    required this.existingItems,
    required this.onSelectStaple,
    required this.onAddToShoppingList,
  });

  @override
  State<_AllEssentialsModal> createState() => _AllEssentialsModalState();
}

class _AllEssentialsModalState extends State<_AllEssentialsModal> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var list = _selectedCategory == 'All'
        ? kHouseholdStaples
        : kHouseholdStaples.where((s) => s.category == _selectedCategory).toList();

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((s) {
        final matchName = s.name.toLowerCase().contains(q);
        final matchTamil = s.tamilName != null && s.tamilName!.toLowerCase().contains(q);
        final matchAlias = s.commonNames != null && s.commonNames!.any((a) => a.toLowerCase().contains(q));
        final matchSub = s.subCategory != null && s.subCategory!.toLowerCase().contains(q);
        return matchName || matchTamil || matchAlias || matchSub;
      }).toList();
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header: Yellow Bolt Container + Title + Subtitle + Close Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.bolt_rounded, size: 22, color: Color(0xFFD97706)),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Household Essentials',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E1B4B),
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 1),
                        Text(
                          'Select suggested items for quick details\n& quantity picking',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF1E1B4B), size: 22),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Search Bar: White background + Lavender/Purple outline + Barcode Scan Icon
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFFC7D2FE), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  style: const TextStyle(fontSize: 13.5, color: Color(0xFF1E1B4B)),
                  decoration: InputDecoration(
                    hintText: 'Search 650+ essentials in English or தமிழ்...',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.qr_code_scanner_rounded, size: 20, color: Color(0xFF1E1B4B)),
                      tooltip: 'Scan Barcode',
                      onPressed: () => BarcodeScannerWidget.open(context),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Category Chips: Horizontal pill list
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                itemCount: kHouseholdStapleCategories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = kHouseholdStapleCategories[index];
                  final isSelected = _selectedCategory == cat;
                  return Material(
                    color: isSelected ? const Color(0xFF6366F1) : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    child: InkWell(
                      onTap: () => setState(() => _selectedCategory = cat),
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
                            width: 1.0,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected ? Colors.white : const Color(0xFF1E1B4B),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),

            // Staples List
            Expanded(
              child: list.isEmpty
                  ? const Center(
                      child: Text(
                        'No matching essentials found.',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: list.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final staple = list[index];
                        final existing = widget.existingItems.cast<InventoryItemModel?>().firstWhere(
                              (i) => i?.name.trim().toLowerCase() == staple.name.trim().toLowerCase(),
                              orElse: () => null,
                            );
                        final inPantry = existing != null;

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: inPantry ? const Color(0xFFF0FDF4) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: inPantry ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
                              width: inPantry ? 1.2 : 0.9,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 1.5),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Food Emoji Graphic
                              Text(
                                staple.emoji,
                                style: const TextStyle(fontSize: 32),
                              ),
                              const SizedBox(width: 14),

                              // Middle: Name + Tamil Badge + Category / Pack Subtitle
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            staple.name,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF1E1B4B),
                                              letterSpacing: -0.2,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (staple.tamilName != null && staple.tamilName!.isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFEF3C7),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              staple.tamilName!,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF92400E),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${staple.subCategory ?? staple.category} • Pack: ${staple.defaultQty == staple.defaultQty.roundToDouble() ? staple.defaultQty.toInt() : staple.defaultQty} ${staple.defaultUnit}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 8),

                              // Right Actions:
                              // If in pantry: [ ✓ In Pantry ] + [ 🛒 + List ]
                              // If not in pantry: [ + Add ] orange pill button
                              if (inPantry) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF16A34A)),
                                      SizedBox(width: 4),
                                      Text(
                                        'In Pantry',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF16A34A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Material(
                                  color: const Color(0xFFF5F3FF),
                                  borderRadius: BorderRadius.circular(10),
                                  child: InkWell(
                                    onTap: () => widget.onAddToShoppingList(existing),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: const Color(0xFFC7D2FE), width: 1.0),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.shopping_cart_outlined, size: 13, color: Color(0xFF6366F1)),
                                          SizedBox(width: 4),
                                          Text(
                                            '+ List',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF6366F1),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ] else ...[
                                Material(
                                  color: const Color(0xFFEA580C),
                                  borderRadius: BorderRadius.circular(30),
                                  child: InkWell(
                                    onTap: () => widget.onSelectStaple(staple),
                                    borderRadius: BorderRadius.circular(30),
                                    child: Container(
                                      height: 38,
                                      padding: const EdgeInsets.symmetric(horizontal: 18),
                                      alignment: Alignment.center,
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.add_rounded, size: 16, color: Colors.white),
                                          SizedBox(width: 4),
                                          Text(
                                            'Add',
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
