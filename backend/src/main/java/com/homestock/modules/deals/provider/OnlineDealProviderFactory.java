package com.homestock.modules.deals.provider;

import com.homestock.modules.deals.adapter.DealSourceAdapterRegistry;
import com.homestock.modules.deals.dto.BasketOptimizationResponseDto.OnlineDealOfferDto;
import com.homestock.modules.deals.model.DealSource;
import com.homestock.modules.deals.model.ExternalProduct;
import com.homestock.modules.smartshopping.provider.ProductSearchRequest;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.*;

/**
 * OnlineDealProviderFactory:
 * Coordinates structured deal retrieval across online platforms (Amazon, Flipkart, Blinkit, BigBasket, Zepto, JioMart)
 * without fragile web scraping or CAPTCHA bypassing.
 */
@Component
@RequiredArgsConstructor
public class OnlineDealProviderFactory {

    private static final Logger log = LoggerFactory.getLogger(OnlineDealProviderFactory.class);

    private final DealSourceAdapterRegistry adapterRegistry;

    /**
     * Fetch online offers for a product query.
     */
    public List<OnlineDealOfferDto> searchOnlineOffers(String productName, BigDecimal quantity, String unit) {
        if (productName == null || productName.isBlank()) {
            return Collections.emptyList();
        }

        ProductSearchRequest request = ProductSearchRequest.builder()
                .itemName(productName)
                .quantity(quantity)
                .unit(unit)
                .maxResults(10)
                .build();

        List<ExternalProduct> rawCandidates;
        try {
            rawCandidates = adapterRegistry.searchAll(request);
        } catch (Exception e) {
            log.warn("[OnlineDealProviderFactory] Adapter search failed: {}", e.getMessage());
            rawCandidates = Collections.emptyList();
        }

        List<OnlineDealOfferDto> offers = new ArrayList<>();
        for (ExternalProduct p : rawCandidates) {
            BigDecimal price = p.getPrice() != null ? p.getPrice() : BigDecimal.ZERO;
            BigDecimal delivery = p.getDeliveryCharge() != null ? p.getDeliveryCharge() : BigDecimal.ZERO;
            BigDecimal effective = price.add(delivery);

            BigDecimal unitPrice = null;
            String unitPriceLabel = null;
            if (p.getQuantity() != null && p.getQuantity().compareTo(BigDecimal.ZERO) > 0) {
                unitPrice = price.divide(p.getQuantity(), 2, RoundingMode.HALF_UP);
                unitPriceLabel = "₹" + unitPrice + " / " + (p.getUnit() != null ? p.getUnit() : "unit");
            }

            boolean inStock = p.getAvailability() != null && !"OUT_OF_STOCK".equalsIgnoreCase(p.getAvailability());

            offers.add(OnlineDealOfferDto.builder()
                    .provider(p.getSource() != null ? p.getSource().getDisplayName() : "Online Store")
                    .title(p.getTitle())
                    .price(price)
                    .deliveryCharge(delivery)
                    .effectivePrice(effective)
                    .pricePerUnit(unitPrice)
                    .pricePerUnitLabel(unitPriceLabel)
                    .productUrl(p.getProductUrl())
                    .stockStatus(inStock ? "IN_STOCK" : "OUT_OF_STOCK")
                    .estimatedDelivery(p.getDeliveryStatus() != null ? p.getDeliveryStatus() : "2-3 days delivery")
                    .build());
        }

        offers.sort(Comparator.comparing(OnlineDealOfferDto::getEffectivePrice));
        return offers;
    }
}
