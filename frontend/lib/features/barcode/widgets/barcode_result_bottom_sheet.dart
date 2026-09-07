import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:homestock/core/constants/app_colors.dart';
import 'package:homestock/core/constants/app_spacing.dart';
import 'package:homestock/features/home_switcher/home_controller.dart';
import 'package:homestock/features/inventory/add_edit_item_screen.dart';
import 'package:homestock/features/smart_shopping/smart_shopping_screen.dart';
import 'package:homestock/features/shopping/shopping_controller.dart';
import '../barcode_models.dart';
import '../barcode_repository.dart';

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
  double _stockInQuantity = 1.0;
  double _initialQuantity = 1.0;
  double _minQuantity = 1.0;
  DateTime? _selectedExpiryDate;
  String? _storageLocation;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final homeId = ref.watch(homeControllerProvider).activeHome?.id ?? '';
    final hasExistingInventory = result.existingInventory != null;
    final hasExistingShopping = result.existingShopping != null;

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
              _buildUnknownBarcodeActions(result.barcode),
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
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 32),
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
                  'Barcode $barcode is not in the global catalog yet. You can add it manually to save it.',
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
                    const Text('Already in your home', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                'Add Stock:',
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

        // Action Buttons: + Add Stock, Compare Prices
        ElevatedButton.icon(
          onPressed: _isSubmitting
              ? null
              : () async {
                  setState(() => _isSubmitting = true);
                  final repo = ref.read(barcodeRepositoryProvider);
                  await repo.addOrUpdateInventory(
                    homeId: homeId,
                    barcode: widget.result.barcode,
                    quantity: _stockInQuantity,
                    existingItemId: item.id,
                  );
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('✓ Added ${_stockInQuantity.toInt()} ${item.unit} to stock')),
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

        OutlinedButton.icon(
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
          icon: const Icon(Icons.compare_arrows_rounded, color: AppColors.primary),
          label: const Text('Compare Online Prices', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
          ),
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
                    barcode: widget.result.barcode,
                    quantity: _initialQuantity,
                    minQty: _minQuantity,
                    product: product,
                    expiryDate: _selectedExpiryDate?.toIso8601String().substring(0, 10),
                    location: _storageLocation,
                  );
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('✓ ${product.name} added to inventory')),
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
                onPressed: () async {
                  final repo = ref.read(barcodeRepositoryProvider);
                  await repo.addToShoppingList(
                    homeId: homeId,
                    product: product,
                    quantity: _initialQuantity,
                  );
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('✓ ${product.name} added to shopping list')),
                    );
                  }
                },
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
                        itemId: widget.result.barcode,
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

  Widget _buildUnknownBarcodeActions(String barcode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
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
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Manually to Catalog & Inventory'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
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
