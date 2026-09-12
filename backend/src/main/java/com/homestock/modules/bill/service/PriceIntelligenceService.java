package com.homestock.modules.bill.service;

import com.homestock.core.exception.ResourceNotFoundException;
import com.homestock.modules.bill.dto.ProductPriceHistoryDto;
import com.homestock.modules.bill.dto.ProductPriceIntelligenceDto;
import com.homestock.modules.bill.dto.StorePriceComparisonDto;
import com.homestock.modules.bill.entity.ProductPriceHistory;
import com.homestock.modules.bill.repository.ProductPriceHistoryRepository;
import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.inventory.repository.InventoryItemRepository;
import com.homestock.modules.product.entity.Product;
import com.homestock.modules.product.repository.ProductRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Service
public class PriceIntelligenceService {

    private final ProductPriceHistoryRepository priceHistoryRepository;
    private final ProductRepository productRepository;
    private final InventoryItemRepository inventoryItemRepository;

    public PriceIntelligenceService(
            ProductPriceHistoryRepository priceHistoryRepository,
            ProductRepository productRepository,
            InventoryItemRepository inventoryItemRepository
    ) {
        this.priceHistoryRepository = priceHistoryRepository;
        this.productRepository = productRepository;
        this.inventoryItemRepository = inventoryItemRepository;
    }

    @Transactional(readOnly = true)
    public ProductPriceIntelligenceDto getProductPriceIntelligence(UUID homeId, UUID productId) {
        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new ResourceNotFoundException("Product not found"));

        List<ProductPriceHistory> historyList = priceHistoryRepository
                .findByHomeIdAndProductIdOrderByPurchaseDateDesc(homeId, productId, PageRequest.of(0, 50));

        List<Object[]> statsList = priceHistoryRepository.getPriceStatsByProduct(homeId, productId);
        List<Object[]> storeStatsList = priceHistoryRepository.getStorePriceComparison(homeId, productId);

