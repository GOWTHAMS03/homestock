package com.homestock;

import com.homestock.core.exception.BusinessRuleException;
import com.homestock.core.security.UserPrincipal;
import com.homestock.modules.auth.dto.RegisterRequest;
import com.homestock.modules.auth.service.AuthService;
import com.homestock.modules.home.dto.CreateHomeRequest;
import com.homestock.modules.home.dto.HomeDto;
import com.homestock.modules.home.service.HomeService;
import com.homestock.modules.inventory.dto.CreateInventoryItemRequest;
import com.homestock.modules.inventory.dto.InventoryItemDto;
import com.homestock.modules.inventory.dto.StockUpdateRequest;
import com.homestock.modules.inventory.entity.StockStatus;
import com.homestock.modules.inventory.entity.TransactionType;
import com.homestock.modules.inventory.service.InventoryService;
import com.homestock.modules.purchase.dto.CreatePurchaseItemRequest;
import com.homestock.modules.purchase.dto.CreatePurchaseRequest;
import com.homestock.modules.purchase.dto.PurchaseDto;
import com.homestock.modules.purchase.service.PurchaseService;
import com.homestock.modules.shopping.dto.ShoppingListDto;
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

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("local")
@Transactional
class InventoryAndShoppingIntegrationTest {

    @Autowired
    private AuthService authService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private HomeService homeService;

    @Autowired
    private InventoryService inventoryService;

    @Autowired
    private ShoppingService shoppingService;

    @Autowired
    private PurchaseService purchaseService;

    private User currentUser;
    private HomeDto home;

    @BeforeEach
    void setUp() {
        RegisterRequest register = new RegisterRequest();
        register.setEmail("gowtham.home@example.com");
        register.setPassword("Password123!");
        register.setFullName("Gowtham Sekar");
        authService.register(register);

        currentUser = userRepository.findByEmail("gowtham.home@example.com").orElseThrow();
        UserPrincipal principal = UserPrincipal.create(currentUser);
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(principal, null, principal.getAuthorities()));

        CreateHomeRequest homeRequest = new CreateHomeRequest();
        homeRequest.setName("Gowtham's Residence");
        home = homeService.createHome(homeRequest);
    }

    @Test
    void testCompleteInventoryStockAndAutoShoppingWorkflow() {
        // 1. Add item: Sunflower Oil (quantity = 2.0, min = 1.0)
        CreateInventoryItemRequest itemReq = new CreateInventoryItemRequest();
        itemReq.setName("Sunflower Cooking Oil");
        itemReq.setBrand("Fortune");
        itemReq.setQuantity(new BigDecimal("2.0"));
        itemReq.setUnit("L");
        itemReq.setMinimumQuantity(new BigDecimal("1.0"));
        itemReq.setMaximumQuantity(new BigDecimal("3.0"));
        itemReq.setStorageLocation("Kitchen Pantry");
        itemReq.setExpiryDate(LocalDate.now().plusDays(30));

        InventoryItemDto item = inventoryService.createItem(home.getId(), itemReq);
        assertEquals(StockStatus.IN_STOCK, item.getStockStatus());
        assertEquals(new BigDecimal("2.0"), item.getQuantity());

        // 2. Stock Out: use 1.5 L -> remaining = 0.5 L <= 1.0 minimum -> LOW_STOCK
        StockUpdateRequest stockOut = new StockUpdateRequest();
        stockOut.setTransactionType(TransactionType.STOCK_OUT);
        stockOut.setQuantityChange(new BigDecimal("1.5"));
        stockOut.setReason("Dinner cooking");

        InventoryItemDto lowStockItem = inventoryService.updateStock(home.getId(), item.getId(), stockOut);
        assertEquals(StockStatus.LOW_STOCK, lowStockItem.getStockStatus());
        assertEquals(0, new BigDecimal("0.5").compareTo(lowStockItem.getQuantity()));

        // 3. Verify Auto Low Stock triggered addition to Shopping List
        ShoppingListDto shoppingList = shoppingService.getDefaultShoppingList(home.getId());
        assertTrue(shoppingList.getPendingCount() >= 1);
        boolean foundInShopping = shoppingList.getItems().stream()
                .anyMatch(si -> si.getItemName().equals("Sunflower Cooking Oil") && Boolean.TRUE.equals(si.getIsAutoGenerated()));
        assertTrue(foundInShopping, "Item should have been automatically added to shopping list");

        // 4. Test Negative Stock Prevention: try to consume 1.0 L when only 0.5 L available
        StockUpdateRequest invalidStockOut = new StockUpdateRequest();
        invalidStockOut.setTransactionType(TransactionType.STOCK_OUT);
        invalidStockOut.setQuantityChange(new BigDecimal("1.0"));
        invalidStockOut.setReason("Excess usage");

        assertThrows(BusinessRuleException.class, () ->
                inventoryService.updateStock(home.getId(), item.getId(), invalidStockOut));

        // 5. Record Purchase: Buy 2.0 L at "DMart" for ₹280 -> Restock inventory and complete shopping item
        CreatePurchaseRequest purchaseReq = new CreatePurchaseRequest();
        purchaseReq.setTotalAmount(new BigDecimal("280.00"));
        purchaseReq.setCurrency("INR");
        purchaseReq.setPurchaseDate(LocalDate.now());

        CreatePurchaseItemRequest pItem = new CreatePurchaseItemRequest();
        pItem.setInventoryItemId(item.getId());
        pItem.setItemName("Sunflower Cooking Oil");
        pItem.setQuantity(new BigDecimal("2.0"));
        pItem.setUnit("L");
        pItem.setUnitPrice(new BigDecimal("140.00"));
        pItem.setTotalPrice(new BigDecimal("280.00"));
        purchaseReq.setItems(List.of(pItem));

        PurchaseDto purchase = purchaseService.recordPurchase(home.getId(), purchaseReq);
        assertNotNull(purchase.getId());

        // 6. Verify Inventory is restocked to 2.5 L -> IN_STOCK
        InventoryItemDto restockedItem = inventoryService.getItemById(home.getId(), item.getId());
        assertEquals(StockStatus.IN_STOCK, restockedItem.getStockStatus());
        assertEquals(0, new BigDecimal("2.5").compareTo(restockedItem.getQuantity()));

        // 7. Verify Shopping item is now marked as completed!
        ShoppingListDto updatedShoppingList = shoppingService.getDefaultShoppingList(home.getId());
        boolean autoItemCompleted = updatedShoppingList.getItems().stream()
                .filter(si -> si.getItemName().equals("Sunflower Cooking Oil"))
                .allMatch(si -> Boolean.TRUE.equals(si.getIsCompleted()));
        assertTrue(autoItemCompleted, "Related shopping list item should be marked completed after purchase");
    }
}
