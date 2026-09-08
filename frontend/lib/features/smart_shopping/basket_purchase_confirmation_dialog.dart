import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../home_switcher/home_controller.dart';
import '../inventory/inventory_controller.dart';
import '../shopping/shopping_controller.dart';
import 'smart_shopping_controller.dart';
import 'smart_shopping_models.dart';

/// Modal bottom sheet to confirm completion of a multi-item basket purchase.
/// Allows verifying editable quantities and prices, then transactionally restocks
/// inventory, completes shopping list items, and updates consumption predictions.
class BasketPurchaseConfirmationDialog extends ConsumerStatefulWidget {
  final BasketOptionModel basketOption;
  final String? sessionId;

  const BasketPurchaseConfirmationDialog({
    super.key,
    required this.basketOption,
    this.sessionId,
  });

  static Future<bool?> show({
    required BuildContext context,
    required BasketOptionModel basketOption,
    String? sessionId,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (_) => BasketPurchaseConfirmationDialog(
        basketOption: basketOption,
        sessionId: sessionId,
      ),
    );
  }

  @override
  ConsumerState<BasketPurchaseConfirmationDialog> createState() =>
      _BasketPurchaseConfirmationDialogState();
}

class _BasketPurchaseConfirmationDialogState
    extends ConsumerState<BasketPurchaseConfirmationDialog> {
  late final List<TextEditingController> _priceControllers;
  late final List<TextEditingController> _qtyControllers;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _priceControllers = widget.basketOption.items.map((item) {
      return TextEditingController(text: item.price.toStringAsFixed(0));
    }).toList();

    _qtyControllers = widget.basketOption.items.map((item) {
      final q = item.quantity;
      return TextEditingController(
          text: q == q.roundToDouble() ? q.toInt().toString() : q.toString());
    }).toList();
  }

  @override
  void dispose() {
    for (final c in _priceControllers) {
      c.dispose();
    }
    for (final c in _qtyControllers) {
      c.dispose();
    }
    super.dispose();
  }

  double get _computedTotal {
    double total = widget.basketOption.deliveryFeesTotal;
    for (int i = 0; i < widget.basketOption.items.length; i++) {
      final p = double.tryParse(_priceControllers[i].text.trim()) ?? 0;
      final q = double.tryParse(_qtyControllers[i].text.trim()) ?? 1;
      total += p * q;
    }
    return total;
  }

  Future<void> _confirmPurchase() async {
    setState(() => _isSaving = true);

    final homeId = ref.read(homeControllerProvider).activeHome?.id ?? '';
    final itemsPayload = <Map<String, dynamic>>[];

    for (int i = 0; i < widget.basketOption.items.length; i++) {
      final item = widget.basketOption.items[i];
      final unitPrice = double.tryParse(_priceControllers[i].text.trim()) ?? item.price;
      final qty = double.tryParse(_qtyControllers[i].text.trim()) ?? item.quantity;
      final totalPrice = unitPrice * qty;

      itemsPayload.add({
        'shoppingListItemId': item.shoppingItemId,
        'itemName': item.itemName,
        'quantity': qty,
        'unit': item.unit,
        'unitPrice': unitPrice,
        'totalPrice': totalPrice,
        'provider': item.provider,
        'providerProductId': item.providerProductId,
      });
    }

    final payload = {
      'storeName': widget.basketOption.storeName,
      'totalAmount': _computedTotal,
      'notes': 'Smart Shopping ${widget.basketOption.title}',
      'items': itemsPayload,
    };

    bool success = false;
    final sessionId = widget.sessionId;

    if (sessionId != null && sessionId.isNotEmpty) {
      success = await ref.read(smartShoppingControllerProvider.notifier).completeSession(
        homeId,
        sessionId,
        payload,
      );
    } else {
      // Create session first or complete directly
      final session = await ref.read(smartShoppingControllerProvider.notifier).startSession(
        homeId,
        itemIds: widget.basketOption.items.map((i) => i.shoppingItemId).toList(),
        selectedProviders: widget.basketOption.storeName,
        estimatedTotal: _computedTotal,
        recommendedOption: widget.basketOption.optionType,
      );
      if (session != null) {
        success = await ref.read(smartShoppingControllerProvider.notifier).completeSession(
          homeId,
          session.id,
          payload,
        );
      }
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      // Refresh inventory and shopping list
      ref.read(inventoryControllerProvider.notifier).loadData();
      ref.read(shoppingControllerProvider.notifier).loadShoppingList();

      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Restocked ${widget.basketOption.items.length} items to pantry!'),
          backgroundColor: AppColors.primary,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to complete purchase. Please try again.'),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Record Restock (${widget.basketOption.storeName})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Confirm the quantities and prices paid. HomeStock will automatically restock your pantry and update consumption forecasts.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),

          // Items list
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: widget.basketOption.items.length,
              separatorBuilder: (context, index) => const Divider(height: 12),
              itemBuilder: (context, index) {
                final item = widget.basketOption.items[index];
                return Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.itemName,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${item.provider ?? ''} • ${item.unit}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Qty
                    SizedBox(
                      width: 55,
                      child: TextFormField(
                        controller: _qtyControllers[index],
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          border: OutlineInputBorder(),
                          labelText: 'Qty',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Price
                    SizedBox(
                      width: 75,
                      child: TextFormField(
                        controller: _priceControllers[index],
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          isDense: true,
                          prefixText: '₹',
                          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          border: OutlineInputBorder(),
                          labelText: 'Price',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: AppSpacing.md),
          // Total breakdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Est. Total (incl. delivery):', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                Text(
                  '₹${_computedTotal.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _confirmPurchase,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Confirm & Restock Pantry',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
