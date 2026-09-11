package com.homestock.modules.smartshopping.service.dedup;

import com.homestock.modules.smartshopping.dto.ProductCandidate;
import com.homestock.modules.smartshopping.dto.ProductDealDto;
import com.homestock.modules.smartshopping.dto.StoreOfferDto;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Deduplicates candidate offers using canonical product fingerprints
 * (BRAND|NORMALIZED_NAME|VARIANT|PACK_SIZE|BARCODE) and consolidates multi-seller deals.
 */
@Service
public class ProductDeduplicationService {

    private static final Logger log = LoggerFactory.getLogger(ProductDeduplicationService.class);

    /**
     * Group multiple candidate offers across search engines into canonical product deals.
     */
    public List<ProductDealDto> deduplicateAndGroup(List<ProductCandidate> candidates) {
        if (candidates == null || candidates.isEmpty()) {
            return Collections.emptyList();
        }

        Map<String, List<ProductCandidate>> grouped = new LinkedHashMap<>();

        for (ProductCandidate c : candidates) {
            String fingerprint = generateFingerprint(c);
            grouped.computeIfAbsent(fingerprint, k -> new ArrayList<>()).add(c);
        }

        List<ProductDealDto> deals = new ArrayList<>();

        for (Map.Entry<String, List<ProductCandidate>> entry : grouped.entrySet()) {
            List<ProductCandidate> group = entry.getValue();
            if (group.isEmpty()) continue;

            ProductDealDto deal = buildCanonicalDeal(entry.getKey(), group);
            deals.add(deal);
        }

        log.debug("[ProductDeduplicationService] Deduplicated {} candidates into {} canonical product groups",
                candidates.size(), deals.size());

        return deals;
    }

    /**
     * Generate canonical fingerprint: BRAND|NORMALIZED_NAME|VARIANT|PACK_SIZE|BARCODE
     */
    public String generateFingerprint(ProductCandidate c) {
        if (c.getBarcode() != null && !c.getBarcode().isBlank()) {
            return "BARCODE:" + c.getBarcode().trim();
        }

        String brand = c.getBrand() != null ? c.getBrand().trim().toUpperCase() : "GENERIC";
        String variant = c.getVariant() != null ? c.getVariant().trim().toUpperCase() : "";
        String pack = c.getPackageSize() != null ? c.getPackageSize().replaceAll("\\s+", "").toUpperCase() : "";

        // Normalize product name to core tokens
        String name = c.getProductName() != null ? c.getProductName().toLowerCase() : "";
        name = name.replaceAll("[^a-zA-Z0-9\\s]", "").replaceAll("\\s+", " ").trim().toUpperCase();

        return brand + "|" + name + "|" + variant + "|" + pack;
    }

    private ProductDealDto buildCanonicalDeal(String fingerprint, List<ProductCandidate> candidates) {
        // Collect store offers
        List<StoreOfferDto> storeOffers = candidates.stream()
                .map(c -> StoreOfferDto.builder()
                        .storeName(c.getProvider())
                        .price(c.getEffectivePrice() != null ? c.getEffectivePrice() : c.getPrice())
                        .mrp(c.getMrp() != null ? c.getMrp() : c.getPrice())
                        .deliveryFee(c.getDeliveryCharge())
                        .estimatedDelivery(c.getEstimatedDelivery())
                        .availability(c.getAvailability())
                        .productUrl(c.getAffiliateUrl() != null ? c.getAffiliateUrl() : c.getProductUrl())
                        .affiliateUrl(c.getAffiliateUrl())
                        .deepLink(c.getDeepLink())
                        .rating(c.getRating())
                        .reviewCount(c.getReviewCount())
                        .build())
                .sorted(Comparator.comparing(StoreOfferDto::getPrice, Comparator.nullsLast(BigDecimal::compareTo)))
                .collect(Collectors.toList());

        // Best offer (lowest effective price)
        ProductCandidate bestCandidate = candidates.stream()
                .min(Comparator.comparing(c -> c.getEffectivePrice() != null ? c.getEffectivePrice() : c.getPrice(),
                        Comparator.nullsLast(BigDecimal::compareTo)))
                .orElse(candidates.get(0));

        BigDecimal minPrice = storeOffers.get(0).getPrice();
        BigDecimal maxPrice = storeOffers.get(storeOffers.size() - 1).getPrice();
        BigDecimal savings = maxPrice.subtract(minPrice);
        String comparisonStore = storeOffers.size() > 1 ? storeOffers.get(storeOffers.size() - 1).getStoreName() : null;

        Double discountPercent = null;
        if (maxPrice.compareTo(BigDecimal.ZERO) > 0 && savings.compareTo(BigDecimal.ZERO) > 0) {
            discountPercent = savings.divide(maxPrice, 4, RoundingMode.HALF_UP)
                    .multiply(BigDecimal.valueOf(100))
                    .setScale(1, RoundingMode.HALF_UP)
                    .doubleValue();
        }

        String dealId = "DEAL-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();

        return ProductDealDto.builder()
                .id(dealId)
                .productName(bestCandidate.getProductName())
                .brand(bestCandidate.getBrand())
                .variantType(bestCandidate.getVariant())
                .category(bestCandidate.getCategory())
                .packageSize(bestCandidate.getPackageSize())
                .packSize(bestCandidate.getPackageSize())
                .unit(bestCandidate.getUnit())
                .bestPrice(minPrice)
                .price(minPrice)
                .mrp(bestCandidate.getMrp() != null ? bestCandidate.getMrp() : maxPrice)
                .discountPercent(discountPercent)
                .discountPercentage(discountPercent)
                .bestProvider(storeOffers.get(0).getStoreName())
                .seller(storeOffers.get(0).getStoreName())
                .source(bestCandidate.getProvider())
                .deliveryCharge(bestCandidate.getDeliveryCharge())
                .effectivePrice(bestCandidate.getEffectivePrice() != null ? bestCandidate.getEffectivePrice() : minPrice)
                .savingsVsHighest(savings)
                .comparisonStore(comparisonStore)
                .imageUrl(bestCandidate.getImageUrl())
                .productUrl(bestCandidate.getAffiliateUrl() != null ? bestCandidate.getAffiliateUrl() : bestCandidate.getProductUrl())
                .deepLink(bestCandidate.getDeepLink())
                .rating(bestCandidate.getRating() != null ? bestCandidate.getRating() : 4.4)
                .reviewCount(bestCandidate.getReviewCount() != null ? bestCandidate.getReviewCount() : 1000)
                .availability(bestCandidate.getAvailability())
                .matchScore(bestCandidate.getMatchScore())
                .matchConfidence(bestCandidate.getMatchScore() != null ? bestCandidate.getMatchScore() / 100.0 : 0.85)
                .matchStatus(bestCandidate.getMatchStatus())
                .priceConfidence(bestCandidate.getPriceConfidence())
                .priceStatus(bestCandidate.getPriceStatus())
                .lastVerifiedAt(bestCandidate.getLastVerifiedAt())
                .storeOffers(storeOffers)
                .build();
    }
}
