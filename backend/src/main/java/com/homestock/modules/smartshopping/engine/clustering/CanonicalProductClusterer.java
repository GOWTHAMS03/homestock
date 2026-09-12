package com.homestock.modules.smartshopping.engine.clustering;

import com.homestock.modules.smartshopping.dto.*;
import lombok.Builder;
import lombok.Data;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Canonical Product Clusterer:
 * Groups identical product candidates from multiple search engines into canonical clusters.
 * Performs multi-seller price verification, anomaly detection, effective unit price calculation,
 * and partitions deals into primary target deals vs similar alternatives.
 */
@Component
public class CanonicalProductClusterer {

    private static final Logger log = LoggerFactory.getLogger(CanonicalProductClusterer.class);

    @Data
    @Builder
    public static class ClusteringResult {
        private List<ProductDealDto> primaryDeals;
        private List<ProductDealDto> similarProducts;
        private int totalClustersCount;
    }

    /**
     * Clusters valid candidates into canonical products and converts to ProductDealDto list.
     */
    public ClusteringResult clusterAndRank(ProductIdentity identity, List<ProductCandidate> validCandidates) {
        if (validCandidates == null || validCandidates.isEmpty()) {
            return ClusteringResult.builder()
                    .primaryDeals(Collections.emptyList())
                    .similarProducts(Collections.emptyList())
                    .totalClustersCount(0)
                    .build();
        }

        // 1. Group candidates into clusters by identity key
        Map<String, List<ProductCandidate>> clusters = new LinkedHashMap<>();
        for (ProductCandidate cand : validCandidates) {
            String clusterKey = buildClusterKey(identity, cand);
            clusters.computeIfAbsent(clusterKey, k -> new ArrayList<>()).add(cand);
        }

        List<ProductDealDto> primaryDeals = new ArrayList<>();
        List<ProductDealDto> similarDeals = new ArrayList<>();

        int reqQty = identity.getRequestedQuantity() != null && identity.getRequestedQuantity().intValue() > 0
                ? identity.getRequestedQuantity().intValue()
                : 1;

        for (Map.Entry<String, List<ProductCandidate>> entry : clusters.entrySet()) {
            List<ProductCandidate> group = entry.getValue();

            // Perform price anomaly check if multiple candidates exist in cluster
            verifyPricesAndFilterAnomalies(group);
            if (group.isEmpty()) continue;

            // Sort candidates within cluster: verified direct product detail pages first, then cheapest price
            group.sort(Comparator
                    .comparing((ProductCandidate c) -> c.isUrlVerified() && c.isDirectProductUrlAvailable()).reversed()
                    .thenComparingDouble(ProductCandidate::getPriceAsDouble));

            ProductCandidate best = group.get(0);
            List<String> sources = group.stream()
                    .map(ProductCandidate::getProvider)
                    .filter(Objects::nonNull)
                    .distinct()
                    .collect(Collectors.toList());

            // Check if this cluster exactly matches requested pack size (if pack size was required)
            boolean isExactPackMatch = true;
            if (identity.getNormalizedPackSizeValue() != null && best.getNormalizedPackSizeValue() != null) {
                double diffRatio = Math.abs(best.getNormalizedPackSizeValue().doubleValue() - identity.getNormalizedPackSizeValue().doubleValue()) / identity.getNormalizedPackSizeValue().doubleValue();
                if (diffRatio > 0.05) {
                    isExactPackMatch = false;
                }
            }

            // Calculate Effective Unit Price & Total Cost for required quantity
            double unitPrice = best.getPriceAsDouble();
            double totalCost = unitPrice * reqQty;

            double unitPricePerBaseUnit = 0.0;
            if (best.getNormalizedPackSizeValue() != null && best.getNormalizedPackSizeValue().doubleValue() > 0) {
                unitPricePerBaseUnit = (unitPrice / best.getNormalizedPackSizeValue().doubleValue()) * 100.0;
            }

            String packSizeStr = best.getPackageSize() != null
                    ? best.getPackageSize()
                    : (identity.getPackSize() != null ? identity.getPackSize().stripTrailingZeros().toPlainString() + (identity.getPackUnit() != null ? identity.getPackUnit() : "") : null);

            // Build StoreOfferDto for each candidate in group and track savings
            List<StoreOfferDto> storeOffers = new ArrayList<>();
            double highestPrice = unitPrice;
            for (ProductCandidate c : group) {
                double cPrice = c.getPriceAsDouble();
                if (cPrice > highestPrice) {
                    highestPrice = cPrice;
                }
                storeOffers.add(StoreOfferDto.builder()
                        .storeName(c.getProvider())
                        .price(c.getPrice())
                        .mrp(c.getOriginalPrice())
                        .deliveryFee(c.getDeliveryCharge() != null ? c.getDeliveryCharge() : BigDecimal.ZERO)
                        .estimatedDelivery(c.getEstimatedDelivery())
                        .availability(c.getAvailability())
                        .productUrl(c.getProductUrl())
                        .canonicalProductUrl(c.getCanonicalProductUrl() != null ? c.getCanonicalProductUrl() : c.getProductUrl())
                        .urlType(c.getUrlType())
                        .urlVerified(c.isUrlVerified())
                        .directProductUrlAvailable(c.isDirectProductUrlAvailable())
                        .affiliateUrl(c.getAffiliateUrl())
                        .deepLink(c.getDeepLink())
                        .rating(c.getSellerRating())
                        .reviewCount(c.getReviewCount())
                        .build());
            }

            double savingsVsHighest = Math.max(0.0, highestPrice - unitPrice);

            String unitPriceLabel = null;
            if (best.getNormalizedPackSizeUnit() != null) {
                if ("ML".equalsIgnoreCase(best.getNormalizedPackSizeUnit())) {
                    unitPriceLabel = "₹" + String.format("%.2f", (unitPrice / best.getNormalizedPackSizeValue().doubleValue()) * 1000.0) + "/L";
                } else if ("G".equalsIgnoreCase(best.getNormalizedPackSizeUnit())) {
                    unitPriceLabel = "₹" + String.format("%.2f", (unitPrice / best.getNormalizedPackSizeValue().doubleValue()) * 1000.0) + "/kg";
                } else {
                    unitPriceLabel = "per " + best.getNormalizedPackSizeUnit();
                }
            }

            String dealId = best.getCandidateId() != null ? best.getCandidateId() : UUID.randomUUID().toString();
            String canonicalUrl = best.getCanonicalProductUrl() != null ? best.getCanonicalProductUrl() : best.getProductUrl();

            ProductDealDto deal = ProductDealDto.builder()
                    .id(dealId)
                    .canonicalProductId(entry.getKey())
                    .productName(best.getProductName())
                    .brand(best.getCanonicalBrand() != null ? best.getCanonicalBrand() : best.getBrand())
                    .category(best.getCategory() != null ? best.getCategory() : identity.getCategory())
                    .packageSize(packSizeStr)
                    .packSize(packSizeStr)
                    .bestProvider(best.getProvider())
                    .seller(best.getProvider())
                    .bestPrice(BigDecimal.valueOf(unitPrice))
                    .price(BigDecimal.valueOf(unitPrice))
                    .mrp(best.getOriginalPrice() != null ? best.getOriginalPrice() : BigDecimal.valueOf(unitPrice))
                    .discountPercent(best.getDiscountPercent())
                    .effectivePrice(BigDecimal.valueOf(unitPrice))
                    .requiredQuantityCost(BigDecimal.valueOf(totalCost))
                    .unitPrice(unitPricePerBaseUnit > 0 ? BigDecimal.valueOf(unitPricePerBaseUnit) : null)
                    .unitPriceLabel(unitPriceLabel)
                    .savingsVsHighest(BigDecimal.valueOf(savingsVsHighest))
                    .storeOffers(storeOffers)
                    .productUrl(best.getProductUrl())
                    .canonicalProductUrl(canonicalUrl)
                    .urlType(best.getUrlType())
                    .urlVerified(best.isUrlVerified())
                    .urlConfidence(best.getUrlConfidence())
                    .directProductUrlAvailable(best.isDirectProductUrlAvailable())
                    .displayedPrice(BigDecimal.valueOf(unitPrice))
                    .verifiedPrice(best.getVerifiedPrice() != null ? best.getVerifiedPrice() : BigDecimal.valueOf(unitPrice))
                    .priceVerifiedAt(best.getPriceVerifiedAt() != null ? best.getPriceVerifiedAt() : Instant.now())
                    .discoverySource(best.getSourceUrl() != null ? best.getSourceUrl() : best.getProvider())
                    .sku(best.getSku())
                    .asin(best.getAsin())
                    .imageUrl(best.getImageUrl())
                    .availability(best.getAvailability() != null ? best.getAvailability() : (best.isInStock() ? "IN_STOCK" : "OUT_OF_STOCK"))
                    .rating(best.getSellerRating())
                    .sourceCount(sources.size())
                    .evidence(best.getEvidence())
                    .identityConfidence(best.getScore() != null ? best.getScore() / 100.0 : 0.8)
                    .matchScore(best.getScore() != null ? best.getScore() : 80.0)
                    .matchStatus(best.getMatchStatus())
                    .isExactMatch(isExactPackMatch)
                    .validationStatus(best.isInStock() ? "VALID" : "OUT_OF_STOCK")
                    .lastVerifiedAt(best.getPriceVerifiedAt() != null ? best.getPriceVerifiedAt() : Instant.now())
                    .freshnessLabel("Verified just now")
                    .build();

            if (isExactPackMatch) {
                primaryDeals.add(deal);
            } else {
                similarDeals.add(deal);
            }
        }

        // Sort deals: best identity confidence first, then lowest required quantity cost
        Comparator<ProductDealDto> dealComparator = Comparator
                .comparingDouble((ProductDealDto d) -> d.getIdentityConfidence() != null ? d.getIdentityConfidence() : 0.0).reversed()
                .thenComparingDouble((ProductDealDto d) -> d.getRequiredQuantityCost() != null ? d.getRequiredQuantityCost().doubleValue() : 0.0);

        primaryDeals.sort(dealComparator);
        similarDeals.sort(dealComparator);

        log.info("Clustering completed: {} clusters -> {} primary deals, {} similar products",
                clusters.size(), primaryDeals.size(), similarDeals.size());

        return ClusteringResult.builder()
                .primaryDeals(primaryDeals)
                .similarProducts(similarDeals)
                .totalClustersCount(clusters.size())
                .build();
    }

