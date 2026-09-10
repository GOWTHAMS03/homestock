import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/household_staples.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/homestock/homestock_app_bar.dart';
import '../../core/widgets/homestock/homestock_card.dart';
import '../../core/widgets/quantity_stepper.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/widgets/stock_status_badge.dart';
import '../voice/widgets/voice_input_button.dart';
import '../voice/widgets/voice_bottom_sheet.dart';
import '../barcode/widgets/barcode_scanner_widget.dart';
import '../shopping/shopping_controller.dart';
import '../shopping/shopping_model.dart';
import 'add_edit_item_screen.dart';
import 'category_model.dart';
import 'inventory_controller.dart';
import 'inventory_model.dart';
import 'item_detail_screen.dart';
import 'stock_update_dialog.dart';
import 'staple_quantity_details_sheet.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _searchController = TextEditingController();
  final Set<String> _justCreatedStaples = {};
  bool _isEssentialsExpanded = true;
  bool _isSelectionMode = false;
  final Set<String> _selectedItemIds = {};

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

  /// Opens product-tailored quantity selection & details sheet for suggested household staple
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

  /// Add a created inventory item to the shopping list
  Future<void> _addItemToShoppingList(InventoryItemModel item, [double? quantity]) async {
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

  /// Batch add multiple selected created items to shopping list
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

  /// Open comprehensive sheet modal with all 650+ categorized essentials
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

  /// Quick-Add Essentials section in Inventory Screen - sleek, non-intrusive suggestion card
  Widget _buildQuickEssentialsSection(
    BuildContext context,
    List<InventoryItemModel> existingItems,
    InventoryState invState,
  ) {
    // Hide when searching or when specifically filtering for low stock / expiring items
    if (_searchController.text.isNotEmpty || invState.filterType != InventoryFilterType.all) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(left: AppSpacing.lg, right: AppSpacing.lg, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline, width: 0.8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.bolt_rounded, size: 14, color: AppColors.primary),
              ),
              const SizedBox(width: 6),
              const Text(
                'Quick Add Staples',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '650+ Items',
                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => _showAllEssentialsBottomSheet(context, existingItems),
                borderRadius: BorderRadius.circular(50),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Explore All',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                      Icon(Icons.chevron_right_rounded, size: 15, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: () => setState(() => _isEssentialsExpanded = !_isEssentialsExpanded),
                borderRadius: BorderRadius.circular(50),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    _isEssentialsExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: const Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),

          if (_isEssentialsExpanded) ...[
            const SizedBox(height: 8),
            // Staples Horizontal Carousel
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: kHouseholdStaples.length,
                separatorBuilder: (context, index) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final staple = kHouseholdStaples[index];
                  final inPantry = existingItems.any(
                    (i) => i.name.trim().toLowerCase() == staple.name.trim().toLowerCase(),
                  );
                  final isJustCreated = _justCreatedStaples.contains(staple.name);
                  final isHighlighted = inPantry || isJustCreated;

                  return Material(
                    color: isHighlighted ? const Color(0xFFECFDF5) : Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    child: InkWell(
                      onTap: () => _openStapleQuantityAndDetails(staple),
                      borderRadius: BorderRadius.circular(50),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                            color: isHighlighted ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                            width: isHighlighted ? 1.3 : 1.0,
                          ),
                          boxShadow: [
                            if (!isHighlighted)
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
                            Text(staple.emoji, style: const TextStyle(fontSize: 13.5)),
                            const SizedBox(width: 5),
                            Text(
                              staple.tamilName != null && staple.tamilName!.isNotEmpty
                                  ? '${staple.name} • ${staple.tamilName} (${staple.defaultQty == staple.defaultQty.roundToDouble() ? staple.defaultQty.toInt() : staple.defaultQty} ${staple.defaultUnit})'
                                  : '${staple.name} (${staple.defaultQty == staple.defaultQty.roundToDouble() ? staple.defaultQty.toInt() : staple.defaultQty} ${staple.defaultUnit})',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isHighlighted ? const Color(0xFF047857) : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Icon(
                              isHighlighted ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                              size: 15,
                              color: isHighlighted ? const Color(0xFF10B981) : const Color(0xFFD97706),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final invState = ref.watch(inventoryControllerProvider);
    final displayedItems = invState.filteredItems;

    // Deduplicate categories by normalized name to guarantee zero repeat content
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

    // Dynamic metrics for urgency filters
    final lowStockCount = invState.items
        .where((i) => i.stockStatus == 'LOW_STOCK' || i.stockStatus == 'OUT_OF_STOCK')
        .length;
    final expiringCount = invState.items
        .where((i) => i.expiryStatus == 'EXPIRING_SOON' || i.expiryStatus == 'EXPIRED')
        .length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: HomeStockAppBar(
        title: 'Household Inventory',
        subtitle: invState.items.isEmpty
            ? 'Home pantry & supplies'
            : '${invState.items.length} ${invState.items.length == 1 ? "item" : "items"} tracked'
                '${lowStockCount > 0 ? " • $lowStockCount low stock" : (expiringCount > 0 ? " • $expiringCount expiring" : " • All stocked")}',
        showBackButton: false,
        actions: [
          if (invState.items.isNotEmpty)
            InkWell(
              onTap: () {
                setState(() {
                  _isSelectionMode = !_isSelectionMode;
                  if (!_isSelectionMode) _selectedItemIds.clear();
                });
              },
              borderRadius: BorderRadius.circular(50),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _isSelectionMode ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: _isSelectionMode ? AppColors.primary : AppColors.outline.withValues(alpha: 0.8),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isSelectionMode ? Icons.close_rounded : Icons.playlist_add_check_rounded,
                      size: 14,
                      color: _isSelectionMode ? Colors.white : AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isSelectionMode ? 'Cancel' : 'Select to Buy',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: _isSelectionMode ? Colors.white : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search Bar: integrated camera barcode scan + voice search in single clean container
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: AppColors.outline.withValues(alpha: 0.85)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.035),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => ref.read(inventoryControllerProvider.notifier).setSearchQuery(val),
                decoration: InputDecoration(
                  hintText: 'Search pantry, fridge, spices...',
                  hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.primary),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchController.clear();
                            ref.read(inventoryControllerProvider.notifier).setSearchQuery('');
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.qr_code_scanner_rounded, size: 20, color: AppColors.primary),
                        tooltip: 'Scan Barcode',
                        onPressed: () => BarcodeScannerWidget.open(context),
                      ),
                      const VoiceInputButton(size: 20, tooltip: 'Voice search'),
                      const SizedBox(width: 4),
                    ],
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // Tier 1: Modern Segmented Status Bar (All | Low Stock | Expiring)
          _buildStatusSegmentedControl(context, invState, lowStockCount, expiringCount),

          const SizedBox(height: 8),

          // Tier 2: Category Pills (Clean, Deduplicated Pantry Categories)
          if (uniqueCategories.isNotEmpty) ...[
            SizedBox(
              height: 34,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                scrollDirection: Axis.horizontal,
                itemCount: uniqueCategories.length + 1,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    final isAll = invState.selectedCategoryId == null;
                    return InkWell(
                      onTap: () => ref.read(inventoryControllerProvider.notifier).selectCategory(null),
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isAll ? Theme.of(context).colorScheme.primaryContainer : Colors.white,
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                            color: isAll ? Theme.of(context).colorScheme.primary : AppColors.outline.withValues(alpha: 0.8),
                            width: isAll ? 1.2 : 0.8,
                          ),
                          boxShadow: [
                            if (!isAll)
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
                            Icon(
                              Icons.grid_view_rounded,
                              size: 13,
                              color: isAll ? Theme.of(context).colorScheme.primary : AppColors.textMuted,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'All Categories',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: isAll ? FontWeight.w700 : FontWeight.w500,
                                color: isAll ? Theme.of(context).colorScheme.primary : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final cat = uniqueCategories[index - 1];
                  final isSelected = invState.selectedCategoryId == cat.id;

                  return InkWell(
                    onTap: () => ref.read(inventoryControllerProvider.notifier).selectCategory(cat.id),
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Colors.white,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: isSelected ? Theme.of(context).colorScheme.primary : AppColors.outline.withValues(alpha: 0.8),
                          width: isSelected ? 1.2 : 0.8,
                        ),
                        boxShadow: [
                          if (!isSelected)
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
                          Icon(
                            cat.iconData,
                            size: 13,
                            color: isSelected ? Theme.of(context).colorScheme.primary : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            cat.name,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Theme.of(context).colorScheme.primary : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
          ],

          // Tier 3: Quick Add Staples (Collapsible Suggestion Strip)
          _buildQuickEssentialsSection(context, invState.items, invState),
          const SizedBox(height: 4),

          // Items List with Layout-Stable Skeletons
          Expanded(
            child: (invState.isLoading && invState.items.isEmpty)
                ? ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: 5,
                    separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) => const SkeletonItemCard(),
                  )
                : displayedItems.isEmpty
                    ? EmptyStateView(
                        icon: Icons.inventory_2_outlined,
                        title: 'No items found',
                        message: invState.searchQuery.isNotEmpty
                            ? 'No products matched "${invState.searchQuery}".'
                            : (invState.filterType != InventoryFilterType.all
                                ? 'No items match the active status filter.'
                                : 'Your household pantry is empty. Add your first item!'),
                        actionLabel: invState.searchQuery.isEmpty && invState.filterType == InventoryFilterType.all
                            ? 'Add First Item'
                            : 'Reset Filters',
                        onAction: () {
                          if (invState.searchQuery.isNotEmpty || invState.filterType != InventoryFilterType.all) {
                            _searchController.clear();
                            ref.read(inventoryControllerProvider.notifier).setSearchQuery('');
                            ref.read(inventoryControllerProvider.notifier).setFilterType(InventoryFilterType.all);
                            ref.read(inventoryControllerProvider.notifier).selectCategory(null);
                          } else {
                            _showAddItemMenu(context, invState.items);
                          }
                        },
                      )
                    : RefreshIndicator(
                        onRefresh: () => ref.read(inventoryControllerProvider.notifier).loadData(),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                          itemCount: displayedItems.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = displayedItems[index];
                            return _buildInventoryCard(context, item);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemMenu(context, invState.items),
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text('Add Item', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
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
                                : '${_selectedItemIds.length} created item(s) selected',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppColors.textPrimary),
                          ),
                          const Text(
                            'Add to your shopping list with 1 tap',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
                          backgroundColor: AppColors.primary,
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
                    color: AppColors.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Add to Inventory',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
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
                    child: const Icon(Icons.flash_on_rounded, color: Color(0xFFD97706)),
                  ),
                  title: const Text('Quick Essentials', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('1-tap create Milk, Bread, Rice, Salt, and 650+ staples', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _showAllEssentialsBottomSheet(context, existingItems);
                  },
                ),
                const HomeStockDottedDivider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_note_rounded, color: AppColors.primary),
                  ),
                  title: const Text('Add Manually', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Enter name, category, quantity, and expiry', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AddEditItemScreen()),
                    );
                  },
                ),
                const HomeStockDottedDivider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.secondary),
                  ),
                  title: const Text('Scan Barcode', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Instant camera scan with product recognition', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    BarcodeScannerWidget.open(context);
                  },
                ),
                const HomeStockDottedDivider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.hsPurpleBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.mic_rounded, color: AppColors.hsPurple),
                  ),
                  title: const Text('Voice Input', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Say "Add 2 packets of milk to inventory"', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
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

  /// Tier 1 Segmented Status Control (All | Low Stock | Expiring)
  Widget _buildStatusSegmentedControl(BuildContext context, InventoryState invState, int lowStockCount, int expiringCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(3),
        child: Row(
          children: [
            Expanded(
              child: _buildSegmentTab(
                context: context,
                label: 'All Items (${invState.items.length})',
                icon: Icons.inventory_2_rounded,
                isSelected: invState.filterType == InventoryFilterType.all,
                onTap: () => ref.read(inventoryControllerProvider.notifier).setFilterType(InventoryFilterType.all),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _buildSegmentTab(
                context: context,
                label: lowStockCount > 0 ? 'Low Stock ($lowStockCount)' : 'Low Stock',
                icon: Icons.warning_amber_rounded,
                isSelected: invState.filterType == InventoryFilterType.lowStock,
                activeColor: const Color(0xFFB45309),
                activeBg: const Color(0xFFFEF3C7),
                onTap: () => ref.read(inventoryControllerProvider.notifier).setFilterType(InventoryFilterType.lowStock),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _buildSegmentTab(
                context: context,
                label: expiringCount > 0 ? 'Expiring ($expiringCount)' : 'Expiring',
                icon: Icons.hourglass_top_rounded,
                isSelected: invState.filterType == InventoryFilterType.expiringSoon,
                activeColor: const Color(0xFFC2410C),
                activeBg: const Color(0xFFFFEDD5),
                onTap: () => ref.read(inventoryControllerProvider.notifier).setFilterType(InventoryFilterType.expiringSoon),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentTab({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    Color? activeColor,
    Color? activeBg,
    required VoidCallback onTap,
  }) {
    final defaultActiveColor = Theme.of(context).colorScheme.primary;
    final fgColor = isSelected ? (activeColor ?? defaultActiveColor) : AppColors.textSecondary;
    final bg = isSelected ? (activeBg ?? Colors.white) : Colors.transparent;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1.5),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? fgColor : AppColors.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: fgColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryCard(BuildContext context, InventoryItemModel item) {
    final isLow = item.isLowStock;
    final isOut = item.isOutOfStock;
    final formattedName = _formatName(item.name);
    final isSelected = _selectedItemIds.contains(item.id);

    final staple = findStapleForName(item.name, item.categoryName);
    final shoppingList = ref.watch(shoppingControllerProvider).list;
    final pendingShoppingItem = shoppingList?.items.cast<ShoppingItemModel?>().firstWhere(
      (s) => !s!.isCompleted &&
             ((s.inventoryItemId != null && s.inventoryItemId == item.id) ||
              s.itemName.toLowerCase().trim() == item.name.toLowerCase().trim()),
      orElse: () => null,
    );
    final isOnShoppingList = pendingShoppingItem != null;

    return HomeStockCard(
      padding: const EdgeInsets.all(14),
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
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Selection Checkbox (if in selection mode)
              if (_isSelectionMode) ...[
                Checkbox(
                  value: isSelected,
                  activeColor: AppColors.primary,
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
                const SizedBox(width: 4),
              ],

              // Left Category / Staple Indicator with calm neutral surface
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.outline,
                    width: 0.8,
                  ),
                ),
                alignment: Alignment.center,
                child: staple != null && staple.emoji.isNotEmpty
                    ? Text(staple.emoji, style: const TextStyle(fontSize: 22))
                    : Icon(
                        item.categoryIconData,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
              ),
              const SizedBox(width: 12),

              // Middle Item Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            formattedName,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (staple?.tamilName != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              staple!.tamilName!,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (item.categoryName.isNotEmpty)
                          Text(
                            item.categoryName,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        if (item.categoryName.isNotEmpty &&
                            item.storageLocation != null &&
                            item.storageLocation!.isNotEmpty)
                          const Text(' • ', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                        if (item.storageLocation != null && item.storageLocation!.isNotEmpty)
                          Expanded(
                            child: Text(
                              item.storageLocation!,
                              style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Subtle Stock status tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isOut
                                ? AppColors.outOfStockBg
                                : (isLow ? AppColors.lowStockBg : AppColors.inStockBg),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isOut
                                  ? AppColors.outOfStockBorder
                                  : (isLow ? AppColors.lowStockBorder : AppColors.inStockBorder),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            isOut ? 'Out of stock' : (isLow ? 'Low stock' : 'In stock'),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isOut
                                  ? AppColors.outOfStockText
                                  : (isLow ? AppColors.lowStockText : AppColors.inStockText),
                            ),
                          ),
                        ),

                        if (isOnShoppingList)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.outline, width: 0.8),
                            ),
                            child: const Text(
                              'On Shopping List',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),

                        if (item.expiryDate != null)
                          ExpiryUrgencyBadge(expiryDateStr: item.expiryDate, compact: true),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Right Quantity & Quick Action Stepper
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  QuantityStepper(
                    value: item.quantity,
                    unit: item.unit,
                    compact: true,
                    onDecrement: () => _handleDecrement(item),
                    onIncrement: () => _handleIncrement(item),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Min: ${item.minimumQuantity.toStringAsFixed(0)} ${item.unit}',
                    style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),

          // Dedicated "+ Shopping List" action for all in-stock created pantry items
          if (!isLow && !isOut) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isOnShoppingList)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: AppColors.outline),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shopping_cart_outlined, size: 12, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          'On Shopping List (${pendingShoppingItem.quantity % 1 == 0 ? pendingShoppingItem.quantity.toInt() : pendingShoppingItem.quantity} ${pendingShoppingItem.unit})',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                      ],
                    ),
                  )
                else
                  InkWell(
                    onTap: () => _addItemToShoppingList(item),
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: AppColors.outline),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_shopping_cart_rounded, size: 12, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text(
                            '+ Shopping List',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],

          // Helpful Restock Alert banner if Low Stock or Out of Stock
          if (isLow || isOut) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isOut ? const Color(0xFFFFF1F2) : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isOut ? const Color(0xFFFECDD3) : const Color(0xFFFDE68A),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isOut ? Icons.remove_shopping_cart_rounded : Icons.notification_important_rounded,
                    size: 14,
                    color: isOut ? const Color(0xFFE11D48) : const Color(0xFFD97706),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isOut ? 'Stock depleted' : 'Running low (${item.quantity.toStringAsFixed(0)} left)',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isOut ? const Color(0xFFBE123C) : const Color(0xFFB45309),
                      ),
                    ),
                  ),
                  if (isOnShoppingList)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFD8B4FE), width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🛒', style: TextStyle(fontSize: 10.5)),
                          const SizedBox(width: 4),
                          Text(
                            'On List (${pendingShoppingItem.quantity % 1 == 0 ? pendingShoppingItem.quantity.toInt() : pendingShoppingItem.quantity} ${pendingShoppingItem.unit})',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF7E22CE),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    InkWell(
                      onTap: () => _addItemToShoppingList(item),
                      borderRadius: BorderRadius.circular(6),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_shopping_cart_rounded, size: 13, color: AppColors.primary),
                            SizedBox(width: 4),
                            Text(
                              '+ Shopping List',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
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
      height: MediaQuery.of(context).size.height * 0.85,
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
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Title & Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.flash_on_rounded, size: 20, color: Color(0xFFD97706)),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Household Essentials',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                        Text(
                          'Select suggested items for quick details & quantity picking',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Search 650+ essentials in English or தமிழ்...',
                    hintStyle: TextStyle(fontSize: 13, color: AppColors.textMuted),
                    prefixIcon: Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Category Chips
            SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: kHouseholdStapleCategories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final cat = kHouseholdStapleCategories[index];
                  final isSelected = _selectedCategory == cat;
                  return InkWell(
                    onTap: () => setState(() => _selectedCategory = cat),
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),

            // Staples List
            Expanded(
              child: list.isEmpty
                  ? const Center(
                      child: Text(
                        'No matching essentials found.',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: list.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final staple = list[index];
                        final existing = widget.existingItems.cast<InventoryItemModel?>().firstWhere(
                              (i) => i?.name.trim().toLowerCase() == staple.name.trim().toLowerCase(),
                              orElse: () => null,
                            );
                        final inPantry = existing != null;

                        return InkWell(
                          onTap: () => widget.onSelectStaple(staple),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: inPantry ? const Color(0xFFF0FDF4) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: inPantry ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
                                width: inPantry ? 1.2 : 0.8,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(staple.emoji, style: const TextStyle(fontSize: 22)),
                                const SizedBox(width: 12),
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
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimary,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (staple.tamilName != null && staple.tamilName!.isNotEmpty) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFEF3C7),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: const Color(0xFFFDE68A)),
                                              ),
                                              child: Text(
                                                staple.tamilName!,
                                                style: const TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF92400E),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${staple.subCategory ?? staple.category} • Pack: ${staple.defaultQty == staple.defaultQty.roundToDouble() ? staple.defaultQty.toInt() : staple.defaultQty} ${staple.defaultUnit}',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                if (inPantry) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF16A34A)),
                                        SizedBox(width: 4),
                                        Text(
                                          'In Pantry',
                                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF16A34A)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () => widget.onAddToShoppingList(existing),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryContainer,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.add_shopping_cart_rounded, size: 13, color: AppColors.primary),
                                          SizedBox(width: 4),
                                          Text(
                                            '+ List',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  ElevatedButton.icon(
                                    onPressed: () => widget.onSelectStaple(staple),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFD97706),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      visualDensity: VisualDensity.compact,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                                    ),
                                    icon: const Icon(Icons.add_rounded, size: 14),
                                    label: const Text(
                                      'Select & Add',
                                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ],
                            ),
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
