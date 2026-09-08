package com.homestock.modules.smartshopping.service;

import com.homestock.core.exception.ResourceNotFoundException;
import com.homestock.modules.shopping.entity.ShoppingListItem;
import com.homestock.modules.shopping.repository.ShoppingListItemRepository;
import com.homestock.modules.smartshopping.dto.*;
import com.homestock.modules.smartshopping.dto.PriceComparisonResponse.*;
import com.homestock.modules.smartshopping.provider.ProductSearchRequest;
import com.homestock.modules.smartshopping.provider.ShoppingProvider;
import com.homestock.modules.smartshopping.provider.ShoppingProviderRegistry;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.*;
import java.util.concurrent.*;
import java.util.stream.Collectors;

/**
 * Core price comparison orchestrator.
 * Fans out search requests across enabled providers, applies product matching with variant protection,
 * calculates price per unit and freshness, and drives multi-item basket optimization.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class PriceComparisonService {

    private final ShoppingProviderRegistry providerRegistry;
    private final ProductMatchingService matchingService;
    private final UnitNormalizationService unitService;
    private final PriceCacheService cacheService;
    private final ShoppingListItemRepository shoppingItemRepository;
    private final BasketOptimizationService basketOptimizationService;
    private final DuplicateProtectionService duplicateProtectionService;
    private final OfferRankingService offerRankingService;

    @Value("${app.smart-shopping.provider-timeout-seconds:5}")
    private int providerTimeoutSeconds;

    /**
     * Compare prices for a single shopping item across all enabled providers.
     */
    public PriceComparisonResponse compareItem(UUID homeId, UUID itemId) {
        ShoppingListItem shoppingItem = shoppingItemRepository.findById(itemId)
                .orElseThrow(() -> new ResourceNotFoundException("Shopping item not found: " + itemId));

        ShoppingItemSummary itemSummary = toSummary(shoppingItem);
        List<ProductOfferDto> matchedOffers = fetchOffersForItem(shoppingItem, itemSummary);

        return buildResponse(itemSummary, matchedOffers);
    }

    /**
     * Compare multiple shopping items together to produce multi-provider basket optimizations
     * (Option A split vs Option B single store), along with duplicate warnings.
     */
    public BasketComparisonResponse compareBasket(UUID homeId, BasketComparisonRequest request) {
        List<ShoppingListItem> items;
        if (request.getItemIds() != null && !request.getItemIds().isEmpty()) {
            items = shoppingItemRepository.findAllById(request.getItemIds());
        } else {
            // Default to all active, uncompleted items for this home
            items = shoppingItemRepository.findPendingItemsByHomeId(homeId);
        }

        if (items.isEmpty()) {
            return BasketComparisonResponse.builder()
                    .options(List.of())
                    .duplicateWarnings(List.of())
                    .calculatedAt(Instant.now())
                    .build();
        }

        // 1. Run duplicate check
        List<DuplicateWarningDto> duplicateWarnings = duplicateProtectionService.checkDuplicates(homeId, items);

        // 2. Fetch offers for all items
        Map<UUID, List<ProductOfferDto>> offersByItemId = new LinkedHashMap<>();
        Map<UUID, ShoppingListItem> itemById = new LinkedHashMap<>();

        for (ShoppingListItem item : items) {
            itemById.put(item.getId(), item);
            ShoppingItemSummary summary = toSummary(item);
            List<ProductOfferDto> offers = fetchOffersForItem(item, summary);
            offersByItemId.put(item.getId(), offers);
        }

        // 3. Run basket optimization (Option A split, Option B single-store)
        List<BasketOptionDto> options = basketOptimizationService.computeBasketOptions(
                offersByItemId, itemById, request.getPreferredStore()
        );

        // 4. Determine recommended option
        BasketOptionDto recommended = null;
        if (!options.isEmpty()) {
            // Default recommended: Option B if difference is small, else Option A
            BasketOptionDto optB = options.stream()
                    .filter(o -> "OPTION_B_SINGLE_STORE".equals(o.getOptionType()))
                    .findFirst().orElse(null);
            BasketOptionDto optA = options.stream()
                    .filter(o -> "OPTION_A_INDIVIDUAL_BEST".equals(o.getOptionType()))
                    .findFirst().orElse(null);

            if (optB != null && optA != null) {
                BigDecimal diff = optB.getNetTotal().subtract(optA.getNetTotal());
                recommended = diff.compareTo(BigDecimal.valueOf(50)) <= 0 ? optB : optA;
            } else {
                recommended = options.get(0);
            }
        }

        return BasketComparisonResponse.builder()
                .options(options)
                .recommendedOption(recommended)
                .duplicateWarnings(duplicateWarnings)
                .calculatedAt(Instant.now())
                .build();
    }

    private List<ProductOfferDto> fetchOffersForItem(ShoppingListItem shoppingItem, ShoppingItemSummary itemSummary) {
        String canonicalId = buildCanonicalId(itemSummary);

        // Check cache first
        List<ProductOfferDto> cachedOffers = cacheService.getCachedOffers(canonicalId);
        if (!cachedOffers.isEmpty()) {
            return cachedOffers;
        }

        // Build search request
        ProductSearchRequest searchRequest = ProductSearchRequest.builder()
                .itemName(itemSummary.getName())
                .brand(itemSummary.getBrand())
                .quantity(itemSummary.getQuantity())
                .unit(itemSummary.getUnit())
                .category(itemSummary.getCategoryName())
                .barcode(shoppingItem.getBarcode())
                .build();

        List<ShoppingProvider> enabledProviders = providerRegistry.getEnabledProviders();
        if (enabledProviders.isEmpty()) {
            log.warn("[PriceComparison] No shopping providers enabled");
            return List.of();
        }

        ExecutorService executor = Executors.newFixedThreadPool(Math.min(enabledProviders.size(), 4));
        Map<String, Future<ProviderResult>> futures = new LinkedHashMap<>();

        for (ShoppingProvider provider : enabledProviders) {
            futures.put(provider.getProviderName(), executor.submit(() -> {
                long start = System.currentTimeMillis();
                try {
                    List<ProductOfferDto> results = provider.searchProducts(searchRequest);
                    long duration = System.currentTimeMillis() - start;
                    return new ProviderResult(provider.getProviderName(), results, "SUCCESS", null, duration);
                } catch (Exception e) {
                    long duration = System.currentTimeMillis() - start;
                    log.error("[PriceComparison] Provider {} failed: {}", provider.getProviderName(), e.getMessage());
                    return new ProviderResult(provider.getProviderName(), List.of(), "FAILED", e.getMessage(), duration);
                }
            }));
        }

        List<ProductOfferDto> allOffers = new ArrayList<>();
        for (Map.Entry<String, Future<ProviderResult>> entry : futures.entrySet()) {
            try {
                ProviderResult result = entry.getValue().get(providerTimeoutSeconds, TimeUnit.SECONDS);
                allOffers.addAll(result.offers);
            } catch (TimeoutException e) {
                log.warn("[PriceComparison] Provider {} timed out after {}s", entry.getKey(), providerTimeoutSeconds);
                entry.getValue().cancel(true);
            } catch (Exception e) {
                log.error("[PriceComparison] Error from provider {}: {}", entry.getKey(), e.getMessage());
            }
        }
        executor.shutdown();

        // Apply product matching & variant clash filtering
        List<ProductOfferDto> matchedOffers = allOffers.stream()
                .map(offer -> {
                    ProductMatchingService.MatchResult match = matchingService.calculateMatch(
                            itemSummary.getName(),
                            itemSummary.getBrand(),
                            itemSummary.getQuantity(),
                            itemSummary.getUnit(),
                            itemSummary.getCategoryName(),
                            shoppingItem.getBarcode(),
                            offer
                    );
                    matchingService.enrichWithMatch(offer, match);

                    // Calculate price per unit
                    if (offer.getPackageSize() != null) {
                        UnitNormalizationService.PackageSize pkg = unitService.parsePackageSize(offer.getPackageSize());
                        if (pkg != null && offer.getPrice() != null) {
                            UnitNormalizationService.PricePerUnit ppu = unitService.calculatePricePerUnit(
                                    offer.getPrice(), pkg.quantity(), pkg.unit());
                            if (ppu != null) {
                                offer.setPricePerUnit(ppu.price());
                                offer.setPricePerUnitLabel(ppu.label());
                            }
                        }
                    }

                    return offer;
                })
                .filter(offer -> offer.getMatchConfidence() != null && offer.getMatchConfidence() >= 0.5)
                .collect(Collectors.toList());

        // Cache acceptable results
        if (!matchedOffers.isEmpty()) {
            cacheService.cacheOffers(canonicalId, matchedOffers);
        }

        return matchedOffers;
    }

    private ShoppingItemSummary toSummary(ShoppingListItem shoppingItem) {
        String brand = shoppingItem.getPreferredBrand();
        if (brand == null && shoppingItem.getInventoryItem() != null) {
            brand = shoppingItem.getInventoryItem().getBrand();
        }
        return ShoppingItemSummary.builder()
                .id(shoppingItem.getId().toString())
                .name(shoppingItem.getItemName())
                .quantity(shoppingItem.getQuantity())
                .unit(shoppingItem.getUnit())
                .brand(brand)
                .categoryName(shoppingItem.getCategory() != null ? shoppingItem.getCategory().getName() : null)
                .build();
    }

    private PriceComparisonResponse buildResponse(ShoppingItemSummary item, List<ProductOfferDto> offers) {
        offers.sort(Comparator.comparing(
                o -> o.getEffectivePrice() != null ? o.getEffectivePrice() : BigDecimal.valueOf(Long.MAX_VALUE)));

        ProductOfferDto bestOffer = offers.isEmpty() ? null : offers.get(0);

        return PriceComparisonResponse.builder()
                .shoppingItem(item)
                .offers(offers)
                .bestOffer(bestOffer)
                .lastUpdated(Instant.now())
                .build();
    }

    private String buildCanonicalId(ShoppingItemSummary item) {
        String name = item.getName() != null ? item.getName().toLowerCase().trim() : "";
        String unit = item.getUnit() != null ? item.getUnit().toLowerCase().trim() : "";
        String qty = item.getQuantity() != null ? item.getQuantity().toPlainString() : "1";
        return name + ":" + qty + ":" + unit;
    }

    private record ProviderResult(
            String providerName,
            List<ProductOfferDto> offers,
            String status,
            String errorMessage,
            long durationMs
    ) {}
}
