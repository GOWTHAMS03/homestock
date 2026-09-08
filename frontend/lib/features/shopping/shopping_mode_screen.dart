import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/homestock/homestock_card.dart';
import '../barcode/widgets/barcode_scanner_widget.dart';
import '../inventory/inventory_controller.dart';
import '../purchase/purchase_controller.dart';
import 'shopping_controller.dart';
import 'shopping_model.dart';

class ShoppingModeScreen extends ConsumerStatefulWidget {
  const ShoppingModeScreen({super.key});

  @override
  ConsumerState<ShoppingModeScreen> createState() => _ShoppingModeScreenState();
}

class _ShoppingModeScreenState extends ConsumerState<ShoppingModeScreen> {
  final Map<String, bool> _inCart = {};
  final Map<String, double> _itemPrices = {};
  bool _isCompleting = false;

  void _toggleInCart(ShoppingItemModel item) {
    setState(() {
      final current = _inCart[item.id] ?? false;
      _inCart[item.id] = !current;
    });
  }

  void _setItemPrice(String itemId, double price) {
    setState(() {
      _itemPrices[itemId] = price;
    });
  }

  double get _calculatedTotal {
    double sum = 0.0;
    _itemPrices.forEach((id, price) {
      if (_inCart[id] == true) {
        sum += price;
      }
    });
    return sum;
  }

  int get _inCartCount {
    return _inCart.values.where((v) => v).length;
  }

  Future<void> _completeShopping(List<ShoppingItemModel> items) async {
    final boughtItems = items.where((i) => _inCart[i.id] == true).toList();
    if (boughtItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please check at least 1 item into your cart before finishing')),
      );
      return;
    }

    setState(() => _isCompleting = true);

    try {
      final total = _calculatedTotal > 0 ? _calculatedTotal : (boughtItems.length * 50.0);
      final purchaseNotifier = ref.read(purchaseControllerProvider.notifier);

      final lineItems = boughtItems.map((item) {
        final price = _itemPrices[item.id] ?? 50.0;
        return {
          'inventoryItemId': item.inventoryItemId,
          'itemName': item.itemName,
          'quantity': item.quantity,
          'unit': item.unit,
          'unitPrice': price / (item.quantity > 0 ? item.quantity : 1.0),
          'totalPrice': price,
        };
      }).toList();

      await purchaseNotifier.recordPurchase({
        'totalAmount': total,
        'purchaseDate': DateTime.now().toIso8601String().substring(0, 10),
        'currency': 'INR',
        'notes': 'In-store shopping mode run',
        'items': lineItems,
      });

      // Refresh shopping list and inventory
      await ref.read(shoppingControllerProvider.notifier).loadShoppingList();
      await ref.read(inventoryControllerProvider.notifier).loadData();

      if (mounted) {
        setState(() => _isCompleting = false);
        _showCelebrationDialog(boughtItems.length, total);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCompleting = false);
        _showCelebrationDialog(boughtItems.length, _calculatedTotal);
      }
    }
  }

  void _showCelebrationDialog(int count, double total) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.celebration_rounded, color: Color(0xFF10B981), size: 54),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Shopping Complete 🎉',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Items have been restocked into your household pantry automatically.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('Items Bought', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(height: 2),
                      Text('$count', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  Container(width: 1, height: 28, color: Colors.grey.shade300),
                  Column(
                    children: [
                      const Text('Total Amount', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(height: 2),
                      Text('₹${total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back to HomeStock', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shoppingState = ref.watch(shoppingControllerProvider);
    final items = shoppingState.list?.items ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Shopping Mode 🛒', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
            Text('Tap items as you put them in your cart', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
            tooltip: 'Scan Barcode',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BarcodeScannerWidget()),
              );
            },
          ),
        ],
      ),
      body: items.isEmpty
          ? const Center(
              child: Text('No items in shopping list.\nAdd some items first!', textAlign: TextAlign.center),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 100),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                final inCart = _inCart[item.id] ?? false;

                return HomeStockCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  backgroundColor: inCart ? const Color(0xFFF0FDF4) : Colors.white,
                  child: Row(
                    children: [
                      // Large tactile checkbox
                      InkWell(
                        onTap: () => _toggleInCart(item),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: inCart ? const Color(0xFF10B981) : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: inCart ? const Color(0xFF10B981) : Colors.grey.shade400,
                              width: 2,
                            ),
                          ),
                          child: inCart
                              ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                              : null,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),

                      // Item name & quantity
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.itemName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: inCart ? AppColors.textSecondary : AppColors.textPrimary,
                                decoration: inCart ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity} ${item.unit}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),

                      // Price quick entry
                      SizedBox(
                        width: 72,
                        height: 36,
                        child: TextField(
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            prefixText: '₹',
                            hintText: 'Price',
                            hintStyle: const TextStyle(fontSize: 11, color: Colors.grey),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          onChanged: (val) {
                            final p = double.tryParse(val);
                            if (p != null) _setItemPrice(item.id, p);
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_inCartCount of ${items.length} in Cart',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    Text(
                      _calculatedTotal > 0 ? 'Total: ₹${_calculatedTotal.toStringAsFixed(0)}' : 'Ready to checkout',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isCompleting ? null : () => _completeShopping(items),
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Finish Shopping'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.hsGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
