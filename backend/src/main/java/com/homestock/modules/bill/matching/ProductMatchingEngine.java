package com.homestock.modules.bill.matching;

import com.homestock.modules.bill.parser.ParsedBillItem;
import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.inventory.repository.InventoryItemRepository;
import com.homestock.modules.product.entity.Product;
import com.homestock.modules.product.repository.ProductRepository;
import com.homestock.modules.shopping.entity.ShoppingListItem;
import com.homestock.modules.shopping.repository.ShoppingListItemRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.*;

@Service("billProductMatchingEngine")
public class ProductMatchingEngine {

    private static final Logger log = LoggerFactory.getLogger(ProductMatchingEngine.class);

    private final InventoryItemRepository inventoryItemRepository;
    private final ProductRepository productRepository;
    private final ShoppingListItemRepository shoppingListItemRepository;
    private final ProductNormalizationService normalizationService;

    public ProductMatchingEngine(
            InventoryItemRepository inventoryItemRepository,
            ProductRepository productRepository,
            ShoppingListItemRepository shoppingListItemRepository,
            ProductNormalizationService normalizationService
    ) {
        this.inventoryItemRepository = inventoryItemRepository;
        this.productRepository = productRepository;
        this.shoppingListItemRepository = shoppingListItemRepository;
        this.normalizationService = normalizationService;
    }

    public ProductMatchResult matchItem(UUID homeId, ParsedBillItem scannedItem) {
        ProductNormalizationService.NormalizedProductInfo norm = normalizationService.normalize(scannedItem.getName());
        String normName = norm.normalizedName();
        String brand = norm.detectedBrand();
        String unit = norm.unit();
        BigDecimal qty = scannedItem.getQuantity() != null && scannedItem.getQuantity().compareTo(BigDecimal.ZERO) > 0 ? scannedItem.getQuantity() : BigDecimal.ONE;
        BigDecimal finalPrice = scannedItem.getFinalPrice() != null ? scannedItem.getFinalPrice() : BigDecimal.ZERO;
        BigDecimal unitPrice = scannedItem.getUnitPrice() != null ? scannedItem.getUnitPrice()
                : (finalPrice.compareTo(BigDecimal.ZERO) > 0 ? finalPrice.divide(qty, 2, RoundingMode.HALF_UP) : BigDecimal.ZERO);

        // Calculate standard unit price (per 1 KG or per 1 L or per 1 PCS)
        BigDecimal standardUnitPrice = calculateStandardPrice(finalPrice, qty, unit);

        // 1. Check Barcode Match (if barcode present)
        if (scannedItem.getBarcode() != null && !scannedItem.getBarcode().isEmpty()) {
            Optional<InventoryItem> barcodeItem = inventoryItemRepository.findByHomeIdAndBarcode(homeId, scannedItem.getBarcode());
            if (barcodeItem.isPresent()) {
                return buildResult(scannedItem, barcodeItem.get(), barcodeItem.get().getProduct(), BigDecimal.valueOf(100.0), "AUTO_MATCHED", standardUnitPrice);
            }
            Optional<Product> barcodeProduct = productRepository.findByBarcode(scannedItem.getBarcode());
            if (barcodeProduct.isPresent()) {
                return buildResult(scannedItem, null, barcodeProduct.get(), BigDecimal.valueOf(100.0), "AUTO_MATCHED", standardUnitPrice);
            }
        }

        // Fetch home's existing inventory items
        List<InventoryItem> homeItems = inventoryItemRepository.findByHomeId(homeId);

        // 2. Exact Normalized Name Match in Household Inventory
        for (InventoryItem item : homeItems) {
            ProductNormalizationService.NormalizedProductInfo itemNorm = normalizationService.normalize(item.getName());
            if (normName.equalsIgnoreCase(itemNorm.normalizedName())) {
                boolean brandMatch = (brand == null || item.getBrand() == null || brand.equalsIgnoreCase(item.getBrand()));
                BigDecimal confidence = brandMatch ? BigDecimal.valueOf(98.0) : BigDecimal.valueOf(95.0);
                return buildResult(scannedItem, item, item.getProduct(), confidence, "AUTO_MATCHED", standardUnitPrice);
            }
        }

        // 3. Exact Normalized Name Match in Global Product Catalog
        Optional<Product> catalogProduct = productRepository.findByNormalizedName(normName);
        if (catalogProduct.isPresent()) {
            return buildResult(scannedItem, null, catalogProduct.get(), BigDecimal.valueOf(95.0), "AUTO_MATCHED", standardUnitPrice);
        }

        // 4. Fuzzy Similarity across Household Inventory
        InventoryItem bestFuzzyItem = null;
        double bestFuzzyScore = 0.0;

        for (InventoryItem item : homeItems) {
            ProductNormalizationService.NormalizedProductInfo itemNorm = normalizationService.normalize(item.getName());
            double sim = calculateSimilarity(normName, itemNorm.normalizedName(), brand, item.getBrand());
            if (sim > bestFuzzyScore) {
                bestFuzzyScore = sim;
                bestFuzzyItem = item;
            }
        }

        if (bestFuzzyScore >= 0.80 && bestFuzzyItem != null) {
            BigDecimal confidence = BigDecimal.valueOf(Math.min(99.0, bestFuzzyScore * 100.0)).setScale(2, RoundingMode.HALF_UP);
            String status = confidence.compareTo(BigDecimal.valueOf(95.0)) >= 0 ? "AUTO_MATCHED" : "SUGGESTED";
            return buildResult(scannedItem, bestFuzzyItem, bestFuzzyItem.getProduct(), confidence, status, standardUnitPrice);
        }

        // 5. If confidence is below 80%, treat as new product candidate
        BigDecimal confidence = BigDecimal.valueOf(Math.max(20.0, bestFuzzyScore * 100.0)).setScale(2, RoundingMode.HALF_UP);
        return ProductMatchResult.builder()
                .confidence(confidence)
                .matchStatus("NEW_PRODUCT")
                .matchedInventoryItem(null)
                .matchedProduct(null)
                .resolvedName(formatCapitalized(scannedItem.getName()))
                .resolvedBrand(brand)
                .resolvedCategory("Food & Grocery")
                .resolvedUnit(unit)
                .resolvedQuantity(qty)
                .resolvedUnitPrice(unitPrice)
                .resolvedFinalPrice(finalPrice)
                .standardUnitPrice(standardUnitPrice)
                .build();
    }

