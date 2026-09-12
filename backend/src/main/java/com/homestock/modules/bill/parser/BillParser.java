package com.homestock.modules.bill.parser;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeFormatterBuilder;
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Service
public class BillParser {

    private static final Logger log = LoggerFactory.getLogger(BillParser.class);

    // Known supermarket patterns
    private static final List<String> KNOWN_SHOPS = List.of(
            "D-MART", "DMART", "AVENUE SUPERMARTS",
            "RELIANCE FRESH", "RELIANCE SMART", "RELIANCE RETAIL",
            "MORE RETAIL", "MORE SUPERMARKET",
            "SPENCER'S", "SPENCERS RETAIL",
            "NATURE'S BASKET", "BIG BAZAAR", "SMART BAZAAR",
            "RATNADEEP", "LULU HYPERMARKET", "ZEPTO", "BLINKIT", "INSTAMART",
            "LOCAL KIRANA", "PROVISION STORE", "SUPER MARKET"
    );

    // Date regex patterns
    private static final List<Pattern> DATE_PATTERNS = List.of(
            Pattern.compile("(?i)(?:date|bill\\s*date|inv(?:oice)?\\s*date)\\s*[:\\-]?\\s*(\\d{1,2}[\\/\\-\\.]\\d{1,2}[\\/\\-\\.]\\d{2,4})"),
            Pattern.compile("(?i)(?:date|bill\\s*date|inv(?:oice)?\\s*date)\\s*[:\\-]?\\s*(\\d{1,2}[\\/\\-\\s][A-Za-z]{3}[\\/\\-\\s]\\d{2,4})"),
            Pattern.compile("(\\d{1,2}[\\/\\-\\.]\\d{1,2}[\\/\\-\\.]\\d{4})"),
            Pattern.compile("(\\d{4}[\\/\\-\\.]\\d{1,2}[\\/\\-\\.]\\d{1,2})"),
            Pattern.compile("(\\d{1,2}[\\/\\-\\s][A-Za-z]{3}[\\/\\-\\s]\\d{4})")
    );

    // Invoice/Bill number patterns
    private static final List<Pattern> BILL_NO_PATTERNS = List.of(
            Pattern.compile("(?i)(?:bill\\s*(?:no|num|number)|invoice\\s*(?:no|num|number)|inv\\s*no|receipt\\s*#?|\\bno)\\s*[:\\-\\.]?\\s*([A-Za-z0-9\\/\\-_]+)"),
            Pattern.compile("(?i)(?:token|order\\s*id|trans(?:action)?\\s*id)\\s*[:\\-]?\\s*([A-Za-z0-9\\/\\-_]+)")
    );

    // Quantity x Rate pattern (e.g. "2 x 145.00", "1.000 KG @ 110.00", "2 * 145.00")
    private static final Pattern QTY_RATE_PATTERN = Pattern.compile(
            "(\\d+(?:\\.\\d+)?)\\s*(?:KG|KGS|G|GM|GMS|L|LTR|LTRS|ML|PCS|PKT|PACK)?\\s*(?:x|\\*|@)\\s*(\\d+(?:\\.\\d+)?)(?:\\s*=?\\s*(\\d+(?:\\.\\d+)?))?",
            Pattern.CASE_INSENSITIVE
    );

    // Standard item line ending with prices: "NAME ... QTY RATE AMOUNT" or "NAME ... AMOUNT"
    private static final Pattern LINE_WITH_PRICES = Pattern.compile(
            "^(.+?)\\s+(\\d+(?:\\.\\d+)?)\\s+(\\d+(?:\\.\\d+)?)(?:\\s+(\\d+(?:\\.\\d+)?))?\\s*$"
    );

    // Single price at end of line: "NAME ... 150.00"
    private static final Pattern LINE_SINGLE_PRICE = Pattern.compile(
            "^(.+?)\\s+([0-9]{1,6}\\.[0-9]{2})\\s*$"
    );

    // Non-item line keywords to ignore
    private static final Set<String> NON_ITEM_KEYWORDS = Set.of(
            "TOTAL", "SUBTOTAL", "SUB TOTAL", "NET TOTAL", "GRAND TOTAL", "TAX", "GST", "CGST", "SGST",
            "IGST", "CASH", "CARD", "CHANGE", "ROUND OFF", "SAVINGS", "DISCOUNT", "TENDER",
            "THANK YOU", "VISIT AGAIN", "TERMS", "CONDITIONS", "ITEMS COUNT", "QTY", "RATE", "AMOUNT",
            "GSTIN", "FSSAI", "CIN", "TEL", "PHONE", "EMAIL", "ADDRESS", "INVOICE", "BILL", "CASHIER"
    );

