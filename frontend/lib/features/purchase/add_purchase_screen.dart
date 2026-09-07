import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/homestock/homestock_app_bar.dart';
import '../../core/widgets/homestock/homestock_card.dart';
import '../inventory/inventory_controller.dart';
import '../shopping/shopping_controller.dart';
import 'purchase_controller.dart';

class AddPurchaseScreen extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>>? initialScannedItems;
  const AddPurchaseScreen({super.key, this.initialScannedItems});

  @override
  ConsumerState<AddPurchaseScreen> createState() => _AddPurchaseScreenState();
}

class _AddPurchaseItemEntry {
  String? inventoryItemId;
  String itemName = '';
  double quantity = 1.0;
  String unit = 'pcs';
  double unitPrice = 0.0;
  double totalPrice = 0.0;
}

class _AddPurchaseScreenState extends ConsumerState<AddPurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _newStoreController = TextEditingController();

  String? _selectedStoreId;
  DateTime _purchaseDate = DateTime.now();
  final List<_AddPurchaseItemEntry> _items = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-populate with quick scan items if provided
    if (widget.initialScannedItems != null && widget.initialScannedItems!.isNotEmpty) {
      for (final raw in widget.initialScannedItems!) {
        final entry = _AddPurchaseItemEntry()
          ..inventoryItemId = raw['inventoryItemId'] as String?
          ..itemName = raw['name'] as String? ?? ''
          ..quantity = (raw['quantity'] as num?)?.toDouble() ?? 1.0
          ..unit = raw['unit'] as String? ?? 'pcs'
          ..unitPrice = (raw['unitPrice'] as num?)?.toDouble() ?? 0.0
          ..totalPrice = ((raw['quantity'] as num?)?.toDouble() ?? 1.0) *
              ((raw['unitPrice'] as num?)?.toDouble() ?? 0.0);
        _items.add(entry);
      }
    } else {
      // Pre-populate with pending shopping items if available
      final shoppingList = ref.read(shoppingControllerProvider).list;
      if (shoppingList != null && shoppingList.items.isNotEmpty) {
        final pending = shoppingList.items.where((i) => !i.isCompleted).toList();
        for (final s in pending) {
          final entry = _AddPurchaseItemEntry()
            ..inventoryItemId = s.inventoryItemId
            ..itemName = s.itemName
            ..quantity = s.quantity
            ..unit = s.unit;
          _items.add(entry);
        }
      }
    }

    // Always have at least one empty row
    if (_items.isEmpty) {
      _items.add(_AddPurchaseItemEntry());
    }

    // Auto-fetch purchases & stores
    Future.microtask(() {
      ref.read(purchaseControllerProvider.notifier).loadPurchases();
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _newStoreController.dispose();
    super.dispose();
  }

  double get _calculatedTotal {
    return _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final payload = {
      'storeId': _selectedStoreId,
      'purchaseDate': DateFormat('yyyy-MM-dd').format(_purchaseDate),
      'totalAmount': _calculatedTotal,
      'currency': 'INR',
      'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      'items': _items.map((i) {
        return {
          'inventoryItemId': i.inventoryItemId,
          'itemName': i.itemName.trim(),
          'quantity': i.quantity,
          'unit': i.unit,
          'unitPrice': i.unitPrice,
          'totalPrice': i.totalPrice,
        };
      }).toList(),
    };

    final success = await ref.read(purchaseControllerProvider.notifier).recordPurchase(payload);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ref.read(inventoryControllerProvider.notifier).loadData();
        ref.read(shoppingControllerProvider.notifier).loadShoppingList();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchase recorded! Inventory restocked 🎉'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final purchaseState = ref.watch(purchaseControllerProvider);
    final invState = ref.watch(inventoryControllerProvider);
    final stores = purchaseState.stores;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: HomeStockAppBar(
        title: 'Record Purchase',
        subtitle: 'Bill Total: ₹${_calculatedTotal.toStringAsFixed(2)}',
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // Store & Date Card
            HomeStockCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Store & Purchase Date',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          initialValue: _selectedStoreId,
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
                            hintText: 'Select Store',
                          ),
                          items: [
                            const DropdownMenuItem<String?>(value: null, child: Text('General / Supermarket')),
                            ...stores.map((s) => DropdownMenuItem<String?>(value: s.id, child: Text(s.name))),
                          ],
                          onChanged: (val) => setState(() => _selectedStoreId = val),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _showAddStoreDialog,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 48,
                          width: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: const Icon(Icons.add_business_rounded, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Store presets
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: ['Supermarket', 'Local Mart', 'Reliance Smart', 'Online', 'Pharmacy'].map((preset) {
                      return InkWell(
                        onTap: () async {
                          final existing = stores.where((s) => s.name.toLowerCase() == preset.toLowerCase()).firstOrNull;
                          if (existing != null) {
                            setState(() => _selectedStoreId = existing.id);
                          } else {
                            final created = await ref.read(purchaseControllerProvider.notifier).addStore(preset, null);
                            if (created != null && mounted) {
                              setState(() => _selectedStoreId = created.id);
                            }
                          }
                        },
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(color: AppColors.outline.withValues(alpha: 0.8)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.storefront_outlined, size: 12, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                preset,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  // Date Picker
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _purchaseDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => _purchaseDate = picked);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.outline.withValues(alpha: 0.8)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Text(
                            'Date: ${DateFormat('dd MMM yyyy').format(_purchaseDate)}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Purchased Items list
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Items Purchased (${_items.length})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _items.add(_AddPurchaseItemEntry())),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Item', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),

            ..._items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;

              return HomeStockCard(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: item.itemName,
                            decoration: InputDecoration(
                              labelText: 'Item Name *',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.outline)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.outline)),
                            ),
                            validator: (val) => (val == null || val.trim().isEmpty) ? 'Required' : null,
                            onChanged: (val) => item.itemName = val,
                          ),
                        ),
                        if (_items.length > 1)
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.textMuted),
                            onPressed: () => setState(() => _items.removeAt(index)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Link to inventory item
                    if (invState.items.isNotEmpty) ...[
                      DropdownButtonFormField<String?>(
                        initialValue: item.inventoryItemId,
                        decoration: InputDecoration(
                          labelText: 'Link to Pantry (auto-restock)',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.outline)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.outline)),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(value: null, child: Text('— Not linked —')),
                          ...invState.items.map((i) => DropdownMenuItem<String?>(
                                value: i.id,
                                child: Text('${i.name} (${i.quantity} ${i.unit})'),
                              )),
                        ],
                        onChanged: (val) {
                          setState(() {
                            item.inventoryItemId = val;
                            if (val != null) {
                              final matched = invState.items.firstWhere((i) => i.id == val);
                              item.itemName = matched.name;
                              item.unit = matched.unit;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                    ],

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: item.quantity.toString(),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Qty (${item.unit})',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.outline)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.outline)),
                            ),
                            onChanged: (val) {
                              final q = double.tryParse(val) ?? 1.0;
                              setState(() {
                                item.quantity = q;
                                item.totalPrice = item.quantity * item.unitPrice;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: item.unitPrice > 0 ? item.unitPrice.toString() : '',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Price/Unit (₹)',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.outline)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.outline)),
                            ),
                            onChanged: (val) {
                              final p = double.tryParse(val) ?? 0.0;
                              setState(() {
                                item.unitPrice = p;
                                item.totalPrice = item.quantity * item.unitPrice;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            key: ValueKey(item.totalPrice),
                            initialValue: item.totalPrice > 0 ? item.totalPrice.toStringAsFixed(1) : '',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Total (₹)',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.outline)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.outline)),
                            ),
                            onChanged: (val) {
                              final t = double.tryParse(val) ?? 0.0;
                              setState(() => item.totalPrice = t);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: AppSpacing.md),

            // Total Bill Card
            HomeStockCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Bill Amount', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                  Text(
                    '₹${_calculatedTotal.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Confirm Button
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
                    : const Text('Confirm Purchase & Restock', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  void _showAddStoreDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Store', style: TextStyle(fontWeight: FontWeight.w800)),
        content: TextField(
          controller: _newStoreController,
          decoration: const InputDecoration(labelText: 'Store Name', hintText: 'e.g. DMart, Reliance Smart'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (_newStoreController.text.trim().isNotEmpty) {
                final created = await ref
                    .read(purchaseControllerProvider.notifier)
                    .addStore(_newStoreController.text.trim(), null);
                if (created != null) {
                  setState(() => _selectedStoreId = created.id);
                }
                _newStoreController.clear();
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
