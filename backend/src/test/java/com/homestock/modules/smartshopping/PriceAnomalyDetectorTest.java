package com.homestock.modules.smartshopping;

import com.homestock.modules.smartshopping.dto.PriceStatus;
import com.homestock.modules.smartshopping.dto.ProductCandidate;
import com.homestock.modules.smartshopping.service.anomaly.PriceAnomalyDetector;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.*;

class PriceAnomalyDetectorTest {

    private PriceAnomalyDetector anomalyDetector;

    @BeforeEach
    void setUp() {
        anomalyDetector = new PriceAnomalyDetector();
    }

    @Test
    @DisplayName("Requirement 18: Normal market price ₹140-₹180 vs search result ₹29 -> flagged as PRICE_ANOMALY")
    void testSuspiciousLowPriceFlagged() {
        ProductCandidate candidate = ProductCandidate.builder()
                .productName("Fortune Sunflower Oil 1L")
                .category("Cooking Oil")
                .packageSize("1 L")
                .price(new BigDecimal("29")) // Suspiciously low for 1L oil
                .build();

        anomalyDetector.inspect(candidate);

        assertEquals(PriceStatus.PRICE_ANOMALY, candidate.getPriceStatus(),
                "₹29 for 1L Cooking Oil must be flagged as PRICE_ANOMALY");
    }

    @Test
    @DisplayName("Requirement 18: Realistic market price ₹145 for 1L oil is not flagged as anomaly")
    void testRealisticPriceNotFlagged() {
        ProductCandidate candidate = ProductCandidate.builder()
                .productName("Fortune Sunflower Oil 1L")
                .category("Cooking Oil")
                .packageSize("1 L")
                .price(new BigDecimal("145"))
                .build();

        anomalyDetector.inspect(candidate);

        assertNotEquals(PriceStatus.PRICE_ANOMALY, candidate.getPriceStatus());
    }

    @Test
    @DisplayName("Requirement 18: Price below ₹10 threshold flagged as PRICE_ANOMALY")
    void testExtremeLowPriceFlagged() {
        ProductCandidate candidate = ProductCandidate.builder()
                .productName("India Gate Basmati Rice 5kg")
                .category("Rice & Grains")
                .packageSize("5 kg")
                .price(new BigDecimal("5"))
                .build();

        anomalyDetector.inspect(candidate);

        assertEquals(PriceStatus.PRICE_ANOMALY, candidate.getPriceStatus());
    }
}
