package com.homestock.modules.smartshopping.engine.identity;

import org.springframework.stereotype.Component;

import java.util.*;

/**
 * Canonical Product Taxonomy:
 * Defines hierarchical product categories, subcategories, and collision guards.
 * Prevents dangerous category leaks (e.g. Cooking Oil matching Hair Oil,
 * or Sunflower Oil matching Coconut Oil).
 */
@Component
public class ProductTaxonomy {

    public record CategoryNode(
            String name,
            List<String> keywords,
            List<String> subcategories,
            List<String> negativeKeywords
    ) {}

    private static final Map<String, CategoryNode> TAXONOMY = new LinkedHashMap<>();

    private static final List<List<String>> MUTUALLY_EXCLUSIVE_VARIANTS = List.of(
            // Cooking Oils
            List.of("sunflower", "groundnut", "peanut", "mustard", "olive", "sesame", "gingelly", "coconut", "palm", "rice bran", "canola"),
            // Rice
            List.of("basmati", "brown rice", "sona masoori", "ponni", "idli rice", "raw rice", "boiled rice", "jeera samba"),
            // Dairy
            List.of("toned", "double toned", "full cream", "cow milk", "skimmed", "standardized"),
            // Detergent machine type
            List.of("top load", "front load"),
            // Detergent form
            List.of("liquid", "bar", "powder"),
            // Beverages
            List.of("zero sugar", "diet", "regular")
    );

    static {
        TAXONOMY.put("Cooking Oil", new CategoryNode(
                "Cooking Oil",
                List.of("oil", "ennai", "cooking oil", "edible oil", "refined oil"),
                List.of("Sunflower Oil", "Groundnut Oil", "Gingelly Oil", "Coconut Oil", "Mustard Oil", "Rice Bran Oil", "Olive Oil"),
                List.of("hair oil", "castor oil for hair", "motor oil", "engine oil", "aroma oil", "essential oil", "massage oil", "oil pastel")
        ));

        TAXONOMY.put("Laundry & Detergents", new CategoryNode(
                "Laundry & Detergents",
                List.of("detergent", "washing powder", "surf", "thuni soap", "fabric conditioner", "matic"),
                List.of("Detergent Powder", "Liquid Detergent", "Detergent Bar", "Fabric Softener"),
                List.of("dishwash", "floor cleaner", "toilet cleaner")
        ));

        TAXONOMY.put("Rice & Grains", new CategoryNode(
                "Rice & Grains",
                List.of("rice", "arisi", "chawal", "paddy"),
                List.of("Basmati Rice", "Sona Masoori", "Ponni Rice", "Idli Rice", "Brown Rice", "Raw Rice"),
                List.of("rice bran oil", "rice flour", "puffed rice", "rice flakes")
        ));

        TAXONOMY.put("Dairy & Milk", new CategoryNode(
                "Dairy & Milk",
                List.of("milk", "paal", "doodh", "curd", "thayir", "paneer", "butter", "cheese"),
                List.of("Toned Milk", "Full Cream Milk", "Cow Milk", "Curd", "Butter", "Cheese"),
                List.of("milk chocolate", "milk powder", "condensed milk")
        ));

        TAXONOMY.put("Atta & Flours", new CategoryNode(
                "Atta & Flours",
                List.of("atta", "flour", "gothumai", "maida", "besan", "ragi", "sooji", "rava"),
                List.of("Whole Wheat Atta", "Chakki Fresh Atta", "Multigrain Atta", "Maida", "Besan"),
                List.of("biscuit", "cookie")
        ));

        TAXONOMY.put("Dals & Pulses", new CategoryNode(
                "Dals & Pulses",
                List.of("dal", "paruppu", "dhal", "pulses", "toor dal", "moong dal", "urad dal", "chana dal"),
                List.of("Toor Dal", "Moong Dal", "Urad Dal", "Chana Dal", "Masoor Dal"),
                List.of("dal makhani ready to eat", "dal mixture")
        ));

        TAXONOMY.put("Sugar & Sweeteners", new CategoryNode(
                "Sugar & Sweeteners",
                List.of("sugar", "sakkarai", "cheeni", "jaggery", "vellam"),
                List.of("Refined White Sugar", "Sulphurless Sugar", "Brown Sugar", "Jaggery"),
                List.of("sugar free tablet", "sugar scrub")
        ));

        TAXONOMY.put("Personal Care", new CategoryNode(
                "Personal Care",
                List.of("soap", "soappu", "sabun", "toothpaste", "paste", "shampoo", "body wash"),
                List.of("Bathing Soap", "Toothpaste", "Shampoo", "Body Wash"),
                List.of("dishwash soap", "detergent soap")
        ));
    }