    public Optional<ShoppingListItem> findMatchingShoppingItem(UUID homeId, String itemName) {
        if (itemName == null || itemName.trim().isEmpty()) return Optional.empty();

        List<ShoppingListItem> pendingItems = shoppingListItemRepository.findPendingItemsByHomeId(homeId);
        ProductNormalizationService.NormalizedProductInfo targetNorm = normalizationService.normalize(itemName);

        ShoppingListItem bestMatch = null;
        double bestScore = 0.0;

        for (ShoppingListItem item : pendingItems) {
            ProductNormalizationService.NormalizedProductInfo itemNorm = normalizationService.normalize(item.getItemName());
            if (targetNorm.normalizedName().equalsIgnoreCase(itemNorm.normalizedName())) {
                return Optional.of(item);
            }
            double score = jaroWinkler(targetNorm.normalizedName(), itemNorm.normalizedName());
            if (score > bestScore && score >= 0.80) {
                bestScore = score;
                bestMatch = item;
            }
        }

        return Optional.ofNullable(bestMatch);
    }

    private double calculateSimilarity(String s1, String s2, String brand1, String brand2) {
        if (s1 == null || s2 == null) return 0.0;
        double textScore = jaroWinkler(s1.toUpperCase(), s2.toUpperCase());

        // Token overlap check
        Set<String> tokens1 = new HashSet<>(Arrays.asList(s1.toUpperCase().split("\\s+")));
        Set<String> tokens2 = new HashSet<>(Arrays.asList(s2.toUpperCase().split("\\s+")));
        Set<String> intersection = new HashSet<>(tokens1);
        intersection.retainAll(tokens2);

        double minTokens = Math.min(tokens1.size(), tokens2.size());
        double tokenScore = (!tokens1.isEmpty() && !tokens2.isEmpty() && minTokens > 0)
                ? (double) intersection.size() / minTokens
                : 0.0;

        double combinedScore = (textScore * 0.4) + (tokenScore * 0.6);

        // Boost if brand matches
        if (brand1 != null && brand2 != null && brand1.equalsIgnoreCase(brand2)) {
            combinedScore = Math.min(1.0, combinedScore + 0.15);
        }

        return combinedScore;
    }

