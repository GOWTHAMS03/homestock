package com.homestock.modules.smartshopping.engine.intent;

import com.homestock.modules.smartshopping.dto.ProductIntent;
import com.homestock.modules.smartshopping.dto.SearchIntent;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Extracts and normalizes structured Product Intent from user input.
 * Extracts 18+ fields, separates pack size from requested quantity,
 * and computes confidence scores.
 */
@Component
@RequiredArgsConstructor
public class ProductIntentExtractor {

    private static final Logger log = LoggerFactory.getLogger(ProductIntentExtractor.class);

    private final ProductNormalizer normalizer;
    private final SearchIntentClassifier classifier;

    private static final Pattern BARCODE_PATTERN = Pattern.compile("^\\d{8,14}$");

    // Pack size pattern: e.g. "1L", "500 ml", "2 kg", "5kg", "800g"
    private static final Pattern PACK_SIZE_PATTERN = Pattern.compile(
            "(?i)\\b(\\d+(?:\\.\\d+)?)\\s*(l(?:itre|iters?|iter)?|ml|kg|kilos?|g(?:m|rams?)?|pcs?|packs?)\\b"
    );

    // Quantity pattern e.g. "- 2 bottles", "quantity 3", "qty: 2", "2 bottles", "x 4", "3 cans"
    private static final Pattern EXPLICIT_QTY_DASH_PATTERN = Pattern.compile(
            "(?i)[\\s,-]+(?:quantity|qty|need|count)?[\\s:=]*(\\d+(?:\\.\\d+)?)\\s*(bottles?|packs?|packets?|cans?|pouches?|bags?|boxes?|pieces?|pcs?|units?|items?)\\b"
    );

    private static final Pattern EXPLICIT_QTY_WORD_PATTERN = Pattern.compile(
            "(?i)\\b(?:quantity|qty|need|count)[\\s:=]+(\\d+(?:\\.\\d+)?)(?:\\s*(bottles?|packs?|cans?|pouches?|bags?|pcs?|units?))?\\b"
    );

    private static final Pattern MULTIPLIER_PATTERN = Pattern.compile(
            "(?i)\\b[xX*]\\s*(\\d+(?:\\.\\d+)?)(?:\\s*(bottles?|packs?|cans?|pouches?|bags?|pcs?))?\\b"
    );

    private static final List<String> KNOWN_BRANDS = List.of(
            "Fortune", "Saffola", "Freedom", "Gold Winner", "Gemini", "Sundrop", "Dhara", "Idhayam",
            "Aashirvaad", "India Gate", "Daawat", "Kohinoor", "Fortune Rozana", "Pillsbury",
            "Amul", "Nandini", "Heritage", "Mother Dairy", "Milky Mist", "Aavin", "Govind",
            "Tata Sampann", "Tata Salt", "Tata Tea", "Tata", "Trust", "Madhur", "Parry's", "24 Mantra",
            "Surf Excel", "Ariel", "Tide", "Rin", "Henko", "Vim", "Pril",
            "Colgate", "Pepsodent", "Sensodyne", "Close Up", "Dabur Red", "Vicco",
            "Dettol", "Lifebuoy", "Dove", "Lux", "Pears", "Cinthol", "Hamam", "Medimix",
            "Head & Shoulders", "Pantene", "Sunsilk", "Dove Hair", "Clinic Plus", "Tresemme",
            "Red Label", "Taj Mahal", "Bru", "Nescafe", "Sunrise",
            "Parle-G", "Parle", "Britannia", "Sunfeast", "Oreo", "Good Day", "Marie Gold",
            "Coca Cola", "Coke", "Pepsi", "Thums Up", "Sprite", "Fanta", "Limca", "Frooti", "Maaza"
    );