    /**
     * Resolve category from input text.
     */
    public String resolveCategory(String text) {
        if (text == null || text.isBlank()) return "Groceries";
        String lower = text.toLowerCase();

        for (Map.Entry<String, CategoryNode> entry : TAXONOMY.entrySet()) {
            CategoryNode node = entry.getValue();
            // Check negative keywords first
            if (node.negativeKeywords.stream().anyMatch(lower::contains)) {
                continue;
            }
            if (node.keywords.stream().anyMatch(lower::contains)) {
                return node.name;
            }
        }
        return "Groceries";
    }

    public record TaxonomyResult(String category, String subCategory) {}

    /**
     * Classifies text into Category and Subcategory.
     */
    public TaxonomyResult classify(String text) {
        if (text == null || text.isBlank()) {
            return new TaxonomyResult("Groceries", "General Grocery");
        }
        String lower = text.toLowerCase();

        for (Map.Entry<String, CategoryNode> entry : TAXONOMY.entrySet()) {
            CategoryNode node = entry.getValue();
            if (node.negativeKeywords.stream().anyMatch(lower::contains)) {
                continue;
            }
            if (node.keywords.stream().anyMatch(lower::contains)) {
                String sub = node.subcategories.stream()
                        .filter(s -> lower.contains(s.toLowerCase()))
                        .findFirst()
                        .orElse(node.subcategories.isEmpty() ? node.name : node.subcategories.get(0));
                return new TaxonomyResult(node.name, sub);
            }
        }
        return new TaxonomyResult("Groceries", "General Grocery");
    }

    /**
     * Check if a candidate product violates the requested category.
     */
    public boolean isCategoryClash(String requestedCategory, String candidateText) {
        return isCategoryMismatch(requestedCategory, candidateText);
    }

    /**
     * Check if two variants conflict within mutually exclusive groups.
     */
    public boolean isVariantClash(String requestedVariant, String candidateText) {
        return hasVariantClash(requestedVariant, candidateText);
    }

    /**
     * Check if a candidate product violates the requested category.
     */
    public boolean isCategoryMismatch(String requestedCategory, String candidateText) {
        if (requestedCategory == null || "Groceries".equalsIgnoreCase(requestedCategory)) {
            return false;
        }

        CategoryNode node = TAXONOMY.get(requestedCategory);
        if (node == null) return false;

        String lowerCand = candidateText != null ? candidateText.toLowerCase() : "";

        // Check if candidate contains negative keywords for the requested category
        for (String neg : node.negativeKeywords) {
            if (lowerCand.contains(neg)) {
                return true;
            }
        }

        return false;
    }

    /**
     * Check if two variants conflict within mutually exclusive groups
     * (e.g. Sunflower vs Mustard, Basmati vs Brown rice).
     */
    public boolean hasVariantClash(String requestedVariant, String candidateText) {
        if (requestedVariant == null || candidateText == null) return false;
        String req = requestedVariant.toLowerCase().trim();
        String cand = candidateText.toLowerCase().trim();

        for (List<String> group : MUTUALLY_EXCLUSIVE_VARIANTS) {
            boolean reqInGroup = group.stream().anyMatch(req::contains);
            if (reqInGroup) {
                for (String v : group) {
                    if (cand.contains(v) && !req.contains(v)) {
                        return true;
                    }
                }
            }
        }
        return false;
    }
}
