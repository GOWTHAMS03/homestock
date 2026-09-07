import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/homestock/homestock_app_bar.dart';
import '../../core/widgets/homestock/homestock_card.dart';
import '../../core/widgets/homestock/homestock_pill_badge.dart';
import '../../core/widgets/quantity_stepper.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/widgets/stock_status_badge.dart';
import '../../core/widgets/sync_status_bar.dart';
import '../voice/widgets/voice_input_button.dart';
import '../voice/widgets/voice_bottom_sheet.dart';
import '../barcode/widgets/barcode_scanner_widget.dart';
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
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: HomeStockAppBar(
        title: 'Household Inventory',
        subtitle: '${invState.items.length} items tracked in home pantry',
        showBackButton: false,
        actions: const [
          VoiceInputButton(
            tooltip: 'Inventory voice command',
          ),
          SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          const SyncStatusBar(),

          // Search Box with 50dp pill radius, scan icon, voice button, clear button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: AppColors.outline.withValues(alpha: 0.8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => ref.read(inventoryControllerProvider.notifier).setSearchQuery(val),
                decoration: InputDecoration(
                  hintText: 'Search items, brands, location...',
                  hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textMuted),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
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
                      IconButton(
                        icon: const Icon(Icons.qr_code_scanner_rounded, size: 20, color: AppColors.primary),
                        tooltip: 'Scan Barcode',
                        onPressed: () => BarcodeScannerWidget.open(context),
                      ),
                      const VoiceInputButton(size: 20),
                      const SizedBox(width: 4),
                    ],
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // Urgency Filter Chips (Tier 1)
          SizedBox(
            height: 38,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              scrollDirection: Axis.horizontal,
              children: [
                _buildUrgencyChip(
                  label: 'All Items',
                  isSelected: invState.filterType == InventoryFilterType.all,
                  onTap: () => ref.read(inventoryControllerProvider.notifier).setFilterType(InventoryFilterType.all),
                ),
                const SizedBox(width: 8),
                _buildUrgencyChip(
                  label: lowStockCount > 0 ? '⚠️ Low Stock ($lowStockCount)' : 'Low Stock',
                  isSelected: invState.filterType == InventoryFilterType.lowStock,
                  selectedColor: AppColors.lowStockBg,
                  selectedTextColor: AppColors.lowStockText,
                  onTap: () => ref.read(inventoryControllerProvider.notifier).setFilterType(InventoryFilterType.lowStock),
                ),
                const SizedBox(width: 8),
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

          const SizedBox(height: 8),

          // Category Chips (Tier 2)
          if (categories.isNotEmpty) ...[
            SizedBox(
              height: 34,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length + 1,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    final isAll = invState.selectedCategoryId == null;
                    return InkWell(
                      onTap: () => ref.read(inventoryControllerProvider.notifier).selectCategory(null),
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isAll ? AppColors.darkFloatingPill : Colors.white,
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                            color: isAll ? AppColors.darkFloatingPill : AppColors.outline.withValues(alpha: 0.8),
                          ),
                        ),
                        child: Text(
                          'All Categories',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isAll ? FontWeight.w700 : FontWeight.w500,
                            color: isAll ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }

                  final cat = categories[index - 1];
                  final isSelected = invState.selectedCategoryId == cat.id;

                  return InkWell(
                    onTap: () => ref.read(inventoryControllerProvider.notifier).selectCategory(cat.id),
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.darkFloatingPill : Colors.white,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: isSelected ? AppColors.darkFloatingPill : AppColors.outline.withValues(alpha: 0.8),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            cat.iconData,
                            size: 13,
                            color: isSelected ? Colors.white : cat.color,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            cat.name,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 8),

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
                            _showAddItemMenu(context);
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
        onPressed: () => _showAddItemMenu(context),
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text('Add Item', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      ),
    );
  }

  void _showAddItemMenu(BuildContext context) {
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

  Widget _buildUrgencyChip({
    required String label,
    required bool isSelected,
    Color? selectedColor,
    Color? selectedTextColor,
    required VoidCallback onTap,
  }) {
    final bgColor = isSelected ? (selectedColor ?? AppColors.primaryContainer) : Colors.white;
    final textColor = isSelected ? (selectedTextColor ?? AppColors.primary) : AppColors.textSecondary;
    final borderColor = isSelected ? (selectedTextColor ?? AppColors.primary) : AppColors.outline.withValues(alpha: 0.8);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: borderColor, width: 0.8),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
          ],
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
    final isLow = item.isLowStock;
    final isOut = item.isOutOfStock;

    return HomeStockCard(
      padding: const EdgeInsets.all(14),
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: item.id)),
        );
        ref.read(inventoryControllerProvider.notifier).loadData();
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Category Indicator with soft background
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outline.withValues(alpha: 0.5)),
            ),
            child: Icon(
              item.categoryIconData,
              size: 22,
              color: item.categoryColorParsed,
            ),
          ),
          const SizedBox(width: 12),

          // Middle Item Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
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
                    // Stock status pill
                    HomeStockPillBadge(
                      label: isOut ? 'Out of Stock' : (isLow ? 'Low Stock' : 'In Stock'),
                      variant: isOut
                          ? HomeStockPillVariant.pink
                          : (isLow ? HomeStockPillVariant.yellow : HomeStockPillVariant.green),
                      fontSize: 10,
                    ),

                    if (item.expiryDate != null)
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
                'Min: ${item.minimumQuantity.toStringAsFixed(0)} ${item.unit}',
                style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
