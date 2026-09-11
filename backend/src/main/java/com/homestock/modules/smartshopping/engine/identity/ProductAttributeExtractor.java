package com.homestock.modules.smartshopping.engine.identity;

import lombok.Builder;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Product Attribute Extractor:
 * Extracts 20+ structured product attributes from user input or candidate titles:
 * - Brand (with BrandResolver & typo tolerance)
 * - Exact Product Name / Generic Name
 * - Variant (sunflower, basmati, toned, top load, etc.)
 * - Pack size vs Requested Quantity separation (e.g. "1L 2 bottles" -> packSize 1L, qty 2)
 * - Base Unit Normalization (1000 ML, 5000 G, PCS)
 * - Regional / Tamil / Tanglish colloquial mapping
 * - Category and Sub-category determination
 */
@Component
@RequiredArgsConstructor
public class ProductAttributeExtractor {

    private final BrandResolver brandResolver;
    private final ProductTaxonomy productTaxonomy;

    // Pattern for pack size: e.g. "1L", "500ml", "2 kg", "5kg", "800g", "4 x 100g", "pack of 4"
    private static final Pattern PACK_SIZE_MULTIPACK_PATTERN = Pattern.compile(
            "(?i)\\b(\\d+)\\s*[xX*]\\s*(\\d+(?:\\.\\d+)?)\\s*(l(?:itre|iters?|iter)?|ml|kg|kilos?|g(?:m|rams?)?)\\b"
    );

    private static final Pattern PACK_OF_N_PATTERN = Pattern.compile(
            "(?i)\\bpack\\s+of\\s+(\\d+)\\b"
    );

    private static final Pattern PACK_SIZE_STANDARD_PATTERN = Pattern.compile(
            "(?i)\\b(\\d+(?:\\.\\d+)?)\\s*(l(?:itre|iters?|iter)?|ml|kg|kilos?|g(?:m|rams?)?|pcs?|pieces?)\\b"
    );

    // Quantity patterns: e.g. "2 bottles", "x 3", "qty: 2", "- 2 packs", "3 cans", "2 pouches", "1 piece"
    private static final Pattern QTY_PREFIX_PATTERN = Pattern.compile(
            "(?i)(?:^|\\s)(?:qty|quantity|need|count)[\\s:=]+(\\d+)(?:\\s*(bottles?|packs?|packets?|cans?|pouches?|bags?|boxes?|pieces?|pcs?|units?))?\\b"
    );

    private static final Pattern QTY_MULTIPLIER_SUFFIX_PATTERN = Pattern.compile(
            "(?i)\\b[xX*]\\s*(\\d+)(?:\\s*(bottles?|packs?|packets?|cans?|pouches?|bags?|pieces?|pcs?|units?))?\\b"
    );

    private static final Pattern QTY_COUNT_UNIT_PATTERN = Pattern.compile(
            "(?i)(?:^|[\\s,-]+)(\\d+)\\s+(bottles?|packs?|packets?|cans?|pouches?|bags?|boxes?|pieces?|pcs?|units?)\\b"
    );

    // Regional / Tanglish translations
    private static final Map<String, String> REGIONAL_TERMS = new LinkedHashMap<>();
    static {
        REGIONAL_TERMS.put("samayal ennai", "Cooking Oil");
        REGIONAL_TERMS.put("samayal", "Cooking");
        REGIONAL_TERMS.put("kadalai ennai", "Groundnut Oil");
        REGIONAL_TERMS.put("nallennai", "Sesame Oil");
        REGIONAL_TERMS.put("thengai ennai", "Coconut Oil");
        REGIONAL_TERMS.put("kadugu ennai", "Mustard Oil");
        REGIONAL_TERMS.put("ennai", "Cooking Oil");

        REGIONAL_TERMS.put("seeraga samba arisi", "Seeraga Samba Rice");
        REGIONAL_TERMS.put("seeraga samba", "Seeraga Samba Rice");
        REGIONAL_TERMS.put("ponni arisi", "Ponni Rice");
        REGIONAL_TERMS.put("idli arisi", "Idli Rice");
        REGIONAL_TERMS.put("pacharisi", "Raw Rice");
        REGIONAL_TERMS.put("puzhungal arisi", "Boiled Rice");
        REGIONAL_TERMS.put("arisi", "Rice");

        REGIONAL_TERMS.put("thuvaram paruppu", "Toor Dal");
        REGIONAL_TERMS.put("paasi paruppu", "Moong Dal");
        REGIONAL_TERMS.put("ulunthu", "Urad Dal");
        REGIONAL_TERMS.put("kadalai paruppu", "Chana Dal");
        REGIONAL_TERMS.put("paruppu", "Dal");

        REGIONAL_TERMS.put("nattu sakkarai", "Brown Sugar");
        REGIONAL_TERMS.put("vellam", "Jaggery");
        REGIONAL_TERMS.put("sakkarai", "Sugar");

        REGIONAL_TERMS.put("thool uppu", "Table Salt");
        REGIONAL_TERMS.put("kal uppu", "Rock Salt");
        REGIONAL_TERMS.put("uppu", "Salt");

        REGIONAL_TERMS.put("milagai thool", "Chilli Powder");
        REGIONAL_TERMS.put("manjal thool", "Turmeric Powder");
        REGIONAL_TERMS.put("malli thool", "Coriander Powder");
        REGIONAL_TERMS.put("jeeragam", "Cumin");
        REGIONAL_TERMS.put("milagu", "Black Pepper");
        REGIONAL_TERMS.put("milagai", "Chilli");

        REGIONAL_TERMS.put("tea thool", "Tea Powder");
        REGIONAL_TERMS.put("kaapi thool", "Coffee Powder");
        REGIONAL_TERMS.put("kaapi", "Coffee");
        REGIONAL_TERMS.put("paal", "Milk");

        REGIONAL_TERMS.put("thuni soap", "Laundry Detergent");
        REGIONAL_TERMS.put("sabun", "Soap");
    }

