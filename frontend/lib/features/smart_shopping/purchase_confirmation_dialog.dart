import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../inventory/inventory_controller.dart';
import '../purchase/purchase_controller.dart';
import '../shopping/shopping_controller.dart';
import 'smart_shopping_models.dart';

/// Modal bottom sheet that confirms whether user completed an online purchase
/// via affiliate link, and records it into HomeStock inventory & purchase history.
class PurchaseConfirmationDialog extends ConsumerStatefulWidget {
  final ProductOfferModel offer;
  final String shoppingItemId;
  final String? inventoryItemId;
  final String itemName;
  final double defaultQuantity;
  final String unit;

  const PurchaseConfirmationDialog({
    super.key,
    required this.offer,
    required this.shoppingItemId,
    this.inventoryItemId,
    required this.itemName,
    required this.defaultQuantity,
    required this.unit,
  });

  static Future<bool?> show({
    required BuildContext context,
    required ProductOfferModel offer,
    required String shoppingItemId,
    String? inventoryItemId,
    required String itemName,
    required double defaultQuantity,
    required String unit,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (_) => PurchaseConfirmationDialog(
        offer: offer,
        shoppingItemId: shoppingItemId,
        inventoryItemId: inventoryItemId,
        itemName: itemName,
        defaultQuantity: defaultQuantity,
        unit: unit,
      ),
    );
  }

  @override
  ConsumerState<PurchaseConfirmationDialog> createState() => _PurchaseConfirmationDialogState();
}

class _PurchaseConfirmationDialogState extends ConsumerState<PurchaseConfirmationDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _priceController;
  late final TextEditingController _qtyController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(
      text: widget.offer.effectivePrice.toStringAsFixed(0),
    );
    final formattedQty = widget.defaultQuantity == widget.defaultQuantity.roundToDouble()
        ? widget.defaultQuantity.toInt().toString()
        : widget.defaultQuantity.toString();
    _qtyController = TextEditingController(text: formattedQty);
  }

  @override
  void dispose() {
    _priceController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  Future<void> _confirmPurchase() async {
    if (!_formKey.currentState!.validate()) return;

    final unitPrice = double.tryParse(_priceController.text.trim()) ?? widget.offer.effectivePrice;
    final quantity = double.tryParse(_qtyController.text.trim()) ?? widget.defaultQuantity;
    final totalAmount = unitPrice * quantity;

    setState(() => _isSaving = true);

    final payload = {
      'storeId': null,
      'purchaseDate': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'totalAmount': totalAmount,
      'currency': widget.offer.currency,
      'notes': 'Online purchase from ${widget.offer.provider}',
      'items': [
        {
          'inventoryItemId': widget.inventoryItemId,
          'itemName': widget.offer.productName.isNotEmpty ? widget.offer.productName : widget.itemName,
          'quantity': quantity,
          'unit': widget.unit,
          'unitPrice': unitPrice,
          'totalPrice': totalAmount,
        }
      ],
    };

    final purchase = await ref.read(purchaseControllerProvider.notifier).recordPurchase(payload);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (purchase != null) {
      // Toggle/complete shopping item if still pending
      final shoppingList = ref.read(shoppingControllerProvider).list;
      if (shoppingList != null) {
        final item = shoppingList.items.where((i) => i.id == widget.shoppingItemId).firstOrNull;
        if (item != null && !item.isCompleted) {
          await ref.read(shoppingControllerProvider.notifier).toggleItem(widget.shoppingItemId);
        }
      }

      // Refresh inventory and shopping list
      ref.read(inventoryControllerProvider.notifier).loadData();
      ref.read(shoppingControllerProvider.notifier).loadShoppingList();

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to record purchase. Please try again.'),
          backgroundColor: AppColors.outOfStockText,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            const Row(
              children: [
                Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 22),
                SizedBox(width: AppSpacing.sm),
                Text(
                  'Did you buy this item?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${widget.offer.productName} • ${widget.offer.provider}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Price and Quantity Inputs
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Price Paid',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Enter price';
                      if (double.tryParse(val.trim()) == null) return 'Invalid';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _qtyController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Quantity',
                      suffixText: widget.unit,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Enter qty';
                      final num = double.tryParse(val.trim());
                      if (num == null || num <= 0) return '> 0';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                    ),
                    child: const Text('Not Yet', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _confirmPurchase,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text(
                      _isSaving ? 'Updating...' : 'Yes, Update Stock',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
