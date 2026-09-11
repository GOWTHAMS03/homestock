package com.homestock.modules.smartshopping.engine.identity;

import com.homestock.modules.smartshopping.engine.matching.FuzzySimilarityEngine;
import org.springframework.stereotype.Component;

import java.util.*;

/**
 * Brand Resolver:
 * Resolves, normalizes, and validates brand identities against a comprehensive
 * canonical brand registry with alias mappings and typo tolerance (>0.90 Jaro-Winkler).
 */
@Component
public class BrandResolver {

    private final FuzzySimilarityEngine fuzzyEngine;

    // Normalized key -> Canonical Brand Name
    private static final Map<String, String> BRAND_REGISTRY = new LinkedHashMap<>();

    // Canonical Brand -> Set of Aliases / Sub-brands
    private static final Map<String, Set<String>> BRAND_ALIASES = new HashMap<>();

    static {
        registerBrand("Surf Excel", "surf", "surf excel", "surfexcel", "surf-excel");
        registerBrand("Ariel", "ariel");
        registerBrand("Tide", "tide", "tide plus");
        registerBrand("Rin", "rin");
        registerBrand("Vim", "vim");
        registerBrand("Pril", "pril");
        registerBrand("Exo", "exo");
        registerBrand("Comfort", "comfort");
        registerBrand("Lizol", "lizol");
        registerBrand("Harpic", "harpic");
        registerBrand("Colin", "colin");
        registerBrand("Domex", "domex");
        registerBrand("Dettol", "dettol", "detol");
        registerBrand("Lifebuoy", "lifebuoy", "life buoy", "lifeboy");
        registerBrand("Savlon", "savlon");
        registerBrand("Lux", "lux");
        registerBrand("Dove", "dove");
        registerBrand("Pears", "pears");
        registerBrand("Liril", "liril");
        registerBrand("Cinthol", "cinthol");
        registerBrand("Hamam", "hamam");
        registerBrand("Medimix", "medimix");
        registerBrand("Mysore Sandal", "mysore sandal", "mysoresandal");
        registerBrand("Moti", "moti");
        registerBrand("Fiama", "fiama");
        registerBrand("Vivel", "vivel");
        registerBrand("Santoor", "santoor");
        registerBrand("Godrej No.1", "godrej no 1", "godrej no.1", "godrej no1");
        registerBrand("Head & Shoulders", "head & shoulders", "head and shoulders", "head & shoulder", "head and shoulder");
        registerBrand("Pantene", "pantene");
        registerBrand("Sunsilk", "sunsilk");
        registerBrand("Tresemme", "tresemme", "tresemmé");
        registerBrand("Clinic Plus", "clinic plus", "clinicplus");
        registerBrand("Colgate", "colgate");
        registerBrand("Pepsodent", "pepsodent");
        registerBrand("Sensodyne", "sensodyne");
        registerBrand("Close-Up", "close up", "closeup", "close-up");
        registerBrand("Dabur Red", "dabur red");
        registerBrand("Dabur", "dabur");
        registerBrand("Himalaya", "himalaya");
        registerBrand("Patanjali", "patanjali");
        registerBrand("Fortune", "fortune", "fortun");
        registerBrand("Aashirvaad", "aashirvaad", "aashirwad", "asirvad", "ashirvad");
        registerBrand("Pillsbury", "pillsbury");
        registerBrand("Tata", "tata");
        registerBrand("Catch", "catch");
        registerBrand("Everest", "everest");
        registerBrand("MDH", "mdh");
        registerBrand("MTR", "mtr");
        registerBrand("Eastern", "eastern");
        registerBrand("Aachi", "aachi");
        registerBrand("Sakthi", "sakthi");
        registerBrand("Amul", "amul");
        registerBrand("Britannia", "britannia", "britania");
        registerBrand("Parle", "parle", "parle-g", "parleg");
        registerBrand("Sunfeast", "sunfeast");
        registerBrand("Oreo", "oreo");
        registerBrand("Cadbury", "cadbury");
        registerBrand("Nestle", "nestle");
        registerBrand("Horlicks", "horlicks");
        registerBrand("Boost", "boost");
        registerBrand("Complan", "complan");
        registerBrand("Bru", "bru");
        registerBrand("Nescafe", "nescafe", "nescafé");
        registerBrand("Saffola", "saffola");
        registerBrand("Kellogg's", "kellogg's", "kelloggs", "kellogg", "kellog's");
        registerBrand("Quaker", "quaker");
        registerBrand("Lay's", "lays", "lay's", "lay");
        registerBrand("Kurkure", "kurkure");
        registerBrand("Bingo", "bingo");
        registerBrand("Doritos", "doritos");
        registerBrand("Pringles", "pringles");
        registerBrand("Haldiram's", "haldiram", "haldiram's", "haldirams");
        registerBrand("Bikaji", "bikaji");
        registerBrand("Heritage", "heritage");
        registerBrand("Nandini", "nandini");
        registerBrand("Arokya", "arokya");
        registerBrand("Hatsun", "hatsun");
        registerBrand("Dodla", "dodla");
        registerBrand("Milky Mist", "milky mist", "milkymist");
        registerBrand("Gold Winner", "gold winner", "goldwinner");
        registerBrand("Sunpure", "sunpure");
        registerBrand("Gemini", "gemini");
        registerBrand("Freedom", "freedom");
        registerBrand("Dhara", "dhara");
        registerBrand("Dalda", "dalda");
        registerBrand("Idhayam", "idhayam");
        registerBrand("Parry's", "parry's", "parrys", "parry");
        registerBrand("Madhur", "madhur");
        registerBrand("Dhampur", "dhampur");
        registerBrand("Trust", "trust");
        registerBrand("India Gate", "india gate", "indiagate");
        registerBrand("Daawat", "daawat", "dawat");
        registerBrand("Kohinoor", "kohinoor");
        registerBrand("Lal Qilla", "lal qilla", "lalqilla");
        registerBrand("Pepsi", "pepsi");
        registerBrand("Coca-Cola", "coca-cola", "coca cola", "coke");
        registerBrand("Thums Up", "thums up", "thumsup");
        registerBrand("Sprite", "sprite");
        registerBrand("Fanta", "fanta");
        registerBrand("Mirinda", "mirinda");
        registerBrand("Limca", "limca");
        registerBrand("Maaza", "maaza");
        registerBrand("Frooti", "frooti");
        registerBrand("Slice", "slice");
        registerBrand("Tropicana", "tropicana");
        registerBrand("Real", "real");
        registerBrand("Red Bull", "red bull", "redbull");
        registerBrand("Monster", "monster");
        registerBrand("Whisper", "whisper");
        registerBrand("Stayfree", "stayfree");
        registerBrand("Sofy", "sofy");
        registerBrand("Pampers", "pampers");
        registerBrand("Huggies", "huggies");
        registerBrand("MamyPoko", "mamypoko", "mamy poko");
        registerBrand("Gillette", "gillette");
        registerBrand("Goodknight", "goodknight", "good knight");
        registerBrand("All Out", "all out", "allout");
        registerBrand("HIT", "hit");
        registerBrand("Godrej", "godrej");
        registerBrand("Odonil", "odonil");
        registerBrand("Scotch-Brite", "scotch-brite", "scotch brite", "scotchbrite");
        registerBrand("iD Fresh", "id fresh", "id");
        registerBrand("Epigamia", "epigamia");
        registerBrand("Yakult", "yakult");
        registerBrand("Nutella", "nutella");
        registerBrand("Kissan", "kissan");
        registerBrand("Maggi", "maggi");
    }

