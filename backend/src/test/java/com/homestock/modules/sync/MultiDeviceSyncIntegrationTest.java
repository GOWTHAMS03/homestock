package com.homestock.modules.sync;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.homestock.modules.category.repository.CategoryRepository;
import com.homestock.modules.home.entity.Home;
import com.homestock.modules.home.repository.HomeMemberRepository;
import com.homestock.modules.home.repository.HomeRepository;
import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.inventory.entity.StockTransaction;
import com.homestock.modules.inventory.repository.InventoryItemRepository;
import com.homestock.modules.inventory.repository.StockTransactionRepository;
import com.homestock.modules.notification.service.NotificationEngine;
import com.homestock.modules.purchase.repository.PurchaseItemRepository;
import com.homestock.modules.purchase.repository.PurchaseRepository;
import com.homestock.modules.shopping.entity.ShoppingList;
import com.homestock.modules.shopping.entity.ShoppingListItem;
import com.homestock.modules.shopping.repository.ShoppingListItemRepository;
import com.homestock.modules.shopping.repository.ShoppingListRepository;
import com.homestock.modules.shopping.service.ShoppingService;
import com.homestock.modules.store.repository.StoreRepository;
import com.homestock.modules.sync.dto.SyncOperationDto;
import com.homestock.modules.sync.dto.SyncPullResponse;
import com.homestock.modules.sync.dto.SyncPushResponse;
import com.homestock.modules.sync.dto.SyncRequest;
import com.homestock.modules.sync.entity.HomeChangeLog;
import com.homestock.modules.sync.entity.ProcessedOperation;
import com.homestock.modules.sync.repository.ProcessedOperationRepository;
import com.homestock.modules.sync.service.HomeChangeLogService;
import com.homestock.modules.sync.service.SyncService;
import com.homestock.modules.user.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
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
class MultiDeviceSyncIntegrationTest {

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
    private HomeMemberRepository homeMemberRepository;
    @Mock
    private UserRepository userRepository;
    @Mock
    private ShoppingService shoppingService;
    @Mock
    private ObjectMapper objectMapper;
    @Mock
    private com.homestock.modules.consumption.service.ConsumptionService consumptionService;
    @Mock
    private HomeChangeLogService homeChangeLogService;
    @Mock
    private NotificationEngine notificationEngine;
    @Mock
    private com.homestock.core.redis.DistributedLockService distributedLockService;
    @Mock
    private com.homestock.modules.dashboard.service.DashboardCacheService dashboardCacheService;
    @Mock
    private com.homestock.core.observability.OfflineSyncMetrics offlineSyncMetrics;

    @InjectMocks
    private SyncService syncService;

    private UUID homeId;
    private Home home;

    @BeforeEach
    void setUp() {
        homeId = UUID.randomUUID();
        home = Home.builder().name("Family Household").build();
        home.setId(homeId);

        lenient().when(distributedLockService.executeWithLock(anyString(), any(), any(java.util.function.Supplier.class)))
                .thenAnswer(invocation -> ((java.util.function.Supplier<?>) invocation.getArgument(2)).get());
    }

