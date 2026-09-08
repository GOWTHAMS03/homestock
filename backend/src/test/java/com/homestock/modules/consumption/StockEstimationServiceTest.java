package com.homestock.modules.consumption;

import com.homestock.modules.consumption.entity.ConsumptionProfile;
import com.homestock.modules.consumption.entity.QuantitySource;
import com.homestock.modules.consumption.entity.QuantityStatus;
import com.homestock.modules.consumption.service.StockEstimationService;
import com.homestock.modules.inventory.entity.InventoryItem;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.ZoneId;

import static org.assertj.core.api.Assertions.assertThat;

class StockEstimationServiceTest {

    private StockEstimationService estimationService;

    @BeforeEach
    void setUp() {
        estimationService = new StockEstimationService();
    }

    @Test
    @DisplayName("Estimates remaining stock passively after 4 days of ~0.7 kg/day usage without manual entry")
    void testPassiveStockEstimation() {
        LocalDate fourDaysAgo = LocalDate.now().minusDays(4);

        InventoryItem item = InventoryItem.builder()
                .name("Rice")
                .unit("kg")
                .quantity(new BigDecimal("5.0"))
                .minimumQuantity(new BigDecimal("1.0"))
                .purchaseDate(fourDaysAgo)
                .lastVerifiedAt(fourDaysAgo.atStartOfDay(ZoneId.systemDefault()).toInstant())
                .quantitySource(QuantitySource.ESTIMATED)
                .build();

        ConsumptionProfile profile = ConsumptionProfile.builder()
                .weightedDailyConsumption(new BigDecimal("0.7000"))
                .build();

        BigDecimal estimatedQty = estimationService.estimateCurrentQuantity(item, profile);
        // 5.0 - (4 * 0.70) = 2.2 kg
        assertThat(estimatedQty).isEqualByComparingTo(new BigDecimal("2.2000"));

        Integer daysRemaining = estimationService.calculateDaysRemaining(estimatedQty, profile);
        assertThat(daysRemaining).isEqualTo(3);

        String display = estimationService.formatStockDisplay(item, estimatedQty, daysRemaining);
        // Should avoid decimal spam, showing range or rounded string
        assertThat(display).contains("2–4 days");
    }

    @Test
    @DisplayName("Displays fast qualitative level when verified by user")
    void testQualitativeLevelDisplay() {
        InventoryItem item = InventoryItem.builder()
                .name("Sunflower Oil")
                .unit("L")
                .quantity(new BigDecimal("0.5"))
                .quantityStatus(QuantityStatus.ABOUT_HALF)
                .quantitySource(QuantitySource.VERIFIED)
                .build();

        String display = estimationService.formatStockDisplay(item, new BigDecimal("0.5"), 10);
        assertThat(display).isEqualTo("About half");
    }
}
