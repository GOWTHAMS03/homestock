package com.homestock.modules.bill.matching;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Normalization service for grocery bills in Tamil script and Tanglish (Romanized Tamil).
 * Handles:
 * - Direct Tamil Unicode script words (அரிசி, பருப்பு, எண்ணெய், etc.)
 * - Tanglish transliterated words (arisi, paruppu, dhal, ennai, etc.)
 * - Tamil unit terms (கிலோ, கிராம், லிட்டர், etc.)
 */
@Service
public class TamilNormalizationService {

    private static final Logger log = LoggerFactory.getLogger(TamilNormalizationService.class);

    // Tamil Unicode range: U+0B80 to U+0BFF
    private static final Pattern TAMIL_SCRIPT_PATTERN = Pattern.compile("[\\u0B80-\\u0BFF]");

    // Tamil Script -> English Canonical Grocery Map
    private static final Map<String, String> TAMIL_SCRIPT_TO_ENGLISH = new LinkedHashMap<>();

    // Tanglish (Romanized Tamil) -> English Canonical Grocery Map
    private static final Map<String, String> TANGLISH_TO_ENGLISH = new LinkedHashMap<>();

    // Tamil Units -> Standard Units
    private static final Map<String, String> TAMIL_UNITS = new LinkedHashMap<>();

