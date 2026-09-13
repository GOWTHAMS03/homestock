package com.homestock.modules.voice.service;

import org.springframework.stereotype.Service;

import java.util.*;
import java.util.regex.Pattern;

@Service
public class TamilTanglishNormalizer {

    private static final Map<String, String> GROCERY_CANONICAL_MAP = new LinkedHashMap<>();
    private static final Map<String, String> CANONICAL_TO_CATEGORY_MAP = new HashMap<>();
    private static final Map<String, String> CANONICAL_TO_UNIT_MAP = new HashMap<>();

    static {
        // Grains & Flours
        registerWithMeta("Rice", "Grains", "KG",
                "rice", "arisi", "arici", "ரைஸ்", "அரிசி", "சாப்பாடு அரிசி", "பச்சரிசி", "புழுங்கல் அரிசி",
                "basmati", "basmati rice", "sona masoori", "ponni rice", "raw rice", "boiled rice",
                "idli rice", "dosa rice", "brown rice", "rais", "raice", "arisii", "ricee", "rice-a", "arisi-a");

        registerWithMeta("Atta", "Flour & Batter", "KG",
                "atta", "wheat flour", "gothumai maavu", "ஆட்டா", "கோதுமை மாவு", "மாவு", "wheat",
                "chakki atta", "aashirvaad atta", "godhumai", "atta maavu");

        registerWithMeta("Maida", "Flour & Batter", "KG",
                "maida", "all purpose flour", "மைதா", "maida maavu");

        registerWithMeta("Besan", "Flour & Batter", "KG",
                "besan", "gram flour", "kadalai maavu", "கடலை மாவு", "senaga pindi");

        registerWithMeta("Rava", "Flour & Batter", "KG",
                "rava", "sooji", "semolina", "ரவை", "ravai");

        registerWithMeta("Poha", "Grains", "KG",
                "poha", "aval", "அவல்", "flattened rice", "avalu");

        registerWithMeta("Oats", "Grains", "PACKET",
                "oats", "ஓட்ஸ்", "quaker oats", "masala oats");

        // Cooking Oils & Ghee
        registerWithMeta("Cooking Oil", "Oils & Ghee", "L",
                "oil", "oill", "ennai", "enna", "cooking oil", "ஆயில்", "எண்ணெய்", "சமையல் எண்ணெய்",
                "sunflower oil", "groundnut oil", "sesame oil", "gingelly oil", "mustard oil", "coconut oil",
                "நல்லெண்ணெய்", "கடலை எண்ணெய்", "தேங்காய் எண்ணெய்", "oil-u", "oil-a", "ennai-a",
                "fortune oil", "gemini oil", "gold winner", "dhara");

        registerWithMeta("Ghee", "Dairy", "G",
                "ghee", "nei", "neyyi", "நெய்", "cow ghee", "amul ghee", "grb ghee");

        // Dairy
        registerWithMeta("Milk", "Dairy", "PACKET",
                "milk", "paal", "பால்", "மில்க்", "milk-u", "paalu", "toned milk", "full cream milk",
                "aavin milk", "amul milk", "milk packet", "paal packet", "cow milk");

        registerWithMeta("Curd", "Dairy", "PACKET",
                "curd", "thayir", "தயிர்", "yogurt", "curd packet", "thayir packet");

        registerWithMeta("Butter", "Dairy", "G",
                "butter", "vennei", "வெண்ணெய்", "amul butter", "salted butter");

        registerWithMeta("Paneer", "Dairy", "G",
                "paneer", "பன்னீர்", "cottage cheese", "amul paneer");

        registerWithMeta("Cheese", "Dairy", "PACKET",
                "cheese", "சீஸ்", "cheese slices", "cheese cube", "amul cheese");

        // Pulses & Dal
        registerWithMeta("Toor Dal", "Pulses & Dal", "KG",
                "toor dal", "thoor dhal", "thuvaram paruppu", "துவரம் பருப்பு", "paruppu", "பருப்பு",
                "dal", "dhal", "sambhar paruppu");

        registerWithMeta("Moong Dal", "Pulses & Dal", "KG",
                "moong dal", "paasi paruppu", "பாசி பருப்பு", "pasi paruppu", "yellow dal");

        registerWithMeta("Urad Dal", "Pulses & Dal", "KG",
                "urad dal", "ulundham paruppu", "உளுந்தம் பருப்பு", "ulunthu", "black dal");

        registerWithMeta("Chana Dal", "Pulses & Dal", "KG",
                "chana dal", "kadalai paruppu", "கடலை பருப்பு", "bengal gram");

        registerWithMeta("Rajma", "Pulses & Dal", "KG",
                "rajma", "kidney beans", "ராஜ்மா");

        registerWithMeta("Chana", "Pulses & Dal", "KG",
                "chana", "kondakadalai", "கொண்டைக்கடலை", "chickpeas", "white chana", "black chana");

        // Spices & Seasonings
        registerWithMeta("Sugar", "Spices & Seasonings", "KG",
                "sugar", "sakkarai", "sarkkarai", "சீனி", "சர்க்கரை", "sugar-u", "nattu sakkarai", "brown sugar");

        registerWithMeta("Salt", "Spices & Seasonings", "KG",
                "salt", "uppu", "உப்பு", "salt-u", "tata salt", "iodized salt", "kallu uppu", "crystal salt");

        registerWithMeta("Turmeric Powder", "Spices & Seasonings", "G",
                "turmeric", "turmeric powder", "manjal thool", "மஞ்சள் தூள்", "manjal", "manjal podi");

        registerWithMeta("Chilli Powder", "Spices & Seasonings", "G",
                "chilli powder", "milagai thool", "மிளகாய் தூள்", "red chilli powder", "milagai podi");

        registerWithMeta("Coriander Powder", "Spices & Seasonings", "G",
                "coriander powder", "dhaniya thool", "மல்லி தூள்", "kothamalli thool", "dhaniya powder");

        registerWithMeta("Mustard Seeds", "Spices & Seasonings", "G",
                "mustard", "mustard seeds", "kadugu", "கடுகு");

        registerWithMeta("Cumin Seeds", "Spices & Seasonings", "G",
                "cumin", "cumin seeds", "jeeragam", "சீரகம்", "zeera");

        registerWithMeta("Pepper", "Spices & Seasonings", "G",
                "pepper", "black pepper", "milagu", "மிளகு");

        registerWithMeta("Fenugreek", "Spices & Seasonings", "G",
                "fenugreek", "vendhayam", "வெந்தயம்");

        registerWithMeta("Fennel Seeds", "Spices & Seasonings", "G",
                "fennel", "fennel seeds", "sombu", "சோம்பு", "saunf");

        registerWithMeta("Cardamom", "Spices & Seasonings", "G",
                "cardamom", "elakkai", "ஏலக்காய்", "elaichi");

        registerWithMeta("Cloves", "Spices & Seasonings", "G",
                "cloves", "lavangam", "கிராம்பு", "laung");

        registerWithMeta("Cinnamon", "Spices & Seasonings", "G",
                "cinnamon", "pattai", "பட்டை", "dalchini");

        registerWithMeta("Asafoetida", "Spices & Seasonings", "G",
                "asafoetida", "perungayam", "பெருங்காயம்", "hing", "compounded asafoetida");

        registerWithMeta("Sambar Powder", "Spices & Seasonings", "PACKET",
                "sambar powder", "sambar thool", "சாம்பார் தூள்", "sambar podi", "aachi sambar powder");

        registerWithMeta("Rasam Powder", "Spices & Seasonings", "PACKET",
                "rasam powder", "rasam thool", "ரசம் தூள்", "rasam podi");

        registerWithMeta("Garam Masala", "Spices & Seasonings", "PACKET",
                "garam masala", "கரம் மசாலா", "garam masala powder");

        registerWithMeta("Tamarind", "Spices & Seasonings", "KG",
                "tamarind", "puli", "புளி");

        // Beverages
        registerWithMeta("Tea", "Beverages", "PACKET",
                "tea", "theenir", "டீ", "tea powder", "taj mahal tea", "red label", "chakra gold", "tea thool", "3 roses");

        registerWithMeta("Coffee", "Beverages", "PACKET",
                "coffee", "kaapi", "காபி", "coffee powder", "bru", "sunrise", "filter coffee powder", "nescafe");

        // Vegetables & Fresh Produce
        registerWithMeta("Onion", "Vegetables", "KG",
                "onion", "onions", "vengayam", "வெங்காயம்", "vengayam-u", "chinna vengayam", "periya vengayam", "shallots");

        registerWithMeta("Tomato", "Vegetables", "KG",
                "tomato", "tomatoes", "thakkali", "தக்காளி", "thakkaali");

        registerWithMeta("Potato", "Vegetables", "KG",
                "potato", "potatoes", "urulaikizhangu", "உருளைக்கிழங்கு", "urulai", "aloo");

        registerWithMeta("Ginger", "Vegetables", "G",
                "ginger", "inji", "இஞ்சி", "adrak");

        registerWithMeta("Garlic", "Vegetables", "G",
                "garlic", "poondu", "பூண்டு", "lahsun");

        registerWithMeta("Green Chilli", "Vegetables", "G",
                "green chilli", "pachai milagai", "பச்சை மிளகாய்", "green chillies");

        registerWithMeta("Coriander Leaves", "Vegetables", "PACKET",
                "coriander", "coriander leaves", "kothamalli", "கொத்தமல்லி", "cilantro");

        registerWithMeta("Curry Leaves", "Vegetables", "PACKET",
                "curry leaves", "karuveppilai", "கறிவேப்பிலை", "karivepila");

        registerWithMeta("Carrot", "Vegetables", "KG",
                "carrot", "கேரட்");

        registerWithMeta("Beans", "Vegetables", "KG",
                "beans", "பீன்ஸ்");

        registerWithMeta("Cabbage", "Vegetables", "KG",
                "cabbage", "muttaikose", "முட்டைகோஸ்");

        registerWithMeta("Beetroot", "Vegetables", "KG",
                "beetroot", "பீட்ரூட்");

        registerWithMeta("Ladies Finger", "Vegetables", "KG",
                "ladies finger", "okra", "vendakkai", "வெண்டைக்காய்", "bhindi");

        registerWithMeta("Brinjal", "Vegetables", "KG",
                "brinjal", "eggplant", "kathirikkai", "கத்தரிக்காய்", "baingan");

        registerWithMeta("Drumstick", "Vegetables", "PCS",
                "drumstick", "murungakkai", "முருங்கைக்காய்");

        registerWithMeta("Lemon", "Vegetables", "PCS",
                "lemon", "elumichai", "எலுமிச்சை", "nimbu");

        registerWithMeta("Coconut", "Vegetables", "PCS",
                "coconut", "thengai", "தேங்காய்");

        // Bakery, Breakfast & Snacks
        registerWithMeta("Bread", "Bakery", "PACKET",
                "bread", "ரொட்டி", "bread-u", "white bread", "wheat bread", "brown bread", "bread packet");

        registerWithMeta("Egg", "Eggs & Meat", "PCS",
                "egg", "eggs", "muttai", "mutta", "முட்டை", "country egg", "nattu muttai");

        registerWithMeta("Biscuits", "Snacks", "PACKET",
                "biscuit", "biscuits", "பிஸ்கட்", "cookies", "parle g", "marie gold", "good day", "bourbon");

        registerWithMeta("Noodles", "Snacks", "PACKET",
                "noodles", "maggi", "மேகி", "yippee", "instant noodles");

        // Cleaning & Personal Care
        registerWithMeta("Soap", "Personal Care", "PCS",
                "soap", "soappu", "சோப்பு", "bathing soap", "body soap", "lifebuoy", "hamam", "dettol", "dove", "cinthol");

        registerWithMeta("Shampoo", "Personal Care", "BOTTLE",
                "shampoo", "ஷாம்பு", "hair shampoo", "clinic plus", "head and shoulders", "sunsilk");

        registerWithMeta("Toothpaste", "Personal Care", "PCS",
                "toothpaste", "paste", "பற்பசை", "colgate", "close up", "pepsodent");

        registerWithMeta("Detergent", "Cleaning", "KG",
                "detergent", "surf", "washing powder", "சலவை தூள்", "surf excel", "ariel", "detergent powder", "tide", "rin");

        registerWithMeta("Dishwash Liquid", "Cleaning", "BOTTLE",
                "dishwash", "dishwash liquid", "vim", "vim gel", "பாத்திரம் கழுவும் திரவம்", "pril");

        registerWithMeta("Floor Cleaner", "Cleaning", "BOTTLE",
                "floor cleaner", "lizol", "surface cleaner");
    }

