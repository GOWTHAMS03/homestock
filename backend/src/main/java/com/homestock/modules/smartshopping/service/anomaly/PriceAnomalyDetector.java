package com.homestock.modules.smartshopping.service.anomaly;

import com.homestock.modules.smartshopping.dto.PriceStatus;
import com.homestock.modules.smartshopping.dto.ProductCandidate;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Price Anomaly Detector:
 * Flags suspicious prices (e.g. ₹29 for 1L oil normally ₹140-₹180)
 * as PRICE_ANOMALY to prevent misleading deals from appearing as best offers.
 */
@Service
public class PriceAnomalyDetector {

    private static final Logger log = LoggerFactory.getLogger(PriceAnomalyDetector.class);

    // Baseline minimum realistic market price bounds per unit/category in INR
    private static final Map<String, PriceRange> CATEGORY_PRICE_BENCHMARKS = new LinkedHashMap<>();

    static {
        // Minimum realistic price for 1L / 1kg of category
        CATEGORY_PRICE_BENCHMARKS.put("Cooking Oil", new PriceRange(new BigDecimal("90"), new BigDecimal("350")));
        CATEGORY_PRICE_BENCHMARKS.put("Rice & Grains", new PriceRange(new BigDecimal("40"), new BigDecimal("250")));
        CATEGORY_PRICE_BENCHMARKS.put("Dairy & Milk", new PriceRange(new BigDecimal("50"), new BigDecimal("120")));
        CATEGORY_PRICE_BENCHMARKS.put("Atta & Flours", new PriceRange(new BigDecimal("35"), new BigDecimal("100")));
        CATEGORY_PRICE_BENCHMARKS.put("Dals & Pulses", new PriceRange(new BigDecimal("90"), new BigDecimal("250")));
        CATEGORY_PRICE_BENCHMARKS.put("Sugar & Sweeteners", new PriceRange(new BigDecimal("35"), new BigDecimal("150")));
        CATEGORY_PRICE_BENCHMARKS.put("Cleaning & Detergents", new PriceRange(new BigDecimal("60"), new BigDecimal("500")));
    }

    /**
     * Inspect candidate price for potential anomaly.
     */
    public ProductCandidate inspect(ProductCandidate candidate) {
        if (candidate.getPrice() == null) return candidate;

        BigDecimal price = candidate.getPrice();

        // 1. Extreme absolute minimum threshold (e.g. < ₹10 for standard retail grocery pack)
        if (price.compareTo(new BigDecimal("10")) < 0) {
            log.warn("[PriceAnomalyDetector] Anomaly detected (< ₹10): '{}' price = ₹{}",
                    candidate.getProductName(), price);
            candidate.setPriceStatus(PriceStatus.PRICE_ANOMALY);
            return candidate;
        }

        // 2. Category Benchmark check for 1L / 1kg packs
        String cat = candidate.getCategory();
        String pack = candidate.getPackageSize();
        if (cat != null && pack != null) {
            String normPack = pack.replaceAll("\\s+", "").toLowerCase();
            if (normPack.equals("1l") || normPack.equals("1kg")) {
                PriceRange range = CATEGORY_PRICE_BENCHMARKS.get(cat);
                if (range != null) {
                    if (price.compareTo(range.minPrice.multiply(new BigDecimal("0.50"))) < 0) {
                        // More than 50% below min benchmark (e.g. ₹29 vs min ₹90)
                        log.warn("[PriceAnomalyDetector] Anomaly detected: '{}' in '{}' priced at ₹{} (Expected min ₹{})",
                                candidate.getProductName(), cat, price, range.minPrice);
                        candidate.setPriceStatus(PriceStatus.PRICE_ANOMALY);
                    }
                }
            }
        }

        return candidate;
    }

    private record PriceRange(BigDecimal minPrice, BigDecimal maxPrice) {}
}