    @Test
    @DisplayName("Example 12 Requirement: Phone A (+5kg) and Phone B (-1kg) concurrent offline operations merge to 14kg")
    void testConcurrentOfflineStockMerge() {
        UUID riceItemId = UUID.randomUUID();
        // Initial state: 10.0 kg of Basmati Rice
        InventoryItem rice = InventoryItem.builder()
                .home(home)
                .name("Basmati Rice")
                .unit("kg")
                .quantity(new BigDecimal("10.0"))
                .minimumQuantity(new BigDecimal("2.0"))
                .isArchived(false)
                .build();
        rice.setId(riceItemId);

        when(homeRepository.findById(homeId)).thenReturn(Optional.of(home));
        when(inventoryItemRepository.findWithLockByIdAndHomeId(riceItemId, homeId))
                .thenReturn(Optional.of(rice));
        when(inventoryItemRepository.save(any(InventoryItem.class))).thenAnswer(i -> i.getArgument(0));

        // ──── 1. Phone A Reconnects & Pushes STOCK_IN (+5kg) ────
        String opIdPhoneA = "op-phoneA-rice-add-5kg-" + UUID.randomUUID();
        when(processedOperationRepository.existsByOperationId(opIdPhoneA)).thenReturn(false);

        SyncOperationDto opA = SyncOperationDto.builder()
                .operationId(opIdPhoneA)
                .operationType("STOCK_IN")
                .entityType("INVENTORY_ITEM")
                .entityId(riceItemId.toString())
                .payload(Map.of("quantityChange", 5.0, "reason", "Bought 5kg Rice from Market"))
                .build();

        SyncRequest requestA = SyncRequest.builder()
                .homeId(homeId)
                .operations(List.of(opA))
                .build();

        SyncPushResponse responseA = syncService.pushOperations(requestA);

        assertNotNull(responseA);
        assertEquals(1, responseA.getResults().size());
        assertEquals("SYNCED", responseA.getResults().get(0).getStatus());
        assertEquals(new BigDecimal("15.0"), rice.getQuantity(), "Rice should be 10 + 5 = 15kg after Phone A pushes");

        verify(processedOperationRepository).save(argThat(po ->
                opIdPhoneA.equals(po.getOperationId()) && "SYNCED".equals(po.getStatus())));
        verify(homeChangeLogService).recordChange(eq(home), eq("INVENTORY_ITEM"), eq(riceItemId), eq("UPDATE"), any(), eq(opIdPhoneA));

        // ──── 2. Phone B Reconnects & Pushes STOCK_OUT (-1kg) ────
        String opIdPhoneB = "op-phoneB-rice-consume-1kg-" + UUID.randomUUID();
        when(processedOperationRepository.existsByOperationId(opIdPhoneB)).thenReturn(false);

        SyncOperationDto opB = SyncOperationDto.builder()
                .operationId(opIdPhoneB)
                .operationType("STOCK_OUT")
                .entityType("INVENTORY_ITEM")
                .entityId(riceItemId.toString())
                .payload(Map.of("quantityChange", 1.0, "reason", "Cooked 1kg Rice for Dinner"))
                .build();

        SyncRequest requestB = SyncRequest.builder()
                .homeId(homeId)
                .operations(List.of(opB))
                .build();

        SyncPushResponse responseB = syncService.pushOperations(requestB);

        assertNotNull(responseB);
        assertEquals(1, responseB.getResults().size());
        assertEquals("SYNCED", responseB.getResults().get(0).getStatus());

        // CRITICAL CHECK: Final merged server quantity must be exactly 14.0 kg!
        assertEquals(new BigDecimal("14.0"), rice.getQuantity(), "Rice must be 15 - 1 = 14kg after Phone B applies delta!");
        verify(processedOperationRepository).save(argThat(po ->
                opIdPhoneB.equals(po.getOperationId()) && "SYNCED".equals(po.getStatus())));
        verify(homeChangeLogService).recordChange(eq(home), eq("INVENTORY_ITEM"), eq(riceItemId), eq("UPDATE"), any(), eq(opIdPhoneB));

        // Both transactions are tracked in audit log
        verify(stockTransactionRepository, times(2)).save(any(StockTransaction.class));
    }

    @Test
    @DisplayName("Requirement 9: Server rejects duplicate operationIds safely without re-applying operation")
    void testIdempotencyDuplicateRequestRejection() {
        UUID itemId = UUID.randomUUID();
        InventoryItem oliveOil = InventoryItem.builder()
                .home(home)
                .name("Olive Oil")
                .unit("L")
                .quantity(new BigDecimal("2.0"))
                .build();
        oliveOil.setId(itemId);

        String duplicateOpId = "op-dup-test-999";
        when(homeRepository.findById(homeId)).thenReturn(Optional.of(home));
        // Simulate that this operation was already processed earlier
        when(processedOperationRepository.existsByOperationId(duplicateOpId)).thenReturn(true);

        SyncOperationDto duplicateOp = SyncOperationDto.builder()
                .operationId(duplicateOpId)
                .operationType("STOCK_IN")
                .entityType("INVENTORY_ITEM")
                .entityId(itemId.toString())
                .payload(Map.of("quantityChange", 10.0))
                .build();

        SyncPushResponse response = syncService.pushOperations(
                SyncRequest.builder().homeId(homeId).operations(List.of(duplicateOp)).build());

        assertNotNull(response);
        assertEquals(1, response.getResults().size());
        assertEquals("ALREADY_PROCESSED", response.getResults().get(0).getStatus());
        assertEquals(duplicateOpId, response.getResults().get(0).getOperationId());

        // Verify stock was NOT modified again
        assertEquals(new BigDecimal("2.0"), oliveOil.getQuantity());
        verify(inventoryItemRepository, never()).save(any());
        verify(stockTransactionRepository, never()).save(any());
    }

