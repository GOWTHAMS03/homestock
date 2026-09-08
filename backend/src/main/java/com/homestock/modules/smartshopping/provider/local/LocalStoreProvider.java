package com.homestock.modules.smartshopping.provider.local;

import com.homestock.modules.smartshopping.dto.ProductOfferDto;
import com.homestock.modules.smartshopping.entity.PriceHistory;
import com.homestock.modules.smartshopping.provider.ProductSearchRequest;
import com.homestock.modules.smartshopping.provider.ProviderCapability;
import com.homestock.modules.smartshopping.provider.ShoppingProvider;
import com.homestock.modules.smartshopping.repository.PriceHistoryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.*;

/**
 * Local store provider supporting user-reported prices and manual prices.
 * Never fabricates prices: strictly uses historical user reports or explicit store submissions.
 */
@Component
@RequiredArgsConstructor
public class LocalStoreProvider implements ShoppingProvider {

    private final PriceHistoryRepository priceHistoryRepository;

    private static final Set<ProviderCapability> CAPABILITIES = Set.of(
            ProviderCapability.SEARCH,
            ProviderCapability.OFFERS,
            ProviderCapability.PRICE
    );

    @Override
    public String getProviderName() {
        return "LOCAL";
    }

    @Override
    public String getDisplayName() {
        return "Local Store";
    }

    @Override
    public boolean isEnabled() {
        return true;
    }

    @Override
    public Set<ProviderCapability> getCapabilities() {
        return CAPABILITIES;
    }

    @Override
    public List<ProductOfferDto> searchProducts(ProductSearchRequest request) {
        String canonicalKey = (request.getItemName() != null ? request.getItemName().toLowerCase().trim() : "");
        if (canonicalKey.isBlank()) return Collections.emptyList();

        // Search user-reported price history for this product
        List<PriceHistory> history = priceHistoryRepository.findByProviderOrderByRecordedAtDesc("LOCAL");
        List<ProductOfferDto> results = new ArrayList<>();

        for (PriceHistory record : history) {
            if (record.getProviderProductId() != null && record.getProviderProductId().toLowerCase().contains(canonicalKey)) {
                results.add(ProductOfferDto.builder()
                        .provider("LOCAL")
                        .providerProductId(record.getProviderProductId())
                        .productName(request.getItemName())
                        .brand(request.getBrand() != null ? request.getBrand() : "Local")
                        .packageSize(request.getQuantity() != null ? request.getQuantity().toPlainString() : "1")
                        .unit(request.getUnit() != null ? request.getUnit() : "pcs")
                        .price(record.getPrice())
                        .deliveryCharge(BigDecimal.ZERO)
                        .effectivePrice(record.getEffectivePrice())
                        .currency("INR")
                        .availability("IN_STOCK")
                        .estimatedDelivery("Available locally")
                        .matchConfidence(0.95)
                        .matchType("EXACT")
                        .lastCheckedAt(record.getRecordedAt() != null ? record.getRecordedAt() : Instant.now())
                        .fromCache(false)
                        .build());
                break; // Most recent report
            }
        }

        return results;
    }

    @Override
    public Optional<ProductOfferDto> getProduct(String providerProductId) {
        return Optional.empty();
    }

    @Override
    public String buildAffiliateUrl(String providerProductId, String originalUrl) {
        return originalUrl;
    }
}
