import 'package:drift/drift.dart';
import '../app_database.dart';

/// Data access object for purchases, purchase items, and stores.
class PurchaseDao {
  final AppDatabase _db;

  PurchaseDao(this._db);

  // ──── PURCHASES ────

  /// Watch all purchases for a home, most recent first.
  Stream<List<LocalPurchase>> watchPurchases(String homeId) {
    return (_db.select(_db.localPurchases)
          ..where((t) => t.homeId.equals(homeId))
          ..orderBy([(t) => OrderingTerm.desc(t.purchaseDate)]))
        .watch();
  }

  /// Get all purchases for a home (non-reactive).
  Future<List<LocalPurchase>> getPurchases(String homeId) {
    return (_db.select(_db.localPurchases)
          ..where((t) => t.homeId.equals(homeId))
          ..orderBy([(t) => OrderingTerm.desc(t.purchaseDate)]))
        .get();
  }

  /// Get a single purchase by ID.
  Future<LocalPurchase?> getPurchaseById(String id) {
    return (_db.select(_db.localPurchases)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Insert or update a purchase.
  Future<void> upsertPurchase(LocalPurchasesCompanion purchase) {
    return _db.into(_db.localPurchases).insertOnConflictUpdate(purchase);
  }

  /// Batch upsert purchases.
  Future<void> upsertPurchases(List<LocalPurchasesCompanion> purchases) {
    return _db.batch((batch) {
      for (final p in purchases) {
        batch.insert(_db.localPurchases, p, onConflict: DoUpdate((_) => p));
      }
    });
  }

  // ──── PURCHASE ITEMS ────

  /// Get items for a specific purchase.
  Future<List<LocalPurchaseItem>> getPurchaseItems(String purchaseId) {
    return (_db.select(_db.localPurchaseItems)
          ..where((t) => t.purchaseId.equals(purchaseId)))
        .get();
  }

  /// Watch items for a specific purchase.
  Stream<List<LocalPurchaseItem>> watchPurchaseItems(String purchaseId) {
    return (_db.select(_db.localPurchaseItems)
          ..where((t) => t.purchaseId.equals(purchaseId)))
        .watch();
  }

  /// Insert or update a purchase item.
  Future<void> upsertPurchaseItem(LocalPurchaseItemsCompanion item) {
    return _db.into(_db.localPurchaseItems).insertOnConflictUpdate(item);
  }

  /// Batch upsert purchase items.
  Future<void> upsertPurchaseItems(List<LocalPurchaseItemsCompanion> items) {
    return _db.batch((batch) {
      for (final item in items) {
        batch.insert(_db.localPurchaseItems, item,
            onConflict: DoUpdate((_) => item));
      }
    });
  }

  /// Insert a purchase with all its items atomically.
  Future<void> insertPurchaseWithItems({
    required LocalPurchasesCompanion purchase,
    required List<LocalPurchaseItemsCompanion> items,
  }) {
    return _db.transaction(() async {
      await _db.into(_db.localPurchases).insertOnConflictUpdate(purchase);
      for (final item in items) {
        await _db.into(_db.localPurchaseItems).insertOnConflictUpdate(item);
      }
    });
  }

  // ──── STORES ────

  /// Watch all stores for a home.
  Stream<List<LocalStore>> watchStores(String homeId) {
    return (_db.select(_db.localStores)
          ..where((t) => t.homeId.equals(homeId))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  /// Get all stores for a home (non-reactive).
  Future<List<LocalStore>> getStores(String homeId) {
    return (_db.select(_db.localStores)
          ..where((t) => t.homeId.equals(homeId))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  /// Insert or update a store.
  Future<void> upsertStore(LocalStoresCompanion store) {
    return _db.into(_db.localStores).insertOnConflictUpdate(store);
  }

  /// Batch upsert stores.
  Future<void> upsertStores(List<LocalStoresCompanion> stores) {
    return _db.batch((batch) {
      for (final s in stores) {
        batch.insert(_db.localStores, s, onConflict: DoUpdate((_) => s));
      }
    });
  }

  /// Delete a store by ID (for remote deletions).
  Future<void> deleteStore(String storeId) {
    return (_db.delete(_db.localStores)
          ..where((t) => t.id.equals(storeId)))
        .go();
  }
}
