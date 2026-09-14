import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/homestock/homestock_app_bar.dart';
import '../home_switcher/home_controller.dart';
import '../shopping/shopping_controller.dart';
import '../shopping/shopping_model.dart';
import 'deal_search_models.dart';
import 'location_deals_controller.dart';
import 'location_deals_models.dart';
import 'location_service.dart';
import 'nearby_grocery_shops_screen.dart';
import 'nearby_shop_detail_screen.dart';
import 'product_deal_controller.dart';
import 'widgets/manual_location_dialog.dart';
import 'widgets/shop_radar_map_view.dart';
import '../voice/widgets/voice_input_button.dart';
import '../voice/widgets/voice_bottom_sheet.dart';
import '../voice/services/ai_voice_service.dart';
import '../../core/capabilities/capability_provider.dart';
import '../../core/capabilities/feature_capability.dart';

/// Screen for Real-World Product Deal Search.
/// Supports both generic intent discovery ("Oil", "Rice", "Milk", "samayal ennai")
/// and exact brand/variant/barcode lookups with multi-store comparison.
class ProductDealSearchScreen extends ConsumerStatefulWidget {
  final String? initialQuery;
  final String? initialItemId;
  final String? initialBarcode;
  final String? initialBrand;
  final String? initialUnit;

  const ProductDealSearchScreen({
    super.key,
    this.initialQuery,
    this.initialItemId,
    this.initialBarcode,
    this.initialBrand,
    this.initialUnit,
  });

  @override
  ConsumerState<ProductDealSearchScreen> createState() =>
      _ProductDealSearchScreenState();
}