    public static double jaroWinkler(String s1, String s2) {
        if (s1 == null || s2 == null) return 0.0;
        if (s1.equals(s2)) return 1.0;
        if (s1.isEmpty() || s2.isEmpty()) return 0.0;

        int matchDistance = Math.max(s1.length(), s2.length()) / 2 - 1;
        if (matchDistance < 0) matchDistance = 0;

        boolean[] s1Matches = new boolean[s1.length()];
        boolean[] s2Matches = new boolean[s2.length()];

        int matches = 0;
        for (int i = 0; i < s1.length(); i++) {
            int start = Math.max(0, i - matchDistance);
            int end = Math.min(i + matchDistance + 1, s2.length());

            for (int j = start; j < end; j++) {
                if (s2Matches[j]) continue;
                if (s1.charAt(i) != s2.charAt(j)) continue;
                s1Matches[i] = true;
                s2Matches[j] = true;
                matches++;
                break;
            }
        }

        if (matches == 0) return 0.0;

        double transpositions = 0;
        int k = 0;
        for (int i = 0; i < s1.length(); i++) {
            if (!s1Matches[i]) continue;
            while (!s2Matches[k]) {
                k++;
            }
            if (s1.charAt(i) != s2.charAt(k)) {
                transpositions++;
            }
            k++;
        }

        double jaro = ((double) matches / s1.length()
                + (double) matches / s2.length()
                + ((double) matches - transpositions / 2.0) / matches) / 3.0;

        // Winkler prefix bonus
        int prefix = 0;
        int maxPrefix = Math.min(4, Math.min(s1.length(), s2.length()));
        for (int i = 0; i < maxPrefix; i++) {
            if (s1.charAt(i) == s2.charAt(i)) {
                prefix++;
            } else {
                break;
            }
        }

        return jaro + prefix * 0.1 * (1.0 - jaro);
    }

    private BigDecimal calculateStandardPrice(BigDecimal price, BigDecimal quantity, String unit) {
        if (price == null || quantity == null || quantity.compareTo(BigDecimal.ZERO) <= 0) {
            return BigDecimal.ZERO;
        }

        BigDecimal unitPrice = price.divide(quantity, 4, RoundingMode.HALF_UP);
        String u = unit != null ? unit.toLowerCase() : "pcs";

        // Convert G to KG standard price: multiply by 1000
        if ("g".equals(u) || "gm".equals(u) || "grams".equals(u)) {
            return unitPrice.multiply(BigDecimal.valueOf(1000)).setScale(2, RoundingMode.HALF_UP);
        }
        // Convert ML to L standard price: multiply by 1000
        if ("ml".equals(u)) {
            return unitPrice.multiply(BigDecimal.valueOf(1000)).setScale(2, RoundingMode.HALF_UP);
        }

        return unitPrice.setScale(2, RoundingMode.HALF_UP);
    }

    private ProductMatchResult buildResult(
            ParsedBillItem scanned,
            InventoryItem inv,
            Product prod,
            BigDecimal confidence,
            String status,
            BigDecimal standardPrice
    ) {
        String name = inv != null ? inv.getName() : (prod != null ? prod.getName() : formatCapitalized(scanned.getName()));
        String brand = inv != null ? inv.getBrand() : (prod != null ? prod.getBrand() : null);
        String category = inv != null && inv.getCategory() != null ? inv.getCategory().getName() : "Food & Grocery";
        String unit = inv != null ? inv.getUnit() : (prod != null ? prod.getUnit() : scanned.getUnit());

        return ProductMatchResult.builder()
                .confidence(confidence)
                .matchStatus(status)
                .matchedInventoryItem(inv)
                .matchedProduct(prod)
                .resolvedName(name)
                .resolvedBrand(brand)
                .resolvedCategory(category)
                .resolvedUnit(unit)
                .resolvedQuantity(scanned.getQuantity())
                .resolvedUnitPrice(scanned.getUnitPrice())
                .resolvedFinalPrice(scanned.getFinalPrice())
                .standardUnitPrice(standardPrice)
                .build();
    }

    private String formatCapitalized(String str) {
        if (str == null || str.isEmpty()) return str;
        String[] words = str.toLowerCase().split("\\s+");
        StringBuilder sb = new StringBuilder();
        for (String w : words) {
            if (!w.isEmpty()) {
                sb.append(Character.toUpperCase(w.charAt(0))).append(w.substring(1)).append(" ");
            }
        }
        return sb.toString().trim();
    }
}
