import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../inventory/inventory_controller.dart';
import '../inventory/inventory_model.dart';
import '../inventory/item_detail_screen.dart';
import '../purchase/purchase_model.dart';
import '../purchase/purchases_screen.dart';

/// Screen displayed after a shopping run or purchase process completes.
///
/// Implemented according to the 10/10 Premium Restock Experience guidelines:
/// - Fast 3-second comprehension
/// - Zero confirmation redundancy (ONE strong confirmation)
/// - Contextual hero with subtle 600ms success micro-interaction
/// - Large, legible KPI summary (Total spent & Products added)
/// - Tangible Before -> After inventory delta in product cards (e.g. 3.5 L -> 4.5 L)
/// - Compact contextual purchase details (Store, Date, Verified source)
/// - Obvious primary action (View Inventory ->) vs secondary (<- Shopping List)
/// - Calm, human-made, Apple-level simplicity with 8pt spacing
class ProcessedProductsScreen extends ConsumerStatefulWidget {
  final PurchaseModel purchase;
  final bool isJustCompleted;
  final String? source;
  final bool isOffline;

  const ProcessedProductsScreen({
    super.key,
    required this.purchase,
    this.isJustCompleted = false,
    this.source,
    this.isOffline = false,
  });

  @override
  ConsumerState<ProcessedProductsScreen> createState() =>
      _ProcessedProductsScreenState();
}

