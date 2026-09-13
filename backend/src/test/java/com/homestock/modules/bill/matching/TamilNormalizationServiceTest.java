package com.homestock.modules.bill.matching;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class TamilNormalizationServiceTest {

    private TamilNormalizationService service;

    @BeforeEach
    void setUp() {
        service = new TamilNormalizationService();
    }

    @Test
    void testTamilScriptDetection() {
        assertTrue(service.containsTamilScript("அரிசி 1kg"));
        assertTrue(service.containsTamilScript("பால்"));
        assertFalse(service.containsTamilScript("Rice 1kg"));
        assertFalse(service.containsTamilScript("Arisi 1kg"));
        assertFalse(service.containsTamilScript(""));
        assertFalse(service.containsTamilScript(null));
    }

    @Test
    void testTamilScriptNormalization() {
        var riceResult = service.normalizeTamilOrTanglish("அரிசி");
        assertTrue(riceResult.isTamilOrTanglish());
        assertEquals("RICE", riceResult.englishEquivalent());

        var toorDalResult = service.normalizeTamilOrTanglish("துவரம்பருப்பு");
        assertTrue(toorDalResult.isTamilOrTanglish());
        assertEquals("TOOR DAL", toorDalResult.englishEquivalent());

        var sugarResult = service.normalizeTamilOrTanglish("சர்க்கரை");
        assertTrue(sugarResult.isTamilOrTanglish());
        assertEquals("SUGAR", sugarResult.englishEquivalent());

        var oilResult = service.normalizeTamilOrTanglish("எண்ணெய்");
        assertTrue(oilResult.isTamilOrTanglish());
        assertEquals("OIL", oilResult.englishEquivalent());

        var onionResult = service.normalizeTamilOrTanglish("வெங்காயம்");
        assertTrue(onionResult.isTamilOrTanglish());
        assertEquals("ONION", onionResult.englishEquivalent());
    }

    @Test
    void testTamilScriptWithUnits() {
        var result = service.normalizeTamilOrTanglish("அரிசி 1 கிலோ");
        assertTrue(result.isTamilOrTanglish());
        assertEquals("RICE", result.englishEquivalent());
        assertEquals("kg", result.detectedUnit());
    }

    @Test
    void testTanglishNormalization() {
        var arisi = service.normalizeTamilOrTanglish("arisi 5kg");
        assertTrue(arisi.isTamilOrTanglish());
        assertEquals("RICE", arisi.englishEquivalent());

        var thuvaram = service.normalizeTamilOrTanglish("thuvaram paruppu");
        assertTrue(thuvaram.isTamilOrTanglish());
        assertEquals("TOOR DAL", thuvaram.englishEquivalent());

        var vengayam = service.normalizeTamilOrTanglish("periya vengayam");
        assertTrue(vengayam.isTamilOrTanglish());
        assertEquals("ONION", vengayam.englishEquivalent());

        var thakkali = service.normalizeTamilOrTanglish("thakkali 1kg");
        assertTrue(thakkali.isTamilOrTanglish());
        assertEquals("TOMATO", thakkali.englishEquivalent());

        var cheeni = service.normalizeTamilOrTanglish("cheeni");
        assertTrue(cheeni.isTamilOrTanglish());
        assertEquals("SUGAR", cheeni.englishEquivalent());

        var kadugu = service.normalizeTamilOrTanglish("kadugu 100g");
        assertTrue(kadugu.isTamilOrTanglish());
        assertEquals("MUSTARD", kadugu.englishEquivalent());
    }

    @Test
    void testEnglishNonTamilLeavesUntouched() {
        var result = service.normalizeTamilOrTanglish("Fortune Sunflower Oil 1L");
        assertFalse(result.isTamilOrTanglish());
        assertNull(result.englishEquivalent());
    }
}