    public ParsedBill parse(String rawOcrText) {
        if (rawOcrText == null || rawOcrText.trim().isEmpty()) {
            return ParsedBill.builder()
                    .shopName("Local Store")
                    .billDate(LocalDate.now())
                    .billNumber("BILL-" + System.currentTimeMillis())
                    .items(new ArrayList<>())
                    .subtotal(BigDecimal.ZERO)
                    .tax(BigDecimal.ZERO)
                    .discount(BigDecimal.ZERO)
                    .total(BigDecimal.ZERO)
                    .rawText("")
                    .build();
        }

        List<String> rawLines = Arrays.stream(rawOcrText.split("\\r?\\n"))
                .map(String::trim)
                .filter(l -> !l.isEmpty())
                .toList();

        String shopName = extractShopName(rawLines);
        LocalDate billDate = extractDate(rawLines);
        String billNumber = extractBillNumber(rawLines);

        BigDecimal subtotal = null;
        BigDecimal tax = BigDecimal.ZERO;
        BigDecimal discount = BigDecimal.ZERO;
        BigDecimal total = null;

        List<ParsedBillItem> items = new ArrayList<>();

        for (int i = 0; i < rawLines.size(); i++) {
            String line = rawLines.get(i);
            String upper = line.toUpperCase();

            // Check for Totals and Taxes
            if (upper.contains("SUB TOTAL") || upper.contains("SUBTOTAL") || upper.contains("NET TOTAL")) {
                BigDecimal val = extractAmountFromLine(line);
                if (val != null) subtotal = val;
                continue;
            }
            if (upper.startsWith("TOTAL") || upper.contains("GRAND TOTAL") || upper.contains("NET AMOUNT") || upper.contains("TOTAL AMOUNT")) {
                BigDecimal val = extractAmountFromLine(line);
                if (val != null && (total == null || val.compareTo(total) > 0)) total = val;
                continue;
            }
            if (upper.contains("TAX") || upper.contains("CGST") || upper.contains("SGST") || upper.contains("IGST")) {
                BigDecimal val = extractAmountFromLine(line);
                if (val != null) tax = tax.add(val);
                continue;
            }
            if (upper.contains("DISCOUNT") || upper.contains("SAVINGS") || upper.contains("SCHEME")) {
                BigDecimal val = extractAmountFromLine(line);
                if (val != null) discount = discount.add(val.abs());
                continue;
            }

            // Skip non-item lines
            if (isNonItemHeaderOrFooter(line)) {
                continue;
            }

            // Attempt to parse item from this line (and possibly next line for "Qty x Rate")
            ItemParseResult res = tryParseItem(rawLines, i);
            if (res != null) {
                items.add(res.item());
                if (res.linesConsumed() > 1) {
                    i += (res.linesConsumed() - 1);
                }
            }
        }

        // Calculate totals if not explicitly found in receipt text
        BigDecimal calculatedTotal = items.stream()
                .map(ParsedBillItem::getFinalPrice)
                .filter(Objects::nonNull)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        if (total == null || total.compareTo(BigDecimal.ZERO) == 0) {
            total = calculatedTotal.add(tax).subtract(discount);
            if (total.compareTo(BigDecimal.ZERO) < 0) total = calculatedTotal;
        }

        if (subtotal == null) {
            subtotal = calculatedTotal;
        }

        if (billNumber == null || billNumber.isEmpty()) {
            billNumber = "BILL-" + Math.abs(Objects.hash(shopName, billDate, total, items.size()));
        }

        return ParsedBill.builder()
                .shopName(shopName)
                .billDate(billDate != null ? billDate : LocalDate.now())
                .billNumber(billNumber)
                .items(items)
                .subtotal(subtotal)
                .tax(tax)
                .discount(discount)
                .total(total)
                .rawText(rawOcrText)
                .build();
    }

    private record ItemParseResult(ParsedBillItem item, int linesConsumed) {}