    @Test
    @DisplayName("Requirement 6: Partial failure handling — one invalid operation in a batch does not abort valid operations")
    void testPartialFailureHandlingInBatch() {
        UUID validItemId = UUID.randomUUID();
        InventoryItem validItem = InventoryItem.builder()
                .home(home)
                .name("Sugar")
                .unit("kg")
                .quantity(new BigDecimal("5.0"))
                .build();
        validItem.setId(validItemId);

        when(homeRepository.findById(homeId)).thenReturn(Optional.of(home));
        when(inventoryItemRepository.findWithLockByIdAndHomeId(validItemId, homeId))
                .thenReturn(Optional.of(validItem));
        when(inventoryItemRepository.save(any())).thenAnswer(i -> i.getArgument(0));

        String validOpId = "op-valid-batch-1";
        String invalidOpId = "op-invalid-batch-2";
        when(processedOperationRepository.existsByOperationId(validOpId)).thenReturn(false);
        when(processedOperationRepository.existsByOperationId(invalidOpId)).thenReturn(false);

        // Op 1: Valid STOCK_IN +2kg
        SyncOperationDto validOp = SyncOperationDto.builder()
                .operationId(validOpId)
                .operationType("STOCK_IN")
                .entityType("INVENTORY_ITEM")
                .entityId(validItemId.toString())
                .payload(Map.of("quantityChange", 2.0))
                .build();

        // Op 2: Invalid entity id format that causes an exception
        SyncOperationDto invalidOp = SyncOperationDto.builder()
                .operationId(invalidOpId)
                .operationType("UPDATE_ITEM")
                .entityType("INVENTORY_ITEM")
                .entityId("not-a-valid-uuid") // Causes IllegalArgumentException on UUID.fromString
                .payload(Map.of("name", "New Name"))
                .build();

        SyncRequest batchRequest = SyncRequest.builder()
                .homeId(homeId)
                .operations(List.of(validOp, invalidOp))
                .build();

        SyncPushResponse response = syncService.pushOperations(batchRequest);

        assertNotNull(response);
        assertEquals(2, response.getResults().size());

        // Valid op succeeded
        assertEquals("SYNCED", response.getResults().get(0).getStatus());
        assertEquals(validOpId, response.getResults().get(0).getOperationId());
        assertEquals(new BigDecimal("7.0"), validItem.getQuantity(), "Sugar was successfully increased to 7kg");

        // Invalid op failed gracefully without crashing the push endpoint
        assertEquals("FAILED", response.getResults().get(1).getStatus());
        assertEquals(invalidOpId, response.getResults().get(1).getOperationId());
        assertNotNull(response.getResults().get(1).getErrorMessage());

        // Both operations have their result recorded in ProcessedOperation repository
        verify(processedOperationRepository).save(argThat(po -> validOpId.equals(po.getOperationId()) && "SYNCED".equals(po.getStatus())));
        verify(processedOperationRepository).save(argThat(po -> invalidOpId.equals(po.getOperationId()) && "FAILED".equals(po.getStatus())));
    }

