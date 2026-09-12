package com.homestock.modules.deals.adapter;

import com.homestock.modules.deals.model.*;
import com.homestock.modules.smartshopping.dto.ProductOfferDto;
import com.homestock.modules.smartshopping.provider.ProductSearchRequest;
import com.homestock.modules.smartshopping.provider.flipkart.FlipkartProvider;
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
public class FlipkartDealSourceAdapter implements DealSourceAdapter {

    private static final Logger log = LoggerFactory.getLogger(FlipkartDealSourceAdapter.class);

    private final FlipkartProvider flipkartProvider;

    @Override
    public DealSource getSource() {
        return DealSource.FLIPKART;
    }

    @Override
    public boolean isEnabled() {
        return flipkartProvider != null && flipkartProvider.isEnabled();
    }

    @Override
    public List<ExternalProduct> searchProducts(ProductSearchRequest request) {
        if (!isEnabled()) {
            return Collections.emptyList();
        }
        try {
            List<ProductOfferDto> offers = flipkartProvider.searchProducts(request);
            List<ExternalProduct> result = new ArrayList<>();
            for (ProductOfferDto o : offers) {
                result.add(toExternalProduct(o));
            }
            return result;
        } catch (Exception e) {
            log.error("[FlipkartDealSourceAdapter] Search failed: {}", e.getMessage());
            return Collections.emptyList();
        }
    }

    @Override
    public ProductAvailability checkAvailability(ExternalProduct product) {
        if (product == null) return ProductAvailability.outOfStock();
        return ProductAvailability.inStock("Standard 2-3 day delivery");
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

    private ExternalProduct toExternalProduct(ProductOfferDto o) {
        return ExternalProduct.builder()
                .source(DealSource.FLIPKART)
                .externalProductId(o.getProviderProductId())
                .title(o.getProductName())
                .brand(o.getBrand())
                .price(o.getPrice())
                .mrp(o.getPrice())
                .deliveryCharge(o.getDeliveryCharge())
                .currency(o.getCurrency() != null ? o.getCurrency() : "INR")
                .availability(o.getAvailability())
                .productUrl(o.getProductUrl())
                .affiliateUrl(o.getAffiliateUrl())
                .imageUrl(o.getImageUrl())
                .rating(o.getRating() != null ? o.getRating().doubleValue() : null)
                .reviewCount(o.getReviewCount())
                .build();
    }
}