    // Common Variants
    private static final Map<String, String> COMMON_VARIANTS = new LinkedHashMap<>();
    static {
        // Oil
        COMMON_VARIANTS.put("sunflower", "Sunflower");
        COMMON_VARIANTS.put("groundnut", "Groundnut");
        COMMON_VARIANTS.put("peanut", "Groundnut");
        COMMON_VARIANTS.put("mustard", "Mustard");
        COMMON_VARIANTS.put("sesame", "Sesame");
        COMMON_VARIANTS.put("gingelly", "Gingelly");
        COMMON_VARIANTS.put("coconut", "Coconut");
        COMMON_VARIANTS.put("rice bran", "Rice Bran");
        COMMON_VARIANTS.put("ricebran", "Rice Bran");
        COMMON_VARIANTS.put("olive", "Olive");
        COMMON_VARIANTS.put("cold pressed", "Cold Pressed");

        // Rice
        COMMON_VARIANTS.put("basmati", "Basmati");
        COMMON_VARIANTS.put("sona masoori", "Sona Masoori");
        COMMON_VARIANTS.put("sonamasoori", "Sona Masoori");
        COMMON_VARIANTS.put("ponni", "Ponni");
        COMMON_VARIANTS.put("idli rice", "Idli Rice");
        COMMON_VARIANTS.put("brown rice", "Brown Rice");
        COMMON_VARIANTS.put("seeraga samba", "Seeraga Samba");
        COMMON_VARIANTS.put("raw rice", "Raw Rice");
        COMMON_VARIANTS.put("boiled rice", "Boiled Rice");

        // Detergent
        COMMON_VARIANTS.put("top load matic", "Matic Top Load");
        COMMON_VARIANTS.put("front load matic", "Matic Front Load");
        COMMON_VARIANTS.put("matic top load", "Matic Top Load");
        COMMON_VARIANTS.put("matic front load", "Matic Front Load");
        COMMON_VARIANTS.put("top load", "Matic Top Load");
        COMMON_VARIANTS.put("front load", "Matic Front Load");
        COMMON_VARIANTS.put("liquid", "Liquid");
        COMMON_VARIANTS.put("powder", "Powder");
        COMMON_VARIANTS.put("bar", "Bar");

        // Milk
        COMMON_VARIANTS.put("toned", "Toned");
        COMMON_VARIANTS.put("double toned", "Double Toned");
        COMMON_VARIANTS.put("full cream", "Full Cream");
        COMMON_VARIANTS.put("cow milk", "Cow Milk");
        COMMON_VARIANTS.put("skimmed", "Skimmed");

        // Dal
        COMMON_VARIANTS.put("toor dal", "Toor Dal");
        COMMON_VARIANTS.put("moong dal", "Moong Dal");
        COMMON_VARIANTS.put("urad dal", "Urad Dal");
        COMMON_VARIANTS.put("chana dal", "Chana Dal");
        COMMON_VARIANTS.put("masoor dal", "Masoor Dal");

        // Sugar & Flour
        COMMON_VARIANTS.put("multigrain", "Multigrain");
        COMMON_VARIANTS.put("whole wheat", "Whole Wheat");
        COMMON_VARIANTS.put("brown sugar", "Brown Sugar");
        COMMON_VARIANTS.put("jaggery", "Jaggery");

        // Beverages
        COMMON_VARIANTS.put("zero sugar", "Zero Sugar");
        COMMON_VARIANTS.put("diet", "Diet");
    }

