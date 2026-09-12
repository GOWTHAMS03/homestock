package com.homestock.modules.bill.matching;

import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Service
public class ProductNormalizationService {

    // Known brand aliases and canonical forms
    private static final Map<String, String> BRAND_ALIASES = Map.ofEntries(
            Map.entry("AASHIRWAD", "AASHIRVAAD"),
            Map.entry("AASHIRVAAD", "AASHIRVAAD"),
            Map.entry("AMUL", "AMUL"),
            Map.entry("FORTUNE", "FORTUNE"),
            Map.entry("SAFFOLA", "SAFFOLA"),
            Map.entry("TATA", "TATA"),
            Map.entry("BRITANNIA", "BRITANNIA"),
            Map.entry("PARLE", "PARLE"),
            Map.entry("NESTLE", "NESTLE"),
            Map.entry("MAGGI", "MAGGI"),
            Map.entry("EVEREST", "EVEREST"),
            Map.entry("MDH", "MDH"),
            Map.entry("HALDIRAM", "HALDIRAM"),
            Map.entry("HALDIRAMS", "HALDIRAM"),
            Map.entry("COLGATE", "COLGATE"),
            Map.entry("DETTOL", "DETTOL"),
            Map.entry("SURF EXCEL", "SURF EXCEL"),
            Map.entry("ARIEL", "ARIEL"),
            Map.entry("TIDE", "TIDE"),
            Map.entry("DAAWAT", "DAAWAT"),
            Map.entry("INDIA GATE", "INDIA GATE")
    );

    // Common grocery synonyms
    private static final Map<String, String> COMMODITY_SYNONYMS = Map.ofEntries(
            Map.entry("WHEAT FLOUR", "ATTA"),
            Map.entry("WHOLE WHEAT ATTA", "ATTA"),
            Map.entry("CHAKKI FRESH ATTA", "ATTA"),
            Map.entry("SUNFLOWER OIL", "OIL"),
            Map.entry("REFINED OIL", "OIL"),
            Map.entry("GROUNDNUT OIL", "OIL"),
            Map.entry("MUSTARD OIL", "OIL"),
            Map.entry("FULL CREAM MILK", "MILK"),
            Map.entry("TONED MILK", "MILK"),
            Map.entry("DOUBLE TONED MILK", "MILK"),
            Map.entry("IODIZED SALT", "SALT"),
            Map.entry("CRYSTAL SALT", "SALT"),
            Map.entry("WHITE SUGAR", "SUGAR")
    );

    // Unit patterns
    private static final Pattern UNIT_PATTERN = Pattern.compile(
            "(\\d+(?:\\.\\d+)?)\\s*(KG|KGS|KILO|KILOS|G|GM|GMS|GRAM|GRAMS|L|LTR|LTRS|LITRE|LITRES|LITER|ML|PKT|PCS|PACK)",
            Pattern.CASE_INSENSITIVE
    );

    public NormalizedProductInfo normalize(String rawName) {
        if (rawName == null || rawName.trim().isEmpty()) {
            return new NormalizedProductInfo("", "", null, "pcs", "");
        }

        String text = rawName.trim().toUpperCase();

        // 1. Fix common OCR mistakes
        text = fixOcrMistakes(text);

        // 2. Extract Pack Size and Unit
        BigDecimal packSize = null;
        String unit = "pcs";
        Matcher unitMatcher = UNIT_PATTERN.matcher(text);
        if (unitMatcher.find()) {
            try {
                packSize = new BigDecimal(unitMatcher.group(1));
                unit = normalizeUnit(unitMatcher.group(2));
            } catch (Exception ignored) {}
        }

        // Strip the unit and pack size from name for canonical base matching
        String nameWithoutUnit = unitMatcher.replaceAll(" ").trim();

        // 3. Extract Brand
        String detectedBrand = extractBrand(text);

        // 4. Clean extra characters and punctuation
        String cleaned = nameWithoutUnit.replaceAll("[^A-Z0-9\\s]", " ")
                .replaceAll("\\s+", " ")
                .trim();

        // 5. Replace synonyms (e.g. "WHEAT FLOUR" -> "ATTA")
        for (Map.Entry<String, String> entry : COMMODITY_SYNONYMS.entrySet()) {
            if (cleaned.contains(entry.getKey())) {
                cleaned = cleaned.replace(entry.getKey(), entry.getValue()).trim();
            }
        }

        // Canonical tokenized name
        String normalizedName = cleaned.replaceAll("\\s+", " ").trim();

        return new NormalizedProductInfo(rawName, normalizedName, packSize, unit, detectedBrand);
    }

    public String normalizeUnit(String rawUnit) {
        if (rawUnit == null) return "pcs";
        String u = rawUnit.toUpperCase().trim();
        if (u.matches("KG|KGS|KILO|KILOS")) return "kg";
        if (u.matches("G|GM|GMS|GRAM|GRAMS")) return "g";
        if (u.matches("L|LTR|LTRS|LITRE|LITRES|LITER")) return "l";
        if (u.matches("ML|MILLILITRE")) return "ml";
        if (u.matches("PKT|PACKET|PACKETS|PACK|PC|PCS|PIECE|PIECES|BOTTLE|BOX")) return "pcs";
        return u.toLowerCase();
    }

    private String fixOcrMistakes(String s) {
        // Replace common OCR number/letter mixups in grocery context
        String fixed = s;
        fixed = fixed.replaceAll("(\\d+)KC\\b", "$1KG"); // KC -> KG
        fixed = fixed.replaceAll("(\\d+)1KG\\b", "$1KG");
        fixed = fixed.replaceAll("\\b0IL\\b", "OIL");
        fixed = fixed.replaceAll("\\bFL0UR\\b", "FLOUR");
        fixed = fixed.replaceAll("\\bSU6AR\\b", "SUGAR");
        return fixed;
    }

    private String extractBrand(String text) {
        for (Map.Entry<String, String> entry : BRAND_ALIASES.entrySet()) {
            if (text.contains(entry.getKey())) {
                return entry.getValue();
            }
        }
        return null;
    }

    public record NormalizedProductInfo(
            String originalName,
            String normalizedName,
            BigDecimal packSize,
            String unit,
            String detectedBrand
    ) {}
}
