import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../home_switcher/home_controller.dart';
import '../barcode/widgets/barcode_scanner_widget.dart';
import 'category_model.dart';
import 'inventory_controller.dart';
import 'inventory_model.dart';

class AddEditItemScreen extends ConsumerStatefulWidget {
  final InventoryItemModel? initialItem;
  final String? initialBarcode;

  const AddEditItemScreen({super.key, this.initialItem, this.initialBarcode});

  @override
  ConsumerState<AddEditItemScreen> createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends ConsumerState<AddEditItemScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _minQtyController;
  late TextEditingController _brandController;
  late TextEditingController _barcodeController;
  late TextEditingController _locationController;
  late TextEditingController _priceController;
  late TextEditingController _notesController;

  String _unit = 'pcs';
  String? _categoryId;
  DateTime? _expiryDate;
  bool _showMoreDetails = false;
  bool _isLoading = false;

  final List<String> _commonUnits = ['pcs', 'kg', 'g', 'L', 'ml', 'pack', 'bottle', 'can', 'box'];

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    _nameController = TextEditingController(text: item?.name ?? '');
    _quantityController = TextEditingController(text: item != null ? item.quantity.toString() : '1.0');
    _minQtyController = TextEditingController(text: item != null ? item.minimumQuantity.toString() : '1.0');
    _brandController = TextEditingController(text: item?.brand ?? '');
    _barcodeController = TextEditingController(text: item?.barcode ?? widget.initialBarcode ?? '');
    _locationController = TextEditingController(text: item?.storageLocation ?? '');
    _priceController = TextEditingController(text: item?.purchasePrice != null ? item!.purchasePrice.toString() : '');
    _notesController = TextEditingController(text: item?.notes ?? '');
    _unit = item?.unit ?? 'pcs';
    _categoryId = item?.categoryId;

