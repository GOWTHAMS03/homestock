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
    private com.homestock.modules.home.repository.HomeMemberRepository homeMemberRepository;
    @Mock
    private UserRepository userRepository;
    @Mock
    private ShoppingService shoppingService;
    @Mock
    private ObjectMapper objectMapper;
    @Mock
    private com.homestock.modules.consumption.service.ConsumptionService consumptionService;
    @Mock
    private com.homestock.modules.sync.service.HomeChangeLogService homeChangeLogService;
    @Mock
    private com.homestock.modules.notification.service.NotificationEngine notificationEngine;

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

    @Test
    void pullChanges_withSinceVersion_returnsDeletedIdsAndServerVersion() {
        UUID deletedShoppingId = UUID.randomUUID();
        com.homestock.modules.sync.entity.HomeChangeLog change = com.homestock.modules.sync.entity.HomeChangeLog.builder()
                .home(home)
                .changeVersion(45L)
                .entityType("SHOPPING_LIST_ITEM")
                .entityId(deletedShoppingId)
                .operationType("DELETE")
                .createdAt(Instant.now())
                .build();

        when(homeChangeLogService.getMaxVersion(homeId)).thenReturn(50L);
        when(homeChangeLogService.getChangesSince(eq(homeId), eq(40L), anyInt())).thenReturn(List.of(change));

        SyncPullResponse response = syncService.pullChanges(homeId, Instant.EPOCH, 40L);

        assertNotNull(response);
        assertEquals(50L, response.getServerVersion());
        assertEquals(1, response.getDeletedShoppingItemIds().size());
        assertEquals(deletedShoppingId.toString(), response.getDeletedShoppingItemIds().get(0));
    }

    @Test
    void pushOperations_updateShoppingItem_updatesAndRecordsChange() {
        UUID itemId = UUID.randomUUID();
        com.homestock.modules.shopping.entity.ShoppingList mockList = com.homestock.modules.shopping.entity.ShoppingList.builder()
                .home(home)
                .name("Groceries")
                .build();
        com.homestock.modules.shopping.entity.ShoppingListItem existingItem = com.homestock.modules.shopping.entity.ShoppingListItem.builder()
                .shoppingList(mockList)
                .itemName("Milk")
                .quantity(new BigDecimal("1.0"))
                .unit("pcs")
                .build();
        existingItem.setId(itemId);

        when(homeRepository.findById(homeId)).thenReturn(Optional.of(home));
        when(processedOperationRepository.existsByOperationId("op-update-shop-1")).thenReturn(false);
        when(shoppingListItemRepository.findById(itemId)).thenReturn(Optional.of(existingItem));
        when(shoppingListItemRepository.save(any())).thenAnswer(i -> i.getArgument(0));

        SyncOperationDto op = SyncOperationDto.builder()
                .operationId("op-update-shop-1")
                .operationType("UPDATE_SHOPPING_ITEM")
                .entityType("SHOPPING_LIST_ITEM")
                .entityId(itemId.toString())
                .payload(Map.of("quantity", 3.0, "unit", "L"))
                .build();

        SyncRequest request = SyncRequest.builder()
                .homeId(homeId)
                .operations(List.of(op))
                .build();

        SyncPushResponse response = syncService.pushOperations(request);

        assertNotNull(response);
        assertEquals(1, response.getResults().size());
        assertEquals("SYNCED", response.getResults().get(0).getStatus());
        assertEquals(new BigDecimal("3.0"), existingItem.getQuantity());
        assertEquals("L", existingItem.getUnit());
        verify(homeChangeLogService).recordChange(eq(home), eq("SHOPPING_LIST_ITEM"), eq(itemId), eq("UPDATE"), any(), eq("op-update-shop-1"));
        verify(notificationEngine).notifyHomeChanged(eq(home), any());
    }

    @Test
    void pushOperations_changeRole_updatesRoleAndRecordsChange() {
        UUID targetUserId = UUID.randomUUID();
        com.homestock.modules.user.entity.User targetUser = com.homestock.modules.user.entity.User.builder()
                .email("user@example.com")
                .fullName("Family Member")
                .build();
        targetUser.setId(targetUserId);

        com.homestock.modules.home.entity.HomeMember member = com.homestock.modules.home.entity.HomeMember.builder()
                .home(home)
                .user(targetUser)
                .role(com.homestock.modules.home.entity.HomeRole.MEMBER)
                .build();
        UUID memberId = UUID.randomUUID();
        member.setId(memberId);

        when(homeRepository.findById(homeId)).thenReturn(Optional.of(home));
        when(processedOperationRepository.existsByOperationId("op-role-1")).thenReturn(false);
        when(homeMemberRepository.findByHomeIdAndUserId(homeId, targetUserId)).thenReturn(Optional.of(member));
        when(homeMemberRepository.save(any())).thenAnswer(i -> i.getArgument(0));

        SyncOperationDto op = SyncOperationDto.builder()
                .operationId("op-role-1")
                .operationType("CHANGE_ROLE")
                .entityType("HOME_MEMBER")
                .entityId(targetUserId.toString())
                .payload(Map.of("role", "ADMIN"))
                .build();

        SyncRequest request = SyncRequest.builder()
                .homeId(homeId)
                .operations(List.of(op))
                .build();

        SyncPushResponse response = syncService.pushOperations(request);

        assertNotNull(response);
        assertEquals(1, response.getResults().size());
        assertEquals("SYNCED", response.getResults().get(0).getStatus());
        assertEquals(com.homestock.modules.home.entity.HomeRole.ADMIN, member.getRole());
        verify(homeChangeLogService).recordChange(eq(home), eq("HOME_MEMBER"), eq(memberId), eq("UPDATE"), any(), eq("op-role-1"));
        verify(notificationEngine).notifyHomeChanged(eq(home), any());
    }

    @Test
    void pullChanges_withSinceVersionAndNoChanges_returnsEmptyImmediately() {
        when(homeChangeLogService.getMaxVersion(homeId)).thenReturn(150L);
        when(homeChangeLogService.getChangesSince(eq(homeId), eq(150L), anyInt())).thenReturn(Collections.emptyList());

        SyncPullResponse response = syncService.pullChanges(homeId, null, 150L, 500);

        assertNotNull(response);
        assertEquals(150L, response.getServerVersion());
        assertEquals(150L, response.getNextServerVersion());
        assertFalse(response.getHasMore());
        assertTrue(response.getInventoryItems().isEmpty());
        assertTrue(response.getShoppingListItems().isEmpty());
        assertTrue(response.getHomeMembers().isEmpty());

        // Verify full repository scans were NOT performed
        verify(inventoryItemRepository, never()).findByHomeIdAndUpdatedAtAfter(any(), any());
        verify(shoppingListItemRepository, never()).findByHomeIdAndUpdatedAtAfter(any(), any());
    }
}