    public BrandResolver(FuzzySimilarityEngine fuzzyEngine) {
        this.fuzzyEngine = fuzzyEngine;
    }

    private static void registerBrand(String canonicalName, String... aliases) {
        Set<String> aliasSet = BRAND_ALIASES.computeIfAbsent(canonicalName, k -> new HashSet<>());
        aliasSet.add(canonicalName.toLowerCase());
        BRAND_REGISTRY.put(canonicalName.toLowerCase(), canonicalName);

        for (String alias : aliases) {
            String norm = alias.trim().toLowerCase();
            BRAND_REGISTRY.put(norm, canonicalName);
            aliasSet.add(norm);
        }
    }

    /**
     * Finds and extracts a brand from the given text.
     * Uses multi-token phrases first, then single tokens, and finally typo-tolerant matching.
     */
    public BrandMatch findBrand(String text) {
        if (text == null || text.isBlank()) {
            return null;
        }

        String lower = text.toLowerCase();
        String cleaned = lower.replaceAll("[^a-zA-Z0-9\\s]", " ");
        String[] words = cleaned.split("\\s+");

        // 1. Check multi-word n-grams (longest match first: 4-grams down to 2-grams)
        for (int n = Math.min(4, words.length); n >= 2; n--) {
            for (int i = 0; i <= words.length - n; i++) {
                StringBuilder sb = new StringBuilder();
                for (int j = 0; j < n; j++) {
                    if (j > 0) sb.append(" ");
                    sb.append(words[i + j]);
                }
                String phrase = sb.toString();
                if (BRAND_REGISTRY.containsKey(phrase)) {
                    String canonical = BRAND_REGISTRY.get(phrase);
                    return new BrandMatch(canonical, phrase, true);
                }
            }
        }

        // 2. Check single-word exact match against brand dictionary
        for (String word : words) {
            if (word.length() < 3) continue; // Avoid 1-2 char noise
            if (BRAND_REGISTRY.containsKey(word)) {
                String canonical = BRAND_REGISTRY.get(word);
                return new BrandMatch(canonical, word, true);
            }
        }

        // 3. Typo-tolerant matching (>0.90 Jaro-Winkler) for single tokens >= 4 chars
        for (String word : words) {
            if (word.length() < 4) continue;
            // Test against canonical brands
            for (Map.Entry<String, String> entry : BRAND_REGISTRY.entrySet()) {
                String alias = entry.getKey();
                if (alias.contains(" ")) continue; // test single word aliases
                if (Math.abs(word.length() - alias.length()) > 2) continue;

                double sim = fuzzyEngine.jaroWinkler(word, alias);
                if (sim >= 0.90) {
                    return new BrandMatch(entry.getValue(), word, false);
                }
            }
        }

        return null;
    }

