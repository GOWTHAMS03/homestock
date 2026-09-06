import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../shopping/shopping_controller.dart';
import 'dashboard_controller.dart';
import 'dashboard_model.dart';

class WhatDoINeedSheet extends ConsumerWidget {
  const WhatDoINeedSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardControllerProvider);
    final recs = dashboardState.recommendations;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lightbulb_outline_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What Do I Need?',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Smart restock suggestions based on current stock levels',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            if (recs == null)
              const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SkeletonItemCard(),
                  SizedBox(height: AppSpacing.sm),
                  SkeletonItemCard(),
                ],
              )
            else if (recs.urgent.isEmpty && recs.soon.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text(
                    "You're all stocked up! Nothing urgently needed right now 🎉",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    if (recs.urgent.isNotEmpty) ...[
                      const Text(
                        'URGENT RESTOCK',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.outOfStockText,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      ...recs.urgent.map((item) => _buildItemTile(context, ref, item, isUrgent: true)),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    if (recs.soon.isNotEmpty) ...[
                      const Text(
                        'RESTOCK SOON',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.lowStockText,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      ...recs.soon.map((item) => _buildItemTile(context, ref, item, isUrgent: false)),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemTile(BuildContext context, WidgetRef ref, RecommendationModel item, {required bool isUrgent}) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        side: BorderSide(
          color: isUrgent ? AppColors.outOfStockBorder : AppColors.lowStockBorder,
        ),
      ),
      child: ListTile(
        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(
          '${item.rationale} • Need ~${item.recommendedQuantity.toStringAsFixed(1)} ${item.unit}',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.add_shopping_cart_rounded, color: AppColors.primary, size: 20),
          tooltip: 'Add to Shopping List',
          onPressed: () async {
            await ref.read(shoppingControllerProvider.notifier).addItem(
                  inventoryItemId: item.itemId,
                  itemName: item.name,
                  quantity: item.recommendedQuantity,
                  unit: item.unit,
                );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${item.name} added to shopping list!'),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
