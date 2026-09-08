import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/homestock/homestock_app_bar.dart';
import '../../core/widgets/homestock/homestock_card.dart';
import '../../core/widgets/homestock/homestock_pill_badge.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/widgets/sync_status_bar.dart';
import '../barcode/widgets/barcode_scanner_widget.dart';
import '../inventory/inventory_controller.dart';
import '../inventory/inventory_model.dart';
import '../purchase/add_purchase_screen.dart';
import '../smart_shopping/smart_shopping_screen.dart';
import '../voice/widgets/voice_bottom_sheet.dart';
import '../voice/widgets/voice_input_button.dart';
import 'add_shopping_item_dialog.dart';
import 'shopping_controller.dart';
import 'shopping_model.dart';
import 'shopping_mode_screen.dart';

enum _ShoppingFilter { all, toBuy, completed }

class ShoppingScreen extends ConsumerStatefulWidget {
  const ShoppingScreen({super.key});

  @override
  ConsumerState<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends ConsumerState<ShoppingScreen> {
  _ShoppingFilter _filter = _ShoppingFilter.all;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _selectedItemIds = {};
  bool _isSelectionMode = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

    // Pantry restock suggestions: items that are low or out of stock and not yet in the shopping list
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
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: HomeStockAppBar(
        title: 'Shared Shopping List',
        subtitle: '$pendingCount item(s) to buy',
        showBackButton: false,
        actions: [
          const VoiceInputButton(
            tooltip: 'Voice shopping command',
          ),
          if (completedCount > 0)
            TextButton(
              onPressed: () => ref.read(shoppingControllerProvider.notifier).clearCompleted(),
              child: const Text('Clear Done', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          const SyncStatusBar(),
          Expanded(
            child: (shoppingState.isLoading && list == null)
                ? ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: 6,
                    separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) => const SkeletonItemCard(),
                  )
                : RefreshIndicator(
                    onRefresh: () => ref.read(shoppingControllerProvider.notifier).loadShoppingList(),
                    child: ListView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      children: [
                        // 1. Shopping Progress & Record CTA Card (when items exist)
                        if (totalCount > 0) ...[
                          HomeStockCard(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                '$pendingCount item(s) to buy',
                                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimary),
                                              ),
                                              const SizedBox(width: 6),
                                              HomeStockPillBadge(
                                                label: '${(completionRatio * 100).toInt()}% Done',
                                                variant: completedCount > 0 ? HomeStockPillVariant.green : HomeStockPillVariant.neutral,
                                                fontSize: 10,
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '$completedCount of $totalCount items checked off',
                                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (pendingCount > 0) ...[
                                      ElevatedButton.icon(
                                        onPressed: () => Navigator.of(context).push(
                                          MaterialPageRoute(builder: (_) => const ShoppingModeScreen()),
                                        ),
                                        icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 14),
                                        label: const Text('Shop Mode', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.hsGreen,
                                          foregroundColor: Colors.white,
                                          minimumSize: Size.zero,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      OutlinedButton.icon(
                                        onPressed: () => Navigator.of(context).push(
                                          MaterialPageRoute(builder: (_) => const AddPurchaseScreen()),
                                        ),
                                        icon: const Icon(Icons.receipt_long_rounded, size: 14),
                                        label: const Text('Record', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.primary,
                                          side: const BorderSide(color: AppColors.primary),
                                          minimumSize: Size.zero,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: completionRatio,
                                    backgroundColor: const Color(0xFFE2E8F0),
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.hsGreen),
                                    minHeight: 6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],

                        // 2. Pantry Restock Suggestions (When items exist in list)
                        if (totalCount > 0 && lowStockSuggestions.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.bolt_rounded, size: 16, color: Color(0xFFF59E0B)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Pantry Running Low',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                              Text(
                                '${lowStockSuggestions.length} items',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 82,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: lowStockSuggestions.length,
                              separatorBuilder: (_, i) => const SizedBox(width: 10),
                              itemBuilder: (context, index) {
                                final pantryItem = lowStockSuggestions[index];
                                return _buildRestockSuggestionCard(pantryItem);
                              },
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],

                        // 3. Search Bar & Filter Chips (When items exist)
                        if (totalCount > 0) ...[
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                                    style: const TextStyle(fontSize: 13),
                                    decoration: InputDecoration(
                                      hintText: 'Search shopping items...',
                                      hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                      prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textSecondary),
                                      suffixIcon: _searchQuery.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(Icons.clear_rounded, size: 16),
                                              onPressed: () {
                                                _searchController.clear();
                                                setState(() => _searchQuery = '');
                                              },
                                            )
                                          : null,
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildFilterChip('All ($totalCount)', _ShoppingFilter.all),
                                const SizedBox(width: 8),
                                _buildFilterChip('To Buy ($pendingCount)', _ShoppingFilter.toBuy),
                                const SizedBox(width: 8),
                                _buildFilterChip('Done ($completedCount)', _ShoppingFilter.completed),
                                const SizedBox(width: 12),
                                ActionChip(
                                  avatar: Icon(
                                    _isSelectionMode ? Icons.close_rounded : Icons.bolt_rounded,
                                    size: 14,
                                    color: _isSelectionMode ? AppColors.primary : const Color(0xFFD97706),
                                  ),
                                  label: Text(
                                    _isSelectionMode ? 'Cancel' : 'Compare Basket ⚡',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: _isSelectionMode ? AppColors.primary : const Color(0xFFD97706),
                                    ),
                                  ),
                                  backgroundColor: _isSelectionMode ? AppColors.primaryContainer : const Color(0xFFFEF3C7),
                                  side: BorderSide(
                                    color: _isSelectionMode ? AppColors.primary : const Color(0xFFFDE68A),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isSelectionMode = !_isSelectionMode;
                                      if (!_isSelectionMode) {
                                        _selectedItemIds.clear();
                                      } else {
                                        _selectedItemIds.addAll(
                                          filteredItems.where((i) => !i.isCompleted).map((i) => i.id),
                                        );
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          if (_isSelectionMode) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedItemIds.addAll(filteredItems.where((i) => !i.isCompleted).map((i) => i.id));
                                    });
                                  },
                                  child: const Text('Select All Pending', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w700)),
                                ),
                                const SizedBox(width: 12),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedItemIds.addAll(
                                        filteredItems.where((i) => i.isAutoGenerated && !i.isCompleted).map((i) => i.id),
                                      );
                                    });
                                  },
                                  child: const Text('Select Low-Stock', style: TextStyle(fontSize: 11, color: Color(0xFFD97706), fontWeight: FontWeight.w700)),
                                ),
                                const SizedBox(width: 12),
                                InkWell(
                                  onTap: () => setState(() => _selectedItemIds.clear()),
                                  child: const Text('Clear', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: AppSpacing.md),
                        ],

                        // 4. Shopping Items List / Clean Empty State
                        if (totalCount == 0)
                          _buildEmptyShoppingState(context, lowStockSuggestions)
                        else if (filteredItems.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(32),
                            alignment: Alignment.center,
                            child: Column(
                              children: [
                                const Icon(Icons.search_off_rounded, size: 40, color: AppColors.textMuted),
                                const SizedBox(height: 8),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? 'No items matching "$_searchQuery"'
                                      : 'No items in this category',
                                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          )
                        else
                          ...filteredItems.map((item) => _buildShoppingItemTile(context, item)),

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: totalCount == 0
          ? null
          : FloatingActionButton.extended(
              heroTag: 'shopping_add_btn',
              onPressed: () => _showAddShoppingItemMenu(context),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Add Item', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
            ),
      bottomNavigationBar: _selectedItemIds.isNotEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    offset: const Offset(0, -2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_selectedItemIds.length} item(s) selected',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textPrimary),
                        ),
                        const Text('Multi-provider price optimizer', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                    const Spacer(),
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
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.bolt_rounded, size: 18),
                      label: const Text('Find Best Price ⚡', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildEmptyShoppingState(BuildContext context, List<InventoryItemModel> lowStockSuggestions) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shopping_bag_outlined, size: 52, color: AppColors.primary),
          ),
          const SizedBox(height: 18),
          const Text(
            'Your shopping list is empty',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Add items you need to buy or let HomeStock restock items running low in your pantry.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 22),

          // 3 Quick Add Options
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => AddShoppingItemDialog.show(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Manually'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  elevation: 2,
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => BarcodeScannerWidget.open(context),
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 18, color: AppColors.primary),
                label: const Text('Scan Barcode', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => VoiceBottomSheet.show(context),
                icon: const Icon(Icons.mic_rounded, size: 18, color: AppColors.hsPurple),
                label: const Text('Voice Input', style: TextStyle(color: AppColors.hsPurple, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.hsPurple.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                ),
              ),
            ],
          ),

          // If pantry has low stock items, show them right here for 1-tap restock!
          if (lowStockSuggestions.isNotEmpty) ...[
            const SizedBox(height: 32),
            Row(
              children: [
                const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFFF59E0B)),
                const SizedBox(width: 4),
                const Text(
                  'Quick Restock from Pantry',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                const Spacer(),
                Text(
                  '${lowStockSuggestions.length} items low',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 82,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: lowStockSuggestions.length,
                separatorBuilder: (_, i) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final pantryItem = lowStockSuggestions[index];
                  return _buildRestockSuggestionCard(pantryItem);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, _ShoppingFilter filter) {
    final isSelected = _filter == filter;
    return InkWell(
      onTap: () => setState(() => _filter = filter),
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
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
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  pantryItem.isOutOfStock ? 'Out of stock' : 'Low stock (${pantryItem.quantity} ${pantryItem.unit})',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: pantryItem.isOutOfStock ? AppColors.outOfStockText : const Color(0xFFD97706),
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
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShoppingItemTile(BuildContext context, ShoppingItemModel item) {
    return Dismissible(
      key: Key('shopping_item_${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Delete', style: TextStyle(color: AppColors.outOfStockText, fontWeight: FontWeight.w700, fontSize: 13)),
            SizedBox(width: 8),
            Icon(Icons.delete_outline_rounded, color: AppColors.outOfStockText, size: 20),
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
                      categoryId: null,
                      quantity: item.quantity,
                      unit: item.unit,
                    );
              },
            ),
          ),
        );
      },
      child: HomeStockCard(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
            : () => ref.read(shoppingControllerProvider.notifier).toggleItem(item.id),
        child: Row(
          children: [
            if (_isSelectionMode && !item.isCompleted) ...[
              Checkbox(
                value: _selectedItemIds.contains(item.id),
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
            // Circular Check Indicator
            InkWell(
              onTap: () => ref.read(shoppingControllerProvider.notifier).toggleItem(item.id),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.isCompleted ? AppColors.hsGreen : Colors.white,
                  border: Border.all(
                    color: item.isCompleted ? AppColors.hsGreen : AppColors.outline.withValues(alpha: 0.9),
                    width: 1.5,
                  ),
                ),
                child: item.isCompleted
                    ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 12),

            // Item Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.itemName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                            color: item.isCompleted ? AppColors.textMuted : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (item.isAutoGenerated) ...[
                        const SizedBox(width: 6),
                        const HomeStockPillBadge(
                          label: 'Low-Stock',
                          variant: HomeStockPillVariant.yellow,
                          fontSize: 9,
                          padding: EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.isCompleted
                        ? 'Bought by ${item.completedByName ?? 'Family'}'
                        : 'Added by ${item.addedByName} • ${item.quantity == item.quantity.roundToDouble() ? item.quantity.toInt() : item.quantity} ${item.unit}',
                    style: TextStyle(
                      fontSize: 11,
                      color: item.isCompleted ? AppColors.hsGreen : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // In-card Quantity Stepper
            if (!item.isCompleted) ...[
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () {
                        final next = (item.quantity - 1.0).clamp(0.0, 999.0);
                        ref.read(shoppingControllerProvider.notifier).updateQuantity(item.id, next);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.remove_rounded, size: 14, color: AppColors.textSecondary),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        '${item.quantity == item.quantity.roundToDouble() ? item.quantity.toInt() : item.quantity}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppColors.textPrimary),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        ref.read(shoppingControllerProvider.notifier).updateQuantity(item.id, item.quantity + 1.0);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.add_rounded, size: 14, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Compare Deals Button
              InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SmartShoppingScreen(
                      itemId: item.id,
                      inventoryItemId: item.inventoryItemId,
                      itemName: item.itemName,
                      quantity: item.quantity,
                      unit: item.unit,
                    ),
                  ),
                ),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.compare_arrows_rounded, size: 13, color: AppColors.primary),
                      SizedBox(width: 3),
                      Text(
                        'Deals',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Delete action
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
              onPressed: () => ref.read(shoppingControllerProvider.notifier).deleteItem(item.id),
              tooltip: 'Remove',
            ),
          ],
        ),
      ),
    );
  }

  void _showAddShoppingItemMenu(BuildContext context) {
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
                      'Add to Shopping List',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
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
                  subtitle: const Text('Enter name, quantity, and unit', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    AddShoppingItemDialog.show(context);
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
                  subtitle: const Text('Camera scan to add verified product', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
                  subtitle: const Text('Say "Add 2 litre cooking oil to shopping list"', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
}
