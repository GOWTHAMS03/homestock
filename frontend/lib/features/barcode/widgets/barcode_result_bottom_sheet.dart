import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:homestock/core/constants/app_colors.dart';
import 'package:homestock/core/constants/app_spacing.dart';
import 'package:homestock/features/home_switcher/home_controller.dart';
import 'package:homestock/features/inventory/add_edit_item_screen.dart';
import 'package:homestock/features/inventory/item_detail_screen.dart';
import 'package:homestock/features/smart_shopping/smart_shopping_screen.dart';
import 'package:homestock/features/shopping/shopping_controller.dart';
import '../barcode_models.dart';
import '../barcode_repository.dart';
import '../barcode_scan_controller.dart';
import 'add_product_manually_sheet.dart';

class BarcodeResultBottomSheet extends ConsumerStatefulWidget {
  final BarcodeLookupResult result;
  final VoidCallback onDismissed;

  const BarcodeResultBottomSheet({
    super.key,
    required this.result,
    required this.onDismissed,
  });

  static Future<void> show(
    BuildContext context,
    BarcodeLookupResult result, {
    required VoidCallback onDismissed,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BarcodeResultBottomSheet(
        result: result,
        onDismissed: onDismissed,
      ),
    ).whenComplete(onDismissed);
  }

  @override
  ConsumerState<BarcodeResultBottomSheet> createState() => _BarcodeResultBottomSheetState();
}