    private ItemParseResult tryParseItem(List<String> lines, int index) {
        String line = lines.get(index);
        if (line.length() < 3) return null;

        // Check if next line contains "Qty x Rate" (Multi-line item pattern)
        if (index + 1 < lines.size()) {
            String nextLine = lines.get(index + 1);
            Matcher qtyRateMatch = QTY_RATE_PATTERN.matcher(nextLine);
            if (qtyRateMatch.find()) {
                try {
                    BigDecimal qty = new BigDecimal(qtyRateMatch.group(1));
                    BigDecimal rate = new BigDecimal(qtyRateMatch.group(2));
                    BigDecimal finalPrice = (qtyRateMatch.group(3) != null)
                            ? new BigDecimal(qtyRateMatch.group(3))
                            : qty.multiply(rate).setScale(2, RoundingMode.HALF_UP);

                    String cleanName = cleanItemName(line);
                    String unit = detectUnit(cleanName);

                    ParsedBillItem item = ParsedBillItem.builder()
                            .name(cleanName)
                            .quantity(qty)
                            .unit(unit)
                            .unitPrice(rate)
                            .mrp(rate)
                            .finalPrice(finalPrice)
                            .build();
                    return new ItemParseResult(item, 2);
                } catch (Exception ignored) {}
            }
        }

        // Layout: "NAME ... QTY RATE AMOUNT"
        Matcher match = LINE_WITH_PRICES.matcher(line);
        if (match.find()) {
            String rawName = match.group(1).trim();
            if (!isValidItemName(rawName)) return null;

            try {
                BigDecimal p1 = new BigDecimal(match.group(2));
                BigDecimal p2 = new BigDecimal(match.group(3));
                String g4 = match.group(4);

                BigDecimal qty;
                BigDecimal unitPrice;
                BigDecimal finalPrice;

                if (g4 != null) {
                    // 3 numbers: Qty, Rate, Amount
                    qty = p1;
                    unitPrice = p2;
                    finalPrice = new BigDecimal(g4);
                } else {
                    // 2 numbers: could be Qty & Amount or Rate & Amount
                    if (p1.compareTo(BigDecimal.valueOf(100)) <= 0 && p1.scale() <= 3) {
                        qty = p1;
                        finalPrice = p2;
                        unitPrice = qty.compareTo(BigDecimal.ZERO) > 0
                                ? finalPrice.divide(qty, 2, RoundingMode.HALF_UP)
                                : finalPrice;
                    } else {
                        qty = BigDecimal.ONE;
                        unitPrice = p1;
                        finalPrice = p2;
                    }
                }

                String cleanName = cleanItemName(rawName);
                String unit = detectUnit(cleanName);

                ParsedBillItem item = ParsedBillItem.builder()
                        .name(cleanName)
                        .quantity(qty)
                        .unit(unit)
                        .unitPrice(unitPrice)
                        .mrp(unitPrice)
                        .finalPrice(finalPrice)
                        .build();
                return new ItemParseResult(item, 1);
            } catch (Exception ignored) {}
        }

        // Layout: "NAME ... 150.00" (single price)
        Matcher singleMatch = LINE_SINGLE_PRICE.matcher(line);
        if (singleMatch.find()) {
            String rawName = singleMatch.group(1).trim();
            if (!isValidItemName(rawName)) return null;

            try {
                BigDecimal finalPrice = new BigDecimal(singleMatch.group(2));
                String cleanName = cleanItemName(rawName);
                String unit = detectUnit(cleanName);
                BigDecimal qty = extractQuantityFromItemName(cleanName);

                BigDecimal unitPrice = qty.compareTo(BigDecimal.ZERO) > 0
                        ? finalPrice.divide(qty, 2, RoundingMode.HALF_UP)
                        : finalPrice;

                ParsedBillItem item = ParsedBillItem.builder()
                        .name(cleanName)
                        .quantity(qty)
                        .unit(unit)
                        .unitPrice(unitPrice)
                        .mrp(unitPrice)
                        .finalPrice(finalPrice)
                        .build();
                return new ItemParseResult(item, 1);
            } catch (Exception ignored) {}
        }

        return null;
    }

    private boolean isValidItemName(String name) {
        if (name == null || name.length() < 2) return false;
        String upper = name.toUpperCase();
        for (String kw : NON_ITEM_KEYWORDS) {
            if (upper.equals(kw) || upper.startsWith(kw + " ") || upper.endsWith(" " + kw)) {
                return false;
            }
        }
        // Must contain at least one letter
        return name.matches(".*[a-zA-Z].*");
    }

    private boolean isNonItemHeaderOrFooter(String line) {
        String upper = line.toUpperCase().trim();
        for (String kw : NON_ITEM_KEYWORDS) {
            if (upper.contains(kw) && !upper.matches(".*\\d+.*(?:KG|L|GM|ML).*")) {
                return true;
            }
        }
        return false;
    }

    private String cleanItemName(String raw) {
        // Strip leading item numbers or codes (e.g. "1. ", "01 ", "8901030383123 ")
        String cleaned = raw.replaceAll("^[0-9]{1,4}[\\.\\)]\\s*", "");
        cleaned = cleaned.replaceAll("^[0-9]{8,14}\\s+", ""); // strip leading barcode if any
        return cleaned.trim();
    }