    /**
     * Normalizes a brand name to its canonical form if recognized, else returns trimmed name.
     */
    public String normalizeBrand(String brand) {
        if (brand == null || brand.isBlank()) return null;
        String norm = brand.trim().toLowerCase();
        if (BRAND_REGISTRY.containsKey(norm)) {
            return BRAND_REGISTRY.get(norm);
        }

        // Check if prefix / substring matches a canonical brand
        for (Map.Entry<String, String> entry : BRAND_REGISTRY.entrySet()) {
            if (norm.equalsIgnoreCase(entry.getKey())) {
                return entry.getValue();
            }
        }

        // Typo check
        for (Map.Entry<String, String> entry : BRAND_REGISTRY.entrySet()) {
            if (fuzzyEngine.jaroWinkler(norm, entry.getKey()) >= 0.90) {
                return entry.getValue();
            }
        }

        return capitalizeWords(brand.trim());
    }

    /**
     * Strict Brand Conflict Checking:
     * Returns true if both brand names are specified and represent mutually conflicting brands.
     * E.g., "Dettol" vs "Lifebuoy", "Surf Excel" vs "Ariel", "Tata" vs "Fortune".
     */
    public boolean areConflictingBrands(String brand1, String brand2) {
        if (brand1 == null || brand1.isBlank() || brand2 == null || brand2.isBlank()) {
            return false;
        }

        String c1 = normalizeBrand(brand1);
        String c2 = normalizeBrand(brand2);

        if (c1.equalsIgnoreCase(c2)) {
            return false;
        }

        // Check alias groups - e.g. "Cadbury" and "Oreo" or "Nestle" and "Maggi"
        Set<String> aliases1 = BRAND_ALIASES.getOrDefault(c1, Collections.emptySet());
        Set<String> aliases2 = BRAND_ALIASES.getOrDefault(c2, Collections.emptySet());

        if (aliases1.contains(c2.toLowerCase()) || aliases2.contains(c1.toLowerCase())) {
            return false;
        }

        return true;
    }

    /**
     * Checks if the text explicitly contains the requested brand or its aliases.
     */
    public boolean containsBrand(String text, String requestedBrand) {
        if (text == null || requestedBrand == null) return false;
        String lowerText = " " + text.toLowerCase().replaceAll("[^a-zA-Z0-9]", " ") + " ";
        String canonical = normalizeBrand(requestedBrand);

        Set<String> aliases = BRAND_ALIASES.getOrDefault(canonical, Set.of(requestedBrand.toLowerCase()));
        for (String alias : aliases) {
            if (lowerText.contains(" " + alias + " ")) {
                return true;
            }
        }

        // Typo match
        for (String word : lowerText.split("\\s+")) {
            if (word.length() >= 4 && fuzzyEngine.jaroWinkler(word, canonical.toLowerCase()) >= 0.90) {
                return true;
            }
        }

        return false;
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

    public record BrandMatch(String canonicalBrand, String matchedToken, boolean isExact) {}
}
