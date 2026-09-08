package com.homestock.modules.smartshopping.service;

import com.homestock.modules.shopping.entity.ShoppingListItem;
import com.homestock.modules.smartshopping.dto.BasketOptionDto;
import com.homestock.modules.smartshopping.dto.BasketOptionDto.BasketItemDto;
import com.homestock.modules.smartshopping.dto.ProductOfferDto;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Optimizes multi-item grocery shopping baskets across providers.
 * Evaluates split-store savings vs single-store convenience, taking delivery
 * fees and minimum order thresholds into account.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class BasketOptimizationService {

    private final OfferRankingService offerRankingService;

    // Delivery fee thresholds (can also be driven by provider configuration)
    private static final Map<String, BigDecimal> FREE_DELIVERY_THRESHOLDS = Map.of(
            "amazon", BigDecimal.valueOf(499),
            "flipkart", BigDecimal.valueOf(500),
            "blinkit", BigDecimal.valueOf(199),
            "zepto", BigDecimal.valueOf(199),
            "local store", BigDecimal.ZERO,
            "mock", BigDecimal.valueOf(299)
    );

    private static final Map<String, BigDecimal> STANDARD_DELIVERY_FEES = Map.of(
            "amazon", BigDecimal.valueOf(40),
            "flipkart", BigDecimal.valueOf(40),
            "blinkit", BigDecimal.valueOf(25),
            "zepto", BigDecimal.valueOf(25),
            "local store", BigDecimal.ZERO,
            "mock", BigDecimal.valueOf(30)
    );

    /**
     * Compute basket options given the available offers for each shopping item.
     */
    public List<BasketOptionDto> computeBasketOptions(
            Map<UUID, List<ProductOfferDto>> offersByItemId,
            Map<UUID, ShoppingListItem> itemById,
            String preferredStore
    ) {
        List<BasketOptionDto> options = new ArrayList<>();

        if (offersByItemId == null || offersByItemId.isEmpty()) {
            return options;
        }

        // Option A: Individual Best Across All Stores
        BasketOptionDto optionA = buildOptionA(offersByItemId, itemById);
        if (optionA != null && !optionA.getItems().isEmpty()) {
            options.add(optionA);
        }

        // Option B: Best Single-Store Basket
        BasketOptionDto optionB = buildOptionB(offersByItemId, itemById, preferredStore);
        if (optionB != null && !optionB.getItems().isEmpty()) {
            options.add(optionB);
        }

        // Calculate potential savings and recommendation comparison
        enrichRecommendations(options);

        return options;
    }

    private BasketOptionDto buildOptionA(
            Map<UUID, List<ProductOfferDto>> offersByItemId,
            Map<UUID, ShoppingListItem> itemById
    ) {
        List<BasketItemDto> basketItems = new ArrayList<>();
        Map<String, BigDecimal> storeSubtotals = new HashMap<>();

        for (Map.Entry<UUID, List<ProductOfferDto>> entry : offersByItemId.entrySet()) {
            UUID itemId = entry.getKey();
            List<ProductOfferDto> offers = entry.getValue();
            if (offers.isEmpty()) continue;

            // Pick lowest effective price offer
            ProductOfferDto bestOffer = offers.stream()
                    .min(Comparator.comparing(ProductOfferDto::getEffectivePrice, Comparator.nullsLast(BigDecimal::compareTo)))
                    .orElse(offers.get(0));

            ShoppingListItem item = itemById.get(itemId);
            BasketItemDto basketItem = toBasketItem(itemId, item, bestOffer);
            basketItems.add(basketItem);

            String prov = bestOffer.getProvider() != null ? bestOffer.getProvider().toLowerCase() : "other";
            storeSubtotals.put(prov, storeSubtotals.getOrDefault(prov, BigDecimal.ZERO).add(bestOffer.getPrice()));
        }

        BigDecimal itemsSubtotal = basketItems.stream()
                .map(BasketItemDto::getPrice)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        // Compute total delivery fees across involved stores
        BigDecimal totalDelivery = BigDecimal.ZERO;
        for (Map.Entry<String, BigDecimal> entry : storeSubtotals.entrySet()) {
            totalDelivery = totalDelivery.add(calculateStoreDelivery(entry.getKey(), entry.getValue()));
        }

        BigDecimal netTotal = itemsSubtotal.add(totalDelivery);

        Set<String> distinctStores = basketItems.stream()
                .map(BasketItemDto::getProvider)
                .filter(Objects::nonNull)
                .collect(Collectors.toSet());

        String storeLabel = distinctStores.size() == 1 ? distinctStores.iterator().next() : "Split (" + distinctStores.size() + " Stores)";

        return BasketOptionDto.builder()
                .optionType("OPTION_A_INDIVIDUAL_BEST")
                .title("Lowest Price Items (Split Basket)")
                .storeName(storeLabel)
                .itemsSubtotal(itemsSubtotal.setScale(2, RoundingMode.HALF_UP))
                .deliveryFeesTotal(totalDelivery.setScale(2, RoundingMode.HALF_UP))
                .netTotal(netTotal.setScale(2, RoundingMode.HALF_UP))
                .potentialSavings(BigDecimal.ZERO)
                .items(basketItems)
                .build();
    }

    private BasketOptionDto buildOptionB(
            Map<UUID, List<ProductOfferDto>> offersByItemId,
            Map<UUID, ShoppingListItem> itemById,
            String preferredStore
    ) {
        // Collect all distinct providers
        Set<String> allProviders = offersByItemId.values().stream()
                .flatMap(List::stream)
                .map(ProductOfferDto::getProvider)
                .filter(Objects::nonNull)
                .map(String::toLowerCase)
                .collect(Collectors.toSet());

        BasketOptionDto bestSingleStoreOption = null;

        for (String provider : allProviders) {
            List<BasketItemDto> singleStoreItems = new ArrayList<>();
            BigDecimal subtotal = BigDecimal.ZERO;

            for (Map.Entry<UUID, List<ProductOfferDto>> entry : offersByItemId.entrySet()) {
                UUID itemId = entry.getKey();
                List<ProductOfferDto> offers = entry.getValue();

                Optional<ProductOfferDto> provOffer = offers.stream()
                        .filter(o -> o.getProvider() != null && o.getProvider().equalsIgnoreCase(provider))
                        .min(Comparator.comparing(ProductOfferDto::getEffectivePrice, Comparator.nullsLast(BigDecimal::compareTo)));

                if (provOffer.isPresent()) {
                    ProductOfferDto offer = provOffer.get();
                    ShoppingListItem item = itemById.get(itemId);
                    singleStoreItems.add(toBasketItem(itemId, item, offer));
                    subtotal = subtotal.add(offer.getPrice());
                }
            }

            // Only consider if it covers at least one item
            if (singleStoreItems.isEmpty()) continue;

            BigDecimal delivery = calculateStoreDelivery(provider, subtotal);
            BigDecimal net = subtotal.add(delivery);

            String displayName = singleStoreItems.get(0).getProvider();

            BasketOptionDto candidate = BasketOptionDto.builder()
                    .optionType("OPTION_B_SINGLE_STORE")
                    .title("Single Store Convenience (" + displayName + ")")
                    .storeName(displayName)
                    .itemsSubtotal(subtotal.setScale(2, RoundingMode.HALF_UP))
                    .deliveryFeesTotal(delivery.setScale(2, RoundingMode.HALF_UP))
                    .netTotal(net.setScale(2, RoundingMode.HALF_UP))
                    .potentialSavings(BigDecimal.ZERO)
                    .items(singleStoreItems)
                    .build();

            if (bestSingleStoreOption == null) {
                bestSingleStoreOption = candidate;
            } else {
                // Prefer higher item coverage, then preferredStore match, then lower net total
                boolean candidateHasMoreItems = candidate.getItems().size() > bestSingleStoreOption.getItems().size();
                boolean sameCoverage = candidate.getItems().size() == bestSingleStoreOption.getItems().size();
                boolean candidateIsPreferred = preferredStore != null && provider.equalsIgnoreCase(preferredStore);
                boolean currentIsPreferred = preferredStore != null && bestSingleStoreOption.getStoreName().equalsIgnoreCase(preferredStore);

                if (candidateHasMoreItems) {
                    bestSingleStoreOption = candidate;
                } else if (sameCoverage) {
                    if (candidateIsPreferred && !currentIsPreferred) {
                        bestSingleStoreOption = candidate;
                    } else if (!currentIsPreferred && candidate.getNetTotal().compareTo(bestSingleStoreOption.getNetTotal()) < 0) {
                        bestSingleStoreOption = candidate;
                    }
                }
            }
        }

        return bestSingleStoreOption;
    }

    private BigDecimal calculateStoreDelivery(String providerName, BigDecimal subtotal) {
        if (providerName == null || subtotal == null) return BigDecimal.ZERO;
        String key = providerName.toLowerCase();
        BigDecimal threshold = FREE_DELIVERY_THRESHOLDS.getOrDefault(key, BigDecimal.valueOf(499));
        if (subtotal.compareTo(threshold) >= 0) {
            return BigDecimal.ZERO;
        }
        return STANDARD_DELIVERY_FEES.getOrDefault(key, BigDecimal.valueOf(35));
    }

    private void enrichRecommendations(List<BasketOptionDto> options) {
        if (options.size() < 2) {
            if (options.size() == 1) {
                options.get(0).setRecommendationReason("Best available option for your shopping list.");
            }
            return;
        }

        BasketOptionDto optA = options.stream()
                .filter(o -> "OPTION_A_INDIVIDUAL_BEST".equals(o.getOptionType()))
                .findFirst().orElse(null);

        BasketOptionDto optB = options.stream()
                .filter(o -> "OPTION_B_SINGLE_STORE".equals(o.getOptionType()))
                .findFirst().orElse(null);

        if (optA != null && optB != null) {
            BigDecimal diff = optB.getNetTotal().subtract(optA.getNetTotal());

            if (diff.compareTo(BigDecimal.ZERO) <= 0) {
                // Single store is cheaper or equal (due to delivery threshold savings)!
                optB.setRecommendationReason(String.format(
                        "%s provides the lowest net total (₹%s) and free delivery on the combined order.",
                        optB.getStoreName(), optB.getNetTotal().toPlainString()));
                optA.setRecommendationReason("Split stores have separate delivery fees totaling ₹" + optA.getDeliveryFeesTotal());
            } else if (diff.compareTo(BigDecimal.valueOf(50)) <= 0) {
                // Difference is small (<= ₹50)
                optB.setRecommendationReason(String.format(
                        "%s is only ₹%s more (₹%s total) and lets you buy everything in one single delivery.",
                        optB.getStoreName(), diff.setScale(0, RoundingMode.HALF_UP).toPlainString(), optB.getNetTotal().toPlainString()));
                optA.setRecommendationReason(String.format(
                        "Saves ₹%s, but requires managing orders across multiple stores.",
                        diff.setScale(0, RoundingMode.HALF_UP).toPlainString()));
            } else {
                // Split order provides substantial savings (> ₹50)
                optA.setRecommendationReason(String.format(
                        "Saves ₹%s net by picking the best price from each store.",
                        diff.setScale(0, RoundingMode.HALF_UP).toPlainString()));
                optB.setRecommendationReason(String.format(
                        "All from %s. Single delivery convenience, but ₹%s more expensive.",
                        optB.getStoreName(), diff.setScale(0, RoundingMode.HALF_UP).toPlainString()));
            }

            // Set potential savings on option A relative to B
            if (diff.compareTo(BigDecimal.ZERO) > 0) {
                optA.setPotentialSavings(diff.setScale(2, RoundingMode.HALF_UP));
            }
        }
    }

    private BasketItemDto toBasketItem(UUID itemId, ShoppingListItem item, ProductOfferDto offer) {
        String freshness = offerRankingService.evaluateFreshness(offer.getLastCheckedAt()).name();

        return BasketItemDto.builder()
                .shoppingItemId(itemId)
                .itemName(item != null ? item.getItemName() : offer.getProductName())
                .quantity(item != null ? item.getQuantity() : BigDecimal.ONE)
                .unit(item != null ? item.getUnit() : offer.getUnit())
                .provider(offer.getProvider())
                .providerProductId(offer.getProviderProductId())
                .productTitle(offer.getProductName())
                .price(offer.getPrice())
                .deliveryCharge(offer.getDeliveryCharge())
                .effectivePrice(offer.getEffectivePrice())
                .pricePerUnit(offer.getPricePerUnit())
                .pricePerUnitLabel(offer.getPricePerUnitLabel())
                .matchType(offer.getMatchType())
                .matchConfidence(offer.getMatchConfidence())
                .freshness(freshness)
                .affiliateUrl(offer.getAffiliateUrl())
                .productUrl(offer.getProductUrl())
                .imageUrl(offer.getImageUrl())
                .build();
    }
}
