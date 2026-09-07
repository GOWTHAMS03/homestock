package com.homestock.modules.product.service;

import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.inventory.repository.InventoryItemRepository;
import com.homestock.modules.product.dto.ProductLookupResponse;
import com.homestock.modules.product.entity.Product;
import com.homestock.modules.product.provider.InternalProductProvider;
import com.homestock.modules.product.provider.MockGroceryProductProvider;
import com.homestock.modules.product.provider.ProductDataProvider;
import com.homestock.modules.product.repository.ProductRepository;
import com.homestock.modules.shopping.entity.ShoppingListItem;
import com.homestock.modules.shopping.repository.ShoppingListItemRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class ProductLookupServiceTest {

    @Mock
    private ProductRepository productRepository;

    @Mock
    private InventoryItemRepository inventoryItemRepository;

    @Mock
    private ShoppingListItemRepository shoppingListItemRepository;

    private BarcodeValidationService barcodeValidationService;
    private MockGroceryProductProvider mockProvider;
    private InternalProductProvider internalProvider;
    private ProductLookupService service;

    @BeforeEach
    void setUp() {
        barcodeValidationService = new BarcodeValidationService();
        mockProvider = new MockGroceryProductProvider();
        internalProvider = new InternalProductProvider(productRepository);

        List<ProductDataProvider> providers = List.of(internalProvider, mockProvider);

        service = new ProductLookupService(
                providers,
                productRepository,
                barcodeValidationService,
                inventoryItemRepository,
                shoppingListItemRepository
        );
    }

    @Test
    @DisplayName("Should lookup known grocery item from mock catalog and cache to product database")
    void testLookupFromMockCatalog() {
        when(productRepository.findByBarcode("8901030000003")).thenReturn(Optional.empty());
        when(productRepository.existsByBarcode("8901030000003")).thenReturn(false);

        Product savedProduct = Product.builder()
                .barcode("8901030000003")
                .name("Tata Salt Vacuum Evaporated Iodised Salt")
                .build();
        savedProduct.setId(UUID.randomUUID());

        when(productRepository.save(any(Product.class))).thenReturn(savedProduct);

        ProductLookupResponse response = service.lookupByBarcode("8901030000003", null);

        assertTrue(response.isFound());
        assertNotNull(response.getProduct());
        assertEquals("Tata Salt Vacuum Evaporated Iodised Salt", response.getProduct().getName());
        assertEquals("EAN_13", response.getBarcodeType());
    }

    @Test
    @DisplayName("Should detect existing inventory item in home and attach context")
    void testLookupExistingInventoryItem() {
        UUID homeId = UUID.randomUUID();
        String barcode = "8901725181222"; // Aashirvaad Atta

        when(productRepository.findByBarcode(barcode)).thenReturn(Optional.empty());
        when(productRepository.existsByBarcode(barcode)).thenReturn(false);
        when(productRepository.save(any(Product.class))).thenAnswer(i -> i.getArgument(0));

        InventoryItem item = InventoryItem.builder()
                .name("Aashirvaad Atta")
                .quantity(new BigDecimal("2.0"))
                .minimumQuantity(new BigDecimal("1.0"))
                .unit("kg")
                .storageLocation("Pantry Shelf 1")
                .build();
        item.setId(UUID.randomUUID());

        when(inventoryItemRepository.findByHomeIdAndBarcodeAndIsArchivedFalse(homeId, barcode))
                .thenReturn(Optional.of(item));
        when(shoppingListItemRepository.findActiveItemByHomeIdAndBarcode(homeId, barcode))
                .thenReturn(Optional.empty());

        ProductLookupResponse response = service.lookupByBarcode(barcode, homeId);

        assertTrue(response.isFound());
        assertNotNull(response.getExistingInventoryItem());
        assertEquals(new BigDecimal("2.0"), response.getExistingInventoryItem().getCurrentQuantity());
        assertEquals("Aashirvaad Atta", response.getExistingInventoryItem().getName());
        assertNull(response.getExistingShoppingListItem());
    }

    @Test
    @DisplayName("Should return found=false for unknown barcode without throwing error")
    void testLookupUnknownBarcode() {
        when(productRepository.findByBarcode("9999999999999")).thenReturn(Optional.empty());

        ProductLookupResponse response = service.lookupByBarcode("9999999999999", null);

        assertFalse(response.isFound());
        assertNull(response.getProduct());
        assertEquals("9999999999999", response.getBarcode());
    }
}
