package com.homestock.modules.sync;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.homestock.modules.category.repository.CategoryRepository;
import com.homestock.modules.home.entity.Home;
import com.homestock.modules.home.repository.HomeRepository;
import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.inventory.entity.StockStatus;
import com.homestock.modules.inventory.entity.TransactionType;
import com.homestock.modules.inventory.repository.InventoryItemRepository;
import com.homestock.modules.inventory.repository.StockTransactionRepository;
import com.homestock.modules.purchase.repository.PurchaseItemRepository;
import com.homestock.modules.purchase.repository.PurchaseRepository;
import com.homestock.modules.shopping.repository.ShoppingListItemRepository;
import com.homestock.modules.shopping.repository.ShoppingListRepository;
import com.homestock.modules.shopping.service.ShoppingService;
import com.homestock.modules.store.repository.StoreRepository;
import com.homestock.modules.sync.dto.*;
import com.homestock.modules.sync.entity.ProcessedOperation;
import com.homestock.modules.sync.repository.ProcessedOperationRepository;
import com.homestock.modules.sync.service.SyncService;
import com.homestock.modules.user.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class SyncServiceTest {

    @Mock
    private ProcessedOperationRepository processedOperationRepository;
    @Mock
    private InventoryItemRepository inventoryItemRepository;
    @Mock
    private StockTransactionRepository stockTransactionRepository;
    @Mock
    private ShoppingListRepository shoppingListRepository;
    @Mock
    private ShoppingListItemRepository shoppingListItemRepository;
    @Mock
    private PurchaseRepository purchaseRepository;
    @Mock
    private PurchaseItemRepository purchaseItemRepository;
    @Mock
    private CategoryRepository categoryRepository;
    @Mock
    private StoreRepository storeRepository;
    @Mock
    private HomeRepository homeRepository;
    @Mock
    private UserRepository userRepository;
    @Mock
    private ShoppingService shoppingService;
    @Mock
    private ObjectMapper objectMapper;

    @InjectMocks
    private SyncService syncService;

    private UUID homeId;
    private Home home;

    @BeforeEach
    void setUp() {
        homeId = UUID.randomUUID();
        home = Home.builder().name("Test Household").build();
        home.setId(homeId);
    }

    @Test
    void pushOperations_alreadyProcessedOperation_returnsAlreadyProcessedStatus() {
        when(homeRepository.findById(homeId)).thenReturn(Optional.of(home));
        when(processedOperationRepository.existsByOperationId("op-duplicate-123")).thenReturn(true);

        SyncOperationDto op = SyncOperationDto.builder()
                .operationId("op-duplicate-123")
                .operationType("STOCK_OUT")
                .entityType("INVENTORY_ITEM")
                .entityId(UUID.randomUUID().toString())
                .payload(Map.of("quantityChange", 1.0))
                .build();

        SyncRequest request = SyncRequest.builder()
                .homeId(homeId)
                .operations(List.of(op))
                .build();

        SyncPushResponse response = syncService.pushOperations(request);

        assertNotNull(response);
        assertEquals(1, response.getResults().size());
        assertEquals("ALREADY_PROCESSED", response.getResults().get(0).getStatus());
        assertEquals("op-duplicate-123", response.getResults().get(0).getOperationId());

        // Ensure no stock updates were made
        verify(inventoryItemRepository, never()).save(any());
        verify(processedOperationRepository, never()).save(any());
    }

    @Test
    void pushOperations_stockOutOperation_appliesDeltaAndRecordsOperation() {
        UUID itemId = UUID.randomUUID();
        InventoryItem existingItem = InventoryItem.builder()
                .home(home)
                .name("Cooking Oil")
                .unit("L")
                .quantity(new BigDecimal("5.0"))
                .minimumQuantity(new BigDecimal("1.0"))
                .isArchived(false)
                .build();
        existingItem.setId(itemId);

        when(homeRepository.findById(homeId)).thenReturn(Optional.of(home));
        when(processedOperationRepository.existsByOperationId("op-stockout-456")).thenReturn(false);
        when(inventoryItemRepository.findByIdAndHomeId(eq(itemId), eq(homeId)))
                .thenReturn(Optional.of(existingItem));
        when(inventoryItemRepository.save(any(InventoryItem.class))).thenAnswer(i -> i.getArgument(0));

        SyncOperationDto op = SyncOperationDto.builder()
                .operationId("op-stockout-456")
                .operationType("STOCK_OUT")
                .entityType("INVENTORY_ITEM")
                .entityId(itemId.toString())
                .payload(Map.of("quantityChange", 2.0, "reason", "Cooking dinner"))
                .build();

        SyncRequest request = SyncRequest.builder()
                .homeId(homeId)
                .operations(List.of(op))
                .build();

        SyncPushResponse response = syncService.pushOperations(request);

        assertNotNull(response);
        assertEquals(1, response.getResults().size());
        assertEquals("SYNCED", response.getResults().get(0).getStatus());

        // Verify quantity was reduced by delta: 5.0 - 2.0 = 3.0
        assertEquals(new BigDecimal("3.0"), existingItem.getQuantity());
        verify(inventoryItemRepository).save(existingItem);
        verify(stockTransactionRepository).save(any());
        verify(processedOperationRepository).save(any(ProcessedOperation.class));
    }

    @Test
    void pushOperations_createStore_savesStoreSuccessfully() {
        UUID storeId = UUID.randomUUID();
        when(homeRepository.findById(homeId)).thenReturn(Optional.of(home));
        when(processedOperationRepository.existsByOperationId("op-store-1")).thenReturn(false);
        when(storeRepository.existsById(storeId)).thenReturn(false);

        SyncOperationDto op = SyncOperationDto.builder()
                .operationId("op-store-1")
                .operationType("CREATE_STORE")
                .entityType("STORE")
                .entityId(storeId.toString())
                .payload(Map.of("name", "Local Organic Market", "location", "Downtown"))
                .build();

        SyncRequest request = SyncRequest.builder()
                .homeId(homeId)
                .operations(List.of(op))
                .build();

        SyncPushResponse response = syncService.pushOperations(request);

        assertNotNull(response);
        assertEquals(1, response.getResults().size());
        assertEquals("SYNCED", response.getResults().get(0).getStatus());
        verify(storeRepository).save(argThat(s ->
                s.getId().equals(storeId) &&
                "Local Organic Market".equals(s.getName()) &&
                "Downtown".equals(s.getLocation())
        ));
    }

    @Test
    void pushOperations_clearCompletedShopping_callsRepository() {
        when(homeRepository.findById(homeId)).thenReturn(Optional.of(home));
        when(processedOperationRepository.existsByOperationId("op-clear-1")).thenReturn(false);
        com.homestock.modules.shopping.entity.ShoppingList mockList = com.homestock.modules.shopping.entity.ShoppingList.builder()
                .name("Default List")
                .build();
        UUID listId = UUID.randomUUID();
        mockList.setId(listId);
        when(shoppingService.getOrCreateDefaultListEntity(home)).thenReturn(mockList);

        SyncOperationDto op = SyncOperationDto.builder()
                .operationId("op-clear-1")
                .operationType("CLEAR_COMPLETED_SHOPPING")
                .entityType("SHOPPING_LIST")
                .entityId(listId.toString())
                .payload(Map.of())
                .build();

        SyncRequest request = SyncRequest.builder()
                .homeId(homeId)
                .operations(List.of(op))
                .build();

        SyncPushResponse response = syncService.pushOperations(request);

        assertNotNull(response);
        assertEquals(1, response.getResults().size());
        assertEquals("SYNCED", response.getResults().get(0).getStatus());
        verify(shoppingListItemRepository).deleteAllCompletedByShoppingListId(listId);
    }
}
