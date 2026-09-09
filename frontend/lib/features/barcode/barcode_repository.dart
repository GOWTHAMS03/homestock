import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/household_staples.dart';
import '../../core/database/app_database.dart';
import '../../core/network/api_client.dart';
import '../../core/sync/connectivity_monitor.dart';
import '../../core/sync/sync_providers.dart' show databaseProvider, connectivityMonitorProvider;
import '../auth/auth_controller.dart' show apiClientProvider;
import '../inventory/inventory_controller.dart' show inventoryRepositoryProvider;
import '../inventory/inventory_repository.dart';
import '../shopping/shopping_controller.dart' show shoppingRepositoryProvider;
import '../shopping/shopping_repository.dart';
import 'barcode_models.dart';
import 'barcode_normalization_service.dart';

const _uuid = Uuid();

final barcodeRepositoryProvider = Provider<BarcodeRepository>((ref) {
  return BarcodeRepository(
    db: ref.watch(databaseProvider),
    apiClient: ref.watch(apiClientProvider),
    connectivity: ref.watch(connectivityMonitorProvider),
    inventoryRepository: ref.watch(inventoryRepositoryProvider),
    shoppingRepository: ref.watch(shoppingRepositoryProvider),
    normalizer: BarcodeNormalizationService(),
  );
});

class BarcodeRepository {
  final AppDatabase _db;
  final ApiClient _apiClient;
  final ConnectivityMonitor _connectivity;
  final InventoryRepository _inventoryRepository;
  final ShoppingRepository _shoppingRepository;
  final BarcodeNormalizationService _normalizer;

  BarcodeRepository({
    required AppDatabase db,
    required ApiClient apiClient,
    required ConnectivityMonitor connectivity,
    required InventoryRepository inventoryRepository,
    required ShoppingRepository shoppingRepository,
    required BarcodeNormalizationService normalizer,
  })  : _db = db,
        _apiClient = apiClient,
        _connectivity = connectivity,
        _inventoryRepository = inventoryRepository,
        _shoppingRepository = shoppingRepository,
        _normalizer = normalizer;

  BarcodeNormalizationService get normalizer => _normalizer;

  /// Looks up product by barcode local-first, then falls back to backend API if online.
  Future<BarcodeLookupResult> lookupBarcode(String rawBarcode, {required String homeId}) async {
    final normalized = _normalizer.normalizeBarcode(rawBarcode);
    final detectedType = _normalizer.detectBarcodeType(normalized);

    // 1. LOCAL-FIRST: Check local inventory in this home
    LocalInventoryItem? existingInvItem;
    try {
      existingInvItem = await (_db.select(_db.localInventoryItems)
            ..where((t) => t.homeId.equals(homeId) & t.barcode.equals(normalized) & t.isDeleted.equals(false)))
          .getSingleOrNull();
    } catch (_) {}

    // Check local shopping list in this home
    LocalShoppingListItem? existingShoppingItem;
    try {
      existingShoppingItem = await (_db.select(_db.localShoppingListItems)
            ..where((t) => t.barcode.equals(normalized) & t.isDeleted.equals(false) & t.isCompleted.equals(false)))
          .getSingleOrNull();
    } catch (_) {}

    // Check local catalog cache
    LocalProduct? cachedProduct;
    try {
      cachedProduct = await (_db.select(_db.localProducts)
            ..where((t) => t.barcode.equals(normalized)))
          .getSingleOrNull();
    } catch (_) {}

    // If we have both existing inventory item or cached product locally:
    if (existingInvItem != null || cachedProduct != null) {
      final productModel = cachedProduct != null
          ? ProductCatalogModel(
              id: cachedProduct.id,
              barcode: cachedProduct.barcode ?? normalized,
              barcodeType: cachedProduct.barcodeType,
              name: cachedProduct.name,
              normalizedName: cachedProduct.normalizedName,
              brand: cachedProduct.brand,
              categoryId: cachedProduct.categoryId,
              categoryName: cachedProduct.categoryName,
              packageSize: cachedProduct.packageSize,
              unit: cachedProduct.unit,
              imageUrl: cachedProduct.imageUrl,
              source: 'LOCAL_CACHE',
            )
          : ProductCatalogModel(
              barcode: normalized,
              barcodeType: detectedType.displayName,
              name: existingInvItem!.name,
              normalizedName: existingInvItem.name.toLowerCase(),
              brand: existingInvItem.brand,
              categoryId: existingInvItem.categoryId,
              categoryName: existingInvItem.categoryName,
              unit: existingInvItem.unit,
              imageUrl: existingInvItem.imageUrl,
              source: 'LOCAL_INVENTORY',
            );

      return BarcodeLookupResult(
        found: true,
        barcode: normalized,
        barcodeType: detectedType.displayName,
        product: productModel,
        existingInventory: existingInvItem != null
            ? ExistingInventoryContext(
                id: existingInvItem.id,
                name: existingInvItem.name,
                currentQuantity: existingInvItem.quantity,
                minimumQuantity: existingInvItem.minimumQuantity,
                unit: existingInvItem.unit,
                storageLocation: existingInvItem.storageLocation,
                expiryDate: existingInvItem.expiryDate,
              )
            : null,
        existingShopping: existingShoppingItem != null
            ? ExistingShoppingContext(
                id: existingShoppingItem.id,
                name: existingShoppingItem.itemName,
                quantity: existingShoppingItem.quantity,
                unit: existingShoppingItem.unit,
                isCompleted: existingShoppingItem.isCompleted,
              )
            : null,
        isFromLocalCache: true,
      );
    }

    // 1b. MASTER CATALOG LOOKUP: Check offline 2,055 product master staples
    final stapleMatch = findStapleForName(normalized);
    if (stapleMatch != null) {
      final productModel = ProductCatalogModel(
        barcode: normalized,
        barcodeType: detectedType.displayName,
        name: stapleMatch.name,
        normalizedName: stapleMatch.name.toLowerCase(),
        brand: stapleMatch.customBrands?.firstOrNull,
        categoryName: stapleMatch.category,
        unit: stapleMatch.defaultUnit,
        source: 'MASTER_CATALOG',
      );

      return BarcodeLookupResult(
        found: true,
        barcode: normalized,
        barcodeType: detectedType.displayName,
        product: productModel,
        existingInventory: null,
        existingShopping: null,
        isFromLocalCache: true,
      );
    }

    // 2. ONLINE LOOKUP: Query HomeStock backend API
    if (_connectivity.isOnline) {
      try {
        final response = await _apiClient.dio.get(
          '/api/v1/products/barcode/$normalized',
          queryParameters: {'homeId': homeId},
        );

        if (response.data != null && response.data is Map) {
          final Map<String, dynamic> data = Map<String, dynamic>.from(response.data as Map);
          final Map<String, dynamic> resultData = data['data'] is Map
              ? Map<String, dynamic>.from(data['data'] as Map)
              : data;

          final result = BarcodeLookupResult.fromJson(resultData);

          // Cache product locally in SQLite for future offline & fast scans
          if (result.found && result.product != null) {
            await cacheProductLocally(result.product!);
          }

          return result;
        }
      } catch (e) {
        // Fallback gracefully on network timeout or server error
      }
    }

    // 3. UNKNOWN OR OFFLINE NOT FOUND
    return BarcodeLookupResult(
      found: false,
      barcode: normalized,
      barcodeType: detectedType.displayName,
      isFromLocalCache: false,
    );
  }

