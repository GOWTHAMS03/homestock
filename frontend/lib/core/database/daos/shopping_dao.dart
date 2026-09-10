import 'package:drift/drift.dart';
import '../app_database.dart';

/// Data access object for shopping lists and shopping list items.
class ShoppingDao {
  final AppDatabase _db;

  ShoppingDao(this._db);

  // ──── SHOPPING LISTS ────

  /// Get the default shopping list for a home.
  /// Uses limit(1) and ordering to avoid StateError if multiple default lists exist.
  Future<LocalShoppingList?> getDefaultList(String homeId) async {
    final lists = await (_db.select(_db.localShoppingLists)
          ..where((t) => t.homeId.equals(homeId))
          ..orderBy([
            (t) => OrderingTerm.desc(t.isDefault),
            (t) => OrderingTerm.desc(t.updatedAt),
          ])
          ..limit(1))
        .get();
    return lists.firstOrNull;
  }

  /// Ensure a default shopping list exists locally for the home.
  /// If none exists, creates one and returns it.
  Future<LocalShoppingList> ensureDefaultList(String homeId,
      [String name = 'Home Shopping List']) async {
    final existing = await getDefaultList(homeId);
    if (existing != null) return existing;

    final companion = LocalShoppingListsCompanion(
      id: Value(homeId),
      homeId: Value(homeId),
      name: Value(name),
      isDefault: const Value(true),
      updatedAt: Value(DateTime.now()),
    );
    await upsertShoppingList(companion);
    final created = await getDefaultList(homeId);
    return created ??
        LocalShoppingList(
          id: homeId,
          homeId: homeId,
          name: name,
          isDefault: true,
          updatedAt: DateTime.now(),
        );
  }

  /// Upsert a shopping list.
  Future<void> upsertShoppingList(LocalShoppingListsCompanion list) {
    return _db
        .into(_db.localShoppingLists)
        .insertOnConflictUpdate(list);
  }

  /// Delete a shopping list by ID.
  Future<void> deleteShoppingListById(String listId) {
    return (_db.delete(_db.localShoppingLists)
          ..where((t) => t.id.equals(listId)))
        .go();
  }

  /// Resolve a fallback home ID from local database tables.
  Future<String?> resolveFallbackHomeId() async {
    final home = await (_db.select(_db.localHomes)..limit(1)).getSingleOrNull();
    if (home != null && home.id.isNotEmpty) return home.id;

    final list = await (_db.select(_db.localShoppingLists)..limit(1)).getSingleOrNull();
    if (list != null && list.homeId.isNotEmpty) return list.homeId;

    final item = await (_db.select(_db.localInventoryItems)..limit(1)).getSingleOrNull();
    if (item != null && item.homeId.isNotEmpty) return item.homeId;

    return 'default_home';
  }

  // ──── SHOPPING LIST ITEMS ────

  /// Watch all non-deleted items for a shopping list.
  Stream<List<LocalShoppingListItem>> watchShoppingItems(String listId) {
    return (_db.select(_db.localShoppingListItems)
          ..where((t) =>
              t.shoppingListId.equals(listId) & t.isDeleted.equals(false))
          ..orderBy([
            (t) => OrderingTerm.asc(t.isCompleted),
            (t) => OrderingTerm.desc(t.updatedAt),
          ]))
        .watch();
  }

  /// Watch all items for a home across any of its shopping lists.
  /// Extremely resilient: queries all list IDs associated with the home and the homeId itself.
  Stream<List<LocalShoppingListItem>> watchShoppingItemsForHome(
      String homeId) {
    final listQuery = _db.select(_db.localShoppingLists)
      ..where((t) => t.homeId.equals(homeId));

    return listQuery.watch().asyncExpand((lists) {
      final listIds = {
        homeId,
        ...lists.map((l) => l.id),
      }.toList();

      return (_db.select(_db.localShoppingListItems)
            ..where((t) =>
                (t.homeId.equals(homeId) | t.shoppingListId.isIn(listIds)) &
                t.isDeleted.equals(false))
            ..orderBy([
              (t) => OrderingTerm.asc(t.isCompleted),
              (t) => OrderingTerm.desc(t.updatedAt),
            ]))
          .watch();
    });
  }

  /// Get all items for all shopping lists belonging to a home (non-reactive).
  Future<List<LocalShoppingListItem>> getShoppingItemsForHome(String homeId) async {
    final lists = await (_db.select(_db.localShoppingLists)
          ..where((t) => t.homeId.equals(homeId)))
        .get();
    final listIds = {
      homeId,
      ...lists.map((l) => l.id),
    }.toList();

    return (_db.select(_db.localShoppingListItems)
          ..where((t) =>
              (t.homeId.equals(homeId) | t.shoppingListId.isIn(listIds)) &
              t.isDeleted.equals(false))
          ..orderBy([
            (t) => OrderingTerm.asc(t.isCompleted),
            (t) => OrderingTerm.desc(t.updatedAt),
          ]))
        .get();
  }

  /// Get all items for a shopping list (non-reactive).
  Future<List<LocalShoppingListItem>> getShoppingItems(String listId) {
    return (_db.select(_db.localShoppingListItems)
          ..where((t) =>
              t.shoppingListId.equals(listId) & t.isDeleted.equals(false)))
        .get();
  }