    static {
        // --- 1. Tamil Script Dictionary ---
        // Grains & Flours
        TAMIL_SCRIPT_TO_ENGLISH.put("அரிசி", "RICE");
        TAMIL_SCRIPT_TO_ENGLISH.put("பொன்னி அரிசி", "PONNI RICE");
        TAMIL_SCRIPT_TO_ENGLISH.put("பாசுமதி அரிசி", "BASMATI RICE");
        TAMIL_SCRIPT_TO_ENGLISH.put("பச்சரிசி", "RAW RICE");
        TAMIL_SCRIPT_TO_ENGLISH.put("புழுங்கல் அரிசி", "BOILED RICE");
        TAMIL_SCRIPT_TO_ENGLISH.put("கோதுமை மாவு", "ATTA");
        TAMIL_SCRIPT_TO_ENGLISH.put("கோதுமை", "WHEAT");
        TAMIL_SCRIPT_TO_ENGLISH.put("ஆட்டா", "ATTA");
        TAMIL_SCRIPT_TO_ENGLISH.put("மைதா", "MAIDA");
        TAMIL_SCRIPT_TO_ENGLISH.put("ரவை", "RAVA");
        TAMIL_SCRIPT_TO_ENGLISH.put("சேமியா", "VERMICELLI");
        TAMIL_SCRIPT_TO_ENGLISH.put("அவல்", "POHA");

        // Dals & Pulses
        TAMIL_SCRIPT_TO_ENGLISH.put("பருப்பு", "DAL");
        TAMIL_SCRIPT_TO_ENGLISH.put("துவரம் பருப்பு", "TOOR DAL");
        TAMIL_SCRIPT_TO_ENGLISH.put("துவரம்பருப்பு", "TOOR DAL");
        TAMIL_SCRIPT_TO_ENGLISH.put("பாசிப் பருப்பு", "MOONG DAL");
        TAMIL_SCRIPT_TO_ENGLISH.put("பாசிப்பருப்பு", "MOONG DAL");
        TAMIL_SCRIPT_TO_ENGLISH.put("உளுத்தம் பருப்பு", "URAD DAL");
        TAMIL_SCRIPT_TO_ENGLISH.put("உளுத்தம்பருப்பு", "URAD DAL");
        TAMIL_SCRIPT_TO_ENGLISH.put("உளுந்து", "URAD DAL");
        TAMIL_SCRIPT_TO_ENGLISH.put("கடலைப் பருப்பு", "CHANA DAL");
        TAMIL_SCRIPT_TO_ENGLISH.put("கடலைப்பருப்பு", "CHANA DAL");
        TAMIL_SCRIPT_TO_ENGLISH.put("பொட்டுக்கடலை", "ROASTED GRAM");
        TAMIL_SCRIPT_TO_ENGLISH.put("சுண்டல்", "CHANA");
        TAMIL_SCRIPT_TO_ENGLISH.put("வேர்க்கடலை", "PEANUTS");
        TAMIL_SCRIPT_TO_ENGLISH.put("நிலக்கடலை", "PEANUTS");

        // Oils & Dairy
        TAMIL_SCRIPT_TO_ENGLISH.put("எண்ணெய்", "OIL");
        TAMIL_SCRIPT_TO_ENGLISH.put("நல்லெண்ணெய்", "SESAME OIL");
        TAMIL_SCRIPT_TO_ENGLISH.put("கடலை எண்ணெய்", "GROUNDNUT OIL");
        TAMIL_SCRIPT_TO_ENGLISH.put("சூரியகாந்தி எண்ணெய்", "SUNFLOWER OIL");
        TAMIL_SCRIPT_TO_ENGLISH.put("தேங்காய் எண்ணெய்", "COCONUT OIL");
        TAMIL_SCRIPT_TO_ENGLISH.put("நெய்", "GHEE");
        TAMIL_SCRIPT_TO_ENGLISH.put("பால்", "MILK");
        TAMIL_SCRIPT_TO_ENGLISH.put("தயிர்", "CURD");
        TAMIL_SCRIPT_TO_ENGLISH.put("வெண்ணெய்", "BUTTER");
        TAMIL_SCRIPT_TO_ENGLISH.put("பன்னீர்", "PANEER");

        // Spices & Condiments
        TAMIL_SCRIPT_TO_ENGLISH.put("சர்க்கரை", "SUGAR");
        TAMIL_SCRIPT_TO_ENGLISH.put("சீனி", "SUGAR");
        TAMIL_SCRIPT_TO_ENGLISH.put("நாட்டுச் சர்க்கரை", "BROWN SUGAR");
        TAMIL_SCRIPT_TO_ENGLISH.put("வெல்லம்", "JAGGERY");
        TAMIL_SCRIPT_TO_ENGLISH.put("உப்பு", "SALT");
        TAMIL_SCRIPT_TO_ENGLISH.put("தூள் உப்பு", "SALT");
        TAMIL_SCRIPT_TO_ENGLISH.put("கல் உப்பு", "CRYSTAL SALT");
        TAMIL_SCRIPT_TO_ENGLISH.put("மஞ்சள் தூள்", "TURMERIC POWDER");
        TAMIL_SCRIPT_TO_ENGLISH.put("மஞ்சள்", "TURMERIC");
        TAMIL_SCRIPT_TO_ENGLISH.put("மிளகாய் தூள்", "CHILLI POWDER");
        TAMIL_SCRIPT_TO_ENGLISH.put("மிளகாய்", "CHILLI");
        TAMIL_SCRIPT_TO_ENGLISH.put("மல்லித் தூள்", "CORIANDER POWDER");
        TAMIL_SCRIPT_TO_ENGLISH.put("மல்லி", "CORIANDER");
        TAMIL_SCRIPT_TO_ENGLISH.put("தனியா", "CORIANDER");
        TAMIL_SCRIPT_TO_ENGLISH.put("கடுகு", "MUSTARD");
        TAMIL_SCRIPT_TO_ENGLISH.put("சீரகம்", "CUMIN");
        TAMIL_SCRIPT_TO_ENGLISH.put("சோம்பு", "FENNEL");
        TAMIL_SCRIPT_TO_ENGLISH.put("வெந்தயம்", "FENUGREEK");
        TAMIL_SCRIPT_TO_ENGLISH.put("மிளகு", "BLACK PEPPER");
        TAMIL_SCRIPT_TO_ENGLISH.put("பெருங்காயம்", "ASAFOETIDA");
        TAMIL_SCRIPT_TO_ENGLISH.put("புளி", "TAMARIND");
        TAMIL_SCRIPT_TO_ENGLISH.put("பூண்டு", "GARLIC");
        TAMIL_SCRIPT_TO_ENGLISH.put("இஞ்சி", "GINGER");
        TAMIL_SCRIPT_TO_ENGLISH.put("பட்டை", "CINNAMON");
        TAMIL_SCRIPT_TO_ENGLISH.put("கிராம்பு", "CLOVE");
        TAMIL_SCRIPT_TO_ENGLISH.put("ஏலக்காய்", "CARDAMOM");

        // Vegetables & Fresh Goods
        TAMIL_SCRIPT_TO_ENGLISH.put("வெங்காயம்", "ONION");
        TAMIL_SCRIPT_TO_ENGLISH.put("சின்ன வெங்காயம்", "SHALLOTS");
        TAMIL_SCRIPT_TO_ENGLISH.put("பெரிய வெங்காயம்", "ONION");
        TAMIL_SCRIPT_TO_ENGLISH.put("தக்காளி", "TOMATO");
        TAMIL_SCRIPT_TO_ENGLISH.put("உருளைக்கிழங்கு", "POTATO");
        TAMIL_SCRIPT_TO_ENGLISH.put("உருளை", "POTATO");
        TAMIL_SCRIPT_TO_ENGLISH.put("கேரட்", "CARROT");
        TAMIL_SCRIPT_TO_ENGLISH.put("பீன்ஸ்", "BEANS");
        TAMIL_SCRIPT_TO_ENGLISH.put("கத்தரிக்காய்", "BRINJAL");
        TAMIL_SCRIPT_TO_ENGLISH.put("வெண்டைக்காய்", "LADIES FINGER");
        TAMIL_SCRIPT_TO_ENGLISH.put("தேங்காய்", "COCONUT");
        TAMIL_SCRIPT_TO_ENGLISH.put("கொத்தமல்லி", "CORIANDER LEAVES");
        TAMIL_SCRIPT_TO_ENGLISH.put("கருவேப்பிலை", "CURRY LEAVES");
        TAMIL_SCRIPT_TO_ENGLISH.put("புதினா", "MINT");
        TAMIL_SCRIPT_TO_ENGLISH.put("பச்சை மிளகாய்", "GREEN CHILLI");

        // Beverages & Household
        TAMIL_SCRIPT_TO_ENGLISH.put("தேயிலை", "TEA");
        TAMIL_SCRIPT_TO_ENGLISH.put("டீ தூள்", "TEA POWDER");
        TAMIL_SCRIPT_TO_ENGLISH.put("காபி தூள்", "COFFEE POWDER");
        TAMIL_SCRIPT_TO_ENGLISH.put("சோப்பு", "SOAP");
        TAMIL_SCRIPT_TO_ENGLISH.put("துணி சோப்பு", "LAUNDRY SOAP");
        TAMIL_SCRIPT_TO_ENGLISH.put("ஷாம்பு", "SHAMPOO");

        // --- 2. Tanglish (Romanized Tamil) Dictionary ---
        // Grains & Flours
        TANGLISH_TO_ENGLISH.put("ARISI", "RICE");
        TANGLISH_TO_ENGLISH.put("PONNI ARISI", "PONNI RICE");
        TANGLISH_TO_ENGLISH.put("BASMATHI ARISI", "BASMATI RICE");
        TANGLISH_TO_ENGLISH.put("BASMATI ARISI", "BASMATI RICE");
        TANGLISH_TO_ENGLISH.put("PACHARISI", "RAW RICE");
        TANGLISH_TO_ENGLISH.put("PUZHUNGAL ARISI", "BOILED RICE");
        TANGLISH_TO_ENGLISH.put("GODHUMAI MAAVU", "ATTA");
        TANGLISH_TO_ENGLISH.put("GODHUMAI", "WHEAT");
        TANGLISH_TO_ENGLISH.put("MAIDHA", "MAIDA");
        TANGLISH_TO_ENGLISH.put("MAIDA", "MAIDA");
        TANGLISH_TO_ENGLISH.put("RAVAI", "RAVA");
        TANGLISH_TO_ENGLISH.put("SEMIYA", "VERMICELLI");
        TANGLISH_TO_ENGLISH.put("AVAL", "POHA");

        // Dals & Pulses
        TANGLISH_TO_ENGLISH.put("PARUPPU", "DAL");
        TANGLISH_TO_ENGLISH.put("PARUPU", "DAL");
        TANGLISH_TO_ENGLISH.put("DHAL", "DAL");
        TANGLISH_TO_ENGLISH.put("DAL", "DAL");
        TANGLISH_TO_ENGLISH.put("THUVARAM PARUPPU", "TOOR DAL");
        TANGLISH_TO_ENGLISH.put("THUVARAM PARUPU", "TOOR DAL");
        TANGLISH_TO_ENGLISH.put("THOOR DAL", "TOOR DAL");
        TANGLISH_TO_ENGLISH.put("TOOR DAL", "TOOR DAL");
        TANGLISH_TO_ENGLISH.put("THUVAREM", "TOOR DAL");
        TANGLISH_TO_ENGLISH.put("PAASI PARUPPU", "MOONG DAL");
        TANGLISH_TO_ENGLISH.put("PASI PARUPPU", "MOONG DAL");
        TANGLISH_TO_ENGLISH.put("MOONG DAL", "MOONG DAL");
        TANGLISH_TO_ENGLISH.put("ULUNTHAM PARUPPU", "URAD DAL");
        TANGLISH_TO_ENGLISH.put("ULUNTHU", "URAD DAL");
        TANGLISH_TO_ENGLISH.put("URAD DAL", "URAD DAL");
        TANGLISH_TO_ENGLISH.put("KADALAI PARUPPU", "CHANA DAL");
        TANGLISH_TO_ENGLISH.put("KADALA PARUPU", "CHANA DAL");
        TANGLISH_TO_ENGLISH.put("CHANA DAL", "CHANA DAL");
        TANGLISH_TO_ENGLISH.put("POTTUKADALAI", "ROASTED GRAM");
        TANGLISH_TO_ENGLISH.put("POTTU KADALAI", "ROASTED GRAM");
        TANGLISH_TO_ENGLISH.put("SUNDAL", "CHANA");
        TANGLISH_TO_ENGLISH.put("VERKADALAI", "PEANUTS");
        TANGLISH_TO_ENGLISH.put("NILAKADALAI", "PEANUTS");

        // Oils & Dairy
        TANGLISH_TO_ENGLISH.put("ENNAI", "OIL");
        TANGLISH_TO_ENGLISH.put("ENNAY", "OIL");
        TANGLISH_TO_ENGLISH.put("NALLENNAI", "SESAME OIL");
        TANGLISH_TO_ENGLISH.put("KADALAI ENNAI", "GROUNDNUT OIL");
        TANGLISH_TO_ENGLISH.put("SOORIYAGANDHI ENNAI", "SUNFLOWER OIL");
        TANGLISH_TO_ENGLISH.put("THENGAAI ENNAI", "COCONUT OIL");
        TANGLISH_TO_ENGLISH.put("THENGAI ENNAI", "COCONUT OIL");
        TANGLISH_TO_ENGLISH.put("NEI", "GHEE");
        TANGLISH_TO_ENGLISH.put("PAAL", "MILK");
        TANGLISH_TO_ENGLISH.put("THAYIR", "CURD");
        TANGLISH_TO_ENGLISH.put("VENNAI", "BUTTER");

        // Spices & Condiments
        TANGLISH_TO_ENGLISH.put("SARKARAI", "SUGAR");
        TANGLISH_TO_ENGLISH.put("SARKARA", "SUGAR");
        TANGLISH_TO_ENGLISH.put("CHEENI", "SUGAR");
        TANGLISH_TO_ENGLISH.put("NAATTU SARKARAI", "BROWN SUGAR");
        TANGLISH_TO_ENGLISH.put("VELLAM", "JAGGERY");
        TANGLISH_TO_ENGLISH.put("UPPU", "SALT");
        TANGLISH_TO_ENGLISH.put("THOOL UPPU", "SALT");
        TANGLISH_TO_ENGLISH.put("KAL UPPU", "CRYSTAL SALT");
        TANGLISH_TO_ENGLISH.put("MANJAL THOOL", "TURMERIC POWDER");
        TANGLISH_TO_ENGLISH.put("MANJAL", "TURMERIC");
        TANGLISH_TO_ENGLISH.put("MILAGAI THOOL", "CHILLI POWDER");
        TANGLISH_TO_ENGLISH.put("MILAGAI", "CHILLI");
        TANGLISH_TO_ENGLISH.put("MALLI THOOL", "CORIANDER POWDER");
        TANGLISH_TO_ENGLISH.put("MALLI", "CORIANDER");
        // Spices
        TANGLISH_TO_ENGLISH.put("KADUGU", "MUSTARD");
        TANGLISH_TO_ENGLISH.put("SEERAGAM", "CUMIN");
        TANGLISH_TO_ENGLISH.put("JEERAGAM", "CUMIN");
        TANGLISH_TO_ENGLISH.put("SOMBU", "FENNEL");
        TANGLISH_TO_ENGLISH.put("VENTHAYAM", "FENUGREEK");
        TANGLISH_TO_ENGLISH.put("VENDHAYAM", "FENUGREEK");
        TANGLISH_TO_ENGLISH.put("MILAGU", "BLACK PEPPER");
        TANGLISH_TO_ENGLISH.put("PERUNGAYAM", "ASAFOETIDA");
        TANGLISH_TO_ENGLISH.put("PULI", "TAMARIND");
        TANGLISH_TO_ENGLISH.put("POONDU", "GARLIC");
        TANGLISH_TO_ENGLISH.put("INJI", "GINGER");
        TANGLISH_TO_ENGLISH.put("PATTAI", "CINNAMON");
        TANGLISH_TO_ENGLISH.put("KIRAMBU", "CLOVE");
        TANGLISH_TO_ENGLISH.put("ELAKKAI", "CARDAMOM");
        TANGLISH_TO_ENGLISH.put("YELAKKAI", "CARDAMOM");

        // Veg & Fresh
        TANGLISH_TO_ENGLISH.put("VENGAYAM", "ONION");
        TANGLISH_TO_ENGLISH.put("VENKAYAM", "ONION");
        TANGLISH_TO_ENGLISH.put("CHINNA VENGAYAM", "SHALLOTS");
        TANGLISH_TO_ENGLISH.put("PERIYA VENGAYAM", "ONION");
        TANGLISH_TO_ENGLISH.put("THAKKALI", "TOMATO");
        TANGLISH_TO_ENGLISH.put("URULAI", "POTATO");
        TANGLISH_TO_ENGLISH.put("URULAIKIZHANGU", "POTATO");
        TANGLISH_TO_ENGLISH.put("THENGAI", "COCONUT");
        TANGLISH_TO_ENGLISH.put("THENGAAI", "COCONUT");
        TANGLISH_TO_ENGLISH.put("KOTHAMALLI", "CORIANDER LEAVES");
        TANGLISH_TO_ENGLISH.put("KARUVEPPILAI", "CURRY LEAVES");
        TANGLISH_TO_ENGLISH.put("PUDHINA", "MINT");
        TANGLISH_TO_ENGLISH.put("PACHAI MILAGAI", "GREEN CHILLI");

        // Beverages & Essentials
        TANGLISH_TO_ENGLISH.put("THEYILAI", "TEA");
        TANGLISH_TO_ENGLISH.put("TEA THOOL", "TEA POWDER");
        TANGLISH_TO_ENGLISH.put("COFFEE THOOL", "COFFEE POWDER");
        TANGLISH_TO_ENGLISH.put("SOAPU", "SOAP");
        TANGLISH_TO_ENGLISH.put("SOAP", "SOAP");

        // --- 3. Tamil Units Dictionary ---
        TAMIL_UNITS.put("கிலோ", "kg");
        TAMIL_UNITS.put("கிலோகிராம்", "kg");
        TAMIL_UNITS.put("கிராம்", "g");
        TAMIL_UNITS.put("லிட்டர்", "l");
        TAMIL_UNITS.put("மில்லி", "ml");
        TAMIL_UNITS.put("பாக்கெட்", "pkt");
        TAMIL_UNITS.put("எண்ணிக்கை", "pcs");
        TAMIL_UNITS.put("கட்டு", "bunch");

        SORTED_TAMIL_SCRIPT_ENTRIES = TAMIL_SCRIPT_TO_ENGLISH.entrySet().stream()
                .sorted((a, b) -> Integer.compare(b.getKey().length(), a.getKey().length()))
                .toList();

        SORTED_TANGLISH_ENTRIES = TANGLISH_TO_ENGLISH.entrySet().stream()
                .sorted((a, b) -> Integer.compare(b.getKey().length(), a.getKey().length()))
                .toList();
    }

