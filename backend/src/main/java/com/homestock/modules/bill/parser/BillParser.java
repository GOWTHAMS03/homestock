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
            Pattern.compile("(?i)(?:bill\\s*(?:no|num|number|#)?|invoice\\s*(?:no|num|number|#)?|inv\\s*no|receipt\\s*#?|#)\\s*[:\\-\\.]?\\s*([A-Za-z0-9\\/\\-_]+)"),
            Pattern.compile("(?i)(?:token|order\\s*id|trans(?:action)?\\s*id)\\s*[:\\-]?\\s*([A-Za-z0-9\\/\\-_]+)")
    );

    // Quantity x Rate pattern (e.g. "2 x 145.00", "1.000 KG @ 110.00", "2 * 145.00")
    private static final Pattern QTY_RATE_PATTERN = Pattern.compile(
            "(\\d+(?:\\.\\d+)?)\\s*(?:KG|KGS|G|GM|GMS|L|LTR|LTRS|ML|PCS|PKT|PACK)?\\s*(?:x|\\*|@)\\s*(\\d+(?:\\.\\d+)?)(?:\\s*=?\\s*(\\d+(?:\\.\\d+)?))?",
            Pattern.CASE_INSENSITIVE
    );

    // Tabular Item with Unit: "1 Ponni Raw Rice 5 kg 58.00 290.00" or "Green Chilli 250 g 40.00 10.00"
    private static final Pattern TABULAR_WITH_UNIT = Pattern.compile(
            "^(?:(\\d{1,3})[\\.\\)]?\\s+)?(.+?)\\s+([0-9]+(?:\\.[0-9]+)?)\\s*(kg|kgs|g|gm|gms|l|ltr|ltrs|ml|pcs|pkt|pack)\\s+([0-9]+(?:\\.[0-9]{2})?)\\s+([0-9]+(?:\\.[0-9]{2})?)$",
            Pattern.CASE_INSENSITIVE
    );

    // Tabular Item with Qty, Rate, Amount (no unit): "1 Item Name 2 50.00 100.00"
    private static final Pattern TABULAR_WITHOUT_UNIT = Pattern.compile(
            "^(?:(\\d{1,3})[\\.\\)]?\\s+)?(.+?)\\s+([0-9]+(?:\\.[0-9]+)?)\\s+([0-9]+(?:\\.[0-9]{2})?)\\s+([0-9]+(?:\\.[0-9]{2})?)$"
    );

    // Tabular Item with Rate & Amount (matching or single price): "4 Aashirvaad Atta 265.00 265.00"
    private static final Pattern TABULAR_RATE_AMOUNT = Pattern.compile(
            "^(?:(\\d{1,3})[\\.\\)]?\\s+)?(.+?)\\s+([0-9]+(?:\\.[0-9]{2})?)\\s+([0-9]+(?:\\.[0-9]{2})?)$"
    );

    // Single price at end of line: "NAME ... 150.00"
    private static final Pattern LINE_SINGLE_PRICE = Pattern.compile(
            "^(?:(\\d{1,3})[\\.\\)]?\\s+)?(.+?)\\s+([0-9]{1,6}\\.[0-9]{2})\\s*$"
    );

    // Non-item line keywords to ignore
    private static final Set<String> NON_ITEM_KEYWORDS = Set.of(
            "SUBTOTAL", "SUB TOTAL", "NET TOTAL", "GRAND TOTAL", "TAX", "GST", "CGST", "SGST",
            "IGST", "CASH", "CARD", "CHANGE", "ROUND OFF", "SAVINGS", "DISCOUNT", "TENDER",
            "THANK YOU", "VISIT AGAIN", "TERMS", "CONDITIONS", "ITEMS COUNT",
            "GSTIN", "FSSAI", "CIN", "TEL", "PHONE", "EMAIL", "ADDRESS", "INVOICE", "CASHIER",
            "PAYMENT MODE", "AMOUNT PAID", "BALANCE"
    );

    public ParsedBill parse(String rawOcrText) {
        String safeText = rawOcrText != null
                ? rawOcrText.replace("\u0000", "").replaceAll("[\\x00-\\x08\\x0B\\x0C\\x0E-\\x1F]", "").trim()
                : "";

        if (safeText.isEmpty()) {
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

        List<String> rawLines = Arrays.stream(safeText.split("\\r?\\n"))
                .map(this::normalizeOcrLine)
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

            // Check for Subtotal
            if (isSubtotalLine(line)) {
                BigDecimal val = extractAmountFromLine(line);
                if (val != null) subtotal = val;
                continue;
            }
            // Check for Grand / Final Total
            if (isTotalLine(line)) {
                BigDecimal val = extractAmountFromLine(line);
                if (val != null && (total == null || val.compareTo(total) > 0)) total = val;
                continue;
            }
            // Check for Taxes (CGST, SGST, IGST, etc.)
            if (isTaxLine(line)) {
                BigDecimal val = extractAmountFromLine(line);
                if (val != null) tax = tax.add(val);
                continue;
            }
            // Check for Discounts / Savings
            if (isDiscountLine(line)) {
                BigDecimal val = extractAmountFromLine(line);
                if (val != null) discount = discount.add(val.abs());
                continue;
            }

            // Skip non-item lines (header/footer metadata)
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

        // Post-filter: purge any lines that accidentally passed through as items but are totals/taxes
        List<ParsedBillItem> validItems = items.stream()
                .filter(item -> {
                    String name = item.getName();
                    if (!isValidItemName(name)) return false;
                    if (isSubtotalLine(name) || isTotalLine(name) || isTaxLine(name) || isDiscountLine(name)) return false;
                    return true;
                })
                .toList();

        // Calculate totals if not explicitly found in receipt text
        BigDecimal calculatedTotal = validItems.stream()
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
            billNumber = "BILL-" + Math.abs(Objects.hash(shopName, billDate, total, validItems.size()));
        }

        return ParsedBill.builder()
                .shopName(shopName)
                .billDate(billDate != null ? billDate : LocalDate.now())
                .billNumber(billNumber)
                .items(validItems)
                .subtotal(subtotal)
                .tax(tax)
                .discount(discount)
                .total(total)
                .rawText(rawOcrText)
                .build();
    }

    private boolean isSubtotalLine(String line) {
        if (line == null) return false;
        String clean = line.toUpperCase().replaceAll("[^A-Z0-9%]", " ").replaceAll("\\s+", " ").trim();
        return clean.matches(".*\\bSUB\\s*TOT[A-Z0-9]*\\b.*")
                || clean.matches(".*\\bSUBTOT[A-Z0-9]*\\b.*")
                || clean.matches(".*\\bSU\\s*OT[A-Z0-9]*\\b.*")
                || clean.matches(".*\\bSU\\s*TOT[A-Z0-9]*\\b.*")
                || clean.matches(".*\\bNET\\s*TOTAL\\b.*")
                || clean.startsWith("SUB")
                || clean.contains("SUBTOTAL")
                || clean.contains("SUB TOTAL");
    }

    private boolean isTotalLine(String line) {
        if (line == null || isSubtotalLine(line)) return false;
        String clean = line.toUpperCase().replaceAll("[^A-Z0-9%]", " ").replaceAll("\\s+", " ").trim();
        return clean.matches(".*\\bGRAND\\s*TOT[A-Z0-9]*\\b.*")
                || clean.matches(".*\\b(?:TOTAL|NET)\\s*AMOUNT\\b.*")
                || clean.matches("^TOT[A-Z0-9]*\\b.*")
                || clean.matches(".*\\bTOT[A-Z0-9]*\\s*\\d+.*")
                || clean.matches(".*\\bFINAL\\s*TOTAL\\b.*");
    }

    private boolean isTaxLine(String line) {
        if (line == null) return false;
        String upper = line.toUpperCase();
        if (upper.contains("GSTIN")) return false; // Merchant GST registration number, not tax amount
        if (upper.contains("TAX") || upper.contains("CGST") || upper.contains("SGST") ||
            upper.contains("IGST") || upper.contains("VAT") || upper.contains("CESS") ||
            upper.matches(".*\\bGST\\b.*")) {
            return true;
        }
        return upper.contains("%") || upper.matches(".*\\bGS[TU0-9].*%.*");
    }

    private boolean isDiscountLine(String line) {
        if (line == null) return false;
        String upper = line.toUpperCase();
        return upper.contains("DISCOUNT") || upper.contains("SAVINGS") ||
               upper.contains("SCHEME") || upper.contains("OFFER") || upper.contains("COUPON") ||
               upper.matches(".*\\bLESS\\b.*");
    }

    private String normalizeOcrLine(String line) {
        if (line == null) return "";
        String s = sanitize(line);
        s = s.replace("\uFFFD", ""); // Remove unicode replacement char

        // Fix decimal places with space: "42 . 00" -> "42.00"
        s = s.replaceAll("(\\d+)\\s*\\.\\s*(\\d{2})", "$1.$2");

        // Fix thousands comma with space: "1, 115.00" -> "1115.00", "1,155.50" -> "1155.50"
        s = s.replaceAll("(\\d+)\\s*,\\s*(\\d{3}(?:\\.\\d{2})?)", "$1$2");
        s = s.replaceAll("(\\d+),(\\d{3}(?:\\.\\d{2})?)", "$1$2");

        // Clean OCR currency symbol artifacts: "(0 Amount", "Rate (0"
        s = s.replaceAll("(?i)\\bRate\\s*\\([0O₹]\\b", "Rate");
        s = s.replaceAll("(?i)\\bAmount\\s*\\([0O₹]\\b", "Amount");
        s = s.replaceAll("[₹€$]", "");

        // Fix OCR quantity character confusions: "I kg" -> "1 kg", "l Itr" -> "1 ltr"
        s = s.replaceAll("(?<=\\s|^)[Il|](\\s*(?:kg|kgs|g|gm|gms|l|ltr|ltrs|ml|pcs|pkt|pack)\\b)", "1$1");
        s = s.replaceAll("(?i)\\bItr\\b", "ltr");

        return s.trim();
    }

    private record ItemParseResult(ParsedBillItem item, int linesConsumed) {}

    private ItemParseResult tryParseItem(List<String> lines, int index) {
        String line = lines.get(index);
        if (line.length() < 3) return null;

        // Pattern 1: Multi-line with next line "Qty x Rate"
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

        // Pattern 2: Tabular with explicit unit: "1 Ponni Raw Rice 5 kg 58.00 290.00" or "Green Chilli 250 g 40.00 10.00"
        Matcher unitMatch = TABULAR_WITH_UNIT.matcher(line);
        if (unitMatch.find()) {
            String rawName = unitMatch.group(2).trim();
            if (isValidItemName(rawName)) {
                try {
                    BigDecimal qty = new BigDecimal(unitMatch.group(3));
                    String unit = unitMatch.group(4).toLowerCase();
                    BigDecimal rate = new BigDecimal(unitMatch.group(5));
                    BigDecimal finalPrice = new BigDecimal(unitMatch.group(6));

                    String cleanName = cleanItemName(rawName);

                    ParsedBillItem item = ParsedBillItem.builder()
                            .name(cleanName)
                            .quantity(qty)
                            .unit(unit)
                            .unitPrice(rate)
                            .mrp(rate)
                            .finalPrice(finalPrice)
                            .build();
                    return new ItemParseResult(item, 1);
                } catch (Exception ignored) {}
            }
        }

        // Pattern 3: Tabular without unit: "1 Item Name 2 50.00 100.00"
        Matcher noUnitMatch = TABULAR_WITHOUT_UNIT.matcher(line);
        if (noUnitMatch.find()) {
            String rawName = noUnitMatch.group(2).trim();
            if (isValidItemName(rawName)) {
                try {
                    BigDecimal qty = new BigDecimal(noUnitMatch.group(3));
                    BigDecimal rate = new BigDecimal(noUnitMatch.group(4));
                    BigDecimal finalPrice = new BigDecimal(noUnitMatch.group(5));

                    String cleanName = cleanItemName(rawName);
                    String unit = detectUnit(cleanName);

                    ParsedBillItem item = ParsedBillItem.builder()
                            .name(cleanName)
                            .quantity(qty)
                            .unit(unit)
                            .unitPrice(rate)
                            .mrp(rate)
                            .finalPrice(finalPrice)
                            .build();
                    return new ItemParseResult(item, 1);
                } catch (Exception ignored) {}
            }
        }

        // Pattern 4: Tabular rate & amount only: "4 Aashirvaad Atta 265.00 265.00"
        Matcher rateAmountMatch = TABULAR_RATE_AMOUNT.matcher(line);
        if (rateAmountMatch.find()) {
            String rawName = rateAmountMatch.group(2).trim();
            if (isValidItemName(rawName)) {
                try {
                    BigDecimal p1 = new BigDecimal(rateAmountMatch.group(3));
                    BigDecimal p2 = new BigDecimal(rateAmountMatch.group(4));

                    String cleanName = cleanItemName(rawName);
                    String unit = detectUnit(cleanName);
                    BigDecimal qty = extractQuantityFromItemName(cleanName);

                    BigDecimal unitPrice = p1;
                    BigDecimal finalPrice = p2;

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
        }

        // Pattern 5: Single price line: "NAME ... 150.00"
        Matcher singleMatch = LINE_SINGLE_PRICE.matcher(line);
        if (singleMatch.find()) {
            String rawName = singleMatch.group(2).trim();
            if (isValidItemName(rawName)) {
                try {
                    BigDecimal finalPrice = new BigDecimal(singleMatch.group(3));
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
        }

        return null;
    }

    private boolean isValidItemName(String name) {
        if (name == null || name.length() < 2) return false;
        String upper = name.toUpperCase().trim();

        // Reject any name that matches subtotal, total, tax, or discount lines
        if (isSubtotalLine(upper) || isTotalLine(upper) || isTaxLine(upper) || isDiscountLine(upper)) {
            return false;
        }

        for (String kw : NON_ITEM_KEYWORDS) {
            if (upper.equals(kw) || upper.startsWith(kw + " ") || upper.endsWith(" " + kw)) {
                return false;
            }
        }

        // Disallow table headers like "ITEM NAME", "QTY RATE AMOUNT"
        if (upper.contains("ITEM NAME") || upper.contains("QTY RATE") || upper.contains("NO ITEM") ||
            upper.contains("DESCRIPTION") || upper.contains("PARTICULARS")) {
            return false;
        }

        // Must contain at least 2 alphabetic letters
        long letterCount = name.chars().filter(Character::isLetter).count();
        if (letterCount < 2) return false;

        // Any % sign in item name is a tax/discount indicator, not a product
        if (name.contains("%")) return false;

        return true;
    }

    private boolean isNonItemHeaderOrFooter(String line) {
        if (isSubtotalLine(line) || isTotalLine(line) || isTaxLine(line) || isDiscountLine(line)) {
            return true;
        }
        String upper = line.toUpperCase().trim();
        if (upper.startsWith("NO ") && upper.contains("ITEM") && (upper.contains("QTY") || upper.contains("RATE"))) {
            return true;
        }
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
        cleaned = cleaned.replaceAll("^[0-9]{8,14}\\s+", ""); // strip leading barcode
        cleaned = cleaned.replaceAll("^[-_\\.\\s:]+", ""); // strip leading punctuation like "-"
        cleaned = cleaned.replaceAll("[-_\\.\\s:]+$", ""); // strip trailing punctuation
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
        // Dynamically inspect receipt header lines to extract the business / store name
        for (int i = 0; i < Math.min(5, lines.size()); i++) {
            String candidate = lines.get(i).trim();
            if (candidate.length() < 3 || candidate.length() > 80) continue;

            String upper = candidate.toUpperCase();

            // Skip lines containing typical invoice metadata, dates, or cashier info
            if (upper.startsWith("BILL") || upper.startsWith("INV") || upper.startsWith("DATE") ||
                upper.startsWith("TIME") || upper.startsWith("CASHIER") || upper.startsWith("TOKEN") ||
                upper.startsWith("ORDER") || upper.startsWith("RECEIPT") || upper.startsWith("TAX INVOICE") ||
                upper.startsWith("CASH MEMO") || upper.startsWith("CASH BILL")) {
                continue;
            }

            // Skip tax identifiers and contact lines
            if (upper.startsWith("GSTIN") || upper.startsWith("FSSAI") || upper.startsWith("CIN") ||
                upper.startsWith("TEL") || upper.startsWith("PHONE") || upper.startsWith("EMAIL") ||
                upper.startsWith("WEBSITE") || upper.startsWith("WWW.")) {
                continue;
            }

            // Skip address lines (door numbers, streets, roads, pin codes)
            if (upper.matches(".*\\b(?:NO\\.?\\s*\\d+|ROAD|STREET|NAGAR|LANE|FLOOR|DOOR|OPP|NEAR|CHENNAI|BANGALORE|MUMBAI|DELHI|\\d{6})\\b.*")) {
                continue;
            }

            // Skip greetings and generic taglines
            if (upper.equals("WELCOME") || upper.startsWith("WELCOME TO") ||
                upper.contains("THANK YOU") || upper.contains("VISIT AGAIN")) {
                continue;
            }

            // Must contain at least 3 alphabetic letters and be a valid name
            long letterCount = candidate.chars().filter(Character::isLetter).count();
            if (letterCount >= 3 && isValidShopName(candidate)) {
                return candidate;
            }
        }

        return "Retail Store";
    }

    private boolean isValidShopName(String name) {
        if (name == null) return false;
        String s = sanitize(name);
        if (s.length() < 3 || s.length() > 80) return false;
        long letters = s.chars().filter(Character::isLetter).count();
        if (letters < 3) return false;
        return s.chars().allMatch(c -> Character.isLetterOrDigit(c) || Character.isWhitespace(c) || ".-'&,/()".indexOf(c) != -1);
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
        // Pass 1: Explicit bill/invoice/receipt/token patterns
        for (String line : lines) {
            for (Pattern p : BILL_NO_PATTERNS) {
                Matcher m = p.matcher(line);
                if (m.find()) {
                    String num = sanitize(m.group(1).trim());
                    if (num.length() >= 2 && num.length() <= 50) {
                        return num;
                    }
                }
            }
        }

        // Pass 2: Generic "No: 123" on non-address lines
        Pattern genericNo = Pattern.compile("(?i)\\bno\\s*[:\\-\\.]\\s*([A-Za-z0-9\\/\\-_]+)");
        for (String line : lines) {
            String upper = line.toUpperCase();
            if (upper.contains("ROAD") || upper.contains("STREET") || upper.contains("NAGAR") ||
                upper.contains("LANE") || upper.contains("FLOOR") || upper.contains("NEAR") ||
                upper.contains("OPP") || upper.contains("MAIN") || upper.contains("ADDRESS")) {
                continue;
            }
            Matcher m = genericNo.matcher(line);
            if (m.find()) {
                String num = sanitize(m.group(1).trim());
                if (num.length() >= 2 && num.length() <= 50) {
                    return num;
                }
            }
        }
        return null;
    }

    private BigDecimal extractAmountFromLine(String line) {
        if (line == null) return null;
        String cleaned = line.replace(",", "").replaceAll("(\\d+)\\s*\\.\\s*(\\d{2})", "$1.$2");
        Matcher m = Pattern.compile("([0-9]+(?:\\.[0-9]{2})?)").matcher(cleaned);
        BigDecimal last = null;
        while (m.find()) {
            try {
                last = new BigDecimal(m.group(1));
            } catch (Exception ignored) {}
        }
        return last;
    }

    private String sanitize(String input) {
        if (input == null) return "";
        return input.replace("\u0000", "").replaceAll("[\\x00-\\x08\\x0B\\x0C\\x0E-\\x1F]", "").trim();
    }
}

