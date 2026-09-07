import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/homestock/homestock_app_bar.dart';
import '../../core/widgets/homestock/homestock_card.dart';
import '../../core/widgets/homestock/homestock_pill_badge.dart';
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
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: HomeStockAppBar(
        title: 'Compare Prices',
        subtitle: '${widget.itemName} • ${widget.quantity == widget.quantity.roundToDouble() ? widget.quantity.toInt() : widget.quantity} ${widget.unit}',
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
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
          const SizedBox(height: AppSpacing.md),

          // Provider status warnings
          if (result.failedProviderCount > 0)
            _buildProviderWarnings(result),

          // Best Deal
          if (result.bestOffer != null) ...[
            _buildBestDealCard(result.bestOffer!, homeId, result.shoppingItem.id),
            const SizedBox(height: AppSpacing.md),
          ],

          // Other offers
          if (otherOffers.isNotEmpty) ...[
            _buildSectionLabel('Other store options'),
            const SizedBox(height: AppSpacing.sm),
            ...otherOffers.map((offer) =>
                _buildOfferCard(offer, homeId, result.shoppingItem.id)),
            const SizedBox(height: AppSpacing.md),
          ],

          // Savings label banner
          if (result.savingsLabel != null) ...[
            HomeStockCard(
              backgroundColor: AppColors.hsGreenBg,
              borderColor: AppColors.hsGreen.withValues(alpha: 0.4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.savings_outlined, color: AppColors.hsGreen, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      result.savingsLabel!,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.hsGreen),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Local purchase option
          _buildLocalPurchaseCard(),
          const SizedBox(height: AppSpacing.lg),

          // Affiliate disclosure
          _buildAffiliateDisclosure(),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  // ──── Components ────

  Widget _buildItemHeader() {
    return HomeStockCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outline.withValues(alpha: 0.6)),
            ),
            child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.itemName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  'Quantity Needed: ${widget.quantity == widget.quantity.roundToDouble() ? widget.quantity.toInt() : widget.quantity} ${widget.unit}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
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
          color: AppColors.hsYellowBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.hsYellow.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.hsYellow),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                '${failed.map((f) => f.provider).join(', ')} temporarily unavailable',
                style: const TextStyle(fontSize: 12, color: Color(0xFF92400E), fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBestDealCard(ProductOfferModel offer, String homeId, String itemId) {
    return HomeStockCard(
      borderColor: AppColors.hsGreen.withValues(alpha: 0.5),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Best deal header strip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.hsGreenBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(color: AppColors.hsGreen.withValues(alpha: 0.2)),
              ),
            ),
            child: const Row(
              children: [
                Text('🏆', style: TextStyle(fontSize: 15)),
                SizedBox(width: 8),
                Text(
                  'Best Online Deal',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.hsGreen),
                ),
                Spacer(),
                HomeStockPillBadge(
                  label: 'Lowest Price',
                  variant: HomeStockPillVariant.green,
                  fontSize: 10,
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      offer.provider,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                    if (offer.isFreeDelivery)
                      const HomeStockPillBadge(
                        label: 'Free Delivery',
                        variant: HomeStockPillVariant.purple,
                        fontSize: 10,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  offer.productName,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Price and delivery
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${offer.effectivePrice.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: 8),
                    if (offer.pricePerUnitLabel != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          offer.pricePerUnitLabel!,
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(Icons.bolt_rounded, size: 16, color: AppColors.hsYellow),
                    const SizedBox(width: 4),
                    Text(
                      offer.deliveryText,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => _onBuyOnline(offer, homeId, itemId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                      elevation: 1,
                    ),
                    child: const Text('Buy Online Now', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
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
    return HomeStockCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                offer.provider,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
              ),
              if (offer.isFreeDelivery)
                const HomeStockPillBadge(
                  label: 'Free Delivery',
                  variant: HomeStockPillVariant.neutral,
                  fontSize: 10,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            offer.productName,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '₹${offer.effectivePrice.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  if (offer.pricePerUnitLabel != null)
                    Text(
                      offer.pricePerUnitLabel!,
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                ],
              ),
              ElevatedButton(
                onPressed: () => _onBuyOnline(offer, homeId, itemId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                ),
                child: const Text('Select', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocalPurchaseCard() {
    return HomeStockCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.storefront_rounded, size: 20, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Nearby Grocery Store',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Prefer buying from a local shop? Record your purchase to restock inventory.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: _onBuyLocally,
              icon: const Icon(Icons.receipt_long_rounded, size: 18),
              label: const Text('Record Local Store Purchase', style: TextStyle(fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
              ),
            ),
          ),
        ],
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
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
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
      Navigator.of(context).pop();
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
