package com.homestock.modules.smartshopping.service;

import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Map;

/**
 * Handles unit conversion and normalization for product comparison.
 * <p>
 * Ensures that "1 kg" and "1000 g" are treated as equivalent,
 * and prevents incorrect comparisons between "5 kg Rice" and "1 kg Rice".
 */
@Service
public class UnitNormalizationService {

    /**
     * Conversion factors to base units.
     * Base units: g (mass), ml (volume), pcs (count)
     */
    private static final Map<String, UnitMapping> UNIT_MAP = Map.ofEntries(
            // Mass
            Map.entry("kg",    new UnitMapping("g",   new BigDecimal("1000"))),
            Map.entry("g",     new UnitMapping("g",   BigDecimal.ONE)),
            Map.entry("mg",    new UnitMapping("g",   new BigDecimal("0.001"))),

            // Volume
            Map.entry("l",     new UnitMapping("ml",  new BigDecimal("1000"))),
            Map.entry("L",     new UnitMapping("ml",  new BigDecimal("1000"))),
            Map.entry("ml",    new UnitMapping("ml",  BigDecimal.ONE)),
            Map.entry("litre", new UnitMapping("ml",  new BigDecimal("1000"))),
            Map.entry("liter", new UnitMapping("ml",  new BigDecimal("1000"))),
            Map.entry("liters",new UnitMapping("ml",  new BigDecimal("1000"))),
            Map.entry("litres",new UnitMapping("ml",  new BigDecimal("1000"))),

            // Count
            Map.entry("pcs",   new UnitMapping("pcs", BigDecimal.ONE)),
            Map.entry("pack",  new UnitMapping("pcs", BigDecimal.ONE)),
            Map.entry("box",   new UnitMapping("pcs", BigDecimal.ONE)),
            Map.entry("bottle",new UnitMapping("pcs", BigDecimal.ONE)),
            Map.entry("dozen", new UnitMapping("pcs", new BigDecimal("12"))),
            Map.entry("unit",  new UnitMapping("pcs", BigDecimal.ONE)),
            Map.entry("units", new UnitMapping("pcs", BigDecimal.ONE)),
            Map.entry("piece", new UnitMapping("pcs", BigDecimal.ONE)),
            Map.entry("pieces",new UnitMapping("pcs", BigDecimal.ONE))
    );

    /**
     * Normalize a quantity to its base unit.
     *
     * @param quantity the original quantity
     * @param unit     the original unit string
     * @return normalized result with base unit and converted quantity
     */
    public NormalizedUnit normalize(BigDecimal quantity, String unit) {
        if (unit == null || quantity == null) {
            return new NormalizedUnit(quantity != null ? quantity : BigDecimal.ONE, unit != null ? unit : "pcs");
        }

        String cleanUnit = unit.trim().toLowerCase();
        UnitMapping mapping = UNIT_MAP.get(cleanUnit);

        if (mapping == null) {
            // Unknown unit — return as-is
            return new NormalizedUnit(quantity, cleanUnit);
        }

        BigDecimal normalizedQty = quantity.multiply(mapping.factor);
        return new NormalizedUnit(normalizedQty, mapping.baseUnit);
    }

    /**
     * Check whether two units are in the same measurement family.
     *
     * @return true if both units can be compared (e.g. kg vs g)
     */
    public boolean areUnitsComparable(String unit1, String unit2) {
        if (unit1 == null || unit2 == null) return false;

        NormalizedUnit n1 = normalize(BigDecimal.ONE, unit1);
        NormalizedUnit n2 = normalize(BigDecimal.ONE, unit2);

        return n1.baseUnit.equals(n2.baseUnit);
    }

    /**
     * Calculate price per standard unit (e.g. per kg, per L).
     *
     * @param price    product price
     * @param quantity product quantity
     * @param unit     product unit
     * @return price per standard unit, or null if calculation is not possible
     */
    public PricePerUnit calculatePricePerUnit(BigDecimal price, BigDecimal quantity, String unit) {
        if (price == null || quantity == null || unit == null || quantity.compareTo(BigDecimal.ZERO) == 0) {
            return null;
        }

        String cleanUnit = unit.trim().toLowerCase();
        NormalizedUnit normalized = normalize(quantity, cleanUnit);

        // Determine display unit (per kg, per L, per unit)
        String displayUnit;
        BigDecimal divisor;

        switch (normalized.baseUnit) {
            case "g":
                displayUnit = "kg";
                divisor = new BigDecimal("1000");
                break;
            case "ml":
                displayUnit = "L";
                divisor = new BigDecimal("1000");
                break;
            default:
                displayUnit = "unit";
                divisor = BigDecimal.ONE;
                break;
        }

        // price per base unit * conversion to display unit
        BigDecimal pricePerBaseUnit = price.divide(normalized.quantity, 6, RoundingMode.HALF_UP);
        BigDecimal pricePerDisplayUnit = pricePerBaseUnit.multiply(divisor).setScale(2, RoundingMode.HALF_UP);

        return new PricePerUnit(pricePerDisplayUnit, displayUnit, "₹" + pricePerDisplayUnit + "/" + displayUnit);
    }

    /**
     * Parse package size string like "5 kg" or "500 ml" into quantity and unit.
     */
    public PackageSize parsePackageSize(String packageSizeStr) {
        if (packageSizeStr == null || packageSizeStr.isBlank()) {
            return null;
        }

        String cleaned = packageSizeStr.trim();

        // Try to split by spaces or between number and letter
        String[] parts = cleaned.split("\\s+", 2);
        if (parts.length == 2) {
            try {
                BigDecimal qty = new BigDecimal(parts[0]);
                return new PackageSize(qty, parts[1].trim());
            } catch (NumberFormatException ignored) {}
        }

        // Try regex: "500ml", "5kg"
        java.util.regex.Matcher m = java.util.regex.Pattern.compile("^([\\d.]+)\\s*([a-zA-Z]+)$").matcher(cleaned);
        if (m.matches()) {
            try {
                BigDecimal qty = new BigDecimal(m.group(1));
                return new PackageSize(qty, m.group(2).trim());
            } catch (NumberFormatException ignored) {}
        }

        return null;
    }

    // ──── Result records ────

    public record NormalizedUnit(BigDecimal quantity, String baseUnit) {}

    public record PricePerUnit(BigDecimal price, String unit, String label) {}

    public record PackageSize(BigDecimal quantity, String unit) {}

    private record UnitMapping(String baseUnit, BigDecimal factor) {}
}
