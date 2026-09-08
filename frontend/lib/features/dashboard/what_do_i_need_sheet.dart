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
    final qtyStr = item.recommendedQuantity == item.recommendedQuantity.roundToDouble()
        ? item.recommendedQuantity.toInt().toString()
        : item.recommendedQuantity.toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUrgent ? const Color(0xFFFECDD3) : const Color(0xFFFDE68A),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.name,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isUrgent ? const Color(0xFFFFF1F2) : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Buy ~$qtyStr ${item.unit}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isUrgent ? const Color(0xFFBE123C) : const Color(0xFFB45309),
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Icon(
                isUrgent ? Icons.error_outline_rounded : Icons.schedule_rounded,
                size: 13,
                color: isUrgent ? const Color(0xFFE11D48) : const Color(0xFFD97706),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item.rationale.isNotEmpty ? item.rationale : 'Predicted to run out soon based on household cycles',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.2),
                ),
              ),
            ],
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.add_shopping_cart_rounded, color: AppColors.primary, size: 22),
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
                  content: Text('Added "${item.name}" to your shopping list!'),
                  duration: const Duration(seconds: 2),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