class _ProcessedProductsScreenState extends ConsumerState<ProcessedProductsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.2, 0.85, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.25, 0.95, curve: Curves.easeOutCubic),
      ),
    );

    if (widget.isJustCompleted) {
      _animController.forward();
    } else {
      _animController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String _formatQty(double val) {
    return val == val.roundToDouble()
        ? val.toInt().toString()
        : val.toStringAsFixed(1);
  }

  InventoryItemModel? _findMatchingInventoryItem(
    List<InventoryItemModel> inventoryItems,
    PurchaseItemModel item,
  ) {
    if (item.inventoryItemId != null) {
      final direct = inventoryItems.where((i) => i.id == item.inventoryItemId);
      if (direct.isNotEmpty) return direct.first;
    }
    final normalized = item.itemName.toLowerCase().trim();
    final nameMatch = inventoryItems.where(
      (i) => i.name.toLowerCase().trim() == normalized,
    );
    if (nameMatch.isNotEmpty) return nameMatch.first;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final invState = ref.watch(inventoryControllerProvider);
    final items = widget.purchase.items;
    final totalSpent = widget.purchase.totalAmount;
    final totalSpentStr = '₹${totalSpent.toStringAsFixed(0)}';

    final parsedDate = DateTime.tryParse(widget.purchase.purchaseDate) ?? DateTime.now();
    final dateStr = DateFormat('MMM dd, yyyy • hh:mm a').format(parsedDate);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Restocked Products',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            Text(
              '${items.length} ${items.length == 1 ? 'item' : 'items'} added to household pantry',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded, color: AppColors.primary),
            tooltip: 'All Receipts',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PurchasesScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFE2E8F0),
            height: 1,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          // ─── 1. Contextual Hero Section with Subtle Animation ─────────
          _buildHeroSection(context, items.length, totalSpentStr),

          // ─── 2. Compact KPI Summary ──────────────────────────────────
          _buildSummaryCard(items.length, totalSpentStr),

          // ─── 3. Section Title ─────────────────────────────────────────
          _buildSectionHeader(items.length),

          // ─── 4. Product Breakdown with Tangible Before -> After ───────
          if (items.isEmpty)
            _buildEmptyState()
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: items.map((item) {
                  final matchedInvItem =
                      _findMatchingInventoryItem(invState.items, item);
                  return _buildProductCard(context, item, matchedInvItem);
                }).toList(),
              ),
            ),

          const SizedBox(height: 16),

          // ─── 5. Compact Purchase Details ─────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildPurchaseDetails(context, dateStr),
          ),

          const SizedBox(height: 16),

          // ─── 6. Smart Inventory Insight (Subtle & Contextual) ─────────
          if (items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildSmartInventoryInsight(items.length),
            ),

          const SizedBox(height: 16),
        ],
      ),
      // ─── 7. Bottom Navigation & Obvious Primary Action ─────────────
      bottomNavigationBar: _buildBottomActions(context),
    );
  }

  // ─── HERO SECTION ──────────────────────────────────────────────────────────
  Widget _buildHeroSection(BuildContext context, int itemCount, String spentStr) {
    final isCompleted = widget.isJustCompleted;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          return Column(
            children: [
              // Subtle check icon with calm scale animation
              Transform.scale(
                scale: isCompleted ? _scaleAnimation.value : 1.0,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF86EFAC),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 36,
                    color: Color(0xFF059669),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Result Title & Subtitle with smooth fade/slide
              Opacity(
                opacity: isCompleted ? _fadeAnimation.value : 1.0,
                child: Transform.translate(
                  offset: isCompleted ? _slideAnimation.value : Offset.zero,
                  child: Column(
                    children: [
                      Text(
                        isCompleted ? 'Restock completed' : 'Restock record',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isCompleted
                            ? 'Your inventory has been updated'
                            : 'Verified purchase and inventory record',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Concise supporting info: "1 product added • ₹50 spent"
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$itemCount ${itemCount == 1 ? 'product' : 'products'} added  •  $spentStr spent',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── COMPACT SUMMARY ───────────────────────────────────────────────────────
  Widget _buildSummaryCard(int itemCount, String spentStr) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Total spent (Primary visual emphasis)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spentStr,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Total spent',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          // Clean vertical divider
          Container(
            height: 36,
            width: 1,
            color: const Color(0xFFE2E8F0),
          ),
          const SizedBox(width: 20),
          // Products added (Secondary emphasis)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$itemCount',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  itemCount == 1 ? 'Product added' : 'Products added',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── SECTION HEADER ────────────────────────────────────────────────────────
  Widget _buildSectionHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Added products',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count ${count == 1 ? 'item' : 'items'}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── PRODUCT CARD WITH BEFORE -> AFTER PANTRY BALANCE ──────────────────────
  Widget _buildProductCard(
    BuildContext context,
    PurchaseItemModel item,
    InventoryItemModel? invItem,
  ) {
    final qtyStr = _formatQty(item.quantity);

    // Calculate Before -> After inventory balances
    String beforeQtyStr;
    String afterQtyStr;

    if (invItem != null) {
      final afterQty = invItem.quantity;
      final beforeQty = (afterQty - item.quantity);
      final clampedBefore = beforeQty < 0 ? 0.0 : beforeQty;
      beforeQtyStr = '${_formatQty(clampedBefore)} ${invItem.unit}';
      afterQtyStr = '${_formatQty(afterQty)} ${invItem.unit}';
    } else {
      beforeQtyStr = '0 ${item.unit}';
      afterQtyStr = '$qtyStr ${item.unit}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: invItem != null
              ? () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ItemDetailScreen(itemId: invItem.id),
                    ),
                  );
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Icon Container
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Icon(
                    Icons.shopping_bag_outlined,
                    size: 22,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),

                // Main Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name & Total Price Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.itemName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '₹${item.totalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),

                      // Quantity & Unit Price
                      Text(
                        '+$qtyStr ${item.unit}${item.unitPrice > 0 ? ' • ₹${item.unitPrice.toStringAsFixed(0)}/${item.unit}' : ''}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // BEFORE -> AFTER Pantry Balance
                      Row(
                        children: [
                          const Text(
                            'Pantry balance: ',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            beforeQtyStr,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 13,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_rounded,
                                  size: 11,
                                  color: Color(0xFF059669),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  afterQtyStr,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF059669),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Chevron for detail view
                if (invItem != null) ...[
                  const SizedBox(width: 8),
                  const Padding(
                    padding: EdgeInsets.only(top: 14),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: Color(0xFFCBD5E1),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── PURCHASE DETAILS ──────────────────────────────────────────────────────
  Widget _buildPurchaseDetails(BuildContext context, String dateStr) {
    final isScanned = (widget.source != null &&
        (widget.source!.toLowerCase().contains('receipt') ||
            widget.source!.toLowerCase().contains('scan')));
    final isBarcode = (widget.source != null &&
        widget.source!.toLowerCase().contains('barcode'));

    String sourceLabel = 'In-store purchase';
    IconData sourceIcon = Icons.storefront_rounded;

    if (widget.isOffline) {
      sourceLabel = 'Saved offline • Sync pending';
      sourceIcon = Icons.cloud_off_rounded;
    } else if (isScanned) {
      sourceLabel = 'Receipt scanned ✓ Verified';
      sourceIcon = Icons.document_scanner_rounded;
    } else if (isBarcode) {
      sourceLabel = 'Barcode scan';
      sourceIcon = Icons.qr_code_scanner_rounded;
    } else if (widget.source != null && widget.source!.isNotEmpty) {
      sourceLabel = widget.source!;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Purchase details',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.storefront_outlined,
                size: 16,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.purchase.storeName ?? (widget.source ?? 'In-store'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 15,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              Text(
                dateStr,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Source pill badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isScanned
                  ? const Color(0xFFECFDF5)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isScanned
                    ? const Color(0xFFA7F3D0)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  sourceIcon,
                  size: 13,
                  color: isScanned
                      ? const Color(0xFF059669)
                      : const Color(0xFF475569),
                ),
                const SizedBox(width: 6),
                Text(
                  sourceLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isScanned
                        ? const Color(0xFF059669)
                        : const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── SMART INVENTORY INSIGHT (SUBTLE & CONTEXTUAL) ─────────────────────────
  Widget _buildSmartInventoryInsight(int count) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDD6FE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Inventory updated',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4C1D95),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'All $count ${count == 1 ? 'item' : 'items'} are recorded and stock balances have been updated in your household pantry.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6D28D9),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── EMPTY STATE ───────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Center(
        child: Column(
          children: const [
            Icon(Icons.inventory_2_outlined, size: 40, color: Color(0xFFCBD5E1)),
            SizedBox(height: 12),
            Text(
              'No products recorded for this transaction.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── PRIMARY & SECONDARY ACTIONS (BOTTOM STICKY BAR) ───────────────────────
  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFF1F5F9), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Primary CTA: View Inventory
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => context.go('/inventory'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'View Inventory',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Secondary Action: Shopping List
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(
                Icons.arrow_back_rounded,
                size: 16,
                color: Color(0xFF64748B),
              ),
              label: const Text(
                'Shopping List',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              style: TextButton.styleFrom(
                minimumSize: const Size(120, 44),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
