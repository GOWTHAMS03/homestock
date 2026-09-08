import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/homestock/homestock_app_bar.dart';
import '../../core/widgets/homestock/homestock_card.dart';
import '../inventory/inventory_controller.dart';
import '../inventory/inventory_model.dart';
import '../inventory/item_detail_screen.dart';
import '../purchase/purchase_model.dart';
import '../purchase/purchases_screen.dart';

/// Screen displayed after a shopping run or purchase process completes,
/// showing all added and restocked products, their updated quantities,
/// prices, and current pantry stock status.
class ProcessedProductsScreen extends ConsumerWidget {
  final PurchaseModel purchase;
  final bool isJustCompleted;
  final String? source;

  const ProcessedProductsScreen({
    super.key,
    required this.purchase,
    this.isJustCompleted = false,
    this.source,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invState = ref.watch(inventoryControllerProvider);
    final items = purchase.items;

    final dateStr = DateFormat('dd MMM yyyy, hh:mm a')
        .format(DateTime.tryParse(purchase.purchaseDate) ?? DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: HomeStockAppBar(
        title: 'Restocked Products',
        subtitle: '${items.length} items added to household pantry',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded, color: AppColors.primary),
            tooltip: 'All Receipts',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PurchasesScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // ─── 1. Success Celebration Banner ──────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF065F46), Color(0xFF047857), Color(0xFF10B981)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF059669).withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isJustCompleted
                                ? 'Process Completed! 🎉'
                                : 'Restock Record',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isJustCompleted
                                ? 'All products restocked to pantry & removed from shopping list.'
                                : 'Verified purchase and inventory restocking record.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.storefront_rounded, size: 16, color: Colors.white70),
                          const SizedBox(width: 6),
                          Text(
                            purchase.storeName ?? (source ?? 'In-store run'),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ─── 2. Metric KPI Cards ─────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Total Spent',
                  value: '₹${purchase.totalAmount.toStringAsFixed(0)}',
                  subtitle: '${purchase.currency} total',
                  icon: Icons.payments_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Products Added',
                  value: '${items.length}',
                  subtitle: 'Restocked in pantry',
                  icon: Icons.inventory_2_outlined,
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // ─── 3. Section Title ────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.format_list_bulleted_rounded, size: 18, color: AppColors.textPrimary),
                  SizedBox(width: 6),
                  Text(
                    'Added Products Breakdown',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.inStockBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.inStockBorder),
                ),
                child: Text(
                  '${items.length} Items',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inStockText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ─── 4. List of Added Products ───────────────────────────────────
          if (items.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No items recorded in this transaction.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ...items.map((item) {
              final matchedInvItem = _findMatchingInventoryItem(invState.items, item);
              return _buildProductCard(context, item, matchedInvItem);
            }),

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Shopping List'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to main inventory tab
                    context.go('/inventory');
                  },
                  icon: const Icon(Icons.inventory_2_rounded, size: 18),
                  label: const Text('View in Inventory'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InventoryItemModel? _findMatchingInventoryItem(
    List<InventoryItemModel> inventoryItems,
    PurchaseItemModel item,
  ) {
    if (item.inventoryItemId != null) {
      final direct = inventoryItems.where((i) => i.id == item.inventoryItemId);
      if (direct.isNotEmpty) return direct.first;
    }
    final normalized = item.itemName.toLowerCase().trim();
    final nameMatch = inventoryItems.where(
      (i) => i.name.toLowerCase().trim() == normalized,
    );
    if (nameMatch.isNotEmpty) return nameMatch.first;
    return null;
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return HomeStockCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    PurchaseItemModel item,
    InventoryItemModel? invItem,
  ) {
    final qtyStr = item.quantity == item.quantity.roundToDouble()
        ? item.quantity.toInt().toString()
        : item.quantity.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: invItem != null
              ? () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ItemDetailScreen(itemId: invItem.id),
                    ),
                  );
                }
              : null,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Icon(
                    Icons.shopping_bag_outlined,
                    size: 22,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),

                // Name & details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.itemName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Restocked badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: Text(
                              '+$qtyStr ${item.unit}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF047857),
                              ),
                            ),
                          ),
                          if (item.unitPrice > 0) ...[
                            const SizedBox(width: 8),
                            Text(
                              '₹${item.unitPrice.toStringAsFixed(0)}/${item.unit}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Current Pantry Balance
                      if (invItem != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              size: 13,
                              color: Color(0xFF10B981),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Pantry Balance: ${invItem.quantity == invItem.quantity.roundToDouble() ? invItem.quantity.toInt() : invItem.quantity} ${invItem.unit} (In Stock)',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF047857),
                              ),
                            ),
                          ],
                        )
                      else
                        const Row(
                          children: [
                            Icon(
                              Icons.sync_alt_rounded,
                              size: 13,
                              color: AppColors.textMuted,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Added to household stock',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                // Price & chevron
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${item.totalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                    if (invItem != null) ...[
                      const SizedBox(height: 6),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
