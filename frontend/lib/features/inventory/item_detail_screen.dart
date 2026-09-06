import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
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
          if (success) {
            _loadDetails();
          }
          return success;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_item == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Item not found')),
      );
    }

    final item = _item!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(item.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => AddEditItemScreen(initialItem: item)),
              );
              _loadDetails();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.outOfStockText),
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
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Main Stock Hero Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    StockStatusBadge.fromString(item.stockStatus),
                    if (item.expiryDate != null)
                      ExpiryUrgencyBadge(expiryDateStr: item.expiryDate),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
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

                // Fast Action Buttons: Use Stock & Add Stock (48dp height minimum)
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.remove_circle_outline_rounded, size: 18, color: AppColors.outOfStockText),
                          label: const Text('Use Stock', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.outOfStockText)),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: AppColors.outOfStockBg,
                            side: const BorderSide(color: AppColors.outOfStockBorder),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                          ),
                          onPressed: item.quantity > 0 ? () => _openStockDialog('STOCK_OUT') : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 18, color: Colors.white),
                          label: const Text('Add Stock', style: TextStyle(fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Metadata Grid
          const SectionHeader(title: 'Item Details'),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  _buildDetailRow('Category', item.categoryName),
                  const Divider(height: 16),
                  _buildDetailRow('Brand', item.brand ?? '—'),
                  const Divider(height: 16),
                  _buildDetailRow('Storage Location', item.storageLocation ?? '—'),
                  const Divider(height: 16),
                  _buildDetailRow('Last Purchase Price', item.purchasePrice != null ? '₹${item.purchasePrice!.toStringAsFixed(2)}' : '—'),
                  if (item.notes != null && item.notes!.isNotEmpty) ...[
                    const Divider(height: 16),
                    _buildDetailRow('Notes', item.notes!),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Stock History Audit Trail (Section 12)
          SectionHeader(
            title: 'Stock History',
            subtitle: '${_transactions.length} record(s) logged',
          ),
          const SizedBox(height: AppSpacing.sm),

          if (_transactions.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                child: Center(
                  child: Text('No stock changes recorded yet.', style: TextStyle(color: AppColors.textMuted)),
                ),
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

              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isPositive ? AppColors.inStockBg : AppColors.outOfStockBg,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
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
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
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
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}