    @Data
    @Builder
    public static class ExtractedAttributes {
        private String rawText;
        private String translatedText;
        private String brand;
        private String productName;
        private String genericName;
        private String variant;
        private String packSize;
        private String packUnit;
        private Double normalizedPackSizeValue;
        private String normalizedPackSizeUnit;
        private Integer requestedQuantity;
        private String requestedQuantityUnit;
        private String category;
        private String subCategory;
        private String barcode;
        private double extractionConfidence;
    }

    /**
     * Extracts structured attributes from query text or candidate title.
     */
    public ExtractedAttributes extract(String text, String barcode) {
        if (text == null) text = "";
        String raw = text.trim();

        // 1. Regional / Tanglish translation
        String translated = translateRegionalTerms(raw);

        // 2. Extract Requested Quantity vs Pack Size
        QuantityResult qtyResult = extractQuantityAndCleanText(translated);
        String cleanedForPack = qtyResult.cleanedText;
        Integer requestedQty = qtyResult.quantity != null ? qtyResult.quantity : 1;
        String requestedQtyUnit = qtyResult.quantityUnit != null ? qtyResult.quantityUnit : "unit";

        // 3. Extract Pack Size
        PackSizeResult packResult = extractPackSize(cleanedForPack);

        // 4. Extract Brand using BrandResolver
        String textForBrand = packResult.cleanedText;
        BrandResolver.BrandMatch brandMatch = brandResolver.findBrand(textForBrand);
        String brand = brandMatch != null ? brandMatch.canonicalBrand() : null;

        // If brand was found, strip it out to isolate product name/variant
        String textForVariant = textForBrand;
        if (brandMatch != null) {
            textForVariant = textForVariant.replaceAll("(?i)\\b" + Pattern.quote(brandMatch.matchedToken()) + "\\b", " ").trim();
        }

        // 5. Extract Variant
        VariantResult variantResult = extractVariant(textForVariant);
        String variant = variantResult.variant;
        String textForProd = variantResult.cleanedText;

        // 6. Generic & Product Name Resolution
        String genericName = resolveGenericName(translated, variant);
        String productName = cleanProductName(textForProd, brand, variant, genericName);

        // 7. Category & Subcategory resolution
        ProductTaxonomy.TaxonomyResult tax = productTaxonomy.classify(productName + " " + (variant != null ? variant : "") + " " + (genericName != null ? genericName : ""));

        // 8. Confidence calculation
        double confidence = calculateConfidence(brand, productName, variant, packResult.packSize, barcode);

        return ExtractedAttributes.builder()
                .rawText(raw)
                .translatedText(translated)
                .brand(brand)
                .productName(productName)
                .genericName(genericName)
                .variant(variant)
                .packSize(packResult.packSize)
                .packUnit(packResult.packUnit)
                .normalizedPackSizeValue(packResult.normalizedValue)
                .normalizedPackSizeUnit(packResult.normalizedUnit)
                .requestedQuantity(requestedQty)
                .requestedQuantityUnit(requestedQtyUnit)
                .category(tax.category())
                .subCategory(tax.subCategory())
                .barcode(barcode != null && !barcode.isBlank() ? barcode.trim() : null)
                .extractionConfidence(confidence)
                .build();
    }

    private String translateRegionalTerms(String text) {
        String res = " " + text + " ";
        for (Map.Entry<String, String> entry : REGIONAL_TERMS.entrySet()) {
            Pattern p = Pattern.compile("(?i)(?<=\\s)" + Pattern.quote(entry.getKey()) + "(?=\\s)");
            res = p.matcher(res).replaceAll(" " + Matcher.quoteReplacement(entry.getValue()) + " ");
        }
        return res.trim().replaceAll("\\s+", " ");
    }

    private static class QuantityResult {
        Integer quantity;
        String quantityUnit;
        String cleanedText;
    }

