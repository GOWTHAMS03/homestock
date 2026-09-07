import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../home_switcher/home_controller.dart';
import 'local_purchase_dialog.dart';
import 'purchase_confirmation_dialog.dart';
import 'smart_shopping_controller.dart';
import 'smart_shopping_models.dart';

/// Smart Shopping price comparison screen.
///
/// Pushed from Shopping List when user taps "Compare Prices" on an item.
/// Displays provider offers ranked by effective price, best deal highlighted,
/// and a local purchase option.
class SmartShoppingScreen extends ConsumerStatefulWidget {
  final String itemId;
  final String? inventoryItemId;
  final String itemName;
  final double quantity;
  final String unit;

  const SmartShoppingScreen({
    super.key,
    required this.itemId,
    this.inventoryItemId,
    required this.itemName,
    required this.quantity,
    required this.unit,
  });

  @override
  ConsumerState<SmartShoppingScreen> createState() => _SmartShoppingScreenState();
}

class _SmartShoppingScreenState extends ConsumerState<SmartShoppingScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final homeId = ref.read(homeControllerProvider).activeHome?.id;
      if (homeId != null) {
        ref.read(smartShoppingControllerProvider.notifier).fetchOffers(homeId, widget.itemId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(smartShoppingControllerProvider);
    final homeId = ref.watch(homeControllerProvider).activeHome?.id ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Compare Prices'),
        elevation: 0,
      ),
      body: state.isLoading
          ? _buildLoadingState()
          : state.errorMessage != null
              ? _buildErrorState(state, homeId)
              : state.result != null
                  ? _buildResultsState(state.result!, homeId)
                  : _buildEmptyState(),
    );
  }

  // ──── Loading ────

  Widget _buildLoadingState() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _buildItemHeader(),
        const SizedBox(height: AppSpacing.lg),
        // Skeleton cards mimicking offer layout
        ...List.generate(3, (i) => const Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.sm),
          child: SkeletonItemCard(),
        )),
      ],
    );
  }

  // ──── Error ────

  Widget _buildErrorState(SmartShoppingState state, String homeId) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              state.isOffline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
              size: 56,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              state.errorMessage ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (!state.isOffline)
              ElevatedButton.icon(
                onPressed: () => ref.read(smartShoppingControllerProvider.notifier)
                    .fetchOffers(homeId, widget.itemId),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(140, 44),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ──── Empty ────

  Widget _buildEmptyState() {
    return EmptyStateView(
      icon: Icons.search_off_rounded,
      title: 'No offers found',
      message: 'We couldn\'t find any online offers for "${widget.itemName}". You can still buy it locally.',
    );
  }

  // ──── Results ────

  Widget _buildResultsState(PriceComparisonResult result, String homeId) {
    final otherOffers = result.offers.length > 1 ? result.offers.sublist(1) : <ProductOfferModel>[];

    return RefreshIndicator(
      onRefresh: () => ref.read(smartShoppingControllerProvider.notifier)
          .fetchOffers(homeId, widget.itemId),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Item header
          _buildItemHeader(),
          const SizedBox(height: AppSpacing.lg),

          // Provider status warnings
          if (result.failedProviderCount > 0)
            _buildProviderWarnings(result),

          // Best Deal
          if (result.bestOffer != null) ...[
            _buildBestDealCard(result.bestOffer!, homeId, result.shoppingItem.id),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Other offers
          if (otherOffers.isNotEmpty) ...[
            _buildSectionLabel('Other options'),
            const SizedBox(height: AppSpacing.sm),
            ...otherOffers.map((offer) =>
                _buildOfferCard(offer, homeId, result.shoppingItem.id)),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Savings label
          if (result.savingsLabel != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.inStockBg,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.inStockBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.savings_outlined, size: 18, color: AppColors.inStockText),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      result.savingsLabel!,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.inStockText),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Local purchase option
          _buildLocalPurchaseCard(),
          const SizedBox(height: AppSpacing.md),

          // Affiliate disclosure
          _buildAffiliateDisclosure(),
          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }

  // ──── Sub-components ────

  Widget _buildItemHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.itemName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.quantity == widget.quantity.roundToDouble() ? widget.quantity.toInt() : widget.quantity} ${widget.unit}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderWarnings(PriceComparisonResult result) {
    final failed = result.providerStatuses.values.where((s) => s.isFailed || s.isTimeout).toList();
    if (failed.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.lowStockBg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.lowStockBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.lowStockText),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                '${failed.map((f) => f.provider).join(', ')} temporarily unavailable',
                style: const TextStyle(fontSize: 12, color: AppColors.lowStockText, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBestDealCard(ProductOfferModel offer, String homeId, String itemId) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Best deal badge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSpacing.radiusMd),
                topRight: Radius.circular(AppSpacing.radiusMd),
              ),
            ),
            child: const Row(
              children: [
                Text('🏆', style: TextStyle(fontSize: 16)),
                SizedBox(width: AppSpacing.sm),
                Text(
                  'Best Online Price',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product name + provider
                Text(
                  offer.productName,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  offer.provider,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.md),

                // Price + delivery
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${offer.effectivePrice.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    if (offer.pricePerUnitLabel != null)
                      Text(
                        offer.pricePerUnitLabel!,
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // Delivery + arrival
                Row(
                  children: [
                    Icon(
                      offer.isFreeDelivery ? Icons.local_shipping_outlined : Icons.local_shipping_outlined,
                      size: 15,
                      color: offer.isFreeDelivery ? AppColors.inStockText : AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      offer.deliveryText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: offer.isFreeDelivery ? AppColors.inStockText : AppColors.textSecondary,
                      ),
                    ),
                    if (offer.estimatedDelivery != null) ...[
                      const SizedBox(width: AppSpacing.md),
                      const Icon(Icons.schedule_rounded, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 3),
                      Text(
                        'Arrives: ${offer.estimatedDelivery}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),

                // Match type + freshness
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    if (offer.matchType == 'SIMILAR')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.lowStockBg,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.lowStockBorder, width: 0.6),
                        ),
                        child: const Text(
                          'Similar product',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.lowStockText),
                        ),
                      ),
                    const Spacer(),
                    if (offer.freshnessLabel.isNotEmpty)
                      Text(
                        'Price checked: ${offer.freshnessLabel}',
                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                      ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // Buy Online button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () => _onBuyOnline(offer, homeId, itemId),
                    icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                    label: const Text('Buy Online', style: TextStyle(fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCard(ProductOfferModel offer, String homeId, String itemId) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // Provider + product
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offer.productName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        offer.provider,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        offer.deliveryText,
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  if (offer.matchType == 'SIMILAR')
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Similar product',
                        style: TextStyle(fontSize: 10, color: AppColors.lowStockText, fontWeight: FontWeight.w500),
                      ),
                    ),
                ],
              ),
            ),

            // Price + buy
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${offer.effectivePrice.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                if (offer.pricePerUnitLabel != null)
                  Text(
                    offer.pricePerUnitLabel!,
                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                  ),
                const SizedBox(height: AppSpacing.xs),
                SizedBox(
                  height: 32,
                  child: OutlinedButton(
                    onPressed: () => _onBuyOnline(offer, homeId, itemId),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary, width: 1),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                    ),
                    child: const Text('Buy Online', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalPurchaseCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.store_rounded, size: 20, color: AppColors.textSecondary),
                SizedBox(width: AppSpacing.sm),
                Text(
                  'Nearby / Local',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Prefer buying from a nearby store? Record your purchase to update inventory.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: _onBuyLocally,
                icon: const Icon(Icons.storefront_rounded, size: 18),
                label: const Text('I\'ll Buy Locally', style: TextStyle(fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.outline),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAffiliateDisclosure() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Text(
        'Some links may earn HomeStock a commission at no extra cost to you.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontStyle: FontStyle.italic),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
    );
  }

  // ──── Actions ────

  void _onBuyOnline(ProductOfferModel offer, String homeId, String itemId) {
    ref.read(smartShoppingControllerProvider.notifier).openAffiliateLink(
      homeId: homeId,
      shoppingItemId: itemId,
      provider: offer.provider,
      providerProductId: offer.providerProductId,
      fallbackUrl: offer.affiliateUrl ?? offer.productUrl,
    );

    // Show purchase confirmation after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _showPurchaseConfirmation(offer);
      }
    });
  }

  Future<void> _onBuyLocally() async {
    final recorded = await LocalPurchaseDialog.show(
      context: context,
      shoppingItemId: widget.itemId,
      inventoryItemId: widget.inventoryItemId,
      itemName: widget.itemName,
      defaultQuantity: widget.quantity,
      unit: widget.unit,
    );

    if (recorded == true && mounted) {
      Navigator.of(context).pop(); // Back to shopping list
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Local purchase recorded! Inventory restocked 🎉'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showPurchaseConfirmation(ProductOfferModel offer) async {
    final recorded = await PurchaseConfirmationDialog.show(
      context: context,
      offer: offer,
      shoppingItemId: widget.itemId,
      inventoryItemId: widget.inventoryItemId,
      itemName: widget.itemName,
      defaultQuantity: widget.quantity,
      unit: widget.unit,
    );

    if (recorded == true && mounted) {
      Navigator.of(context).pop(); // Back to shopping list
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Purchase recorded! Inventory restocked 🎉'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
