import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/homestock/homestock_app_bar.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../home_switcher/home_controller.dart';
import '../shopping/shopping_controller.dart';
import 'basket_purchase_confirmation_dialog.dart';
import 'local_purchase_dialog.dart';
import 'product_match_review_sheet.dart';
import 'purchase_confirmation_dialog.dart';
import 'smart_shopping_controller.dart';
import 'smart_shopping_models.dart';

/// Smart Shopping multi-provider price comparison screen.
/// Supports both multi-item basket optimization (Option A split vs Option B single store)
/// and single-item deal comparison, with duplicate warnings and affiliate transparency.
class SmartShoppingScreen extends ConsumerStatefulWidget {
  final List<String>? itemIds;
  final String? itemId;
  final String? inventoryItemId;
  final String? itemName;
  final double? quantity;
  final String? unit;

  const SmartShoppingScreen({
    super.key,
    this.itemIds,
    this.itemId,
    this.inventoryItemId,
    this.itemName,
    this.quantity,
    this.unit,
  });

  bool get isBasketMode => (itemIds != null && itemIds!.isNotEmpty) || (itemId == null);

  @override
  ConsumerState<SmartShoppingScreen> createState() => _SmartShoppingScreenState();
}

class _SmartShoppingScreenState extends ConsumerState<SmartShoppingScreen> {
  late List<String> _activeItemIds;

