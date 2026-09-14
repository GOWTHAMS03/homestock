package com.homestock.modules.voice;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.homestock.core.security.HomeSecurityService;
import com.homestock.modules.home.entity.Home;
import com.homestock.modules.home.repository.HomeRepository;
import com.homestock.modules.inventory.dto.InventoryItemDto;
import com.homestock.modules.inventory.dto.StockUpdateRequest;
import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.inventory.entity.TransactionType;
import com.homestock.modules.inventory.repository.InventoryItemRepository;
import com.homestock.modules.inventory.repository.StockTransactionRepository;
import com.homestock.modules.inventory.service.InventoryService;
import com.homestock.modules.product.repository.ProductRepository;
import com.homestock.modules.shopping.repository.ShoppingListItemRepository;
import com.homestock.modules.shopping.repository.ShoppingListRepository;
import com.homestock.modules.shopping.service.ShoppingService;
import com.homestock.modules.voice.config.VoiceProperties;
import com.homestock.modules.voice.dto.*;
import com.homestock.modules.voice.provider.SpeechToTextProvider;
import com.homestock.modules.voice.service.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class VoiceQuantityValidationIntegrationTest {

    @Mock private SpeechToTextProvider speechToTextProvider;
    @Mock private GeminiVoiceService geminiVoiceService;
    @Mock private ShoppingService shoppingService;
    @Mock private ShoppingListItemRepository shoppingListItemRepository;
    @Mock private ShoppingListRepository shoppingListRepository;
    @Mock private InventoryService inventoryService;
    @Mock private InventoryItemRepository inventoryItemRepository;
    @Mock private HomeRepository homeRepository;
    @Mock private HomeSecurityService homeSecurityService;
    @Mock private ProductRepository productRepository;
    @Mock private StockTransactionRepository stockTransactionRepository;
    @Mock private VoiceAuditService voiceAuditService;

    private UnitNormalizationService unitNormalizer;
    private NumberNormalizationService numberNormalizer;
    private TamilTanglishNormalizer tamilNormalizer;
    private ProductMatcher productMatcher;
    private VoiceCommandParser voiceCommandParser;
    private VoiceIntentService voiceIntentService;
    private VoiceResponseGenerator voiceResponseGenerator;
    private VoiceCommandValidator voiceCommandValidator;
    private VoiceCommandExecutor voiceCommandExecutor;
    private VoiceService voiceService;

    private final UUID homeId = UUID.randomUUID();
    private final UUID riceItemId = UUID.randomUUID();
    private final UUID oilItemId = UUID.randomUUID();
    private final UUID sugarItemId = UUID.randomUUID();

    private InventoryItem riceItem;
    private InventoryItem oilItem;
    private InventoryItem sugarItem;

    @BeforeEach
    void setUp() {
        unitNormalizer = new UnitNormalizationService();
        numberNormalizer = new NumberNormalizationService();
        tamilNormalizer = new TamilTanglishNormalizer();
        productMatcher = new ProductMatcher(inventoryItemRepository, tamilNormalizer);
        voiceCommandParser = new VoiceCommandParser(unitNormalizer, numberNormalizer, tamilNormalizer, productMatcher);

        voiceIntentService = new VoiceIntentService();
        voiceResponseGenerator = new VoiceResponseGenerator();
        voiceCommandValidator = new VoiceCommandValidator(
                homeSecurityService,
                voiceIntentService,
                inventoryItemRepository,
                stockTransactionRepository,
                unitNormalizer
        );

        ProductResolutionService resolutionService = new ProductResolutionService(
                inventoryItemRepository, productRepository, tamilNormalizer);

        voiceCommandExecutor = new VoiceCommandExecutor(
                shoppingService,
                shoppingListItemRepository,
                shoppingListRepository,
                inventoryService,
                inventoryItemRepository,
                homeRepository,
                homeSecurityService,
                resolutionService,
                productRepository,
                unitNormalizer
        );

        VoiceProperties voiceProperties = new VoiceProperties();
        ObjectMapper objectMapper = new ObjectMapper();
        VoiceContextService voiceContextService = new VoiceContextService(voiceProperties, objectMapper, null);
        IdempotencyService idempotencyService = new IdempotencyService(voiceProperties, objectMapper, null);

        voiceService = new VoiceService(
                speechToTextProvider,
                voiceCommandParser,
                voiceCommandExecutor,
                geminiVoiceService,
                resolutionService,
                voiceIntentService,
                voiceCommandValidator,
                voiceContextService,
                idempotencyService,
                voiceResponseGenerator,
                voiceAuditService,
                voiceProperties
        );

        // Setup rice item with 9 kg existing stock
        Home home = new Home();
        home.setId(homeId);

        riceItem = new InventoryItem();
        riceItem.setId(riceItemId);
        riceItem.setHome(home);
        riceItem.setIsArchived(false);
        riceItem.setName("Rice");
        riceItem.setQuantity(new BigDecimal("9"));
        riceItem.setUnit("KG");

        // Setup oil item with 2 L existing stock
        oilItem = new InventoryItem();
        oilItem.setId(oilItemId);
        oilItem.setHome(home);
        oilItem.setIsArchived(false);
        oilItem.setName("Cooking Oil");
        oilItem.setQuantity(new BigDecimal("2"));
        oilItem.setUnit("L");

        // Setup sugar item with 3 PACK existing stock
        sugarItem = new InventoryItem();
        sugarItem.setId(sugarItemId);
        sugarItem.setHome(home);
        sugarItem.setIsArchived(false);
        sugarItem.setName("Sugar");
        sugarItem.setQuantity(new BigDecimal("3"));
        sugarItem.setUnit("PACK");

        lenient().when(homeSecurityService.isMember(homeId)).thenReturn(true);
        lenient().when(homeSecurityService.canManageInventory(homeId)).thenReturn(true);
        lenient().when(homeSecurityService.canEditShoppingList(homeId)).thenReturn(true);
        lenient().when(inventoryItemRepository.findAll()).thenReturn(List.of(riceItem, oilItem, sugarItem));
        lenient().when(inventoryItemRepository.findAllByHomeIdOrderByNameAsc(homeId)).thenReturn(List.of(riceItem, oilItem, sugarItem));
        lenient().when(inventoryItemRepository.findAll(any(org.springframework.data.jpa.domain.Specification.class))).thenReturn(List.of(riceItem, oilItem, sugarItem));
        lenient().when(inventoryItemRepository.findByIdAndHomeId(eq(riceItemId), eq(homeId))).thenReturn(Optional.of(riceItem));
        lenient().when(inventoryItemRepository.findByIdAndHomeId(eq(oilItemId), eq(homeId))).thenReturn(Optional.of(oilItem));
        lenient().when(inventoryItemRepository.findByIdAndHomeId(eq(sugarItemId), eq(homeId))).thenReturn(Optional.of(sugarItem));
    }

    @Test
    @DisplayName("Bug Fix: 'add 200 kg rice' on 9 kg stock triggers confirmation UI with 209 kg projected stock, never silent 209 kg update")
    void testAdd200KgRiceTriggersConfirmationUI() {
        // 1. Parse command via VoiceService
        VoiceCommandResult parsed = voiceService.parseCommand("add 200 kg rice", homeId);

        // Verify detected quantity is preserved as 200 kg
        assertEquals("ADD", parsed.getAction());
        assertEquals(VoiceIntent.STOCK_IN, parsed.getIntent());
        assertEquals(0, new BigDecimal("200").compareTo(parsed.getEntities().getQuantity()));
        assertTrue("KG".equalsIgnoreCase(parsed.getEntities().getUnit()));

        // Verify confirmation required
        assertTrue(parsed.isRequiresConfirmation());
        assertEquals("NEEDS_QUANTITY_CONFIRMATION", parsed.getExecutionStatus());
        assertNotNull(parsed.getQuantityConfirmation());

        QuantityConfirmationInfo info = parsed.getQuantityConfirmation();
        assertEquals("ADD", info.getAction());
        assertEquals("Rice", info.getProductName());
        assertEquals(0, new BigDecimal("200").compareTo(info.getRequestedQuantity()));
        assertTrue("KG".equalsIgnoreCase(info.getRequestedUnit()));
        assertEquals(0, new BigDecimal("9").compareTo(info.getCurrentQuantity()));
        assertTrue("KG".equalsIgnoreCase(info.getCurrentUnit()));
        assertEquals(0, new BigDecimal("209").compareTo(info.getProjectedQuantity()));

        // Verify the exact prompt required by Requirement 7
        assertEquals("Add 200 kg of Rice?", info.getPromptTitle());
        assertEquals("You currently have 9 kg.", info.getPromptCurrent());
        assertEquals("Your new stock will be 209 kg.", info.getPromptProjected());

        // 2. If unconfirmed, execution MUST be blocked
        ExecuteCommandRequest unconfirmedReq = ExecuteCommandRequest.builder()
                .homeId(homeId)
                .commandResult(parsed)
                .confirmed(false)
                .build();

        ExecuteCommandResponse unconfirmedResp = voiceService.execute(unconfirmedReq);
        assertFalse(unconfirmedResp.isSuccess());
        assertEquals("NEEDS_CONFIRMATION", unconfirmedResp.getExecutionStatus());
        verify(inventoryService, never()).updateStock(any(), any(), any());

        // 3. When user confirms, stock update is executed to 209 kg
        InventoryItemDto updatedDto = new InventoryItemDto();
        updatedDto.setId(riceItemId);
        updatedDto.setName("Rice");
        updatedDto.setQuantity(new BigDecimal("209"));
        updatedDto.setUnit("KG");

        when(inventoryService.updateStock(eq(homeId), eq(riceItemId), any(StockUpdateRequest.class)))
                .thenReturn(updatedDto);

        ExecuteCommandRequest confirmedReq = ExecuteCommandRequest.builder()
                .homeId(homeId)
                .commandResult(parsed)
                .confirmed(true)
                .build();

        ExecuteCommandResponse confirmedResp = voiceService.execute(confirmedReq);
        assertTrue(confirmedResp.isSuccess());

        ArgumentCaptor<StockUpdateRequest> captor = ArgumentCaptor.forClass(StockUpdateRequest.class);
        verify(inventoryService).updateStock(eq(homeId), eq(riceItemId), captor.capture());
        assertEquals(TransactionType.STOCK_IN, captor.getValue().getTransactionType());
        assertEquals(0, new BigDecimal("200").compareTo(captor.getValue().getQuantityChange()));
    }

    @Test
    @DisplayName("'set rice to 10 kg' updates stock to 10 kg, never adds to existing 9 kg")
    void testSetRiceTo10Kg() {
        VoiceCommandResult parsed = voiceService.parseCommand("set rice to 10 kg", homeId);
        assertEquals("SET", parsed.getAction());
        assertEquals(VoiceIntent.UPDATE_STOCK, parsed.getIntent());
        assertEquals(0, new BigDecimal("10").compareTo(parsed.getEntities().getQuantity()));

        InventoryItemDto updatedDto = new InventoryItemDto();
        updatedDto.setId(riceItemId);
        updatedDto.setName("Rice");
        updatedDto.setQuantity(new BigDecimal("10"));
        updatedDto.setUnit("KG");

        when(inventoryService.updateStock(eq(homeId), eq(riceItemId), any(StockUpdateRequest.class)))
                .thenReturn(updatedDto);

        ExecuteCommandRequest req = ExecuteCommandRequest.builder()
                .homeId(homeId)
                .commandResult(parsed)
                .confirmed(true)
                .build();

        ExecuteCommandResponse resp = voiceService.execute(req);
        assertTrue(resp.isSuccess());

        ArgumentCaptor<StockUpdateRequest> captor = ArgumentCaptor.forClass(StockUpdateRequest.class);
        verify(inventoryService).updateStock(eq(homeId), eq(riceItemId), captor.capture());
        // ADJUSTMENT sets absolute stock to 10 kg
        assertEquals(TransactionType.ADJUSTMENT, captor.getValue().getTransactionType());
        assertEquals(0, new BigDecimal("10").compareTo(captor.getValue().getQuantityChange()));
    }

    @Test
    @DisplayName("'remove 2 kg rice' deducts 2 kg from existing 9 kg to 7 kg")
    void testRemove2KgRice() {
        VoiceCommandResult parsed = voiceService.parseCommand("remove 2 kg rice", homeId);
        assertEquals("REMOVE", parsed.getAction());
        assertEquals(VoiceIntent.STOCK_OUT, parsed.getIntent());

        InventoryItemDto updatedDto = new InventoryItemDto();
        updatedDto.setId(riceItemId);
        updatedDto.setName("Rice");
        updatedDto.setQuantity(new BigDecimal("7"));
        updatedDto.setUnit("KG");

        when(inventoryService.updateStock(eq(homeId), eq(riceItemId), any(StockUpdateRequest.class)))
                .thenReturn(updatedDto);

        ExecuteCommandRequest req = ExecuteCommandRequest.builder()
                .homeId(homeId)
                .commandResult(parsed)
                .confirmed(true)
                .build();

        ExecuteCommandResponse resp = voiceService.execute(req);
        assertTrue(resp.isSuccess());

        ArgumentCaptor<StockUpdateRequest> captor = ArgumentCaptor.forClass(StockUpdateRequest.class);
        verify(inventoryService).updateStock(eq(homeId), eq(riceItemId), captor.capture());
        assertEquals(TransactionType.STOCK_OUT, captor.getValue().getTransactionType());
        assertEquals(0, new BigDecimal("2").compareTo(captor.getValue().getQuantityChange()));
    }

    @Test
    @DisplayName("'add 500 grams rice' converts 500 g to 0.5 kg before stock update")
    void testAdd500GramsRiceUnitConversion() {
        VoiceCommandResult parsed = voiceService.parseCommand("add 500 grams rice", homeId);
        assertEquals("ADD", parsed.getAction());
        assertEquals(0, new BigDecimal("500").compareTo(parsed.getEntities().getQuantity()));
        assertTrue("G".equalsIgnoreCase(parsed.getEntities().getUnit()));

        InventoryItemDto updatedDto = new InventoryItemDto();
        updatedDto.setId(riceItemId);
        updatedDto.setName("Rice");
        updatedDto.setQuantity(new BigDecimal("9.5"));
        updatedDto.setUnit("KG");

        when(inventoryService.updateStock(eq(homeId), eq(riceItemId), any(StockUpdateRequest.class)))
                .thenReturn(updatedDto);

        ExecuteCommandRequest req = ExecuteCommandRequest.builder()
                .homeId(homeId)
                .commandResult(parsed)
                .confirmed(true)
                .build();

        ExecuteCommandResponse resp = voiceService.execute(req);
        assertTrue(resp.isSuccess());

        ArgumentCaptor<StockUpdateRequest> captor = ArgumentCaptor.forClass(StockUpdateRequest.class);
        verify(inventoryService).updateStock(eq(homeId), eq(riceItemId), captor.capture());
        assertEquals(TransactionType.STOCK_IN, captor.getValue().getTransactionType());
        // 500 grams converted to 0.5 kg
        assertEquals(0, new BigDecimal("0.5").compareTo(captor.getValue().getQuantityChange()));
    }

    @Test
    @DisplayName("'add 2 packets sugar' adds 2 packets to existing 3 packets")
    void testAdd2PacketsSugar() {
        VoiceCommandResult parsed = voiceService.parseCommand("add 2 packets sugar", homeId);
        assertEquals("ADD", parsed.getAction());
        assertEquals(0, new BigDecimal("2").compareTo(parsed.getEntities().getQuantity()));
        assertTrue("PACK".equalsIgnoreCase(parsed.getEntities().getUnit()));

        InventoryItemDto updatedDto = new InventoryItemDto();
        updatedDto.setId(sugarItemId);
        updatedDto.setName("Sugar");
        updatedDto.setQuantity(new BigDecimal("5"));
        updatedDto.setUnit("PACK");

        when(inventoryService.updateStock(eq(homeId), eq(sugarItemId), any(StockUpdateRequest.class)))
                .thenReturn(updatedDto);

        ExecuteCommandRequest req = ExecuteCommandRequest.builder()
                .homeId(homeId)
                .commandResult(parsed)
                .confirmed(true)
                .build();

        ExecuteCommandResponse resp = voiceService.execute(req);
        assertTrue(resp.isSuccess());

        ArgumentCaptor<StockUpdateRequest> captor = ArgumentCaptor.forClass(StockUpdateRequest.class);
        verify(inventoryService).updateStock(eq(homeId), eq(sugarItemId), captor.capture());
        assertEquals(TransactionType.STOCK_IN, captor.getValue().getTransactionType());
        assertEquals(0, new BigDecimal("2").compareTo(captor.getValue().getQuantityChange()));
    }

    @Test
    @DisplayName("Unsafe conversion: 'add 2 kg cooking oil' on 'L' item is safely rejected")
    void testUnsafeCrossDimensionalConversionRejected() {
        VoiceEntities entities = VoiceEntities.builder()
                .itemName("Cooking Oil")
                .quantity(new BigDecimal("2"))
                .unit("KG")
                .action("ADD")
                .matchedInventoryItemId(oilItemId)
                .build();

        VoiceCommandResult cmd = VoiceCommandResult.builder()
                .intent(VoiceIntent.STOCK_IN)
                .action("ADD")
                .entities(entities)
                .build();

        // Validator detects incompatible units (MASS vs VOLUME)
        var valResult = voiceCommandValidator.validate(homeId, cmd);
        assertFalse(valResult.isValid());
        assertTrue(valResult.getErrorMessage().contains("Measurement types are incompatible"));

        // Executor also guards against incompatible conversion
        ExecuteCommandRequest req = ExecuteCommandRequest.builder()
                .homeId(homeId)
                .commandResult(cmd)
                .confirmed(true)
                .build();

        ExecuteCommandResponse execResp = voiceCommandExecutor.execute(req);
        assertFalse(execResp.isSuccess());
        assertTrue(execResp.getMessage().contains("incompatible"));
        verify(inventoryService, never()).updateStock(any(), any(), any());
    }

    @Test
    @DisplayName("Speech-to-text misrecognition safeguards: 200 kg instead of 2 kg pauses for confirmation")
    void testMisrecognitionSafeguard() {
        // When STT misrecognizes "2 kg" as "200 kg"
        VoiceCommandResult parsed = voiceService.parseCommand("add 200 kg rice", homeId);
        assertTrue(parsed.isRequiresConfirmation());
        assertEquals("NEEDS_QUANTITY_CONFIRMATION", parsed.getExecutionStatus());
        assertNotNull(parsed.getQuantityConfirmation());
        assertTrue(parsed.getQuantityConfirmation().getWarningReason().contains("unusually high"));
    }
}
