import 'package:drift/drift.dart';
import '../app_database.dart';

/// Data access object for shopping lists and shopping list items.
class ShoppingDao {
  final AppDatabase _db;

  ShoppingDao(this._db);

  // ──── SHOPPING LISTS ────

  /// Get the default shopping list for a home.
  Future<LocalShoppingList?> getDefaultList(String homeId) {
    return (_db.select(_db.localShoppingLists)
          ..where(
              (t) => t.homeId.equals(homeId) & t.isDefault.equals(true)))
        .getSingleOrNull();
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

  /// Watch all items for a home's default list.
  Stream<List<LocalShoppingListItem>> watchShoppingItemsForHome(
      String homeId) {
    // First get the default list, then watch its items
    final listQuery = _db.select(_db.localShoppingLists)
      ..where((t) => t.homeId.equals(homeId) & t.isDefault.equals(true));

    return listQuery.watchSingleOrNull().asyncExpand((list) {
      if (list == null) return Stream.value(<LocalShoppingListItem>[]);
      return watchShoppingItems(list.id);
    });
  }

  /// Get all items for a shopping list (non-reactive).
  Future<List<LocalShoppingListItem>> getShoppingItems(String listId) {
    return (_db.select(_db.localShoppingListItems)
          ..where((t) =>
              t.shoppingListId.equals(listId) & t.isDeleted.equals(false)))
        .get();
  }

  /// Get a single shopping item by ID.
  Future<LocalShoppingListItem?> getShoppingItemById(String itemId) {
    return (_db.select(_db.localShoppingListItems)
          ..where((t) => t.id.equals(itemId)))
        .getSingleOrNull();
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
