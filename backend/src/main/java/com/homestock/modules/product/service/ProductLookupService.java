package com.homestock.modules.product.service;

import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.inventory.repository.InventoryItemRepository;
import com.homestock.modules.product.dto.ProductDto;
import com.homestock.modules.product.dto.ProductLookupResponse;
import com.homestock.modules.product.dto.ProductLookupResponse.ExistingInventorySummary;
import com.homestock.modules.product.dto.ProductLookupResponse.ExistingShoppingSummary;
import com.homestock.modules.product.entity.Product;
import com.homestock.modules.product.provider.ProductDataProvider;
import com.homestock.modules.product.repository.ProductRepository;
import com.homestock.modules.shopping.entity.ShoppingListItem;
import com.homestock.modules.shopping.repository.ShoppingListItemRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Comparator;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class ProductLookupService {

    private static final Logger log = LoggerFactory.getLogger(ProductLookupService.class);

    private final List<ProductDataProvider> providers;
    private final ProductRepository productRepository;
    private final BarcodeValidationService barcodeValidationService;
    private final InventoryItemRepository inventoryItemRepository;
    private final ShoppingListItemRepository shoppingListItemRepository;

    @Transactional
    public ProductLookupResponse lookupByBarcode(String rawBarcode, UUID homeId) {
        String normalizedBarcode = barcodeValidationService.normalizeBarcode(rawBarcode);
        String detectedType = barcodeValidationService.detectBarcodeType(normalizedBarcode);

        // Sort providers by priority (lowest int = highest priority)
        List<ProductDataProvider> sortedProviders = providers.stream()
                .sorted(Comparator.comparingInt(ProductDataProvider::getPriority))
                .toList();

        ProductDto foundDto = null;
        for (ProductDataProvider provider : sortedProviders) {
            try {
                Optional<ProductDto> result = provider.findByBarcode(normalizedBarcode);
                if (result.isPresent()) {
                    foundDto = result.get();
                    log.info("Barcode {} resolved via provider {}", normalizedBarcode, provider.getProviderName());
                    break;
                }
            } catch (Exception e) {
                log.warn("Error looking up barcode {} with provider {}: {}", normalizedBarcode, provider.getProviderName(), e.getMessage());
            }
        }

        // If found externally and not yet in PostgreSQL, persist to local catalog
        if (foundDto != null && (foundDto.getId() == null || !productRepository.existsByBarcode(normalizedBarcode))) {
            try {
                Product savedProduct = saveOrUpdateCatalogProduct(foundDto);
                foundDto.setId(savedProduct.getId());
            } catch (Exception e) {
                log.warn("Could not cache product to database: {}", e.getMessage());
            }
        }

        ProductLookupResponse.ProductLookupResponseBuilder responseBuilder = ProductLookupResponse.builder()
                .barcode(normalizedBarcode)
                .barcodeType(detectedType)
                .found(foundDto != null)
                .product(foundDto);

        // Contextual checks for existing inventory and shopping items in this home
        if (homeId != null) {
            // Check inventory
            Optional<InventoryItem> existingInv = inventoryItemRepository
                    .findByHomeIdAndBarcodeAndIsArchivedFalse(homeId, normalizedBarcode);

            if (existingInv.isEmpty() && foundDto != null && foundDto.getId() != null) {
                existingInv = inventoryItemRepository
                        .findByHomeIdAndProductIdAndIsArchivedFalse(homeId, foundDto.getId());
            }

            existingInv.ifPresent(item -> responseBuilder.existingInventoryItem(ExistingInventorySummary.builder()
                    .id(item.getId())
                    .name(item.getName())
                    .currentQuantity(item.getQuantity())
                    .minimumQuantity(item.getMinimumQuantity())
                    .unit(item.getUnit())
                    .storageLocation(item.getStorageLocation())
                    .expiryDate(item.getExpiryDate() != null ? item.getExpiryDate().toString() : null)
                    .build()));

            // Check shopping list
            Optional<ShoppingListItem> existingShop = shoppingListItemRepository
                    .findActiveItemByHomeIdAndBarcode(homeId, normalizedBarcode);

            existingShop.ifPresent(item -> responseBuilder.existingShoppingListItem(ExistingShoppingSummary.builder()
                    .id(item.getId())
                    .name(item.getItemName())
                    .quantity(item.getQuantity())
                    .unit(item.getUnit())
                    .isCompleted(item.getIsCompleted())
                    .build()));
        }

        return responseBuilder.build();
    }

    private Product saveOrUpdateCatalogProduct(ProductDto dto) {
        Optional<Product> existing = productRepository.findByBarcode(dto.getBarcode());
        Product product = existing.orElseGet(() -> Product.builder()
                .barcode(dto.getBarcode())
                .barcodeType(dto.getBarcodeType() != null ? dto.getBarcodeType() : "EAN_13")
                .name(dto.getName())
                .normalizedName(dto.getNormalizedName())
                .brand(dto.getBrand())
                .categoryName(dto.getCategoryName())
                .packageSize(dto.getPackageSize())
                .unit(dto.getUnit() != null ? dto.getUnit() : "pcs")
                .imageUrl(dto.getImageUrl())
                .source(dto.getSource() != null ? dto.getSource() : "EXTERNAL")
                .build());

        return productRepository.save(product);
    }
}
