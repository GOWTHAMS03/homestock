package com.homestock.modules.shop.service;

import com.homestock.core.exception.ResourceNotFoundException;
import com.homestock.core.security.ShopSecurityService;
import com.homestock.modules.deals.entity.NearbyShop;
import com.homestock.modules.deals.entity.ShopProductOffer;
import com.homestock.modules.deals.repository.NearbyShopRepository;
import com.homestock.modules.deals.repository.ShopProductOfferRepository;
import com.homestock.modules.shop.dto.demand.*;
import com.homestock.modules.shop.entity.CustomerDemandEvent;
import com.homestock.modules.shop.entity.DemandEventType;
import com.homestock.modules.shop.entity.ShopSubscription;
import com.homestock.modules.shop.entity.SubscriptionPlan;
import com.homestock.modules.shop.repository.CustomerDemandEventRepository;
import com.homestock.modules.shop.repository.ShopSubscriptionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class CustomerDemandService {

    private static final double DEFAULT_LAT = 12.9716;
    private static final double DEFAULT_LON = 77.5946;
    private static final int PRIVACY_MIN_SIGNALS = 3;

    private final CustomerDemandEventRepository demandEventRepository;
    private final NearbyShopRepository nearbyShopRepository;
    private final ShopProductOfferRepository shopProductOfferRepository;
    private final ShopSubscriptionRepository subscriptionRepository;
    private final ShopSecurityService shopSecurityService;

    /**
     * Aggregates anonymized, location-aware customer demand intelligence for a shop owner.
     */
    @Transactional(readOnly = true)
    public CustomerDemandDashboardResponse getShopDemandDashboard(
            UUID shopId,
            DemandPeriod period,
            Double radiusKm) {

        if (!shopSecurityService.canManageShop(shopId)) {
            throw new org.springframework.security.access.AccessDeniedException("Access denied to manage shop: " + shopId);
        }

        NearbyShop shop = nearbyShopRepository.findById(shopId)
                .orElseThrow(() -> new ResourceNotFoundException("Shop not found with ID: " + shopId));

        double centerLat = shop.getLatitude() != null ? shop.getLatitude().doubleValue() : DEFAULT_LAT;
        double centerLon = shop.getLongitude() != null ? shop.getLongitude().doubleValue() : DEFAULT_LON;
        double effectiveRadius = (radiusKm != null && radiusKm > 0) ? radiusKm : 5.0;
        DemandPeriod effectivePeriod = period != null ? period : DemandPeriod.LAST_7_DAYS;

        // Subscription Check
        ShopSubscription activeSub = subscriptionRepository.findActiveSubscription(shopId).orElse(null);
        SubscriptionPlan plan = activeSub != null ? activeSub.getPlan() : null;
        String tierName = plan != null ? plan.getName() : "FREE";
        boolean isGated = plan == null || !Boolean.TRUE.equals(plan.getAnalyticsEnabled());

        // Temporal bounds
        Instant now = Instant.now();
        Instant currentStart = now.minus(effectivePeriod.getDays(), ChronoUnit.DAYS);
        Instant prevStart = currentStart.minus(effectivePeriod.getDays(), ChronoUnit.DAYS);
        Instant prevEnd = currentStart;

        // Bounding box
        BoundingBox bbox = calculateBoundingBox(centerLat, centerLon, effectiveRadius);

        // Fetch events
        List<CustomerDemandEvent> rawCurrentEvents = demandEventRepository.findEventsInBoundingBoxAndDateRange(
                bbox.minLat, bbox.maxLat, bbox.minLon, bbox.maxLon, currentStart, now);

        List<CustomerDemandEvent> rawPrevEvents = demandEventRepository.findEventsInBoundingBoxAndDateRange(
                bbox.minLat, bbox.maxLat, bbox.minLon, bbox.maxLon, prevStart, prevEnd);

        // Filter strictly by Haversine distance
        List<EventWithDistance> currentEvents = rawCurrentEvents.stream()
                .map(e -> new EventWithDistance(e, haversineKm(centerLat, centerLon, e.getLatitude().doubleValue(), e.getLongitude().doubleValue())))
                .filter(ed -> ed.distanceKm <= effectiveRadius)
                .toList();

        List<EventWithDistance> prevEvents = rawPrevEvents.stream()
                .map(e -> new EventWithDistance(e, haversineKm(centerLat, centerLon, e.getLatitude().doubleValue(), e.getLongitude().doubleValue())))
                .filter(ed -> ed.distanceKm <= effectiveRadius)
                .toList();

        // Shop's current catalog offers
        List<ShopProductOffer> shopOffers = shopProductOfferRepository.findByShopId(shopId);
        Map<UUID, ShopProductOffer> shopOffersByProductId = new HashMap<>();
        Map<String, ShopProductOffer> shopOffersByNormalizedName = new HashMap<>();
        for (ShopProductOffer offer : shopOffers) {
            if (offer.getProduct() != null) {
                shopOffersByProductId.put(offer.getProduct().getId(), offer);
            }
            if (offer.getNormalizedName() != null) {
                shopOffersByNormalizedName.put(offer.getNormalizedName().toLowerCase(), offer);
            }
        }

        // Competitor offers nearby for price comparisons
        List<NearbyShop> nearbyShops = nearbyShopRepository.findVerifiedShopsInBoundingBox(
                bbox.minLat, bbox.maxLat, bbox.minLon, bbox.maxLon);
        List<UUID> competitorShopIds = nearbyShops.stream()
                .map(NearbyShop::getId)
                .filter(id -> !id.equals(shopId))
                .toList();

        Map<UUID, List<BigDecimal>> competitorPricesByProductId = new HashMap<>();
        Map<String, List<BigDecimal>> competitorPricesByName = new HashMap<>();
        if (!competitorShopIds.isEmpty()) {
            List<ShopProductOffer> competitorOffers = shopProductOfferRepository.findByShopIdIn(competitorShopIds);
            for (ShopProductOffer offer : competitorOffers) {
                if (offer.getPrice() != null && offer.getPrice().compareTo(BigDecimal.ZERO) > 0) {
                    if (offer.getProduct() != null) {
                        competitorPricesByProductId.computeIfAbsent(offer.getProduct().getId(), k -> new ArrayList<>()).add(offer.getPrice());
                    }
                    if (offer.getNormalizedName() != null) {
                        competitorPricesByName.computeIfAbsent(offer.getNormalizedName().toLowerCase(), k -> new ArrayList<>()).add(offer.getPrice());
                    }
                }
            }
        }

        // Previous period score by normalized query
        Map<String, Double> prevScoreByQuery = calculateScoresByQuery(prevEvents, prevStart, prevEnd);

        // Group current events by normalized query
        Map<String, List<EventWithDistance>> eventsByQuery = currentEvents.stream()
                .collect(Collectors.groupingBy(ed -> ed.event.getNormalizedQuery()));

        List<ProductDemandItemDto> demandItems = new ArrayList<>();
        List<DemandOpportunityDto> opportunities = new ArrayList<>();

        for (Map.Entry<String, List<EventWithDistance>> entry : eventsByQuery.entrySet()) {
            String normQuery = entry.getKey();
            List<EventWithDistance> events = entry.getValue();

            CustomerDemandEvent sample = events.get(0).event;
            String displayName = sample.getQueryText();
            String category = sample.getCategoryName() != null ? sample.getCategoryName() : "General";
            UUID canonicalProductId = sample.getProductId();

            double currentScore = calculateGroupScore(events, now);
            double prevScore = prevScoreByQuery.getOrDefault(normQuery, 0.0);

            DemandTrend trend = calculateTrend(currentScore, prevScore);
            Double percentageGrowth = calculateGrowthPercentage(currentScore, prevScore);

            // Catalog matching
            ShopProductOffer matchingOffer = null;
            if (canonicalProductId != null && shopOffersByProductId.containsKey(canonicalProductId)) {
                matchingOffer = shopOffersByProductId.get(canonicalProductId);
            } else if (shopOffersByNormalizedName.containsKey(normQuery)) {
                matchingOffer = shopOffersByNormalizedName.get(normQuery);
            }

            boolean inCatalog = matchingOffer != null;
            String stockStatus = inCatalog
                    ? (matchingOffer.getAvailabilityStatus() != null ? matchingOffer.getAvailabilityStatus() : "IN_STOCK")
                    : "NOT_IN_CATALOG";
            BigDecimal currentPrice = inCatalog ? matchingOffer.getPrice() : null;

            // Competitor price analysis
            List<BigDecimal> compPrices = new ArrayList<>();
            if (canonicalProductId != null && competitorPricesByProductId.containsKey(canonicalProductId)) {
                compPrices.addAll(competitorPricesByProductId.get(canonicalProductId));
            } else if (competitorPricesByName.containsKey(normQuery)) {
                compPrices.addAll(competitorPricesByName.get(normQuery));
            }

            BigDecimal minCompPrice = null;
            BigDecimal avgCompPrice = null;
            if (!compPrices.isEmpty()) {
                minCompPrice = compPrices.stream().min(BigDecimal::compareTo).orElse(null);
                BigDecimal sum = compPrices.stream().reduce(BigDecimal.ZERO, BigDecimal::add);
                avgCompPrice = sum.divide(BigDecimal.valueOf(compPrices.size()), 2, RoundingMode.HALF_UP);
            }

            // Geographic zone dominance
            String dominantZone = calculateDominantZone(events);

            boolean lowData = events.size() < PRIVACY_MIN_SIGNALS;

            ProductDemandItemDto itemDto = ProductDemandItemDto.builder()
                    .productName(displayName)
                    .categoryName(category)
                    .canonicalProductId(canonicalProductId)
                    .shopOfferId(matchingOffer != null ? matchingOffer.getId() : null)
                    .totalSignals(events.size())
                    .demandScore(round2(currentScore))
                    .trend(trend)
                    .percentageGrowth(percentageGrowth)
                    .inShopCatalog(inCatalog)
                    .shopStockStatus(stockStatus)
                    .shopPrice(currentPrice)
                    .minCompetitorPrice(minCompPrice)
                    .avgCompetitorPrice(avgCompPrice)
                    .lowDataWarning(lowData)
                    .topZone(dominantZone)
                    .build();

            demandItems.add(itemDto);

            // Identify Actionable Opportunities
            generateOpportunities(itemDto, matchingOffer, currentScore, minCompPrice, opportunities);
        }

        // Sort items by demand score descending
        demandItems.sort((a, b) -> Double.compare(b.getDemandScore(), a.getDemandScore()));

        // Sort opportunities by priority score descending
        opportunities.sort((a, b) -> Double.compare(b.getPriorityScore(), a.getPriorityScore()));

        // Concentric Demand Zones
        List<DemandZoneDto> demandZones = calculateConcentricZones(currentEvents, effectiveRadius);

        // Counts
        long missingProductsCount = opportunities.stream()
                .filter(o -> o.getType() == OpportunityType.MISSING_PRODUCT).count();
        long restockOpportunitiesCount = opportunities.stream()
                .filter(o -> o.getType() == OpportunityType.OUT_OF_STOCK || o.getType() == OpportunityType.LOW_STOCK).count();
        long priceOpportunitiesCount = opportunities.stream()
                .filter(o -> o.getType() == OpportunityType.PRICE_OPPORTUNITY).count();

        // Gating for FREE tier
        List<ProductDemandItemDto> finalItems = demandItems;
        List<DemandOpportunityDto> finalOpportunities = opportunities;
        if (isGated) {
            finalItems = demandItems.stream().limit(5).toList();
            finalOpportunities = opportunities.stream().limit(2).toList();
        }

        String summaryInsight = generateSummaryInsight(demandItems, opportunities, effectivePeriod);

        return CustomerDemandDashboardResponse.builder()
                .shopId(shopId)
                .shopName(shop.getName())
                .period(effectivePeriod.name())
                .radiusKm(effectiveRadius)
                .totalDemandSignals(currentEvents.size())
                .uniqueSearchQueries(eventsByQuery.size())
                .missingProductsCount(missingProductsCount)
                .restockOpportunitiesCount(restockOpportunitiesCount)
                .priceOpportunitiesCount(priceOpportunitiesCount)
                .topDemandedProducts(finalItems)
                .opportunities(finalOpportunities)
                .demandZones(demandZones)
                .isGated(isGated)
                .subscriptionTier(tierName)
                .summaryInsight(summaryInsight)
                .build();
    }

    /**
     * Search specific customer demand details for an individual product or query.
     */
    @Transactional(readOnly = true)
    public ProductDemandDetailResponse searchProductDemandDetail(
            UUID shopId,
            String query,
            Double radiusKm) {

        if (!shopSecurityService.canManageShop(shopId)) {
            throw new org.springframework.security.access.AccessDeniedException("Access denied to manage shop: " + shopId);
        }

        if (query == null || query.isBlank()) {
            throw new IllegalArgumentException("Query must not be empty");
        }

        NearbyShop shop = nearbyShopRepository.findById(shopId)
                .orElseThrow(() -> new ResourceNotFoundException("Shop not found with ID: " + shopId));

        double centerLat = shop.getLatitude() != null ? shop.getLatitude().doubleValue() : DEFAULT_LAT;
        double centerLon = shop.getLongitude() != null ? shop.getLongitude().doubleValue() : DEFAULT_LON;
        double effectiveRadius = (radiusKm != null && radiusKm > 0) ? radiusKm : 5.0;

        Instant now = Instant.now();
        Instant start = now.minus(30, ChronoUnit.DAYS);

        BoundingBox bbox = calculateBoundingBox(centerLat, centerLon, effectiveRadius);

        List<CustomerDemandEvent> rawEvents = demandEventRepository.findEventsByQueryInBoundingBox(
                query.trim(), bbox.minLat, bbox.maxLat, bbox.minLon, bbox.maxLon, start, now);

        List<EventWithDistance> events = rawEvents.stream()
                .map(e -> new EventWithDistance(e, haversineKm(centerLat, centerLon, e.getLatitude().doubleValue(), e.getLongitude().doubleValue())))
                .filter(ed -> ed.distanceKm <= effectiveRadius)
                .toList();

        Map<String, Long> signalsByType = events.stream()
                .collect(Collectors.groupingBy(ed -> ed.event.getEventType().name(), Collectors.counting()));

        double score = calculateGroupScore(events, now);

        // Shop catalog check
        List<ShopProductOffer> shopOffers = shopProductOfferRepository.findByShopId(shopId);
        String norm = query.trim().toLowerCase();
        ShopProductOffer matchingOffer = shopOffers.stream()
                .filter(o -> (o.getNormalizedName() != null && o.getNormalizedName().equalsIgnoreCase(norm))
                        || (o.getRawProductName() != null && o.getRawProductName().toLowerCase().contains(norm)))
                .findFirst()
                .orElse(null);

        // Concentric zones for this product
        List<DemandZoneDto> zones = calculateConcentricZones(events, effectiveRadius);

        return ProductDemandDetailResponse.builder()
                .queryText(query.trim())
                .canonicalProductId(events.isEmpty() ? null : events.get(0).event.getProductId())
                .categoryName(events.isEmpty() ? null : events.get(0).event.getCategoryName())
                .totalSignals(events.size())
                .demandScore(round2(score))
                .trend(DemandTrend.NORMAL)
                .signalsByType(signalsByType)
                .breakdownByZone(zones)
                .inShopCatalog(matchingOffer != null)
                .shopOfferId(matchingOffer != null ? matchingOffer.getId() : null)
                .shopStockStatus(matchingOffer != null ? matchingOffer.getAvailabilityStatus() : "NOT_IN_CATALOG")
                .shopPrice(matchingOffer != null ? matchingOffer.getPrice() : null)
                .build();
    }

    // ---------------- HELPER CALCULATIONS ----------------

    private void generateOpportunities(
            ProductDemandItemDto item,
            ShopProductOffer matchingOffer,
            double currentScore,
            BigDecimal minCompPrice,
            List<DemandOpportunityDto> opportunities) {

        // 1. Missing from catalog
        if (!item.isInShopCatalog() && (item.getTotalSignals() >= 2 || currentScore >= 5.0)) {
            opportunities.add(DemandOpportunityDto.builder()
                    .id("gap-" + item.getProductName().toLowerCase().replaceAll("\\s+", "-"))
                    .type(OpportunityType.MISSING_PRODUCT)
                    .title("Add " + item.getProductName() + " to Catalog")
                    .description(item.getTotalSignals() + " nearby customers searched for this recently. Stocking this item can attract new shoppers.")
                    .productName(item.getProductName())
                    .categoryName(item.getCategoryName())
                    .productId(item.getCanonicalProductId())
                    .priorityScore(round2(currentScore * 1.3))
                    .suggestedAction("Add to Catalog")
                    .localDemandCount(item.getTotalSignals())
                    .build());
        }

        // 2. Out of stock
        if (item.isInShopCatalog() && "OUT_OF_STOCK".equalsIgnoreCase(item.getShopStockStatus())) {
            opportunities.add(DemandOpportunityDto.builder()
                    .id("oos-" + (matchingOffer != null ? matchingOffer.getId() : item.getProductName()))
                    .type(OpportunityType.OUT_OF_STOCK)
                    .title("Restock " + item.getProductName())
                    .description("Currently marked Out of Stock while " + item.getTotalSignals() + " local customers are actively searching for it.")
                    .productName(item.getProductName())
                    .categoryName(item.getCategoryName())
                    .productId(item.getCanonicalProductId())
                    .shopOfferId(item.getShopOfferId())
                    .priorityScore(round2(currentScore * 1.6))
                    .suggestedAction("Restock Item")
                    .currentShopPrice(item.getShopPrice())
                    .localDemandCount(item.getTotalSignals())
                    .build());
        }

        // 3. Low stock
        if (item.isInShopCatalog() && "LOW_STOCK".equalsIgnoreCase(item.getShopStockStatus())) {
            opportunities.add(DemandOpportunityDto.builder()
                    .id("low-" + (matchingOffer != null ? matchingOffer.getId() : item.getProductName()))
                    .type(OpportunityType.LOW_STOCK)
                    .title("Low Stock Warning: " + item.getProductName())
                    .description("High local demand detected. Ensure replenishment to avoid missed sales.")
                    .productName(item.getProductName())
                    .categoryName(item.getCategoryName())
                    .productId(item.getCanonicalProductId())
                    .shopOfferId(item.getShopOfferId())
                    .priorityScore(round2(currentScore * 1.1))
                    .suggestedAction("Update Stock")
                    .currentShopPrice(item.getShopPrice())
                    .localDemandCount(item.getTotalSignals())
                    .build());
        }

        // 4. Competitor price comparison (ONLY if real verified competitor prices exist)
        if (item.isInShopCatalog() && minCompPrice != null && item.getShopPrice() != null) {
            if (item.getShopPrice().compareTo(minCompPrice) > 0) {
                BigDecimal diff = item.getShopPrice().subtract(minCompPrice);
                opportunities.add(DemandOpportunityDto.builder()
                        .id("price-" + (matchingOffer != null ? matchingOffer.getId() : item.getProductName()))
                        .type(OpportunityType.PRICE_OPPORTUNITY)
                        .title("Review Price: " + item.getProductName())
                        .description("Nearby verified shops offer this from ₹" + minCompPrice + " (₹" + diff + " lower than your ₹" + item.getShopPrice() + ").")
                        .productName(item.getProductName())
                        .categoryName(item.getCategoryName())
                        .productId(item.getCanonicalProductId())
                        .shopOfferId(item.getShopOfferId())
                        .priorityScore(round2(currentScore * 0.9))
                        .suggestedAction("Adjust Price")
                        .currentShopPrice(item.getShopPrice())
                        .competitorPrice(minCompPrice)
                        .localDemandCount(item.getTotalSignals())
                        .build());
            }
        }
    }

    private double calculateGroupScore(List<EventWithDistance> events, Instant referenceTime) {
        double total = 0.0;
        for (EventWithDistance ed : events) {
            double baseWeight = ed.event.getEventType().getBaseWeight();

            // Exponential recency decay (7-day half life)
            long secondsAgo = Math.max(0, ChronoUnit.SECONDS.between(ed.event.getCreatedAt(), referenceTime));
            double daysAgo = secondsAgo / 86400.0;
            double decayFactor = Math.pow(0.5, daysAgo / 7.0);

            // Distance relevance factor
            double distFactor;
            if (ed.distanceKm <= 1.0) {
                distFactor = 1.0;
            } else if (ed.distanceKm <= 3.0) {
                distFactor = 0.85;
            } else if (ed.distanceKm <= 5.0) {
                distFactor = 0.65;
            } else {
                distFactor = 0.40;
            }

            total += (baseWeight * decayFactor * distFactor);
        }
        return total;
    }

    private Map<String, Double> calculateScoresByQuery(List<EventWithDistance> events, Instant start, Instant end) {
        Map<String, List<EventWithDistance>> grouped = events.stream()
                .collect(Collectors.groupingBy(ed -> ed.event.getNormalizedQuery()));

        Map<String, Double> result = new HashMap<>();
        for (Map.Entry<String, List<EventWithDistance>> e : grouped.entrySet()) {
            result.put(e.getKey(), calculateGroupScore(e.getValue(), end));
        }
        return result;
    }

    private DemandTrend calculateTrend(double currentScore, double prevScore) {
        if (currentScore < 5.0 && prevScore < 5.0) {
            return DemandTrend.NORMAL;
        }
        if (prevScore <= 0.01) {
            return currentScore >= 8.0 ? DemandTrend.HIGH_DEMAND : DemandTrend.RISING;
        }
        double growth = (currentScore - prevScore) / prevScore;
        if (growth >= 0.40) {
            return DemandTrend.HIGH_DEMAND;
        } else if (growth >= 0.15) {
            return DemandTrend.RISING;
        } else if (growth <= -0.20) {
            return DemandTrend.FALLING;
        } else {
            return DemandTrend.NORMAL;
        }
    }

    private Double calculateGrowthPercentage(double currentScore, double prevScore) {
        // Suppress volatile percentage for small numbers
        if (currentScore < 5.0 && prevScore < 5.0) {
            return null;
        }
        if (prevScore <= 0.01) {
            return null;
        }
        double growth = ((currentScore - prevScore) / prevScore) * 100.0;
        return round2(growth);
    }

    private String calculateDominantZone(List<EventWithDistance> events) {
        long d1 = events.stream().filter(ed -> ed.distanceKm <= 1.0).count();
        long d3 = events.stream().filter(ed -> ed.distanceKm > 1.0 && ed.distanceKm <= 3.0).count();
        long d5 = events.stream().filter(ed -> ed.distanceKm > 3.0).count();

        if (d1 >= d3 && d1 >= d5) return "0 - 1 km";
        if (d3 >= d1 && d3 >= d5) return "1 - 3 km";
        return "3 - 5 km";
    }

    private List<DemandZoneDto> calculateConcentricZones(List<EventWithDistance> events, double maxRadiusKm) {
        List<ZoneDefinition> defs = List.of(
                new ZoneDefinition("0 - 1 km (Hyperlocal)", 0.0, 1.0),
                new ZoneDefinition("1 - 3 km (Neighborhood)", 1.0, 3.0),
                new ZoneDefinition("3 - 5 km (Extended)", 3.0, Math.min(5.0, maxRadiusKm)),
                new ZoneDefinition("5 - 10 km (Wider Area)", 5.0, Math.max(5.0, maxRadiusKm))
        );

        long totalSignals = events.size();
        List<DemandZoneDto> zones = new ArrayList<>();

        for (ZoneDefinition def : defs) {
            if (def.minKm >= maxRadiusKm) continue;

            List<EventWithDistance> inZone = events.stream()
                    .filter(ed -> ed.distanceKm >= def.minKm && ed.distanceKm < def.maxKm)
                    .toList();

            double share = totalSignals > 0 ? (inZone.size() * 100.0 / totalSignals) : 0.0;

            // Top search terms in this zone
            List<String> topTerms = inZone.stream()
                    .collect(Collectors.groupingBy(ed -> ed.event.getQueryText(), Collectors.counting()))
                    .entrySet().stream()
                    .sorted((a, b) -> Long.compare(b.getValue(), a.getValue()))
                    .limit(3)
                    .map(Map.Entry::getKey)
                    .toList();

            zones.add(DemandZoneDto.builder()
                    .zoneLabel(def.label)
                    .minRadiusKm(def.minKm)
                    .maxRadiusKm(def.maxKm)
                    .totalEvents(inZone.size())
                    .demandSharePercentage(round2(share))
                    .topSearchTerms(topTerms)
                    .build());
        }

        return zones;
    }

    private String generateSummaryInsight(
            List<ProductDemandItemDto> items,
            List<DemandOpportunityDto> opportunities,
            DemandPeriod period) {

        if (items.isEmpty()) {
            return "Demand signals are gathering in your neighborhood. Check back as more local shoppers search.";
        }

        String topNames = items.stream()
                .limit(3)
                .map(ProductDemandItemDto::getProductName)
                .collect(Collectors.joining(", "));

        long missingCount = opportunities.stream().filter(o -> o.getType() == OpportunityType.MISSING_PRODUCT).count();
        long oosCount = opportunities.stream().filter(o -> o.getType() == OpportunityType.OUT_OF_STOCK).count();

        String periodText = period == DemandPeriod.TODAY ? "today" : "this week";

        if (missingCount > 0 && oosCount > 0) {
            return String.format("Top searched %s: %s. You have %d catalog gaps and %d restock alerts.",
                    periodText, topNames, missingCount, oosCount);
        } else if (missingCount > 0) {
            return String.format("Top searched %s: %s. %d high-demand items are missing from your catalog.",
                    periodText, topNames, missingCount);
        } else if (oosCount > 0) {
            return String.format("High demand for %s. Restock %d out-of-stock items to capture ready buyers.",
                    topNames, oosCount);
        } else {
            return String.format("Top demanded items near your shop %s: %s. Your catalog coverage is strong.",
                    periodText, topNames);
        }
    }

    private BoundingBox calculateBoundingBox(double lat, double lon, double radiusKm) {
        double deltaLat = radiusKm / 111.0;
        double deltaLon = radiusKm / (111.0 * Math.cos(Math.toRadians(lat)));
        return new BoundingBox(
                BigDecimal.valueOf(lat - deltaLat),
                BigDecimal.valueOf(lat + deltaLat),
                BigDecimal.valueOf(lon - deltaLon),
                BigDecimal.valueOf(lon + deltaLon)
        );
    }

    public static double haversineKm(double lat1, double lon1, double lat2, double lon2) {
        final int R = 6371;
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
                Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2)) *
                Math.sin(dLon / 2) * Math.sin(dLon / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c;
    }

    private static double round2(double val) {
        return Math.round(val * 100.0) / 100.0;
    }

    private record EventWithDistance(CustomerDemandEvent event, double distanceKm) {}
    private record BoundingBox(BigDecimal minLat, BigDecimal maxLat, BigDecimal minLon, BigDecimal maxLon) {}
    private record ZoneDefinition(String label, double minKm, double maxKm) {}
}
