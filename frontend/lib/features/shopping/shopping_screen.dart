import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/homestock/homestock_app_bar.dart';
import '../../core/widgets/homestock/homestock_card.dart';
import '../../core/widgets/homestock/homestock_pill_badge.dart';
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
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: HomeStockAppBar(
        title: 'Shared Shopping List',
        subtitle: '${list?.pendingCount ?? 0} item(s) to buy',
        showBackButton: false,
        actions: [
          const VoiceInputButton(
            tooltip: 'Voice shopping command',
          ),
          if (list != null && list.completedCount > 0)
            TextButton(
              onPressed: () => ref.read(shoppingControllerProvider.notifier).clearCompleted(),
              child: const Text('Clear Done', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
            ),
          const SizedBox(width: 8),
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
                              HomeStockCard(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: AppColors.hsGreenBg,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppColors.hsGreen.withValues(alpha: 0.3)),
                                      ),
                                      child: const Icon(Icons.receipt_long_rounded, color: AppColors.hsGreen, size: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                '${list.pendingCount} item(s) to buy',
                                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textPrimary),
                                              ),
                                              const SizedBox(width: 6),
                                              const HomeStockPillBadge(
                                                label: '✓ Restock',
                                                variant: HomeStockPillVariant.green,
                                                fontSize: 9,
                                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          const Text(
                                            'Record receipt to automatically update inventory',
                                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => const AddPurchaseScreen()),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        minimumSize: Size.zero,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                                      ),
                                      child: const Text('Record', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: AppSpacing.md),

                            // Pending Items
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
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('Add Item', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
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
        margin: const EdgeInsets.only(bottom: 10),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFCA5A5)),
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
      child: HomeStockCard(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        onTap: () => ref.read(shoppingControllerProvider.notifier).toggleItem(item.id),
        child: Row(
          children: [
            // Circular Check Indicator
            InkWell(
              onTap: () => ref.read(shoppingControllerProvider.notifier).toggleItem(item.id),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.isCompleted ? AppColors.hsGreen : Colors.white,
                  border: Border.all(
                    color: item.isCompleted ? AppColors.hsGreen : AppColors.outline.withValues(alpha: 0.9),
                    width: 1.5,
                  ),
                ),
                child: item.isCompleted
                    ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 12),

            // Item Details
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
                            fontWeight: FontWeight.w700,
                            decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                            color: item.isCompleted ? AppColors.textMuted : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (item.isAutoGenerated) ...[
                        const SizedBox(width: 6),
                        const HomeStockPillBadge(
                          label: 'Low-Stock',
                          variant: HomeStockPillVariant.yellow,
                          fontSize: 9,
                          padding: EdgeInsets.symmetric(horizontal: 5, vertical: 1),
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
                      fontSize: 11,
                      color: item.isCompleted ? AppColors.hsGreen : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Right side: Quantity pill + Compare action
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.outline.withValues(alpha: 0.6)),
                  ),
                  child: Text(
                    '${item.quantity == item.quantity.roundToDouble() ? item.quantity.toInt() : item.quantity} ${item.unit}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textPrimary),
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
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Delete action
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
              onPressed: () => ref.read(shoppingControllerProvider.notifier).deleteItem(item.id),
              tooltip: 'Remove',
            ),
          ],
        ),
      ),
    );
  }

  void _showAddShoppingItemMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Add to Shopping List',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_note_rounded, color: AppColors.primary),
                  ),
                  title: const Text('Add Manually', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Enter name, quantity, and unit', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    showDialog(
                      context: context,
                      builder: (_) => const AddShoppingItemDialog(),
                    );
                  },
                ),
                const HomeStockDottedDivider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.secondary),
                  ),
                  title: const Text('Scan Barcode', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Camera scan to add verified product', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    BarcodeScannerWidget.open(context);
                  },
                ),
                const HomeStockDottedDivider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.hsPurpleBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.mic_rounded, color: AppColors.hsPurple),
                  ),
                  title: const Text('Voice Input', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Say "Add 2 litre cooking oil to shopping list"', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    VoiceBottomSheet.show(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
