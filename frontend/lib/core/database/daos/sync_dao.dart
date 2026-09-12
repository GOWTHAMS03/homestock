import 'package:drift/drift.dart';
import '../app_database.dart';
import '../../sync/sync_status.dart';

/// Data access object for the sync queue and sync metadata.
/// Manages all pending synchronization operations and tracking.
class SyncDao {
  final AppDatabase _db;

  SyncDao(this._db);

  // ──── SYNC QUEUE ────

  /// Recover from unexpected crashes or app terminations while operations were in-flight.
  /// Resets any operations with status 'SYNCING' back to 'PENDING' so they can be processed.
  Future<int> recoverIncompleteSyncingOperations() {
    return (_db.update(_db.syncQueueEntries)
          ..where((t) => t.status.equals('SYNCING')))
        .write(const SyncQueueEntriesCompanion(
      status: Value('PENDING'),
    ));
  }

  /// Get all pending operations, ordered by creation time (FIFO).
  Future<List<SyncQueueEntry>> getPendingOperations() {
    return (_db.select(_db.syncQueueEntries)
          ..where((t) => t.status.equals('PENDING'))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// Get pending operations for a specific home.
  Future<List<SyncQueueEntry>> getPendingOperationsForHome(String homeId) {
    return (_db.select(_db.syncQueueEntries)
          ..where(
              (t) => t.status.equals('PENDING') & t.homeId.equals(homeId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// Get in-flight syncing operations.
  Future<List<SyncQueueEntry>> getSyncingOperations() {
    return (_db.select(_db.syncQueueEntries)
          ..where((t) => t.status.equals('SYNCING'))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// Get successfully synced operations (most recent first).
  Future<List<SyncQueueEntry>> getSyncedOperations({int limit = 50}) {
    return (_db.select(_db.syncQueueEntries)
          ..where((t) => t.status.equals('SYNCED'))
          ..orderBy([(t) => OrderingTerm.desc(t.serverAcknowledgedAt)])
          ..limit(limit))
        .get();
  }

  /// Get operations marked as having conflict.
  Future<List<SyncQueueEntry>> getConflictOperations() {
    return (_db.select(_db.syncQueueEntries)
          ..where((t) => t.status.equals('CONFLICT'))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// Get operations filtered by status.
  Future<List<SyncQueueEntry>> getOperationsByStatus(String status, {int? limit}) {
    final query = _db.select(_db.syncQueueEntries)
      ..where((t) => t.status.equals(status))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    if (limit != null && limit > 0) {
      query.limit(limit);
    }
    return query.get();
  }

  /// Watch operations filtered by status.
  Stream<List<SyncQueueEntry>> watchOperationsByStatus(String status) {
    return (_db.select(_db.syncQueueEntries)
          ..where((t) => t.status.equals(status))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  /// Get summary breakdown across all queue states: pending, syncing, synced, failed, conflict.
  Future<SyncQueueSummary> getQueueSummary() async {
    final all = await _db.select(_db.syncQueueEntries).get();
    int pending = 0;
    int syncing = 0;
    int synced = 0;
    int failed = 0;
    int conflict = 0;
    for (final op in all) {
      switch (op.status) {
        case 'PENDING':
          pending++;
          break;
        case 'SYNCING':
          syncing++;
          break;
        case 'SYNCED':
          synced++;
          break;
        case 'FAILED':
          failed++;
          break;
        case 'CONFLICT':
          conflict++;
          break;
      }
    }
    return SyncQueueSummary(
      pending: pending,
      syncing: syncing,
      synced: synced,
      failed: failed,
      conflict: conflict,
    );
  }

  /// Watch live summary breakdown across all queue states.
  Stream<SyncQueueSummary> watchQueueSummary() {
    return _db.select(_db.syncQueueEntries).watch().map((all) {
      int pending = 0;
      int syncing = 0;
      int synced = 0;
      int failed = 0;
      int conflict = 0;
      for (final op in all) {
        switch (op.status) {
          case 'PENDING':
            pending++;
            break;
          case 'SYNCING':
            syncing++;
            break;
          case 'SYNCED':
            synced++;
            break;
          case 'FAILED':
            failed++;
            break;
          case 'CONFLICT':
            conflict++;
            break;
        }
      }
      return SyncQueueSummary(
        pending: pending,
        syncing: syncing,
        synced: synced,
        failed: failed,
        conflict: conflict,
      );
    });
  }

  /// Reset all failed and conflict operations back to PENDING for immediate re-attempt.
  Future<int> retryAllFailedOperations() {
    return (_db.update(_db.syncQueueEntries)
          ..where((t) => t.status.equals('FAILED') | t.status.equals('CONFLICT')))
        .write(const SyncQueueEntriesCompanion(
      status: Value('PENDING'),
      lastError: Value(null),
    ));
  }

  /// Clear all acknowledged SYNCED operations from local storage.
  Future<int> clearSyncedHistory() {
    return (_db.delete(_db.syncQueueEntries)
          ..where((t) => t.status.equals('SYNCED')))
        .go();
  }

  /// Get failed operations that should be retried.
  Future<List<SyncQueueEntry>> getFailedOperations({int maxRetries = 5}) {
    return (_db.select(_db.syncQueueEntries)
          ..where((t) =>
              t.status.equals('FAILED') &
              t.retryCount.isSmallerThanValue(maxRetries))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// Get set of entity IDs that currently have pending, syncing, or failed sync operations.
  Future<Set<String>> getActivePendingEntityIds({String? homeId}) async {
    final query = _db.select(_db.syncQueueEntries)
      ..where((t) =>
          t.status.equals('PENDING') |
          t.status.equals('SYNCING') |
          t.status.equals('FAILED'));
    if (homeId != null && homeId.isNotEmpty) {
      query.where((t) => t.homeId.equals(homeId));
    }
    final ops = await query.get();
    return ops.map((o) => o.entityId).toSet();
  }

  /// Add a new operation to the sync queue.
  Future<int> addToSyncQueue(SyncQueueEntriesCompanion entry) {
    return _db.into(_db.syncQueueEntries).insert(entry);
  }

  /// Mark an operation as syncing.
  Future<void> markSyncing(String operationId) {
    return (_db.update(_db.syncQueueEntries)
          ..where((t) => t.operationId.equals(operationId)))
        .write(SyncQueueEntriesCompanion(
      status: const Value('SYNCING'),
      lastAttemptAt: Value(DateTime.now().toUtc()),
    ));
  }

  /// Mark an operation as successfully synced.
  Future<void> markSynced(String operationId) {
    return (_db.update(_db.syncQueueEntries)
          ..where((t) => t.operationId.equals(operationId)))
        .write(SyncQueueEntriesCompanion(
      status: const Value('SYNCED'),
      serverAcknowledgedAt: Value(DateTime.now().toUtc()),
    ));
  }

  /// Mark an operation as failed with error message.
  Future<void> markFailed(String operationId, String error) {
    return (_db.update(_db.syncQueueEntries)
          ..where((t) => t.operationId.equals(operationId)))
        .write(SyncQueueEntriesCompanion(
      status: const Value('FAILED'),
      lastError: Value(error),
    ));
  }

  /// Mark an operation as having a conflict.
  Future<void> markConflict(String operationId, String details) {
    return (_db.update(_db.syncQueueEntries)
          ..where((t) => t.operationId.equals(operationId)))
        .write(SyncQueueEntriesCompanion(
      status: const Value('CONFLICT'),
      lastError: Value(details),
    ));
  }

  /// Increment the retry count for an operation.
  Future<void> incrementRetryCount(String operationId) async {
    final entry = await (_db.select(_db.syncQueueEntries)
          ..where((t) => t.operationId.equals(operationId)))
        .getSingleOrNull();
    if (entry == null) return;

    await (_db.update(_db.syncQueueEntries)
          ..where((t) => t.operationId.equals(operationId)))
        .write(SyncQueueEntriesCompanion(
      retryCount: Value(entry.retryCount + 1),
      status: const Value('PENDING'), // Reset to pending for retry
    ));
  }

  /// Get total count of pending operations.
  Future<int> getPendingCount() async {
    final ops = await (_db.select(_db.syncQueueEntries)
          ..where((t) => t.status.equals('PENDING')))
        .get();
    return ops.length;
  }

  /// Watch the count of pending operations (for UI indicator).
  Stream<int> watchPendingCount() {
    final query = _db.select(_db.syncQueueEntries)
      ..where((t) =>
          t.status.equals('PENDING') |
          t.status.equals('SYNCING') |
          (t.status.equals('FAILED') & t.retryCount.isSmallerThanValue(5)));
    return query.watch().map((ops) => ops.length);
  }

  /// Delete synced operations older than retention duration (defaults to 24 hours).
  Future<void> cleanupOldSyncedOperations({Duration retention = const Duration(hours: 24)}) {
    final cutoff = DateTime.now().toUtc().subtract(retention);
    return (_db.delete(_db.syncQueueEntries)
          ..where((t) =>
              t.status.equals('SYNCED') &
              (t.serverAcknowledgedAt.isSmallerOrEqualValue(cutoff) |
                  t.serverAcknowledgedAt.isNull())))
        .go();
  }

  /// Delete all synced operations (cleanup).
  Future<void> cleanupSyncedOperations() => cleanupOldSyncedOperations();

  /// Delete all operations for a specific entity (e.g., when item is deleted remotely).
  Future<void> deleteOperationsForEntity(String entityId) {
    return (_db.delete(_db.syncQueueEntries)
          ..where((t) => t.entityId.equals(entityId)))
        .go();
  }

  // ──── SYNC METADATA ────

  /// Get the last synced timestamp for a home.
  Future<DateTime?> getLastSyncedAt(String homeId) async {
    final entry = await (_db.select(_db.syncMetadataEntries)
          ..where((t) => t.homeId.equals(homeId)))
        .getSingleOrNull();
    return entry?.lastSyncedAt;
  }

  /// Update the last synced timestamp for a home.
  Future<void> updateLastSyncedAt(String homeId, DateTime timestamp) {
    return _db.into(_db.syncMetadataEntries).insertOnConflictUpdate(
          SyncMetadataEntriesCompanion(
            homeId: Value(homeId),
            lastSyncedAt: Value(timestamp),
          ),
        );
  }

  /// Get sync version for a home.
  Future<int> getSyncVersion(String homeId) async {
    final entry = await (_db.select(_db.syncMetadataEntries)
          ..where((t) => t.homeId.equals(homeId)))
        .getSingleOrNull();
    return entry?.syncVersion ?? 0;
  }

  /// Update sync version for a home.
  Future<void> updateSyncVersion(String homeId, int version) {
    return _db.into(_db.syncMetadataEntries).insertOnConflictUpdate(
          SyncMetadataEntriesCompanion(
            homeId: Value(homeId),
            syncVersion: Value(version),
          ),
        );
  }

  /// Watch sync metadata for a home.
  Stream<SyncMetadataEntry?> watchSyncMetadata(String homeId) {
    return (_db.select(_db.syncMetadataEntries)
          ..where((t) => t.homeId.equals(homeId)))
        .watchSingleOrNull();
  }

  /// Atomically apply all incremental changes from a pull response
  /// within a single SQLite transaction. Updates sync cursor only if all updates succeed.
  Future<void> applyPullChangesInTransaction({
    required String homeId,
    required List<LocalCategoriesCompanion> categories,
    required List<LocalInventoryItemsCompanion> inventoryItems,
    required List<LocalStockTransactionsCompanion> stockTransactions,
    required List<LocalShoppingListsCompanion> shoppingLists,
    required List<LocalShoppingListItemsCompanion> shoppingListItems,
    required List<LocalPurchasesCompanion> purchases,
    required List<LocalPurchaseItemsCompanion> purchaseItems,
    required List<LocalStoresCompanion> stores,
    List<LocalHomeMembersCompanion> homeMembers = const [],
    LocalHomesCompanion? homeDetails,
    required List<String> deletedShoppingItemIds,
    required List<String> deletedInventoryItemIds,
    required List<String> deletedStoreIds,
    required List<String> deletedCategoryIds,
    List<String> deletedMemberUserIds = const [],
    required DateTime serverTimestamp,
    int? nextServerVersion,
  }) {
    return _db.transaction(() async {
      final pendingEntityIds = await getActivePendingEntityIds(homeId: homeId);

      // 1. Categories
      for (final cat in categories) {
        if (pendingEntityIds.contains(cat.id.value)) continue;
        await _db.into(_db.localCategories).insertOnConflictUpdate(cat);
      }
      for (final catId in deletedCategoryIds) {
        if (pendingEntityIds.contains(catId)) continue;
        await (_db.delete(_db.localCategories)..where((t) => t.id.equals(catId))).go();
      }

      // 2. Inventory Items
      for (final item in inventoryItems) {
        if (pendingEntityIds.contains(item.id.value)) {
          // Local entity has unpushed modifications — protect user changes!
          continue;
        }
        await _db.into(_db.localInventoryItems).insertOnConflictUpdate(item);
      }
      for (final itemId in deletedInventoryItemIds) {
        if (pendingEntityIds.contains(itemId)) continue;
        await (_db.update(_db.localInventoryItems)..where((t) => t.id.equals(itemId)))
            .write(const LocalInventoryItemsCompanion(isDeleted: Value(true)));
      }

      // 3. Stock Transactions
      for (final tx in stockTransactions) {
        await _db.into(_db.localStockTransactions).insertOnConflictUpdate(tx);
      }

      // 4. Shopping Lists
      for (final list in shoppingLists) {
        await _db.into(_db.localShoppingLists).insertOnConflictUpdate(list);
      }

      // 5. Shopping List Items
      for (final item in shoppingListItems) {
        if (pendingEntityIds.contains(item.id.value)) continue;
        await _db.into(_db.localShoppingListItems).insertOnConflictUpdate(item);
      }
      for (final sId in deletedShoppingItemIds) {
        if (pendingEntityIds.contains(sId)) continue;
        await (_db.delete(_db.localShoppingListItems)..where((t) => t.id.equals(sId))).go();
      }

      // 6. Purchases & Purchase Items
      for (final p in purchases) {
        if (pendingEntityIds.contains(p.id.value)) continue;
        await _db.into(_db.localPurchases).insertOnConflictUpdate(p);
      }
      for (final pi in purchaseItems) {
        await _db.into(_db.localPurchaseItems).insertOnConflictUpdate(pi);
      }

      // 7. Stores
      for (final s in stores) {
        await _db.into(_db.localStores).insertOnConflictUpdate(s);
      }
      for (final storeId in deletedStoreIds) {
        await (_db.delete(_db.localStores)..where((t) => t.id.equals(storeId))).go();
      }

      // 8. Home Members & Home Details
      for (final m in homeMembers) {
        await _db.into(_db.localHomeMembers).insertOnConflictUpdate(m);
      }
      if (deletedMemberUserIds.isNotEmpty) {
        await (_db.delete(_db.localHomeMembers)
              ..where((t) =>
                  t.homeId.equals(homeId) &
                  t.userId.isIn(deletedMemberUserIds)))
            .go();
      }
      if (homeDetails != null) {
        await _db.into(_db.localHomes).insertOnConflictUpdate(homeDetails);
      }

      // 9. Update sync metadata cursor atomically
      await _db.into(_db.syncMetadataEntries).insertOnConflictUpdate(
            SyncMetadataEntriesCompanion(
              homeId: Value(homeId),
              lastSyncedAt: Value(serverTimestamp),
              syncVersion: nextServerVersion != null
                  ? Value(nextServerVersion)
                  : const Value.absent(),
            ),
          );
    });
  }
}
