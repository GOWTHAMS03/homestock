package com.homestock.modules.voice.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class UnitNormalizationServiceTest {

    private UnitNormalizationService unitNormalizer;

    @BeforeEach
    void setUp() {
        unitNormalizer = new UnitNormalizationService();
    }

    @Test
    void testNormalizeEnglishUnits() {
        assertEquals("KG", unitNormalizer.normalize("kilogram"));
        assertEquals("KG", unitNormalizer.normalize("kilograms"));
        assertEquals("KG", unitNormalizer.normalize("kilo"));
        assertEquals("L", unitNormalizer.normalize("litre"));
        assertEquals("L", unitNormalizer.normalize("litres"));
        assertEquals("ML", unitNormalizer.normalize("millilitre"));
        assertEquals("G", unitNormalizer.normalize("grams"));
        assertEquals("PACK", unitNormalizer.normalize("packets"));
        assertEquals("BOTTLE", unitNormalizer.normalize("bottles"));
    }

    @Test
    void testNormalizeTanglishAndTamilUnits() {
        assertEquals("KG", unitNormalizer.normalize("kilo"));
        assertEquals("KG", unitNormalizer.normalize("கிலோ"));
        assertEquals("L", unitNormalizer.normalize("லிட்டர்"));
        assertEquals("G", unitNormalizer.normalize("கிராம்"));
    }

    @Test
    void testNullOrUnknownDefaults() {
        assertEquals("PCS", unitNormalizer.normalize(null));
        assertEquals("PCS", unitNormalizer.normalize(""));
        assertEquals("BOX", unitNormalizer.normalize("box"));
    }
}
