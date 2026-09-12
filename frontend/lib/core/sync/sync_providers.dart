import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../database/daos/inventory_dao.dart';
import '../database/daos/purchase_dao.dart';
import '../database/daos/shopping_dao.dart';
import '../database/daos/sync_dao.dart';
import '../database/daos/notification_dao.dart';
import 'connectivity_monitor.dart';
import 'sync_engine.dart';
import 'sync_status.dart';

// ──── Core Infrastructure Providers ────

/// The local SQLite database singleton.
/// Override in ProviderScope at app startup.
final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError(
      'databaseProvider must be overridden in ProviderScope');
});

/// Connectivity monitor singleton.
/// Override in ProviderScope at app startup.
final connectivityMonitorProvider = Provider<ConnectivityMonitor>((ref) {
  throw UnimplementedError(
      'connectivityMonitorProvider must be overridden in ProviderScope');
});

/// Sync engine singleton.
/// Override in ProviderScope at app startup.
final syncEngineProvider = Provider<SyncEngine>((ref) {
  throw UnimplementedError(
      'syncEngineProvider must be overridden in ProviderScope');
});

// ──── DAO Providers ────

final inventoryDaoProvider = Provider<InventoryDao>((ref) {
  return InventoryDao(ref.watch(databaseProvider));
});

final shoppingDaoProvider = Provider<ShoppingDao>((ref) {
  return ShoppingDao(ref.watch(databaseProvider));
});

final purchaseDaoProvider = Provider<PurchaseDao>((ref) {
  return PurchaseDao(ref.watch(databaseProvider));
});

final syncDaoProvider = Provider<SyncDao>((ref) {
  return SyncDao(ref.watch(databaseProvider));
});

final notificationDaoProvider = Provider<NotificationDao>((ref) {
  return NotificationDao(ref.watch(databaseProvider));
});

// ──── Sync State Providers ────

/// Stream provider for network status changes.
final networkStatusProvider = StreamProvider<NetworkStatus>((ref) {
  final monitor = ref.watch(connectivityMonitorProvider);
  return monitor.statusStream;
});

/// Stream provider for full sync state (status, pending count, last synced).
final syncStateProvider = StreamProvider<SyncState>((ref) {
  final engine = ref.watch(syncEngineProvider);
  return engine.stateStream;
});

/// Watch the count of pending sync operations.
final pendingOperationsCountProvider = StreamProvider<int>((ref) {
  final syncDao = ref.watch(syncDaoProvider);
  return syncDao.watchPendingCount();
});

/// Current sync state as a simple state provider (for imperative access).
final currentSyncStateProvider = StateProvider<SyncState>((ref) {
  // Listen to the stream and update
  ref.listen<AsyncValue<SyncState>>(syncStateProvider, (prev, next) {
    next.whenData((state) {
      ref.controller.state = state;
    });
  });
  return const SyncState();
});

/// Watch real-time breakdown of queue operations across all 5 states:
/// pending, syncing, synced, failed, and conflict.
final syncQueueSummaryProvider = StreamProvider<SyncQueueSummary>((ref) {
  final syncDao = ref.watch(syncDaoProvider);
  return syncDao.watchQueueSummary();
});
