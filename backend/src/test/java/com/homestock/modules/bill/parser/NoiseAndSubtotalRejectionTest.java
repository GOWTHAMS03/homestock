package com.homestock.modules.bill.parser;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.*;

class NoiseAndSubtotalRejectionTest {

    private BillParser billParser;

    @BeforeEach
    void setUp() {
        billParser = new BillParser();
    }

    @Test
    void testRejectsCorruptedSubtotalTotalAndTaxLinesFromItems() {
        String receipt = """
                Reliance SM
                Bill # 123456
                Date: 07 Sep 2026
                -----------------------------------
                Fortune Sunflower Oil 1L 1 130.00 130.00
                Aashirvaad Atta 5kg 1 240.00 240.00
                Tata Salt 1kg 1 28.00 28.00
                Amul Butter 500g 1 275.00 275.00
                Maggi Noodles 1 136.00 136.00
                -su\uFFFDotal 809.00
                Gsu2s%y 20.00
                Tota - 819.00
                -----------------------------------
                """;

        ParsedBill bill = billParser.parse(receipt);

        assertNotNull(bill);
        assertEquals("Reliance SM", bill.getShopName());
        assertEquals("123456", bill.getBillNumber());

        // Verify subtotal, tax, and total are recognized from the degraded lines
        assertEquals(new BigDecimal("809.00"), bill.getSubtotal());
        assertEquals(new BigDecimal("20.00"), bill.getTax());
        assertEquals(new BigDecimal("819.00"), bill.getTotal());

        // Verify that none of "-suotal", "Gsu2s%y", or "Tota -" were added as items
        boolean hasFakeSubtotal = bill.getItems().stream().anyMatch(i -> i.getName().toLowerCase().contains("su") && i.getName().toLowerCase().contains("tal"));
        assertFalse(hasFakeSubtotal, "Subtotal line must not be added as an item");

        boolean hasFakeTax = bill.getItems().stream().anyMatch(i -> i.getName().contains("%") || i.getName().toLowerCase().contains("gsu"));
        assertFalse(hasFakeTax, "Tax line with % must not be added as an item");

        boolean hasFakeTotal = bill.getItems().stream().anyMatch(i -> i.getName().toLowerCase().contains("tota"));
        assertFalse(hasFakeTotal, "Total line must not be added as an item");

        // Exactly 5 genuine grocery items
        assertEquals(5, bill.getItems().size());
    }
}
