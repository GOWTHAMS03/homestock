package com.homestock.modules.smartshopping.engine.intent;

import com.homestock.modules.smartshopping.dto.SearchIntent;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Set;

/**
 * Classifies search inputs into the 5 search intent categories:
 * EXACT_PRODUCT, BRANDED_PRODUCT, SPECIFIC_VARIANT, GENERIC_PRODUCT, INSUFFICIENT_INFORMATION.
 */
@Component
public class SearchIntentClassifier {

    private static final Set<String> AMBIGUOUS_SINGLE_TERMS = Set.of(
            "oil", "ennai", "soap", "soappu", "sabun", "rice", "arisi", "chawal",
            "dal", "paruppu", "dhal", "atta", "flour", "sugar", "sakkarai", "milk", "paal",
            "tea", "thool", "coffee", "biscuit", "paste", "shampoo", "cleaner"
    );

    private static final List<String> SAFE_GENERIC_PATTERNS = List.of(
            "sunflower oil", "groundnut oil", "mustard oil", "coconut oil", "sesame oil", "gingelly oil", "olive oil", "rice bran oil", "cooking oil",
            "basmati rice", "sona masoori", "ponni rice", "idli rice", "brown rice",
            "toor dal", "moong dal", "urad dal", "chana dal", "masoor dal",
            "whole wheat atta", "chakki atta", "maida", "besan", "ragi flour",
            "bathing soap", "toilet soap", "body wash", "hand wash",
            "dishwash liquid", "dishwash bar", "washing powder", "detergent powder", "liquid detergent",
            "toned milk", "cow milk", "full cream milk",
            "black tea", "green tea", "filter coffee", "instant coffee"
    );

    /**
     * Classify input based on extracted components.
     *
     * @param rawQuery    original query text
     * @param brand       extracted brand (if any)
     * @param variant     extracted variant/flavor (if any)
     * @param packSize    extracted pack size (if any)
     * @param barcode     barcode / GTIN (if any)
     * @param category    detected primary category
     * @return SearchIntent classification
     */
    public SearchIntent classify(
            String rawQuery,
            String brand,
            String variant,
            String packSize,
            String barcode,
            String category
    ) {
        String query = rawQuery != null ? rawQuery.trim().toLowerCase() : "";

        // 1. Barcode is always EXACT_PRODUCT
        if (barcode != null && !barcode.isBlank()) {
            return SearchIntent.EXACT_PRODUCT;
        }

        // 2. Check for Ambiguous / Insufficient Information
        // If single token and matches overly broad words without qualifiers
        String[] tokens = query.split("\\s+");
        if (tokens.length == 1 && AMBIGUOUS_SINGLE_TERMS.contains(tokens[0]) && brand == null && variant == null && packSize == null) {
            return SearchIntent.INSUFFICIENT_INFORMATION;
        }

        // 3. Exact Product: User provided Brand + (Variant or Pack Size or clear specific name)
        if (brand != null && !brand.isBlank()) {
            if (variant != null && !variant.isBlank() && packSize != null && !packSize.isBlank()) {
                return SearchIntent.EXACT_PRODUCT;
            }
            if (variant != null && !variant.isBlank()) {
                return SearchIntent.EXACT_PRODUCT;
            }
            if (packSize != null && !packSize.isBlank()) {
                return SearchIntent.EXACT_PRODUCT;
            }
            // Brand only with general noun (e.g. "Parle-G 800g", "Amul Butter")
            return SearchIntent.BRANDED_PRODUCT;
        }

        // 4. Specific Variant without Brand (e.g. "Coca Cola Zero Sugar 750ml" or "Cold Pressed Gingelly Oil 1L")
        if (variant != null && !variant.isBlank()) {
            if (packSize != null && !packSize.isBlank()) {
                return SearchIntent.SPECIFIC_VARIANT;
            }
            // Check if query specifies a safe multi-token generic grocery staple
            for (String pattern : SAFE_GENERIC_PATTERNS) {
                if (query.contains(pattern)) {
                    return SearchIntent.GENERIC_PRODUCT;
                }
            }
            return SearchIntent.SPECIFIC_VARIANT;
        }

        // 5. Check if multi-word query is a safe generic staple
        for (String pattern : SAFE_GENERIC_PATTERNS) {
            if (query.contains(pattern)) {
                return SearchIntent.GENERIC_PRODUCT;
            }
        }

        // 6. If has pack size e.g. "Sunflower oil 1L"
        if (packSize != null && !packSize.isBlank() && tokens.length >= 2) {
            return SearchIntent.GENERIC_PRODUCT;
        }

        // Fallback: If 2 or more tokens in recognized category
        if (tokens.length >= 2) {
            return SearchIntent.GENERIC_PRODUCT;
        }

        return SearchIntent.INSUFFICIENT_INFORMATION;
    }
}
