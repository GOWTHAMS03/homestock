import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/household_staples.dart';
import '../../core/sync/sync_providers.dart';
import '../../core/widgets/homestock/homestock_pill_badge.dart';
import '../auth/auth_controller.dart';
import '../shopping/shopping_controller.dart';
import 'inventory_controller.dart';
import 'inventory_model.dart';

class SmartConfirmationSheet extends ConsumerStatefulWidget {
  final InventoryItemModel item;

  const SmartConfirmationSheet({super.key, required this.item});

  static Future<void> show(BuildContext context, InventoryItemModel item) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SmartConfirmationSheet(item: item),
    );
  }

  @override
  ConsumerState<SmartConfirmationSheet> createState() => _SmartConfirmationSheetState();
}

class _SmartConfirmationSheetState extends ConsumerState<SmartConfirmationSheet>
    with SingleTickerProviderStateMixin {
  bool _isProcessing = false;
  late AnimationController _animController;

  final List<_StatusOption> _statusOptions = const [
    _StatusOption('ALMOST_FULL', 'Almost Full', Color(0xFF10B981), 0.90),
    _StatusOption('MORE_THAN_HALF', 'More than Half', Color(0xFF059669), 0.70),
    _StatusOption('ABOUT_HALF', 'About Half', Color(0xFF3B82F6), 0.50),
    _StatusOption('LESS_THAN_HALF', 'Less than Half', Color(0xFFF59E0B), 0.30),
    _StatusOption('ALMOST_EMPTY', 'Almost Empty', Color(0xFFEF4444), 0.10),
    _StatusOption('EMPTY', 'Empty', Color(0xFFDC2626), 0.0),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  double _getReferenceCapacity() {
    final item = widget.item;
    if (item.maximumQuantity != null && item.maximumQuantity! > 0) {
      return item.maximumQuantity!;
    }
    if (item.minimumQuantity > 0) {
      return item.minimumQuantity * 2.0;
    }
    if (item.quantity > 0) {
      return item.quantity * 1.5;
    }
    return 2.0;
  }

  double _calculateTargetQuantity(double ratio) {
    if (ratio == 0.0) return 0.0;
    final refCap = _getReferenceCapacity();
    final raw = refCap * ratio;
    final isDiscrete = widget.item.unit.toLowerCase().contains('pc') ||
        widget.item.unit.toLowerCase().contains('pack') ||
        widget.item.unit.toLowerCase().contains('bottle') ||
        widget.item.unit.toLowerCase().contains('can') ||
        widget.item.unit.toLowerCase().contains('box');
    if (isDiscrete) {
      return raw.roundToDouble().clamp(1.0, 9999.0);
    }
    return double.parse(raw.toStringAsFixed(1));
  }

  String _formatPreviewQty(double ratio) {
    if (ratio == 0.0) return '0 ${widget.item.unit}';
    final qty = _calculateTargetQuantity(ratio);
    final isWhole = qty == qty.roundToDouble();
    final valStr = isWhole ? qty.toInt().toString() : qty.toStringAsFixed(1);
    return '~$valStr ${widget.item.unit}';
  }

  Future<void> _handleStillHaveEnough() async {
    setState(() => _isProcessing = true);
    final finalQty = _calculateTargetQuantity(0.85);

    try {
      // 1. Immediately update Drift SQLite database (local reactive reflection!)
      await ref.read(inventoryControllerProvider.notifier).updateItem(
        widget.item.id,
        {
          'quantity': finalQty,
          'quantityStatus': 'ALMOST_FULL',
          'stockStatus': 'IN_STOCK',
        },
      );

      // 2. Sync to API backend (non-blocking, online only)
      final conn = ref.read(connectivityMonitorProvider);
      if (conn.isOnline) {
        final apiClient = ref.read(apiClientProvider);
        unawaited(() async {
          try {
            await apiClient.post('/items/${widget.item.id}/confirm-status', data: {
              'action': 'STILL_HAVE_ENOUGH',
            });
          } catch (_) {}
        }());
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Text('🌿', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Updated ${widget.item.name} stock to $finalQty ${widget.item.unit} (Stocked)',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.hsGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _handleAddToShopping() async {
    setState(() => _isProcessing = true);
    try {
      final shoppingNotifier = ref.read(shoppingControllerProvider.notifier);
      final restockQty = widget.item.minimumQuantity > 0 ? widget.item.minimumQuantity * 2 : 1.0;
      await shoppingNotifier.addItem(
        itemName: widget.item.name,
        quantity: restockQty,
        unit: widget.item.unit,
        inventoryItemId: widget.item.id,
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Text('🛒', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Added ${widget.item.name} ($restockQty ${widget.item.unit}) to Shopping List',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _handleSelectStatus(_StatusOption option) async {
    setState(() => _isProcessing = true);
    final finalQty = _calculateTargetQuantity(option.ratio);
    final newStatus = finalQty <= 0
        ? 'OUT_OF_STOCK'
        : (finalQty <= widget.item.minimumQuantity ? 'LOW_STOCK' : 'IN_STOCK');

    try {
      // 1. Immediately update Drift SQLite database (local reactive reflection!)
      await ref.read(inventoryControllerProvider.notifier).updateItem(
        widget.item.id,
        {
          'quantity': finalQty,
          'quantityStatus': option.code,
          'stockStatus': newStatus,
        },
      );

      // 2. Sync to API backend (non-blocking, online only)
      final conn = ref.read(connectivityMonitorProvider);
      if (conn.isOnline) {
        final apiClient = ref.read(apiClientProvider);
        unawaited(() async {
          try {
            await apiClient.post('/items/${widget.item.id}/confirm-status', data: {
              'status': option.code,
            });
          } catch (_) {}
        }());
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Text('✨', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${widget.item.name} set to "${option.label}" ($finalQty ${widget.item.unit})',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: option.color,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final staple = findStapleForName(item.name);
    final emoji = staple?.emoji ?? '📦';
    final tamilName = staple?.tamilName;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 24,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Handle bar
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Item Title & Current Status Header with Staple Pedestal
            Row(
              children: [
                // 3D-styled pedestal badge
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        item.categoryColorParsed.withValues(alpha: 0.18),
                        item.categoryColorParsed.withValues(alpha: 0.06),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: item.categoryColorParsed.withValues(alpha: 0.28),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: item.categoryColorParsed.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          HomeStockPillBadge(
                            label: item.isEstimated ? 'Estimated' : 'Verified',
                            variant: item.isEstimated ? HomeStockPillVariant.yellow : HomeStockPillVariant.green,
                            fontSize: 10,
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (tamilName != null && tamilName.isNotEmpty) ...[
                            Text(
                              tamilName,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary.withValues(alpha: 0.85),
                              ),
                            ),
                            const Text(' · ', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                          Flexible(
                            child: Text(
                              'Current: ${item.humanQuantityDisplay} (min: ${item.minimumQuantity.toInt() == item.minimumQuantity ? item.minimumQuantity.toInt() : item.minimumQuantity} ${item.unit})',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Prompt message banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  Text('⚡', style: TextStyle(fontSize: 15)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How is your stock at home right now?',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 1),
                        Text(
                          'Tap any level below — quantity is instantly updated in your stock.',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 6 Qualitative SVG Gauge Level Cards (Fast 1-tap selection)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.18,
              ),
              itemCount: _statusOptions.length,
              itemBuilder: (context, index) {
                final opt = _statusOptions[index];
                final isCurrent = item.quantityStatus == opt.code;
                final previewQty = _formatPreviewQty(opt.ratio);

                return InkWell(
                  onTap: _isProcessing ? null : () => _handleSelectStatus(opt),
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isCurrent ? opt.color.withValues(alpha: 0.12) : const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isCurrent ? opt.color : const Color(0xFFE5E7EB),
                        width: isCurrent ? 2 : 1,
                      ),
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: opt.color.withValues(alpha: 0.22),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // SVG Visual Gauge Icon
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: SvgPicture.string(
                            _buildGaugeSvg(opt.code, opt.color, opt.ratio),
                          ),
                        ),
                        const SizedBox(height: 5),
                        // Label (Must match exact string for existing test compatibility)
                        Text(
                          opt.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w700,
                            color: isCurrent ? opt.color : AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        // Real-time calculated quantity preview chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? opt.color.withValues(alpha: 0.18)
                                : const Color(0xFFE2E8F0).withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            previewQty,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: isCurrent ? opt.color : Colors.blueGrey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // Quick 1-tap Actions with Animated SVGs: [Still Have Enough] & [Add to Shopping]
            Row(
              children: [
                // Still Have Enough (Shield Check SVG)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isProcessing ? null : _handleStillHaveEnough,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.hsGreen,
                      side: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                      backgroundColor: const Color(0xFFF0FDF4),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: SvgPicture.string(_kShieldCheckSvg),
                        ),
                        const SizedBox(width: 8),
                        const Flexible(
                          child: Text(
                            'Still Have Enough',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // Add to Shopping (Shopping Cart Plus SVG)
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _handleAddToShopping,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 1,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: SvgPicture.string(_kCartPlusSvg),
                        ),
                        const SizedBox(width: 8),
                        const Flexible(
                          child: Text(
                            'Add to Shopping',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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

  // ──── SVG GAUGE VECTOR GENERATORS ────

  static String _buildGaugeSvg(String code, Color color, double ratio) {
    switch (code) {
      case 'ALMOST_FULL':
        return '''
<svg viewBox="0 0 36 36" fill="none" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="grad_af" x1="0" y1="32" x2="0" y2="6" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#059669"/>
      <stop offset="100%" stop-color="#34D399"/>
    </linearGradient>
  </defs>
  <rect x="7" y="4" width="22" height="28" rx="6" fill="#F0FDF4" stroke="#10B981" stroke-width="2"/>
  <rect x="14" y="1.5" width="8" height="3" rx="1.5" fill="#10B981"/>
  <rect x="9" y="8" width="18" height="22" rx="4" fill="url(#grad_af)"/>
  <rect x="10.5" y="9" width="2.5" height="18" rx="1.2" fill="#FFFFFF" fill-opacity="0.6"/>
  <circle cx="21" cy="14" r="1.5" fill="#FFFFFF" fill-opacity="0.7"/>
  <circle cx="23" cy="22" r="1.2" fill="#FFFFFF" fill-opacity="0.5"/>
</svg>
''';

      case 'MORE_THAN_HALF':
        return '''
<svg viewBox="0 0 36 36" fill="none" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="grad_mh" x1="0" y1="32" x2="0" y2="12" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#047857"/>
      <stop offset="100%" stop-color="#10B981"/>
    </linearGradient>
  </defs>
  <rect x="7" y="4" width="22" height="28" rx="6" fill="#F0FDF4" stroke="#059669" stroke-width="2"/>
  <rect x="14" y="1.5" width="8" height="3" rx="1.5" fill="#059669"/>
  <rect x="9" y="13" width="18" height="17" rx="4" fill="url(#grad_mh)"/>
  <rect x="10.5" y="14" width="2.5" height="13" rx="1.2" fill="#FFFFFF" fill-opacity="0.6"/>
  <circle cx="21" cy="19" r="1.5" fill="#FFFFFF" fill-opacity="0.6"/>
</svg>
''';

      case 'ABOUT_HALF':
        return '''
<svg viewBox="0 0 36 36" fill="none" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="grad_ah" x1="0" y1="32" x2="0" y2="18" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#2563EB"/>
      <stop offset="100%" stop-color="#60A5FA"/>
    </linearGradient>
  </defs>
  <rect x="7" y="4" width="22" height="28" rx="6" fill="#EFF6FF" stroke="#3B82F6" stroke-width="2"/>
  <rect x="14" y="1.5" width="8" height="3" rx="1.5" fill="#3B82F6"/>
  <rect x="9" y="18" width="18" height="12" rx="4" fill="url(#grad_ah)"/>
  <path d="M9 19 Q13.5 17 18 19 T27 19" stroke="#93C5FD" stroke-width="1.5" fill="none"/>
  <rect x="10.5" y="19" width="2.5" height="8" rx="1.2" fill="#FFFFFF" fill-opacity="0.6"/>
</svg>
''';

      case 'LESS_THAN_HALF':
        return '''
<svg viewBox="0 0 36 36" fill="none" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="grad_lh" x1="0" y1="32" x2="0" y2="23" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#D97706"/>
      <stop offset="100%" stop-color="#FBBF24"/>
    </linearGradient>
  </defs>
  <rect x="7" y="4" width="22" height="28" rx="6" fill="#FFFBEB" stroke="#F59E0B" stroke-width="2"/>
  <rect x="14" y="1.5" width="8" height="3" rx="1.5" fill="#F59E0B"/>
  <rect x="9" y="23" width="18" height="7" rx="3" fill="url(#grad_lh)"/>
  <rect x="10.5" y="24" width="2.5" height="4" rx="1" fill="#FFFFFF" fill-opacity="0.6"/>
</svg>
''';

      case 'ALMOST_EMPTY':
        return '''
<svg viewBox="0 0 36 36" fill="none" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="grad_ae" x1="0" y1="32" x2="0" y2="27" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#DC2626"/>
      <stop offset="100%" stop-color="#F87171"/>
    </linearGradient>
  </defs>
  <rect x="7" y="4" width="22" height="28" rx="6" fill="#FEF2F2" stroke="#EF4444" stroke-width="2"/>
  <rect x="14" y="1.5" width="8" height="3" rx="1.5" fill="#EF4444"/>
  <rect x="9" y="27" width="18" height="3.5" rx="1.5" fill="url(#grad_ae)"/>
  <circle cx="18" cy="14" r="2" fill="#EF4444"/>
  <rect x="17" y="17" width="2" height="3" rx="1" fill="#EF4444"/>
</svg>
''';

      case 'EMPTY':
      default:
        return '''
<svg viewBox="0 0 36 36" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="7" y="4" width="22" height="28" rx="6" fill="#FFF1F2" stroke="#DC2626" stroke-width="2" stroke-dasharray="3 3"/>
  <rect x="14" y="1.5" width="8" height="3" rx="1.5" fill="#DC2626"/>
  <line x1="11" y1="28" x2="25" y2="8" stroke="#DC2626" stroke-width="2" stroke-linecap="round"/>
</svg>
''';
    }
  }

  static const String _kShieldCheckSvg = '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M12 2L3 6V12C3 17.5 7.5 22 12 23C16.5 22 21 17.5 21 12V6L12 2Z" fill="#DCFCE7" stroke="#10B981" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M8.5 12L11 14.5L15.5 9.5" stroke="#059669" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

  static const String _kCartPlusSvg = '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M2 3H4.5L6.8 14.5C6.9 15 7.4 15.5 8 15.5H18C18.5 15.5 19 15 19.2 14.5L21.5 6.5H5.5" stroke="#FFFFFF" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
  <circle cx="9" cy="19.5" r="1.5" fill="#FFFFFF"/>
  <circle cx="17.5" cy="19.5" r="1.5" fill="#FFFFFF"/>
  <path d="M13.5 9V13M11.5 11H15.5" stroke="#FFFFFF" stroke-width="2" stroke-linecap="round"/>
</svg>
''';
}

class _StatusOption {
  final String code;
  final String label;
  final Color color;
  final double ratio;

  const _StatusOption(this.code, this.label, this.color, this.ratio);
}