    if (item?.expiryDate != null) {
      _expiryDate = DateTime.tryParse(item!.expiryDate!);
    }
    if (item != null && (item.brand != null || item.storageLocation != null || item.expiryDate != null)) {
      _showMoreDetails = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _minQtyController.dispose();
    _brandController.dispose();
    _barcodeController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final homeId = ref.read(homeControllerProvider).activeHome?.id;
    if (homeId == null) return;

    setState(() => _isLoading = true);

    final homeState = ref.read(homeControllerProvider);
    final invState = ref.read(inventoryControllerProvider);
    final allCategories = invState.categories.isNotEmpty
        ? invState.categories
        : CategoryModel.defaultCategories(homeState.activeHome?.id);

    final selectedCat = allCategories.cast<CategoryModel?>().firstWhere(
      (c) => c?.id == _categoryId,
      orElse: () => null,
    );

    final data = {
      'name': _nameController.text.trim(),
      'categoryId': _categoryId,
      'categoryName': selectedCat?.name ?? (widget.initialItem?.categoryName ?? 'General'),
      'categoryIcon': selectedCat?.icon ?? (widget.initialItem?.categoryIcon ?? 'category'),
      'categoryColor': selectedCat?.colorHex ?? (widget.initialItem?.categoryColor ?? '#6366F1'),
      'quantity': double.tryParse(_quantityController.text) ?? 1.0,
      'unit': _unit,
      'minimumQuantity': double.tryParse(_minQtyController.text) ?? 1.0,
      'brand': _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
      'barcode': _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
      'storageLocation': _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      'purchasePrice': double.tryParse(_priceController.text),
      'expiryDate': _expiryDate != null ? DateFormat('yyyy-MM-dd').format(_expiryDate!) : null,
      'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    };

    try {
      final repo = ref.read(inventoryRepositoryProvider);
      if (widget.initialItem == null) {
        await repo.createItem(homeId, data);
      } else {
        await repo.updateItem(homeId, widget.initialItem!.id, data);
      }
      ref.read(inventoryControllerProvider.notifier).loadData();
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save item: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final invState = ref.watch(inventoryControllerProvider);
    final homeState = ref.watch(homeControllerProvider);
    final categories = invState.categories.isNotEmpty
        ? invState.categories
        : CategoryModel.defaultCategories(homeState.activeHome?.id);
    final isEditing = widget.initialItem != null;

    final categoryExists = categories.any((c) => c.id == _categoryId);
    final effectiveCategoryId = categoryExists
        ? _categoryId
        : categories.cast<CategoryModel?>().firstWhere(
            (c) => c?.name.toLowerCase() == widget.initialItem?.categoryName.toLowerCase(),
            orElse: () => null,
          )?.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Item' : 'Add Household Item'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // Core Mandatory Fields (Progressive Disclosure)
            AppTextField(
              controller: _nameController,
              label: 'Item Name *',
              hint: 'e.g. Sunflower Cooking Oil, Basmati Rice, Milk',
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Please enter an item name';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // Category Dropdown - Always populated offline and online
            const Text(
              'Category',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
            ),
            const SizedBox(height: AppSpacing.xs),
            DropdownButtonFormField<String?>(
              initialValue: effectiveCategoryId,
              decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
              hint: const Text('Select category'),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('General / Uncategorized')),
                ...categories.map((c) => DropdownMenuItem<String?>(
                      value: c.id,
                      child: Row(
                        children: [
                          Icon(c.iconData, size: 18, color: c.color),
                          const SizedBox(width: 8),
                          Text(c.name),
                        ],
                      ),
                    )),
              ],
              onChanged: (val) => setState(() => _categoryId = val),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Quantity & Unit
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: AppTextField(
                    controller: _quantityController,
                    label: 'Current Quantity *',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Required';
                      final num = double.tryParse(val);
                      if (num == null || num < 0) return 'Cannot be negative';
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
                        'Unit *',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      DropdownButtonFormField<String>(
                        initialValue: _unit,
                        decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                        items: _commonUnits.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                        onChanged: (val) => setState(() => _unit = val ?? 'pcs'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Minimum Quantity (Low Stock Alert threshold)
            AppTextField(
              controller: _minQtyController,
              label: 'Low Stock Alert Threshold *',
              hint: 'e.g. 1.0 (Auto-adds to shopping list when stock reaches this)',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Required';
                final num = double.tryParse(val);
                if (num == null || num < 0) return 'Cannot be negative';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.xl),

            // Progressive Disclosure Expander
            InkWell(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              onTap: () => setState(() => _showMoreDetails = !_showMoreDetails),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(
                      _showMoreDetails ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _showMoreDetails ? 'Hide additional details' : 'More Details (Brand, Location, Expiry, Notes)',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_showMoreDetails) ...[
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _brandController,
                label: 'Brand (Optional)',
                hint: 'e.g. Fortune, Aashirvaad, Dettol',
              ),
              const SizedBox(height: AppSpacing.lg),

              AppTextField(
                controller: _barcodeController,
                label: 'Barcode (Optional)',
                hint: 'e.g. 8901725181222',
                keyboardType: TextInputType.number,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
                  tooltip: 'Scan Barcode',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const BarcodeScannerWidget(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              AppTextField(
                controller: _locationController,
                label: 'Storage Location (Optional)',
                hint: 'e.g. Kitchen Pantry Shelf 2, Master Fridge, Bathroom Cabinet',
              ),
              const SizedBox(height: AppSpacing.lg),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _priceController,
                      label: 'Purchase Price (₹)',
                      hint: 'e.g. 150',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Expiry Date',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _expiryDate ?? DateTime.now().plusDays(30),
                              firstDate: DateTime.now().subtract(const Duration(days: 30)),
                              lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                            );
                            if (picked != null) setState(() => _expiryDate = picked);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              border: Border.all(color: AppColors.outline),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textSecondary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _expiryDate != null ? DateFormat('dd MMM yyyy').format(_expiryDate!) : 'Select Date',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _expiryDate != null ? AppColors.textPrimary : AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              AppTextField(
                controller: _notesController,
                label: 'Notes',
                hint: 'Additional household notes or dietary info',
                maxLines: 3,
              ),
            ],

            const SizedBox(height: AppSpacing.xxxl),
            AppButton(
              label: isEditing ? 'Update Item' : 'Add Item',
              onPressed: _submit,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}

extension DateTimeExtension on DateTime {
  DateTime plusDays(int days) => add(Duration(days: days));
}
