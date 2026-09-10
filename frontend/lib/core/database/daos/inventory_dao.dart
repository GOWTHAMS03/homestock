import 'package:drift/drift.dart';
import '../app_database.dart';
import '../../../features/inventory/category_model.dart';

/// Data access object for inventory items and stock transactions.
/// Provides reactive streams and CRUD operations against local SQLite.
class InventoryDao {
  final AppDatabase _db;

  InventoryDao(this._db);

  // ──── READ ────

  /// Watch all non-deleted items for a home, ordered by name.
  Stream<List<LocalInventoryItem>> watchItems(String homeId) {
    return (_db.select(_db.localInventoryItems)
          ..where((t) => t.homeId.equals(homeId) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  /// Watch items filtered by category.
  Stream<List<LocalInventoryItem>> watchItemsByCategory(
      String homeId, String categoryId) {
    return (_db.select(_db.localInventoryItems)
          ..where((t) =>
              t.homeId.equals(homeId) &
              t.isDeleted.equals(false) &
              t.categoryId.equals(categoryId))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  /// Watch items matching a search query (name or brand) and/or category.
  Stream<List<LocalInventoryItem>> watchItemsFiltered(
    String homeId, {
    String? categoryId,
    String? categoryName,
    String? query,
  }) {
    return (_db.select(_db.localInventoryItems)
          ..where((t) {
            var condition = t.homeId.equals(homeId) & t.isDeleted.equals(false);
            if (categoryId != null) {
              if (categoryName != null && categoryName.isNotEmpty) {
                condition = condition &
                    (t.categoryId.equals(categoryId) |
                        t.categoryName.lower().equals(categoryName.toLowerCase()));
              } else {
                condition = condition & t.categoryId.equals(categoryId);
              }
            }
            if (query != null && query.isNotEmpty) {
              final pattern = '%${query.toLowerCase()}%';
              condition = condition &
                  (t.name.lower().like(pattern) |
                      t.brand.lower().like(pattern));
            }
            return condition;
          })
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  /// Get a single item by ID.
  Future<LocalInventoryItem?> getItemById(String id) {
    return (_db.select(_db.localInventoryItems)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Get a single item by ID strictly within a home.
  Future<LocalInventoryItem?> getItemByIdAndHome(String homeId, String id) {
    return (_db.select(_db.localInventoryItems)
          ..where((t) =>
              t.id.equals(id) &
              t.homeId.equals(homeId) &
              t.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  /// Get item by barcode for a home.
  Future<LocalInventoryItem?> getItemByBarcode(String homeId, String barcode) {
    return (_db.select(_db.localInventoryItems)
          ..where((t) =>
              t.homeId.equals(homeId) &
              t.barcode.equals(barcode) &
              t.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  /// Get item by product ID for a home.
  Future<LocalInventoryItem?> getItemByProductId(String homeId, String productId) {
    return (_db.select(_db.localInventoryItems)
          ..where((t) =>
              t.homeId.equals(homeId) &
              t.productId.equals(productId) &
              t.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  /// Find an item by matching name (case-insensitive) for a home.
  Future<LocalInventoryItem?> findItemByName(String homeId, String name) async {
    final clean = name.trim().toLowerCase();
    if (clean.isEmpty) return null;

    // 1. Exact match (case-insensitive)
    final exact = await (_db.select(_db.localInventoryItems)
          ..where((t) =>
              t.homeId.equals(homeId) &
              t.isDeleted.equals(false) &
              t.name.lower().equals(clean))
          ..limit(1))
        .get();
    if (exact.isNotEmpty) return exact.first;

    // 2. Substring match (e.g. "Milk" matches "Amul Milk")
    final contains = await (_db.select(_db.localInventoryItems)
          ..where((t) =>
              t.homeId.equals(homeId) &
              t.isDeleted.equals(false) &
              t.name.lower().like('%$clean%'))
          ..limit(1))
        .get();
    return contains.firstOrNull;
  }


  /// Get all items for a home (non-reactive, for sync use).
  Future<List<LocalInventoryItem>> getAllItems(String homeId) {
    return (_db.select(_db.localInventoryItems)
          ..where((t) => t.homeId.equals(homeId) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  /// Get item count for a home.
  Future<int> getItemCount(String homeId) async {
    final items = await getAllItems(homeId);
    return items.length;
  }

  /// Get low stock items.
  Future<List<LocalInventoryItem>> getLowStockItems(String homeId) async {
    return (_db.select(_db.localInventoryItems)
          ..where((t) =>
              t.homeId.equals(homeId) &
              t.isDeleted.equals(false) &
              (t.stockStatus.equals('LOW_STOCK') |
                  t.stockStatus.equals('OUT_OF_STOCK'))))
        .get();
  }

  /// Get expiring soon items.
  Future<List<LocalInventoryItem>> getExpiringSoonItems(String homeId) async {
    return (_db.select(_db.localInventoryItems)
          ..where((t) =>
              t.homeId.equals(homeId) &
              t.isDeleted.equals(false) &
              (t.expiryStatus.equals('EXPIRING_SOON') |
                  t.expiryStatus.equals('EXPIRED'))))
        .get();
  }

  // ──── WRITE ────

  /// Insert or update a single item.
  Future<void> upsertItem(LocalInventoryItemsCompanion item) {
    return _db
        .into(_db.localInventoryItems)
        .insertOnConflictUpdate(item);
  }

  /// Batch upsert items (for sync pull).
  Future<void> upsertItems(List<LocalInventoryItemsCompanion> items) {
    return _db.batch((batch) {
      for (final item in items) {
        batch.insert(_db.localInventoryItems, item,
            onConflict: DoUpdate((_) => item));
      }
    });
  }

  /// Update stock quantity locally and recompute stock status.
  Future<void> updateLocalStock(
    String itemId,
    double newQuantity,
    String newStockStatus,
  ) {
    return (_db.update(_db.localInventoryItems)
          ..where((t) => t.id.equals(itemId)))
        .write(LocalInventoryItemsCompanion(
      quantity: Value(newQuantity),
      stockStatus: Value(newStockStatus),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// Update item qualitative status (e.g. About Half, More than half) in 2 taps.
  Future<void> updateItemStatus(
    String itemId,
    String quantityStatus,
    double newQuantity,
    String newStockStatus,
  ) {
    return (_db.update(_db.localInventoryItems)
          ..where((t) => t.id.equals(itemId)))
        .write(LocalInventoryItemsCompanion(
      quantityStatus: Value(quantityStatus),
      quantity: Value(newQuantity),
      quantitySource: const Value('VERIFIED'),
      stockStatus: Value(newStockStatus),
      lastVerifiedAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// Confirm exact item stock quantity.
  Future<void> confirmItemQuantity(
    String itemId,
    double quantity,
    String stockStatus,
  ) {
    return (_db.update(_db.localInventoryItems)
          ..where((t) => t.id.equals(itemId)))
        .write(LocalInventoryItemsCompanion(
      quantity: Value(quantity),
      quantitySource: const Value('VERIFIED'),
      stockStatus: Value(stockStatus),
      lastVerifiedAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// Watch consumption profiles for a home.
  Stream<List<LocalConsumptionProfile>> watchConsumptionProfiles(String homeId) {
    return (_db.select(_db.localConsumptionProfiles)
          ..where((t) => t.homeId.equals(homeId)))
        .watch();
  }

  /// Upsert consumption profiles in batch.
  Future<void> upsertConsumptionProfiles(List<LocalConsumptionProfilesCompanion> profiles) {
    return _db.batch((batch) {
      for (final p in profiles) {
        batch.insert(_db.localConsumptionProfiles, p,
            onConflict: DoUpdate((_) => p));
      }
    });
  }

  /// Soft delete an item locally.
  Future<void> softDeleteItem(String itemId) {
    return (_db.update(_db.localInventoryItems)
          ..where((t) => t.id.equals(itemId)))
        .write(const LocalInventoryItemsCompanion(
      isDeleted: Value(true),
      updatedAt: Value(null),
    ));
  }

  /// Clear all items for a home (for full re-sync).
  Future<void> clearItemsForHome(String homeId) {
    return (_db.delete(_db.localInventoryItems)
          ..where((t) => t.homeId.equals(homeId)))
        .go();
  }

  // ──── STOCK TRANSACTIONS ────

  /// Watch transactions for a specific item.
  Stream<List<LocalStockTransaction>> watchTransactions(String itemId) {
    return (_db.select(_db.localStockTransactions)
          ..where((t) => t.inventoryItemId.equals(itemId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  /// Get transactions for a specific item (non-reactive).
  Future<List<LocalStockTransaction>> getTransactions(String itemId) {
    return (_db.select(_db.localStockTransactions)
          ..where((t) => t.inventoryItemId.equals(itemId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// Insert a stock transaction.
  Future<void> insertTransaction(LocalStockTransactionsCompanion tx) {
    return _db.into(_db.localStockTransactions).insert(tx);
  }

  /// Batch upsert transactions (for sync pull).
  Future<void> upsertTransactions(List<LocalStockTransactionsCompanion> txs) {
    return _db.batch((batch) {
      for (final tx in txs) {
        batch.insert(_db.localStockTransactions, tx,
            onConflict: DoUpdate((_) => tx));
      }
    });
  }

  // ──── CATEGORIES ────

  /// Watch categories for a home.
  Stream<List<LocalCategory>> watchCategories(String homeId) {
    return (_db.select(_db.localCategories)
          ..where((t) => t.homeId.equals(homeId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch();
  }

  /// Get categories for a home (non-reactive).
  Future<List<LocalCategory>> getCategories(String homeId) {
    return (_db.select(_db.localCategories)
          ..where((t) => t.homeId.equals(homeId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  /// Batch upsert categories.
  Future<void> upsertCategories(List<LocalCategoriesCompanion> categories) {
    return _db.batch((batch) {
      for (final cat in categories) {
        batch.insert(_db.localCategories, cat,
            onConflict: DoUpdate((_) => cat));
      }
    });
  }

  /// Delete placeholder default categories that have been superseded by server categories.
  Future<void> removeDefaultCategories(String homeId) {
    return (_db.delete(_db.localCategories)
          ..where((t) => t.homeId.equals(homeId) & t.id.like('default_%')))
        .go();
  }

  /// Seed default household categories into SQLite if none exist for this home.
  Future<void> seedDefaultCategories(String homeId) async {
    final existing = await getCategories(homeId);
    final existingNames = existing.map((e) => e.name.trim().toLowerCase()).toSet();

    final defaults = CategoryModel.defaultCategories(homeId);
    final needed = defaults
        .where((c) => !existingNames.contains(c.name.trim().toLowerCase()))
        .toList();

    if (needed.isEmpty) return;

    final companions = needed.map((c) {
      return LocalCategoriesCompanion(
        id: Value(c.id),
        homeId: Value(homeId),
        name: Value(c.name),
        iconName: Value(c.icon),
        colorHex: Value(c.colorHex),
        sortOrder: Value(c.displayOrder),
        updatedAt: Value(DateTime.now()),
      );
    }).toList();

    await upsertCategories(companions);
  }

  /// Delete a category by ID (for remote deletions).
  Future<void> deleteCategory(String categoryId) {
    return (_db.delete(_db.localCategories)
          ..where((t) => t.id.equals(categoryId)))
        .go();
  }
}
