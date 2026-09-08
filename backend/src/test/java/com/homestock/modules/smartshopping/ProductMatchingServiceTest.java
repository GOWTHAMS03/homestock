package com.homestock.modules.smartshopping;

import com.homestock.modules.smartshopping.dto.ProductOfferDto;
import com.homestock.modules.smartshopping.service.ProductMatchingService;
import com.homestock.modules.smartshopping.service.UnitNormalizationService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThat;

class ProductMatchingServiceTest {

    private ProductMatchingService matchingService;

    @BeforeEach
    void setUp() {
        UnitNormalizationService unitService = new UnitNormalizationService();
        matchingService = new ProductMatchingService(unitService);
        ReflectionTestUtils.setField(matchingService, "confidenceThreshold", 0.75);
    }

    @Test
    @DisplayName("Exact match for identical brand, product name, and package size")
    void exactMatch() {
        ProductOfferDto offer = ProductOfferDto.builder()
                .productName("Tata Salt Vacuum Evaporated Iodized Salt")
                .brand("Tata Salt")
                .packageSize("1")
                .unit("kg")
                .build();

        var result = matchingService.calculateMatch(
                "Tata Salt",
                "Tata",
                new BigDecimal("1"),
                "kg",
                "Groceries",
                offer
        );

        assertThat(result.matchType()).isIn("EXACT", "SIMILAR");
        assertThat(result.confidence()).isGreaterThanOrEqualTo(0.75);
    }

    @Test
    @DisplayName("Reject match when package sizes differ significantly (5 kg vs 1 kg)")
    void differentPackageSizeLowersConfidence() {
        ProductOfferDto offer = ProductOfferDto.builder()
                .productName("India Gate Basmati Rice 5kg")
                .brand("India Gate")
                .packageSize("5")
                .unit("kg")
                .build();

        var result = matchingService.calculateMatch(
                "India Gate Basmati Rice",
                "India Gate",
                new BigDecimal("1"),
                "kg",
                "Rice & Grains",
                offer
        );

        // Size score is penalized
        assertThat(result.confidence()).isLessThan(0.90);
    }

    @Test
    @DisplayName("Completely different product results in NO_MATCH")
    void differentProductNoMatch() {
        ProductOfferDto offer = ProductOfferDto.builder()
                .productName("Surf Excel Detergent Powder")
                .brand("Surf Excel")
                .packageSize("1")
                .unit("kg")
                .build();

        var result = matchingService.calculateMatch(
                "Amul Butter",
                "Amul",
                new BigDecimal("500"),
                "g",
                "Dairy",
                offer
        );

        assertThat(result.matchType()).isEqualTo("NO_MATCH");
        assertThat(result.confidence()).isLessThan(0.75);
    }

    @Test
    @DisplayName("Variant protection: Never match Basmati Rice with Brown Rice")
    void variantClashRice() {
        ProductOfferDto offer = ProductOfferDto.builder()
                .productName("India Gate Brown Rice")
                .brand("India Gate")
                .packageSize("1")
                .unit("kg")
                .build();

        var result = matchingService.calculateMatch(
                "Basmati Rice",
                "India Gate",
                new BigDecimal("1"),
                "kg",
                "Grains",
                offer
        );

        assertThat(result.matchType()).isEqualTo("NO_MATCH");
        assertThat(result.confidence()).isEqualTo(0.0);
        assertThat(result.isAcceptableMatch()).isFalse();
    }

    @Test
    @DisplayName("Variant protection: Never match Sunflower Oil with Mustard Oil")
    void variantClashOil() {
        ProductOfferDto offer = ProductOfferDto.builder()
                .productName("Fortune Mustard Oil 1L Pouch")
                .brand("Fortune")
                .packageSize("1")
                .unit("L")
                .build();

        var result = matchingService.calculateMatch(
                "Fortune Sunflower Oil",
                "Fortune",
                new BigDecimal("1"),
                "L",
                "Oils",
                offer
        );

        assertThat(result.matchType()).isEqualTo("NO_MATCH");
        assertThat(result.confidence()).isEqualTo(0.0);
        assertThat(result.isAcceptableMatch()).isFalse();
    }

    @Test
    @DisplayName("Exact barcode match produces 1.0 confidence regardless of name difference")
    void barcodeExactMatch() {
        ProductOfferDto offer = ProductOfferDto.builder()
                .productName("Aashirvaad Shudh Chakki Atta")
                .brand("Aashirvaad")
                .barcode("8901030383792")
                .packageSize("5")
                .unit("kg")
                .build();

        var result = matchingService.calculateMatch(
                "Wheat Flour",
                "ITC",
                new BigDecimal("5"),
                "kg",
                "Groceries",
                "8901030383792",
                offer
        );

        assertThat(result.matchType()).isEqualTo("EXACT");
        assertThat(result.confidence()).isEqualTo(1.0);
        assertThat(result.isAcceptableMatch()).isTrue();
    }
}
