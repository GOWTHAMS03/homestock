/// Network status states for the application.
enum NetworkStatus {
  online,
  offline,
  syncing,
}

/// Current sync state exposed to the UI.
class SyncState {
  final NetworkStatus status;
  final DateTime? lastSyncedAt;
  final int pendingOperationsCount;
  final String? lastError;
  final bool isSyncInProgress;

  const SyncState({
    this.status = NetworkStatus.offline,
    this.lastSyncedAt,
    this.pendingOperationsCount = 0,
    this.lastError,
    this.isSyncInProgress = false,
  });

  SyncState copyWith({
    NetworkStatus? status,
    DateTime? lastSyncedAt,
    int? pendingOperationsCount,
    String? lastError,
    bool? isSyncInProgress,
  }) {
    return SyncState(
      status: status ?? this.status,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      pendingOperationsCount:
          pendingOperationsCount ?? this.pendingOperationsCount,
      lastError: lastError,
      isSyncInProgress: isSyncInProgress ?? this.isSyncInProgress,
    );
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
    switch (status) {
      case NetworkStatus.online:
        if (pendingOperationsCount > 0) {
          return 'Online • $pendingOperationsCount changes pending';
        }
        return 'Online';
      case NetworkStatus.offline:
        if (lastSyncedAt != null) {
          return 'Offline • Last synced $lastSyncedAgo';
        }
        return 'Offline • Changes will sync automatically';
      case NetworkStatus.syncing:
        return 'Syncing...';
    }
  }

  bool get isOnline => status == NetworkStatus.online;
  bool get isOffline => status == NetworkStatus.offline;
  bool get isSyncing => status == NetworkStatus.syncing;
}
