package com.homestock;

import com.homestock.core.security.UserPrincipal;
import com.homestock.modules.auth.dto.RegisterRequest;
import com.homestock.modules.auth.service.AuthService;
import com.homestock.modules.bill.dto.*;
import com.homestock.modules.bill.entity.ProductPriceHistory;
import com.homestock.modules.bill.entity.PurchasedBill;
import com.homestock.modules.bill.repository.ProductPriceHistoryRepository;
import com.homestock.modules.bill.repository.PurchasedBillRepository;
import com.homestock.modules.bill.service.BillConfirmationService;
import com.homestock.modules.bill.service.BillScanService;
import com.homestock.modules.bill.service.ExpenseIntelligenceService;
import com.homestock.modules.bill.service.PriceIntelligenceService;
import com.homestock.modules.home.dto.CreateHomeRequest;
import com.homestock.modules.home.dto.HomeDto;
import com.homestock.modules.home.service.HomeService;
import com.homestock.modules.inventory.dto.CreateInventoryItemRequest;
import com.homestock.modules.inventory.dto.InventoryItemDto;
import com.homestock.modules.inventory.service.InventoryService;
import com.homestock.modules.shopping.dto.CreateShoppingItemRequest;
import com.homestock.modules.shopping.dto.ShoppingListDto;
import com.homestock.modules.shopping.entity.ShoppingListItem;
import com.homestock.modules.shopping.repository.ShoppingListItemRepository;
import com.homestock.modules.shopping.service.ShoppingService;
import com.homestock.modules.user.entity.User;
import com.homestock.modules.user.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("local")
@Transactional
class BillScanAndConfirmationIntegrationTest {

    @Autowired
    private AuthService authService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private HomeService homeService;

    @Autowired
    private InventoryService inventoryService;

    @Autowired
    private com.homestock.modules.inventory.repository.InventoryItemRepository inventoryItemRepository;

    @Autowired
    private ShoppingService shoppingService;

    @Autowired
    private ShoppingListItemRepository shoppingListItemRepository;

    @Autowired
    private BillScanService billScanService;

    @Autowired
    private BillConfirmationService billConfirmationService;

    @Autowired
    private PurchasedBillRepository billRepository;

    @Autowired
    private ProductPriceHistoryRepository priceHistoryRepository;

    @Autowired
    private ExpenseIntelligenceService expenseIntelligenceService;

    @Autowired
    private PriceIntelligenceService priceIntelligenceService;

    private User currentUser;
    private HomeDto home;

    @BeforeEach
    void setUp() {
        String email = "scanner.test." + UUID.randomUUID().toString().substring(0, 8) + "@example.com";
        RegisterRequest register = new RegisterRequest();
        register.setEmail(email);
        register.setPassword("Password123!");
        register.setFullName("Scanner Test User");
        authService.register(register);

        currentUser = userRepository.findByEmail(email).orElseThrow();
        UserPrincipal principal = UserPrincipal.create(currentUser);
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(principal, null, principal.getAuthorities()));

