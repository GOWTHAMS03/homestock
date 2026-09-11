import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/household_staples.dart';
import '../../core/sync/sync_providers.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/widgets/sync_diagnostics_dialog.dart';
import '../barcode/widgets/barcode_scanner_widget.dart';
import '../inventory/inventory_controller.dart';
import '../inventory/inventory_model.dart';
import '../purchase/add_purchase_screen.dart';
import '../purchase/purchases_screen.dart';
import '../smart_shopping/product_deal_search_screen.dart';
import '../smart_shopping/smart_shopping_screen.dart';
import '../voice/widgets/voice_input_button.dart';
import 'add_shopping_item_dialog.dart';
import 'shopping_controller.dart';
import 'shopping_model.dart';
import 'shopping_mode_screen.dart';

enum _ShoppingFilter { all, toBuy, completed }
enum _ShoppingSortOption { defaultOrder, nameAsc, quantityAsc, quantityDesc }

class ShoppingScreen extends ConsumerStatefulWidget {
  const ShoppingScreen({super.key});

  @override
  ConsumerState<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends ConsumerState<ShoppingScreen> {
  _ShoppingFilter _filter = _ShoppingFilter.all;
  _ShoppingSortOption _currentSort = _ShoppingSortOption.defaultOrder;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _selectedItemIds = {};
  bool _isSelectionMode = false;
  bool _isAddingQuickItem = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Parses quick inputs such as "Milk 2L", "Rice 5kg", "Eggs 12", "Tomatoes"
  ({String name, double quantity, String unit}) _parseQuickInput(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return (name: '', quantity: 1.0, unit: 'pcs');

    // Case 1: Trailing quantity (e.g. "Milk 2L", "Rice 5 kg", "Eggs 12")
    final regexTrailingQty = RegExp(
      r'^(.*?)\s+(\d+(?:\.\d+)?)\s*(kg|g|l|ml|pcs|packs?|boxes?|bags?|bottles?|cans?|loaf|loaves)?$',
      caseSensitive: false,
    );
    final matchTrailing = regexTrailingQty.firstMatch(text);
    if (matchTrailing != null) {
      final name = matchTrailing.group(1)?.trim() ?? text;
      final qty = double.tryParse(matchTrailing.group(2) ?? '1') ?? 1.0;
      final unitRaw = matchTrailing.group(3)?.toLowerCase();
      return (name: name.isNotEmpty ? name : text, quantity: qty, unit: _normalizeUnit(unitRaw));
    }

    // Case 2: Leading quantity (e.g. "2L Milk", "5kg Rice", "12 Eggs")
    final regexLeadingQty = RegExp(
      r'^(\d+(?:\.\d+)?)\s*(kg|g|l|ml|pcs|packs?|boxes?|bags?|bottles?|cans?|loaf|loaves)?\s+(.*)$',
      caseSensitive: false,
    );
    final matchLeading = regexLeadingQty.firstMatch(text);
    if (matchLeading != null) {
      final qty = double.tryParse(matchLeading.group(1) ?? '1') ?? 1.0;
      final unitRaw = matchLeading.group(2)?.toLowerCase();
      final name = matchLeading.group(3)?.trim() ?? text;
      return (name: name.isNotEmpty ? name : text, quantity: qty, unit: _normalizeUnit(unitRaw));
    }

    return (name: text, quantity: 1.0, unit: 'pcs');
  }

  String _normalizeUnit(String? raw) {
    if (raw == null || raw.isEmpty) return 'pcs';
    final lower = raw.toLowerCase();
    if (lower.startsWith('kg')) return 'kg';
    if (lower == 'g') return 'g';
    if (lower == 'l' || lower.startsWith('lit')) return 'L';
    if (lower == 'ml') return 'ml';
    if (lower.startsWith('pack') || lower.startsWith('pk')) return 'pk';
    if (lower.startsWith('box')) return 'box';
    if (lower.startsWith('bottle')) return 'bottle';
    if (lower.startsWith('can')) return 'can';
    if (lower.startsWith('loaf') || lower.startsWith('loaves')) return 'pk';
    return 'pcs';
  }

  Future<void> _submitQuickAdd([String? rawText]) async {
    final text = (rawText ?? _searchController.text).trim();
    if (text.isEmpty) return;

    final parsed = _parseQuickInput(text);
    if (parsed.name.isEmpty) return;

    setState(() => _isAddingQuickItem = true);
    _searchController.clear();
    setState(() => _searchQuery = '');

    final success = await ref.read(shoppingControllerProvider.notifier).addItem(
      itemName: parsed.name,
      quantity: parsed.quantity,
      unit: parsed.unit,
    );

    if (mounted) {
      setState(() => _isAddingQuickItem = false);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Added ${parsed.name} (${parsed.quantity == parsed.quantity.roundToDouble() ? parsed.quantity.toInt() : parsed.quantity} ${parsed.unit})',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF0F172A),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        final error = ref.read(shoppingControllerProvider).errorMessage ??
            'Could not add "${parsed.name}" to shopping list';
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

  void _handleToggleItem(ShoppingItemModel item) {
    final willBeCompleted = !item.isCompleted;
    ref.read(shoppingControllerProvider.notifier).toggleItem(item.id);

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      final qtyText = '${item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 1)} ${item.unit}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                willBeCompleted ? Icons.check_circle_rounded : Icons.undo_rounded,
                color: willBeCompleted ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  willBeCompleted
                      ? 'Restocked ${item.itemName} (+$qtyText) to pantry & updated low-stock!'
                      : 'Unmarked ${item.itemName} & reverted stock',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 2400),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _restockAllLowStock(List<InventoryItemModel> lowStockSuggestions) async {
    if (lowStockSuggestions.isEmpty) return;
    int count = 0;
    for (final item in lowStockSuggestions) {
      final success = await ref.read(shoppingControllerProvider.notifier).addItem(
        inventoryItemId: item.id,
        itemName: item.name,
        categoryId: item.categoryId,
        categoryName: item.categoryName,
        categoryIcon: item.categoryIcon,
        categoryColor: item.categoryColor,
        quantity: 1.0,
        unit: item.unit,
      );
      if (success) count++;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (count > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Restocked all $count low-stock items to your shopping list! ⚡',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFD97706),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        final error = ref.read(shoppingControllerProvider).errorMessage ??
            'Failed to restock low-stock items';
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

  List<ShoppingItemModel> _applySorting(List<ShoppingItemModel> items) {
    final list = List<ShoppingItemModel>.from(items);
    switch (_currentSort) {
      case _ShoppingSortOption.defaultOrder:
        return list;
      case _ShoppingSortOption.nameAsc:
        list.sort((a, b) => a.itemName.toLowerCase().compareTo(b.itemName.toLowerCase()));
        return list;
      case _ShoppingSortOption.quantityAsc:
        list.sort((a, b) => a.quantity.compareTo(b.quantity));
        return list;
      case _ShoppingSortOption.quantityDesc:
        list.sort((a, b) => b.quantity.compareTo(a.quantity));
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
                    'Sort Shopping Items',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E1B4B),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildSortTile('Default Order', _ShoppingSortOption.defaultOrder, Icons.sort_rounded),
              _buildSortTile('Name (A to Z)', _ShoppingSortOption.nameAsc, Icons.sort_by_alpha_rounded),
              _buildSortTile('Quantity (Low to High)', _ShoppingSortOption.quantityAsc, Icons.trending_up_rounded),
              _buildSortTile('Quantity (High to Low)', _ShoppingSortOption.quantityDesc, Icons.trending_down_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortTile(String title, _ShoppingSortOption option, IconData icon) {
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
    final shoppingState = ref.watch(shoppingControllerProvider);
    final invState = ref.watch(inventoryControllerProvider);
    final list = shoppingState.list;

    // Filter items based on active filter and search query
    List<ShoppingItemModel> filteredItems = [];
    if (list != null) {
      filteredItems = list.items.where((item) {
        if (_filter == _ShoppingFilter.toBuy && item.isCompleted) return false;
        if (_filter == _ShoppingFilter.completed && !item.isCompleted) return false;
        if (_searchQuery.isNotEmpty &&
            !item.itemName.toLowerCase().contains(_searchQuery.toLowerCase())) {
          return false;
        }
        return true;
      }).toList();
    }

    final displayedItems = _applySorting(filteredItems);

    // Pantry restock suggestions: items low or out of stock not yet in shopping list
    final lowStockSuggestions = invState.items.where((pantryItem) {
      if (!pantryItem.isLowStock && !pantryItem.isOutOfStock) return false;
      if (list != null) {
        final alreadyInList = list.items.any((s) =>
            s.inventoryItemId == pantryItem.id ||
            s.itemName.toLowerCase() == pantryItem.name.toLowerCase());
        if (alreadyInList) return false;
      }
      return true;
    }).toList();

    final totalCount = list?.items.length ?? 0;
    final completedCount = list?.completedCount ?? 0;
    final pendingCount = list?.pendingCount ?? 0;
    final completionRatio = totalCount > 0 ? (completedCount / totalCount) : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        bottom: false,
        child: (shoppingState.isLoading && list == null)
            ? ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: 6,
                separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) => const SkeletonItemCard(),
              )
            : RefreshIndicator(
                onRefresh: () => ref.read(shoppingControllerProvider.notifier).loadShoppingList(),
                color: const Color(0xFF6366F1),
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // 1. Top Header: Title + Subtitle + Cloud Sync + More menu
                    _buildTopHeader(context, pendingCount, completedCount, totalCount),

                    // 2. Sync Status Banner: [ ☁✓ ] All changes synced | Tap to sync
                    _buildSyncStatusBanner(context),

                    // 3. Search Bar: [ 🔍 Search or add items...  🔲 🎤 ]
                    _buildExistingSearchBar(context),

                    const SizedBox(height: 8),

                    // 4. Feature Actions Row: [ Price Deals > ] [ Shop Mode > ] [ Restocked > ]
                    _buildFeatureActionsRow(context),

                    const SizedBox(height: 12),

                    // 5. Pantry Auto-Restock Section (Only when low stock items exist)
                    if (lowStockSuggestions.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildPantryRestockSection(context, lowStockSuggestions),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // 6. Shopping Progress Card: [ 🛒 2 to buy  0% Done ] [ 🧾 Record Bill ] >
                    _buildProgressCard(
                      context,
                      totalCount: totalCount,
                      completedCount: completedCount,
                      pendingCount: pendingCount,
                      completionRatio: completionRatio,
                    ),

                    const SizedBox(height: 10),

                    // 7. Best Prices Promotion Banner: [ 🏷 Best prices for your list > ]
                    _buildBestPricesBanner(context, pendingCount),

                    const SizedBox(height: 14),

                    // 8. Filter Tabs & Sort Row: [ All (2) ] [ To Buy (2) ] [ Done (0) ]   [ 🎛 Sort ]
                    _buildFilterTabsAndSortRow(
                      context,
                      totalCount: totalCount,
                      pendingCount: pendingCount,
                      completedCount: completedCount,
                    ),

                    const SizedBox(height: 12),

                    // 9. Items list OR Clean Empty Guide
                    if (totalCount > 0) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            if (displayedItems.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(28),
                                alignment: Alignment.center,
                                child: Column(
                                  children: [
                                    const Icon(Icons.search_off_rounded, size: 36, color: Color(0xFF94A3B8)),
                                    const SizedBox(height: 8),
                                    Text(
                                      _searchQuery.isNotEmpty
                                          ? 'No items matching "$_searchQuery"'
                                          : 'No items in this filter tab',
                                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              )
                            else
                              ...displayedItems.map((item) => _buildShoppingItemTile(context, item)),
                          ],
                        ),
                      ),
                    ] else ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildEmptyShoppingGuide(context),
                      ),
                    ],

                    // Bottom spacing for floating navigation bar
                    const SizedBox(height: 120),
                  ],
                ),
              ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 75),
        child: FloatingActionButton(
          heroTag: 'shopping_add_btn',
          onPressed: () => AddShoppingItemDialog.show(context),
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          elevation: 4,
          shape: const CircleBorder(),
          tooltip: 'Add Shopping Item',
          child: const Icon(Icons.add_rounded, size: 28),
        ),
      ),
      bottomNavigationBar: (_isSelectionMode || _selectedItemIds.isNotEmpty)
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
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
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF1E1B4B)),
                          ),
                          const Text(
                            'Compare Blinkit, Zepto, Instamart',
                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    if (_selectedItemIds.isEmpty)
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _selectedItemIds.addAll(
                              filteredItems.where((i) => !i.isCompleted).map((i) => i.id),
                            );
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
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SmartShoppingScreen(
                                itemIds: _selectedItemIds.toList(),
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.bolt_rounded, size: 18),
                        label: const Text('Compare Deals ⚡', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                      ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      tooltip: 'Exit Selection Mode',
                      onPressed: () {
                        setState(() {
                          _isSelectionMode = false;
                          _selectedItemIds.clear();
                        });
                      },
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  // ==========================================
  // SECTION 1: TOP APP BAR / HEADER
  // ==========================================
  Widget _buildTopHeader(BuildContext context, int pendingCount, int completedCount, int totalCount) {
    return Padding(
      padding: const EdgeInsets.only(left: 18, right: 16, top: 12, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Title + Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Shopping List',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E1B4B),
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  totalCount == 0
                      ? '0 items • Offline ready'
                      : '$pendingCount to buy • $completedCount completed',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Cloud sync circular button
          InkWell(
            onTap: () {
              try {
                ref.read(syncEngineProvider).syncAll();
              } catch (_) {}
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Syncing changes with cloud ☁️'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            borderRadius: BorderRadius.circular(50),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.cloud_done_outlined,
                color: Color(0xFF10B981),
                size: 20,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // More options circular button
          PopupMenuButton<String>(
            icon: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.more_vert_rounded,
                color: Color(0xFF1E1B4B),
                size: 20,
              ),
            ),
            padding: EdgeInsets.zero,
            onSelected: (val) {
              if (val == 'clear_done') {
                ref.read(shoppingControllerProvider.notifier).clearCompleted();
              } else if (val == 'record_bill') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddPurchaseScreen()),
                );
              } else if (val == 'diagnostics') {
                SyncDiagnosticsDialog.show(context);
              }
            },
            itemBuilder: (ctx) => [
              if (completedCount > 0)
                const PopupMenuItem(
                  value: 'clear_done',
                  child: Row(
                    children: [
                      Icon(Icons.cleaning_services_rounded, size: 16, color: Color(0xFF64748B)),
                      SizedBox(width: 8),
                      Text('Clear Completed Items', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'record_bill',
                child: Row(
                  children: [
                    Icon(Icons.receipt_long_rounded, size: 16, color: Color(0xFF64748B)),
                    SizedBox(width: 8),
                    Text('Record Bill', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'diagnostics',
                child: Row(
                  children: [
                    Icon(Icons.cloud_sync_rounded, size: 16, color: Color(0xFF64748B)),
                    SizedBox(width: 8),
                    Text('Sync Diagnostics', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SECTION 2: SYNC STATUS BANNER
  // ==========================================
  Widget _buildSyncStatusBanner(BuildContext context) {
    final syncStateAsync = ref.watch(syncStateProvider);
    final isOnline = syncStateAsync.whenOrNull(data: (s) => s.isOnline) ?? true;
    final isSyncing = syncStateAsync.whenOrNull(data: (s) => s.isSyncing) ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isOnline ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isOnline ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            // Cloud check icon in circle
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isOnline ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                isSyncing
                    ? Icons.sync_rounded
                    : (isOnline ? Icons.cloud_done_rounded : Icons.cloud_off_rounded),
                size: 20,
                color: isOnline ? const Color(0xFF059669) : const Color(0xFFD97706),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isSyncing
                        ? 'Syncing changes...'
                        : (isOnline ? 'All changes synced' : 'Working offline'),
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: isOnline ? const Color(0xFF065F46) : const Color(0xFF92400E),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    isOnline ? 'Updated just now' : 'Local changes saved on device',
                    style: TextStyle(
                      fontSize: 11,
                      color: isOnline ? const Color(0xFF047857) : const Color(0xFFB45309),
                    ),
                  ),
                ],
              ),
            ),
            // Vertical divider
            Container(
              width: 1,
              height: 24,
              color: isOnline ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
            ),
            const SizedBox(width: 10),
            InkWell(
              onTap: () async {
                HapticFeedback.lightImpact();
                try {
                  ref.read(syncEngineProvider).syncAll();
                } catch (_) {}
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sync completed successfully ☁️'),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text(
                  'Tap to sync',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isOnline ? const Color(0xFF047857) : const Color(0xFF92400E),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // SECTION 3: SEARCH BAR (WITH SCAN & VOICE)
  // ==========================================
  Widget _buildExistingSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) => setState(() => _searchQuery = val.trim()),
          onSubmitted: (val) => _submitQuickAdd(val),
          textInputAction: TextInputAction.done,
          style: const TextStyle(fontSize: 13.5, color: Color(0xFF1E1B4B)),
          decoration: InputDecoration(
            hintText: 'Search or add items...',
            hintStyle: const TextStyle(fontSize: 13.5, color: Color(0xFF94A3B8)),
            prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_searchController.text.isNotEmpty) ...[
                  IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    tooltip: 'Clear search',
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  ),
                  InkWell(
                    onTap: () => _submitQuickAdd(_searchController.text),
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isAddingQuickItem)
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          else ...[
                            const Icon(Icons.add_rounded, size: 14, color: Colors.white),
                            const SizedBox(width: 2),
                            const Text('Add', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 20, color: Color(0xFF6366F1)),
                    tooltip: 'Scan Barcode',
                    onPressed: () => BarcodeScannerWidget.open(context),
                  ),
                  const VoiceInputButton(size: 20, color: Color(0xFF6366F1), tooltip: 'Voice shopping command'),
                  const SizedBox(width: 4),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SECTION 4: 3 FEATURE ACTION CARDS
  // ==========================================
  Widget _buildFeatureActionsRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // 1. Price Deals
          Expanded(
            child: _buildActionTile(
              icon: Icons.bolt_rounded,
              iconColor: const Color(0xFFD97706),
              iconBg: const Color(0xFFFEF3C7),
              title: 'Price Deals',
              subtitle: 'Compare stores',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SmartShoppingScreen()),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // 2. Shop Mode
          Expanded(
            child: _buildActionTile(
              icon: Icons.shopping_cart_outlined,
              iconColor: const Color(0xFF10B981),
              iconBg: const Color(0xFFDCFCE7),
              title: 'Shop Mode',
              subtitle: 'Store checklist',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ShoppingModeScreen()),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // 3. Restocked
          Expanded(
            child: _buildActionTile(
              icon: Icons.receipt_long_rounded,
              iconColor: const Color(0xFF8B5CF6),
              iconBg: const Color(0xFFF5F3FF),
              title: 'Restocked',
              subtitle: 'Bills & receipts',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PurchasesScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E1B4B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 14,
                      color: Color(0xFF94A3B8),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SECTION 5: PANTRY RESTOCK SECTION
  // ==========================================
  Widget _buildPantryRestockSection(BuildContext context, List<InventoryItemModel> lowStockSuggestions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.warning_amber_rounded, size: 15, color: Color(0xFFD97706)),
            ),
            const SizedBox(width: 6),
            const Text(
              'Pantry Running Low',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1E1B4B)),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${lowStockSuggestions.length} low',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFB45309)),
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: () => _restockAllLowStock(lowStockSuggestions),
              borderRadius: BorderRadius.circular(50),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt_rounded, size: 13, color: Colors.white),
                    const SizedBox(width: 2),
                    Text(
                      'Restock All (${lowStockSuggestions.length})',
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 82,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: lowStockSuggestions.length,
            separatorBuilder: (_, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final pantryItem = lowStockSuggestions[index];
              return _buildRestockSuggestionCard(pantryItem);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRestockSuggestionCard(InventoryItemModel pantryItem) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: pantryItem.categoryColorParsed.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(pantryItem.categoryIconData, size: 18, color: pantryItem.categoryColorParsed),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  pantryItem.name,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF1E1B4B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  pantryItem.isOutOfStock ? 'Out of stock' : 'Low stock (${pantryItem.quantity} ${pantryItem.unit})',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: pantryItem.isOutOfStock ? const Color(0xFFE11D48) : const Color(0xFFD97706),
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () async {
              await ref.read(shoppingControllerProvider.notifier).addItem(
                    inventoryItemId: pantryItem.id,
                    itemName: pantryItem.name,
                    categoryId: pantryItem.categoryId,
                    categoryName: pantryItem.categoryName,
                    categoryIcon: pantryItem.categoryIcon,
                    categoryColor: pantryItem.categoryColor,
                    quantity: 1.0,
                    unit: pantryItem.unit,
                  );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added ${pantryItem.name} to shopping list'),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(50),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFFEEF2FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded, size: 16, color: Color(0xFF6366F1)),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SECTION 6: SHOPPING PROGRESS CARD
  // ==========================================
  Widget _buildProgressCard(
    BuildContext context, {
    required int totalCount,
    required int completedCount,
    required int pendingCount,
    required double completionRatio,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF8FF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEDE9FE), width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Purple cart icon in circle
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEDE9FE),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.shopping_cart_rounded,
                    size: 20,
                    color: Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '$pendingCount to buy',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15.5,
                              color: Color(0xFF1E1B4B),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE9FE),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${(completionRatio * 100).toInt()}% Done',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$completedCount of $totalCount items checked off',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Outlined button: [ 🧾 Record Bill ] >
                InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddPurchaseScreen()),
                  ),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF818CF8), width: 1.2),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long_rounded, size: 14, color: Color(0xFF6366F1)),
                        SizedBox(width: 4),
                        Text(
                          'Record Bill',
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
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: Color(0xFF6366F1),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: completionRatio,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                minHeight: 5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // SECTION 7: BEST PRICES PROMOTION BANNER
  // ==========================================
  Widget _buildBestPricesBanner(BuildContext context, int pendingCount) {
    final savings = pendingCount > 0 ? (pendingCount * 60) : 120;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProductDealSearchScreen()),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFDE68A), width: 1.0),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: Color(0xFFF59E0B),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.local_offer_rounded, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Best prices for your list',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF78350F),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Save up to ₹$savings • $pendingCount items',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFFB45309),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Color(0xFFB45309),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SECTION 8: FILTER TABS & SORT ROW
  // ==========================================
  Widget _buildFilterTabsAndSortRow(
    BuildContext context, {
    required int totalCount,
    required int pendingCount,
    required int completedCount,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildFilterTab('All ($totalCount)', _ShoppingFilter.all),
          const SizedBox(width: 8),
          _buildFilterTab('To Buy ($pendingCount)', _ShoppingFilter.toBuy),
          const SizedBox(width: 8),
          _buildFilterTab('Done ($completedCount)', _ShoppingFilter.completed),
          const Spacer(),
          // Sort Button
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            child: InkWell(
              onTap: () => _showSortBottomSheet(context),
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.tune_rounded, size: 15, color: Color(0xFF1E1B4B)),
                    SizedBox(width: 5),
                    Text(
                      'Sort',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E1B4B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, _ShoppingFilter filter) {
    final isSelected = _filter == filter;
    return Material(
      color: isSelected ? const Color(0xFF6366F1) : Colors.white,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: () => setState(() => _filter = filter),
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
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SECTION 9: SHOPPING ITEM TILE (CARD)
  // ==========================================
  Widget _buildShoppingItemTile(BuildContext context, ShoppingItemModel item) {
    final staple = findStapleForName(item.itemName);
    final emoji = staple?.emoji ?? '🛒';
    final tamilName = staple?.tamilName;

    return Dismissible(
      key: Key('shopping_item_${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Delete', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w700, fontSize: 13)),
            SizedBox(width: 8),
            Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 20),
          ],
        ),
      ),
      onDismissed: (_) {
        ref.read(shoppingControllerProvider.notifier).deleteItem(item.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.itemName} removed from list'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Undo',
              textColor: Colors.white,
              onPressed: () {
                ref.read(shoppingControllerProvider.notifier).addItem(
                      inventoryItemId: item.inventoryItemId,
                      itemName: item.itemName,
                      categoryName: item.categoryName,
                      quantity: item.quantity,
                      unit: item.unit,
                    );
              },
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 1.5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Checkbox + Food Emoji + Title & Subtitle + Stepper + Delete
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Circular Check Indicator
                InkWell(
                  onTap: () => _handleToggleItem(item),
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: item.isCompleted ? const Color(0xFF10B981) : Colors.white,
                      border: Border.all(
                        color: item.isCompleted ? const Color(0xFF10B981) : const Color(0xFFC7D2FE),
                        width: 1.8,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: item.isCompleted
                        ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
                        : null,
                  ),
                ),

                const SizedBox(width: 12),

                // Food Graphic / Emoji Container
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF9C3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 26),
                  ),
                ),

                const SizedBox(width: 12),

                // Title and Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.itemName,
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                                color: item.isCompleted ? const Color(0xFF94A3B8) : const Color(0xFF1E1B4B),
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (tamilName != null && tamilName.isNotEmpty) ...[
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                '($tamilName)',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                                  color: item.isCompleted ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Added by ${item.addedByName.isNotEmpty ? item.addedByName : "You"} • ${item.quantity == item.quantity.roundToDouble() ? item.quantity.toInt() : item.quantity} ${item.unit}',
                        style: TextStyle(
                          fontSize: 12,
                          color: item.isCompleted ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // In-card Quantity Stepper
                if (!item.isCompleted) ...[
                  Container(
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () {
                            final next = (item.quantity - 1.0).clamp(0.0, 999.0);
                            ref.read(shoppingControllerProvider.notifier).updateQuantity(item.id, next);
                          },
                          borderRadius: BorderRadius.circular(15),
                          child: const Padding(
                            padding: EdgeInsets.all(3),
                            child: Icon(Icons.remove_rounded, size: 14, color: Color(0xFF64748B)),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Text(
                            '${item.quantity == item.quantity.roundToDouble() ? item.quantity.toInt() : item.quantity}',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF1E1B4B)),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            ref.read(shoppingControllerProvider.notifier).updateQuantity(item.id, item.quantity + 1.0);
                          },
                          borderRadius: BorderRadius.circular(15),
                          child: const Padding(
                            padding: EdgeInsets.all(3),
                            child: Icon(Icons.add_rounded, size: 14, color: Color(0xFF6366F1)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                ],

                // Delete button ✕
                InkWell(
                  onTap: () => ref.read(shoppingControllerProvider.notifier).deleteItem(item.id),
                  borderRadius: BorderRadius.circular(50),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
                  ),
                ),
              ],
            ),

            // Row 2: Deals & Scan Actions (aligned to right)
            if (!item.isCompleted) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Deals button
                  Material(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProductDealSearchScreen(
                            initialQuery: item.itemName,
                            initialItemId: item.id,
                            initialBarcode: item.barcode,
                            initialUnit: item.unit,
                          ),
                        ),
                      ),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bolt_rounded, size: 13, color: Color(0xFFD97706)),
                            SizedBox(width: 4),
                            Text(
                              'Deals',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF92400E)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Scan button
                  Material(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      onTap: () {
                        BarcodeScannerWidget.open(context, targetShoppingItem: item);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFDDD6FE)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.qr_code_scanner_rounded, size: 13, color: Color(0xFF6366F1)),
                            SizedBox(width: 4),
                            Text(
                              'Scan',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF6366F1)),
                            ),
                          ],
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

  // ==========================================
  // SECTION 10: EMPTY SHOPPING GUIDE
  // ==========================================
  Widget _buildEmptyShoppingGuide(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0xFFEEF2FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shopping_bag_outlined, size: 38, color: Color(0xFF6366F1)),
          ),
          const SizedBox(height: 12),
          const Text(
            'Your Shopping List is Empty',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E1B4B),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Search or type above to add items, tap essentials, or compare live prices across stores.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                height: 1.35,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),

          // Offline indicator badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.offline_pin_rounded, size: 14, color: Color(0xFF10B981)),
                SizedBox(width: 4),
                Text(
                  '100% Offline Ready • Changes saved locally',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF10B981)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          TextButton.icon(
            onPressed: () => AddShoppingItemDialog.show(context),
            icon: const Icon(Icons.edit_note_rounded, size: 18, color: Color(0xFF6366F1)),
            label: const Text(
              '+ Add with Category & Notes',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6366F1)),
            ),
          ),
        ],
      ),
    );
  }
}
