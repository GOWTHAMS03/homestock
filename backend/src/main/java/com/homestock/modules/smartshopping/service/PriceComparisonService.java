package com.homestock.modules.smartshopping.service;

import com.homestock.core.exception.ResourceNotFoundException;
import com.homestock.modules.shopping.entity.ShoppingListItem;
import com.homestock.modules.shopping.repository.ShoppingListItemRepository;
import com.homestock.modules.smartshopping.dto.PriceComparisonResponse;
import com.homestock.modules.smartshopping.dto.PriceComparisonResponse.*;
import com.homestock.modules.smartshopping.dto.ProductOfferDto;
import com.homestock.modules.smartshopping.provider.ProductSearchRequest;
import com.homestock.modules.smartshopping.provider.ShoppingProvider;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.*;
import java.util.concurrent.*;
import java.util.stream.Collectors;

/**
 * Core price comparison orchestrator.
 * <p>
 * Fans out search requests to all enabled providers in parallel,
 * applies product matching, calculates effective prices, and ranks results.
 * <p>
 * Ranking is always based on user value (effective price), never on commission.
 */
@Service
@RequiredArgsConstructor
public class PriceComparisonService {

    private static final Logger log = LoggerFactory.getLogger(PriceComparisonService.class);

    private final List<ShoppingProvider> providers;
    private final ProductMatchingService matchingService;
    private final UnitNormalizationService unitService;
    private final PriceCacheService cacheService;
    private final ShoppingListItemRepository shoppingItemRepository;

    @Value("${app.smart-shopping.provider-timeout-seconds:5}")
    private int providerTimeoutSeconds;

    /**
     * Compare prices for a single shopping item across all enabled providers.
     */
    public PriceComparisonResponse compareItem(UUID homeId, UUID itemId) {
        // Load shopping item
        ShoppingListItem shoppingItem = shoppingItemRepository.findById(itemId)
                .orElseThrow(() -> new ResourceNotFoundException("Shopping item not found"));

        // Build shopping item summary
        ShoppingItemSummary itemSummary = ShoppingItemSummary.builder()
                .id(shoppingItem.getId().toString())
                .name(shoppingItem.getItemName())
                .quantity(shoppingItem.getQuantity())
                .unit(shoppingItem.getUnit())
                .brand(shoppingItem.getInventoryItem() != null ? shoppingItem.getInventoryItem().getBrand() : null)
                .categoryName(shoppingItem.getCategory() != null ? shoppingItem.getCategory().getName() : null)
                .build();

        // Build canonical ID for caching
        String canonicalId = buildCanonicalId(itemSummary);

        // Check cache first
        List<ProductOfferDto> cachedOffers = cacheService.getCachedOffers(canonicalId);
        if (!cachedOffers.isEmpty()) {
            return buildResponse(itemSummary, cachedOffers);
        }

        // Build search request
        ProductSearchRequest searchRequest = ProductSearchRequest.builder()
                .itemName(itemSummary.getName())
                .brand(itemSummary.getBrand())
                .quantity(itemSummary.getQuantity())
                .unit(itemSummary.getUnit())
                .category(itemSummary.getCategoryName())
                .build();

        // Fan out to all enabled providers in parallel
        List<ShoppingProvider> enabledProviders = providers.stream()
                .filter(ShoppingProvider::isEnabled)
                .collect(Collectors.toList());

        if (enabledProviders.isEmpty()) {
            log.warn("[PriceComparison] No providers enabled");
            return buildEmptyResponse(itemSummary);
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

        // Collect results with timeout
        List<ProductOfferDto> allOffers = new ArrayList<>();
        Map<String, ProviderStatusDto> providerStatuses = new LinkedHashMap<>();

        for (Map.Entry<String, Future<ProviderResult>> entry : futures.entrySet()) {
            String providerName = entry.getKey();
            try {
                ProviderResult result = entry.getValue().get(providerTimeoutSeconds, TimeUnit.SECONDS);
                allOffers.addAll(result.offers);
                providerStatuses.put(providerName, ProviderStatusDto.builder()
                        .provider(providerName)
                        .status(result.status)
                        .message(result.errorMessage)
                        .offerCount(result.offers.size())
                        .responseTimeMs(result.durationMs)
                        .build());
            } catch (TimeoutException e) {
                log.warn("[PriceComparison] Provider {} timed out after {}s", providerName, providerTimeoutSeconds);
                entry.getValue().cancel(true);
                providerStatuses.put(providerName, ProviderStatusDto.builder()
                        .provider(providerName)
                        .status("TIMEOUT")
                        .message("Provider response timed out")
                        .offerCount(0)
                        .responseTimeMs(providerTimeoutSeconds * 1000L)
                        .build());
            } catch (Exception e) {
                log.error("[PriceComparison] Error collecting results from {}: {}", providerName, e.getMessage());
                providerStatuses.put(providerName, ProviderStatusDto.builder()
                        .provider(providerName)
                        .status("FAILED")
                        .message(e.getMessage())
                        .offerCount(0)
                        .build());
            }
        }

        executor.shutdown();

        // Apply product matching
        List<ProductOfferDto> matchedOffers = allOffers.stream()
                .map(offer -> {
                    ProductMatchingService.MatchResult match = matchingService.calculateMatch(
                            itemSummary.getName(),
                            itemSummary.getBrand(),
                            itemSummary.getQuantity(),
                            itemSummary.getUnit(),
                            itemSummary.getCategoryName(),
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
                // Only include acceptable matches
                .filter(offer -> offer.getMatchConfidence() != null && offer.getMatchConfidence() >= 0.5)
                .collect(Collectors.toList());

        // Cache the results
        if (!matchedOffers.isEmpty()) {
            cacheService.cacheOffers(canonicalId, matchedOffers);
        }

        // Build response
        PriceComparisonResponse response = buildResponse(itemSummary, matchedOffers);
        response.setProviderStatuses(providerStatuses);
        return response;
    }

    private PriceComparisonResponse buildResponse(ShoppingItemSummary item, List<ProductOfferDto> offers) {
        // Sort by effective price (user value)
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

    private PriceComparisonResponse buildEmptyResponse(ShoppingItemSummary item) {
        return PriceComparisonResponse.builder()
                .shoppingItem(item)
                .offers(List.of())
                .bestOffer(null)
                .providerStatuses(Map.of())
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