    private QuantityResult extractQuantityAndCleanText(String text) {
        QuantityResult result = new QuantityResult();
        result.cleanedText = text;

        // Try QTY prefix: "qty: 2 bottles", "quantity 3"
        Matcher m1 = QTY_PREFIX_PATTERN.matcher(result.cleanedText);
        if (m1.find()) {
            result.quantity = Integer.parseInt(m1.group(1));
            result.quantityUnit = m1.group(2) != null ? m1.group(2).toLowerCase() : "unit";
            result.cleanedText = m1.replaceFirst(" ").trim();
            return result;
        }

        // Try Multiplier suffix: "1L x 3", "500g * 2"
        Matcher m2 = QTY_MULTIPLIER_SUFFIX_PATTERN.matcher(result.cleanedText);
        if (m2.find()) {
            result.quantity = Integer.parseInt(m2.group(1));
            result.quantityUnit = m2.group(2) != null ? m2.group(2).toLowerCase() : "pack";
            result.cleanedText = m2.replaceFirst(" ").trim();
            return result;
        }

        // Try Count Unit pattern: "1L 2 bottles", "500g - 2 packs", "3 pieces"
        // Ensure we don't accidentally swallow pack size like "1 bottle" if it's the only size
        Matcher m3 = QTY_COUNT_UNIT_PATTERN.matcher(result.cleanedText);
        if (m3.find()) {
            // Check if there is also another pack size indicator (like 1L or 500g)
            boolean hasPackSizeElsewhere = PACK_SIZE_STANDARD_PATTERN.matcher(result.cleanedText).find();
            if (hasPackSizeElsewhere || m3.group(2).matches("(?i)bottles?|packs?|cans?|pouches?|pieces?|pcs?")) {
                result.quantity = Integer.parseInt(m3.group(1));
                result.quantityUnit = normalizeQuantityUnit(m3.group(2));
                result.cleanedText = result.cleanedText.substring(0, m3.start()) + " " + result.cleanedText.substring(m3.end());
                result.cleanedText = result.cleanedText.trim().replaceAll("\\s+", " ");
            }
        }

        return result;
    }

    private String normalizeQuantityUnit(String rawUnit) {
        if (rawUnit == null) return "unit";
        String u = rawUnit.toLowerCase().trim();
        if (u.startsWith("bottle")) return "bottle";
        if (u.startsWith("pack") || u.startsWith("packet")) return "pack";
        if (u.startsWith("can")) return "can";
        if (u.startsWith("pouch")) return "pouch";
        if (u.startsWith("bag")) return "bag";
        if (u.startsWith("box")) return "box";
        if (u.startsWith("piece") || u.startsWith("pc")) return "piece";
        if (u.startsWith("item")) return "item";
        return u;
    }

    private static class PackSizeResult {
        String packSize;
        String packUnit;
        Double normalizedValue;
        String normalizedUnit;
        String cleanedText;
    }

    private PackSizeResult extractPackSize(String text) {
        PackSizeResult res = new PackSizeResult();
        res.cleanedText = text;

        // 1. Check Multi-pack: "4 x 100g", "2 x 1L"
        Matcher multiMatcher = PACK_SIZE_MULTIPACK_PATTERN.matcher(text);
        if (multiMatcher.find()) {
            int count = Integer.parseInt(multiMatcher.group(1));
            double subVal = Double.parseDouble(multiMatcher.group(2));
            String unit = multiMatcher.group(3).toLowerCase();

            double total = count * subVal;
            NormalizedUnit norm = normalizeUnit(total, unit);

            res.packSize = multiMatcher.group(0);
            res.packUnit = unit;
            res.normalizedValue = norm.value;
            res.normalizedUnit = norm.unit;
            res.cleanedText = multiMatcher.replaceFirst(" ").trim();
            return res;
        }

        // 2. Check "Pack of N"
        Matcher packOfNMatcher = PACK_OF_N_PATTERN.matcher(text);
        if (packOfNMatcher.find()) {
            int count = Integer.parseInt(packOfNMatcher.group(1));
            res.packSize = packOfNMatcher.group(0);
            res.packUnit = "pcs";
            res.normalizedValue = (double) count;
            res.normalizedUnit = "PCS";
            res.cleanedText = packOfNMatcher.replaceFirst(" ").trim();
            return res;
        }

        // 3. Standard Pack Size: "1L", "500ml", "5kg", "200g"
        Matcher stdMatcher = PACK_SIZE_STANDARD_PATTERN.matcher(text);
        if (stdMatcher.find()) {
            double val = Double.parseDouble(stdMatcher.group(1));
            String unit = stdMatcher.group(2).toLowerCase();

            NormalizedUnit norm = normalizeUnit(val, unit);
            res.packSize = stdMatcher.group(0).replaceAll("\\s+", "");
            res.packUnit = unit;
            res.normalizedValue = norm.value;
            res.normalizedUnit = norm.unit;
            res.cleanedText = stdMatcher.replaceFirst(" ").trim();
            return res;
        }

        return res;
    }

