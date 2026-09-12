package com.homestock.modules.deals.adapter;

import com.homestock.modules.deals.model.*;
import com.homestock.modules.smartshopping.dto.ProductOfferDto;
import com.homestock.modules.smartshopping.provider.ProductSearchRequest;
import com.homestock.modules.smartshopping.provider.online.LiveOnlineShoppingProvider;
import com.homestock.modules.smartshopping.provider.real.RealMarketCatalogProvider;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

@Component
@RequiredArgsConstructor
public class OnlineLiveDealSourceAdapter implements DealSourceAdapter {

    private static final Logger log = LoggerFactory.getLogger(OnlineLiveDealSourceAdapter.class);

    private final LiveOnlineShoppingProvider liveOnlineShoppingProvider;
    private final RealMarketCatalogProvider realMarketCatalogProvider;

    @Override
    public DealSource getSource() {
        return DealSource.ONLINE_LIVE;
    }

    @Override
    public boolean isEnabled() {
        return (liveOnlineShoppingProvider != null && liveOnlineShoppingProvider.isEnabled())
                || (realMarketCatalogProvider != null && realMarketCatalogProvider.isEnabled());
    }

    @Override
    public List<ExternalProduct> searchProducts(ProductSearchRequest request) {
        if (!isEnabled()) return Collections.emptyList();

        List<ExternalProduct> results = new ArrayList<>();
        try {
            if (liveOnlineShoppingProvider != null && liveOnlineShoppingProvider.isEnabled()) {
                List<ProductOfferDto> liveOffers = liveOnlineShoppingProvider.searchProducts(request);
                for (ProductOfferDto o : liveOffers) {
                    results.add(toExternalProduct(o, DealSource.ONLINE_LIVE));
                }
            }
        } catch (Exception e) {
            log.warn("[OnlineLiveDealSourceAdapter] Live online search error: {}", e.getMessage());
        }

        try {
            if (results.isEmpty() && realMarketCatalogProvider != null && realMarketCatalogProvider.isEnabled()) {
                List<ProductOfferDto> catalogOffers = realMarketCatalogProvider.searchProducts(request);
                for (ProductOfferDto o : catalogOffers) {
                    results.add(toExternalProduct(o, DealSource.ONLINE_LIVE));
                }
            }
        } catch (Exception e) {
            log.warn("[OnlineLiveDealSourceAdapter] Catalog search error: {}", e.getMessage());
        }

        return results;
    }

    @Override
    public ProductAvailability checkAvailability(ExternalProduct product) {
        if (product == null) return ProductAvailability.outOfStock();
        boolean available = product.getAvailability() == null || !product.getAvailability().equalsIgnoreCase("OUT_OF_STOCK");
        return ProductAvailability.builder()
                .available(available)
                .status(available ? "IN_STOCK" : "OUT_OF_STOCK")
                .deliveryStatus(available ? "In stock & ready to ship" : "Currently out of stock")
                .estimatedDelivery("Instant delivery (15-30 mins / 1-2 days)")
                .build();
    }

    @Override
    public PriceDetails getCurrentPrice(ExternalProduct product) {
        if (product == null || product.getPrice() == null) {
            return PriceDetails.builder().price(BigDecimal.ZERO).verified(false).build();
        }
        return PriceDetails.builder()
                .price(product.getPrice())
                .mrp(product.getMrp())
                .deliveryCharge(product.getDeliveryCharge() != null ? product.getDeliveryCharge() : BigDecimal.ZERO)
                .currency(product.getCurrency() != null ? product.getCurrency() : "INR")
                .verified(true)
                .build();
    }

    private ExternalProduct toExternalProduct(ProductOfferDto o, DealSource defaultSource) {
        DealSource source = o.getProvider() != null ? DealSource.fromString(o.getProvider()) : defaultSource;
        return ExternalProduct.builder()
                .source(source)
                .externalProductId(o.getProviderProductId())
                .title(o.getProductName())
                .brand(o.getBrand())
                .price(o.getPrice())
                .mrp(o.getPrice())
                .deliveryCharge(o.getDeliveryCharge())
                .currency(o.getCurrency() != null ? o.getCurrency() : "INR")
                .availability(o.getAvailability())
                .deliveryStatus(o.getEstimatedDelivery())
                .productUrl(o.getProductUrl())
                .affiliateUrl(o.getAffiliateUrl())
                .imageUrl(o.getImageUrl())
                .rating(o.getRating() != null ? o.getRating().doubleValue() : null)
                .reviewCount(o.getReviewCount())
                .build();
    }
}
