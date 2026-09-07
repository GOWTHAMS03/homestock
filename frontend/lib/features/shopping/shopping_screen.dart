import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/widgets/sync_status_bar.dart';
import '../purchase/add_purchase_screen.dart';
import 'add_shopping_item_dialog.dart';
import '../voice/widgets/voice_input_button.dart';
import '../voice/widgets/voice_bottom_sheet.dart';
import '../barcode/widgets/barcode_scanner_widget.dart';
import '../smart_shopping/smart_shopping_screen.dart';
import 'shopping_controller.dart';
import 'shopping_model.dart';

class ShoppingScreen extends ConsumerWidget {
  const ShoppingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shoppingState = ref.watch(shoppingControllerProvider);
    final list = shoppingState.list;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Shared Shopping List'),
        actions: [
          const VoiceInputButton(
            tooltip: 'Voice shopping command',
          ),
          if (list != null && list.completedCount > 0)
            TextButton(
              onPressed: () => ref.read(shoppingControllerProvider.notifier).clearCompleted(),
              child: const Text('Clear Checked', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: Column(
        children: [
          const SyncStatusBar(),
          Expanded(
            child: (shoppingState.isLoading && list == null)
                ? ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: 6,
                    separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) => const SkeletonItemCard(),
                  )
                : (list == null || list.items.isEmpty)
                    ? EmptyStateView(
                        icon: Icons.shopping_bag_outlined,
                        title: 'Your shopping list is empty',
                        message: "Looks like you're all set! Items running low in your inventory will also appear here automatically.",
                        actionLabel: 'Add Item',
                        onAction: () => _showAddShoppingItemMenu(context),
                      )
                    : RefreshIndicator(
                  onRefresh: () => ref.read(shoppingControllerProvider.notifier).loadShoppingList(),
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      // Quick CTA: Record Purchase Direct from Shopping List
                      if (list.pendingCount > 0)
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.receipt_long_rounded, color: AppColors.primary),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${list.pendingCount} item(s) to buy',
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                    ),
                                    const Text(
                                      'Record receipt to automatically restock your inventory',
                                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 38,
                                child: ElevatedButton(
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const AddPurchaseScreen()),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                                  ),
                                  child: const Text('Record', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: AppSpacing.lg),

                      // Pending Items (Checkbox with strike-through)
                      ...list.items.where((i) => !i.isCompleted).map((item) => _buildShoppingItemTile(context, ref, item)),

                      // Completed Items section
                      if (list.completedCount > 0) ...[
                        const SizedBox(height: AppSpacing.lg),
                        SectionHeader(
                          title: 'Purchased Items (${list.completedCount})',
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ...list.items.where((i) => i.isCompleted).map((item) => _buildShoppingItemTile(context, ref, item)),
                      ],
                    ],
                  ),
                ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const VoiceInputButton.floating(
            tooltip: 'Voice shopping command',
          ),
          const SizedBox(width: 12),
          FloatingActionButton.extended(
            heroTag: 'shopping_add_btn',
            onPressed: () => _showAddShoppingItemMenu(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Item', style: TextStyle(fontWeight: FontWeight.w700)),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildShoppingItemTile(BuildContext context, WidgetRef ref, ShoppingItemModel item) {
    return Dismissible(
      key: Key('shopping_item_${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.outOfStockBg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.outOfStockBorder),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Delete', style: TextStyle(color: AppColors.outOfStockText, fontWeight: FontWeight.w700, fontSize: 13)),
            SizedBox(width: 8),
            Icon(Icons.delete_outline_rounded, color: AppColors.outOfStockText, size: 20),
          ],
        ),
      ),
      onDismissed: (_) {
        ref.read(shoppingControllerProvider.notifier).deleteItem(item.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.itemName} removed from list'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Undo',
              textColor: Colors.white,
              onPressed: () {
                ref.read(shoppingControllerProvider.notifier).addItem(
                      inventoryItemId: item.inventoryItemId,
                      itemName: item.itemName,
                      categoryId: null,
                      quantity: item.quantity,
                      unit: item.unit,
                    );
              },
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: () => ref.read(shoppingControllerProvider.notifier).toggleItem(item.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                // 1-Tap Checkbox (48dp touch target)
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: Checkbox(
                      value: item.isCompleted,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      activeColor: AppColors.primary,
                      onChanged: (_) => ref.read(shoppingControllerProvider.notifier).toggleItem(item.id),
                    ),
                  ),
                ),

                // Item details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.itemName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                                color: item.isCompleted ? AppColors.textMuted : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (item.isAutoGenerated) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.lowStockBg,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.lowStockBorder, width: 0.6),
                              ),
                              child: const Text(
                                'Auto Low-Stock',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.lowStockText),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.isCompleted
                            ? 'Bought by ${item.completedByName ?? 'Family'}'
                            : 'Added by ${item.addedByName} • ${item.quantity == item.quantity.roundToDouble() ? item.quantity.toInt() : item.quantity} ${item.unit}',
                        style: TextStyle(
                          fontSize: 12,
                          color: item.isCompleted ? AppColors.inStockText : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Right side: Quantity tag + Compare button
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Text(
                        '${item.quantity == item.quantity.roundToDouble() ? item.quantity.toInt() : item.quantity} ${item.unit}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ),
                    if (!item.isCompleted)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: InkWell(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SmartShoppingScreen(
                                itemId: item.id,
                                inventoryItemId: item.inventoryItemId,
                                itemName: item.itemName,
                                quantity: item.quantity,
                                unit: item.unit,
                              ),
                            ),
                          ),
                          borderRadius: BorderRadius.circular(4),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.compare_arrows_rounded, size: 13, color: AppColors.primary),
                                SizedBox(width: 3),
                                Text(
                                  'Compare',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                // Delete IconButton with min 48dp target
                SizedBox(
                  width: 44,
                  height: 44,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                    onPressed: () => ref.read(shoppingControllerProvider.notifier).deleteItem(item.id),
                    tooltip: 'Remove',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddShoppingItemMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Add to Shopping List',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit_note_rounded, color: AppColors.primary),
                ),
                title: const Text('Add Manually', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Enter name, quantity, unit and urgency', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  showDialog(
                    context: context,
                    builder: (_) => const AddShoppingItemDialog(),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.secondary),
                ),
                title: const Text('Scan Barcode', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Scan grocery items to quickly add to shopping list', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  BarcodeScannerWidget.open(context);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.mic_rounded, color: Color(0xFF9333EA)),
                ),
                title: const Text('Voice Input', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Say e.g. "Add 2 litre cooking oil to shopping list"', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  VoiceBottomSheet.show(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
