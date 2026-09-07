import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/homestock/homestock_app_bar.dart';
import '../../core/widgets/homestock/homestock_card.dart';
import '../../core/widgets/homestock/homestock_pill_badge.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/stock_status_badge.dart';
import '../home_switcher/home_controller.dart';
import '../shopping/shopping_controller.dart';
import 'add_edit_item_screen.dart';
import 'inventory_controller.dart';
import 'inventory_model.dart';
import 'stock_update_dialog.dart';

class ItemDetailScreen extends ConsumerStatefulWidget {
  final String itemId;

  const ItemDetailScreen({super.key, required this.itemId});

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  InventoryItemModel? _item;
  List<StockTransactionModel> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final homeId = ref.read(homeControllerProvider).activeHome?.id;
    if (homeId == null) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(inventoryRepositoryProvider);
      final item = await repo.getItemById(homeId, widget.itemId);
      final transactions = await repo.getTransactions(homeId, widget.itemId);

      if (mounted) {
        setState(() {
          _item = item;
          _transactions = transactions;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openStockDialog(String type) {
    if (_item == null) return;
    showDialog(
      context: context,
      builder: (_) => StockUpdateDialog(
        item: _item!,
        transactionType: type,
        onConfirm: (qty, reason) async {
          final success = await ref
              .read(inventoryControllerProvider.notifier)
              .updateStock(_item!.id, type, qty, reason);
          if (success) _loadDetails();
          return success;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF6F7F9),
        appBar: HomeStockAppBar(title: 'Loading Item...'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final item = _item;
    if (item == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F7F9),
        appBar: const HomeStockAppBar(title: 'Item Not Found'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.textMuted),
              const SizedBox(height: AppSpacing.md),
              const Text('Item could not be loaded.'),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Go Back')),
            ],
          ),
        ),
      );
    }

    final isLow = item.isLowStock;
    final isOut = item.isOutOfStock;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: HomeStockAppBar(
        title: item.name,
        subtitle: item.brand != null && item.brand!.isNotEmpty
            ? '${item.brand} • ${item.categoryName}'
            : item.categoryName,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.textPrimary),
            tooltip: 'Edit Item',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => AddEditItemScreen(initialItem: item)),
              );
              _loadDetails();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.outOfStockText),
            tooltip: 'Archive Item',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Archive Item?'),
                  content: Text('Are you sure you want to remove ${item.name} from your inventory?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.outOfStockText),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Archive'),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                final homeId = ref.read(homeControllerProvider).activeHome?.id;
                if (homeId != null) {
                  await ref.read(inventoryRepositoryProvider).deleteItem(homeId, item.id);
                  ref.read(inventoryControllerProvider.notifier).loadData();
                  if (context.mounted) context.pop();
                }
              }
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Main Stock Hero Card
          HomeStockCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.outline.withValues(alpha: 0.7)),
                          ),
                          child: Icon(item.categoryIconData, size: 22, color: item.categoryColorParsed),
                        ),
                        const SizedBox(width: 10),
                        HomeStockPillBadge(
                          label: isOut ? 'Out of Stock' : (isLow ? 'Low Stock' : 'In Stock'),
                          variant: isOut
                              ? HomeStockPillVariant.pink
                              : (isLow ? HomeStockPillVariant.yellow : HomeStockPillVariant.green),
                        ),
                      ],
                    ),
                    if (item.expiryDate != null)
                      ExpiryUrgencyBadge(expiryDateStr: item.expiryDate),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  '${item.quantity == item.quantity.roundToDouble() ? item.quantity.toInt() : item.quantity} ${item.unit}',
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Alert when below ${item.minimumQuantity == item.minimumQuantity.roundToDouble() ? item.minimumQuantity.toInt() : item.minimumQuantity} ${item.unit}${item.maximumQuantity != null ? ' • Max: ${item.maximumQuantity == item.maximumQuantity!.roundToDouble() ? item.maximumQuantity!.toInt() : item.maximumQuantity} ${item.unit}' : ''}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Fast Action Buttons: Use Stock & Add Stock
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.remove_circle_outline_rounded, size: 18, color: AppColors.outOfStockText),
                          label: const Text('Use Stock', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.outOfStockText)),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: AppColors.outOfStockBg,
                            side: const BorderSide(color: AppColors.outOfStockBorder),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: item.quantity > 0 ? () => _openStockDialog('STOCK_OUT') : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 18, color: Colors.white),
                          label: const Text('Add Stock', style: TextStyle(fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => _openStockDialog('STOCK_IN'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                SizedBox(
                  height: 44,
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(shoppingControllerProvider.notifier).addItem(
                            inventoryItemId: item.id,
                            itemName: item.name,
                            quantity: item.minimumQuantity > 0 ? item.minimumQuantity : 1.0,
                            unit: item.unit,
                          );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${item.name} added to shopping list!'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                    label: const Text('Add to Shopping List', style: TextStyle(fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Metadata Grid inside HomeStockCard with dotted dividers
          const SectionHeader(title: 'Item Details'),
          const SizedBox(height: AppSpacing.sm),
          HomeStockCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDetailRow('Category', item.categoryName),
                const HomeStockDottedDivider(height: 16),
                _buildDetailRow('Brand', item.brand ?? '—'),
                const HomeStockDottedDivider(height: 16),
                _buildDetailRow('Storage Location', item.storageLocation ?? '—'),
                const HomeStockDottedDivider(height: 16),
                _buildDetailRow('Last Purchase Price', item.purchasePrice != null ? '₹${item.purchasePrice!.toStringAsFixed(2)}' : '—'),
                if (item.notes != null && item.notes!.isNotEmpty) ...[
                  const HomeStockDottedDivider(height: 16),
                  _buildDetailRow('Notes', item.notes!),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Stock History Audit Trail
          SectionHeader(
            title: 'Stock History',
            subtitle: '${_transactions.length} record(s) logged',
          ),
          const SizedBox(height: AppSpacing.sm),

          if (_transactions.isEmpty)
            const HomeStockCard(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Center(
                child: Text('No stock changes recorded yet.', style: TextStyle(color: AppColors.textMuted)),
              ),
            )
          else
            ..._transactions.map((tx) {
              final isPositive = tx.quantityChange > 0 &&
                  tx.transactionType != 'STOCK_OUT' &&
                  tx.transactionType != 'EXPIRED' &&
                  tx.transactionType != 'DAMAGED';
              final sign = isPositive ? '+' : '';
              final changeColor = isPositive ? AppColors.inStockText : AppColors.outOfStockText;

              String humanType;
              switch (tx.transactionType) {
                case 'STOCK_IN':
                  humanType = 'Restocked';
                  break;
                case 'STOCK_OUT':
                  humanType = 'Used / Consumed';
                  break;
                case 'EXPIRED':
                  humanType = 'Expired';
                  break;
                case 'DAMAGED':
                  humanType = 'Damaged';
                  break;
                case 'ADJUSTMENT':
                  humanType = 'Audit Adjustment';
                  break;
                default:
                  humanType = tx.transactionType.replaceAll('_', ' ');
              }

              final dateFormatted = tx.createdAt.isNotEmpty
                  ? DateFormat('dd MMM, hh:mm a').format(DateTime.tryParse(tx.createdAt) ?? DateTime.now())
                  : '';

              return HomeStockCard(
                margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isPositive ? AppColors.inStockBg : AppColors.outOfStockBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isPositive ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                        size: 18,
                        color: changeColor,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            humanType,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
                          ),
                          Text(
                            '${tx.userName} • ${tx.reason ?? 'Direct update'} • $dateFormatted',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '$sign${tx.quantityChange == tx.quantityChange.roundToDouble() ? tx.quantityChange.toInt() : tx.quantityChange} ${tx.unit}',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: changeColor),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
      ],
    );
  }
}