    private static void registerWithMeta(String canonical, String category, String defaultUnit, String... variations) {
        CANONICAL_TO_CATEGORY_MAP.put(canonical, category);
        CANONICAL_TO_UNIT_MAP.put(canonical, defaultUnit);

        // Canonical itself
        GROCERY_CANONICAL_MAP.put(canonical.toLowerCase().trim(), canonical);

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
        clean = clean.replaceAll("(?i)-(la|ula|ah|a|oda|ode|kku|ukku|ku)$", "");

        // Strip common Tanglish trailing suffixes attached to words
        if (clean.length() > 4) {
            clean = clean.replaceAll("(?i)(la|ula|lerundhu|irundhu|oda|ode|kku|ukku)$", "");
        }

        // Tamil script suffixes: -ஐ, -இல், -இருந்து, -க்கு, -உக்கு
        clean = clean.replaceAll("(ஐ|இல்|இருந்து|க்கு|உக்கு)$", "");

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
            Pattern pattern = Pattern.compile("\\b" + Pattern.quote(entry.getKey()) + "\\b",
                    Pattern.CASE_INSENSITIVE | Pattern.UNICODE_CASE);
            if (pattern.matcher(query).find()) {
                return entry.getValue();
            }
        }

        // 3. Fallback to capitalized original name
        return capitalizeTitle(rawText.trim());
    }

    /**
     * Returns true if the query is a recognized alias in the canonical dictionary.
     */
    public boolean hasCanonicalMatch(String text) {
        if (text == null || text.isBlank()) return false;
        String query = cleanPostpositions(text.trim().toLowerCase());
        return GROCERY_CANONICAL_MAP.containsKey(query);
    }

    /**
     * Gets canonical name if present, or null.
     */
    public String getCanonicalMatch(String text) {
        if (text == null || text.isBlank()) return null;
        String query = cleanPostpositions(text.trim().toLowerCase());
        return GROCERY_CANONICAL_MAP.get(query);
    }

    public String getDefaultCategory(String canonicalName) {
        return CANONICAL_TO_CATEGORY_MAP.getOrDefault(canonicalName, "General");
    }

    public String getDefaultUnit(String canonicalName) {
        return CANONICAL_TO_UNIT_MAP.getOrDefault(canonicalName, "PCS");
    }

    public Set<String> getAllCanonicalNames() {
        return Collections.unmodifiableSet(CANONICAL_TO_CATEGORY_MAP.keySet());
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
