import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/quantity_stepper.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/widgets/stock_status_badge.dart';
import '../../core/widgets/sync_status_bar.dart';
import '../voice/widgets/voice_input_button.dart';
import 'add_edit_item_screen.dart';
import 'category_model.dart';
import 'inventory_controller.dart';
import 'inventory_model.dart';
import 'item_detail_screen.dart';
import 'stock_update_dialog.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _searchController = TextEditingController();

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
            content: Text('Used 1 ${item.unit} of ${item.name}'),
            duration: const Duration(seconds: 2),
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

  @override
  Widget build(BuildContext context) {
    final invState = ref.watch(inventoryControllerProvider);
    final displayedItems = invState.filteredItems;
    final categories = invState.categories.isNotEmpty
        ? invState.categories
        : CategoryModel.defaultCategories();

    // Counts for filter chips
    final lowStockCount = invState.items
        .where((i) => i.stockStatus == 'LOW_STOCK' || i.stockStatus == 'OUT_OF_STOCK')
        .length;
    final expiringCount = invState.items
        .where((i) => i.expiryStatus == 'EXPIRING_SOON' || i.expiryStatus == 'EXPIRED')
        .length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Household Inventory', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: const [
          VoiceInputButton(
            tooltip: 'Inventory voice command',
          ),
        ],
      ),
      body: Column(
        children: [
          const SyncStatusBar(),
          // Search Box with Clean Clear Action and Voice Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => ref.read(inventoryControllerProvider.notifier).setSearchQuery(val),
              decoration: InputDecoration(
                hintText: 'Search items, brands, storage location...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textMuted),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(inventoryControllerProvider.notifier).setSearchQuery('');
                        },
                      ),
                    const VoiceInputButton(size: 20),
                  ],
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),

          // Smart Urgency Filter Chips (Tier 1)
          SizedBox(
            height: 44,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              scrollDirection: Axis.horizontal,
              children: [
                _buildUrgencyChip(
                  label: 'All Items',
                  isSelected: invState.filterType == InventoryFilterType.all,
                  onTap: () => ref.read(inventoryControllerProvider.notifier).setFilterType(InventoryFilterType.all),
                ),
                const SizedBox(width: AppSpacing.xs),
                _buildUrgencyChip(
                  label: lowStockCount > 0 ? '⚠️ Low Stock ($lowStockCount)' : 'Low Stock',
                  isSelected: invState.filterType == InventoryFilterType.lowStock,
                  selectedColor: AppColors.lowStockBg,
                  selectedTextColor: AppColors.lowStockText,
                  onTap: () => ref.read(inventoryControllerProvider.notifier).setFilterType(InventoryFilterType.lowStock),
                ),
                const SizedBox(width: AppSpacing.xs),
                _buildUrgencyChip(
                  label: expiringCount > 0 ? '⏳ Expiring ($expiringCount)' : 'Expiring Soon',
                  isSelected: invState.filterType == InventoryFilterType.expiringSoon,
                  selectedColor: AppColors.expiringSoonBg,
                  selectedTextColor: AppColors.expiringSoonText,
                  onTap: () => ref.read(inventoryControllerProvider.notifier).setFilterType(InventoryFilterType.expiringSoon),
                ),
              ],
            ),
          ),

          // Category Chips (Tier 2) - Always visible in offline and online modes
          if (categories.isNotEmpty) ...[
            SizedBox(
              height: 38,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length + 1,
                separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.xs),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    final isAll = invState.selectedCategoryId == null;
                    return FilterChip(
                      selected: isAll,
                      label: const Text('All Categories'),
                      onSelected: (_) => ref.read(inventoryControllerProvider.notifier).selectCategory(null),
                      selectedColor: AppColors.primaryContainer,
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: isAll ? FontWeight.w700 : FontWeight.w500,
                        color: isAll ? AppColors.primary : AppColors.textSecondary,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusFull)),
                      side: BorderSide(color: isAll ? AppColors.primary : AppColors.outline),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    );
                  }

                  final cat = categories[index - 1];
                  final isSelected = invState.selectedCategoryId == cat.id;

                  return FilterChip(
                    selected: isSelected,
                    avatar: Icon(cat.iconData, size: 14, color: isSelected ? AppColors.primary : cat.color),
                    label: Text(cat.name),
                    onSelected: (_) => ref.read(inventoryControllerProvider.notifier).selectCategory(cat.id),
                    selectedColor: AppColors.primaryContainer,
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusFull)),
                    side: BorderSide(color: isSelected ? AppColors.primary : AppColors.outline),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xs),

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
                                ? 'No items match the active urgency filter.'
                                : 'No items yet. Add your first household product.'),
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
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const AddEditItemScreen()),
                            );
                          }
                        },
                      )
                    : RefreshIndicator(
                        onRefresh: () => ref.read(inventoryControllerProvider.notifier).loadData(),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          itemCount: displayedItems.length,
                          separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            final item = displayedItems[index];
                            return _buildInventoryCard(context, item);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const VoiceInputButton.floating(
            tooltip: 'Voice inventory command',
          ),
          const SizedBox(width: 12),
          FloatingActionButton.extended(
            heroTag: 'inventory_add_btn',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddEditItemScreen()),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Item', style: TextStyle(fontWeight: FontWeight.w700)),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildUrgencyChip({
    required String label,
    required bool isSelected,
    Color? selectedColor,
    Color? selectedTextColor,
    required VoidCallback onTap,
  }) {
    final bgColor = isSelected ? (selectedColor ?? AppColors.primaryContainer) : AppColors.surface;
    final textColor = isSelected ? (selectedTextColor ?? AppColors.primary) : AppColors.textSecondary;
    final borderColor = isSelected ? (selectedTextColor ?? AppColors.primary) : AppColors.outline;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(color: borderColor),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildInventoryCard(BuildContext context, InventoryItemModel item) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: item.id)),
          );
          ref.read(inventoryControllerProvider.notifier).loadData();
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Category Indicator with soft background
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.categoryColorParsed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(item.categoryIconData, size: 22, color: item.categoryColorParsed),
              ),
              const SizedBox(width: AppSpacing.md),

              // Middle Item Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    if (item.brand != null && item.brand!.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(
                        item.brand!,
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Dedicated Category Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: item.categoryColorParsed.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: item.categoryColorParsed.withValues(alpha: 0.25),
                              width: 0.6,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(item.categoryIconData, size: 10, color: item.categoryColorParsed),
                              const SizedBox(width: 3),
                              Text(
                                item.categoryName,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: item.categoryColorParsed,
                                ),
                              ),
                            ],
                          ),
                        ),
                        StockStatusBadge.fromString(item.stockStatus, compact: true),
                        ExpiryUrgencyBadge(expiryDateStr: item.expiryDate, compact: true),
                        if (item.storageLocation != null && item.storageLocation!.isNotEmpty)
                          Text(
                            '• ${item.storageLocation}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Right Quantity & Quick Action Stepper
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
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
                    'Min: ${item.minimumQuantity} ${item.unit}',
                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
