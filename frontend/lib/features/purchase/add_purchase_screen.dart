import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/app_button.dart';
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
            ..unit = s.unit
            ..unitPrice = 0.0
            ..totalPrice = 0.0;
          _items.add(entry);
        }
      }
    }

    if (_items.isEmpty) {
      _items.add(_AddPurchaseItemEntry());
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _newStoreController.dispose();
    super.dispose();
  }

  double get _calculatedTotal {
    return _items.fold(0.0, (sum, i) => sum + i.totalPrice);
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
        // Refresh inventory and shopping list since items were restocked
        ref.read(inventoryControllerProvider.notifier).loadData();
        ref.read(shoppingControllerProvider.notifier).loadShoppingList();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase recorded! Inventory restocked 🎉')),
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Record Purchase'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // Store Selection Row
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Store & Date', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String?>(
                            initialValue: _selectedStoreId,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              hintText: 'Select Store',
                            ),
                            items: [
                              const DropdownMenuItem<String?>(value: null, child: Text('General / Supermarket')),
                              ...stores.map((s) => DropdownMenuItem<String?>(value: s.id, child: Text(s.name))),
                            ],
                            onChanged: (val) => setState(() => _selectedStoreId = val),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_business_rounded, color: AppColors.primary),
                          tooltip: 'Add new store',
                          onPressed: _showAddStoreDialog,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: ['Supermarket', 'Local Mart', 'Reliance Smart', 'Online', 'Pharmacy'].map((preset) {
                        return ActionChip(
                          label: Text(preset),
                          avatar: const Icon(Icons.storefront_outlined, size: 14),
                          backgroundColor: AppColors.chipBackground,
                          side: const BorderSide(color: AppColors.cardBorder),
                          labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          onPressed: () async {
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
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.sm),
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
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Text('Date: ${DateFormat('dd MMM yyyy').format(_purchaseDate)}'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Purchased Items list
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Items Purchased', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                TextButton.icon(
                  onPressed: () => setState(() => _items.add(_AddPurchaseItemEntry())),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Row'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),

            ..._items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;

              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: item.itemName,
                              decoration: const InputDecoration(
                                labelText: 'Item Name *',
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              validator: (val) => (val == null || val.trim().isEmpty) ? 'Required' : null,
                              onChanged: (val) => item.itemName = val,
                            ),
                          ),
                          if (_items.length > 1)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.textMuted),
                              onPressed: () => setState(() => _items.removeAt(index)),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Link to inventory item
                      if (invState.items.isNotEmpty) ...[
                        DropdownButtonFormField<String?>(
                          initialValue: item.inventoryItemId,
                          decoration: const InputDecoration(
                            labelText: 'Link to Inventory Item (restocks automatically)',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        const SizedBox(height: AppSpacing.sm),
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
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: TextFormField(
                              initialValue: item.unitPrice > 0 ? item.unitPrice.toString() : '',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Price/Unit (₹)',
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: TextFormField(
                              key: ValueKey(item.totalPrice),
                              initialValue: item.totalPrice > 0 ? item.totalPrice.toStringAsFixed(1) : '',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Total (₹)',
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                ),
              );
            }),
            const SizedBox(height: AppSpacing.lg),

            // Total Bill Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Amount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  Text(
                    '₹${_calculatedTotal.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            SizedBox(
              height: 48,
              child: AppButton(
                label: 'Confirm Purchase & Restock',
                onPressed: _submit,
                isLoading: _isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddStoreDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Store'),
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
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
