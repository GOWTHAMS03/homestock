import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../controllers/shop_owner_controller.dart';

class ShopAddProductScreen extends ConsumerStatefulWidget {
  final String? initialName;

  const ShopAddProductScreen({super.key, this.initialName});

  @override
  ConsumerState<ShopAddProductScreen> createState() => _ShopAddProductScreenState();
}

class _ShopAddProductScreenState extends ConsumerState<ShopAddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final _brandController = TextEditingController();
  final _packageSizeController = TextEditingController();
  final _priceController = TextEditingController();
  final _mrpController = TextEditingController();
  final _offerPriceController = TextEditingController();
  final _stockQtyController = TextEditingController();
  final _barcodeController = TextEditingController();

  String _unit = 'pcs';
  String _availabilityStatus = 'AVAILABLE';
  final List<String> _units = ['pcs', 'kg', 'g', 'l', 'ml', 'pack', 'bottle', 'can'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _packageSizeController.dispose();
    _priceController.dispose();
    _mrpController.dispose();
    _offerPriceController.dispose();
    _stockQtyController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final price = double.parse(_priceController.text.trim());
    final mrp = _mrpController.text.trim().isNotEmpty ? double.tryParse(_mrpController.text.trim()) : null;
    final offerPrice = _offerPriceController.text.trim().isNotEmpty ? double.tryParse(_offerPriceController.text.trim()) : null;
    final stockQty = _stockQtyController.text.trim().isNotEmpty ? double.tryParse(_stockQtyController.text.trim()) : null;

    final data = {
      'productName': _nameController.text.trim(),
      'brand': _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
      'packageSize': _packageSizeController.text.trim().isEmpty ? null : _packageSizeController.text.trim(),
      'unit': _unit,
      'price': price,
      'mrp': mrp,
      'offerPrice': offerPrice,
      'availabilityStatus': _availabilityStatus,
      'stockQuantity': stockQty,
      'stockVisibility': stockQty != null ? 'QUANTITY' : 'STATUS_ONLY',
      'barcode': _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
    };

    final success = await ref.read(shopOwnerControllerProvider.notifier).addProduct(data);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added successfully to your catalog!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shopOwnerControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product to Catalog'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Product Name & Brand
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name *',
                  hintText: 'e.g. Fortune Sunlite Sunflower Oil',
                  prefixIcon: Icon(Icons.shopping_bag_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Product name is required' : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _brandController,
                      decoration: const InputDecoration(labelText: 'Brand', hintText: 'e.g. Fortune', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextFormField(
                      controller: _packageSizeController,
                      decoration: const InputDecoration(labelText: 'Size / Pack', hintText: 'e.g. 1', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(
                    width: 90,
                    child: DropdownButtonFormField<String>(
                      value: _unit,
                      decoration: const InputDecoration(labelText: 'Unit', border: OutlineInputBorder()),
                      items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                      onChanged: (v) => setState(() => _unit = v ?? 'pcs'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Pricing Section
              const Text('Pricing & Discounts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Selling Price (₹) *',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || double.tryParse(v) == null ? 'Valid price required' : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextFormField(
                      controller: _mrpController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'MRP (₹) (Optional)',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _offerPriceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Promotional Offer Price (₹) (Optional)',
                  hintText: 'Special discount price for customer discovery',
                  prefixIcon: Icon(Icons.local_offer_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Inventory & Stock
              const Text('Inventory Availability', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                value: _availabilityStatus,
                decoration: const InputDecoration(labelText: 'Availability Status', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'AVAILABLE', child: Text('In Stock (Available for purchase)')),
                  DropdownMenuItem(value: 'LIMITED', child: Text('Low Stock (Limited items remaining)')),
                  DropdownMenuItem(value: 'OUT_OF_STOCK', child: Text('Out of Stock (Temporarily unavailable)')),
                ],
                onChanged: (v) => setState(() => _availabilityStatus = v ?? 'AVAILABLE'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _stockQtyController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Stock Quantity (Optional)',
                  hintText: 'e.g. 25',
                  prefixIcon: Icon(Icons.production_quantity_limits),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _barcodeController,
                decoration: const InputDecoration(
                  labelText: 'Barcode / EAN (Optional)',
                  hintText: 'Links to global product catalog',
                  prefixIcon: Icon(Icons.qr_code_scanner),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              if (state.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      state.errorMessage!,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

              ElevatedButton(
                onPressed: state.isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: state.isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Add Product to Catalog', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