        return buildIntelligenceDto(product.getName(), product.getUnit(), productId, null, historyList, statsList, storeStatsList);
    }

    @Transactional(readOnly = true)
    public ProductPriceIntelligenceDto getInventoryItemPriceIntelligence(UUID homeId, UUID itemId) {
        InventoryItem item = inventoryItemRepository.findById(itemId)
                .orElseThrow(() -> new ResourceNotFoundException("Inventory item not found"));

        if (!item.getHome().getId().equals(homeId)) {
            throw new org.springframework.security.access.AccessDeniedException("Item does not belong to household");
        }

        List<ProductPriceHistory> historyList = priceHistoryRepository
                .findByHomeIdAndInventoryItemIdOrderByPurchaseDateDesc(homeId, itemId, PageRequest.of(0, 50));

        List<Object[]> statsList = priceHistoryRepository.getPriceStatsByInventoryItem(homeId, itemId);
        List<Object[]> storeStatsList = priceHistoryRepository.getStorePriceComparisonByItem(homeId, itemId);

        return buildIntelligenceDto(item.getName(), item.getUnit(), item.getProduct() != null ? item.getProduct().getId() : null, item.getId(), historyList, statsList, storeStatsList);
    }

    private ProductPriceIntelligenceDto buildIntelligenceDto(
            String name,
            String unit,
            UUID productId,
            UUID itemId,
            List<ProductPriceHistory> historyList,
            List<Object[]> statsList,
            List<Object[]> storeStatsList
    ) {
        BigDecimal avgPrice = BigDecimal.ZERO;
        BigDecimal minPrice = BigDecimal.ZERO;
        BigDecimal maxPrice = BigDecimal.ZERO;

        if (statsList != null && !statsList.isEmpty() && statsList.get(0) != null) {
            Object[] row = statsList.get(0);
            if (row[0] != null) avgPrice = BigDecimal.valueOf(((Number) row[0]).doubleValue()).setScale(2, RoundingMode.HALF_UP);
            if (row[1] != null) minPrice = BigDecimal.valueOf(((Number) row[1]).doubleValue()).setScale(2, RoundingMode.HALF_UP);
            if (row[2] != null) maxPrice = BigDecimal.valueOf(((Number) row[2]).doubleValue()).setScale(2, RoundingMode.HALF_UP);
        }

        BigDecimal currentPrice = BigDecimal.ZERO;
        BigDecimal prevPrice = BigDecimal.ZERO;
        BigDecimal priceChangePercent = BigDecimal.ZERO;
        boolean isHigherThanUsual = false;

        List<ProductPriceHistoryDto> dtoList = new ArrayList<>();

        if (!historyList.isEmpty()) {
            ProductPriceHistory latest = historyList.get(0);
            currentPrice = latest.getStandardUnitPrice();

            if (historyList.size() > 1) {
                ProductPriceHistory prev = historyList.get(1);
                prevPrice = prev.getStandardUnitPrice();
                if (prevPrice.compareTo(BigDecimal.ZERO) > 0) {
                    priceChangePercent = currentPrice.subtract(prevPrice)
                            .divide(prevPrice, 4, RoundingMode.HALF_UP)
                            .multiply(BigDecimal.valueOf(100))
                            .setScale(2, RoundingMode.HALF_UP);
                }
            }

            // Anomaly check: if current purchase is >10% above average historical price
            if (avgPrice.compareTo(BigDecimal.ZERO) > 0) {
                BigDecimal threshold = avgPrice.multiply(BigDecimal.valueOf(1.10));
                isHigherThanUsual = currentPrice.compareTo(threshold) > 0;
            }

            for (ProductPriceHistory h : historyList) {
                boolean higher = avgPrice.compareTo(BigDecimal.ZERO) > 0 &&
                        h.getStandardUnitPrice().compareTo(avgPrice.multiply(BigDecimal.valueOf(1.10))) > 0;

                dtoList.add(ProductPriceHistoryDto.builder()
                        .id(h.getId())
                        .purchaseDate(h.getPurchaseDate())
                        .storeName(h.getStoreName() != null ? h.getStoreName() : "Local Store")
                        .quantity(h.getQuantity())
                        .unit(h.getUnit())
                        .unitPrice(h.getUnitPrice())
                        .standardUnitPrice(h.getStandardUnitPrice())
                        .totalPrice(h.getTotalPrice())
                        .isHigherThanUsual(higher)
                        .build());
            }
        }

        // Store price comparison
        List<StorePriceComparisonDto> storeComparisons = new ArrayList<>();
        String recommendedStore = null;
        BigDecimal lowestStorePrice = null;

        if (storeStatsList != null) {
            for (Object[] row : storeStatsList) {
                if (row[0] != null && row[1] != null) {
                    String sName = (String) row[0];
                    BigDecimal sAvg = BigDecimal.valueOf(((Number) row[1]).doubleValue()).setScale(2, RoundingMode.HALF_UP);
                    BigDecimal sMin = row[2] != null ? BigDecimal.valueOf(((Number) row[2]).doubleValue()).setScale(2, RoundingMode.HALF_UP) : sAvg;
                    BigDecimal sMax = row[3] != null ? BigDecimal.valueOf(((Number) row[3]).doubleValue()).setScale(2, RoundingMode.HALF_UP) : sAvg;
                    long count = row[4] != null ? ((Number) row[4]).longValue() : 1L;

                    storeComparisons.add(StorePriceComparisonDto.builder()
                            .storeName(sName)
                            .averagePrice(sAvg)
                            .minPrice(sMin)
                            .maxPrice(sMax)
                            .purchaseCount(count)
                            .build());

                    if (lowestStorePrice == null || sAvg.compareTo(lowestStorePrice) < 0) {
                        lowestStorePrice = sAvg;
                        recommendedStore = sName;
                    }
                }
            }
        }

        return ProductPriceIntelligenceDto.builder()
                .productId(productId)
                .inventoryItemId(itemId)
                .productName(name)
                .unit(unit)
                .currentPrice(currentPrice)
                .previousPrice(prevPrice)
                .priceChangePercent(priceChangePercent)
                .averagePrice(avgPrice)
                .minPrice(minPrice)
                .maxPrice(maxPrice)
                .isHigherThanUsual(isHigherThanUsual)
                .recommendedStore(recommendedStore)
                .recentPurchases(dtoList)
                .storeComparisons(storeComparisons)
                .build();
    }
}
