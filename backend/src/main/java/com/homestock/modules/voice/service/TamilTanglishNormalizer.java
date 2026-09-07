package com.homestock.modules.voice.service;

import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;
import java.util.regex.Pattern;

@Service
public class TamilTanglishNormalizer {

    private static final Map<String, String> GROCERY_CANONICAL_MAP = new HashMap<>();

    static {
        // Rice
        register("Rice", "rice", "arisi", "arici", "ரைஸ்", "அரிசி", "சாப்பாடு அரிசி", "பச்சரிசி", "புழுங்கல் அரிசி", "basmati rice");
        // Cooking Oil
        register("Cooking Oil", "oil", "oill", "ennai", "enna", "cooking oil", "ஆயில்", "எண்ணெய்", "சமையல் எண்ணெய்", "நல்லெண்ணெய்", "கடலை எண்ணெய்", "தேங்காய் எண்ணெய்", "oil-u");
        // Milk
        register("Milk", "milk", "paal", "பால்", "மில்க்", "milk-u", "paalu");
        // Sugar
        register("Sugar", "sugar", "sakkarai", "sarkkarai", "சீனி", "சர்க்கரை", "sugar-u");
        // Salt
        register("Salt", "salt", "uppu", "உப்பு", "salt-u");
        // Atta / Wheat Flour
        register("Atta", "atta", "wheat flour", "gothumai maavu", "ஆட்டா", "கோதுமை மாவு", "மாவு", "aashirvaad atta");
        // Tea / Coffee
        register("Tea", "tea", "theenir", "டீ", "tea powder");
        register("Coffee", "coffee", "kaapi", "காபி", "coffee powder");
        // Dal
        register("Toor Dal", "toor dal", "thoor dhal", "thuvaram paruppu", "துவரம் பருப்பு", "paruppu", "பருப்பு", "dal", "dhal");
        // Vegetables
        register("Onion", "onion", "onions", "vengayam", "வெங்காயம்", "vengayam-u");
        register("Tomato", "tomato", "tomatoes", "thakkali", "தக்காளி");
        register("Potato", "potato", "potatoes", "urulaikizhangu", "உருளைக்கிழங்கு", "urulai");
        // Egg
        register("Egg", "egg", "eggs", "muttai", "mutta", "முட்டை");
        // Dairy & Bakery
        register("Ghee", "ghee", "nei", "நெய்");
        register("Butter", "butter", "vennei", "வெண்ணெய்");
        register("Curd", "curd", "thayir", "தயிர்");
        register("Bread", "bread", "ரொட்டி", "bread-u");
        // Household Cleaning
        register("Soap", "soap", "soappu", "சோப்பு", "bathing soap");
        register("Shampoo", "shampoo", "ஷாம்பு");
        register("Detergent", "detergent", "surf", "washing powder", "சலவை தூள்");
    }

    private static void register(String canonical, String... variations) {
        for (String variation : variations) {
            GROCERY_CANONICAL_MAP.put(variation.toLowerCase().trim(), canonical);
        }
    }

    /**
     * Strips Tamil/Tanglish grammatical suffixes (like "-ah", "-la", "-oda", "-kku", "-lerundhu").
     */
    public String cleanPostpositions(String word) {
        if (word == null || word.isBlank()) return "";
        String clean = word.trim();

        // Strip English/Tanglish hyphenated suffixes (e.g. "shopping-list-la", "rice-ah")
        clean = clean.replaceAll("(?i)-(la|ula|ah|a|oda|kku|ukku)$", "");

        // Strip common Tanglish trailing suffixes attached to words
        if (clean.length() > 4) {
            clean = clean.replaceAll("(?i)(la|ula|lerundhu|irundhu)$", "");
        }
        return clean.replace("-", " ").trim();
    }

    /**
     * Resolves a raw word or phrase into a canonical HomeStock item name if matched.
     */
    public String normalizeItemName(String rawText) {
        if (rawText == null || rawText.isBlank()) return rawText;

        String query = cleanPostpositions(rawText.trim().toLowerCase());

        // 1. Exact match in canonical dictionary
        if (GROCERY_CANONICAL_MAP.containsKey(query)) {
            return GROCERY_CANONICAL_MAP.get(query);
        }

        // 2. Check if query contains any known key
        for (Map.Entry<String, String> entry : GROCERY_CANONICAL_MAP.entrySet()) {
            Pattern pattern = Pattern.compile("\\b" + Pattern.quote(entry.getKey()) + "\\b", Pattern.CASE_INSENSITIVE | Pattern.UNICODE_CASE);
            if (pattern.matcher(query).find()) {
                return entry.getValue();
            }
        }

        // 3. Fallback to capitalized original name
        return capitalizeTitle(rawText.trim());
    }

    private String capitalizeTitle(String input) {
        if (input.isEmpty()) return input;
        StringBuilder sb = new StringBuilder();
        for (String word : input.split("\\s+")) {
            if (!word.isEmpty()) {
                sb.append(Character.toUpperCase(word.charAt(0)))
                  .append(word.substring(1).toLowerCase())
                  .append(" ");
            }
        }
        return sb.toString().trim();
    }
}