class _BarcodeResultBottomSheetState extends ConsumerState<BarcodeResultBottomSheet> {
  late BarcodeLookupResult _currentResult;
  double _stockInQuantity = 1.0;
  double _initialQuantity = 1.0;
  double _minQuantity = 1.0;
  DateTime? _selectedExpiryDate;
  String? _storageLocation;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _currentResult = widget.result;
  }

  Future<void> _handleAddToShoppingList({
    required String homeId,
    required String itemName,
    required double quantity,
    required String unit,
    String? categoryId,
    String? categoryName,
    String? inventoryItemId,
    ProductCatalogModel? product,
  }) async {
    final existingShop = _currentResult.existingShopping;
    if (existingShop != null) {
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Already on Shopping List', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: Text(
            '$itemName is already on your shopping list (${existingShop.quantity.toInt()} ${existingShop.unit}).\n\nWould you like to increase its quantity by ${quantity.toInt()} $unit or keep as is?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('cancel'),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('keep'),
              child: const Text('Keep As Is'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop('increase'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Increase Quantity'),
            ),
          ],
        ),
      );

      if (choice == 'increase') {
        final newQty = existingShop.quantity + quantity;
        await ref.read(shoppingControllerProvider.notifier).updateQuantity(existingShop.id, newQty);
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✓ Updated $itemName quantity to ${newQty.toInt()} ${existingShop.unit}')),
          );
        }
      } else if (choice == 'keep') {
        if (mounted) Navigator.of(context).pop();
      }
      return;
    }

    // Not on shopping list: Add new item
    if (product != null) {
      await ref.read(barcodeRepositoryProvider).addToShoppingList(
            homeId: homeId,
            product: product,
            quantity: quantity,
            inventoryItemId: inventoryItemId,
          );
    } else {
      await ref.read(shoppingControllerProvider.notifier).addItem(
            itemName: itemName,
            quantity: quantity,
            unit: unit,
            categoryId: categoryId,
            categoryName: categoryName,
            inventoryItemId: inventoryItemId,
          );
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✓ Added $itemName to shopping list')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _currentResult;
    final homeId = ref.watch(homeControllerProvider).activeHome?.id ?? '';
    final hasExistingInventory = result.existingInventory != null;
    final hasExistingShopping = result.existingShopping != null;

    final scanState = ref.watch(barcodeScanControllerProvider);
    final targetShoppingItem = scanState.targetShoppingItem;
    final packageSizeMismatch = scanState.packageSizeMismatch;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Barcode pill & Status Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(color: AppColors.outline),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.qr_code_2_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        '${result.barcodeType}: ${result.barcode}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (hasExistingInventory)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: const Text(
                      'In Inventory',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary),
                    ),
                  )
                else if (result.found)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: const Text(
                      'Product Found',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Package Size Mismatch Warning Banner (when matching a target shopping item)
            if (packageSizeMismatch && targetShoppingItem != null && result.product != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: const Color(0xFFF59E0B)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 24),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Package Size Mismatch',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF92400E)),
                          ),
                          Text(
                            'Shopping list requested ${targetShoppingItem.quantity.toStringAsFixed(targetShoppingItem.quantity.truncateToDouble() == targetShoppingItem.quantity ? 0 : 1)} ${targetShoppingItem.unit}, but scanned product is ${result.product!.packageSize ?? ''} ${result.product!.unit}.',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF78350F)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Product Header
            if (result.found && result.product != null)
              _buildProductHeader(result.product!)
            else
              _buildUnknownProductHeader(result.barcode),

            const SizedBox(height: AppSpacing.lg),

            // Case 1: Product already in household inventory
            if (hasExistingInventory) ...[
              _buildExistingInventorySection(result.existingInventory!, homeId),
            ]
            // Case 2: Known product, but not yet in inventory
            else if (result.found && result.product != null) ...[
              _buildNewProductSection(result.product!, homeId),
            ]
            // Case 3: Completely unknown barcode
            else ...[
              _buildUnknownBarcodeActions(result.barcode, result.barcodeType),
            ],

            // Shopping List Banner if item is currently on list
            if (hasExistingShopping) ...[
              const SizedBox(height: AppSpacing.md),
              _buildExistingShoppingBanner(result.existingShopping!, homeId),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductHeader(ProductCatalogModel product) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            width: 64,
            height: 64,
            color: AppColors.background,
            child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                ? Image.network(
                    product.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 32),
                  )
                : const Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 32),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                [
                  if (product.brand != null && product.brand!.isNotEmpty) product.brand,
                  if (product.packageSize != null) '${product.packageSize} ${product.unit}',
                  product.categoryName,
                ].whereType<String>().join(' • '),
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUnknownProductHeader(String barcode) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          const Icon(Icons.help_outline_rounded, color: AppColors.textSecondary, size: 36),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Product Not Found',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                Text(
                  'Barcode $barcode is not in the catalog yet. Add it manually to save it offline and online.',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExistingInventorySection(ExistingInventoryContext item, String homeId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.secondaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.secondary, size: 28),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Already in your home pantry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(
                      'Current stock: ${item.currentQuantity.toStringAsFixed(item.currentQuantity.truncateToDouble() == item.currentQuantity ? 0 : 1)} ${item.unit}${item.storageLocation != null ? ' • ${item.storageLocation}' : ''}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Quick Stock-In Stepper
        Row(
          children: [
            const Expanded(
              child: Text(
                'Quantity to add:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
            IconButton.outlined(
              icon: const Icon(Icons.remove, size: 18),
              onPressed: _stockInQuantity > 1 ? () => setState(() => _stockInQuantity -= 1) : null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '${_stockInQuantity.toInt()} ${item.unit}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton.outlined(
              icon: const Icon(Icons.add, size: 18),
              onPressed: () => setState(() => _stockInQuantity += 1),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Primary Action: Restock (+N)
        ElevatedButton.icon(
          onPressed: _isSubmitting
              ? null
              : () async {
                  setState(() => _isSubmitting = true);
                  final repo = ref.read(barcodeRepositoryProvider);
                  await repo.addOrUpdateInventory(
                    homeId: homeId,
                    barcode: _currentResult.barcode,
                    quantity: _stockInQuantity,
                    existingItemId: item.id,
                  );
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('✓ Restocked ${_stockInQuantity.toInt()} ${item.unit} to pantry')),
                    );
                  }
                },
          icon: const Icon(Icons.add_shopping_cart_rounded),
          label: Text('Restock (+${_stockInQuantity.toInt()} ${item.unit})'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Secondary Actions: Add to Shopping List & View Item
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _handleAddToShoppingList(
                  homeId: homeId,
                  itemName: item.name,
                  quantity: _stockInQuantity,
                  unit: item.unit,
                  inventoryItemId: item.id,
                  product: _currentResult.product,
                ),
                icon: const Icon(Icons.playlist_add_rounded, size: 18),
                label: const Text('Shopping List', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ItemDetailScreen(itemId: item.id),
                    ),
                  );
                },
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text('View Item', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),

        // Compare Prices Online
        TextButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SmartShoppingScreen(
                  itemId: item.id,
                  inventoryItemId: item.id,
                  itemName: item.name,
                  quantity: _stockInQuantity,
                  unit: item.unit,
                ),
              ),
            );
          },
          icon: const Icon(Icons.compare_arrows_rounded, size: 16, color: AppColors.primary),
          label: const Text('Compare Online Deals', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildNewProductSection(ProductCatalogModel product, String homeId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Quantity & Min Quantity Pickers
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quantity', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      IconButton.outlined(
                        icon: const Icon(Icons.remove, size: 16),
                        onPressed: _initialQuantity > 1 ? () => setState(() => _initialQuantity -= 1) : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text('${_initialQuantity.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      IconButton.outlined(
                        icon: const Icon(Icons.add, size: 16),
                        onPressed: () => setState(() => _initialQuantity += 1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Min Alert Qty', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      IconButton.outlined(
                        icon: const Icon(Icons.remove, size: 16),
                        onPressed: _minQuantity > 1 ? () => setState(() => _minQuantity -= 1) : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text('${_minQuantity.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      IconButton.outlined(
                        icon: const Icon(Icons.add, size: 16),
                        onPressed: () => setState(() => _minQuantity += 1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Optional Expiry Date Picker
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now().add(const Duration(days: 30)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
            );
            if (picked != null) setState(() => _selectedExpiryDate = picked);
          },
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.outline),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  _selectedExpiryDate != null
                      ? 'Expiry: ${_selectedExpiryDate!.toIso8601String().substring(0, 10)}'
                      : 'Add Expiry Date (Optional)',
                  style: TextStyle(
                    fontSize: 13,
                    color: _selectedExpiryDate != null ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Action: Add to Inventory
        ElevatedButton.icon(
          onPressed: _isSubmitting
              ? null
              : () async {
                  setState(() => _isSubmitting = true);
                  final repo = ref.read(barcodeRepositoryProvider);
                  await repo.addOrUpdateInventory(
                    homeId: homeId,
                    barcode: _currentResult.barcode,
                    quantity: _initialQuantity,
                    minQty: _minQuantity,
                    product: product,
                    expiryDate: _selectedExpiryDate?.toIso8601String().substring(0, 10),
                    location: _storageLocation,
                  );
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('✓ ${product.name} added to pantry')),
                    );
                  }
                },
          icon: const Icon(Icons.inventory_rounded),
          label: const Text('Add to Inventory'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Two-column Secondary Actions: Shopping List & Price Compare
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _handleAddToShoppingList(
                  homeId: homeId,
                  itemName: product.name,
                  quantity: _initialQuantity,
                  unit: product.unit,
                  product: product,
                ),
                icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                label: const Text('Shopping List', style: TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SmartShoppingScreen(
                        itemId: _currentResult.barcode,
                        itemName: product.name,
                        quantity: _initialQuantity,
                        unit: product.unit,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.compare_arrows_rounded, size: 16),
                label: const Text('Compare Prices', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUnknownBarcodeActions(String barcode, String barcodeType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primary: Add Product Manually (Saves to Catalog & immediately reveals restock actions)
        ElevatedButton.icon(
          onPressed: () async {
            final newProduct = await AddProductManuallySheet.show(
              context,
              initialBarcode: barcode,
              initialBarcodeType: barcodeType,
            );

            if (newProduct != null && mounted) {
              setState(() {
                _currentResult = BarcodeLookupResult(
                  found: true,
                  barcode: newProduct.barcode,
                  barcodeType: newProduct.barcodeType,
                  product: newProduct,
                  isFromLocalCache: true,
                );
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('✓ Saved ${newProduct.name} to catalog! Configure stock below.')),
              );
            }
          },
          icon: const Icon(Icons.playlist_add_rounded),
          label: const Text('Add Product to Catalog'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Secondary: Custom Inventory Item form
        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AddEditItemScreen(
                  initialBarcode: barcode,
                ),
              ),
            );
          },
          icon: const Icon(Icons.tune_rounded, size: 18),
          label: const Text('Open Full Item Editor', style: TextStyle(fontSize: 12)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
          ),
        ),
      ],
    );
  }

  Widget _buildExistingShoppingBanner(ExistingShoppingContext shopItem, String homeId) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'On your shopping list (${shopItem.quantity.toInt()} ${shopItem.unit})',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(shoppingControllerProvider.notifier).toggleItem(shopItem.id);
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✓ Marked item as purchased on shopping list')),
                );
              }
            },
            child: const Text('Mark Purchased', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