    private static final Map<String, String> KNOWN_VARIANTS = new LinkedHashMap<>();
    static {
        // Oil variants
        KNOWN_VARIANTS.put("sunflower", "Sunflower");
        KNOWN_VARIANTS.put("sun flower", "Sunflower");
        KNOWN_VARIANTS.put("groundnut", "Groundnut");
        KNOWN_VARIANTS.put("ground nut", "Groundnut");
        KNOWN_VARIANTS.put("peanut", "Groundnut");
        KNOWN_VARIANTS.put("rice bran", "Rice Bran");
        KNOWN_VARIANTS.put("ricebran", "Rice Bran");
        KNOWN_VARIANTS.put("coconut", "Coconut");
        KNOWN_VARIANTS.put("sesame", "Sesame");
        KNOWN_VARIANTS.put("gingelly", "Gingelly");
        KNOWN_VARIANTS.put("mustard", "Mustard");
        KNOWN_VARIANTS.put("olive", "Olive");
        KNOWN_VARIANTS.put("palmolein", "Palmolein");
        KNOWN_VARIANTS.put("cold pressed", "Cold Pressed");

        // Rice variants
        KNOWN_VARIANTS.put("basmati", "Basmati");
        KNOWN_VARIANTS.put("sona masoori", "Sona Masoori");
        KNOWN_VARIANTS.put("sonamasoori", "Sona Masoori");
        KNOWN_VARIANTS.put("ponni", "Ponni");
        KNOWN_VARIANTS.put("idli rice", "Idli Rice");
        KNOWN_VARIANTS.put("brown rice", "Brown Rice");
        KNOWN_VARIANTS.put("jeera samba", "Jeera Samba");
        KNOWN_VARIANTS.put("raw rice", "Raw Rice");
        KNOWN_VARIANTS.put("boiled rice", "Boiled Rice");

        // Detergent & Cleaning variants
        KNOWN_VARIANTS.put("matic top load", "Matic Top Load");
        KNOWN_VARIANTS.put("matic front load", "Matic Front Load");
        KNOWN_VARIANTS.put("top load", "Matic Top Load");
        KNOWN_VARIANTS.put("front load", "Matic Front Load");
        KNOWN_VARIANTS.put("easy wash", "Easy Wash");
        KNOWN_VARIANTS.put("quick wash", "Quick Wash");

        // Milk variants
        KNOWN_VARIANTS.put("toned", "Toned");
        KNOWN_VARIANTS.put("full cream", "Full Cream");
        KNOWN_VARIANTS.put("cow milk", "Cow Milk");
        KNOWN_VARIANTS.put("double toned", "Double Toned");

        // Beverage variants
        KNOWN_VARIANTS.put("zero sugar", "Zero Sugar");
        KNOWN_VARIANTS.put("diet", "Diet");

        // Dal variants
        KNOWN_VARIANTS.put("toor dal", "Toor Dal");
        KNOWN_VARIANTS.put("moong dal", "Moong Dal");
        KNOWN_VARIANTS.put("urad dal", "Urad Dal");
        KNOWN_VARIANTS.put("chana dal", "Chana Dal");
        KNOWN_VARIANTS.put("masoor dal", "Masoor Dal");
    }

    private static final Map<String, String> GENERIC_NAMES = new LinkedHashMap<>();
    static {
        GENERIC_NAMES.put("sunflower", "Sunflower Oil");
        GENERIC_NAMES.put("groundnut", "Groundnut Oil");
        GENERIC_NAMES.put("mustard", "Mustard Oil");
        GENERIC_NAMES.put("coconut", "Coconut Oil");
        GENERIC_NAMES.put("sesame", "Sesame Oil");
        GENERIC_NAMES.put("gingelly", "Gingelly Oil");
        GENERIC_NAMES.put("oil", "Cooking Oil");
        GENERIC_NAMES.put("basmati", "Basmati Rice");
        GENERIC_NAMES.put("sona masoori", "Sona Masoori Rice");
        GENERIC_NAMES.put("rice", "Rice");
        GENERIC_NAMES.put("toned", "Toned Milk");
        GENERIC_NAMES.put("full cream", "Full Cream Milk");
        GENERIC_NAMES.put("milk", "Milk");
        GENERIC_NAMES.put("atta", "Whole Wheat Atta");
        GENERIC_NAMES.put("sugar", "White Sugar");
        GENERIC_NAMES.put("toor dal", "Toor Dal");
        GENERIC_NAMES.put("dal", "Pulses & Dal");
        GENERIC_NAMES.put("detergent", "Detergent Powder");
        GENERIC_NAMES.put("soap", "Bathing Soap");
        GENERIC_NAMES.put("toothpaste", "Toothpaste");
    }

