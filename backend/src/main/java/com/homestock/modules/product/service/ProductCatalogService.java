package com.homestock.modules.product.service;

import com.homestock.core.exception.BusinessRuleException;
import com.homestock.core.exception.ResourceNotFoundException;
import com.homestock.modules.category.entity.Category;
import com.homestock.modules.category.repository.CategoryRepository;
import com.homestock.modules.home.entity.Home;
import com.homestock.modules.home.repository.HomeRepository;
import com.homestock.modules.inventory.dto.InventoryItemDto;
import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.inventory.entity.StockTransaction;
import com.homestock.modules.inventory.entity.TransactionType;
import com.homestock.modules.inventory.repository.InventoryItemRepository;
import com.homestock.modules.inventory.repository.StockTransactionRepository;
import com.homestock.core.util.SecurityUtils;
import com.homestock.modules.product.dto.BarcodeInventoryRequest;
import com.homestock.modules.product.dto.CreateProductRequest;
import com.homestock.modules.product.dto.ProductDto;
import com.homestock.modules.product.entity.Product;
import com.homestock.modules.product.provider.InternalProductProvider;
import com.homestock.modules.product.repository.ProductRepository;
import com.homestock.modules.user.entity.User;
import com.homestock.modules.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.Optional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class ProductCatalogService {

    private final ProductRepository productRepository;
    private final InventoryItemRepository inventoryItemRepository;
    private final StockTransactionRepository stockTransactionRepository;
    private final HomeRepository homeRepository;
    private final CategoryRepository categoryRepository;
    private final UserRepository userRepository;
    private final BarcodeValidationService barcodeValidationService;
    private final InternalProductProvider internalProductProvider;

    @Transactional
    public ProductDto createProduct(CreateProductRequest request) {
        String normalizedBarcode = null;
        String barcodeType = "EAN_13";
        if (request.getBarcode() != null && !request.getBarcode().isBlank()) {
            normalizedBarcode = barcodeValidationService.normalizeBarcode(request.getBarcode());
            barcodeType = request.getBarcodeType() != null ? request.getBarcodeType() : barcodeValidationService.detectBarcodeType(normalizedBarcode);

            if (productRepository.existsByBarcode(normalizedBarcode)) {
                Product existing = productRepository.findByBarcode(normalizedBarcode).orElseThrow();
                return internalProductProvider.toDto(existing);
            }
        }

        Category category = null;
        if (request.getCategoryId() != null) {
            category = categoryRepository.findById(request.getCategoryId()).orElse(null);
        }

        String normalizedName = request.getName().toLowerCase()
                .replaceAll("[^a-z0-9\\s]", " ")
                .replaceAll("\\s+", " ")
                .trim();

        Product product = Product.builder()
                .barcode(normalizedBarcode)
                .barcodeType(barcodeType)
                .name(request.getName().trim())
                .normalizedName(normalizedName)
                .brand(request.getBrand() != null ? request.getBrand().trim() : null)
                .category(category)
                .categoryName(category != null ? category.getName() : request.getCategoryName())
                .packageSize(request.getPackageSize() != null ? request.getPackageSize() : BigDecimal.ONE)
                .unit(request.getUnit() != null ? request.getUnit().trim() : "pcs")
                .imageUrl(request.getImageUrl())
                .source("MANUAL")
                .build();

        Product saved = productRepository.save(product);
        return internalProductProvider.toDto(saved);
    }

    @Transactional(readOnly = true)
    public ProductDto getProductById(UUID id) {
        Product product = productRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Product not found with id: " + id));
        return internalProductProvider.toDto(product);
    }

    @Transactional(readOnly = true)
    public java.util.List<ProductDto> searchProducts(String query) {
        if (query == null || query.isBlank()) {
            return java.util.Collections.emptyList();
        }
        return internalProductProvider.searchByName(query.trim());
    }

    @Transactional
    public InventoryItemDto addOrUpdateInventoryFromBarcode(UUID homeId, BarcodeInventoryRequest request) {
        UUID currentUserId = SecurityUtils.getCurrentUserId();
        User currentUser = userRepository.findById(currentUserId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        Home home = homeRepository.findById(homeId)
                .orElseThrow(() -> new ResourceNotFoundException("Home not found"));

        String normalizedBarcode = barcodeValidationService.normalizeBarcode(request.getBarcode());

        // 1. Check if an item already exists with this barcode in this home
        Optional<InventoryItem> existingItemOpt = inventoryItemRepository
                .findByHomeIdAndBarcodeAndIsArchivedFalse(homeId, normalizedBarcode);

        if (existingItemOpt.isPresent()) {
            // Already in home: Stock in to the existing item
            InventoryItem item = existingItemOpt.get();
            BigDecimal previousQty = item.getQuantity();
            BigDecimal newQty = previousQty.add(request.getQuantity());
            item.setQuantity(newQty);
            if (request.getExpiryDate() != null) {
                item.setExpiryDate(request.getExpiryDate());
            }
            if (request.getStorageLocation() != null) {
                item.setStorageLocation(request.getStorageLocation());
            }
            InventoryItem saved = inventoryItemRepository.save(item);

            StockTransaction tx = StockTransaction.builder()
                    .home(home)
                    .item(saved)
                    .user(currentUser)
                    .transactionType(TransactionType.STOCK_IN)
                    .quantityChange(request.getQuantity())
                    .previousQuantity(previousQty)
                    .newQuantity(newQty)
                    .unit(saved.getUnit())
                    .reason(request.getNotes() != null ? request.getNotes() : "Scanned barcode stock in")
                    .build();
            stockTransactionRepository.save(tx);

            return toInventoryDto(saved);
        }

        // 2. New product in this home: find or create Product
        Optional<Product> catalogProduct = productRepository.findByBarcode(normalizedBarcode);

        String itemName = catalogProduct.map(Product::getName).orElse("Scanned Product (" + normalizedBarcode + ")");
        String brand = catalogProduct.map(Product::getBrand).orElse(null);
        String unit = request.getUnit() != null ? request.getUnit() : catalogProduct.map(Product::getUnit).orElse("pcs");
        String imageUrl = catalogProduct.map(Product::getImageUrl).orElse(null);
        Category category = catalogProduct.map(Product::getCategory).orElse(null);

        InventoryItem newItem = InventoryItem.builder()
                .home(home)
                .product(catalogProduct.orElse(null))
                .barcode(normalizedBarcode)
                .name(itemName)
                .brand(brand)
                .category(category)
                .quantity(request.getQuantity())
                .unit(unit)
                .minimumQuantity(request.getMinimumQuantity() != null ? request.getMinimumQuantity() : BigDecimal.ONE)
                .storageLocation(request.getStorageLocation())
                .purchasePrice(request.getPurchasePrice())
                .expiryDate(request.getExpiryDate())
                .imageUrl(imageUrl)
                .notes(request.getNotes())
                .isArchived(false)
                .build();

        InventoryItem saved = inventoryItemRepository.save(newItem);

        StockTransaction tx = StockTransaction.builder()
                .home(home)
                .item(saved)
                .user(currentUser)
                .transactionType(TransactionType.STOCK_IN)
                .quantityChange(request.getQuantity())
                .previousQuantity(BigDecimal.ZERO)
                .newQuantity(request.getQuantity())
                .unit(saved.getUnit())
                .reason("Initial barcode scan stock-in")
                .build();
        stockTransactionRepository.save(tx);

        return toInventoryDto(saved);
    }

    private InventoryItemDto toInventoryDto(InventoryItem item) {
        return InventoryItemDto.builder()
                .id(item.getId())
                .homeId(item.getHome().getId())
                .categoryId(item.getCategory() != null ? item.getCategory().getId() : null)
                .categoryName(item.getCategory() != null ? item.getCategory().getName() : "General")
                .categoryIcon(item.getCategory() != null ? item.getCategory().getIcon() : "category")
                .categoryColor(item.getCategory() != null ? item.getCategory().getColorHex() : "#6366F1")
                .name(item.getName())
                .brand(item.getBrand())
                .quantity(item.getQuantity())
                .unit(item.getUnit())
                .minimumQuantity(item.getMinimumQuantity())
                .maximumQuantity(item.getMaximumQuantity())
                .storageLocation(item.getStorageLocation())
                .purchasePrice(item.getPurchasePrice())
                .purchaseDate(item.getPurchaseDate())
                .expiryDate(item.getExpiryDate())
                .imageUrl(item.getImageUrl())
                .notes(item.getNotes())
                .stockStatus(item.calculateStockStatus())
                .expiryStatus(item.calculateExpiryStatus())
                .daysUntilExpiry(item.getDaysUntilExpiry())
                .build();
    }
}
