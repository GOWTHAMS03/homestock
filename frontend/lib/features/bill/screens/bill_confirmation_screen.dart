import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/homestock/homestock_app_bar.dart';
import '../../../core/widgets/homestock/homestock_card.dart';
import '../../../core/widgets/homestock/homestock_pill_badge.dart';
import '../controllers/bill_controller.dart';
import '../models/bill_models.dart';

class BillConfirmationScreen extends ConsumerStatefulWidget {
  const BillConfirmationScreen({super.key});

  @override
  ConsumerState<BillConfirmationScreen> createState() => _BillConfirmationScreenState();
}

class _BillConfirmationScreenState extends ConsumerState<BillConfirmationScreen> {
  late TextEditingController _shopNameController;
  late TextEditingController _billNumberController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(billScannerControllerProvider);
    _shopNameController = TextEditingController(text: state.shopName);
    _billNumberController = TextEditingController(text: state.billNumber);
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _billNumberController.dispose();
    super.dispose();
  }

  void _showEditItemDialog(int index, BillItemCandidateDto item) {
    final nameCtrl = TextEditingController(text: item.normalizedItemName);
    final qtyCtrl = TextEditingController(text: item.quantity.toString());
    final unitCtrl = TextEditingController(text: item.unit);
    final unitPriceCtrl = TextEditingController(text: item.unitPrice.toStringAsFixed(2));
    final finalPriceCtrl = TextEditingController(text: item.finalPrice.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Item Details', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Item Name', prefixIcon: Icon(Icons.shopping_bag_outlined)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: qtyCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Quantity'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: unitCtrl,
                      decoration: const InputDecoration(labelText: 'Unit (kg, g, l, pcs)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: unitPriceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Rate / Unit (Rs.)'),
                      onChanged: (val) {
                        final uPrice = double.tryParse(val) ?? 0.0;
                        final q = double.tryParse(qtyCtrl.text) ?? 1.0;
                        finalPriceCtrl.text = (uPrice * q).toStringAsFixed(2);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: finalPriceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Final Total (Rs.)'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () {
              final newQty = double.tryParse(qtyCtrl.text) ?? item.quantity;
              final newUnitPrice = double.tryParse(unitPriceCtrl.text) ?? item.unitPrice;
              final newFinalPrice = double.tryParse(finalPriceCtrl.text) ?? item.finalPrice;

              final updated = item.copyWith(
                normalizedItemName: nameCtrl.text.trim(),
                quantity: newQty,
                unit: unitCtrl.text.trim().toLowerCase(),
                unitPrice: newUnitPrice,
                finalPrice: newFinalPrice,
              );
              ref.read(billScannerControllerProvider.notifier).updateItem(index, updated);
              Navigator.pop(ctx);
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _showSuggestionSheet(int index, BillItemCandidateDto item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select Product Match for "${item.rawItemName}"',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Choose an existing product from inventory or create as a brand-new product.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ...item.suggestedMatches.map((m) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 20),
                ),
                title: Text(m.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Current Stock: ${m.currentStock} ${m.unit}  •  Confidence: ${(m.matchScore * 100).toInt()}%'),
                trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                onTap: () {
                  ref.read(billScannerControllerProvider.notifier).assignMatch(index, m);
                  Navigator.pop(ctx);
                },
              );
            }),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
                child: const Icon(Icons.add_circle_outline, color: AppColors.secondary, size: 20),
              ),
              title: const Text('Create as New Product', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Will register a new item in your household catalog'),
              onTap: () {
                ref.read(billScannerControllerProvider.notifier).setAsNewProduct(index, item.normalizedItemName);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmBill() async {
    final state = ref.read(billScannerControllerProvider);
    if (state.editableItems.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Restock & Save?'),
        content: Text(
          'This will restock ${state.editableItems.length} items in your household inventory, complete matched shopping list tasks, and record Rs. ${state.totalAmount.toStringAsFixed(2)} to spending history.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Review Again')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm & Restock'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final res = await ref.read(billScannerControllerProvider.notifier).confirmBill();
      if (res != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF059669),
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Bill #${res.billNumber ?? res.id.substring(0, 6)} confirmed! Inventory restocked.',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
        Navigator.of(context).pop(); // Back to scanner
        Navigator.of(context).pop(); // Back to caller screen
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(billScannerControllerProvider);
    final scanResult = state.scanResult;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: HomeStockAppBar(
        title: 'Review Bill & Inventory',
        subtitle: '${state.editableItems.length} items extracted • Rs. ${state.totalAmount.toStringAsFixed(2)}',
      ),
      body: Column(
        children: [
          // Top Metadata & Duplicate warning
          _buildHeaderSection(state, scanResult),

          // Items List
          Expanded(
            child: state.editableItems.isEmpty
                ? const Center(
                    child: Text('No items to confirm. Please add an item or scan another receipt.'),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 12),
                    itemCount: state.editableItems.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = state.editableItems[index];
                      return _buildItemCard(index, item);
                    },
                  ),
          ),

          // Bottom Action Bar
          _buildBottomBar(state),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(BillScannerState state, BillScanResponseDto? scanResult) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Duplicate Bill Warning Banner
          if (scanResult?.duplicateBillDetected == true) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Potential Duplicate: A receipt with this bill number has already been recorded in your household!',
                      style: TextStyle(color: Color(0xFF92400E), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _shopNameController,
                  decoration: const InputDecoration(
                    labelText: 'Store / Supermarket',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  ),
                  onChanged: (v) => ref.read(billScannerControllerProvider.notifier).updateShopName(v),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _billNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Bill #',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  ),
                  onChanged: (v) => ref.read(billScannerControllerProvider.notifier).updateBillNumber(v),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: state.billDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 1)),
                  );
                  if (picked != null) {
                    ref.read(billScannerControllerProvider.notifier).updateBillDate(picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        dateFormat.format(state.billDate),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(int index, BillItemCandidateDto item) {
    HomeStockPillVariant variant;
    String statusLabel;
    IconData statusIcon;

    if (item.matchStatus == 'AUTO_MATCHED') {
      variant = HomeStockPillVariant.green;
      statusLabel = 'Matched (${(item.matchConfidence).toInt()}%)';
      statusIcon = Icons.check_circle_outline;
    } else if (item.matchStatus == 'SUGGESTED_MATCH') {
      variant = HomeStockPillVariant.yellow;
      statusLabel = 'Suggestion (${(item.matchConfidence).toInt()}%)';
      statusIcon = Icons.help_outline;
    } else {
      variant = HomeStockPillVariant.purple;
      statusLabel = 'New Product';
      statusIcon = Icons.add_circle_outline;
    }

    return HomeStockCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.normalizedItemName,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    if (item.rawItemName != item.normalizedItemName) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Receipt text: "${item.rawItemName}"',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
              ),
              InkWell(
                onTap: () => _showSuggestionSheet(index, item),
                child: HomeStockPillBadge(
                  label: statusLabel,
                  icon: statusIcon,
                  variant: variant,
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                onPressed: () => ref.read(billScannerControllerProvider.notifier).removeItem(index),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Qty: ${item.quantity} ${item.unit}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              Text(
                '@ Rs. ${item.unitPrice.toStringAsFixed(2)} / ${item.unit}',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              Text(
                'Rs. ${item.finalPrice.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
          if (item.matchedShoppingListItemId != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.checklist, color: Color(0xFF059669), size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Matches shopping list (will restock & complete)',
                    style: TextStyle(color: Color(0xFF059669), fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.edit_outlined, size: 14, color: AppColors.primary),
              label: const Text('Edit quantity / rate', style: TextStyle(fontSize: 12, color: AppColors.primary)),
              onPressed: () => _showEditItemDialog(index, item),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BillScannerState state) {
    final matchedCount = state.editableItems
        .where((i) => i.matchStatus == 'AUTO_MATCHED')
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total (${state.editableItems.length} items)',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  Text(
                    'Rs. ${state.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  Text(
                    '$matchedCount matched • ${state.editableItems.length - matchedCount} new',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              icon: state.isConfirming
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle),
              label: Text(
                state.isConfirming ? 'Restocking...' : 'Confirm & Restock',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              onPressed: state.isConfirming || state.editableItems.isEmpty ? null : _confirmBill,
            ),
          ],
        ),
      ),
    );
  }
}
