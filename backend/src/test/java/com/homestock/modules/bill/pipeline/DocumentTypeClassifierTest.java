package com.homestock.modules.bill.pipeline;

import com.homestock.modules.bill.entity.DocumentType;
import com.homestock.modules.bill.matching.TamilNormalizationService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

class DocumentTypeClassifierTest {

    private DocumentTypeClassifier classifier;

    @BeforeEach
    void setUp() {
        TamilNormalizationService tamilService = new TamilNormalizationService();
        classifier = new DocumentTypeClassifier(tamilService);
    }

    @Test
    void testPrintedBillHeuristicClassification() {
        String printedBill = """
                RELIANCE RETAIL LIMITED
                GSTIN: 33AAACR1234F1Z5
                TAX INVOICE / BILL NO: 104928
                DATE: 2026-03-12
                CASHIER: RAJESH
                AASHIRVAAD ATTA 5KG   1   245.00
                TOTAL AMOUNT: 245.00
                THANK YOU VISIT AGAIN
                """;

        var result = classifier.classify(null, null, printedBill, List.of(printedBill.split("\n")));
        assertNotNull(result);
        assertEquals(DocumentType.PRINTED, result.getDocumentType());
        assertFalse(result.isHasTamil());
        assertTrue(result.getConfidence() >= 0.80);
    }

    @Test
    void testTamilHandwrittenNoteHeuristicClassification() {
        String tamilNote = """
                அரிசி 5 கிலோ
                துவரம்பருப்பு 1 கிலோ
                சர்க்கரை 2 கிலோ
                எண்ணெய் 1 பாக்கெட்
                """;

        var result = classifier.classify(null, null, tamilNote, List.of(tamilNote.split("\n")));
        assertNotNull(result);
        assertEquals(DocumentType.HANDWRITTEN, result.getDocumentType());
        assertTrue(result.isHasTamil());
    }

    @Test
    void testMixedBillHeuristicClassification() {
        String mixedDoc = """
                SUPER BAZAAR
                GSTIN: 33AABC1234A1Z1
                INVOICE: 4410
                AMUL BUTTER 100G  55.00
                Handwritten addition at bottom:
                அரிசி 1 கிலோ
                """;

        var result = classifier.classify(null, null, mixedDoc, List.of(mixedDoc.split("\n")));
        assertNotNull(result);
        assertEquals(DocumentType.MIXED, result.getDocumentType());
        assertTrue(result.isHasTamil());
    }
}