  /// Get a single shopping item by ID.
  Future<LocalShoppingListItem?> getShoppingItemById(String itemId) async {
    final items = await (_db.select(_db.localShoppingListItems)
          ..where((t) => t.id.equals(itemId))
          ..limit(1))
        .get();
    return items.firstOrNull;
  }

  /// Insert or update a shopping item.
  Future<void> upsertShoppingItem(LocalShoppingListItemsCompanion item) {
    return _db
        .into(_db.localShoppingListItems)
        .insertOnConflictUpdate(item);
  }

  /// Batch upsert shopping items.
  Future<void> upsertShoppingItems(
      List<LocalShoppingListItemsCompanion> items) {
    return _db.batch((batch) {
      for (final item in items) {
        batch.insert(_db.localShoppingListItems, item,
            onConflict: DoUpdate((_) => item));
      }
    });
  }

  /// Migrate items from old list ID to new list ID (e.g. after remote list UUID sync).
  Future<void> migrateItemShoppingListId(String oldListId, String newListId) {
    return (_db.update(_db.localShoppingListItems)
          ..where((t) => t.shoppingListId.equals(oldListId)))
        .write(LocalShoppingListItemsCompanion(
      shoppingListId: Value(newListId),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// Toggle the completion status of a shopping item.
  Future<void> toggleShoppingItem(String itemId, bool isCompleted,
      {String? completedByName}) {
    return (_db.update(_db.localShoppingListItems)
          ..where((t) => t.id.equals(itemId)))
        .write(LocalShoppingListItemsCompanion(
      isCompleted: Value(isCompleted),
      completedByName: Value(isCompleted ? completedByName : null),
      completedAt: Value(isCompleted ? DateTime.now().toIso8601String() : null),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// Update the quantity of a shopping item.
  Future<void> updateShoppingItemQuantity(String itemId, double newQuantity) {
    return (_db.update(_db.localShoppingListItems)
          ..where((t) => t.id.equals(itemId)))
        .write(LocalShoppingListItemsCompanion(
      quantity: Value(newQuantity),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// Link an inventory item to a shopping list item.
  Future<void> linkInventoryItem(String itemId, String inventoryItemId) {
    return (_db.update(_db.localShoppingListItems)
          ..where((t) => t.id.equals(itemId)))
        .write(LocalShoppingListItemsCompanion(
      inventoryItemId: Value(inventoryItemId),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// Mark multiple shopping items completed (e.g. after a purchase run).
  Future<void> markItemsCompleted(List<String> itemIds, {String? completedByName}) {
    if (itemIds.isEmpty) return Future.value();
    return (_db.update(_db.localShoppingListItems)
          ..where((t) => t.id.isIn(itemIds)))
        .write(LocalShoppingListItemsCompanion(
      isCompleted: const Value(true),
      completedByName: Value(completedByName ?? 'You'),
      completedAt: Value(DateTime.now().toIso8601String()),
      updatedAt: Value(DateTime.now()),
    ));
  }


  /// Soft delete a shopping item.
  Future<void> softDeleteShoppingItem(String itemId) {
    return (_db.update(_db.localShoppingListItems)
          ..where((t) => t.id.equals(itemId)))
        .write(const LocalShoppingListItemsCompanion(
      isDeleted: Value(true),
    ));
  }

  /// Hard delete a shopping item (for items removed server-side).
  Future<void> deleteShoppingItem(String itemId) {
    return (_db.delete(_db.localShoppingListItems)
          ..where((t) => t.id.equals(itemId)))
        .go();
  }

  /// Delete all completed items for a list (clear completed).
  Future<void> clearCompletedItems(String listId) {
    return (_db.delete(_db.localShoppingListItems)
          ..where((t) =>
              t.shoppingListId.equals(listId) & t.isCompleted.equals(true)))
        .go();
  }

  /// Delete all completed items for all lists of a home.
  Future<void> clearCompletedItemsForHome(String homeId) async {
    final lists = await (_db.select(_db.localShoppingLists)
          ..where((t) => t.homeId.equals(homeId)))
        .get();
    final listIds = {homeId, ...lists.map((l) => l.id)}.toList();
    await (_db.delete(_db.localShoppingListItems)
          ..where((t) =>
              t.shoppingListId.isIn(listIds) & t.isCompleted.equals(true)))
        .go();
  }

  /// Get pending (non-completed) count for a list.
  Future<int> getPendingCount(String listId) async {
    final items = await (_db.select(_db.localShoppingListItems)
          ..where((t) =>
              t.shoppingListId.equals(listId) &
              t.isDeleted.equals(false) &
              t.isCompleted.equals(false)))
        .get();
    return items.length;
  }

  /// Get completed count for a list.
  Future<int> getCompletedCount(String listId) async {
    final items = await (_db.select(_db.localShoppingListItems)
          ..where((t) =>
              t.shoppingListId.equals(listId) &
              t.isDeleted.equals(false) &
              t.isCompleted.equals(true)))
        .get();
    return items.length;
  }
}
