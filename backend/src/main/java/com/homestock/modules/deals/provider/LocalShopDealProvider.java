package com.homestock.modules.deals.provider;

import com.homestock.modules.bill.entity.ProductPriceHistory;
import com.homestock.modules.bill.repository.ProductPriceHistoryRepository;
import com.homestock.modules.deals.dto.NearbyShopDto;
import com.homestock.modules.deals.dto.ShopDealDto;
import com.homestock.modules.deals.entity.NearbyShop;
import com.homestock.modules.deals.entity.ShopProductOffer;
import com.homestock.modules.deals.repository.NearbyShopRepository;
import com.homestock.modules.deals.repository.ShopProductOfferRepository;
import com.homestock.modules.deals.service.NearbyShopService;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.time.format.DateTimeFormatter;
import java.util.*;

/**
 * Local Shop Deal Provider.
 * Integrates nearby retail store catalog prices with historical bill intelligence.
 */
@Component
@RequiredArgsConstructor
public class LocalShopDealProvider {

    private static final Logger log = LoggerFactory.getLogger(LocalShopDealProvider.class);
    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("d MMM");

    private final NearbyShopService nearbyShopService;
    private final NearbyShopRepository shopRepository;
    private final ShopProductOfferRepository offerRepository;
    private final ProductPriceHistoryRepository billPriceHistoryRepository;

    /**
     * Search verified product deals across nearby physical shops.
     */
    public List<ShopDealDto> searchLocalDeals(
            String query,
            BigDecimal latitude,
            BigDecimal longitude,
            Double radiusKm,
            UUID homeId,
            UUID productId
    ) {
        if (query == null || query.isBlank()) {
            return Collections.emptyList();
        }

        // 1. Discover nearby grocery stores within radius
        List<NearbyShopDto> nearbyShops = nearbyShopService.findNearbyShops(latitude, longitude, radiusKm);
        if (nearbyShops.isEmpty()) {
            return Collections.emptyList();
        }

        List<UUID> shopIds = nearbyShops.stream().map(NearbyShopDto::getId).toList();
        Map<UUID, NearbyShopDto> shopDtoMap = new HashMap<>();
        nearbyShops.forEach(s -> shopDtoMap.put(s.getId(), s));

        // 2. Fetch verified offers in these shops matching the product query
        List<ShopProductOffer> offers = offerRepository.searchOffersInShops(shopIds, query.trim());

        // 3. User Bill Intelligence: Fetch user's previous purchase record for this product
        HistoricalBenchmark benchmark = fetchUserPreviousPurchase(homeId, productId);

        List<ShopDealDto> results = new ArrayList<>();
        for (ShopProductOffer offer : offers) {
            NearbyShopDto shopDto = shopDtoMap.get(offer.getShop().getId());
            NearbyShop shop = offer.getShop();
            Double distanceKm = shopDto != null ? shopDto.getDistanceKm() : null;

            ShopDealDto dealDto = nearbyShopService.toShopDealDto(shop, offer, distanceKm);

            // Attach user previous bill purchase info
            if (benchmark != null) {
                dealDto.setUserPreviousPrice(benchmark.price());
                dealDto.setUserPreviousPurchaseDate(benchmark.recordedAt());
                dealDto.setUserPreviousStoreName(benchmark.storeName());

                if (dealDto.getPrice() != null && benchmark.price() != null) {
                    if (dealDto.getPrice().compareTo(benchmark.price()) < 0) {
                        BigDecimal saved = benchmark.price().subtract(dealDto.getPrice());
                        dealDto.setPriceComparisonNote(String.format(
                                "Your previous price was ₹%s on %s. Save ₹%s nearby!",
                                benchmark.price(), benchmark.dateLabel(), saved
                        ));
                    } else {
                        dealDto.setPriceComparisonNote(String.format(
                                "Last purchased at ₹%s on %s at %s",
                                benchmark.price(), benchmark.dateLabel(), benchmark.storeName()
                        ));
                    }
                }
            }

            results.add(dealDto);
        }

        // Sort by effective price ascending
        results.sort(Comparator.comparing(
                d -> d.getEffectivePrice() != null ? d.getEffectivePrice() : BigDecimal.valueOf(999999)
        ));

        return results;
    }

    private record HistoricalBenchmark(
            BigDecimal price,
            java.time.Instant recordedAt,
            String dateLabel,
            String storeName
    ) {}

    private HistoricalBenchmark fetchUserPreviousPurchase(UUID homeId, UUID productId) {
        if (homeId == null || productId == null) return null;

        try {
            List<ProductPriceHistory> history = billPriceHistoryRepository
                    .findByHomeIdAndProductIdOrderByPurchaseDateDesc(homeId, productId, PageRequest.of(0, 1));

            if (!history.isEmpty()) {
                ProductPriceHistory record = history.get(0);
                String label = record.getPurchaseDate() != null ? record.getPurchaseDate().format(DATE_FMT) : "recently";
                return new HistoricalBenchmark(
                        record.getUnitPrice(),
                        record.getCreatedAt(),
                        label,
                        record.getStoreName() != null ? record.getStoreName() : "Local Store"
                );
            }
        } catch (Exception e) {
            log.debug("[LocalShopDealProvider] Historical bill query exception: {}", e.getMessage());
        }

        return null;
    }
}