        CreateHomeRequest homeRequest = new CreateHomeRequest();
        homeRequest.setName("Scanner Household");
        home = homeService.createHome(homeRequest);
    }

    @Test
    void testEndToEndBillScanConfirmAndExpenseIntelligenceWorkflow() {
        UUID homeId = home.getId();

        // 1. Create existing inventory item: Fortune Sunflower Oil (qty: 5.0 L, min: 1.0 L)
        CreateInventoryItemRequest invReq = new CreateInventoryItemRequest();
        invReq.setName("Fortune Sunflower Oil");
        invReq.setBrand("Fortune");
        invReq.setQuantity(new BigDecimal("5.0"));
        invReq.setUnit("L");
        invReq.setMinimumQuantity(new BigDecimal("1.0"));
        InventoryItemDto existingInvItem = inventoryService.createItem(homeId, invReq);

        // 2. Add item to shopping list: Sunflower Oil (10 L needed)
        ShoppingListDto defaultList = shoppingService.getDefaultShoppingList(homeId);
        CreateShoppingItemRequest shopReq = new CreateShoppingItemRequest();
        shopReq.setItemName("Fortune Sunflower Oil");
        shopReq.setQuantity(new BigDecimal("10.0"));
        shopReq.setUnit("L");
        shoppingService.addItem(homeId, defaultList.getId(), shopReq);

        // 3. Scan Bill raw text
        String receiptText = """
                DMART - AVENUE SUPERMARTS
                INVOICE: DM-889922
                DATE: 12/09/2026
                ----------------------------------------
                FORTUNE SUNFLOWER OIL 1L   4   130.00   520.00
                AASHIRVAAD ATTA 5KG        1   240.00   240.00
                ----------------------------------------
                TOTAL:                                  760.00
                """;

        BillScanPreviewResponseDto preview = billScanService.scanBill(homeId, null, receiptText, currentUser);

        assertNotNull(preview);
        assertNotNull(preview.getBillId());
        assertTrue(preview.getShopName().toUpperCase().contains("DMART"));
        assertEquals(new BigDecimal("760.00"), preview.getTotal());
        assertEquals(2, preview.getItems().size());

        // Check matching
        BillScanItemPreviewDto oilItemPreview = preview.getItems().stream()
                .filter(i -> i.getRawItemName().toUpperCase().contains("SUNFLOWER"))
                .findFirst()
                .orElse(null);
        assertNotNull(oilItemPreview);
        assertEquals("AUTO_MATCHED", oilItemPreview.getMatchStatus());
        assertEquals(existingInvItem.getId(), oilItemPreview.getMatchedInventoryItemId());

        // 4. Confirm Bill (Confirm partial purchase: 4 L of Sunflower Oil, and 1 pack of 5KG Atta)
        ConfirmBillRequest confirmReq = ConfirmBillRequest.builder()
                .shopName("DMart")
                .billNumber("DM-889922")
                .billDate(LocalDate.of(2026, 9, 12))
                .totalAmount(new BigDecimal("760.00"))
                .items(List.of(
                        ConfirmBillItemRequest.builder()
                                .rawItemName("FORTUNE SUNFLOWER OIL 1L")
                                .productName("Fortune Sunflower Oil")
                                .inventoryItemId(existingInvItem.getId())
                                .quantity(new BigDecimal("4.0"))
                                .unit("L")
                                .unitPrice(new BigDecimal("130.00"))
                                .finalPrice(new BigDecimal("520.00"))
                                .shoppingListItemId(oilItemPreview.getMatchedShoppingListItemId())
                                .build(),
                        ConfirmBillItemRequest.builder()
                                .rawItemName("AASHIRVAAD ATTA 5KG")
                                .productName("Aashirvaad Superior MP Atta")
                                .brand("Aashirvaad")
                                .categoryName("Food & Grocery")
                                .quantity(new BigDecimal("1.0"))
                                .unit("KG")
                                .unitPrice(new BigDecimal("240.00"))
                                .finalPrice(new BigDecimal("240.00"))
                                .build()
                ))
                .build();

        BillResponseDto confirmed = billConfirmationService.confirmBill(homeId, preview.getBillId(), confirmReq, currentUser);

        assertNotNull(confirmed);
        assertEquals("CONFIRMED", confirmed.getStatus());
        assertEquals(new BigDecimal("760.00"), confirmed.getTotalAmount());

        // 5. Verify Inventory Stock Updated
        // Initial 5.0 L + 4.0 L purchased = 9.0 L
        com.homestock.modules.inventory.entity.InventoryItem updatedInv =
                inventoryItemRepository.findByIdAndHomeId(existingInvItem.getId(), homeId).orElseThrow();
        assertEquals(0, new BigDecimal("9.000").compareTo(updatedInv.getQuantity()));

        // 6. Verify Shopping List Item status: partial purchase
        // Needed 10.0, purchased 4.0 -> status PARTIALLY_PURCHASED, purchasedQuantity = 4.0
        if (oilItemPreview.getMatchedShoppingListItemId() != null) {
            ShoppingListItem updatedShopItem = shoppingListItemRepository.findById(oilItemPreview.getMatchedShoppingListItemId()).orElseThrow();
            assertEquals("PARTIALLY_PURCHASED", updatedShopItem.getStatus());
            assertEquals(0, new BigDecimal("4.0").compareTo(updatedShopItem.getPurchasedQuantity()));
        }

        // 7. Verify Product Price History generated
        List<ProductPriceHistory> histories = priceHistoryRepository.findByHomeIdAndInventoryItemIdOrderByPurchaseDateDesc(homeId, existingInvItem.getId(), org.springframework.data.domain.PageRequest.of(0, 10));
        assertFalse(histories.isEmpty());
        ProductPriceHistory priceRecord = histories.get(0);
        assertEquals(new BigDecimal("130.00"), priceRecord.getStandardUnitPrice());
        assertEquals("DMart", priceRecord.getStoreName());

        // 8. Verify Monthly Expense Report Analytics
        MonthlyExpenseReportDto monthly = expenseIntelligenceService.getMonthlyReport(homeId, 2026, 9);
        assertNotNull(monthly);
        assertEquals(new BigDecimal("760.00"), monthly.getTotalSpend());
        assertEquals(1, monthly.getBillsCount());
        assertFalse(monthly.getCategoryBreakdown().isEmpty());
        assertFalse(monthly.getShopBreakdown().isEmpty());

        // 9. Verify Price Intelligence store & standard unit price metrics
        ProductPriceIntelligenceDto priceIntel = priceIntelligenceService.getInventoryItemPriceIntelligence(homeId, existingInvItem.getId());
        assertNotNull(priceIntel);
        assertEquals("Fortune Sunflower Oil", priceIntel.getProductName());
        assertEquals(new BigDecimal("130.00"), priceIntel.getCurrentPrice());
        assertEquals(new BigDecimal("130.00"), priceIntel.getMinPrice());
    }
}