    private String buildClusterKey(ProductIdentity identity, ProductCandidate cand) {
        if (cand.getBarcode() != null && !cand.getBarcode().isBlank()) {
            return "BARCODE:" + cand.getBarcode().trim();
        }

        String brand = cand.getCanonicalBrand() != null ? cand.getCanonicalBrand().toLowerCase() : "generic";
        String prod = cand.getCanonicalProduct() != null ? cand.getCanonicalProduct().toLowerCase() : "product";
        String variant = identity.getVariant() != null ? identity.getVariant().toLowerCase() : "standard";
        String pack = cand.getNormalizedPackSizeValue() != null
                ? cand.getNormalizedPackSizeValue() + (cand.getNormalizedPackSizeUnit() != null ? cand.getNormalizedPackSizeUnit() : "")
                : "std";

        return brand + "|" + prod + "|" + variant + "|" + pack;
    }

    private void verifyPricesAndFilterAnomalies(List<ProductCandidate> candidates) {
        if (candidates.size() <= 2) return;

        List<Double> prices = candidates.stream()
                .map(ProductCandidate::getPriceAsDouble)
                .sorted()
                .collect(Collectors.toList());

        double median = prices.get(prices.size() / 2);
        if (median <= 0) return;

        // Flag and remove anomalies: <40% of median (likely a sachet or accessory error) or >300% of median
        candidates.removeIf(c -> {
            double ratio = c.getPriceAsDouble() / median;
            if (ratio < 0.40 || ratio > 3.0) {
                log.warn("Price anomaly detected for candidate '{}' (₹{}, median ₹{}). Filtered out.",
                        c.getProductName(), c.getPrice(), median);
                return true;
            }
            return false;
        });
    }
}