    public ProductIntent extractIntent(String rawInput, String barcodeParam, String brandParam, String unitParam) {
        String input = rawInput != null ? rawInput.trim() : "";
        Map<String, Double> fieldConfidences = new LinkedHashMap<>();

        // 1. Check Barcode / GTIN
        String barcode = barcodeParam != null && !barcodeParam.isBlank() ? barcodeParam.trim() : null;
        if (barcode == null && BARCODE_PATTERN.matcher(input).matches()) {
            barcode = input;
            fieldConfidences.put("barcode", 1.0);
        } else if (barcode != null) {
            fieldConfidences.put("barcode", 0.99);
        }

        // 2. Separate Requested User Quantity vs Product Pack Size
        BigDecimal requiredQuantity = BigDecimal.ONE;
        String userUnit = unitParam != null ? normalizer.normalizeUnit(unitParam) : "pack";
        String productString = input;

        // Try matching "- 2 bottles", "quantity 3", "x 4"
        Matcher dashMatcher = EXPLICIT_QTY_DASH_PATTERN.matcher(productString);
        if (dashMatcher.find()) {
            try {
                requiredQuantity = new BigDecimal(dashMatcher.group(1).trim());
                userUnit = normalizer.normalizeUnit(dashMatcher.group(2));
                fieldConfidences.put("quantity", 0.98);
                fieldConfidences.put("unit", 0.95);
                // Remove quantity substring from product string
                productString = productString.substring(0, dashMatcher.start()).trim();
            } catch (Exception ignored) {}
        } else {
            Matcher wordMatcher = EXPLICIT_QTY_WORD_PATTERN.matcher(productString);
            if (wordMatcher.find()) {
                try {
                    requiredQuantity = new BigDecimal(wordMatcher.group(1).trim());
                    if (wordMatcher.group(2) != null) {
                        userUnit = normalizer.normalizeUnit(wordMatcher.group(2));
                    }
                    fieldConfidences.put("quantity", 0.95);
                    fieldConfidences.put("unit", 0.90);
                    productString = productString.substring(0, wordMatcher.start()).trim();
                } catch (Exception ignored) {}
            } else {
                Matcher mulMatcher = MULTIPLIER_PATTERN.matcher(productString);
                if (mulMatcher.find()) {
                    try {
                        requiredQuantity = new BigDecimal(mulMatcher.group(1).trim());
                        if (mulMatcher.group(2) != null) {
                            userUnit = normalizer.normalizeUnit(mulMatcher.group(2));
                        }
                        fieldConfidences.put("quantity", 0.92);
                        fieldConfidences.put("unit", 0.85);
                        productString = productString.substring(0, mulMatcher.start()).trim();
                    } catch (Exception ignored) {}
                }
            }
        }

        // Normalize regional words in product string
        String normalizedQuery = normalizer.normalizeRegionalText(productString);
        String lowerProduct = normalizedQuery.toLowerCase();

        // 3. Extract Pack Size (e.g. 1L, 2kg, 500g)
        String packSize = null;
        BigDecimal weight = null;
        BigDecimal volume = null;
        Matcher sizeMatcher = PACK_SIZE_PATTERN.matcher(productString);
        if (sizeMatcher.find()) {
            String rawPack = sizeMatcher.group(0);
            packSize = normalizer.normalizePackSize(rawPack);
            fieldConfidences.put("packSize", 0.96);

            try {
                BigDecimal num = new BigDecimal(sizeMatcher.group(1).trim());
                String u = sizeMatcher.group(2).toLowerCase();
                if (u.startsWith("l")) {
                    volume = num;
                } else if (u.startsWith("ml")) {
                    volume = num.divide(BigDecimal.valueOf(1000), 4, java.math.RoundingMode.HALF_UP);
                } else if (u.startsWith("kg") || u.startsWith("kilo")) {
                    weight = num;
                } else if (u.startsWith("g")) {
                    weight = num.divide(BigDecimal.valueOf(1000), 4, java.math.RoundingMode.HALF_UP);
                }
            } catch (Exception ignored) {}
        }

        // 4. Extract Brand
        String brand = brandParam;
        if (brand == null || brand.isBlank()) {
            for (String b : KNOWN_BRANDS) {
                if (lowerProduct.contains(b.toLowerCase())) {
                    brand = b;
                    fieldConfidences.put("brand", 0.98);
                    break;
                }
            }
        } else {
            fieldConfidences.put("brand", 0.99);
        }

        // 5. Extract Variant
        String variant = null;
        for (Map.Entry<String, String> vEntry : KNOWN_VARIANTS.entrySet()) {
            if (lowerProduct.contains(vEntry.getKey())) {
                variant = vEntry.getValue();
                fieldConfidences.put("variant", 0.95);
                break;
            }
        }

        // 6. Detect Category & Sub-category
        String category = detectCategory(lowerProduct);
        String subCategory = variant != null ? variant : category;
        fieldConfidences.put("category", 0.90);

        // 7. Extract Generic Name
        String genericName = null;
        for (Map.Entry<String, String> gEntry : GENERIC_NAMES.entrySet()) {
            if (lowerProduct.contains(gEntry.getKey())) {
                genericName = gEntry.getValue();
                fieldConfidences.put("genericName", 0.92);
                break;
            }
        }
        if (genericName == null) {
            genericName = category;
        }

        // 8. Construct Normalized Product Name and Exact Product Name
        String productName = buildNormalizedProductName(brand, variant, genericName, packSize, productString);
        String exactProductName = buildExactProductName(brand, variant, genericName, packSize);

        // 9. Classify Search Intent
        SearchIntent searchIntent = classifier.classify(
                productString, brand, variant, packSize, barcode, category
        );

        // 10. Calculate Overall Confidence
        double overallConfidence = computeOverallConfidence(brand, variant, packSize, barcode, searchIntent);

        return ProductIntent.builder()
                .rawInput(input)
                .productName(productName)
                .genericName(genericName)
                .exactProductName(exactProductName)
                .brand(brand)
                .variant(variant)
                .model(null)
                .quantity(requiredQuantity)
                .unit(userUnit)
                .packSize(packSize)
                .weight(weight)
                .volume(volume)
                .flavor(null)
                .size(packSize)
                .color(null)
                .category(category)
                .subCategory(subCategory)
                .barcode(barcode)
                .searchIntent(searchIntent)
                .confidence(overallConfidence)
                .fieldConfidences(fieldConfidences)
                .build();
    }

