package com.homestock.modules.smartshopping.engine;

import com.homestock.modules.smartshopping.dto.ProductSearchIntentDto;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * ProductIntentEngine:
 * Analyzes search input or shopping item names and extracts structured product intent:
 * - Detects search mode (GENERIC_DISCOVERY vs EXACT_PRODUCT)
 * - Assigns search priority (BARCODE > EXACT_NAME > BRAND_AND_TYPE > TYPE_AND_VARIANT > GENERIC_CATEGORY)
 * - Normalizes Tamil/Tanglish and regional synonyms
 * - Extracts brand, variant, pack size, and unit
 * - Identifies primary category and available sub-types for broad discovery
 */
@Component
public class ProductIntentEngine {

    private static final Logger log = LoggerFactory.getLogger(ProductIntentEngine.class);

    private static final Pattern BARCODE_PATTERN = Pattern.compile("^\\d{8,14}$");
    private static final Pattern PACK_SIZE_PATTERN = Pattern.compile("(?i)\\b(\\d+(?:\\.\\d+)?)\\s*(l(?:itre|iters?|iter)?|ml|kg|kilos?|g(?:m|rams?)?|pcs?|packs?)\\b");

    // Known Brands in Indian Grocery & Retail
    private static final List<String> KNOWN_BRANDS = List.of(
            "Fortune", "Saffola", "Freedom", "Gold Winner", "Gemini", "Sundrop", "Dhara", "Idhayam",
            "Aashirvaad", "India Gate", "Daawat", "Kohinoor", "Fortune Rozana", "Pillsbury",
            "Amul", "Nandini", "Heritage", "Mother Dairy", "Milky Mist", "Aavin", "Govind",
            "Tata Sampann", "Tata", "Trust", "Madhur", "Parry's", "24 Mantra",
            "Surf Excel", "Ariel", "Tide", "Rin", "Henko", "Vim", "Pril",
            "Colgate", "Pepsodent", "Sensodyne", "Close Up", "Dabur Red", "Vicco",
            "Dettol", "Lifebuoy", "Dove", "Lux", "Pears", "Cinthol", "Hamam", "Medimix",
            "Head & Shoulders", "Pantene", "Sunsilk", "Dove Hair", "Clinic Plus", "Tresemme",
            "Tata Tea", "Red Label", "Taj Mahal", "Bru", "Nescafe", "Sunrise",
            "Parle", "Britannia", "Sunfeast", "Oreo", "Good Day", "Marie Gold"
    );

    // Category mappings and their valid subtype lists
    private static final Map<String, CategoryDefinition> CATEGORY_CATALOG = new LinkedHashMap<>();

    static {
        CATEGORY_CATALOG.put("Cooking Oil", new CategoryDefinition(
                "Cooking Oil",
                List.of("oil", "ennai", "samayal ennai", "cooking oil", "edible oil", "refined oil"),
                List.of("Sunflower", "Groundnut", "Rice Bran", "Coconut", "Sesame", "Mustard", "Gingelly", "Olive", "Palmolein")
        ));

        CATEGORY_CATALOG.put("Rice & Grains", new CategoryDefinition(
                "Rice & Grains",
                List.of("rice", "arisi", "chawal", "paddy"),
                List.of("Basmati", "Sona Masoori", "Ponni", "Idli Rice", "Brown Rice", "Raw Rice", "Jeera Samba", "Boiled Rice")
        ));

        CATEGORY_CATALOG.put("Dairy & Milk", new CategoryDefinition(
                "Dairy & Milk",
                List.of("milk", "paal", "doodh", "curd", "thayir", "paneer", "butter", "cheese"),
                List.of("Toned", "Full Cream", "Cow Milk", "Standardized", "Double Toned", "Organic Cow Milk")
        ));

        CATEGORY_CATALOG.put("Atta & Flours", new CategoryDefinition(
                "Atta & Flours",
                List.of("atta", "flour", "gothumai", "maida", "besan", "ragi", "sooji", "rava"),
                List.of("Whole Wheat", "Multigrain", "Chakki Fresh", "Maida", "Rava / Sooji", "Besan")
        ));

        CATEGORY_CATALOG.put("Dals & Pulses", new CategoryDefinition(
                "Dals & Pulses",
                List.of("dal", "paruppu", "dhal", "pulses", "toor dal", "moong dal", "urad dal", "chana dal"),
                List.of("Toor Dal", "Moong Dal", "Urad Dal", "Chana Dal", "Masoor Dal", "Rajma", "Kabuli Chana")
        ));

        CATEGORY_CATALOG.put("Sugar & Sweeteners", new CategoryDefinition(
                "Sugar & Sweeteners",
                List.of("sugar", "sakkarai", "cheeni", "jaggery", "vellam", "nattu sakkarai", "honey"),
                List.of("Refined White Sugar", "Brown Sugar", "Jaggery / Nattu Sakkarai", "Sulphurless Sugar", "Pure Honey")
        ));

        CATEGORY_CATALOG.put("Cleaning & Detergents", new CategoryDefinition(
                "Cleaning & Detergents",
                List.of("detergent", "washing powder", "surf", "thuni soap", "dishwash", "floor cleaner"),
                List.of("Detergent Powder", "Liquid Detergent", "Dishwash Bar", "Dishwash Liquid", "Fabric Conditioner")
        ));

        CATEGORY_CATALOG.put("Personal Care", new CategoryDefinition(
                "Personal Care",
                List.of("soap", "soappu", "sabun", "toothpaste", "paste", "shampoo", "body wash"),
                List.of("Bathing Soap", "Toothpaste", "Shampoo", "Handwash", "Body Wash")
        ));

        CATEGORY_CATALOG.put("Tea & Coffee", new CategoryDefinition(
                "Tea & Coffee",
                List.of("tea", "thool", "chai", "coffee", "kaapi"),
                List.of("Black Tea", "Green Tea", "Filter Coffee", "Instant Coffee")
        ));
    }

