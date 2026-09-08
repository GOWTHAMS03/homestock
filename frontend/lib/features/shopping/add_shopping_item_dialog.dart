import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_text_field.dart';
import '../inventory/inventory_controller.dart';
import 'shopping_controller.dart';

class AddShoppingItemDialog extends ConsumerStatefulWidget {
  final String? prefillName;
  final String? prefillUnit;
  final String? prefillInventoryItemId;
  final String? prefillCategoryId;

  const AddShoppingItemDialog({
    super.key,
    this.prefillName,
    this.prefillUnit,
    this.prefillInventoryItemId,
    this.prefillCategoryId,
  });

  static Future<void> show(
    BuildContext context, {
    String? prefillName,
    String? prefillUnit,
    String? prefillInventoryItemId,
    String? prefillCategoryId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddShoppingItemDialog(
        prefillName: prefillName,
        prefillUnit: prefillUnit,
        prefillInventoryItemId: prefillInventoryItemId,
        prefillCategoryId: prefillCategoryId,
      ),
    );
  }

  @override
  ConsumerState<AddShoppingItemDialog> createState() => _AddShoppingItemDialogState();
}

class _AddShoppingItemDialogState extends ConsumerState<AddShoppingItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late String _unit;
  String? _categoryId;
  String? _inventoryItemId;
  bool _isLoading = false;

  final List<String> _units = ['pcs', 'kg', 'g', 'L', 'ml', 'pack', 'box', 'can', 'bottle'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.prefillName ?? '');
    _quantityController = TextEditingController(text: '1');
    _unit = widget.prefillUnit ?? 'pcs';
    _categoryId = widget.prefillCategoryId;
    _inventoryItemId = widget.prefillInventoryItemId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _adjustQuantity(double delta) {
    final current = double.tryParse(_quantityController.text) ?? 1.0;
    final next = (current + delta).clamp(0.5, 999.0);
    _quantityController.text = next == next.roundToDouble()
        ? next.toInt().toString()
        : next.toStringAsFixed(1);
    setState(() {});
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

    // Filter unique inventory items for quick suggestion chips
    final pantryItems = invState.items;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: bottomInset + 20,
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
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.outline.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Shopping Item',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Quick Pantry Pick Chips
              if (pantryItems.isNotEmpty) ...[
                const Text(
                  'Quick pick from pantry',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: pantryItems.length,
                    separatorBuilder: (_, i) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final item = pantryItems[index];
                      final isSelected = _inventoryItemId == item.id;
                      return ChoiceChip(
                        avatar: Icon(
                          item.categoryIconData,
                          size: 14,
                          color: isSelected ? Colors.white : AppColors.primary,
                        ),
                        label: Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: const Color(0xFFF8FAFC),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _inventoryItemId = item.id;
                              _nameController.text = item.name;
                              _unit = item.unit;
                              _categoryId = item.categoryId;
                            } else {
                              _inventoryItemId = null;
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Item Name Field
              AppTextField(
                controller: _nameController,
                label: 'Item Name *',
                hint: 'e.g. Fresh Milk, Sunflower Oil, Basmati Rice',
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter item name';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Quantity Stepper + Unit Selector
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stepper Quantity
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quantity *',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_rounded, size: 18),
                                color: AppColors.textPrimary,
                                onPressed: () => _adjustQuantity(-1.0),
                              ),
                              Expanded(
                                child: TextFormField(
                                  controller: _quantityController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) return 'Required';
                                    final num = double.tryParse(val);
                                    if (num == null || num <= 0) return '> 0';
                                    return null;
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_rounded, size: 18),
                                color: AppColors.primary,
                                onPressed: () => _adjustQuantity(1.0),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Unit Dropdown
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Unit',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _units.contains(_unit) ? _unit : _units.first,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textSecondary),
                              items: _units.map((u) {
                                return DropdownMenuItem<String>(
                                  value: u,
                                  child: Text(u, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _unit = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Submit CTA Button
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text(
                          '+ Add to Shopping List',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