    private String detectCategory(String lower) {
        if (lower.contains("oil") || lower.contains("ennai")) return "Cooking Oil";
        if (lower.contains("rice") || lower.contains("arisi") || lower.contains("basmati")) return "Rice & Grains";
        if (lower.contains("milk") || lower.contains("paal") || lower.contains("curd") || lower.contains("dairy")) return "Dairy & Milk";
        if (lower.contains("atta") || lower.contains("flour") || lower.contains("wheat") || lower.contains("maida")) return "Atta & Flours";
        if (lower.contains("dal") || lower.contains("paruppu") || lower.contains("pulses")) return "Dals & Pulses";
        if (lower.contains("sugar") || lower.contains("sakkarai") || lower.contains("jaggery")) return "Sugar & Sweeteners";
        if (lower.contains("detergent") || lower.contains("wash") || lower.contains("surf") || lower.contains("cleaner")) return "Cleaning & Detergents";
        if (lower.contains("soap") || lower.contains("toothpaste") || lower.contains("shampoo")) return "Personal Care";
        if (lower.contains("tea") || lower.contains("coffee")) return "Tea & Coffee";
        return "Groceries";
    }

    private String buildNormalizedProductName(String brand, String variant, String genericName, String packSize, String raw) {
        if (brand != null && variant != null && packSize != null) {
            return brand + " " + variant + " " + (genericName != null ? genericName : "") + " " + packSize;
        }
        if (brand != null && packSize != null) {
            return brand + " " + (genericName != null ? genericName : "") + " " + packSize;
        }
        return raw;
    }

    private String buildExactProductName(String brand, String variant, String genericName, String packSize) {
        StringBuilder sb = new StringBuilder();
        if (brand != null) sb.append(brand).append(" ");
        if (variant != null && !variant.equalsIgnoreCase(brand)) sb.append(variant).append(" ");
        if (genericName != null && !genericName.toLowerCase().contains(variant != null ? variant.toLowerCase() : "---")) {
            sb.append(genericName).append(" ");
        }
        if (packSize != null) sb.append(packSize);
        return sb.toString().replaceAll("\\s+", " ").trim();
    }

    private double computeOverallConfidence(String brand, String variant, String packSize, String barcode, SearchIntent intent) {
        if (barcode != null) return 1.0;
        if (intent == SearchIntent.EXACT_PRODUCT) {
            double c = 0.85;
            if (brand != null) c += 0.08;
            if (packSize != null) c += 0.05;
            return Math.min(0.99, c);
        }
        if (intent == SearchIntent.BRANDED_PRODUCT) return 0.90;
        if (intent == SearchIntent.GENERIC_PRODUCT) return 0.88;
        if (intent == SearchIntent.SPECIFIC_VARIANT) return 0.85;
        return 0.40; // INSUFFICIENT_INFORMATION
    }
}
