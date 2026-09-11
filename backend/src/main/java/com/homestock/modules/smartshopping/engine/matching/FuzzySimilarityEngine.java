package com.homestock.modules.smartshopping.engine.matching;

import org.springframework.stereotype.Component;

import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

/**
 * Fuzzy Similarity Engine:
 * Implements Jaro-Winkler, Levenshtein Distance/Similarity, Token Set/Sort Ratio,
 * Character N-Gram overlap, and numeric matching for product identity resolution.
 */
@Component
public class FuzzySimilarityEngine {

    private static final Pattern NUMERIC_PATTERN = Pattern.compile("\\b\\d+(?:\\.\\d+)?\\b");

    /**
     * Jaro-Winkler similarity (0.0 to 1.0).
     * Sensitive to prefix matches and short strings, ideal for brand and variant typos.
     */
    public double jaroWinkler(String s1, String s2) {
        if (s1 == null || s2 == null) return 0.0;
        if (s1.equals(s2)) return 1.0;

        String str1 = s1.trim().toLowerCase();
        String str2 = s2.trim().toLowerCase();
        if (str1.isEmpty() || str2.isEmpty()) return 0.0;
        if (str1.equals(str2)) return 1.0;

        int len1 = str1.length();
        int len2 = str2.length();
        int matchWindow = Math.max(0, Math.max(len1, len2) / 2 - 1);

        boolean[] matched1 = new boolean[len1];
        boolean[] matched2 = new boolean[len2];

        int matches = 0;
        for (int i = 0; i < len1; i++) {
            int start = Math.max(0, i - matchWindow);
            int end = Math.min(i + matchWindow + 1, len2);
            for (int j = start; j < end; j++) {
                if (matched2[j]) continue;
                if (str1.charAt(i) == str2.charAt(j)) {
                    matched1[i] = true;
                    matched2[j] = true;
                    matches++;
                    break;
                }
            }
        }

        if (matches == 0) return 0.0;

        int k = 0;
        int transpositions = 0;
        for (int i = 0; i < len1; i++) {
            if (!matched1[i]) continue;
            while (!matched2[k]) {
                k++;
            }
            if (str1.charAt(i) != str2.charAt(k)) {
                transpositions++;
            }
            k++;
        }

        double jaro = ((double) matches / len1 +
                       (double) matches / len2 +
                       (double) (matches - transpositions / 2) / matches) / 3.0;

        // Prefix bonus (Winkler modification)
        int prefixLen = 0;
        int maxPrefix = Math.min(4, Math.min(len1, len2));
        for (int i = 0; i < maxPrefix; i++) {
            if (str1.charAt(i) == str2.charAt(i)) {
                prefixLen++;
            } else {
                break;
            }
        }

        double scalingFactor = 0.1;
        return jaro + (prefixLen * scalingFactor * (1.0 - jaro));
    }

    /**
     * Levenshtein distance (number of single-character edits).
     */
    public int levenshteinDistance(String s1, String s2) {
        if (s1 == null || s2 == null) return Integer.MAX_VALUE;
        String str1 = s1.trim().toLowerCase();
        String str2 = s2.trim().toLowerCase();

        int[] costs = new int[str2.length() + 1];
        for (int j = 0; j <= str2.length(); j++) {
            costs[j] = j;
        }

        for (int i = 1; i <= str1.length(); i++) {
            costs[0] = i;
            int nw = i - 1;
            for (int j = 1; j <= str2.length(); j++) {
                int cj = Math.min(1 + Math.min(costs[j], costs[j - 1]),
                        str1.charAt(i - 1) == str2.charAt(j - 1) ? nw : nw + 1);
                nw = costs[j];
                costs[j] = cj;
            }
        }

        return costs[str2.length()];
    }

    /**
     * Normalized Levenshtein similarity: 1.0 - (dist / maxLen), clamped to [0.0, 1.0].
     */
    public double levenshteinSimilarity(String s1, String s2) {
        if (s1 == null || s2 == null) return 0.0;
        String str1 = s1.trim().toLowerCase();
        String str2 = s2.trim().toLowerCase();
        if (str1.equals(str2)) return 1.0;
        int maxLen = Math.max(str1.length(), str2.length());
        if (maxLen == 0) return 1.0;
        int dist = levenshteinDistance(str1, str2);
        return Math.max(0.0, 1.0 - ((double) dist / maxLen));
    }

