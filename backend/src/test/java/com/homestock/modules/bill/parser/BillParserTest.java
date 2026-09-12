package com.homestock.modules.bill.parser;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.LocalDate;

import static org.junit.jupiter.api.Assertions.*;

class BillParserTest {

    private BillParser billParser;

    @BeforeEach
    void setUp() {
        billParser = new BillParser();
    }

    @Test
    void testParseDmartSupermarketBill() {
        String receipt = """
                DMART - AVENUE SUPERMARTS LTD
                BRANCH: WHITEFIELD MAIN ROAD, BANGALORE
                GSTIN: 29AABCA1234F1Z5
                INVOICE NO: INV-2026-98124
                DATE: 12/09/2026  TIME: 14:32
                ----------------------------------------
                ITEM DESCRIPTION       QTY   RATE   AMOUNT
                ----------------------------------------
                AASHIRVAAD ATTA 5KG     1    245.00  245.00
                FORTUNE SUNFLOWER OIL 1L 2   130.00  260.00
                TATA SALT 1KG           1     28.00   28.00
                AMUL BUTTER 500G        1    275.00  275.00
                SURF EXCEL EASY WASH 1KG 1   140.00  140.00
                ----------------------------------------
                SUB TOTAL:                           948.00
                DISCOUNT SAVINGS:                     48.00
                CGST 2.5%:                            12.50
                SGST 2.5%:                            12.50
                GRAND TOTAL:                         925.00
                ----------------------------------------
                THANK YOU! VISIT AGAIN
                """;

        ParsedBill bill = billParser.parse(receipt);

        assertNotNull(bill);
        assertTrue(bill.getShopName().toUpperCase().contains("DMART"));
        assertEquals("INV-2026-98124", bill.getBillNumber());
        assertEquals(LocalDate.of(2026, 9, 12), bill.getBillDate());
        assertEquals(new BigDecimal("925.00"), bill.getTotal());
        assertEquals(new BigDecimal("48.00"), bill.getDiscount());
        assertEquals(5, bill.getItems().size());

        ParsedBillItem item1 = bill.getItems().get(0);
        assertTrue(item1.getName().toUpperCase().contains("AASHIRVAAD"));
        assertEquals(new BigDecimal("1"), item1.getQuantity());
        assertEquals(new BigDecimal("245.00"), item1.getFinalPrice());

        ParsedBillItem item2 = bill.getItems().get(1);
        assertTrue(item2.getName().toUpperCase().contains("FORTUNE SUNFLOWER OIL"));
        assertEquals(new BigDecimal("2"), item2.getQuantity());
        assertEquals(new BigDecimal("130.00"), item2.getUnitPrice());
        assertEquals(new BigDecimal("260.00"), item2.getFinalPrice());
    }

    @Test
    void testParseRelianceSmartMultilineReceipt() {
        String receipt = """
                RELIANCE RETAIL LIMITED
                SMART BAZAAR - INDIRANAGAR
                BILL NO: RBL/045812
                DATE: 10-09-2026
                
                DAAWAT ROZANA BASMATI RICE
                  1.000 KG @ 110.00                     110.00
                NESTLE MAGGI NOODLES 4PKT
                  2.000 PCS @ 56.00                     112.00
                EVEREST TURMERIC POWDER 200G
                  1.000 PCS @ 45.00                      45.00
                
                TOTAL ITEMS: 3
                TOTAL SAVINGS: 25.00
                NET AMOUNT: Rs. 267.00
                """;

        ParsedBill bill = billParser.parse(receipt);

        assertNotNull(bill);
        assertTrue(bill.getShopName().toUpperCase().contains("RELIANCE"));
        assertEquals("RBL/045812", bill.getBillNumber());
        assertEquals(LocalDate.of(2026, 9, 10), bill.getBillDate());
        assertEquals(new BigDecimal("267.00"), bill.getTotal());
        assertEquals(3, bill.getItems().size());

        ParsedBillItem rice = bill.getItems().stream()
                .filter(i -> i.getName().toUpperCase().contains("BASMATI"))
                .findFirst()
                .orElse(null);
        assertNotNull(rice);
        assertEquals(new BigDecimal("1.000"), rice.getQuantity());
        assertEquals(new BigDecimal("110.00"), rice.getFinalPrice());
    }

    @Test
    void testParseKiranaCashMemo() {
        String receipt = """
                SRI LAKSHMI PROVISION STORE
                CASH BILL / MEMO
                NO: 842  DATE: 11/09/2026
                
                SUGAR 2KG                       84.00
                TOOR DAL 1KG                   160.00
                JEERA 100G                      45.00
                
                TOTAL AMOUNT:                  289.00
                """;

        ParsedBill bill = billParser.parse(receipt);

        assertNotNull(bill);
        assertTrue(bill.getShopName().toUpperCase().contains("LAKSHMI"));
        assertEquals("842", bill.getBillNumber());
        assertEquals(new BigDecimal("289.00"), bill.getTotal());
        assertEquals(3, bill.getItems().size());
    }
}