    private static class NormalizedUnit {
        Double value;
        String unit;
        NormalizedUnit(Double value, String unit) {
            this.value = value;
            this.unit = unit;
        }
    }

    private NormalizedUnit normalizeUnit(double val, String unit) {
        String u = unit.toLowerCase();
        if (u.startsWith("kg") || u.startsWith("kilo")) {
            return new NormalizedUnit(val * 1000.0, "G");
        } else if (u.startsWith("g")) {
            return new NormalizedUnit(val, "G");
        } else if (u.startsWith("l") && !u.startsWith("pc")) {
            return new NormalizedUnit(val * 1000.0, "ML");
        } else if (u.startsWith("ml")) {
            return new NormalizedUnit(val, "ML");
        } else if (u.startsWith("pc") || u.startsWith("piece")) {
            return new NormalizedUnit(val, "PCS");
        }
        return new NormalizedUnit(val, unit.toUpperCase());
    }

    private static class VariantResult {
        String variant;
        String cleanedText;
    }

    private VariantResult extractVariant(String text) {
        VariantResult res = new VariantResult();
        res.cleanedText = text;
        String lower = text.toLowerCase();

        for (Map.Entry<String, String> entry : COMMON_VARIANTS.entrySet()) {
            String key = entry.getKey();
            Pattern p = Pattern.compile("(?i)\\b" + Pattern.quote(key) + "\\b");
            Matcher m = p.matcher(res.cleanedText);
            if (m.find()) {
                res.variant = entry.getValue();
                res.cleanedText = m.replaceFirst(" ").trim().replaceAll("\\s+", " ");
                break;
            }
        }

        return res;
    }

    private String resolveGenericName(String text, String variant) {
        String lower = text.toLowerCase();
        if (lower.contains("oil") || (variant != null && variant.matches("(?i)Sunflower|Groundnut|Mustard|Sesame|Gingelly|Coconut|Olive|Rice Bran"))) {
            return variant != null ? variant + " Oil" : "Cooking Oil";
        }
        if (lower.contains("rice") || (variant != null && variant.matches("(?i)Basmati|Sona Masoori|Ponni|Idli Rice|Brown Rice|Seeraga Samba"))) {
            return variant != null ? variant + " Rice" : "Rice";
        }
        if (lower.contains("atta") || lower.contains("flour")) {
            return "Atta";
        }
        if (lower.contains("sugar") || lower.contains("jaggery")) {
            return "Sugar";
        }
        if (lower.contains("salt")) {
            return "Salt";
        }
        if (lower.contains("detergent") || lower.contains("surf excel") || lower.contains("ariel") || lower.contains("tide")) {
            return "Detergent";
        }
        if (lower.contains("soap") || lower.contains("dettol") || lower.contains("lifebuoy") || lower.contains("dove")) {
            return "Bathing Soap";
        }
        if (lower.contains("milk") || (variant != null && variant.matches("(?i)Toned|Double Toned|Full Cream|Cow Milk"))) {
            return "Milk";
        }
        if (lower.contains("dal") || (variant != null && variant.endsWith("Dal"))) {
            return variant != null ? variant : "Pulses";
        }
        return null;
    }

    private String cleanProductName(String text, String brand, String variant, String genericName) {
        String cleaned = text.replaceAll("[^a-zA-Z0-9\\s]", " ").replaceAll("\\s+", " ").trim();
        if (cleaned.isBlank() && genericName != null) {
            return genericName;
        }
        if (cleaned.isBlank() && brand != null) {
            return brand + (variant != null ? " " + variant : "");
        }
        return cleaned.isBlank() ? "Product" : capitalizeWords(cleaned);
    }

    private double calculateConfidence(String brand, String product, String variant, String packSize, String barcode) {
        if (barcode != null && !barcode.isBlank()) {
            return 1.0;
        }
        int points = 0;
        if (brand != null) points += 35;
        if (product != null && !product.equals("Product")) points += 25;
        if (variant != null) points += 20;
        if (packSize != null) points += 20;

        return Math.min(1.0, points / 100.0);
    }

    private String capitalizeWords(String str) {
        String[] words = str.split("\\s+");
        StringBuilder sb = new StringBuilder();
        for (String w : words) {
            if (w.isEmpty()) continue;
            if (sb.length() > 0) sb.append(" ");
            sb.append(Character.toUpperCase(w.charAt(0)));
            if (w.length() > 1) {
                sb.append(w.substring(1).toLowerCase());
            }
        }
        return sb.toString();
    }
}
