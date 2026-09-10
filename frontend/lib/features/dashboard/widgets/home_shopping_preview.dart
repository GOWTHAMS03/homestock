import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../shopping/shopping_model.dart';

/// Shopping List Preview for the Home Page
///
/// Shows the top 3-4 items needing purchase with 1-tap check-off capability.
/// When empty, displays a reassuring "Shopping list is clear" state.
class HomeShoppingPreview extends StatelessWidget {
  final List<ShoppingItemModel> items;
  final ValueChanged<ShoppingItemModel> onToggleComplete;
  final VoidCallback onOpenShoppingList;
  final VoidCallback onQuickAdd;

  const HomeShoppingPreview({
    super.key,
    required this.items,
    required this.onToggleComplete,
    required this.onOpenShoppingList,
    required this.onQuickAdd,
  });

  @override
  Widget build(BuildContext context) {
    final pendingItems = items.where((i) => !i.isCompleted).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'Shopping List',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                if (pendingItems.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${pendingItems.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            InkWell(
              onTap: onOpenShoppingList,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View all',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.primary),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Body: Clean empty state or preview list
        if (pendingItems.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.outline.withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.shopping_bag_outlined, size: 18, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shopping list is clear',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 1),
                      Text(
                        'Nothing needs to be bought right now',
                        style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onQuickAdd,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppColors.primary,
                  ),
                  child: const Text('+ Add', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.outline.withValues(alpha: 0.6)),
            ),
            child: Column(
              children: [
                ...pendingItems.take(3).map((item) {
                  return InkWell(
                    onTap: () => onToggleComplete(item),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          // 1-Tap Checkbox touch target (min 48dp accessibility standard)
                          SizedBox(
                            width: AppSpacing.touchTargetMin,
                            height: AppSpacing.touchTargetMin,
                            child: Center(
                              child: Checkbox(
                                value: item.isCompleted,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                activeColor: AppColors.primary,
                                onChanged: (_) => onToggleComplete(item),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.itemName,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            item.quantity > 0
                                ? '${item.quantity == item.quantity.roundToDouble() ? item.quantity.toInt() : item.quantity.toStringAsFixed(1)} ${item.unit}'
                                : item.unit,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                if (pendingItems.length > 3)
                  InkWell(
                    onTap: onOpenShoppingList,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppSpacing.radiusLg)),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSubtle,
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppSpacing.radiusLg)),
                      ),
                      child: Center(
                        child: Text(
                          '+ ${pendingItems.length - 3} more items',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