    /**
     * Token Set Ratio: Computes intersection, diff1, diff2 and compares token permutations.
     * Ideal for strings with rearranged tokens, brand qualifiers, and extra noise words.
     */
    public double tokenSetRatio(String s1, String s2) {
        if (s1 == null || s2 == null) return 0.0;
        Set<String> set1 = tokenizeToSet(s1);
        Set<String> set2 = tokenizeToSet(s2);

        if (set1.isEmpty() || set2.isEmpty()) return 0.0;

        Set<String> intersection = new TreeSet<>(set1);
        intersection.retainAll(set2);

        Set<String> diff1 = new TreeSet<>(set1);
        diff1.removeAll(set2);

        Set<String> diff2 = new TreeSet<>(set2);
        diff2.removeAll(set1);

        String sortedIntersect = String.join(" ", intersection);
        String sortedDiff1 = String.join(" ", diff1);
        String sortedDiff2 = String.join(" ", diff2);

        String combined1 = (sortedIntersect + " " + sortedDiff1).trim();
        String combined2 = (sortedIntersect + " " + sortedDiff2).trim();

        double sim1 = levenshteinSimilarity(sortedIntersect, combined1);
        double sim2 = levenshteinSimilarity(sortedIntersect, combined2);
        double sim3 = levenshteinSimilarity(combined1, combined2);

        return Math.max(sim1, Math.max(sim2, sim3));
    }

    /**
     * Token Sort Ratio: sorts tokens alphabetically then computes normalized similarity.
     */
    public double tokenSortRatio(String s1, String s2) {
        if (s1 == null || s2 == null) return 0.0;
        List<String> list1 = tokenizeToList(s1);
        List<String> list2 = tokenizeToList(s2);
        Collections.sort(list1);
        Collections.sort(list2);
        String sorted1 = String.join(" ", list1);
        String sorted2 = String.join(" ", list2);
        return levenshteinSimilarity(sorted1, sorted2);
    }

    /**
     * Character N-Gram Dice Similarity (default 3-gram).
     */
    public double nGramSimilarity(String s1, String s2, int n) {
        if (s1 == null || s2 == null) return 0.0;
        String str1 = s1.replaceAll("\\s+", "").toLowerCase();
        String str2 = s2.replaceAll("\\s+", "").toLowerCase();
        if (str1.equals(str2)) return 1.0;
        if (str1.length() < n || str2.length() < n) {
            return levenshteinSimilarity(str1, str2);
        }

        Map<String, Integer> ngrams1 = getNgramCounts(str1, n);
        Map<String, Integer> ngrams2 = getNgramCounts(str2, n);

        int intersection = 0;
        for (Map.Entry<String, Integer> entry : ngrams1.entrySet()) {
            if (ngrams2.containsKey(entry.getKey())) {
                intersection += Math.min(entry.getValue(), ngrams2.get(entry.getKey()));
            }
        }

        int total = (str1.length() - n + 1) + (str2.length() - n + 1);
        return (2.0 * intersection) / total;
    }

    /**
     * Verifies whether critical numbers in the query exist in the candidate text.
     * Prevents "1L" matching "2L" or "500g" matching "1kg".
     */
    public boolean numericTokensMatch(String query, String candidate) {
        if (query == null || candidate == null) return true;
        Set<String> queryNums = extractNumbers(query);
        if (queryNums.isEmpty()) return true;

        Set<String> candidateNums = extractNumbers(candidate);
        // All query numbers should be present in candidate numbers
        return candidateNums.containsAll(queryNums);
    }

    /**
     * Combined fuzzy match score between two strings, using a weighted blend of
     * Jaro-Winkler, Token Set Ratio, and Levenshtein similarity.
     */
    public double combinedSimilarity(String s1, String s2) {
        if (s1 == null || s2 == null) return 0.0;
        if (s1.trim().equalsIgnoreCase(s2.trim())) return 1.0;

        double jw = jaroWinkler(s1, s2);
        double tsr = tokenSetRatio(s1, s2);
        double lev = levenshteinSimilarity(s1, s2);

        return (jw * 0.35) + (tsr * 0.45) + (lev * 0.20);
    }

    private Set<String> tokenizeToSet(String s) {
        return Arrays.stream(s.trim().toLowerCase().split("[^a-zA-Z0-9]+"))
                .filter(t -> !t.isBlank())
                .collect(Collectors.toCollection(TreeSet::new));
    }

    private List<String> tokenizeToList(String s) {
        return Arrays.stream(s.trim().toLowerCase().split("[^a-zA-Z0-9]+"))
                .filter(t -> !t.isBlank())
                .collect(Collectors.toList());
    }

    private Map<String, Integer> getNgramCounts(String s, int n) {
        Map<String, Integer> map = new HashMap<>();
        for (int i = 0; i <= s.length() - n; i++) {
            String gram = s.substring(i, i + n);
            map.put(gram, map.getOrDefault(gram, 0) + 1);
        }
        return map;
    }

    private Set<String> extractNumbers(String text) {
        Set<String> numbers = new HashSet<>();
        Matcher m = NUMERIC_PATTERN.matcher(text);
        while (m.find()) {
            numbers.add(m.group());
        }
        return numbers;
    }
}
