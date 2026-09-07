import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/widgets/sync_status_bar.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Household Purchases'),
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
                          separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
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
        icon: const Icon(Icons.add_rounded),
        label: const Text('Record Purchase', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildPurchaseCard(BuildContext context, PurchaseModel purchase) {
    final dateStr = DateFormat('dd MMM yyyy').format(DateTime.tryParse(purchase.purchaseDate) ?? DateTime.now());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: const Icon(Icons.storefront_rounded, size: 20, color: AppColors.primary),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          purchase.storeName ?? 'General Store',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        Text(
                          '$dateStr • by ${purchase.recordedByName}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  '₹${purchase.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Item summary pills
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: purchase.items.map((item) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    '${item.itemName} (${item.quantity} ${item.unit})',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
