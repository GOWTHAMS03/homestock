import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import 'inventory_model.dart';

class StockUpdateDialog extends StatefulWidget {
  final InventoryItemModel item;
  final String transactionType; // 'STOCK_OUT', 'STOCK_IN', 'ADJUSTMENT'
  final Future<bool> Function(double quantity, String? reason) onConfirm;

  const StockUpdateDialog({
    super.key,
    required this.item,
    required this.transactionType,
    required this.onConfirm,
  });

  @override
  State<StockUpdateDialog> createState() => _StockUpdateDialogState();
}

class _StockUpdateDialogState extends State<StockUpdateDialog> {
  final _qtyController = TextEditingController(text: '1.0');
  final _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _qtyController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final qty = double.tryParse(_qtyController.text);
    if (qty == null || qty <= 0) return;

    setState(() => _isLoading = true);
    final success = await widget.onConfirm(qty, _reasonController.text.trim().isEmpty ? null : _reasonController.text.trim());

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isStockOut = widget.transactionType == 'STOCK_OUT';
    final title = isStockOut ? 'How much did you use?' : 'Add Stock';
    final actionLabel = isStockOut ? 'Record Usage' : 'Add to Stock';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isStockOut ? AppColors.outOfStockBg : AppColors.inStockBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isStockOut ? Icons.remove_circle_outline_rounded : Icons.add_circle_outline_rounded,
                      color: isStockOut ? AppColors.outOfStockText : AppColors.inStockText,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        Text(
                          '${widget.item.name} (${widget.item.quantity} ${widget.item.unit} available)',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: AppTextField(
                      controller: _qtyController,
                      label: 'Quantity',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Required';
                        final num = double.tryParse(val);
                        if (num == null || num <= 0) return 'Must be > 0';
                        if (isStockOut && num > widget.item.quantity) {
                          return 'Exceeds stock (${widget.item.quantity})';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(color: AppColors.outline),
                        ),
                        child: Center(
                          child: Text(
                            widget.item.unit,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Quick preset chips
              Wrap(
                spacing: 8,
                children: [
                  ...[1, 2, 5].map((preset) => ActionChip(
                        label: Text('+$preset ${widget.item.unit}'),
                        backgroundColor: AppColors.chipBackground,
                        side: const BorderSide(color: AppColors.cardBorder),
                        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        onPressed: () {
                          final next = isStockOut ? (preset <= widget.item.quantity ? preset.toDouble() : widget.item.quantity) : preset.toDouble();
                          _qtyController.text = next.toString();
                        },
                      )),
                  if (isStockOut && widget.item.quantity > 0)
                    ActionChip(
                      label: const Text('All (Finish)'),
                      backgroundColor: AppColors.outOfStockBg,
                      side: const BorderSide(color: AppColors.outOfStockBorder),
                      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.outOfStockText),
                      onPressed: () {
                        _qtyController.text = widget.item.quantity.toString();
                      },
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              AppTextField(
                controller: _reasonController,
                label: 'Reason (Optional)',
                hint: isStockOut ? 'e.g. Dinner recipe, cooked' : 'e.g. Grocery trip, bought extra',
              ),
              const SizedBox(height: AppSpacing.xl),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(
                    width: 140,
                    child: AppButton(
                      label: actionLabel,
                      onPressed: _submit,
                      isLoading: _isLoading,
                      backgroundColor: isStockOut ? AppColors.outOfStockText : AppColors.primary,
                    ),
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
