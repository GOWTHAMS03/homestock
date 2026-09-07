package com.homestock.modules.voice.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class TamilTanglishNormalizerTest {

    private TamilTanglishNormalizer normalizer;

    @BeforeEach
    void setUp() {
        normalizer = new TamilTanglishNormalizer();
    }

    @Test
    void testTamilScriptNormalizations() {
        assertEquals("Rice", normalizer.normalizeItemName("அரிசி"));
        assertEquals("Cooking Oil", normalizer.normalizeItemName("எண்ணெய்"));
        assertEquals("Milk", normalizer.normalizeItemName("பால்"));
        assertEquals("Sugar", normalizer.normalizeItemName("சர்க்கரை"));
        assertEquals("Toor Dal", normalizer.normalizeItemName("துவரம் பருப்பு"));
    }

    @Test
    void testTanglishNormalizations() {
        assertEquals("Rice", normalizer.normalizeItemName("arisi"));
        assertEquals("Cooking Oil", normalizer.normalizeItemName("ennai"));
        assertEquals("Milk", normalizer.normalizeItemName("paal"));
        assertEquals("Sugar", normalizer.normalizeItemName("sakkarai"));
        assertEquals("Salt", normalizer.normalizeItemName("uppu"));
        assertEquals("Onion", normalizer.normalizeItemName("vengayam"));
        assertEquals("Tomato", normalizer.normalizeItemName("thakkali"));
    }

    @Test
    void testCleanPostpositions() {
        assertEquals("shopping list", normalizer.cleanPostpositions("shopping-list-la"));
        assertEquals("rice", normalizer.cleanPostpositions("rice-ah"));
        assertEquals("arisi", normalizer.cleanPostpositions("arisila"));
    }
}