    // Specific variant mapping for sub-types
    private static final Map<String, String> VARIANT_SYNONYMS = new LinkedHashMap<>();

    static {
        // Oil variants
        VARIANT_SYNONYMS.put("sunflower", "Sunflower");
        VARIANT_SYNONYMS.put("sun flower", "Sunflower");
        VARIANT_SYNONYMS.put("groundnut", "Groundnut");
        VARIANT_SYNONYMS.put("ground nut", "Groundnut");
        VARIANT_SYNONYMS.put("kadala", "Groundnut");
        VARIANT_SYNONYMS.put("kadalai", "Groundnut");
        VARIANT_SYNONYMS.put("peanut", "Groundnut");
        VARIANT_SYNONYMS.put("rice bran", "Rice Bran");
        VARIANT_SYNONYMS.put("ricebran", "Rice Bran");
        VARIANT_SYNONYMS.put("coconut", "Coconut");
        VARIANT_SYNONYMS.put("thengai", "Coconut");
        VARIANT_SYNONYMS.put("sesame", "Sesame");
        VARIANT_SYNONYMS.put("gingelly", "Gingelly");
        VARIANT_SYNONYMS.put("nalla ennai", "Sesame");
        VARIANT_SYNONYMS.put("til", "Sesame");
        VARIANT_SYNONYMS.put("mustard", "Mustard");
        VARIANT_SYNONYMS.put("kadugu", "Mustard");
        VARIANT_SYNONYMS.put("sarson", "Mustard");
        VARIANT_SYNONYMS.put("olive", "Olive");
        VARIANT_SYNONYMS.put("palmolein", "Palmolein");
        VARIANT_SYNONYMS.put("palm", "Palmolein");

        // Rice variants
        VARIANT_SYNONYMS.put("basmati", "Basmati");
        VARIANT_SYNONYMS.put("sona masoori", "Sona Masoori");
        VARIANT_SYNONYMS.put("sonamasoori", "Sona Masoori");
        VARIANT_SYNONYMS.put("ponni", "Ponni");
        VARIANT_SYNONYMS.put("idli rice", "Idli Rice");
        VARIANT_SYNONYMS.put("idly rice", "Idli Rice");
        VARIANT_SYNONYMS.put("brown rice", "Brown Rice");
        VARIANT_SYNONYMS.put("jeera samba", "Jeera Samba");
        VARIANT_SYNONYMS.put("seeraga samba", "Jeera Samba");
        VARIANT_SYNONYMS.put("boiled rice", "Boiled Rice");
        VARIANT_SYNONYMS.put("raw rice", "Raw Rice");

        // Milk variants
        VARIANT_SYNONYMS.put("toned", "Toned");
        VARIANT_SYNONYMS.put("full cream", "Full Cream");
        VARIANT_SYNONYMS.put("cow milk", "Cow Milk");
        VARIANT_SYNONYMS.put("standardized", "Standardized");
        VARIANT_SYNONYMS.put("double toned", "Double Toned");
    }

