package com.homestock.modules.analytics.service;

import com.homestock.core.exception.ResourceNotFoundException;
import com.homestock.modules.analytics.dto.AnalyticsOverviewDto;
import com.homestock.modules.home.repository.HomeRepository;
import com.homestock.modules.purchase.repository.PurchaseItemRepository;
import com.homestock.modules.purchase.repository.PurchaseRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AnalyticsService {

    private final HomeRepository homeRepository;
    private final PurchaseRepository purchaseRepository;
    private final PurchaseItemRepository purchaseItemRepository;

    @Transactional(readOnly = true)
    public AnalyticsOverviewDto getOverview(UUID homeId) {
        homeRepository.findById(homeId)
                .orElseThrow(() -> new ResourceNotFoundException("Home not found"));

        LocalDate startOfMonth = LocalDate.now().withDayOfMonth(1);
        BigDecimal monthlySpend = purchaseRepository.calculateTotalSpendingSince(homeId, startOfMonth);
        if (monthlySpend == null) {
            monthlySpend = BigDecimal.ZERO;
        }

        // Category spending
        List<Object[]> categoryData = purchaseItemRepository.getSpendingByCategory(homeId);
        List<AnalyticsOverviewDto.CategorySpendingDto> categoryList = new ArrayList<>();
        for (Object[] row : categoryData) {
            if (row[0] != null && row[1] != null) {
                categoryList.add(new AnalyticsOverviewDto.CategorySpendingDto(
                        (String) row[0],
                        (BigDecimal) row[1]
                ));
            }
        }

        // Store spending
        List<Object[]> storeData = purchaseRepository.getSpendingByStore(homeId);
        List<AnalyticsOverviewDto.StoreSpendingDto> storeList = new ArrayList<>();
        for (Object[] row : storeData) {
            if (row[0] != null && row[1] != null) {
                storeList.add(new AnalyticsOverviewDto.StoreSpendingDto(
                        (String) row[0],
                        (BigDecimal) row[1]
                ));
            }
        }

        // Most purchased items
        List<Object[]> purchasedData = purchaseItemRepository.getMostPurchasedItems(homeId);
        List<AnalyticsOverviewDto.TopItemDto> mostPurchased = new ArrayList<>();
        for (Object[] row : purchasedData) {
            if (row[0] != null) {
                mostPurchased.add(new AnalyticsOverviewDto.TopItemDto(
                        (String) row[0],
                        row[2] != null ? (BigDecimal) row[2] : BigDecimal.ZERO,
                        row[1] != null ? ((Number) row[1]).longValue() : 0L
                ));
            }
        }

        return AnalyticsOverviewDto.builder()
                .monthlySpending(monthlySpend)
                .currency("INR")
                .categorySpending(categoryList)
                .storeSpending(storeList)
                .mostPurchasedItems(mostPurchased)
                .mostConsumedItems(mostPurchased) // linked to purchased/consumed items
                .build();
    }
}
