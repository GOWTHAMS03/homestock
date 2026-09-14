package com.homestock.modules.voice.service;

import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.HashMap;
import java.util.Map;

@Service("voiceUnitNormalizationService")
public class UnitNormalizationService {

    public enum UnitDimension {
        MASS,
        VOLUME,
        COUNT,
        UNKNOWN
    }

    private static final Map<String, String> UNIT_MAP = new HashMap<>();
    private static final Map<String, UnitDimension> DIMENSION_MAP = new HashMap<>();

    static {
        // Kilograms
        register("KG", UnitDimension.MASS, "kg", "kgs", "kilo", "kilos", "kilogram", "kilograms", "கிலோ", "கிகி");
        // Litres
        register("L", UnitDimension.VOLUME, "l", "ltr", "ltrs", "litre", "litres", "liter", "liters", "litru", "லிட்டர்", "லி");
        // Millilitres
        register("ML", UnitDimension.VOLUME, "ml", "mls", "millilitre", "millilitres", "milliliter", "milliliters", "மில்லி", "மில்லிலிட்டர்");
        // Grams
        register("G", UnitDimension.MASS, "g", "gm", "gms", "gram", "grams", "கிராம்");
        // Pieces
        register("PCS", UnitDimension.COUNT, "pcs", "pc", "piece", "pieces", "item", "items", "பீஸ்", "எண்ணிக்கை", "piece-u");
        // Packets
        register("PACK", UnitDimension.COUNT, "pack", "packs", "packet", "packets", "பாக்கெட்", "பாக்", "pocket", "packets-u");
        // Bottles
        register("BOTTLE", UnitDimension.COUNT, "bottle", "bottles", "பாட்டில்", "bottilu");
        // Cans
        register("CAN", UnitDimension.COUNT, "can", "cans", "கேன்");
        // Boxes
        register("BOX", UnitDimension.COUNT, "box", "boxes", "பாக்ஸ்");
    }

    private static void register(String canonical, UnitDimension dimension, String... aliases) {
        DIMENSION_MAP.put(canonical, dimension);
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

    public UnitDimension getDimension(String unit) {
        if (unit == null || unit.isBlank()) return UnitDimension.UNKNOWN;
        String canonical = normalize(unit);
        return DIMENSION_MAP.getOrDefault(canonical, UnitDimension.UNKNOWN);
    }

    public boolean areCompatible(String unitA, String unitB) {
        if (unitA == null || unitB == null) return false;
        String canA = normalize(unitA);
        String canB = normalize(unitB);
        if (canA.equalsIgnoreCase(canB)) return true;

        UnitDimension dimA = getDimension(canA);
        UnitDimension dimB = getDimension(canB);
        return dimA != UnitDimension.UNKNOWN && dimA == dimB;
    }

    /**
     * Converts quantity from source unit to target unit safely within the same measurement dimension.
     * Throws IllegalArgumentException if attempting cross-dimensional conversion (e.g. Mass to Volume).
     */
    public BigDecimal convert(BigDecimal quantity, String fromUnit, String toUnit) {
        if (quantity == null) return null;
        if (fromUnit == null || toUnit == null) return quantity;

        String normFrom = normalize(fromUnit);
        String normTo = normalize(toUnit);

        if (normFrom.equalsIgnoreCase(normTo)) {
            return quantity;
        }

        UnitDimension dimFrom = getDimension(normFrom);
        UnitDimension dimTo = getDimension(normTo);

        if (dimFrom == UnitDimension.UNKNOWN || dimTo == UnitDimension.UNKNOWN || dimFrom != dimTo) {
            throw new IllegalArgumentException(String.format(
                    "Unsafe unit conversion: Cannot convert between %s (%s) and %s (%s)",
                    dimFrom, normFrom, dimTo, normTo
            ));
        }

        // MASS conversions
        if (dimFrom == UnitDimension.MASS) {
            if ("G".equalsIgnoreCase(normFrom) && "KG".equalsIgnoreCase(normTo)) {
                return quantity.divide(BigDecimal.valueOf(1000), 4, RoundingMode.HALF_UP).stripTrailingZeros();
            }
            if ("KG".equalsIgnoreCase(normFrom) && "G".equalsIgnoreCase(normTo)) {
                return quantity.multiply(BigDecimal.valueOf(1000)).stripTrailingZeros();
            }
        }

        // VOLUME conversions
        if (dimFrom == UnitDimension.VOLUME) {
            if ("ML".equalsIgnoreCase(normFrom) && "L".equalsIgnoreCase(normTo)) {
                return quantity.divide(BigDecimal.valueOf(1000), 4, RoundingMode.HALF_UP).stripTrailingZeros();
            }
            if ("L".equalsIgnoreCase(normFrom) && "ML".equalsIgnoreCase(normTo)) {
                return quantity.multiply(BigDecimal.valueOf(1000)).stripTrailingZeros();
            }
        }

        // COUNT conversions (PCS, PACK, etc. are 1:1 unless pack size is explicitly modeled)
        if (dimFrom == UnitDimension.COUNT) {
            return quantity;
        }

        return quantity;
    }
}

