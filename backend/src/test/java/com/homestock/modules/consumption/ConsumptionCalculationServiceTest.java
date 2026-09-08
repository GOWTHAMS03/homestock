package com.homestock.modules.consumption;

import com.homestock.modules.consumption.entity.ConfidenceLevel;
import com.homestock.modules.consumption.entity.ConsumptionCycle;
import com.homestock.modules.consumption.entity.ConsumptionProfile;
import com.homestock.modules.consumption.service.ConsumptionCalculationService;
import com.homestock.modules.home.entity.Home;
import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.purchase.entity.Purchase;
import com.homestock.modules.purchase.entity.PurchaseItem;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class ConsumptionCalculationServiceTest {

    private ConsumptionCalculationService calculationService;
    private Home testHome;
    private InventoryItem riceItem;

    @BeforeEach
    void setUp() {
        calculationService = new ConsumptionCalculationService();
        testHome = Home.builder().name("Test Home").build();
        testHome.setId(UUID.randomUUID());

        riceItem = InventoryItem.builder()
                .home(testHome)
                .name("Ponni Rice")
                .unit("kg")
                .minimumQuantity(new BigDecimal("2.0"))
                .quantity(new BigDecimal("5.0"))
                .build();
        riceItem.setId(UUID.randomUUID());
    }

    private PurchaseItem createPurchaseItem(LocalDate date, BigDecimal quantity) {
        Purchase purchase = Purchase.builder()
                .home(testHome)
                .purchaseDate(date)
                .totalAmount(new BigDecimal("250.00"))
                .build();
        purchase.setId(UUID.randomUUID());

        PurchaseItem item = PurchaseItem.builder()
                .purchase(purchase)
                .inventoryItem(riceItem)
                .itemName(riceItem.getName())
                .quantity(quantity)
                .unit("kg")
                .unitPrice(new BigDecimal("50.00"))
                .totalPrice(quantity.multiply(new BigDecimal("50.00")))
                .build();
        item.setId(UUID.randomUUID());
        return item;
    }

    @Test
    @DisplayName("Scenario 1: 5kg Rice every 7 days -> ~714g/day daily consumption with HIGH confidence")
    void testConsistentPurchaseCycle() {
        List<PurchaseItem> purchases = List.of(
                createPurchaseItem(LocalDate.of(2026, 9, 1), new BigDecimal("5.0")),
                createPurchaseItem(LocalDate.of(2026, 9, 8), new BigDecimal("5.0")),
                createPurchaseItem(LocalDate.of(2026, 9, 15), new BigDecimal("5.0")),
                createPurchaseItem(LocalDate.of(2026, 9, 22), new BigDecimal("5.0")),
                createPurchaseItem(LocalDate.of(2026, 9, 29), new BigDecimal("5.0"))
        );

        List<ConsumptionCycle> cycles = calculationService.buildCyclesFromPurchases(testHome, riceItem, purchases);
        assertThat(cycles).hasSize(4);

        for (ConsumptionCycle c : cycles) {
            assertThat(c.getIntervalDays()).isEqualTo(7);
            assertThat(c.getEstimatedDailyConsumption()).isEqualByComparingTo(new BigDecimal("0.7143"));
            assertThat(c.getIsAnomaly()).isFalse();
        }

        ConsumptionProfile profile = calculationService.calculateProfile(testHome, riceItem, cycles, null);
        assertThat(profile.getSampleCount()).isEqualTo(4);
        assertThat(profile.getAveragePurchaseInterval()).isEqualByComparingTo(new BigDecimal("7.00"));
        assertThat(profile.getAverageDailyConsumption()).isBetween(new BigDecimal("0.7100"), new BigDecimal("0.7200"));
        assertThat(profile.getConfidence()).isEqualTo(ConfidenceLevel.HIGH);
    }

    @Test
    @DisplayName("Scenario 2: Variable purchase cycles (6-8 days) -> Produces typical interval range")
    void testVariablePurchaseCycle() {
        List<PurchaseItem> purchases = List.of(
                createPurchaseItem(LocalDate.of(2026, 9, 1), new BigDecimal("5.0")),
                createPurchaseItem(LocalDate.of(2026, 9, 8), new BigDecimal("5.0")),  // 7 days
                createPurchaseItem(LocalDate.of(2026, 9, 16), new BigDecimal("5.0")), // 8 days
                createPurchaseItem(LocalDate.of(2026, 9, 22), new BigDecimal("5.0"))  // 6 days
        );

        List<ConsumptionCycle> cycles = calculationService.buildCyclesFromPurchases(testHome, riceItem, purchases);
        assertThat(cycles).hasSize(3);

        ConsumptionProfile profile = calculationService.calculateProfile(testHome, riceItem, cycles, null);
        assertThat(profile.getSampleCount()).isEqualTo(3);
        assertThat(profile.getWeightedDailyConsumption()).isBetween(new BigDecimal("0.6000"), new BigDecimal("0.8500"));

        String rangeText = calculationService.formatTypicalRangeText(
                profile.getMinDailyConsumption(),
                profile.getMaxDailyConsumption(),
                profile.getAveragePurchaseInterval(),
                riceItem.getUnit(),
                new BigDecimal("5.0")
        );
        assertThat(rangeText).contains("every 6–9 days");
    }

    @Test
    @DisplayName("Scenario 8: Vacation creates an abnormal 20-day interval -> flagged as anomaly and down-weighted")
    void testAnomalyDetection() {
        List<PurchaseItem> purchases = List.of(
                createPurchaseItem(LocalDate.of(2026, 7, 1), new BigDecimal("5.0")),
                createPurchaseItem(LocalDate.of(2026, 7, 8), new BigDecimal("5.0")),  // 7 days
                createPurchaseItem(LocalDate.of(2026, 7, 15), new BigDecimal("5.0")), // 7 days
                createPurchaseItem(LocalDate.of(2026, 7, 22), new BigDecimal("5.0")), // 7 days
                createPurchaseItem(LocalDate.of(2026, 8, 11), new BigDecimal("5.0")), // 20 days (vacation gap!)
                createPurchaseItem(LocalDate.of(2026, 8, 18), new BigDecimal("5.0"))  // 7 days
        );

        List<ConsumptionCycle> cycles = calculationService.buildCyclesFromPurchases(testHome, riceItem, purchases);
        assertThat(cycles).hasSize(5);

        ConsumptionCycle anomalyCycle = cycles.stream()
                .filter(c -> c.getIntervalDays() == 20)
                .findFirst()
                .orElseThrow();

        assertThat(anomalyCycle.getIsAnomaly()).isTrue();
        assertThat(anomalyCycle.getAnomalyReason()).contains("Unusual long gap");

        ConsumptionProfile profile = calculationService.calculateProfile(testHome, riceItem, cycles, null);
        // Ensure weightedDaily is closer to 7-day usage (~0.71) than the skewed 20-day usage (0.25)
        assertThat(profile.getWeightedDailyConsumption()).isGreaterThan(new BigDecimal("0.6000"));
    }
}
