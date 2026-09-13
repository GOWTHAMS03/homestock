package com.homestock.modules.bill.ocr;

import com.homestock.modules.bill.parser.BillParser;
import com.homestock.modules.bill.parser.ParsedBill;
import org.junit.jupiter.api.Test;

import java.io.File;
import java.nio.file.Files;

import static org.junit.jupiter.api.Assertions.*;

class DefaultOcrProviderTest {

    @Test
    void testWindowsOcrOnReceiptImageIfExists() throws Exception {
        DefaultOcrProvider provider = new DefaultOcrProvider();
        BillParser parser = new BillParser();

        File sampleFile = new File("C:/Users/GowthamSekar/.gemini/antigravity-ide/brain/13e8fe6b-264e-4512-8088-068da30dbe44/.user_uploaded/media_1789222217513.jpg");
        if (!sampleFile.exists()) {
            return;
        }

        byte[] bytes = Files.readAllBytes(sampleFile.toPath());
        OcrResult result = provider.extractText(bytes, "image/jpeg");

        assertNotNull(result);
        assertFalse(result.getFullText().isEmpty());
        // Verify that binary garbage (like Exif, 1pp<) is NOT in the OCR result
        assertFalse(result.getFullText().contains("1pp<"));
        assertFalse(result.getFullText().contains("lExif"));

        // Verify that real store details are extracted
        assertTrue(result.getFullText().contains("Sri Balaji") || result.getFullText().contains("Balaji"),
                "Should extract Sri Balaji store header");
        assertTrue(result.getFullText().contains("Ponni") || result.getFullText().contains("Rice"),
                "Should extract Ponni Raw Rice item");

        // Parse with BillParser
        ParsedBill bill = parser.parse(result.getFullText());
        assertNotNull(bill);
        assertTrue(bill.getShopName().contains("Balaji") || bill.getShopName().contains("Super Market"));
        assertTrue(bill.getItems().size() >= 10, "Should extract at least 10 items from OCR");
    }
}
