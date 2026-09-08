import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/homestock/homestock_pill_badge.dart';
import '../auth/auth_controller.dart';
import '../dashboard/dashboard_controller.dart';
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

class _SmartConfirmationSheetState extends ConsumerState<SmartConfirmationSheet> {
  bool _isProcessing = false;

  final List<_StatusOption> _statusOptions = const [
    _StatusOption('ALMOST_FULL', 'Almost Full', Icons.battery_full_rounded, Color(0xFF10B981), 0.90),
    _StatusOption('MORE_THAN_HALF', 'More than Half', Icons.battery_6_bar_rounded, Color(0xFF059669), 0.70),
    _StatusOption('ABOUT_HALF', 'About Half', Icons.battery_4_bar_rounded, Color(0xFF3B82F6), 0.50),
    _StatusOption('LESS_THAN_HALF', 'Less than Half', Icons.battery_2_bar_rounded, Color(0xFFF59E0B), 0.30),
    _StatusOption('ALMOST_EMPTY', 'Almost Empty', Icons.battery_1_bar_rounded, Color(0xFFEF4444), 0.10),
    _StatusOption('EMPTY', 'Empty', Icons.battery_alert_rounded, Color(0xFFDC2626), 0.0),
  ];

  Future<void> _handleStillHaveEnough() async {
    setState(() => _isProcessing = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.post('/items/${widget.item.id}/confirm-status', data: {
        'action': 'STILL_HAVE_ENOUGH',
      });
      await ref.read(inventoryControllerProvider.notifier).loadData();
      await ref.read(dashboardControllerProvider.notifier).loadDashboard();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Updated ${widget.item.name}: marked as stocked'),
            backgroundColor: AppColors.hsGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _handleAddToShopping() async {
    setState(() => _isProcessing = true);
    try {
      final shoppingNotifier = ref.read(shoppingControllerProvider.notifier);
      await shoppingNotifier.addItem(
        itemName: widget.item.name,
        quantity: widget.item.minimumQuantity > 0 ? widget.item.minimumQuantity * 2 : 1.0,
        unit: widget.item.unit,
        inventoryItemId: widget.item.id,
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${widget.item.name} to your shopping list'),
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
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.post('/items/${widget.item.id}/confirm-status', data: {
        'status': option.code,
      });
      await ref.read(inventoryControllerProvider.notifier).loadData();
      await ref.read(dashboardControllerProvider.notifier).loadDashboard();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.item.name} set to "${option.label}"'),
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

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Item Title & Current Status
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: item.categoryColorParsed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.categoryIconData, color: item.categoryColorParsed, size: 24),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            item.humanQuantityDisplay,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: 8),
                          HomeStockPillBadge(
                            label: item.isEstimated ? 'Estimated' : 'Verified',
                            variant: item.isEstimated ? HomeStockPillVariant.yellow : HomeStockPillVariant.green,
                            fontSize: 10,
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Prompt message
            const Text(
              'How is your stock at home right now?',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tap any approximate level in 1 tap — no measuring needed.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),

            // 6 Qualitative Level Buttons (Fast 2-tap selection)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.5,
              ),
              itemCount: _statusOptions.length,
              itemBuilder: (context, index) {
                final opt = _statusOptions[index];
                final isCurrent = item.quantityStatus == opt.code;
                return InkWell(
                  onTap: _isProcessing ? null : () => _handleSelectStatus(opt),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isCurrent ? opt.color.withValues(alpha: 0.15) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCurrent ? opt.color : const Color(0xFFE2E8F0),
                        width: isCurrent ? 2 : 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(opt.icon, color: opt.color, size: 20),
                        const SizedBox(height: 4),
                        Text(
                          opt.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                            color: isCurrent ? opt.color : AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // Quick 1-tap Actions: [Still Have Enough] & [Add to Shopping]
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing ? null : _handleStillHaveEnough,
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                    label: const Text('Still Have Enough'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.hsGreen,
                      side: const BorderSide(color: AppColors.hsGreen),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _handleAddToShopping,
                    icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                    label: const Text('Add to Shopping'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusOption {
  final String code;
  final String label;
  final IconData icon;
  final Color color;
  final double ratio;

  const _StatusOption(this.code, this.label, this.icon, this.color, this.ratio);
}
