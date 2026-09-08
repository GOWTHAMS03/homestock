import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../inventory/inventory_controller.dart';
import '../purchase/purchase_controller.dart';
import '../shopping/shopping_controller.dart';

/// Modal bottom sheet for recording a local store purchase directly
/// from the Smart Shopping screen, restocking inventory and completing
/// the shopping list item.
class LocalPurchaseDialog extends ConsumerStatefulWidget {
  final String shoppingItemId;
  final String? inventoryItemId;
  final String itemName;
  final double defaultQuantity;
  final String unit;

  const LocalPurchaseDialog({
    super.key,
    required this.shoppingItemId,
    this.inventoryItemId,
    required this.itemName,
    required this.defaultQuantity,
    required this.unit,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String shoppingItemId,
    String? inventoryItemId,
    required String itemName,
    required double defaultQuantity,
    required String unit,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (_) => LocalPurchaseDialog(
        shoppingItemId: shoppingItemId,
        inventoryItemId: inventoryItemId,
        itemName: itemName,
        defaultQuantity: defaultQuantity,
        unit: unit,
      ),
    );
  }

  @override
  ConsumerState<LocalPurchaseDialog> createState() => _LocalPurchaseDialogState();
}

class _LocalPurchaseDialogState extends ConsumerState<LocalPurchaseDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _priceController;
  late final TextEditingController _qtyController;
  late final TextEditingController _storeNameController;
  late final TextEditingController _notesController;

  String? _selectedStoreId;
  bool _isNewStore = false;
  DateTime _purchaseDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController();
    final formattedQty = widget.defaultQuantity == widget.defaultQuantity.roundToDouble()
        ? widget.defaultQuantity.toInt().toString()
        : widget.defaultQuantity.toString();
    _qtyController = TextEditingController(text: formattedQty);
    _storeNameController = TextEditingController();
    _notesController = TextEditingController();

    // Default select first store if available
    final stores = ref.read(purchaseControllerProvider).stores;
    if (stores.isNotEmpty) {
      _selectedStoreId = stores.first.id;
    } else {
      _isNewStore = true;
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _qtyController.dispose();
    _storeNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _purchaseDate = picked);
    }
  }

  Future<void> _recordLocalPurchase() async {
    if (!_formKey.currentState!.validate()) return;

    final unitPrice = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final quantity = double.tryParse(_qtyController.text.trim()) ?? widget.defaultQuantity;
    final totalAmount = unitPrice * quantity;

    setState(() => _isSaving = true);

    String? storeId = _selectedStoreId;
    if (_isNewStore && _storeNameController.text.trim().isNotEmpty) {
      final newStore = await ref.read(purchaseControllerProvider.notifier).addStore(
        _storeNameController.text.trim(),
        null,
      );
      storeId = newStore?.id;
    }

    final payload = {
      'storeId': storeId,
      'purchaseDate': DateFormat('yyyy-MM-dd').format(_purchaseDate),
      'totalAmount': totalAmount,
      'currency': 'INR',
      'notes': _notesController.text.trim().isEmpty ? 'Bought locally' : _notesController.text.trim(),
      'items': [
        {
          'inventoryItemId': widget.inventoryItemId,
          'itemName': widget.itemName,
          'quantity': quantity,
          'unit': widget.unit,
          'unitPrice': unitPrice,
          'totalPrice': totalAmount,
        }
      ],
    };

    final purchase = await ref.read(purchaseControllerProvider.notifier).recordPurchase(payload);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (purchase != null) {
      // Complete shopping list item
      final shoppingList = ref.read(shoppingControllerProvider).list;
      if (shoppingList != null) {
        final item = shoppingList.items.where((i) => i.id == widget.shoppingItemId).firstOrNull;
        if (item != null && !item.isCompleted) {
          await ref.read(shoppingControllerProvider.notifier).toggleItem(widget.shoppingItemId);
        }
      }

      // Refresh inventory and shopping list
      ref.read(inventoryControllerProvider.notifier).loadData();
      ref.read(shoppingControllerProvider.notifier).loadShoppingList();

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to record purchase. Please try again.'),
          backgroundColor: AppColors.outOfStockText,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stores = ref.watch(purchaseControllerProvider).stores;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
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

              // Title
              const Row(
                children: [
                  Icon(Icons.storefront_rounded, color: AppColors.primary, size: 22),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    'Record Local Purchase',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Purchasing ${widget.itemName} from a nearby store',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Store Selector
              if (stores.isNotEmpty && !_isNewStore) ...[
                DropdownButtonFormField<String>(
                  initialValue: _selectedStoreId,
                  decoration: const InputDecoration(
                    labelText: 'Store',
                    prefixIcon: Icon(Icons.store_rounded, size: 20),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  items: [
                    ...stores.map((s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(s.name),
                        )),
                    const DropdownMenuItem(
                      value: '__new__',
                      child: Text('+ Add New Store...', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ),
                  ],
                  onChanged: (val) {
                    if (val == '__new__') {
                      setState(() {
                        _isNewStore = true;
                        _selectedStoreId = null;
                      });
                    } else {
                      setState(() => _selectedStoreId = val);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),
              ] else ...[
                TextFormField(
                  controller: _storeNameController,
                  decoration: InputDecoration(
                    labelText: 'Store Name',
                    hintText: 'e.g., Local Kirana, D-Mart',
                    prefixIcon: const Icon(Icons.store_rounded, size: 20),
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    suffixIcon: stores.isNotEmpty
                        ? TextButton(
                            onPressed: () {
                              setState(() {
                                _isNewStore = false;
                                _selectedStoreId = stores.first.id;
                              });
                            },
                            child: const Text('Saved Stores', style: TextStyle(fontSize: 12)),
                          )
                        : null,
                  ),
                  validator: (val) {
                    if (_isNewStore && (val == null || val.trim().isEmpty)) {
                      return 'Enter store name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // Price and Quantity
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Price Paid',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Enter price';
                        if (double.tryParse(val.trim()) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _qtyController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                        suffixText: widget.unit,
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Enter qty';
                        final num = double.tryParse(val.trim());
                        if (num == null || num <= 0) return '> 0';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Date Picker Tile
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.outline),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Date: ${DateFormat('dd MMM yyyy').format(_purchaseDate)}',
                        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _recordLocalPurchase,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_rounded, size: 18),
                      label: Text(
                        _isSaving ? 'Saving...' : 'Update Stock',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                      ),
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