    @Test
    @DisplayName("Requirement 11 & 13: Incremental pull using sequence cursor only fetches delta changes")
    void testIncrementalPullCursor() {
        UUID changedItemId = UUID.randomUUID();
        InventoryItem item = InventoryItem.builder()
                .home(home)
                .name("Fresh Apples")
                .unit("kg")
                .quantity(new BigDecimal("3.0"))
                .build();
        item.setId(changedItemId);

        HomeChangeLog changeLog = HomeChangeLog.builder()
                .home(home)
                .changeVersion(102L)
                .entityType("INVENTORY_ITEM")
                .entityId(changedItemId)
                .operationType("UPDATE")
                .createdAt(Instant.now())
                .build();

        when(homeChangeLogService.getMaxVersion(homeId)).thenReturn(102L);
        when(homeChangeLogService.getChangesSince(eq(homeId), eq(100L), anyInt()))
                .thenReturn(List.of(changeLog));
        when(inventoryItemRepository.findAllById(any())).thenReturn(List.of(item));

        // Client pulls changes since version 100
        SyncPullResponse pullResponse = syncService.pullChanges(homeId, Instant.EPOCH, 100L, 500);

        assertNotNull(pullResponse);
        assertEquals(102L, pullResponse.getServerVersion());
        assertEquals(102L, pullResponse.getNextServerVersion());
        assertFalse(pullResponse.getHasMore());
        assertEquals(1, pullResponse.getInventoryItems().size());
        assertEquals("Fresh Apples", pullResponse.getInventoryItems().get(0).get("name"));

        // Verify full repository scans were bypassed
        verify(inventoryItemRepository, never()).findByHomeIdAndUpdatedAtAfter(any(), any());
    }

    @Test
    @DisplayName("Family collaboration: Phone A adds shopping item, Phone B toggles completion")
    void testMultiDeviceShoppingCollaboration() {
        ShoppingList defaultList = ShoppingList.builder().name("Default List").home(home).build();
        UUID listId = UUID.randomUUID();
        defaultList.setId(listId);

        when(homeRepository.findById(homeId)).thenReturn(Optional.of(home));
        when(shoppingService.getOrCreateDefaultListEntity(home)).thenReturn(defaultList);

        // Phone A adds shopping item "Whole Milk"
        UUID shopItemId = UUID.randomUUID();
        String opAddId = "op-phoneA-add-milk";
        when(processedOperationRepository.existsByOperationId(opAddId)).thenReturn(false);
        when(shoppingListItemRepository.existsById(shopItemId)).thenReturn(false);

        ShoppingListItem savedItem = ShoppingListItem.builder()
                .shoppingList(defaultList)
                .itemName("Whole Milk")
                .quantity(new BigDecimal("2.0"))
                .unit("L")
                .isCompleted(false)
                .build();
        savedItem.setId(shopItemId);
        when(shoppingListItemRepository.save(any())).thenReturn(savedItem);

        SyncOperationDto addOp = SyncOperationDto.builder()
                .operationId(opAddId)
                .operationType("ADD_SHOPPING_ITEM")
                .entityType("SHOPPING_LIST_ITEM")
                .entityId(shopItemId.toString())
                .payload(Map.of("itemName", "Whole Milk", "quantity", 2.0, "unit", "L"))
                .build();

        SyncPushResponse addResponse = syncService.pushOperations(
                SyncRequest.builder().homeId(homeId).operations(List.of(addOp)).build());

        assertEquals("SYNCED", addResponse.getResults().get(0).getStatus());
        verify(homeChangeLogService).recordChange(eq(home), eq("SHOPPING_LIST_ITEM"), eq(shopItemId), eq("INSERT"), any(), eq(opAddId));

        // Phone B marks "Whole Milk" as completed
        String opToggleId = "op-phoneB-toggle-milk";
        when(processedOperationRepository.existsByOperationId(opToggleId)).thenReturn(false);
        when(shoppingListItemRepository.findById(shopItemId)).thenReturn(Optional.of(savedItem));

        SyncOperationDto toggleOp = SyncOperationDto.builder()
                .operationId(opToggleId)
                .operationType("TOGGLE_SHOPPING_ITEM")
                .entityType("SHOPPING_LIST_ITEM")
                .entityId(shopItemId.toString())
                .payload(Map.of("isCompleted", true))
                .build();

        SyncPushResponse toggleResponse = syncService.pushOperations(
                SyncRequest.builder().homeId(homeId).operations(List.of(toggleOp)).build());

        assertEquals("SYNCED", toggleResponse.getResults().get(0).getStatus());
        assertTrue(savedItem.getIsCompleted());
        verify(homeChangeLogService).recordChange(eq(home), eq("SHOPPING_LIST_ITEM"), eq(shopItemId), eq("UPDATE"), any(), eq(opToggleId));
    }
}
