package com.homestock.modules.voice.service;

import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.inventory.repository.InventoryItemRepository;
import com.homestock.modules.product.entity.Product;
import com.homestock.modules.product.repository.ProductRepository;
import com.homestock.modules.voice.dto.ProductMatchResult;
import com.homestock.modules.voice.dto.ProductMatchResult.MatchType;
import com.homestock.modules.voice.dto.ProductMatchResult.ProductCandidate;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class ProductResolutionService {

    private final InventoryItemRepository inventoryItemRepository;
    private final ProductRepository productRepository;
    private final TamilTanglishNormalizer tamilTanglishNormalizer;

    /**
     * Resolves a voice-recognized product query into a verified HomeStock product/inventory item.
     *
     * @param homeId             the active home ID
     * @param spokenProductText  the raw product text extracted from speech
     * @param geminiProductName  Gemini's suggested canonical product name
     * @return ProductMatchResult containing matched ID, name, confidence, match type, and disambiguation candidates
     */
    public ProductMatchResult resolveProduct(UUID homeId, String spokenProductText, String geminiProductName) {
        if ((spokenProductText == null || spokenProductText.isBlank())
                && (geminiProductName == null || geminiProductName.isBlank())) {
            return ProductMatchResult.builder()
                    .confidence(0.0)
                    .matchType(MatchType.NONE)
                    .build();
        }

        String primaryQuery = (spokenProductText != null && !spokenProductText.isBlank())
                ? spokenProductText.trim()
                : geminiProductName.trim();

        // 1. Normalization
        String cleanedSpoken = tamilTanglishNormalizer.cleanPostpositions(primaryQuery);
        String canonicalFromSpoken = tamilTanglishNormalizer.getCanonicalMatch(cleanedSpoken);
        String canonicalFromGemini = (geminiProductName != null && !geminiProductName.isBlank())
                ? tamilTanglishNormalizer.getCanonicalMatch(geminiProductName.trim())
                : null;

        String canonicalTarget = canonicalFromSpoken != null ? canonicalFromSpoken
                : (canonicalFromGemini != null ? canonicalFromGemini
                : (geminiProductName != null ? geminiProductName.trim() : cleanedSpoken));

        List<InventoryItem> activeItems = inventoryItemRepository
                .findAllByHomeIdAndIsArchivedFalseOrderByNameAsc(homeId);

        // 2. Exact match against inventory items
        for (InventoryItem item : activeItems) {
            String itemName = item.getName().trim();
            if (itemName.equalsIgnoreCase(primaryQuery)
                    || itemName.equalsIgnoreCase(cleanedSpoken)
                    || itemName.equalsIgnoreCase(canonicalTarget)) {
                return ProductMatchResult.builder()
                        .productId(item.getId())
                        .productName(item.getName())
                        .category(item.getCategory() != null ? item.getCategory().getName() : null)
                        .defaultUnit(item.getUnit())
                        .confidence(1.0)
                        .matchType(MatchType.EXACT)
                        .candidates(List.of(toCandidate(item, 1.0, "Exact match in inventory")))
                        .build();
            }
        }

        // 3. Exact alias match from canonical grocery vocabulary
        if (canonicalFromSpoken != null || canonicalFromGemini != null) {
            String targetCanonical = canonicalFromSpoken != null ? canonicalFromSpoken : canonicalFromGemini;
            List<InventoryItem> aliasMatches = activeItems.stream()
                    .filter(item -> item.getName().toLowerCase().contains(targetCanonical.toLowerCase())
                            || targetCanonical.toLowerCase().contains(item.getName().toLowerCase()))
                    .toList();

            if (aliasMatches.size() == 1) {
                InventoryItem item = aliasMatches.get(0);
                return ProductMatchResult.builder()
                        .productId(item.getId())
                        .productName(item.getName())
                        .category(item.getCategory() != null ? item.getCategory().getName() : tamilTanglishNormalizer.getDefaultCategory(targetCanonical))
                        .defaultUnit(item.getUnit() != null ? item.getUnit() : tamilTanglishNormalizer.getDefaultUnit(targetCanonical))
                        .confidence(0.98)
                        .matchType(MatchType.ALIAS)
                        .candidates(List.of(toCandidate(item, 0.98, "Canonical grocery alias: " + targetCanonical)))
                        .build();
            }
        }

        // 4. Barcode / Master Product Catalog lookup
        if (primaryQuery.matches("^\\d{8,14}$")) {
            Optional<Product> catalogProduct = productRepository.findByBarcode(primaryQuery);
            if (catalogProduct.isPresent()) {
                Product prod = catalogProduct.get();
                Optional<InventoryItem> inv = inventoryItemRepository.findByHomeIdAndProductId(homeId, prod.getId());
                return ProductMatchResult.builder()
                        .productId(inv.map(InventoryItem::getId).orElse(prod.getId()))
                        .productName(prod.getName())
                        .confidence(0.99)
                        .matchType(MatchType.BARCODE)
                        .candidates(List.of(ProductCandidate.builder()
                                .productId(prod.getId())
                                .productName(prod.getName())
                                .brand(prod.getBrand())
                                .score(0.99)
                                .matchReason("Barcode catalog match")
                                .build()))
                        .build();
            }
        }

        // 5 & 6. Fuzzy (Levenshtein) and Semantic (Jaccard Token Overlap) scoring
        List<ScoredItem> scoredItems = new ArrayList<>();
        String queryLower = cleanedSpoken.toLowerCase();
        String canonicalLower = canonicalTarget.toLowerCase();

        for (InventoryItem item : activeItems) {
            String itemLower = item.getName().toLowerCase();
            double score = calculateMatchScore(queryLower, canonicalLower, itemLower);
            if (score > 0.40) {
                scoredItems.add(new ScoredItem(item, score));
            }
        }

        // Sort descending by score
        scoredItems.sort((a, b) -> Double.compare(b.score, a.score));

        // 7. Candidate Ranking & Decision
        if (!scoredItems.isEmpty()) {
            ScoredItem top = scoredItems.get(0);
            List<ProductCandidate> candidates = scoredItems.stream()
                    .limit(5)
                    .map(si -> toCandidate(si.item, si.score, "Similarity score: " + String.format("%.2f", si.score)))
                    .collect(Collectors.toList());

            // Check if top candidate is distinct and high confidence
            boolean isDistinct = scoredItems.size() == 1 || (top.score - scoredItems.get(1).score) >= 0.15;

            if (top.score >= 0.90 && isDistinct) {
                return ProductMatchResult.builder()
                        .productId(top.item.getId())
                        .productName(top.item.getName())
                        .category(top.item.getCategory() != null ? top.item.getCategory().getName() : null)
                        .defaultUnit(top.item.getUnit())
                        .confidence(top.score)
                        .matchType(MatchType.FUZZY)
                        .candidates(candidates)
                        .build();
            } else if (top.score >= 0.70) {
                // Ambiguous or medium confidence: requires confirmation or disambiguation
                return ProductMatchResult.builder()
                        .productId(top.item.getId())
                        .productName(top.item.getName())
                        .category(top.item.getCategory() != null ? top.item.getCategory().getName() : null)
                        .defaultUnit(top.item.getUnit())
                        .confidence(top.score)
                        .matchType(MatchType.SEMANTIC)
                        .candidates(candidates)
                        .build();
            }
        }

        // 8. No home inventory match found — fallback to recognized canonical grocery item
        if (tamilTanglishNormalizer.hasCanonicalMatch(cleanedSpoken) || canonicalFromSpoken != null) {
            String resolvedCanonical = canonicalFromSpoken != null ? canonicalFromSpoken : tamilTanglishNormalizer.normalizeItemName(cleanedSpoken);
            return ProductMatchResult.builder()
                    .productId(null) // Not yet in home inventory
                    .productName(resolvedCanonical)
                    .category(tamilTanglishNormalizer.getDefaultCategory(resolvedCanonical))
                    .defaultUnit(tamilTanglishNormalizer.getDefaultUnit(resolvedCanonical))
                    .confidence(0.98)
                    .matchType(MatchType.ALIAS)
                    .candidates(List.of(ProductCandidate.builder()
                            .productName(resolvedCanonical)
                            .category(tamilTanglishNormalizer.getDefaultCategory(resolvedCanonical))
                            .score(0.98)
                            .matchReason("Standard grocery catalog match")
                            .build()))
                    .build();
        }

        // Generic fallback: use cleaned spoken or Gemini suggestion
        String fallbackName = canonicalTarget.isBlank() ? primaryQuery : canonicalTarget;
        return ProductMatchResult.builder()
                .productId(null)
                .productName(fallbackName)
                .confidence(0.90)
                .matchType(MatchType.NONE)
                .build();
    }

    private double calculateMatchScore(String query, String canonical, String itemName) {
        // Direct containment
        if (itemName.contains(query) || query.contains(itemName)) {
            double lengthRatio = (double) Math.min(query.length(), itemName.length()) / Math.max(query.length(), itemName.length());
            return Math.max(0.85, 0.80 + (0.15 * lengthRatio));
        }

        if (itemName.contains(canonical) || canonical.contains(itemName)) {
            double lengthRatio = (double) Math.min(canonical.length(), itemName.length()) / Math.max(canonical.length(), itemName.length());
            return Math.max(0.82, 0.78 + (0.15 * lengthRatio));
        }

        // Levenshtein distance on full string
        int editDist = computeLevenshteinDistance(query, itemName);
        int maxLen = Math.max(query.length(), itemName.length());
        double editSimilarity = 1.0 - ((double) editDist / maxLen);

        if (editDist <= 2) {
            return Math.max(0.85, editSimilarity);
        }

        // Jaccard word-level overlap
        double jaccard = computeJaccardSimilarity(query, itemName);

        return Math.max(editSimilarity * 0.7, jaccard);
    }

    private int computeLevenshteinDistance(String s1, String s2) {
        int[] prev = new int[s2.length() + 1];
        int[] curr = new int[s2.length() + 1];

        for (int j = 0; j <= s2.length(); j++) {
            prev[j] = j;
        }

        for (int i = 1; i <= s1.length(); i++) {
            curr[0] = i;
            for (int j = 1; j <= s2.length(); j++) {
                int cost = (s1.charAt(i - 1) == s2.charAt(j - 1)) ? 0 : 1;
                curr[j] = Math.min(Math.min(curr[j - 1] + 1, prev[j] + 1), prev[j - 1] + cost);
            }
            System.arraycopy(curr, 0, prev, 0, curr.length);
        }

        return prev[s2.length()];
    }

    private double computeJaccardSimilarity(String s1, String s2) {
        Set<String> words1 = Arrays.stream(s1.split("\\s+")).filter(w -> !w.isBlank()).collect(Collectors.toSet());
        Set<String> words2 = Arrays.stream(s2.split("\\s+")).filter(w -> !w.isBlank()).collect(Collectors.toSet());

        if (words1.isEmpty() || words2.isEmpty()) return 0.0;

        Set<String> intersection = new HashSet<>(words1);
        intersection.retainAll(words2);

        Set<String> union = new HashSet<>(words1);
        union.addAll(words2);

        return (double) intersection.size() / union.size();
    }

    private ProductCandidate toCandidate(InventoryItem item, double score, String reason) {
        return ProductCandidate.builder()
                .productId(item.getId())
                .productName(item.getName())
                .brand(item.getBrand())
                .category(item.getCategory() != null ? item.getCategory().getName() : null)
                .score(score)
                .matchReason(reason)
                .build();
    }

    private record ScoredItem(InventoryItem item, double score) {}
}

