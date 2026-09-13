package com.homestock.modules.shopping.service;

import com.homestock.core.util.SecurityUtils;
import com.homestock.modules.category.repository.CategoryRepository;
import com.homestock.modules.home.entity.Home;
import com.homestock.modules.home.repository.HomeRepository;
import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.inventory.repository.InventoryItemRepository;
import com.homestock.modules.notification.service.NotificationService;
import com.homestock.modules.shopping.dto.CreateShoppingItemRequest;
import com.homestock.modules.shopping.dto.ShoppingListItemDto;
import com.homestock.modules.shopping.entity.ShoppingList;
import com.homestock.modules.shopping.entity.ShoppingListItem;
import com.homestock.modules.shopping.repository.ShoppingListItemRepository;
import com.homestock.modules.shopping.repository.ShoppingListRepository;
import com.homestock.modules.sync.service.HomeChangeLogService;
import com.homestock.modules.user.entity.User;
import com.homestock.modules.user.repository.UserRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ShoppingServiceTest {

    @Mock private ShoppingListRepository shoppingListRepository;
    @Mock private ShoppingListItemRepository shoppingListItemRepository;
    @Mock private HomeRepository homeRepository;
    @Mock private UserRepository userRepository;
    @Mock private CategoryRepository categoryRepository;
    @Mock private InventoryItemRepository inventoryItemRepository;
    @Mock private NotificationService notificationService;
    @Mock private HomeChangeLogService homeChangeLogService;

    private ShoppingService shoppingService;
    private MockedStatic<SecurityUtils> securityUtilsMock;

    private final UUID homeId = UUID.randomUUID();
    private final UUID listId = UUID.randomUUID();
    private final UUID userId = UUID.randomUUID();
    private Home home;
    private User user;
    private ShoppingList shoppingList;

    @BeforeEach
    void setUp() {
        shoppingService = new ShoppingService(
                shoppingListRepository,
                shoppingListItemRepository,
                homeRepository,
                userRepository,
                categoryRepository,
                inventoryItemRepository,
                notificationService,
                homeChangeLogService
        );

        home = Home.builder().name("Our Home").build();
        home.setId(homeId);
        user = User.builder().fullName("Test User").build();
        user.setId(userId);
        shoppingList = ShoppingList.builder().home(home).name("Main List").build();
        shoppingList.setId(listId);

        securityUtilsMock = mockStatic(SecurityUtils.class);
        securityUtilsMock.when(SecurityUtils::getCurrentUserId).thenReturn(userId);
    }

    @AfterEach
    void tearDown() {
        if (securityUtilsMock != null) {
            securityUtilsMock.close();
        }
    }

    @Test
    @DisplayName("addItem saves item and records change in HomeChangeLogService")
    void testAddItemRecordsChangeLog() {
        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        when(shoppingListRepository.findByIdAndHomeId(listId, homeId)).thenReturn(Optional.of(shoppingList));

        UUID itemId = UUID.randomUUID();
        when(shoppingListItemRepository.save(any(ShoppingListItem.class))).thenAnswer(invocation -> {
            ShoppingListItem item = invocation.getArgument(0);
            item.setId(itemId);
            return item;
        });

        CreateShoppingItemRequest req = new CreateShoppingItemRequest();
        req.setItemName("Sugar");
        req.setQuantity(new BigDecimal("2"));
        req.setUnit("kg");

        ShoppingListItemDto result = shoppingService.addItem(homeId, listId, req);

        assertNotNull(result);
        assertEquals("Sugar", result.getItemName());
        verify(homeChangeLogService, times(1)).recordChange(eq(home), eq("SHOPPING_LIST_ITEM"), eq(itemId), eq("INSERT"), any(), any());
    }

    @Test
    @DisplayName("deleteItem deletes item and records change in HomeChangeLogService")
    void testDeleteItemRecordsChangeLog() {
        UUID itemId = UUID.randomUUID();
        ShoppingListItem item = ShoppingListItem.builder()
                .shoppingList(shoppingList)
                .itemName("Oil")
                .build();
        item.setId(itemId);

        when(shoppingListRepository.findByIdAndHomeId(listId, homeId)).thenReturn(Optional.of(shoppingList));
        when(shoppingListItemRepository.findById(itemId)).thenReturn(Optional.of(item));

        shoppingService.deleteItem(homeId, listId, itemId);

        verify(shoppingListItemRepository, times(1)).delete(item);
        verify(homeChangeLogService, times(1)).recordChange(eq(home), eq("SHOPPING_LIST_ITEM"), eq(itemId), eq("DELETE"), any(), any());
    }
}