class _ProductDealSearchScreenState
    extends ConsumerState<ProductDealSearchScreen> {
  late final TextEditingController _searchController;
  final ScrollController _scrollController = ScrollController();

  static const List<String> _quickStaples = [
    'Oil',
    'Rice',
    'Milk',
    'Atta',
    'Sugar',
    'Toor Dal',
    'Detergent',
    'Toothpaste',
    'Soap',
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery ?? '');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSearch();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initSearch() {
    final homeId = ref.read(homeControllerProvider).activeHome?.id;
    if (homeId == null) return;

    final controller = ref.read(productDealControllerProvider.notifier);

    if (widget.initialItemId != null) {
      controller.loadListItemDeals(
        homeId: homeId,
        itemId: widget.initialItemId!,
        initialItemName: widget.initialQuery,
      );
    } else {
      final query = (widget.initialQuery?.isNotEmpty ?? false)
          ? widget.initialQuery!
          : 'Oil';
      _searchController.text = query;
      controller.searchDeals(
        homeId: homeId,
        query: query,
        barcode: widget.initialBarcode,
        brand: widget.initialBrand,
        unit: widget.initialUnit,
        resetFilters: true,
      );
    }
  }

  void _performSearch(String query) {
    final homeId = ref.read(homeControllerProvider).activeHome?.id;
    if (homeId == null) return;

    FocusScope.of(context).unfocus();
    ref.read(productDealControllerProvider.notifier).searchDeals(
          homeId: homeId,
          query: query.trim(),
          resetFilters: true,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productDealControllerProvider);
    final controller = ref.read(productDealControllerProvider.notifier);
    final locState = ref.watch(locationDealsControllerProvider);
    final locController = ref.read(locationDealsControllerProvider.notifier);
    final coreLocState = ref.watch(locationControllerProvider);
    final coreLocNotifier = ref.read(locationControllerProvider.notifier);
    final hsColors = context.hsColors;

    return Scaffold(
      backgroundColor: hsColors.background,
      appBar: HomeStockAppBar(
        title: _searchController.text.isNotEmpty
            ? 'Deals: ${_searchController.text}'
            : 'Real-World Deals',
        subtitle: 'Compare real market prices across stores',
        actions: [
          if (ref.watch(isCapabilityAvailableProvider(FeatureCapability.nearbyShops)))
            IconButton(
              icon: const Icon(Icons.storefront_rounded, color: Color(0xFF10B981)),
              tooltip: 'Nearby Grocery Shops',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NearbyGroceryShopsScreen()),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Location Bar (📍 Mettur [Change] | 5 KM ▼ | [List] [Map])
            _buildLocationBar(locState, locController, coreLocState, coreLocNotifier, hsColors),

            // 1b. Location Status / Warning Banner
            LocationStatusBanner(
              state: coreLocState,
              onTryAgain: () async {
                final granted = await coreLocNotifier.requestPermissionAndAcquire();
                if (granted) {
                  final loc = ref.read(locationControllerProvider).currentLocation;
                  if (loc != null) {
                    locController.setLocation(loc.toUserLocationContext());
                  }
                }
              },
              onOpenSettings: () => coreLocNotifier.openAppSettings(),
              onOpenLocationSettings: () => coreLocNotifier.openLocationSettings(),
              onChooseManually: () async {
                final selected = await showDialog<UserLocationContext>(
                  context: context,
                  builder: (_) => ManualLocationDialog(
                    currentContext: locState.location,
                    onSearchAreas: (q) => locController.searchAreas(q),
                  ),
                );
                if (selected != null) {
                  locController.setLocation(selected);
                  coreLocNotifier.setManualLocation(selected.toLocationResult());
                }
              },
            ),

            // 2. Shopping List Intelligence Banner
            _buildShoppingListIntelligenceBanner(context, locState, locController, hsColors),

            // 3. Search Bar & Quick Categories
            _buildSearchBar(hsColors, locController),

            // 4. Content Area
            Expanded(
              child: locState.viewMode == DealsViewMode.map
                  ? ListView(
                      children: [
                        const SizedBox(height: 12),
                        ShopRadarMapView(
                          shops: locState.nearbyShops,
                          radiusKm: locState.radiusKm,
                          locationLabel: locState.location.displayLabel,
                        ),
                      ],
                    )
                  : RefreshIndicator(
                      color: hsColors.primary,
                      onRefresh: () async {
                        final homeId = ref.read(homeControllerProvider).activeHome?.id;
                        if (homeId != null) {
                          await controller.searchDeals(homeId: homeId);
                        }
                        await locController.loadNearbyShops();
                      },
                      child: _buildBody(state, controller, hsColors),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(
      HomeStockThemeColors hsColors, LocationDealsController locController) {
    return Container(
      color: hsColors.surface,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Input Field
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: hsColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: hsColors.outline, width: 1),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(Icons.search_rounded,
                    color: hsColors.primary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search generic item or brand (e.g. Oil, Rice, Surf)',
                      hintStyle: TextStyle(
                          color: AppColors.textMuted, fontSize: 14),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (val) {
                      if (val.trim().isNotEmpty) {
                        _performSearch(val);
                      }
                    },
                  ),
                ),
                VoiceInputButton(
                  size: 20,
                  color: hsColors.primary,
                  tooltip: 'Voice search deals',
                  onSearch: (query) {
                    _searchController.text = query;
                    _performSearch(query);
                  },
                ),
                IconButton(
                  tooltip: 'Voice & Tanglish Deal Finder',
                  icon: Icon(Icons.chat_bubble_outline_rounded, color: hsColors.primary, size: 20),
                  onPressed: () => _openVoiceSearchDialog(context, locController, hsColors),
                ),
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        size: 18, color: AppColors.textMuted),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  ),
                IconButton(
                  icon: Icon(Icons.arrow_forward_rounded,
                      color: hsColors.primary, size: 20),
                  onPressed: () {
                    if (_searchController.text.trim().isNotEmpty) {
                      _performSearch(_searchController.text);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Quick Staples Pills
          SizedBox(
            height: 28,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _quickStaples.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                final staple = _quickStaples[i];
                final isSelected = _searchController.text
                    .trim()
                    .toLowerCase() ==
                    staple.toLowerCase();
                return InkWell(
                  onTap: () {
                    _searchController.text = staple;
                    _performSearch(staple);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? hsColors.primaryContainer
                          : hsColors.surfaceVariant.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? hsColors.primary
                            : hsColors.outline.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      staple,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? hsColors.primaryDark
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ProductDealState state, ProductDealController controller,
      HomeStockThemeColors hsColors) {
    if (state.isLoading && state.response == null) {
      return _buildLoadingState(hsColors);
    }

    if (state.errorMessage != null && state.response == null) {
      return _buildErrorState(state.errorMessage!, hsColors);
    }

    final response = state.response;
    if (response == null || response.products.isEmpty) {
      return _buildEmptyState(hsColors);
    }

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        // Mode Header & AI Insight Banner
        _buildAiInsightBanner(response, hsColors),

        // 3 Highlight Badges (Lowest Price, Best Value, Popular)
        _buildHighlightCards(response.highlights, hsColors),

        // Dynamic Filters (Subtype, Brand, Pack Size, Sort)
        _buildFilterBar(response.filters, state, controller, hsColors),

        // Deals List Header
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available Deals (${response.products.length})',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (state.selectedSubtype != null ||
                  state.selectedBrand != null ||
                  state.selectedPackSize != null)
                GestureDetector(
                  onTap: () => controller.clearFilters(),
                  child: Text(
                    'Reset Filters',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: hsColors.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Products List
        ...response.products.map(
          (deal) => _buildProductDealCard(deal, controller, hsColors),
        ),
      ],
    );
  }

  Widget _buildAiInsightBanner(
      ProductDealSearchResponse response, HomeStockThemeColors hsColors) {
    final intent = response.intent;
    final summary = response.summary;

    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            hsColors.primaryContainer.withValues(alpha: 0.7),
            const Color(0xFFE0F2FE).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hsColors.primaryLight.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Intent Tag
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: intent.isExactMode
                      ? AppColors.secondaryContainer
                      : hsColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      intent.isExactMode
                          ? Icons.track_changes_rounded
                          : Icons.auto_awesome_rounded,
                      size: 13,
                      color: intent.isExactMode
                          ? AppColors.secondaryDark
                          : hsColors.primaryDark,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      intent.isExactMode
                          ? 'EXACT PRODUCT MATCH'
                          : 'GENERIC DISCOVERY: ${intent.primaryCategory.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: intent.isExactMode
                            ? AppColors.secondaryDark
                            : hsColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (summary.priceRangeMin != null &&
                  summary.priceRangeMax != null)
                Text(
                  '₹${summary.priceRangeMin!.toStringAsFixed(0)} - ₹${summary.priceRangeMax!.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // AI Insight Text + Listen button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  summary.aiRecommendation,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.volume_up_rounded, size: 20, color: AppColors.primary),
                tooltip: 'Listen to deal summary',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () {
                  ref.read(aiVoiceServiceProvider.notifier).play(
                        text: summary.aiRecommendation,
                        language: 'EN',
                        isVoiceInteraction: true,
                      );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Verified Stores Footnote
          Row(
            children: [
              const Icon(Icons.verified_outlined,
                  size: 14, color: AppColors.inStockText),
              const SizedBox(width: 4),
              const Text(
                'Live comparisons across ',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              _buildStoreDot('JioMart', const Color(0xFF0078AD)),
              _buildStoreDot('BigBasket', const Color(0xFF689F38)),
              _buildStoreDot('Blinkit', const Color(0xFFD97706)),
              _buildStoreDot('Amazon', const Color(0xFFFF9900)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStoreDot(String name, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 2),
          Text(
            name,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightCards(
      DealHighlights highlights, HomeStockThemeColors hsColors) {
    final lowest = highlights.lowestPrice;
    final bestVal = highlights.bestValue;
    final pop = highlights.popular;

    if (lowest == null && bestVal == null && pop == null) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 108,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (lowest != null)
            _buildHighlightBadgeCard(
              title: 'Lowest Price',
              badge: '🏆 CHEAPEST',
              badgeColor: const Color(0xFFD97706),
              badgeBg: const Color(0xFFFFFBEB),
              primaryText: '₹${lowest.bestPrice.toStringAsFixed(0)}',
              secondaryText: '${lowest.brand ?? ''} (${lowest.packageSize ?? ''})',
              storeText: 'on ${lowest.bestProvider}',
              deal: lowest,
            ),
          if (bestVal != null)
            _buildHighlightBadgeCard(
              title: 'Best Value',
              badge: '⭐ TOP VALUE',
              badgeColor: const Color(0xFF059669),
              badgeBg: const Color(0xFFECFDF5),
              primaryText: bestVal.unitPriceLabel ?? '₹${bestVal.bestPrice.toStringAsFixed(0)}',
              secondaryText: '${bestVal.brand ?? ''} (${bestVal.packageSize ?? ''})',
              storeText: 'Bulk value on ${bestVal.bestProvider}',
              deal: bestVal,
            ),
          if (pop != null)
            _buildHighlightBadgeCard(
              title: 'Most Popular',
              badge: '🔥 POPULAR',
              badgeColor: hsColors.primary,
              badgeBg: hsColors.primaryContainer,
              primaryText: '★ ${pop.rating?.toStringAsFixed(1) ?? '4.5'}',
              secondaryText: '${pop.brand ?? ''} (${pop.reviewCount ?? 1000}+ reviews)',
              storeText: 'Loved on ${pop.bestProvider}',
              deal: pop,
            ),
        ],
      ),
    );
  }

  Widget _buildHighlightBadgeCard({
    required String title,
    required String badge,
    required Color badgeColor,
    required Color badgeBg,
    required String primaryText,
    required String secondaryText,
    required String storeText,
    required ProductDeal deal,
  }) {
    return Container(
      width: 175,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: badgeColor,
                  ),
                ),
              ),
              Icon(Icons.north_east_rounded, size: 12, color: badgeColor),
            ],
          ),
          Text(
            primaryText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: badgeColor,
            ),
          ),
          Text(
            secondaryText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            storeText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(DealFilters filters, ProductDealState state,
      ProductDealController controller, HomeStockThemeColors hsColors) {
    final types = filters.availableTypes;
    final brands = filters.availableBrands;
    final packSizes = filters.availablePackSizes;

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtypes row
          if (types.isNotEmpty)
            _buildHorizontalChipList(
              items: types,
              selectedKey: state.selectedSubtype,
              onSelect: (k) => controller.selectSubtype(k),
              hsColors: hsColors,
              prefix: 'Type: ',
            ),

          // Brands row
          if (brands.isNotEmpty)
            _buildHorizontalChipList(
              items: brands,
              selectedKey: state.selectedBrand,
              onSelect: (k) => controller.selectBrand(k),
              hsColors: hsColors,
              prefix: 'Brand: ',
            ),

          // Pack Sizes row
          if (packSizes.isNotEmpty)
            _buildHorizontalChipList(
              items: packSizes,
              selectedKey: state.selectedPackSize,
              onSelect: (k) => controller.selectPackSize(k),
              hsColors: hsColors,
              prefix: 'Size: ',
            ),

          // Sort Chips Row
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 4, AppSpacing.md, 0),
            child: Row(
              children: [
                const Icon(Icons.sort_rounded, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                const Text('Sort: ',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary)),
                _buildSortChip('Best Value', 'best_value', state.selectedSort, controller, hsColors),
                const SizedBox(width: 6),
                _buildSortChip('Lowest Price', 'lowest_price', state.selectedSort, controller, hsColors),
                const SizedBox(width: 6),
                _buildSortChip('Highest Savings', 'highest_saving', state.selectedSort, controller, hsColors),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalChipList({
    required List<FilterOption> items,
    required String? selectedKey,
    required ValueChanged<String?> onSelect,
    required HomeStockThemeColors hsColors,
    required String prefix,
  }) {
    return Container(
      height: 32,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final opt = items[i];
          final isSelected = selectedKey != null &&
              selectedKey.toLowerCase() == opt.key.toLowerCase();

          return ChoiceChip(
            label: Text('$prefix${opt.label} (${opt.count})'),
            selected: isSelected,
            onSelected: (_) => onSelect(opt.key),
            selectedColor: hsColors.primaryContainer,
            backgroundColor: hsColors.surface,
            labelStyle: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? hsColors.primaryDark : AppColors.textSecondary,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isSelected
                    ? hsColors.primary
                    : hsColors.outline.withValues(alpha: 0.6),
                width: 1,
              ),
            ),
            showCheckmark: false,
          );
        },
      ),
    );
  }

  Widget _buildSortChip(String label, String sortKey, String activeSort,
      ProductDealController controller, HomeStockThemeColors hsColors) {
    final isSelected = activeSort == sortKey;
    return GestureDetector(
      onTap: () => controller.setSort(isSelected ? 'default' : sortKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? hsColors.primaryDark : hsColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? hsColors.primaryDark : hsColors.outline,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildProductDealCard(ProductDeal deal, ProductDealController controller,
      HomeStockThemeColors hsColors) {
    final bestStore = deal.bestProvider;
    final storeOffers = deal.storeOffers;

    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: deal.isBestValue
              ? const Color(0xFF059669).withValues(alpha: 0.4)
              : deal.isLowestPrice
                  ? const Color(0xFFD97706).withValues(alpha: 0.4)
                  : hsColors.outline.withValues(alpha: 0.6),
          width: deal.isBestValue || deal.isLowestPrice ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: deal.isBestValue
                  ? const Color(0xFFECFDF5)
                  : deal.isLowestPrice
                      ? const Color(0xFFFFFBEB)
                      : hsColors.surfaceVariant,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                if (deal.isExactMatch)
                  _buildPillBadge('✓ EXACT MATCH', const Color(0xFF047857), const Color(0xFFD1FAE5))
                else
                  _buildPillBadge('SIMILAR', const Color(0xFF4B5563), const Color(0xFFF3F4F6)),
                if (deal.isLowestPrice || deal.isBestValue)
                  _buildPillBadge('✓ BEST PRICE', const Color(0xFFD97706), const Color(0xFFFEF3C7)),
                if (deal.validationStatus == 'PRICE_CHANGED')
                  _buildPillBadge('PRICE CHANGED', const Color(0xFF2563EB), const Color(0xFFDBEAFE)),
                if (deal.isOutOfStock)
                  _buildPillBadge('OUT OF STOCK', const Color(0xFFDC2626), const Color(0xFFFEE2E2))
                else
                  _buildPillBadge('✓ IN STOCK', const Color(0xFF059669), Colors.transparent),
                const Spacer(),
                if (deal.isStale)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFFD97706)),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Checking latest price...',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ],
                  )
                else if (deal.freshnessLabel != null)
                  Text(
                    deal.freshnessLabel!,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  )
                else if (deal.savingsVsHighest != null &&
                    deal.savingsVsHighest! > 0 &&
                    deal.comparisonStore != null)
                  Text(
                    'Save ₹${deal.savingsVsHighest!.toStringAsFixed(0)} vs ${deal.comparisonStore}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF059669),
                    ),
                  ),
              ],
            ),
          ),

          // Main Details
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Icon / Avatar
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: hsColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getCategoryIcon(deal.category),
                        color: hsColors.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Info Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (deal.brand != null)
                                Text(
                                  deal.brand!.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: hsColors.primaryDark,
                                  ),
                                ),
                              if (deal.variantType != null) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondaryContainer,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    deal.variantType!,
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.secondaryDark,
                                    ),
                                  ),
                                ),
                              ],
                              const Spacer(),
                              if (deal.packageSize != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: hsColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: hsColors.outline, width: 0.8),
                                  ),
                                  child: Text(
                                    deal.packageSize!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            deal.productName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Price & Best Store Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${deal.bestPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (deal.mrp != null && deal.mrp! > deal.bestPrice) ...[
                      const SizedBox(width: 8),
                      Text(
                        '₹${deal.mrp!.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.lineThrough,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                    if (deal.unitPriceLabel != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          deal.unitPriceLabel!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    _buildStoreChip(bestStore),
                  ],
                ),
                const SizedBox(height: 12),

                // Cross-Store Comparison Breakdown
                if (storeOffers.isNotEmpty) ...[
                  const Divider(height: 1, thickness: 0.8),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        'Cross-Store Availability:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                      if (storeOffers.length > 1) ...[
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: hsColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${storeOffers.length - 1} other store${storeOffers.length > 2 ? 's' : ''}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...storeOffers.map((offer) => _buildStoreOfferRow(offer, deal, controller, hsColors)),
                ],

                const SizedBox(height: 12),

                // View Deal Action Button (Section 41, 49, 50, 51, 54, 55)
                Builder(
                  builder: (context) {
                    final directUrl = deal.canonicalProductUrl ?? deal.productUrl;
                    final isExplicitlyUnavailable = !deal.directProductUrlAvailable;

                    return SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: ElevatedButton(
                        onPressed: () {
                          if (directUrl == null || isExplicitlyUnavailable) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: const [
                                    Icon(Icons.info_outline, color: Colors.white, size: 16),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text('Direct retailer product page is currently unavailable for this item.'),
                                    ),
                                  ],
                                ),
                                backgroundColor: const Color(0xFF1E293B),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                            return;
                          }
                          controller.launchDealUrl(directUrl);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isExplicitlyUnavailable ? AppColors.borderLight : hsColors.primary,
                          foregroundColor: isExplicitlyUnavailable ? AppColors.textMuted : Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isExplicitlyUnavailable ? 'Direct Link Unavailable' : 'View Deal at $bestStore',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              isExplicitlyUnavailable ? Icons.link_off_rounded : Icons.open_in_new_rounded,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreOfferRow(
      StoreOffer offer, ProductDeal deal, ProductDealController controller, HomeStockThemeColors hsColors) {
    final isCheapest = offer.price == deal.bestPrice;
    final directStoreUrl = offer.canonicalProductUrl ?? offer.productUrl;
    final hasDirectLink = offer.directProductUrlAvailable && directStoreUrl != null;

    return Builder(
      builder: (context) => InkWell(
        onTap: () {
          if (!hasDirectLink) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Direct product link is unavailable for ${offer.storeName}.'),
                duration: const Duration(seconds: 2),
              ),
            );
            return;
          }
          controller.launchDealUrl(directStoreUrl);
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Row(
            children: [
              _buildStoreDot(offer.storeName, _getStoreColor(offer.storeName)),
              const Spacer(),
              if (offer.estimatedDelivery != null)
                Text(
                  '${offer.estimatedDelivery!} • ',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              Text(
                '₹${offer.price.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isCheapest ? FontWeight.w800 : FontWeight.w600,
                  color: isCheapest ? const Color(0xFF059669) : AppColors.textPrimary,
                ),
              ),
              if (isCheapest) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'LOWEST',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF059669),
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPillBadge(String label, Color textColor, Color bgColor) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildStoreChip(String storeName) {
    final color = _getStoreColor(storeName);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        storeName,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Color _getStoreColor(String storeName) {
    final lower = storeName.toLowerCase();
    if (lower.contains('jiomart')) return const Color(0xFF0078AD);
    if (lower.contains('bigbasket')) return const Color(0xFF689F38);
    if (lower.contains('blinkit')) return const Color(0xFFD97706);
    if (lower.contains('amazon')) return const Color(0xFFEA580C);
    if (lower.contains('zepto')) return const Color(0xFF7C3AED);
    return const Color(0xFF0284C7);
  }

  IconData _getCategoryIcon(String? category) {
    if (category == null) return Icons.shopping_basket_rounded;
    final lower = category.toLowerCase();
    if (lower.contains('oil')) return Icons.opacity_rounded;
    if (lower.contains('rice') || lower.contains('grain')) return Icons.grain_rounded;
    if (lower.contains('milk') || lower.contains('dairy')) return Icons.water_drop_rounded;
    if (lower.contains('atta') || lower.contains('flour')) return Icons.bakery_dining_rounded;
    if (lower.contains('dal') || lower.contains('pulse')) return Icons.spa_rounded;
    if (lower.contains('sugar')) return Icons.eco_rounded;
    if (lower.contains('detergent') || lower.contains('clean')) return Icons.clean_hands_rounded;
    if (lower.contains('personal') || lower.contains('soap')) return Icons.soap_rounded;
    return Icons.shopping_bag_outlined;
  }

  Widget _buildLoadingState(HomeStockThemeColors hsColors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: hsColors.primary),
          const SizedBox(height: 16),
          Text(
            'Analyzing market prices across stores...',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: hsColors.primaryDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Searching BigBasket, Blinkit, JioMart, Amazon',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message, HomeStockThemeColors hsColors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final homeId = ref.read(homeControllerProvider).activeHome?.id;
                if (homeId != null) {
                  ref
                      .read(productDealControllerProvider.notifier)
                      .searchDeals(homeId: homeId);
                }
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(HomeStockThemeColors hsColors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 54, color: hsColors.primaryLight),
            const SizedBox(height: 16),
            const Text(
              'No active deals found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try searching with a generic term like "Oil", "Rice", "Milk", or "Atta" to discover products across platforms.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationBar(
    LocationDealsState locState,
    LocationDealsController locController,
    LocationState coreLocState,
    LocationController coreLocNotifier,
    HomeStockThemeColors hsColors,
  ) {
    final isManual = locState.location.isManual;
    final sourceSubtitle = isManual
        ? 'Manual location'
        : (coreLocState.currentLocation?.freshnessLabel ??
            (coreLocState.isLoading ? 'Finding location...' : 'Current location'));

    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.xs),
      decoration: BoxDecoration(
        color: hsColors.surface,
        border: Border(
          bottom: BorderSide(color: hsColors.outline.withValues(alpha: 0.4), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Location Pill
          Expanded(
            child: InkWell(
              onTap: () => _openLocationPicker(context, locController, coreLocNotifier),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: hsColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: hsColors.outline.withValues(alpha: 0.6)),
                ),
                child: Row(
                  children: [
                    Icon(
                      !isManual
                          ? Icons.my_location_rounded
                          : Icons.location_on_rounded,
                      size: 16,
                      color: isManual ? const Color(0xFFD97706) : hsColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            locState.location.displayLabel,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            sourceSubtitle,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Change',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: hsColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Subtle Refresh Button (↻)
          if (!isManual)
            IconButton(
              tooltip: coreLocState.isRefreshing ? 'Updating location...' : 'Refresh location',
              visualDensity: VisualDensity.compact,
              icon: coreLocState.isRefreshing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                      ),
                    )
                  : Icon(Icons.refresh_rounded, size: 18, color: hsColors.primary),
              onPressed: coreLocState.isRefreshing
                  ? null
                  : () async {
                      await coreLocNotifier.refreshLocation();
                      final fresh = ref.read(locationControllerProvider).currentLocation;
                      if (fresh != null) {
                        locController.setLocation(fresh.toUserLocationContext());
                      }
                    },
            ),
          const SizedBox(width: 4),

          // Radius dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: hsColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: hsColors.outline.withValues(alpha: 0.6)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<double>(
                value: locState.radiusKm,
                isDense: true,
                icon: const Icon(Icons.arrow_drop_down_rounded, size: 18),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                items: const [
                  DropdownMenuItem(value: 1.0, child: Text('1 KM')),
                  DropdownMenuItem(value: 2.0, child: Text('2 KM')),
                  DropdownMenuItem(value: 5.0, child: Text('5 KM')),
                  DropdownMenuItem(value: 10.0, child: Text('10 KM')),
                  DropdownMenuItem(value: 20.0, child: Text('20 KM')),
                ],
                onChanged: (newRadius) {
                  if (newRadius != null) {
                    locController.updateRadius(newRadius);
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 8),

          // List vs Radar Map Toggle
          Container(
            decoration: BoxDecoration(
              color: hsColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildViewModeButton(
                  icon: Icons.view_list_rounded,
                  isActive: locState.viewMode == DealsViewMode.list,
                  hsColors: hsColors,
                  onTap: () => locController.setViewMode(DealsViewMode.list),
                ),
                _buildViewModeButton(
                  icon: Icons.radar_rounded,
                  isActive: locState.viewMode == DealsViewMode.map,
                  hsColors: hsColors,
                  onTap: () => locController.setViewMode(DealsViewMode.map),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeButton({
    required IconData icon,
    required bool isActive,
    required HomeStockThemeColors hsColors,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? hsColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isActive ? Colors.white : AppColors.textMuted,
        ),
      ),
    );
  }

  void _openLocationPicker(
    BuildContext context,
    LocationDealsController locController,
    LocationController coreLocNotifier,
  ) {
    final locState = ref.read(locationDealsControllerProvider);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Your Shopping Location',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Deals, delivery estimates, and local shop prices will be tuned to this area.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.my_location_rounded, color: Color(0xFF0284C7)),
                ),
                title: const Text(
                  'Detect Real Live Location (GPS)',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                subtitle: const Text(
                  'Auto-detects live coordinates with explanation & privacy guarantees',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final granted = await coreLocNotifier.requestLocationWithExplanation(context);
                  if (granted) {
                    final loc = ref.read(locationControllerProvider).currentLocation;
                    if (loc != null) {
                      locController.setLocation(loc.toUserLocationContext());
                    }
                  }
                },
              ),
              const Divider(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.search_rounded, color: Color(0xFFD97706)),
                ),
                title: const Text(
                  'Search City / Area / Pincode',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                subtitle: const Text(
                  'e.g. Any city, village, locality, or pincode',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final selected = await showDialog<UserLocationContext>(
                    context: context,
                    builder: (_) => ManualLocationDialog(
                      currentContext: locState.location,
                      onSearchAreas: (q) => locController.searchAreas(q),
                    ),
                  );
                  if (selected != null) {
                    locController.setLocation(selected);
                    coreLocNotifier.setManualLocation(selected.toLocationResult());
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShoppingListIntelligenceBanner(
    BuildContext context,
    LocationDealsState locState,
    LocationDealsController locController,
    HomeStockThemeColors hsColors,
  ) {
    List<ShoppingItemModel> pendingItems = const [];
    try {
      final shoppingState = ref.watch(shoppingControllerProvider);
      pendingItems = shoppingState.list?.items.where((it) => !it.isCompleted).toList() ?? [];
    } catch (_) {
      pendingItems = const [];
    }

    if (pendingItems.isEmpty && locState.basketResult == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFEEF2FF),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC7D2FE), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF4F46E5), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Shopping List Deals',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E1B4B),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${pendingItems.length} items',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Compare single-store convenience vs multi-store maximum savings.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.indigo.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              if (locState.basketResult != null)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                  onPressed: () => locController.clearBasketOptimization(),
                ),
            ],
          ),
          const SizedBox(height: 10),

          if (locState.isBasketLoading) ...[
            const LinearProgressIndicator(color: Color(0xFF4F46E5)),
            const SizedBox(height: 8),
            const Text(
              'Analyzing local supermarket stocks & online delivery costs...',
              style: TextStyle(fontSize: 12, color: Color(0xFF4F46E5), fontWeight: FontWeight.w600),
            ),
          ] else if (locState.basketResult != null) ...[
            _buildBasketOptimizationCards(locState.basketResult!, hsColors, locController),
          ] else ...[
            SizedBox(
              width: double.infinity,
              height: 38,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                label: const Text(
                  'Find Best Basket Deals',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  final homeId = ref.read(homeControllerProvider).activeHome?.id ?? 'default_home';
                  final items = pendingItems.map((e) => {
                    'itemName': e.itemName,
                    'quantity': e.quantity,
                    'unit': e.unit,
                    'category': e.categoryName,
                  }).toList();
                  locController.optimizeBasket(homeId: homeId, items: items);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBasketOptimizationCards(
    BasketOptimizationResult basket,
    HomeStockThemeColors hsColors,
    LocationDealsController locController,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI Recommendation
        if (basket.geminiAiRecommendation.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_rounded, size: 18, color: Color(0xFF16A34A)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    basket.geminiAiRecommendation,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF166534),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // 2 Options: Single Store vs Split Savings
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (basket.bestSingleStoreOption != null)
              Expanded(
                child: _buildBasketOptionCard(
                  basket.bestSingleStoreOption!,
                  isSavingsOption: false,
                  hsColors: hsColors,
                ),
              ),
            if (basket.bestSingleStoreOption != null && basket.maximumSavingsOption != null)
              const SizedBox(width: 10),
            if (basket.maximumSavingsOption != null)
              Expanded(
                child: _buildBasketOptionCard(
                  basket.maximumSavingsOption!,
                  isSavingsOption: true,
                  hsColors: hsColors,
                ),
              ),
          ],
        ),

        if (basket.tradeOffExplanation.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            basket.tradeOffExplanation,
            style: const TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBasketOptionCard(
    BasketOption option, {
    required bool isSavingsOption,
    required HomeStockThemeColors hsColors,
  }) {
    final borderColor = isSavingsOption ? const Color(0xFF10B981) : const Color(0xFF6366F1);
    final bgColor = isSavingsOption ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC);
    final badgeText = isSavingsOption ? 'MAX SAVINGS' : '1-TRIP CONVENIENCE';
    final badgeColor = isSavingsOption ? const Color(0xFF059669) : const Color(0xFF4F46E5);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withValues(alpha: 0.5), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: badgeColor,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            option.storeNames.join(' + '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '₹${option.effectiveGrandTotal.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: isSavingsOption ? const Color(0xFF059669) : const Color(0xFF1E293B),
            ),
          ),
          if (option.potentialSavings > 0)
            Text(
              'Saves ₹${option.potentialSavings.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF059669),
              ),
            ),
          if (option.estimatedDeliveryOrTravelCost > 0)
            Text(
              '+ ₹${option.estimatedDeliveryOrTravelCost.toStringAsFixed(0)} travel/delivery',
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textMuted,
              ),
            ),
        ],
      ),
    );
  }

  void _openVoiceSearchDialog(
    BuildContext context,
    LocationDealsController locController,
    HomeStockThemeColors hsColors,
  ) {
    final voiceTextController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final locState = ref.watch(locationDealsControllerProvider);
            final voiceResult = locState.voiceResult;

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  top: AppSpacing.lg,
                  bottom: MediaQuery.of(dialogCtx).viewInsets.bottom + AppSpacing.lg,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: hsColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.mic_rounded, color: hsColors.primary, size: 22),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Voice & Tanglish Deal Finder',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Powered by Gemini 3.1 Flash-Lite NLP',
                                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () {
                            locController.clearVoiceResult();
                            Navigator.pop(dialogCtx);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Input Text
                    TextField(
                      controller: voiceTextController,
                      decoration: InputDecoration(
                        hintText: 'e.g. "ennaiku entha shop la oil kammiya iruku?"',
                        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                        filled: true,
                        fillColor: hsColors.surfaceVariant,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: hsColors.outline),
                        ),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.mic_rounded, color: hsColors.primary),
                              tooltip: 'Speak query',
                              onPressed: () {
                                VoiceBottomSheet.show(
                                  context,
                                  onSearchQuery: (q) async {
                                    voiceTextController.text = q;
                                    await locController.searchVoice(q);
                                    setDialogState(() {});
                                  },
                                );
                              },
                            ),
                            if (locState.isVoiceSearching)
                              const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            else
                              IconButton(
                                icon: Icon(Icons.send_rounded, color: hsColors.primary),
                                onPressed: () async {
                                  final query = voiceTextController.text.trim();
                                  if (query.isNotEmpty) {
                                    await locController.searchVoice(query);
                                    setDialogState(() {});
                                  }
                                },
                              ),
                          ],
                        ),
                      ),
                      onSubmitted: (val) async {
                        if (val.trim().isNotEmpty) {
                          await locController.searchVoice(val.trim());
                          setDialogState(() {});
                        }
                      },
                    ),
                    const SizedBox(height: 10),

                    // Example Tanglish Prompts
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildPromptChip('ennaiku oil best price?', voiceTextController, () {
                          voiceTextController.text = 'ennaiku oil best price?';
                          locController.searchVoice(voiceTextController.text);
                        }),
                        _buildPromptChip('5kg ponni rice offers', voiceTextController, () {
                          voiceTextController.text = '5kg ponni rice offers';
                          locController.searchVoice(voiceTextController.text);
                        }),
                        _buildPromptChip('milk and atta Salem rate', voiceTextController, () {
                          voiceTextController.text = 'milk and atta Salem rate';
                          locController.searchVoice(voiceTextController.text);
                        }),
                      ],
                    ),

                    if (voiceResult != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF16A34A),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    voiceResult.intent,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Lang: ${voiceResult.detectedLanguage}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF166534),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              voiceResult.conversationalReply,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF14532D),
                                height: 1.3,
                              ),
                            ),
                            if (voiceResult.bestNearbyDeal != null) ...[
                              const Divider(height: 16),
                              InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => NearbyShopDetailScreen(
                                        shopId: voiceResult.bestNearbyDeal!.shopId,
                                      ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.storefront_rounded, size: 16, color: Color(0xFF16A34A)),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          '${voiceResult.bestNearbyDeal!.shopName} (${voiceResult.bestNearbyDeal!.distanceLabel ?? ''})',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF14532D),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '₹${voiceResult.bestNearbyDeal!.effectivePrice.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF16A34A),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF16A34A)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF166534),
                                  side: const BorderSide(color: Color(0xFF16A34A)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () {
                                  final term = voiceResult.parsedProduct ?? voiceTextController.text;
                                  Navigator.pop(dialogCtx);
                                  _searchController.text = term;
                                  _performSearch(term);
                                },
                                child: Text('Search Catalog for "${voiceResult.parsedProduct ?? 'item'}"'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPromptChip(String label, TextEditingController controller, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}
