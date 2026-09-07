package com.homestock.modules.smartshopping;

import com.homestock.modules.smartshopping.service.UnitNormalizationService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThat;

class UnitNormalizationServiceTest {

    private UnitNormalizationService unitService;

    @BeforeEach
    void setUp() {
        unitService = new UnitNormalizationService();
    }

    @Test
    @DisplayName("Should normalize 1 kg to 1000 g")
    void normalizeKgToGrams() {
        var result = unitService.normalize(new BigDecimal("1"), "kg");
        assertThat(result.baseUnit()).isEqualTo("g");
        assertThat(result.quantity()).isEqualByComparingTo(new BigDecimal("1000"));
    }

    @Test
    @DisplayName("Should normalize 2 L to 2000 ml")
    void normalizeLitreToMl() {
        var result = unitService.normalize(new BigDecimal("2"), "L");
        assertThat(result.baseUnit()).isEqualTo("ml");
        assertThat(result.quantity()).isEqualByComparingTo(new BigDecimal("2000"));
    }

    @Test
    @DisplayName("Should normalize dozen to 12 pcs")
    void normalizeDozenToPcs() {
        var result = unitService.normalize(new BigDecimal("2"), "dozen");
        assertThat(result.baseUnit()).isEqualTo("pcs");
        assertThat(result.quantity()).isEqualByComparingTo(new BigDecimal("24"));
    }

    @Test
    @DisplayName("Should recognize comparable units (kg and g)")
    void comparableUnits() {
        assertThat(unitService.areUnitsComparable("kg", "g")).isTrue();
        assertThat(unitService.areUnitsComparable("L", "ml")).isTrue();
        assertThat(unitService.areUnitsComparable("kg", "L")).isFalse();
        assertThat(unitService.areUnitsComparable("pcs", "kg")).isFalse();
    }

    @Test
    @DisplayName("Should calculate correct price per standard unit (₹150 for 500g = ₹300/kg)")
    void calculatePricePerUnit() {
        var ppu = unitService.calculatePricePerUnit(
                new BigDecimal("150"),
                new BigDecimal("500"),
                "g"
        );
        assertThat(ppu).isNotNull();
        assertThat(ppu.unit()).isEqualTo("kg");
        assertThat(ppu.price()).isEqualByComparingTo(new BigDecimal("300.00"));
        assertThat(ppu.label()).isEqualTo("₹300.00/kg");
    }

    @Test
    @DisplayName("Should parse package size string correctly")
    void parsePackageSize() {
        var p1 = unitService.parsePackageSize("5 kg");
        assertThat(p1).isNotNull();
        assertThat(p1.quantity()).isEqualByComparingTo(new BigDecimal("5"));
        assertThat(p1.unit()).isEqualTo("kg");

        var p2 = unitService.parsePackageSize("500ml");
        assertThat(p2).isNotNull();
        assertThat(p2.quantity()).isEqualByComparingTo(new BigDecimal("500"));
        assertThat(p2.unit()).isEqualTo("ml");
    }
}
