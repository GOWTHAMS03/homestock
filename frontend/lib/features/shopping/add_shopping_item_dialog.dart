import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../inventory/inventory_controller.dart';
import 'shopping_controller.dart';

class AddShoppingItemDialog extends ConsumerStatefulWidget {
  const AddShoppingItemDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddShoppingItemDialog(),
    );
  }

  @override
  ConsumerState<AddShoppingItemDialog> createState() => _AddShoppingItemDialogState();
}

class _AddShoppingItemDialogState extends ConsumerState<AddShoppingItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1.0');
  String _unit = 'pcs';
  String? _categoryId;
  String? _inventoryItemId;
  bool _isLoading = false;

  final List<String> _units = ['pcs', 'kg', 'g', 'L', 'ml', 'pack', 'bottle', 'can', 'box'];

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final success = await ref.read(shoppingControllerProvider.notifier).addItem(
          inventoryItemId: _inventoryItemId,
          itemName: _nameController.text.trim(),
          categoryId: _categoryId,
          quantity: double.tryParse(_quantityController.text) ?? 1.0,
          unit: _unit,
        );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final invState = ref.watch(inventoryControllerProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.md,
        bottom: bottomInset + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Shopping Item',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Autocomplete / Quick pick from existing household inventory
              if (invState.items.isNotEmpty) ...[
                DropdownButtonFormField<String?>(
                  decoration: const InputDecoration(
                    labelText: 'Pick from existing inventory (Optional)',
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Custom Item (not in inventory)')),
                    ...invState.items.map((i) => DropdownMenuItem<String?>(
                          value: i.id,
                          child: Text('${i.name} (Has ${i.quantity} ${i.unit})'),
                        )),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _inventoryItemId = val;
                      if (val != null) {
                        final picked = invState.items.firstWhere((i) => i.id == val);
                        _nameController.text = picked.name;
                        _unit = picked.unit;
                        _categoryId = picked.categoryId;
                      }
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              AppTextField(
                controller: _nameController,
                label: 'Item Name *',
                hint: 'e.g. Olive Oil, Milk, Eggs',
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Enter item name';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: AppTextField(
                      controller: _quantityController,
                      label: 'Quantity *',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Required';
                        final num = double.tryParse(val);
                        if (num == null || num <= 0) return 'Must be > 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Unit',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        DropdownButtonFormField<String>(
                          initialValue: _unit,
                          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
                          items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                          onChanged: (val) => setState(() => _unit = val ?? 'pcs'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              SizedBox(
                height: 48,
                child: AppButton(
                  label: 'Add to Shopping List',
                  onPressed: _submit,
                  isLoading: _isLoading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
