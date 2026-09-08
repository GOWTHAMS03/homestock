import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/homestock/homestock_app_bar.dart';
import '../../core/widgets/homestock/homestock_card.dart';
import '../../core/widgets/homestock/homestock_pill_badge.dart';
import '../../core/widgets/offline_wifi_badge.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/widgets/sync_status_bar.dart';
import '../barcode/widgets/barcode_scanner_widget.dart';
import '../inventory/inventory_controller.dart';
import '../inventory/inventory_model.dart';
import '../purchase/add_purchase_screen.dart';
import '../purchase/purchases_screen.dart';
import '../smart_shopping/smart_shopping_screen.dart';
import '../voice/widgets/voice_input_button.dart';
import 'add_shopping_item_dialog.dart';
import 'shopping_controller.dart';
import 'shopping_model.dart';
import 'shopping_mode_screen.dart';

enum _ShoppingFilter { all, toBuy, completed }

/// Quick-add household staple definitions with standard sizes and emojis
class _StapleItem {
  final String name;
  final double qty;
  final String unit;
  final String emoji;
  final String category;

  const _StapleItem({
    required this.name,
    required this.qty,
    required this.unit,
    required this.emoji,
    required this.category,
  });
}

const List<_StapleItem> _kQuickStaples = [
  _StapleItem(name: 'Milk', qty: 1.0, unit: 'L', emoji: '🥛', category: 'Dairy'),
  _StapleItem(name: 'Eggs', qty: 12.0, unit: 'pcs', emoji: '🥚', category: 'Dairy'),
  _StapleItem(name: 'Basmati Rice', qty: 5.0, unit: 'kg', emoji: '🌾', category: 'Grains'),
  _StapleItem(name: 'Sunflower Oil', qty: 1.0, unit: 'L', emoji: '🌻', category: 'Oils'),
  _StapleItem(name: 'Onions', qty: 1.0, unit: 'kg', emoji: '🧅', category: 'Vegetables'),
  _StapleItem(name: 'Tomatoes', qty: 1.0, unit: 'kg', emoji: '🍅', category: 'Vegetables'),
  _StapleItem(name: 'Aashirvaad Atta', qty: 5.0, unit: 'kg', emoji: '🫓', category: 'Grains'),
  _StapleItem(name: 'Bread', qty: 1.0, unit: 'pk', emoji: '🍞', category: 'Bakery'),
  _StapleItem(name: 'Tea / Chai', qty: 250.0, unit: 'g', emoji: '☕', category: 'Beverages'),
  _StapleItem(name: 'Potatoes', qty: 1.0, unit: 'kg', emoji: '🥔', category: 'Vegetables'),
  _StapleItem(name: 'Bananas', qty: 6.0, unit: 'pcs', emoji: '🍌', category: 'Fruits'),
  _StapleItem(name: 'Dishwash Gel', qty: 500.0, unit: 'ml', emoji: '🧼', category: 'Cleaning'),
];

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
      if (success) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
            backgroundColor: AppColors.textPrimary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _addStapleItem(_StapleItem staple) async {
    final success = await ref.read(shoppingControllerProvider.notifier).addItem(
      itemName: staple.name,
      quantity: staple.qty,
      unit: staple.unit,
    );
    if (mounted && success) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Text(staple.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Added ${staple.name} (${staple.qty == staple.qty.roundToDouble() ? staple.qty.toInt() : staple.qty} ${staple.unit}) to list',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.textPrimary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
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
    }
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
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: HomeStockAppBar(
        title: 'Shopping List',
        subtitle: totalCount == 0
            ? '0 items • Offline ready'
            : '$pendingCount to buy • $completedCount completed',
        showBackButton: false,
        actions: [
          if (completedCount > 0)
            TextButton(
              onPressed: () => ref.read(shoppingControllerProvider.notifier).clearCompleted(),
              child: const Text(
                'Clear Done',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w700),
              ),
            ),
          const OfflineWifiBadge(),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          const SyncStatusBar(),

          // Unified Existing Pill Search Bar (with camera barcode and voice search)
          _buildExistingSearchBar(context),

          // Main scrollable content
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      children: [
                        // 1. Single Non-Redundant Feature Actions Row (Price Deals, Shop Mode, Restocked)
                        _buildFeatureActionsRow(context),

                        const SizedBox(height: 14),

                        // 2. Pantry Auto-Restock Section (Only when low stock items exist)
                        if (lowStockSuggestions.isNotEmpty) ...[
                          _buildPantryRestockSection(context, lowStockSuggestions),
                          const SizedBox(height: 14),
                        ],

                        // 3. One-Tap Household Essentials Carousel
                        _buildStaplesCarousel(context),

                        const SizedBox(height: 16),

                        // 4. Active Items List OR Clean Non-Redundant Empty Guide
                        if (totalCount > 0) ...[
                          _buildActiveListSection(
                            context,
                            totalCount: totalCount,
                            completedCount: completedCount,
                            pendingCount: pendingCount,
                            completionRatio: completionRatio,
                            filteredItems: filteredItems,
                          ),
                        ] else ...[
                          _buildEmptyShoppingGuide(context),
                        ],

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'shopping_add_btn',
        onPressed: () => AddShoppingItemDialog.show(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        tooltip: 'Add Shopping Item',
        child: const Icon(Icons.add_rounded, size: 26),
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
                        backgroundColor: const Color(0xFFD97706),
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

  /// Unified Existing Search Bar from Inventory:
  /// 48dp pill shape, integrated camera barcode scan + voice search in a single clean container
  Widget _buildExistingSearchBar(BuildContext context) {
    return Padding(
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
          onChanged: (val) => setState(() => _searchQuery = val.trim()),
          onSubmitted: (val) => _submitQuickAdd(val),
          textInputAction: TextInputAction.done,
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search or add shopping items...',
            hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.primary),
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
                        color: AppColors.primary,
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
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 20, color: AppColors.primary),
                    tooltip: 'Scan Barcode',
                    onPressed: () => BarcodeScannerWidget.open(context),
                  ),
                  const VoiceInputButton(size: 20, tooltip: 'Voice shopping command'),
                  const SizedBox(width: 4),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Single, clean, non-redundant feature row:
  /// 1. Live Price Deals ⚡
  /// 2. Shop Mode 🛒
  /// 3. Restocked Receipts 🧾
  Widget _buildFeatureActionsRow(BuildContext context) {
    return Row(
      children: [
        // 1. Price Checker & Live Deals
        Expanded(
          child: _buildActionTile(
            icon: Icons.bolt_rounded,
            iconColor: const Color(0xFFD97706),
            iconBg: const Color(0xFFFEF3C7),
            title: 'Price Deals ⚡',
            subtitle: 'Compare stores',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SmartShoppingScreen()),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // 2. In-Store Shop Mode
        Expanded(
          child: _buildActionTile(
            icon: Icons.shopping_cart_checkout_rounded,
            iconColor: AppColors.hsGreen,
            iconBg: AppColors.hsGreenBg,
            title: 'Shop Mode',
            subtitle: 'Store checklist',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ShoppingModeScreen()),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // 3. Restocked History
        Expanded(
          child: _buildActionTile(
            icon: Icons.receipt_long_rounded,
            iconColor: AppColors.primary,
            iconBg: AppColors.primaryContainer,
            title: 'Restocked',
            subtitle: 'Bills & receipts',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PurchasesScreen()),
            ),
          ),
        ),
      ],
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                const SizedBox(height: 7),
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
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

  /// Pantry Running Low section with 1-tap "Restock All"
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
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(width: 6),
            HomeStockPillBadge(
              label: '${lowStockSuggestions.length} low',
              variant: HomeStockPillVariant.yellow,
              fontSize: 10,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
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

  /// 1-Tap Household Staples Carousel
  Widget _buildStaplesCarousel(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.flash_on_rounded, size: 15, color: AppColors.primary),
            SizedBox(width: 4),
            Text(
              'Quick-Add Essentials (1-Tap)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            SizedBox(width: 6),
            HomeStockPillBadge(
              label: '1-Tap',
              variant: HomeStockPillVariant.green,
              fontSize: 9.5,
              padding: EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _kQuickStaples.length,
            separatorBuilder: (_, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final staple = _kQuickStaples[index];
              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50),
                child: InkWell(
                  onTap: () => _addStapleItem(staple),
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(staple.emoji, style: const TextStyle(fontSize: 13)),
                        const SizedBox(width: 6),
                        Text(
                          '${staple.name} (${staple.qty == staple.qty.roundToDouble() ? staple.qty.toInt() : staple.qty} ${staple.unit})',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.add_circle_outline_rounded, size: 14, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Active Shopping Items List with Filters and Progress
  Widget _buildActiveListSection(
    BuildContext context, {
    required int totalCount,
    required int completedCount,
    required int pendingCount,
    required double completionRatio,
    required List<ShoppingItemModel> filteredItems,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Shopping Progress Card
        HomeStockCard(
          padding: const EdgeInsets.all(12),
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
                              '$pendingCount to buy',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppColors.textPrimary),
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
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AddPurchaseScreen()),
                    ),
                    icon: const Icon(Icons.receipt_long_rounded, size: 13),
                    label: const Text('Record Bill', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                    ),
                  ),
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

        const SizedBox(height: 12),

        // Filter Chips Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('All ($totalCount)', _ShoppingFilter.all),
              const SizedBox(width: 8),
              _buildFilterChip('To Buy ($pendingCount)', _ShoppingFilter.toBuy),
              const SizedBox(width: 8),
              _buildFilterChip('Done ($completedCount)', _ShoppingFilter.completed),
              const SizedBox(width: 10),
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

        const SizedBox(height: 12),

        // Items list
        if (filteredItems.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            alignment: Alignment.center,
            child: Column(
              children: [
                const Icon(Icons.search_off_rounded, size: 36, color: AppColors.textMuted),
                const SizedBox(height: 8),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'No items matching "$_searchQuery"'
                      : 'No items in this filter tab',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          )
        else
          ...filteredItems.map((item) => _buildShoppingItemTile(context, item)),
      ],
    );
  }

  /// Clean, un-cluttered empty guide with ZERO duplicate buttons:
  /// Barcode and Voice are already in the top search bar!
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
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shopping_bag_outlined, size: 38, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          const Text(
            'Your Shopping List is Empty',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
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
                color: AppColors.textSecondary,
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
                Icon(Icons.offline_pin_rounded, size: 14, color: AppColors.hsGreen),
                SizedBox(width: 4),
                Text(
                  '100% Offline Ready • Changes saved locally',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.hsGreen),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Single subtle button for detailed entry
          TextButton.icon(
            onPressed: () => AddShoppingItemDialog.show(context),
            icon: const Icon(Icons.edit_note_rounded, size: 18, color: AppColors.primary),
            label: const Text(
              '+ Add with Category & Notes',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
          ),
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
              decoration: const BoxDecoration(
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
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt_rounded, size: 13, color: Color(0xFFD97706)),
                      SizedBox(width: 2),
                      Text(
                        'Deals',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF92400E)),
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
}
