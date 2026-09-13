package com.homestock.modules.bill.parser;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.LocalDate;

import static org.junit.jupiter.api.Assertions.*;

class SriBalajiBillParserTest {

    private BillParser billParser;

    @BeforeEach
    void setUp() {
        billParser = new BillParser();
    }

    @Test
    void testParseSriBalajiSuperMarketReceipt() {
        String receiptText = """
                Sri Balaji Super Market
                No. 12, Main Road, Anna Nagar, Better Products
                Chennai - 600040 Better Life
                GSTIN: 33ABCDE1234FIZ5
                Bill No SM2509090123 Store Main Branch
                Date 09-09-2025 Mode Cash
                Ti me 04:32 PM
                Cashier Ramesh
                No Item Name Qty Rate (0 Amount (0
                1 Ponni Raw Rice 5 kg 58.00 290.00
                2 Toor Dal 1 kg 120.00 120.00
                3 Sunflower Oil (IL) 1 Itr 165.00 165.00
                4 Aashirvaad Atta 265.00 265.00
                5 Sugar 1 kg 42 . 00 42 .00
                6 Salt 1 kg 20.00 20.00
                7 Turmeric Powder 100 g 30.00 30.00
                8 Red Chilli Powder 100 g 45.00 45.00
                9 Onion 2 kg 28.00 56 . 00
                10 Tomato I kg 32.00 32.00
                11 Potato 2 kg 20.00 40.00
                12 Green Chilli 250 g 40.00 10.00
                Sub Total 1, 115.00
                Discount 15.00
                CGST (2.5%) . 27.75
                SGST (2.5%) . 27.75
                Total 1,155.50
                Payment Mode Cash
                Amount Paid 1,155.50
                Balance 0.00
                Thank you for shopping with us!
                Visit Again!
                """;

        ParsedBill bill = billParser.parse(receiptText);

        assertNotNull(bill);
        assertEquals("Sri Balaji Super Market", bill.getShopName());
        assertEquals("SM2509090123", bill.getBillNumber());
        assertEquals(LocalDate.of(2025, 9, 9), bill.getBillDate());

        assertEquals(new BigDecimal("1115.00"), bill.getSubtotal());
        assertEquals(new BigDecimal("15.00"), bill.getDiscount());
        assertEquals(new BigDecimal("55.50"), bill.getTax()); // 27.75 + 27.75
        assertEquals(new BigDecimal("1155.50"), bill.getTotal());

        assertEquals(12, bill.getItems().size(), "Should extract exactly 12 items");

        // 1: Ponni Raw Rice 5 kg 58.00 290.00
        ParsedBillItem i1 = bill.getItems().get(0);
        assertEquals("Ponni Raw Rice", i1.getName());
        assertEquals(new BigDecimal("5"), i1.getQuantity());
        assertEquals("kg", i1.getUnit());
        assertEquals(new BigDecimal("58.00"), i1.getUnitPrice());
        assertEquals(new BigDecimal("290.00"), i1.getFinalPrice());

        // 2: Toor Dal 1 kg 120.00 120.00
        ParsedBillItem i2 = bill.getItems().get(1);
        assertEquals("Toor Dal", i2.getName());
        assertEquals(new BigDecimal("1"), i2.getQuantity());
        assertEquals("kg", i2.getUnit());
        assertEquals(new BigDecimal("120.00"), i2.getUnitPrice());
        assertEquals(new BigDecimal("120.00"), i2.getFinalPrice());

        // 3: Sunflower Oil (IL) 1 Itr 165.00 165.00
        ParsedBillItem i3 = bill.getItems().get(2);
        assertTrue(i3.getName().contains("Sunflower Oil"));
        assertEquals(new BigDecimal("1"), i3.getQuantity());
        assertEquals("ltr", i3.getUnit());
        assertEquals(new BigDecimal("165.00"), i3.getUnitPrice());
        assertEquals(new BigDecimal("165.00"), i3.getFinalPrice());

        // 4: Aashirvaad Atta 265.00 265.00
        ParsedBillItem i4 = bill.getItems().get(3);
        assertEquals("Aashirvaad Atta", i4.getName());
        assertEquals(new BigDecimal("265.00"), i4.getUnitPrice());
        assertEquals(new BigDecimal("265.00"), i4.getFinalPrice());

        // 5: Sugar 1 kg 42 . 00 42 .00
        ParsedBillItem i5 = bill.getItems().get(4);
        assertEquals("Sugar", i5.getName());
        assertEquals(new BigDecimal("1"), i5.getQuantity());
        assertEquals("kg", i5.getUnit());
        assertEquals(new BigDecimal("42.00"), i5.getUnitPrice());
        assertEquals(new BigDecimal("42.00"), i5.getFinalPrice());

        // 6: Salt 1 kg 20.00 20.00
        ParsedBillItem i6 = bill.getItems().get(5);
        assertEquals("Salt", i6.getName());
        assertEquals(new BigDecimal("1"), i6.getQuantity());
        assertEquals("kg", i6.getUnit());
        assertEquals(new BigDecimal("20.00"), i6.getUnitPrice());
        assertEquals(new BigDecimal("20.00"), i6.getFinalPrice());

        // 7: Turmeric Powder 100 g 30.00 30.00
        ParsedBillItem i7 = bill.getItems().get(6);
        assertEquals("Turmeric Powder", i7.getName());
        assertEquals(new BigDecimal("100"), i7.getQuantity());
        assertEquals("g", i7.getUnit());
        assertEquals(new BigDecimal("30.00"), i7.getUnitPrice());
        assertEquals(new BigDecimal("30.00"), i7.getFinalPrice());

        // 8: Red Chilli Powder 100 g 45.00 45.00
        ParsedBillItem i8 = bill.getItems().get(7);
        assertEquals("Red Chilli Powder", i8.getName());
        assertEquals(new BigDecimal("100"), i8.getQuantity());
        assertEquals("g", i8.getUnit());
        assertEquals(new BigDecimal("45.00"), i8.getUnitPrice());
        assertEquals(new BigDecimal("45.00"), i8.getFinalPrice());

        // 9: Onion 2 kg 28.00 56 . 00
        ParsedBillItem i9 = bill.getItems().get(8);
        assertEquals("Onion", i9.getName());
        assertEquals(new BigDecimal("2"), i9.getQuantity());
        assertEquals("kg", i9.getUnit());
        assertEquals(new BigDecimal("28.00"), i9.getUnitPrice());
        assertEquals(new BigDecimal("56.00"), i9.getFinalPrice());

        // 10: Tomato I kg 32.00 32.00
        ParsedBillItem i10 = bill.getItems().get(9);
        assertEquals("Tomato", i10.getName());
        assertEquals(new BigDecimal("1"), i10.getQuantity());
        assertEquals("kg", i10.getUnit());
        assertEquals(new BigDecimal("32.00"), i10.getUnitPrice());
        assertEquals(new BigDecimal("32.00"), i10.getFinalPrice());

        // 11: Potato 2 kg 20.00 40.00
        ParsedBillItem i11 = bill.getItems().get(10);
        assertEquals("Potato", i11.getName());
        assertEquals(new BigDecimal("2"), i11.getQuantity());
        assertEquals("kg", i11.getUnit());
        assertEquals(new BigDecimal("20.00"), i11.getUnitPrice());
        assertEquals(new BigDecimal("40.00"), i11.getFinalPrice());

        // 12: Green Chilli 250 g 40.00 10.00
        ParsedBillItem i12 = bill.getItems().get(11);
        assertEquals("Green Chilli", i12.getName());
        assertEquals(new BigDecimal("250"), i12.getQuantity());
        assertEquals("g", i12.getUnit());
        assertEquals(new BigDecimal("40.00"), i12.getUnitPrice());
        assertEquals(new BigDecimal("10.00"), i12.getFinalPrice());
    }
}
