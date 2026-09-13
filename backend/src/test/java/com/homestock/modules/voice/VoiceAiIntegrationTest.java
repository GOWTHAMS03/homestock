package com.homestock.modules.voice;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.homestock.core.security.HomeSecurityService;
import com.homestock.modules.home.entity.Home;
import com.homestock.modules.home.repository.HomeRepository;
import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.inventory.repository.InventoryItemRepository;
import com.homestock.modules.inventory.service.InventoryService;
import com.homestock.modules.product.repository.ProductRepository;
import com.homestock.modules.shopping.dto.ShoppingListDto;
import com.homestock.modules.shopping.dto.ShoppingListItemDto;
import com.homestock.modules.shopping.entity.ShoppingList;
import com.homestock.modules.shopping.entity.ShoppingListItem;
import com.homestock.modules.shopping.repository.ShoppingListItemRepository;
import com.homestock.modules.shopping.repository.ShoppingListRepository;
import com.homestock.modules.shopping.service.ShoppingService;
import com.homestock.modules.voice.config.VoiceProperties;
import com.homestock.modules.voice.dto.*;
import com.homestock.modules.voice.service.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class VoiceAiIntegrationTest {

    @Mock private ShoppingService shoppingService;
    @Mock private ShoppingListItemRepository shoppingListItemRepository;
    @Mock private ShoppingListRepository shoppingListRepository;
    @Mock private InventoryService inventoryService;
    @Mock private InventoryItemRepository inventoryItemRepository;
    @Mock private HomeRepository homeRepository;
    @Mock private HomeSecurityService homeSecurityService;
    @Mock private ProductRepository productRepository;

    private VoiceIntentService intentService;
    private VoiceResponseGenerator responseGenerator;
    private VoiceCommandValidator validator;
    private VoiceContextService contextService;
    private IdempotencyService idempotencyService;
    private ProductResolutionService resolutionService;
    private VoiceCommandExecutor executor;

    private final UUID homeId = UUID.randomUUID();
    private final UUID userId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        intentService = new VoiceIntentService();
        responseGenerator = new VoiceResponseGenerator();
        validator = new VoiceCommandValidator(homeSecurityService, intentService);

        VoiceProperties properties = new VoiceProperties();
        ObjectMapper mapper = new ObjectMapper();

        contextService = new VoiceContextService(properties, mapper, null);
        idempotencyService = new IdempotencyService(properties, mapper, null);

        TamilTanglishNormalizer normalizer = new TamilTanglishNormalizer();
        resolutionService = new ProductResolutionService(inventoryItemRepository, productRepository, normalizer);

        executor = new VoiceCommandExecutor(
                shoppingService,
                shoppingListItemRepository,
                shoppingListRepository,
                inventoryService,
                inventoryItemRepository,
                homeRepository,
                homeSecurityService,
                resolutionService,
                productRepository
        );
    }

    @Test
    @DisplayName("VoiceIntentService maps standard and new intents correctly")
    void testIntentMapping() {
        assertEquals(VoiceIntent.ADD_SHOPPING_ITEM, intentService.parseIntent("ADD_TO_SHOPPING_LIST"));
        assertEquals(VoiceIntent.CLEAR_SHOPPING_LIST, intentService.parseIntent("CLEAR_SHOPPING_LIST"));
        assertEquals(VoiceIntent.UPDATE_SHOPPING_ITEM, intentService.parseIntent("UPDATE_SHOPPING_LIST_ITEM"));
        assertEquals(VoiceIntent.REMOVE_INVENTORY_ITEM, intentService.parseIntent("REMOVE_FROM_INVENTORY"));
        assertEquals(VoiceIntent.STOCK_OUT, intentService.parseIntent("CONSUME_INVENTORY"));
        assertEquals(VoiceIntent.SEARCH_PRODUCT, intentService.parseIntent("SEARCH_PRODUCT"));
        assertEquals(VoiceIntent.GET_ITEM_STATUS, intentService.parseIntent("GET_INVENTORY"));
    }

    @Test
    @DisplayName("VoiceResponseGenerator formats response in English, Tamil and Tanglish")
    void testMultilingualResponses() {
        String en = responseGenerator.generateSuccessResponse(
                VoiceIntent.ADD_SHOPPING_ITEM, "Rice", new BigDecimal("2"), "KG", null, "EN");
        assertTrue(en.contains("Added 2 kg Rice"));

        String ta = responseGenerator.generateSuccessResponse(
                VoiceIntent.ADD_SHOPPING_ITEM, "Rice", new BigDecimal("2"), "KG", null, "TA");
        assertTrue(ta.contains("shopping list-ல் சேர்த்துவிட்டேன்"));

        String tanglish = responseGenerator.generateSuccessResponse(
                VoiceIntent.ADD_SHOPPING_ITEM, "Rice", new BigDecimal("2"), "KG", null, "TANGLISH");
        assertTrue(tanglish.contains("shopping list-la add panniten"));
    }

    @Test
    @DisplayName("VoiceCommandValidator flags large quantity for user confirmation")
    void testLargeQuantityConfirmation() {
        when(homeSecurityService.isMember(homeId)).thenReturn(true);
        when(homeSecurityService.canEditShoppingList(homeId)).thenReturn(true);

        VoiceEntities entities = VoiceEntities.builder()
                .itemName("Rice")
                .quantity(new BigDecimal("5000"))
                .unit("KG")
                .build();

        VoiceCommandResult cmd = VoiceCommandResult.builder()
                .intent(VoiceIntent.ADD_SHOPPING_ITEM)
                .entities(entities)
                .build();

        var valResult = validator.validate(homeId, cmd);
        assertTrue(valResult.isValid());
        assertTrue(valResult.isRequiresConfirmation());
        assertTrue(valResult.getConfirmationPrompt().contains("unusually large"));
    }

    @Test
    @DisplayName("VoiceContextService saves and retrieves multi-turn context")
    void testContextLifecycle() {
        VoiceContextService.VoiceContext ctx = VoiceContextService.VoiceContext.builder()
                .homeId(homeId)
                .userId(userId)
                .pendingIntent(VoiceIntent.ADD_SHOPPING_ITEM)
                .pendingProduct("Sugar")
                .target("SHOPPING_LIST")
                .missingField("QUANTITY")
                .build();

        contextService.saveContext(userId, homeId, ctx);

        var retrieved = contextService.getContext(userId, homeId);
        assertTrue(retrieved.isPresent());
        assertEquals("Sugar", retrieved.get().getPendingProduct());
        assertEquals(VoiceIntent.ADD_SHOPPING_ITEM, retrieved.get().getPendingIntent());

        contextService.clearContext(userId, homeId);
        assertTrue(contextService.getContext(userId, homeId).isEmpty());
    }

    @Test
    @DisplayName("IdempotencyService detects duplicate command and returns cached response")
    void testIdempotency() {
        String key = "test-audio-hash-12345";
        ExecuteCommandResponse original = ExecuteCommandResponse.builder()
                .success(true)
                .intent(VoiceIntent.ADD_SHOPPING_ITEM)
                .message("Added 2 kg Rice")
                .build();

        idempotencyService.cacheResponse(key, original);

        var cached = idempotencyService.getCachedResponse(key);
        assertTrue(cached.isPresent());
        assertEquals("Added 2 kg Rice", cached.get().getMessage());
    }

    @Test
    @DisplayName("VoiceCommandExecutor executes CLEAR_SHOPPING_LIST successfully")
    void testExecuteClearShoppingList() {
        when(homeSecurityService.isMember(homeId)).thenReturn(true);
        when(homeSecurityService.canEditShoppingList(homeId)).thenReturn(true);

        ShoppingListDto listDto = ShoppingListDto.builder()
                .id(UUID.randomUUID())
                .name("Main Shopping List")
                .build();
        when(shoppingService.getDefaultShoppingList(homeId)).thenReturn(listDto);

        ExecuteCommandRequest req = ExecuteCommandRequest.builder()
                .homeId(homeId)
                .commandResult(VoiceCommandResult.builder()
                        .intent(VoiceIntent.CLEAR_SHOPPING_LIST)
                        .entities(new VoiceEntities())
                        .build())
                .confirmed(true)
                .build();

        ExecuteCommandResponse response = executor.execute(req);

        assertTrue(response.isSuccess());
        assertEquals(VoiceIntent.CLEAR_SHOPPING_LIST, response.getIntent());
        verify(shoppingListItemRepository, times(1)).deleteAll(any());
    }

    @Test
    @DisplayName("VoiceCommandExecutor executes ADD_SHOPPING_ITEM without quantity and defaults to 1")
    void testExecuteAddShoppingItem() {
        when(homeSecurityService.isMember(homeId)).thenReturn(true);
        when(homeSecurityService.canEditShoppingList(homeId)).thenReturn(true);

        UUID listId = UUID.randomUUID();
        ShoppingListDto listDto = ShoppingListDto.builder()
                .id(listId)
                .name("Main Shopping List")
                .build();
        when(shoppingService.getDefaultShoppingList(homeId)).thenReturn(listDto);
        when(shoppingListItemRepository.findPendingItemsByHomeId(homeId)).thenReturn(List.of());

        ShoppingListItemDto createdDto = ShoppingListItemDto.builder()
                .id(UUID.randomUUID())
                .itemName("Sugar")
                .quantity(BigDecimal.ONE)
                .unit("pcs")
                .build();
        when(shoppingService.addItem(eq(homeId), eq(listId), any())).thenReturn(createdDto);

        ExecuteCommandRequest req = ExecuteCommandRequest.builder()
                .homeId(homeId)
                .commandResult(VoiceCommandResult.builder()
                        .intent(VoiceIntent.ADD_SHOPPING_ITEM)
                        .entities(VoiceEntities.builder().itemName("Sugar").build())
                        .build())
                .confirmed(true)
                .build();

        ExecuteCommandResponse response = executor.execute(req);

        assertTrue(response.isSuccess());
        assertEquals(VoiceIntent.ADD_SHOPPING_ITEM, response.getIntent());
        assertTrue(response.getMessage().contains("Sugar"));
        verify(shoppingService, times(1)).addItem(eq(homeId), eq(listId), any());
    }
}

