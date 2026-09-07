import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/homestock/homestock_app_bar.dart';
import '../../core/widgets/homestock/homestock_card.dart';
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

    final selectedCat = allCategories.firstWhere(
      (c) => c.id == _categoryId,
      orElse: () => CategoryModel(
        id: 'cat_general',
        homeId: homeId,
        name: 'General',
        icon: 'category',
        colorHex: '#64748B',
        displayOrder: 0,
      ),
    );

    final itemData = <String, dynamic>{
      'name': _nameController.text.trim(),
      'categoryId': selectedCat.id,
      'categoryName': selectedCat.name,
      'categoryColor': selectedCat.colorHex,
      'categoryIcon': selectedCat.icon,
      'quantity': double.tryParse(_quantityController.text) ?? 1.0,
      'unit': _unit,
      'minimumQuantity': double.tryParse(_minQtyController.text) ?? 1.0,
      'brand': _brandController.text.trim().isNotEmpty ? _brandController.text.trim() : null,
      'barcode': _barcodeController.text.trim().isNotEmpty ? _barcodeController.text.trim() : null,
      'storageLocation': _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
      'expiryDate': _expiryDate != null ? DateFormat('yyyy-MM-dd').format(_expiryDate!) : null,
      'purchasePrice': double.tryParse(_priceController.text),
      'notes': _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    };

    try {
      final success = widget.initialItem != null
          ? await ref.read(inventoryControllerProvider.notifier).updateItem(widget.initialItem!.id, itemData)
          : await ref.read(inventoryControllerProvider.notifier).createItem(itemData);

      if (success && mounted) {
        context.pop();
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
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: HomeStockAppBar(
        title: isEditing ? 'Edit Item' : 'Add Household Item',
        subtitle: isEditing ? 'Update pantry item specifications' : 'New pantry item record',
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // Card 1: Essential Item Info
            HomeStockCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Basic Information',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _nameController,
                    label: 'Item Name *',
                    hint: 'e.g. Sunflower Cooking Oil, Basmati Rice, Milk',
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Please enter an item name';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Category Dropdown
                  const Text(
                    'Category',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String?>(
                    initialValue: effectiveCategoryId,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.outline.withValues(alpha: 0.8)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.outline.withValues(alpha: 0.8)),
                      ),
                    ),
                    hint: const Text('Select category', style: TextStyle(fontSize: 13)),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('General / Uncategorized')),
                      ...categories.map((c) => DropdownMenuItem<String?>(
                            value: c.id,
                            child: Row(
                              children: [
                                Icon(c.iconData, size: 18, color: c.color),
                                const SizedBox(width: 8),
                                Text(c.name, style: const TextStyle(fontSize: 13)),
                              ],
                            ),
                          )),
                    ],
                    onChanged: (val) => setState(() => _categoryId = val),
                  ),
                  const SizedBox(height: AppSpacing.md),

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
                            if (num == null || num < 0) return 'Invalid';
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
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              initialValue: _unit,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppColors.outline.withValues(alpha: 0.8)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppColors.outline.withValues(alpha: 0.8)),
                                ),
                              ),
                              items: _commonUnits.map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontSize: 13)))).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _unit = val);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Min Alert Threshold
                  AppTextField(
                    controller: _minQtyController,
                    label: 'Low Stock Alert Threshold *',
                    hint: 'Minimum quantity before alert is triggered',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Required';
                      final num = double.tryParse(val);
                      if (num == null || num < 0) return 'Invalid';
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Card 2: Barcode
            HomeStockCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Barcode / GTIN',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _barcodeController,
                          label: 'Product Barcode (Optional)',
                          hint: 'e.g. 8901030000003',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(top: 22),
                        child: InkWell(
                          onTap: () => BarcodeScannerWidget.open(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 48,
                            width: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                            ),
                            child: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Card 3: Additional Details (Expandable)
            HomeStockCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => setState(() => _showMoreDetails = !_showMoreDetails),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Additional Details',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                        Row(
                          children: [
                            Text(
                              _showMoreDetails ? 'Hide' : 'Show',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                            ),
                            Icon(
                              _showMoreDetails ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (_showMoreDetails) ...[
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _brandController,
                      label: 'Brand',
                      hint: 'e.g. Tata, Aashirvaad, Amul, Fortune',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _locationController,
                      label: 'Storage Location',
                      hint: 'e.g. Kitchen Cabinet, Fridge Top Shelf, Pantry Box',
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Expiry Date Picker
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Expiry Date',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () async {
                            final now = DateTime.now();
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _expiryDate ?? now.add(const Duration(days: 30)),
                              firstDate: now.subtract(const Duration(days: 365)),
                              lastDate: now.add(const Duration(days: 365 * 5)),
                            );
                            if (picked != null) {
                              setState(() => _expiryDate = picked);
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.outline.withValues(alpha: 0.8)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _expiryDate != null
                                      ? DateFormat('dd MMM yyyy').format(_expiryDate!)
                                      : 'No expiry date set',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _expiryDate != null ? AppColors.textPrimary : AppColors.textMuted,
                                  ),
                                ),
                                Row(
                                  children: [
                                    if (_expiryDate != null)
                                      InkWell(
                                        onTap: () => setState(() => _expiryDate = null),
                                        child: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textMuted),
                                      ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textSecondary),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    AppTextField(
                      controller: _priceController,
                      label: 'Last Purchase Price (₹)',
                      hint: 'e.g. 120.00',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    AppTextField(
                      controller: _notesController,
                      label: 'Notes / Description',
                      hint: 'Special instructions or remarks',
                      maxLines: 2,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Submit Button
            SizedBox(
              height: 50,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        isEditing ? 'Save Changes' : 'Add Item to Pantry',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
