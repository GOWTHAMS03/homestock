import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:homestock/core/constants/app_colors.dart';
import 'package:homestock/core/constants/app_spacing.dart';
import 'package:homestock/features/purchase/add_purchase_screen.dart';
import 'package:homestock/features/barcode/barcode_scan_controller.dart';

class QuickScanSheet extends ConsumerWidget {
  const QuickScanSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(barcodeScanControllerProvider);
    final items = state.quickScanItems;

    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.75),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
        ),
        child: const Row(
          children: [
            Icon(Icons.shopping_cart_outlined, color: Colors.white70),
            SizedBox(width: 8),
            Text(
              'Quick Scan: Point at items to add to cart',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                const Icon(Icons.shopping_bag_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 6),
                Text(
                  'Scanned Items (${items.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => ref.read(barcodeScanControllerProvider.notifier).clearQuickScanSession(),
                  child: const Text('Clear All', style: TextStyle(fontSize: 12, color: AppColors.outOfStockText)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Running List
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              itemCount: items.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = items[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${item.barcode}${item.brand != null ? ' • ${item.brand}' : ''}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 18, color: AppColors.textSecondary),
                            onPressed: () => ref.read(barcodeScanControllerProvider.notifier).updateQuickScanQuantity(
                                  item.barcode,
                                  item.quantity - 1.0,
                                ),
                          ),
                          Text(
                            '${item.quantity.toInt()} ${item.unit}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, size: 18, color: AppColors.primary),
                            onPressed: () => ref.read(barcodeScanControllerProvider.notifier).updateQuickScanQuantity(
                                  item.barcode,
                                  item.quantity + 1.0,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Checkout CTA
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final scannedPayload = items
                      .map((i) => {
                            'inventoryItemId': i.existingInventoryItemId,
                            'name': i.name,
                            'quantity': i.quantity,
                            'unit': i.unit,
                            'unitPrice': i.unitPrice ?? 0.0,
                          })
                      .toList();

                  // Close scanner and open AddPurchaseScreen
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddPurchaseScreen(
                        initialScannedItems: scannedPayload,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.receipt_long_rounded),
                label: Text('Checkout & Restock (${items.length} Items)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
