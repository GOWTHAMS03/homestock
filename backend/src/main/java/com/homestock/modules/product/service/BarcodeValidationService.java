package com.homestock.modules.product.service;

import org.springframework.stereotype.Service;

import java.util.regex.Pattern;

@Service
public class BarcodeValidationService {

    private static final Pattern NUMERIC_PATTERN = Pattern.compile("^\\d+$");
    private static final Pattern SCANNER_PREFIX_PATTERN = Pattern.compile("^(?:\\][A-Za-z0-9]{2}|(?:EAN[-_]?13|EAN[-_]?8|UPC[-_]?A|UPC[-_]?E|CODE[-_]?128)[:\\s]+)", Pattern.CASE_INSENSITIVE);

    public String normalizeBarcode(String rawBarcode) {
        if (rawBarcode == null) {
            return "";
        }
        String cleaned = rawBarcode.trim();
        // Strip scanner AIM identifiers or format prefixes
        cleaned = SCANNER_PREFIX_PATTERN.matcher(cleaned).replaceFirst("");
        // Remove spaces and hyphens
        cleaned = cleaned.replaceAll("[\\s\\-_]+", "").trim();
        return cleaned;
    }

    public String detectBarcodeType(String barcode) {
        if (barcode == null || barcode.isBlank()) {
            return "UNKNOWN";
        }
        if (!NUMERIC_PATTERN.matcher(barcode).matches()) {
            // Non-numeric could be Code 128, Code 39, QR Code
            if (barcode.startsWith("http://") || barcode.startsWith("https://") || barcode.length() > 30) {
                return "QR_CODE";
            }
            return "CODE_128";
        }

        return switch (barcode.length()) {
            case 8 -> "EAN_8";
            case 12 -> "UPC_A";
            case 13 -> "EAN_13";
            case 14 -> "ITF_14";
            case 6, 7 -> "UPC_E";
            default -> "CODE_128";
        };
    }

    public boolean isValid(String barcode) {
        if (barcode == null || barcode.isBlank()) {
            return false;
        }
        String normalized = normalizeBarcode(barcode);
        if (normalized.length() < 3 || normalized.length() > 50) {
            return false;
        }

        String type = detectBarcodeType(normalized);
        return switch (type) {
            case "EAN_13" -> validateEan13Checksum(normalized);
            case "EAN_8" -> validateEan8Checksum(normalized);
            case "UPC_A" -> validateUpcAChecksum(normalized);
            default -> true; // Standard retail/internal code format
        };
    }

    public boolean validateEan13Checksum(String barcode) {
        if (barcode == null || barcode.length() != 13 || !NUMERIC_PATTERN.matcher(barcode).matches()) {
            return false;
        }
        int sum = 0;
        for (int i = 0; i < 12; i++) {
            int digit = Character.getNumericValue(barcode.charAt(i));
            // 0-indexed: index 0 (1st digit) weight 1, index 1 (2nd digit) weight 3
            sum += (i % 2 == 0) ? digit : digit * 3;
        }
        int checksum = (10 - (sum % 10)) % 10;
        return checksum == Character.getNumericValue(barcode.charAt(12));
    }

    public boolean validateEan8Checksum(String barcode) {
        if (barcode == null || barcode.length() != 8 || !NUMERIC_PATTERN.matcher(barcode).matches()) {
            return false;
        }
        int sum = 0;
        for (int i = 0; i < 7; i++) {
            int digit = Character.getNumericValue(barcode.charAt(i));
            // 0-indexed: index 0 (1st digit) weight 3, index 1 (2nd digit) weight 1
            sum += (i % 2 == 0) ? digit * 3 : digit;
        }
        int checksum = (10 - (sum % 10)) % 10;
        return checksum == Character.getNumericValue(barcode.charAt(7));
    }

    public boolean validateUpcAChecksum(String barcode) {
        if (barcode == null || barcode.length() != 12 || !NUMERIC_PATTERN.matcher(barcode).matches()) {
            return false;
        }
        int sum = 0;
        for (int i = 0; i < 11; i++) {
            int digit = Character.getNumericValue(barcode.charAt(i));
            // 0-indexed: index 0 (1st digit) weight 3, index 1 (2nd digit) weight 1
            sum += (i % 2 == 0) ? digit * 3 : digit;
        }
        int checksum = (10 - (sum % 10)) % 10;
        return checksum == Character.getNumericValue(barcode.charAt(11));
    }
}
