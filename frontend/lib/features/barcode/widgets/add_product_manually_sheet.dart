import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:homestock/core/constants/app_colors.dart';
import 'package:homestock/core/constants/app_spacing.dart';
import 'package:homestock/features/inventory/inventory_controller.dart';
import '../barcode_models.dart';
import '../barcode_repository.dart';

class AddProductManuallySheet extends ConsumerStatefulWidget {
  final String initialBarcode;
  final String? initialBarcodeType;

  const AddProductManuallySheet({
    super.key,
    required this.initialBarcode,
    this.initialBarcodeType,
  });

  static Future<ProductCatalogModel?> show(
    BuildContext context, {
    required String initialBarcode,
    String? initialBarcodeType,
  }) {
    return showModalBottomSheet<ProductCatalogModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddProductManuallySheet(
        initialBarcode: initialBarcode,
        initialBarcodeType: initialBarcodeType,
      ),
    );
  }

  @override
  ConsumerState<AddProductManuallySheet> createState() => _AddProductManuallySheetState();
}

class _AddProductManuallySheetState extends ConsumerState<AddProductManuallySheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _barcodeController;
  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _packageSizeController;
  late final TextEditingController _descriptionController;

  String _selectedUnit = 'pcs';
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  bool _isSaving = false;

  final List<String> _units = ['pcs', 'g', 'kg', 'ml', 'L', 'pk', 'box', 'can', 'bottle'];

  @override
  void initState() {
    super.initState();
    _barcodeController = TextEditingController(text: widget.initialBarcode);
    _nameController = TextEditingController();
    _brandController = TextEditingController();
    _packageSizeController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _nameController.dispose();
    _brandController.dispose();
    _packageSizeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final barcode = _barcodeController.text.trim();
      final name = _nameController.text.trim();
      final brand = _brandController.text.trim();
      final pkgSizeStr = _packageSizeController.text.trim();
      final pkgSize = double.tryParse(pkgSizeStr);
      final desc = _descriptionController.text.trim();

      final newProduct = ProductCatalogModel(
        id: const Uuid().v4(),
        barcode: barcode,
        barcodeType: widget.initialBarcodeType ?? 'BARCODE',
        name: name,
        normalizedName: name.toLowerCase(),
        brand: brand.isNotEmpty ? brand : null,
        categoryId: _selectedCategoryId,
        categoryName: _selectedCategoryName ?? 'General',
        packageSize: pkgSize,
        unit: _selectedUnit,
        description: desc.isNotEmpty ? desc : null,
        source: 'MANUAL_ENTRY',
      );

      final repo = ref.read(barcodeRepositoryProvider);
      final saved = await repo.createProduct(newProduct);

      if (mounted) {
        Navigator.of(context).pop(saved);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save product: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(inventoryControllerProvider).categories;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
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

              // Title Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: const Icon(Icons.add_shopping_cart_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Product to Catalog',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        Text(
                          'Saves locally & globally for future instant scanning',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: AppSpacing.lg),

              // Barcode display (read-only)
              TextFormField(
                controller: _barcodeController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Barcode Number',
                  prefixIcon: const Icon(Icons.qr_code_2_rounded, size: 20),
                  suffixIcon: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.initialBarcodeType ?? 'EAN',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                    ),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                  filled: true,
                  fillColor: AppColors.background,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Product Name
              TextFormField(
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Product Name *',
                  hintText: 'e.g. Amul Salted Butter',
                  prefixIcon: const Icon(Icons.shopping_basket_outlined, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Product name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Brand
              TextFormField(
                controller: _brandController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Brand / Manufacturer',
                  hintText: 'e.g. Amul, Nestle, Britannia',
                  prefixIcon: const Icon(Icons.business_outlined, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Category Selector
              DropdownButtonFormField<String>(
                initialValue: _selectedCategoryId,
                decoration: InputDecoration(
                  labelText: 'Category',
                  prefixIcon: const Icon(Icons.category_outlined, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                ),
                items: categories.map((cat) {
                  return DropdownMenuItem<String>(
                    value: cat.id,
                    child: Text(cat.name),
                  );
                }).toList(),
                onChanged: (catId) {
                  setState(() {
                    _selectedCategoryId = catId;
                    _selectedCategoryName = categories
                        .firstWhere((c) => c.id == catId, orElse: () => categories.first)
                        .name;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Package Size & Unit
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _packageSizeController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Package Size',
                        hintText: 'e.g. 500, 1',
                        prefixIcon: const Icon(Icons.straighten_outlined, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedUnit,
                      decoration: InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                      ),
                      items: _units.map((u) {
                        return DropdownMenuItem<String>(
                          value: u,
                          child: Text(u),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedUnit = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Description (Optional)
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Description / Notes (Optional)',
                  prefixIcon: const Icon(Icons.notes_outlined, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Save & Continue Button
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _handleSave,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_rounded),
                label: Text(_isSaving ? 'Saving Product...' : 'Save Product to Catalog'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