    /**
     * Parse raw query or shopping list item into a comprehensive ProductSearchIntentDto.
     */
    public ProductSearchIntentDto parseIntent(String rawQuery, String barcodeParam, String brandParam, String unitParam) {
        String query = rawQuery != null ? rawQuery.trim() : "";
        String barcode = barcodeParam != null && !barcodeParam.isBlank() ? barcodeParam.trim() : null;

        // 1. Check if query itself is a Barcode / GTIN
        if (barcode == null && BARCODE_PATTERN.matcher(query).matches()) {
            barcode = query;
        }

        if (barcode != null) {
            log.info("[ProductIntentEngine] Intent is BARCODE: {}", barcode);
            return ProductSearchIntentDto.builder()
                    .rawQuery(query)
                    .normalizedQuery(query)
                    .searchMode("EXACT_PRODUCT")
                    .searchPriority("BARCODE")
                    .targetBarcode(barcode)
                    .primaryCategory("General")
                    .allowedTypes(List.of())
                    .build();
        }

        String lowerQuery = query.toLowerCase();

        // 2. Extract Pack Size & Unit
        String extractedPackSize = null;
        String extractedUnit = unitParam;
        Matcher sizeMatcher = PACK_SIZE_PATTERN.matcher(query);
        if (sizeMatcher.find()) {
            extractedPackSize = sizeMatcher.group(0).trim();
            if (extractedUnit == null || extractedUnit.isBlank()) {
                extractedUnit = sizeMatcher.group(2).trim();
            }
        }

        // 3. Extract Brand
        String extractedBrand = brandParam;
        if (extractedBrand == null || extractedBrand.isBlank()) {
            for (String b : KNOWN_BRANDS) {
                if (lowerQuery.contains(b.toLowerCase())) {
                    extractedBrand = b;
                    break;
                }
            }
        }

        // 4. Extract Variant / Sub-type
        String extractedVariant = null;
        for (Map.Entry<String, String> entry : VARIANT_SYNONYMS.entrySet()) {
            if (lowerQuery.contains(entry.getKey())) {
                extractedVariant = entry.getValue();
                break;
            }
        }

        // 5. Detect Primary Category and Allowed Subtypes
        String primaryCategory = "Pantry Essentials";
        List<String> allowedTypes = new ArrayList<>();

        for (Map.Entry<String, CategoryDefinition> catEntry : CATEGORY_CATALOG.entrySet()) {
            CategoryDefinition def = catEntry.getValue();
            boolean matchesCategory = def.synonyms.stream().anyMatch(lowerQuery::contains);
            if (matchesCategory) {
                primaryCategory = def.categoryName;
                allowedTypes = new ArrayList<>(def.subTypes);
                break;
            }
        }

        // 6. Regional Tamil/Tanglish Normalization
        String normalizedQuery = normalizeLanguageSynonyms(query);

        // 7. Determine Search Priority and Mode
        String searchPriority;
        String searchMode;

        if (extractedBrand != null && (extractedVariant != null || extractedPackSize != null)) {
            searchPriority = extractedPackSize != null ? "EXACT_PRODUCT_NAME" : "BRAND_AND_TYPE";
            searchMode = "EXACT_PRODUCT";
        } else if (extractedBrand != null) {
            searchPriority = "BRAND_AND_TYPE";
            searchMode = "EXACT_PRODUCT";
        } else if (extractedVariant != null && extractedPackSize != null) {
            searchPriority = "EXACT_PRODUCT_NAME";
            searchMode = "EXACT_PRODUCT";
        } else if (extractedVariant != null) {
            searchPriority = "TYPE_AND_VARIANT";
            // User specified a variant e.g. "Sunflower Oil", but not brand -> discovery within that variant
            searchMode = "GENERIC_DISCOVERY";
        } else {
            searchPriority = "GENERIC_CATEGORY";
            searchMode = "GENERIC_DISCOVERY";
        }

        log.info("[ProductIntentEngine] Query='{}' → Mode={}, Priority={}, Category='{}', Brand='{}', Variant='{}', Size='{}'",
                query, searchMode, searchPriority, primaryCategory, extractedBrand, extractedVariant, extractedPackSize);

        return ProductSearchIntentDto.builder()
                .rawQuery(query)
                .normalizedQuery(normalizedQuery)
                .searchMode(searchMode)
                .searchPriority(searchPriority)
                .primaryCategory(primaryCategory)
                .extractedVariant(extractedVariant)
                .extractedBrand(extractedBrand)
                .extractedPackSize(extractedPackSize)
                .extractedUnit(extractedUnit)
                .targetBarcode(barcode)
                .allowedTypes(allowedTypes)
                .build();
    }

    private String normalizeLanguageSynonyms(String raw) {
        String clean = raw.toLowerCase().trim();
        // Replace common Tamil/Tanglish terms with English equivalents for standard indexing
        clean = clean.replaceAll("\\bsamayal\\s+ennai\\b", "cooking oil");
        clean = clean.replaceAll("\\bennai\\b", "oil");
        clean = clean.replaceAll("\\barisi\\b", "rice");
        clean = clean.replaceAll("\\bpaal\\b", "milk");
        clean = clean.replaceAll("\\bsakkarai\\b", "sugar");
        clean = clean.replaceAll("\\bparuppu\\b", "dal");
        clean = clean.replaceAll("\\bgothumai\\b", "atta");
        clean = clean.replaceAll("\\buppu\\b", "salt");
        clean = clean.replaceAll("\\bsoappu\\b", "soap");
        clean = clean.replaceAll("\\bthool\\b", "tea");
        clean = clean.replaceAll("\\bkaapi\\b", "coffee");
        return clean.trim();
    }

    private record CategoryDefinition(
            String categoryName,
            List<String> synonyms,
            List<String> subTypes
    ) {}
}