    private String detectUnit(String name) {
        String upper = name.toUpperCase();
        if (upper.matches(".*\\b(?:KG|KGS|KILO|KILOS)\\b.*")) return "kg";
        if (upper.matches(".*\\b(?:G|GM|GMS|GRAM|GRAMS)\\b.*")) return "g";
        if (upper.matches(".*\\b(?:L|LTR|LTRS|LITRE|LITRES|LITER)\\b.*")) return "l";
        if (upper.matches(".*\\b(?:ML|MILLILITRE)\\b.*")) return "ml";
        if (upper.matches(".*\\b(?:PKT|PACKET|PACKETS|PACK|PC|PCS|PIECE|PIECES|BOTTLE|BOX)\\b.*")) return "pcs";
        return "pcs";
    }

    private BigDecimal extractQuantityFromItemName(String name) {
        Matcher m = Pattern.compile("(\\d+(?:\\.\\d+)?)\\s*(?:KG|L|LTR|G|GM|ML|PKT|PCS)", Pattern.CASE_INSENSITIVE).matcher(name);
        if (m.find()) {
            try {
                BigDecimal extracted = new BigDecimal(m.group(1));
                if (extracted.compareTo(BigDecimal.ZERO) > 0) return extracted;
            } catch (Exception ignored) {}
        }
        return BigDecimal.ONE;
    }

    private String extractShopName(List<String> lines) {
        // First check for known shops
        for (String line : lines) {
            String upper = line.toUpperCase();
            for (String shop : KNOWN_SHOPS) {
                if (upper.contains(shop)) {
                    if (shop.contains("DMART") || shop.contains("D-MART") || shop.contains("AVENUE")) return "DMart";
                    if (shop.contains("RELIANCE")) return "Reliance Retail";
                    if (shop.contains("MORE")) return "More Supermarket";
                    if (shop.contains("SPENCER")) return "Spencer's";
                    if (shop.contains("BIG BAZAAR") || shop.contains("SMART BAZAAR")) return "Smart Bazaar";
                    if (shop.contains("NATURE")) return "Nature's Basket";
                    return line.trim();
                }
            }
        }

        // Fallback: pick the first non-trivial line from top that isn't a generic header
        for (int i = 0; i < Math.min(5, lines.size()); i++) {
            String candidate = lines.get(i).trim();
            if (candidate.length() >= 3 && !isNonItemHeaderOrFooter(candidate) && !candidate.matches(".*\\d{5,}.*")) {
                return candidate;
            }
        }
        return "Supermarket Store";
    }

    private LocalDate extractDate(List<String> lines) {
        for (String line : lines) {
            for (Pattern p : DATE_PATTERNS) {
                Matcher m = p.matcher(line);
                if (m.find()) {
                    String dateStr = m.group(1).trim().replaceAll("\\s+", "-");
                    LocalDate parsed = parseDateString(dateStr);
                    if (parsed != null) return parsed;
                }
            }
        }
        return LocalDate.now();
    }

    private LocalDate parseDateString(String dateStr) {
        List<String> formats = List.of(
                "dd/MM/yyyy", "d/M/yyyy", "dd-MM-yyyy", "d-M-yyyy", "dd.MM.yyyy",
                "yyyy-MM-dd", "yyyy/MM/dd",
                "dd-MMM-yyyy", "d-MMM-yyyy", "dd/MMM/yyyy"
        );

        for (String fmt : formats) {
            try {
                DateTimeFormatter formatter = new DateTimeFormatterBuilder()
                        .parseCaseInsensitive()
                        .appendPattern(fmt)
                        .toFormatter(Locale.ENGLISH);
                return LocalDate.parse(dateStr, formatter);
            } catch (Exception ignored) {}
        }
        return null;
    }

    private String extractBillNumber(List<String> lines) {
        for (String line : lines) {
            for (Pattern p : BILL_NO_PATTERNS) {
                Matcher m = p.matcher(line);
                if (m.find()) {
                    return m.group(1).trim();
                }
            }
        }
        return null;
    }

    private BigDecimal extractAmountFromLine(String line) {
        Matcher m = Pattern.compile("([0-9]{1,6}(?:\\.[0-9]{2})?)").matcher(line);
        BigDecimal last = null;
        while (m.find()) {
            try {
                last = new BigDecimal(m.group(1));
            } catch (Exception ignored) {}
        }
        return last;
    }
}
