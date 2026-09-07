package com.homestock.modules.voice.service;

import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;

@Service
public class UnitNormalizationService {

    private static final Map<String, String> UNIT_MAP = new HashMap<>();

    static {
        // Kilograms
        register("KG", "kg", "kgs", "kilo", "kilos", "kilogram", "kilograms", "கிலோ", "கிகி");
        // Litres
        register("L", "l", "ltr", "ltrs", "litre", "litres", "liter", "liters", "litru", "லிட்டர்", "லி");
        // Millilitres
        register("ML", "ml", "mls", "millilitre", "millilitres", "milliliter", "milliliters", "மில்லி", "மில்லிலிட்டர்");
        // Grams
        register("G", "g", "gm", "gms", "gram", "grams", "கிராம்");
        // Pieces
        register("PCS", "pcs", "pc", "piece", "pieces", "item", "items", "பீஸ்", "எண்ணிக்கை", "piece-u");
        // Packets
        register("PACK", "pack", "packs", "packet", "packets", "பாக்கெட்", "பாக்", "pocket", "packets-u");
        // Bottles
        register("BOTTLE", "bottle", "bottles", "பாட்டில்", "bottilu");
        // Cans
        register("CAN", "can", "cans", "கேன்");
        // Boxes
        register("BOX", "box", "boxes", "பாக்ஸ்");
    }

    private static void register(String canonical, String... aliases) {
        for (String alias : aliases) {
            UNIT_MAP.put(alias.toLowerCase(), canonical);
        }
    }

    public String normalize(String rawUnit) {
        if (rawUnit == null || rawUnit.isBlank()) {
            return "PCS";
        }
        String cleaned = rawUnit.trim().toLowerCase()
                .replaceAll("[.,;:]", "");
        return UNIT_MAP.getOrDefault(cleaned, rawUnit.toUpperCase());
    }

    public boolean isUnit(String word) {
        if (word == null || word.isBlank()) return false;
        String cleaned = word.trim().toLowerCase().replaceAll("[.,;:]", "");
        return UNIT_MAP.containsKey(cleaned);
    }
}
