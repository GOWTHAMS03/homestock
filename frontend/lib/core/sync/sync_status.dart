/// Full 8-state synchronization lifecycle.
enum SyncStatus {
  offline,
  networkAvailable,
  syncingPush,
  syncingPull,
  reconciling,
  synced,
  error,
  authRequired,
}

/// Network status states for backward compatibility.
enum NetworkStatus {
  online,
  offline,
  syncing,
}

/// Current sync state exposed to the UI and controllers.
class SyncState {
  final SyncStatus syncStatus;
  final NetworkStatus status;
  final DateTime? lastSyncedAt;
  final int pendingOperationsCount;
  final String? lastError;
  final bool isSyncInProgress;

  const SyncState({
    this.syncStatus = SyncStatus.offline,
    this.status = NetworkStatus.offline,
    this.lastSyncedAt,
    this.pendingOperationsCount = 0,
    this.lastError,
    this.isSyncInProgress = false,
  });

  SyncState copyWith({
    SyncStatus? syncStatus,
    NetworkStatus? status,
    DateTime? lastSyncedAt,
    int? pendingOperationsCount,
    String? lastError,
    bool? isSyncInProgress,
  }) {
    final effectiveSyncStatus = syncStatus ?? this.syncStatus;
    // Keep backward-compatible NetworkStatus in sync
    final effectiveNetworkStatus = status ??
        _mapSyncStatusToNetworkStatus(effectiveSyncStatus);

    return SyncState(
      syncStatus: effectiveSyncStatus,
      status: effectiveNetworkStatus,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      pendingOperationsCount:
          pendingOperationsCount ?? this.pendingOperationsCount,
      lastError: lastError,
      isSyncInProgress: isSyncInProgress ?? this.isSyncInProgress,
    );
  }

  static NetworkStatus _mapSyncStatusToNetworkStatus(SyncStatus syncStatus) {
    switch (syncStatus) {
      case SyncStatus.syncingPush:
      case SyncStatus.syncingPull:
      case SyncStatus.reconciling:
        return NetworkStatus.syncing;
      case SyncStatus.networkAvailable:
      case SyncStatus.synced:
        return NetworkStatus.online;
      case SyncStatus.offline:
      case SyncStatus.authRequired:
      case SyncStatus.error:
        return NetworkStatus.offline;
    }
  }

  SyncStatus get effectiveSyncStatus {
    if (syncStatus == SyncStatus.offline && status == NetworkStatus.online) {
      return SyncStatus.synced;
    }
    if (syncStatus == SyncStatus.offline && status == NetworkStatus.syncing) {
      return SyncStatus.syncingPush;
    }
    return syncStatus;
  }

  /// Human-readable time since last sync.
  String get lastSyncedAgo {
    if (lastSyncedAt == null) return 'Never synced';
    final diff = DateTime.now().difference(lastSyncedAt!);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  /// Status message for the UI status bar.
  String get statusMessage {
    switch (effectiveSyncStatus) {
      case SyncStatus.offline:
        if (pendingOperationsCount > 0) {
          return 'Offline • $pendingOperationsCount change(s) saved locally';
        }
        if (lastSyncedAt != null) {
          return 'Offline • Last synced $lastSyncedAgo';
        }
        return 'Offline • Changes will sync automatically';
      case SyncStatus.networkAvailable:
        return pendingOperationsCount > 0
            ? 'Network available • Syncing soon ($pendingOperationsCount pending)'
            : 'Connecting to server...';
      case SyncStatus.syncingPush:
        if (isSyncInProgress && pendingOperationsCount == 0 && status == NetworkStatus.syncing) {
          return 'Syncing...';
        }
        return pendingOperationsCount > 0
            ? 'Uploading $pendingOperationsCount local change(s)...'
            : 'Uploading changes to server...';
      case SyncStatus.syncingPull:
        return 'Checking for remote updates...';
      case SyncStatus.reconciling:
        return 'Reconciling data with server...';
      case SyncStatus.synced:
        if (pendingOperationsCount > 0) {
          return 'Online • $pendingOperationsCount changes pending';
        }
        return status == NetworkStatus.online ? 'Online' : 'Synced with server';
      case SyncStatus.authRequired:
        return 'Session expired • Sign in to resume sync';
      case SyncStatus.error:
        return lastError != null && lastError!.isNotEmpty
            ? 'Sync error: $lastError'
            : 'Sync error • Retrying shortly';
    }
  }

  bool get isOnline =>
      effectiveSyncStatus != SyncStatus.offline &&
      effectiveSyncStatus != SyncStatus.authRequired;
  bool get isOffline => effectiveSyncStatus == SyncStatus.offline;
  bool get isSyncing =>
      effectiveSyncStatus == SyncStatus.syncingPush ||
      effectiveSyncStatus == SyncStatus.syncingPull ||
      effectiveSyncStatus == SyncStatus.reconciling;
  bool get isPushing => effectiveSyncStatus == SyncStatus.syncingPush;
  bool get isPulling => effectiveSyncStatus == SyncStatus.syncingPull;
  bool get isReconciling => effectiveSyncStatus == SyncStatus.reconciling;
  bool get isAuthRequired => effectiveSyncStatus == SyncStatus.authRequired;
  bool get isSynced => effectiveSyncStatus == SyncStatus.synced;
}

/// Detailed queue diagnostics breakdown across all sync operation states.
class SyncQueueSummary {
  final int pending;
  final int syncing;
  final int synced;
  final int failed;
  final int conflict;

  const SyncQueueSummary({
    this.pending = 0,
    this.syncing = 0,
    this.synced = 0,
    this.failed = 0,
    this.conflict = 0,
  });

  int get totalActive => pending + syncing + failed + conflict;
  int get totalTracked => pending + syncing + synced + failed + conflict;
  bool get hasPending => pending > 0;
  bool get isCurrentlySyncing => syncing > 0;
  bool get hasFailures => failed > 0;
  bool get hasConflicts => conflict > 0;
  bool get isAllSynced => pending == 0 && syncing == 0 && failed == 0 && conflict == 0;
}
