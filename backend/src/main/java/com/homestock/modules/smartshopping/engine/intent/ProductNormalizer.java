package com.homestock.modules.smartshopping.engine.intent;

import org.springframework.stereotype.Component;

import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Normalizes input text, packaging units, and regional grocery terminology.
 */
@Component
public class ProductNormalizer {

    private static final Map<String, String> REGIONAL_SYNONYMS = new LinkedHashMap<>();
    private static final Map<String, String> UNIT_CANONICAL_MAP = new LinkedHashMap<>();

    static {
        // Tamil / Tanglish / Hindi regional food terms
        REGIONAL_SYNONYMS.put("\\bsamayal\\s+ennai\\b", "cooking oil");
        REGIONAL_SYNONYMS.put("\\bennai\\b", "oil");
        REGIONAL_SYNONYMS.put("\\barisi\\b", "rice");
        REGIONAL_SYNONYMS.put("\\bchawal\\b", "rice");
        REGIONAL_SYNONYMS.put("\\bpaal\\b", "milk");
        REGIONAL_SYNONYMS.put("\\bdoodh\\b", "milk");
        REGIONAL_SYNONYMS.put("\\bsakkarai\\b", "sugar");
        REGIONAL_SYNONYMS.put("\\bcheeni\\b", "sugar");
        REGIONAL_SYNONYMS.put("\\bvellam\\b", "jaggery");
        REGIONAL_SYNONYMS.put("\\bparuppu\\b", "dal");
        REGIONAL_SYNONYMS.put("\\bdhal\\b", "dal");
        REGIONAL_SYNONYMS.put("\\bgothumai\\b", "atta");
        REGIONAL_SYNONYMS.put("\\buppu\\b", "salt");
        REGIONAL_SYNONYMS.put("\\bnamak\\b", "salt");
        REGIONAL_SYNONYMS.put("\\bsoappu\\b", "soap");
        REGIONAL_SYNONYMS.put("\\bsabun\\b", "soap");
        REGIONAL_SYNONYMS.put("\\bthool\\b", "tea");
        REGIONAL_SYNONYMS.put("\\bchai\\b", "tea");
        REGIONAL_SYNONYMS.put("\\bkaapi\\b", "coffee");

        // Units normalization
        UNIT_CANONICAL_MAP.put("litre", "L");
        UNIT_CANONICAL_MAP.put("litres", "L");
        UNIT_CANONICAL_MAP.put("liter", "L");
        UNIT_CANONICAL_MAP.put("liters", "L");
        UNIT_CANONICAL_MAP.put("ltr", "L");
        UNIT_CANONICAL_MAP.put("l", "L");

        UNIT_CANONICAL_MAP.put("millilitre", "ml");
        UNIT_CANONICAL_MAP.put("millilitres", "ml");
        UNIT_CANONICAL_MAP.put("milliliter", "ml");
        UNIT_CANONICAL_MAP.put("milliliters", "ml");
        UNIT_CANONICAL_MAP.put("ml", "ml");

        UNIT_CANONICAL_MAP.put("kilogram", "kg");
        UNIT_CANONICAL_MAP.put("kilograms", "kg");
        UNIT_CANONICAL_MAP.put("kilos", "kg");
        UNIT_CANONICAL_MAP.put("kilo", "kg");
        UNIT_CANONICAL_MAP.put("kgs", "kg");
        UNIT_CANONICAL_MAP.put("kg", "kg");

        UNIT_CANONICAL_MAP.put("grams", "g");
        UNIT_CANONICAL_MAP.put("gram", "g");
        UNIT_CANONICAL_MAP.put("gms", "g");
        UNIT_CANONICAL_MAP.put("gm", "g");
        UNIT_CANONICAL_MAP.put("g", "g");

        UNIT_CANONICAL_MAP.put("bottles", "bottle");
        UNIT_CANONICAL_MAP.put("bottle", "bottle");
        UNIT_CANONICAL_MAP.put("packs", "pack");
        UNIT_CANONICAL_MAP.put("packet", "pack");
        UNIT_CANONICAL_MAP.put("packets", "pack");
        UNIT_CANONICAL_MAP.put("pack", "pack");
        UNIT_CANONICAL_MAP.put("cans", "can");
        UNIT_CANONICAL_MAP.put("can", "can");
        UNIT_CANONICAL_MAP.put("pouches", "pouch");
        UNIT_CANONICAL_MAP.put("pouch", "pouch");
        UNIT_CANONICAL_MAP.put("pieces", "pc");
        UNIT_CANONICAL_MAP.put("piece", "pc");
        UNIT_CANONICAL_MAP.put("pcs", "pc");
        UNIT_CANONICAL_MAP.put("pc", "pc");
    }

    /**
     * Normalize regional/colloquial words in raw queries.
     */
    public String normalizeRegionalText(String raw) {
        if (raw == null || raw.isBlank()) return "";
        String clean = raw.toLowerCase().trim();
        for (Map.Entry<String, String> entry : REGIONAL_SYNONYMS.entrySet()) {
            clean = clean.replaceAll(entry.getKey(), entry.getValue());
        }
        return clean.replaceAll("\\s+", " ").trim();
    }

    /**
     * Normalize unit string to canonical abbreviation (e.g. "litres" -> "L", "kilograms" -> "kg").
     */
    public String normalizeUnit(String unit) {
        if (unit == null || unit.isBlank()) return null;
        String key = unit.toLowerCase().trim();
        return UNIT_CANONICAL_MAP.getOrDefault(key, unit.trim());
    }

    /**
     * Normalize pack size string (e.g. "1 L", "1 ltr", "1litre" -> "1L", "500 gm" -> "500g").
     */
    public String normalizePackSize(String packSize) {
        if (packSize == null || packSize.isBlank()) return null;
        String clean = packSize.trim();

        // Match number followed by unit
        java.util.regex.Matcher m = java.util.regex.Pattern
                .compile("(?i)^(\\d+(?:\\.\\d+)?)\\s*([a-zA-Z]+)$")
                .matcher(clean);
        if (m.matches()) {
            String qty = m.group(1);
            String u = normalizeUnit(m.group(2));
            return qty + (u != null ? u : "");
        }
        return clean;
    }

    /**
     * Normalize general query string by trimming and collapsing consecutive whitespace.
     */
    public String cleanWhitespace(String input) {
        if (input == null) return "";
        return input.replaceAll("[\\t\\r\\n]+", " ").replaceAll("\\s{2,}", " ").trim();
    }
}