  /// Caches a resolved product into the local Drift database
  Future<void> cacheProductLocally(ProductCatalogModel product) async {
    try {
      final now = DateTime.now();
      await _db.into(_db.localProducts).insertOnConflictUpdate(
            LocalProductsCompanion(
              id: Value(product.id ?? _uuid.v4()),
              barcode: Value(product.barcode),
              barcodeType: Value(product.barcodeType),
              name: Value(product.name),
              normalizedName: Value(product.normalizedName.isNotEmpty
                  ? product.normalizedName
                  : product.name.toLowerCase()),
              brand: Value(product.brand),
              categoryId: Value(product.categoryId),
              categoryName: Value(product.categoryName),
              packageSize: Value(product.packageSize),
              unit: Value(product.unit),
              imageUrl: Value(product.imageUrl),
              source: Value(product.source),
              updatedAt: Value(now),
            ),
          );
    } catch (_) {}
  }

  /// Manually adds a product to local cache and syncs to backend
  Future<ProductCatalogModel> createProduct(ProductCatalogModel product) async {
    await cacheProductLocally(product);

    if (_connectivity.isOnline) {
      try {
        await _apiClient.dio.post(
          '/api/v1/products',
          data: product.toJson(),
        );
      } catch (_) {}
    }
    return product;
  }

  /// Restocks an existing inventory item or creates a new one from a barcode
  Future<void> addOrUpdateInventory({
    required String homeId,
    required String barcode,
    required double quantity,
    String? existingItemId,
    ProductCatalogModel? product,
    String? location,
    String? expiryDate,
    double? minQty,
    double? purchasePrice,
    String? notes,
  }) async {
    if (existingItemId != null) {
      // Stock In to existing item
      await _inventoryRepository.updateStock(
        homeId,
        existingItemId,
        transactionType: 'STOCK_IN',
        quantityChange: quantity,
        reason: notes ?? 'Barcode scanned restock',
      );
    } else {
      // Create new inventory item
      final name = product?.name ?? 'Scanned Item ($barcode)';
      await _inventoryRepository.createItem(homeId, {
        'barcode': barcode,
        'productId': product?.id,
        'name': name,
        'brand': product?.brand,
        'categoryId': product?.categoryId,
        'categoryName': product?.categoryName ?? 'General',
        'quantity': quantity,
        'unit': product?.unit ?? 'pcs',
        'minimumQuantity': minQty ?? 1.0,
        'storageLocation': location,
        'purchasePrice': purchasePrice,
        'expiryDate': expiryDate,
        'imageUrl': product?.imageUrl,
        'notes': notes ?? 'Added via Barcode Scanner',
      });
    }
  }

  /// Adds a scanned product to the shopping list
  Future<void> addToShoppingList({
    required String homeId,
    required ProductCatalogModel product,
    required double quantity,
    String? inventoryItemId,
    String? notes,
  }) async {
    await _shoppingRepository.addItem(
      homeId,
      null, // default list
      itemName: product.name,
      inventoryItemId: inventoryItemId,
      categoryId: product.categoryId,
      categoryName: product.categoryName,
      quantity: quantity,
      unit: product.unit,
      notes: notes ?? 'Added from barcode ${product.barcode}',
    );
  }
}
