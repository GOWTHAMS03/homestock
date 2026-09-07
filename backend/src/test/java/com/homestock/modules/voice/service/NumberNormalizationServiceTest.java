package com.homestock.modules.voice.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.*;

class NumberNormalizationServiceTest {

    private NumberNormalizationService numberNormalizer;

    @BeforeEach
    void setUp() {
        numberNormalizer = new NumberNormalizationService();
    }

    @Test
    void testStandardDigits() {
        assertEquals(0, new BigDecimal("2").compareTo(numberNormalizer.parseToken("2")));
        assertEquals(0, new BigDecimal("500").compareTo(numberNormalizer.parseToken("500")));
        assertEquals(0, new BigDecimal("1.5").compareTo(numberNormalizer.parseToken("1.5")));
    }

    @Test
    void testEnglishWords() {
        assertEquals(0, new BigDecimal("1").compareTo(numberNormalizer.parseToken("one")));
        assertEquals(0, new BigDecimal("2").compareTo(numberNormalizer.parseToken("two")));
        assertEquals(0, new BigDecimal("5").compareTo(numberNormalizer.parseToken("five")));
        assertEquals(0, new BigDecimal("10").compareTo(numberNormalizer.parseToken("ten")));
    }

    @Test
    void testTanglishSpokenNumerals() {
        assertEquals(0, new BigDecimal("1").compareTo(numberNormalizer.parseToken("onnu")));
        assertEquals(0, new BigDecimal("2").compareTo(numberNormalizer.parseToken("rendu")));
        assertEquals(0, new BigDecimal("3").compareTo(numberNormalizer.parseToken("moonu")));
        assertEquals(0, new BigDecimal("4").compareTo(numberNormalizer.parseToken("naalu")));
        assertEquals(0, new BigDecimal("5").compareTo(numberNormalizer.parseToken("anju")));
        assertEquals(0, new BigDecimal("10").compareTo(numberNormalizer.parseToken("pathu")));
    }

    @Test
    void testTanglishFractions() {
        assertEquals(0, new BigDecimal("0.5").compareTo(numberNormalizer.parseToken("arai")));
        assertEquals(0, new BigDecimal("0.25").compareTo(numberNormalizer.parseToken("kaal")));
        assertEquals(0, new BigDecimal("1.5").compareTo(numberNormalizer.parseToken("onnara")));
        assertEquals(0, new BigDecimal("2.5").compareTo(numberNormalizer.parseToken("rendara")));
    }

    @Test
    void testTamilScriptNumerals() {
        assertEquals(0, new BigDecimal("1").compareTo(numberNormalizer.parseToken("ஒன்று")));
        assertEquals(0, new BigDecimal("2").compareTo(numberNormalizer.parseToken("இரண்டு")));
        assertEquals(0, new BigDecimal("0.5").compareTo(numberNormalizer.parseToken("அரை")));
    }

    @Test
    void testExtractFirstNumber() {
        assertEquals(0, new BigDecimal("2").compareTo(numberNormalizer.extractFirstNumber("Add 2 litre oil")));
        assertEquals(0, new BigDecimal("2").compareTo(numberNormalizer.extractFirstNumber("rendu illai moonu")));
    }
}
