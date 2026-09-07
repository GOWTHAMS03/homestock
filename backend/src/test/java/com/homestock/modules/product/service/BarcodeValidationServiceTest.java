package com.homestock.modules.product.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class BarcodeValidationServiceTest {

    private BarcodeValidationService service;

    @BeforeEach
    void setUp() {
        service = new BarcodeValidationService();
    }

    @Test
    @DisplayName("Should normalize barcodes with whitespaces, hyphens, and scanner prefixes")
    void testNormalizeBarcode() {
        assertEquals("8901030000000", service.normalizeBarcode("  8901030000000  "));
        assertEquals("8901030000000", service.normalizeBarcode("890-103-000000-0"));
        assertEquals("8901030000000", service.normalizeBarcode("]E08901030000000"));
        assertEquals("8901030000000", service.normalizeBarcode("EAN-13: 8901030000000"));
    }

    @Test
    @DisplayName("Should detect correct barcode types")
    void testDetectBarcodeType() {
        assertEquals("EAN_13", service.detectBarcodeType("8901030000000"));
        assertEquals("EAN_8", service.detectBarcodeType("96385074"));
        assertEquals("UPC_A", service.detectBarcodeType("012345678905"));
        assertEquals("CODE_128", service.detectBarcodeType("ITEM-ALPHA-123"));
        assertEquals("QR_CODE", service.detectBarcodeType("https://homestock.app/item/123"));
    }

    @Test
    @DisplayName("Should validate valid EAN-13 checksums correctly")
    void testValidateEan13Checksum() {
        // Known valid Indian grocery retail barcodes
        assertTrue(service.validateEan13Checksum("8901030000003")); // Tata Salt
        assertTrue(service.validateEan13Checksum("8901725181222")); // Aashirvaad Atta
        assertTrue(service.validateEan13Checksum("8906007280013")); // Fortune Oil

        // Invalid checksum
        assertFalse(service.validateEan13Checksum("8901030000001"));
        assertFalse(service.validateEan13Checksum("12345"));
    }

    @Test
    @DisplayName("Should validate valid EAN-8 checksums correctly")
    void testValidateEan8Checksum() {
        assertTrue(service.validateEan8Checksum("96385074"));
        assertFalse(service.validateEan8Checksum("96385070"));
    }

    @Test
    @DisplayName("Should validate valid UPC-A checksums correctly")
    void testValidateUpcAChecksum() {
        assertTrue(service.validateUpcAChecksum("012345678905"));
        assertFalse(service.validateUpcAChecksum("012345678900"));
    }
}