  @override
  void initState() {
    super.initState();
    _activeItemIds = widget.itemIds != null ? List.from(widget.itemIds!) : [];

    Future.microtask(() {
      final homeId = ref.read(homeControllerProvider).activeHome?.id;
      if (homeId != null) {
        if (widget.itemIds != null && widget.itemIds!.isNotEmpty) {
          ref.read(smartShoppingControllerProvider.notifier).fetchBasketComparison(
                homeId,
                itemIds: _activeItemIds,
              );
        } else if (widget.itemId != null) {
          ref.read(smartShoppingControllerProvider.notifier).fetchOffers(homeId, widget.itemId!);
        } else {
          // Open for all pending shopping items automatically
          final pending = ref.read(shoppingControllerProvider).list?.items
              .where((i) => !i.isCompleted)
              .map((i) => i.id)
              .toList() ?? [];
          if (pending.isNotEmpty) {
            setState(() => _activeItemIds = pending);
            ref.read(smartShoppingControllerProvider.notifier).fetchBasketComparison(
                  homeId,
                  itemIds: pending,
                );
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(smartShoppingControllerProvider);
    final homeId = ref.watch(homeControllerProvider).activeHome?.id ?? '';

    final title = widget.isBasketMode ? 'Basket Price Optimizer' : 'Compare Prices';
    final subtitle = widget.isBasketMode
        ? '${_activeItemIds.length} items from your shopping list'
        : '${widget.itemName ?? 'Item'} • ${widget.quantity != null ? (widget.quantity == widget.quantity!.roundToDouble() ? widget.quantity!.toInt() : widget.quantity) : ''} ${widget.unit ?? ''}';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: HomeStockAppBar(
        title: title,
        subtitle: subtitle,
      ),
      body: state.isLoading
          ? _buildLoadingState()
          : state.errorMessage != null
              ? _buildErrorState(state, homeId)
              : widget.isBasketMode
                  ? _buildBasketView(state, homeId)
                  : (state.result != null
                      ? _buildSingleItemView(state.result!, homeId)
                      : _buildEmptyState()),
    );
  }

  // ──── Basket Mode View ────

  Widget _buildBasketView(SmartShoppingState state, String homeId) {
    final basket = state.basketResult;
    if (basket == null || basket.options.isEmpty) {
      return _buildEmptyState(message: 'No price offers found for selected basket items.');
    }

    final activeWarnings = basket.duplicateWarnings
        .where((w) => !state.dismissedWarnings.contains(w.shoppingItemId))
        .toList();

    // Selected basket option
    final selectedOption = basket.options.firstWhere(
      (opt) => opt.optionType == state.selectedOptionType,
      orElse: () => basket.options.first,
    );

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // 1. Duplicate Warnings Banner
              if (activeWarnings.isNotEmpty) ...[
                _buildDuplicateWarningsBanner(activeWarnings),
                const SizedBox(height: AppSpacing.md),
              ],

              // 2. Option Selection Tabs (Option A Split vs Option B Single Store)
              _buildBasketOptionTabs(basket.options, state.selectedOptionType),
              const SizedBox(height: AppSpacing.md),

              // 3. Tradeoff / Recommendation Explanation Card
              _buildRecommendationCard(selectedOption),
              const SizedBox(height: AppSpacing.md),

              // 4. Per-Item breakdown in current option
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Items in this basket (${selectedOption.items.length})',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Delivery: ${selectedOption.deliveryFeesTotal == 0 ? "FREE" : "₹${selectedOption.deliveryFeesTotal.toStringAsFixed(0)}"}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selectedOption.deliveryFeesTotal == 0
                          ? const Color(0xFF16A34A)
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              ...selectedOption.items.map((item) => _buildBasketItemCard(item, homeId)),

              const SizedBox(height: AppSpacing.md),

              // 5. Affiliate Disclosure & Price Freshness Note
              _buildAffiliateDisclosureCard(),
              const SizedBox(height: 80), // bottom bar spacing
            ],
          ),
        ),

        // 6. Bottom Sticky Action Bar
        _buildBottomActionBar(selectedOption, homeId),
      ],
    );
  }

  Widget _buildDuplicateWarningsBanner(List<DuplicateWarningModel> warnings) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 18),
              const SizedBox(width: 8),
              Text(
                'Duplicate Purchase Warning (${warnings.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Color(0xFF92400E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...warnings.map((w) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        w.message,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF78350F)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        ref.read(smartShoppingControllerProvider.notifier).dismissWarning(w.shoppingItemId);
                      },
                      child: const Text(
                        'Buy anyway',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildBasketOptionTabs(List<BasketOptionModel> options, String? selectedType) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: options.map((opt) {
          final isSelected = opt.optionType == selectedType ||
              (selectedType == null && opt == options.first);

          return Expanded(
            child: GestureDetector(
              onTap: () {
                ref.read(smartShoppingControllerProvider.notifier).selectBasketOption(opt.optionType);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  children: [
                    Text(
                      opt.isSplit ? '⚡ Split Stores' : '🏪 ${opt.storeName}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${opt.netTotal.toStringAsFixed(0)} total',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecommendationCard(BasketOptionModel option) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.lightbulb_outline_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 3),
                Text(
                  option.recommendationReason ??
                      'Calculated using real-time prices, store delivery thresholds, and inventory needs.',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                if (option.potentialSavings > 0) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Saves ₹${option.potentialSavings.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF15803D),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasketItemCard(BasketItemModel item, String homeId) {
    final isExact = item.matchType == 'EXACT';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          // Store badge
          Container(
            width: 50,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              item.provider ?? 'Store',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productTitle ?? item.itemName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '${item.quantity == item.quantity.roundToDouble() ? item.quantity.toInt() : item.quantity} ${item.unit}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    if (item.pricePerUnitLabel != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        '(${item.pricePerUnitLabel})',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                    const SizedBox(width: 6),
                    _buildFreshnessDot(item.freshness),
                  ],
                ),
              ],
            ),
          ),

          // Price & Match Review
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${item.price.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              if (!isExact)
                GestureDetector(
                  onTap: () {
                    ProductMatchReviewSheet.show(
                      context: context,
                      queryItemName: item.itemName,
                      offer: ProductOfferModel(
                        provider: item.provider ?? '',
                        providerProductId: item.providerProductId ?? '',
                        productName: item.productTitle ?? item.itemName,
                        price: item.price,
                        effectivePrice: item.effectivePrice,
                        matchConfidence: item.matchConfidence,
                        matchType: item.matchType,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Similar', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFB45309))),
                        Icon(Icons.chevron_right_rounded, size: 12, color: Color(0xFFB45309)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFreshnessDot(String? freshness) {
    Color dotColor;
    String tip;
    if (freshness == 'FRESH') {
      dotColor = const Color(0xFF22C55E);
      tip = 'Price verified <15m ago';
    } else if (freshness == 'RECENT') {
      dotColor = const Color(0xFFF59E0B);
      tip = 'Price verified <1h ago';
    } else {
      dotColor = const Color(0xFF9CA3AF);
      tip = 'Cached benchmark price';
    }

    return Tooltip(
      message: tip,
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: dotColor,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildAffiliateDisclosureCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, size: 16, color: AppColors.textSecondary),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Prices and availability are subject to store changes. HomeStock does not mark up prices and may earn an affiliate commission on qualifying purchases at no extra cost to you.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(BasketOptionModel option, String homeId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 4),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Basket Total', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                Text(
                  '₹${option.netTotal.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary),
                ),
              ],
            ),
            const Spacer(),

            // Proceed / Restock button
            ElevatedButton.icon(
              onPressed: () => _handleBasketCheckout(option, homeId),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 18),
              label: const Text(
                'Proceed & Restock',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleBasketCheckout(BasketOptionModel option, String homeId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Shop ${option.title}'),
        content: Text(
          'This will open official partner links for ${option.items.length} product(s) on ${option.storeName}.\n\nWhen done, confirm below to automatically restock your inventory and update consumption forecasts.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // Open record restock dialog directly
              BasketPurchaseConfirmationDialog.show(
                context: context,
                basketOption: option,
              );
            },
            child: const Text('Record Restock Only'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.of(ctx).pop();

              // Open the first item's link
              final firstItem = option.items.first;
              if (firstItem.affiliateUrl != null || firstItem.productUrl != null) {
                await ref.read(smartShoppingControllerProvider.notifier).openAffiliateLink(
                  homeId: homeId,
                  shoppingItemId: firstItem.shoppingItemId,
                  provider: firstItem.provider ?? 'Store',
                  providerProductId: firstItem.providerProductId ?? '',
                  fallbackUrl: firstItem.productUrl,
                  sourceScreen: 'BASKET_CHECKOUT',
                );
              }

              if (mounted) {
                // Prompt purchase restock
                BasketPurchaseConfirmationDialog.show(
                  context: context,
                  basketOption: option,
                );
              }
            },
            child: const Text('Continue to Store'),
          ),
        ],
      ),
    );
  }

  // ──── Single Item Mode View ────

  Widget _buildSingleItemView(PriceComparisonResult result, String homeId) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _buildItemHeader(),
        const SizedBox(height: AppSpacing.md),

        if (result.offers.isNotEmpty) ...[
          _buildBestDealBanner(result.bestOffer!),
          const SizedBox(height: AppSpacing.md),
        ],

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Online Stores',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            if (result.savingsLabel != null)
              Text(
                result.savingsLabel!,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF16A34A)),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        ...result.offers.map((offer) => _buildOfferCard(offer, homeId)),

        const SizedBox(height: AppSpacing.md),
        _buildLocalStoreOption(result.localEstimate, homeId),
        const SizedBox(height: AppSpacing.md),
        _buildAffiliateDisclosureCard(),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  Widget _buildItemHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.itemName ?? 'Item',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Text(
                  'Desired Quantity: ${widget.quantity ?? 1} ${widget.unit ?? "pcs"}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBestDealBanner(ProductOfferModel best) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Best Value Deal',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF15803D)),
                ),
                Text(
                  '${best.productName} on ${best.provider} • ₹${best.effectivePrice.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF166534)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCard(ProductOfferModel offer, String homeId) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                offer.provider,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const Spacer(),
              Text(
                '₹${offer.effectivePrice.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            offer.productName,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                offer.deliveryText,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              if (offer.pricePerUnitLabel != null) ...[
                const SizedBox(width: 8),
                Text(
                  '• ${offer.pricePerUnitLabel}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
              const Spacer(),
              OutlinedButton(
                onPressed: () {
                  ref.read(smartShoppingControllerProvider.notifier).openAffiliateLink(
                    homeId: homeId,
                    shoppingItemId: widget.itemId ?? '',
                    provider: offer.provider,
                    providerProductId: offer.providerProductId,
                    fallbackUrl: offer.productUrl,
                    sourceScreen: 'SINGLE_ITEM_COMPARISON',
                  );

                  PurchaseConfirmationDialog.show(
                    context: context,
                    offer: offer,
                    shoppingItemId: widget.itemId ?? '',
                    inventoryItemId: widget.inventoryItemId,
                    itemName: widget.itemName ?? '',
                    defaultQuantity: widget.quantity ?? 1,
                    unit: widget.unit ?? 'pcs',
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('View Deal', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocalStoreOption(LocalEstimateModel? estimate, String homeId) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          const Icon(Icons.storefront_rounded, color: AppColors.textSecondary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Local / Physical Store', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                Text(
                  estimate?.priceRangeLabel ?? 'Report price to track offline trends',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              LocalPurchaseDialog.show(
                context: context,
                shoppingItemId: widget.itemId ?? '',
                inventoryItemId: widget.inventoryItemId,
                itemName: widget.itemName ?? '',
                defaultQuantity: widget.quantity ?? 1,
                unit: widget.unit ?? 'pcs',
              );
            },
            child: const Text('Record Price'),
          ),
        ],
      ),
    );
  }

  // ──── States ────

  Widget _buildLoadingState() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _buildItemHeader(),
        const SizedBox(height: AppSpacing.md),
        ...List.generate(3, (i) => const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
              child: SkeletonItemCard(),
            )),
      ],
    );
  }

  Widget _buildErrorState(SmartShoppingState state, String homeId) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              state.isOffline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              state.errorMessage ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () {
                if (widget.isBasketMode) {
                  ref.read(smartShoppingControllerProvider.notifier).fetchBasketComparison(
                        homeId,
                        itemIds: _activeItemIds,
                      );
                } else if (widget.itemId != null) {
                  ref.read(smartShoppingControllerProvider.notifier).fetchOffers(homeId, widget.itemId!);
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({String? message}) {
    return EmptyStateView(
      icon: Icons.search_off_rounded,
      title: 'No Deals Found',
      message: message ?? 'No matching product offers found. Try updating the item name or checking local stores.',
    );
  }
}
