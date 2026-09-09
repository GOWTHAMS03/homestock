import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/household_staples.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/homestock/homestock_pill_badge.dart';
import '../home_switcher/home_controller.dart';
import '../shopping/shopping_controller.dart';
import 'add_edit_item_screen.dart';
import 'category_model.dart';
import 'inventory_controller.dart';
import 'inventory_model.dart';

/// Interactive modal sheet that presents product-tailored quantity selection,
/// basic details, and expandable additional details for suggested household staples.
class StapleQuantityDetailsSheet extends ConsumerStatefulWidget {
  final HouseholdStaple staple;
  final InventoryItemModel? existingItem;

  const StapleQuantityDetailsSheet({
    super.key,
    required this.staple,
    this.existingItem,
  });

  static Future<void> show(
    BuildContext context, {
    required HouseholdStaple staple,
    InventoryItemModel? existingItem,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StapleQuantityDetailsSheet(
        staple: staple,
        existingItem: existingItem,
      ),
    );
  }

  @override
  ConsumerState<StapleQuantityDetailsSheet> createState() => _StapleQuantityDetailsSheetState();
}

class _StapleQuantityDetailsSheetState extends ConsumerState<StapleQuantityDetailsSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _minQtyController;
  late TextEditingController _brandController;
  late TextEditingController _priceController;
  late TextEditingController _notesController;

  late double _quantity;
  late String _selectedUnit;
  late String _selectedLocation;
  String? _selectedCategoryId;
  DateTime? _expiryDate;
  bool _showMoreDetails = false;
  bool _isSubmitting = false;

  final List<String> _commonUnits = ['pcs', 'kg', 'g', 'L', 'ml', 'pk', 'pack', 'bottle', 'can', 'box'];
  final List<String> _storageLocations = [
    'Pantry',
    'Fridge',
    'Freezer',
    'Cabinet',
    'Spice Rack',
    'Fruit Bowl',
    'Cleaning Cabinet',
    'Bathroom',
  ];

  @override
  void initState() {
    super.initState();
    final staple = widget.staple;
    final existing = widget.existingItem;

    _quantity = staple.defaultQty;
    _selectedUnit = staple.defaultUnit;
    _selectedLocation = staple.storageLocation;

    _nameController = TextEditingController(text: existing?.name ?? staple.name);
    _quantityController = TextEditingController(text: _formatQty(_quantity));
    _minQtyController = TextEditingController(text: _formatQty(existing?.minimumQuantity ?? staple.minimumQuantity));
    _brandController = TextEditingController(text: existing?.brand ?? '');
    _priceController = TextEditingController(text: existing?.purchasePrice != null ? existing!.purchasePrice.toString() : '');
    _notesController = TextEditingController(text: existing?.notes ?? '');

    if (existing?.expiryDate != null) {
      _expiryDate = DateTime.tryParse(existing!.expiryDate!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _minQtyController.dispose();
    _brandController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatQty(double qty) {
    return qty == qty.roundToDouble() ? qty.toInt().toString() : qty.toString();
  }

  void _updateQuantity(double newQty) {
    if (newQty <= 0) return;
    HapticFeedback.selectionClick();
    setState(() {
      _quantity = newQty;
      _quantityController.text = _formatQty(newQty);
    });
  }

  double _getStepSize() {
    final u = _selectedUnit.toLowerCase();
    if (u == 'g' || u == 'ml') return 50.0;
    if (u == 'kg' || u == 'l') return 0.5;
    return 1.0;
  }

  Future<void> _handleAddToInventory() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final invState = ref.read(inventoryControllerProvider);
      final homeState = ref.read(homeControllerProvider);
      final homeId = homeState.activeHome?.id;

      final allCategories = invState.categories.isNotEmpty
          ? invState.categories
          : CategoryModel.defaultCategories(homeId);

      final category = allCategories.firstWhere(
        (c) => c.id == _selectedCategoryId || c.name.toLowerCase() == widget.staple.category.toLowerCase(),
        orElse: () => allCategories.first,
      );

      final parsedQty = double.tryParse(_quantityController.text) ?? _quantity;
      final parsedMinQty = double.tryParse(_minQtyController.text) ?? widget.staple.minimumQuantity;
      final parsedPrice = double.tryParse(_priceController.text);

      if (widget.existingItem != null) {
        // Restock existing pantry item
        final existing = widget.existingItem!;
        await ref.read(inventoryControllerProvider.notifier).updateStock(
              existing.id,
              'STOCK_IN',
              parsedQty,
              'Restocked staple suggestion',
            );

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Restocked ${existing.name} (+${_formatQty(parsedQty)} $_selectedUnit) in pantry!'),
              backgroundColor: const Color(0xFF0F172A),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        // Create new item in pantry inventory
        final success = await ref.read(inventoryControllerProvider.notifier).createItem({
          'name': _nameController.text.trim(),
          'categoryId': category.id,
          'categoryName': category.name,
          'categoryIcon': category.icon,
          'categoryColor': category.colorHex,
          'quantity': parsedQty,
          'unit': _selectedUnit,
          'minimumQuantity': parsedMinQty,
          'storageLocation': _selectedLocation,
          'brand': _brandController.text.trim().isNotEmpty ? _brandController.text.trim() : null,
          'expiryDate': _expiryDate != null ? DateFormat('yyyy-MM-dd').format(_expiryDate!) : null,
          'purchasePrice': parsedPrice,
          'notes': _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
          'stockStatus': parsedQty > parsedMinQty ? 'IN_STOCK' : 'LOW_STOCK',
        });

        if (mounted) {
          Navigator.of(context).pop();
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Added ${_nameController.text.trim()} (${_formatQty(parsedQty)} $_selectedUnit) to pantry!'),
                backgroundColor: AppColors.primary,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleAddToShoppingList() async {
    final parsedQty = double.tryParse(_quantityController.text) ?? _quantity;
    final itemName = _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : widget.staple.name;

    final success = await ref.read(shoppingControllerProvider.notifier).addItem(
          itemName: itemName,
          quantity: parsedQty,
          unit: _selectedUnit,
          categoryName: widget.staple.category,
          inventoryItemId: widget.existingItem?.id,
        );

    if (mounted) {
      Navigator.of(context).pop();
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added $itemName (${_formatQty(parsedQty)} $_selectedUnit) to shopping list 🛒'),
            backgroundColor: const Color(0xFF0F172A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _openFullForm() {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditItemScreen(
          initialStaple: widget.staple,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final staple = widget.staple;
    final existing = widget.existingItem;

    final suggestedPresets = staple.suggestedQuantities;
    final suggestedBrands = staple.suggestedBrands;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 42,
                height: 4.5,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),

            // Scrollable Content
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  children: [
                    // Header Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFFEF3C7).withValues(alpha: 0.6),
                            const Color(0xFFF1F5F9),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(staple.emoji, style: const TextStyle(fontSize: 26)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            staple.name,
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          if (staple.tamilName != null && staple.tamilName!.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              staple.tamilName!,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFFD97706),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    HomeStockPillBadge(
                                      label: staple.subCategory ?? staple.category,
                                      variant: HomeStockPillVariant.purple,
                                      fontSize: 10,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                if (existing != null)
                                  Row(
                                    children: [
                                      const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
                                      const SizedBox(width: 4),
                                      Text(
                                        'In Pantry: ${_formatQty(existing.quantity)} ${existing.unit} • ${existing.stockStatus.replaceAll('_', ' ')}',
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF059669),
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  const Text(
                                    'Suggested household staple • Configure details to add',
                                    style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // SECTION 1: Product-Based Quantity Selection
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Quantity',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                        Text(
                          'Based on ${staple.name}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Quick Quantity Presets for this specific product
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: suggestedPresets.map((qty) {
                        final isSelected = _quantity == qty;
                        return InkWell(
                          onTap: () => _updateQuantity(qty),
                          borderRadius: BorderRadius.circular(10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Text(
                              '${_formatQty(qty)} $_selectedUnit',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    // Fine-grained stepper control with unit selector
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.primary),
                            onPressed: () => _updateQuantity((_quantity - _getStepSize()).clamp(0.1, 999.0)),
                          ),
                          Expanded(
                            child: TextFormField(
                              controller: _quantityController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              onChanged: (val) {
                                final parsed = double.tryParse(val);
                                if (parsed != null && parsed > 0) {
                                  setState(() => _quantity = parsed);
                                }
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                            onPressed: () => _updateQuantity(_quantity + _getStepSize()),
                          ),
                          const SizedBox(width: 8),
                          // Unit Dropdown
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _commonUnits.contains(_selectedUnit) ? _selectedUnit : _commonUnits.first,
                                isDense: true,
                                items: _commonUnits.map((u) {
                                  return DropdownMenuItem(
                                    value: u,
                                    child: Text(u, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedUnit = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // SECTION 2: Basic Details
                    const Text(
                      'Basic Information',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 10),

                    // Name Field
                    AppTextField(
                      controller: _nameController,
                      label: 'Item Name *',
                      hint: 'e.g. Milk, Rice, Dish Soap',
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Item name is required';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Storage Location Chips
                    const Text(
                      'Storage Location',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 34,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _storageLocations.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 6),
                        itemBuilder: (context, index) {
                          final loc = _storageLocations[index];
                          final isSelected = _selectedLocation.toLowerCase() == loc.toLowerCase();
                          return InkWell(
                            onTap: () => setState(() => _selectedLocation = loc),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF0F172A) : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  loc,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    color: isSelected ? Colors.white : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Minimum Alert Quantity
                    AppTextField(
                      controller: _minQtyController,
                      label: 'Low Stock Alert Threshold (Min Qty)',
                      hint: '1.0',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 14),

                    // SECTION 3: Additional Details (Expandable)
                    InkWell(
                      onTap: () => setState(() => _showMoreDetails = !_showMoreDetails),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.tune_rounded, size: 16, color: AppColors.primary),
                                const SizedBox(width: 8),
                                const Text(
                                  'More Details (Brand, Expiry, Price)',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                            Icon(
                              _showMoreDetails ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_showMoreDetails) ...[
                      const SizedBox(height: 12),

                      // Brand Field + Suggested Brands
                      AppTextField(
                        controller: _brandController,
                        label: 'Brand (Optional)',
                        hint: 'e.g. Amul, Tata, Aashirvaad',
                      ),
                      if (suggestedBrands.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: suggestedBrands.map((b) {
                            final isSelected = _brandController.text.trim() == b;
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _brandController.text = b;
                                });
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primaryContainer : Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : const Color(0xFFCBD5E1),
                                  ),
                                ),
                                child: Text(
                                  b,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sm),

                      // Expiry Date Picker
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Estimated Expiry Date (Optional)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () async {
                              final now = DateTime.now();
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _expiryDate ?? now.add(const Duration(days: 14)),
                                firstDate: now.subtract(const Duration(days: 30)),
                                lastDate: now.add(const Duration(days: 365 * 5)),
                              );
                              if (picked != null) {
                                setState(() => _expiryDate = picked);
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _expiryDate != null
                                        ? DateFormat('dd MMM yyyy').format(_expiryDate!)
                                        : 'Select expiry date',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _expiryDate != null ? AppColors.textPrimary : AppColors.textMuted,
                                    ),
                                  ),
                                  if (_expiryDate != null)
                                    InkWell(
                                      onTap: () => setState(() => _expiryDate = null),
                                      child: const Icon(Icons.clear_rounded, size: 16, color: AppColors.textMuted),
                                    )
                                  else
                                    const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.textSecondary),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Quick Expiry Presets
                          Wrap(
                            spacing: 6,
                            children: [
                              _buildQuickExpiryChip('+3 Days', const Duration(days: 3)),
                              _buildQuickExpiryChip('+1 Week', const Duration(days: 7)),
                              _buildQuickExpiryChip('+1 Month', const Duration(days: 30)),
                              _buildQuickExpiryChip('+6 Months', const Duration(days: 180)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Price and Notes
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _priceController,
                              label: 'Price (Optional)',
                              hint: 'e.g. 50',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppTextField(
                        controller: _notesController,
                        label: 'Notes (Optional)',
                        hint: 'e.g. Bought from local store',
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    offset: const Offset(0, -3),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Secondary: Add to Shopping List
                      OutlinedButton.icon(
                        onPressed: _isSubmitting ? null : _handleAddToShoppingList,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        icon: const Icon(Icons.shopping_cart_outlined, size: 16, color: AppColors.textPrimary),
                        label: const Text('To Buy', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 12.5)),
                      ),
                      const SizedBox(width: 10),

                      // Primary: Add to Pantry Inventory
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _handleAddToInventory,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: _isSubmitting
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Icon(existing != null ? Icons.add_box_rounded : Icons.check_circle_rounded, size: 18),
                          label: Text(
                            existing != null
                                ? 'Restock (+${_formatQty(_quantity)} $_selectedUnit)'
                                : 'Add to Inventory (${_formatQty(_quantity)} $_selectedUnit)',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: TextButton.icon(
                      onPressed: _openFullForm,
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      ),
                      icon: const Icon(Icons.tune_rounded, size: 14, color: AppColors.textSecondary),
                      label: const Text(
                        'Open in Full Add/Edit Form',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickExpiryChip(String label, Duration duration) {
    return InkWell(
      onTap: () {
        setState(() {
          _expiryDate = DateTime.now().add(duration);
        });
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