    private static final List<Map.Entry<String, String>> SORTED_TAMIL_SCRIPT_ENTRIES;
    private static final List<Map.Entry<String, String>> SORTED_TANGLISH_ENTRIES;

    /**
     * Checks if a given text contains any Tamil script characters.
     */
    public boolean containsTamilScript(String text) {
        if (text == null || text.isBlank()) return false;
        return TAMIL_SCRIPT_PATTERN.matcher(text).find();
    }

    /**
     * Normalizes a grocery item name from Tamil or Tanglish to English canonical form.
     * If neither matches, returns null to allow downstream logic to proceed.
     */
    public TamilNormalizationResult normalizeTamilOrTanglish(String rawText) {
        if (rawText == null || rawText.trim().isEmpty()) {
            return new TamilNormalizationResult(rawText, null, null, false);
        }

        String input = rawText.trim();
        boolean hasTamilScript = containsTamilScript(input);

        // 1. Check direct Tamil Script dictionary (longer phrases match first)
        if (hasTamilScript) {
            String extractedUnit = extractTamilUnit(input);
            for (Map.Entry<String, String> entry : SORTED_TAMIL_SCRIPT_ENTRIES) {
                if (input.contains(entry.getKey())) {
                    log.debug("Recognized Tamil script '{}' -> '{}'", entry.getKey(), entry.getValue());
                    return new TamilNormalizationResult(input, entry.getValue(), extractedUnit, true);
                }
            }
        }

        // 2. Check Tanglish dictionary (longer phrases match first)
        String uppercaseClean = input.toUpperCase().replaceAll("[^A-Z0-9\\s]", " ").replaceAll("\\s+", " ").trim();
        for (Map.Entry<String, String> entry : SORTED_TANGLISH_ENTRIES) {
            // Match whole word or exact token sequence
            Pattern p = Pattern.compile("\\b" + Pattern.quote(entry.getKey()) + "\\b");
            if (p.matcher(uppercaseClean).find()) {
                log.debug("Recognized Tanglish '{}' in '{}' -> '{}'", entry.getKey(), uppercaseClean, entry.getValue());
                return new TamilNormalizationResult(input, entry.getValue(), null, true);
            }
        }

        return new TamilNormalizationResult(input, null, null, false);
    }

    /**
     * Extracts Tamil unit tokens if present.
     */
    public String extractTamilUnit(String text) {
        if (text == null) return null;
        for (Map.Entry<String, String> entry : TAMIL_UNITS.entrySet()) {
            if (text.contains(entry.getKey())) {
                return entry.getValue();
            }
        }
        return null;
    }

    public record TamilNormalizationResult(
            String originalText,
            String englishEquivalent,
            String detectedUnit,
            boolean isTamilOrTanglish
    ) {}
}
