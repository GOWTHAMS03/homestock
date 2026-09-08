import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/homestock/homestock_app_bar.dart';
import '../../core/widgets/homestock/homestock_card.dart';
import '../../core/widgets/homestock/homestock_pill_badge.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/widgets/sync_status_bar.dart';
import '../shopping/processed_products_screen.dart';
import 'add_purchase_screen.dart';
import 'purchase_controller.dart';
import 'purchase_model.dart';

class PurchasesScreen extends ConsumerWidget {
  const PurchasesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchaseState = ref.watch(purchaseControllerProvider);
    final purchases = purchaseState.purchases;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: HomeStockAppBar(
        title: 'Household Purchases',
        subtitle: '${purchases.length} receipts recorded & restocked',
      ),
      body: Column(
        children: [
          const SyncStatusBar(),
          Expanded(
            child: purchaseState.isLoading
                ? ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: 4,
                    separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) => const SkeletonItemCard(),
                  )
                : purchases.isEmpty
                    ? EmptyStateView(
                        icon: Icons.receipt_long_outlined,
                        title: 'No purchases recorded yet',
                        message: 'Record grocery receipts to track your household spending and automatically restock items.',
                        actionLabel: 'Record Purchase',
                        onAction: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AddPurchaseScreen()),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => ref.read(purchaseControllerProvider.notifier).loadPurchases(),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          itemCount: purchases.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final p = purchases[index];
                            return _buildPurchaseCard(context, p);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddPurchaseScreen()),
        ),
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text('Record Purchase', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      ),
    );
  }

  Widget _buildPurchaseCard(BuildContext context, PurchaseModel purchase) {
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a')
        .format(DateTime.tryParse(purchase.purchaseDate) ?? DateTime.now());

    return HomeStockCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProcessedProductsScreen(purchase: purchase),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Store Icon, Store Name, Date, Status Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.outline.withValues(alpha: 0.7)),
                    ),
                    child: const Icon(Icons.storefront_rounded, size: 22, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          purchase.storeName ?? 'Grocery Store',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$dateStr • ${purchase.recordedByName}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const HomeStockPillBadge(
                    label: '✓ Restocked',
                    variant: HomeStockPillVariant.green,
                    fontSize: 10,
                    padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const HomeStockDottedDivider(height: 14),
              const SizedBox(height: 8),

              // Items summary list
              Column(
                children: purchase.items.take(4).map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: AppColors.textMuted,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.itemName,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${item.quantity == item.quantity.roundToDouble() ? item.quantity.toInt() : item.quantity} ${item.unit}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        if (item.totalPrice > 0) ...[
                          const SizedBox(width: 12),
                          Text(
                            '₹${item.totalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),

              if (purchase.items.length > 4)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '+ ${purchase.items.length - 4} more items',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                  ),
                ),

              const SizedBox(height: 8),
              const HomeStockDottedDivider(height: 14),
              const SizedBox(height: 8),

              // Total Price & View link
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Text(
                        'View Added Products',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary),
                    ],
                  ),
                  Text(
                    '₹${purchase.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.primary),
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
