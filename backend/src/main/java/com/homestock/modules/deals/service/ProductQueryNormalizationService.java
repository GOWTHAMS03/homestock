package com.homestock.modules.deals.service;

import com.homestock.modules.deals.model.NormalizedProductQuery;
import com.homestock.modules.smartshopping.engine.identity.BrandResolver;
import com.homestock.modules.smartshopping.engine.identity.ProductTaxonomy;
import com.homestock.modules.smartshopping.engine.intent.ProductNormalizer;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Normalizes user queries into structured product attributes and canonical units.
 * Phase 2 — Normalized Product Search.
 */
@Service
@RequiredArgsConstructor
public class ProductQueryNormalizationService {

    private final ProductNormalizer productNormalizer;
    private final BrandResolver brandResolver;
    private final ProductTaxonomy productTaxonomy;

    // Matches combos: e.g. "2 x 1L", "2x500ml", "pack of 2"
    private static final Pattern COMBO_PATTERN = Pattern.compile(
            "(?i)\\b(?:(\\d+)\\s*x\\s*|pack\\s+of\\s+(\\d+)|(\\d+)\\s*pack\\b)", Pattern.CASE_INSENSITIVE);

    // Matches quantity & unit: e.g. "1 litre", "1l", "1 l", "1000ml", "500 g", "5kg", "2.5 kg"
    private static final Pattern QTY_UNIT_PATTERN = Pattern.compile(
            "(?i)\\b(\\d+(?:\\.\\d+)?)\\s*(l|ltr|litre|liter|litres|liters|ml|millilitre|milliliter|kg|kgs|kilo|kilogram|kilograms|g|gm|gms|gram|grams|pcs|pc|pack|can|bottle|pouch)\\b");

    private static final Map<String, String> OIL_VARIANTS = Map.ofEntries(
            Map.entry("sunflower", "Sunflower"),
            Map.entry("rice bran", "Rice Bran"),
            Map.entry("ricebran", "Rice Bran"),
            Map.entry("groundnut", "Groundnut"),
            Map.entry("peanut", "Groundnut"),
            Map.entry("mustard", "Mustard"),
            Map.entry("sarson", "Mustard"),
            Map.entry("sesame", "Sesame"),
            Map.entry("gingelly", "Sesame"),
            Map.entry("olive", "Olive"),
            Map.entry("soybean", "Soybean"),
            Map.entry("soya", "Soybean"),
            Map.entry("coconut", "Coconut"),
            Map.entry("palm", "Palm")
    );

    public NormalizedProductQuery normalize(String query) {
        if (query == null || query.isBlank()) {
            return NormalizedProductQuery.builder()
                    .rawQuery("")
                    .normalizedQuery("")
                    .packCount(1)
                    .build();
        }

        String raw = query.trim();
        // 1. Regional synonym normalization & lowercase
        String normalized = productNormalizer != null
                ? productNormalizer.normalizeRegionalText(raw)
                : raw.toLowerCase();

        // Punctuation clean: keep periods inside numbers like 1.5, replace other symbols with space
        normalized = normalized.replaceAll("(?<!\\d)[,;!?:/\\-_#@*]+(?!=|\\d)", " ")
                .replaceAll("(?<=\\d)[,;!?:/\\_#@*]+(?!=|\\d)", " ")
                .replaceAll("\\s+", " ")
                .trim();

        // 2. Combo / packCount extraction
        int packCount = 1;
        Matcher comboMatcher = COMBO_PATTERN.matcher(normalized);
        if (comboMatcher.find()) {
            String c1 = comboMatcher.group(1);
            String c2 = comboMatcher.group(2);
            String c3 = comboMatcher.group(3);
            String val = c1 != null ? c1 : (c2 != null ? c2 : c3);
            if (val != null) {
                try {
                    packCount = Integer.parseInt(val);
                } catch (NumberFormatException ignored) {}
            }
        }

        // 3. Quantity and unit canonicalization
        BigDecimal canonicalQty = null;
        String canonicalUnit = null;
        String displayPack = null;

        Matcher qtyMatcher = QTY_UNIT_PATTERN.matcher(normalized);
        if (qtyMatcher.find()) {
            try {
                BigDecimal rawQty = new BigDecimal(qtyMatcher.group(1));
                String rawUnit = qtyMatcher.group(2).toLowerCase();

                switch (rawUnit) {
                    case "l", "ltr", "litre", "liter", "litres", "liters" -> {
                        canonicalQty = rawQty.multiply(new BigDecimal("1000"));
                        canonicalUnit = "ML";
                        displayPack = rawQty.stripTrailingZeros().toPlainString() + " L";
                    }
                    case "ml", "millilitre", "milliliter" -> {
                        canonicalQty = rawQty;
                        canonicalUnit = "ML";
                        displayPack = rawQty.stripTrailingZeros().toPlainString() + " ml";
                    }
                    case "kg", "kgs", "kilo", "kilogram", "kilograms" -> {
                        canonicalQty = rawQty.multiply(new BigDecimal("1000"));
                        canonicalUnit = "G";
                        displayPack = rawQty.stripTrailingZeros().toPlainString() + " kg";
                    }
                    case "g", "gm", "gms", "gram", "grams" -> {
                        canonicalQty = rawQty;
                        canonicalUnit = "G";
                        displayPack = rawQty.stripTrailingZeros().toPlainString() + " g";
                    }
                    default -> {
                        canonicalQty = rawQty;
                        canonicalUnit = "PCS";
                        displayPack = rawQty.stripTrailingZeros().toPlainString() + " pcs";
                    }
                }
            } catch (Exception ignored) {}
        }

        // 4. Brand resolution
        String brand = null;
        if (brandResolver != null) {
            BrandResolver.BrandMatch bm = brandResolver.findBrand(normalized);
            if (bm != null) {
                brand = bm.canonicalBrand();
            }
        }

        // 5. Variant resolution (e.g. Sunflower, Rice Bran, etc.)
        String variant = null;
        for (Map.Entry<String, String> entry : OIL_VARIANTS.entrySet()) {
            if (Pattern.compile("\\b" + Pattern.quote(entry.getKey()) + "\\b", Pattern.CASE_INSENSITIVE).matcher(normalized).find()) {
                variant = entry.getValue();
                break;
            }
        }

        // 6. Category resolution
        String category = null;
        if (normalized.contains("oil") || (variant != null && OIL_VARIANTS.containsValue(variant))) {
            category = "Cooking Oil";
        } else if (normalized.contains("rice") || normalized.contains("basmati")) {
            category = "Rice & Grains";
        } else if (normalized.contains("atta") || normalized.contains("flour")) {
            category = "Flour & Atta";
        } else if (normalized.contains("dal") || normalized.contains("dhal") || normalized.contains("pulse")) {
            category = "Dals & Pulses";
        } else if (normalized.contains("milk") || normalized.contains("curd") || normalized.contains("paneer")) {
            category = "Dairy";
        } else if (productTaxonomy != null) {
            category = productTaxonomy.resolveCategory(normalized);
        }

        // 7. Product name clean derivation
        String product = normalized;
        if (variant != null && category != null && category.equals("Cooking Oil")) {
            product = variant + " Oil";
        } else if (category != null && !category.isBlank()) {
            product = category;
        }

        return NormalizedProductQuery.builder()
                .rawQuery(raw)
                .normalizedQuery(normalized)
                .brand(brand)
                .category(category)
                .product(product)
                .variant(variant)
                .canonicalQuantity(canonicalQty)
                .canonicalUnit(canonicalUnit)
                .packCount(packCount)
                .displayPackSize(displayPack)
                .build();
    }
}
