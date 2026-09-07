import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'sync_status.dart';

/// Monitors network connectivity and emits [NetworkStatus] changes.
/// Automatically detects OFFLINE → ONLINE transitions for sync triggering.
class ConnectivityMonitor {
  final Connectivity _connectivity;
  final StreamController<NetworkStatus> _statusController =
      StreamController<NetworkStatus>.broadcast();

  NetworkStatus _currentStatus = NetworkStatus.offline;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  ConnectivityMonitor({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  /// Current network status (synchronous read).
  NetworkStatus get currentStatus => _currentStatus;

  /// Whether the device is currently online.
  bool get isOnline => _currentStatus == NetworkStatus.online;

  /// Stream of network status changes.
  Stream<NetworkStatus> get statusStream => _statusController.stream;

  /// Callback invoked when transitioning from offline to online.
  VoidCallback? onConnectivityRestored;

  /// Start monitoring connectivity.
  Future<void> start() async {
    // Check initial status
    try {
      final results = await _connectivity.checkConnectivity();
      _updateStatus(results);
    } catch (e) {
      if (kDebugMode) print('[ConnectivityMonitor] Initial check failed: $e');
      _currentStatus = NetworkStatus.offline;
      _statusController.add(_currentStatus);
    }

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen(
      _updateStatus,
      onError: (e) {
        if (kDebugMode) print('[ConnectivityMonitor] Stream error: $e');
      },
    );
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final wasOffline = _currentStatus == NetworkStatus.offline;
    final hasConnection = results.any((r) => r != ConnectivityResult.none);

    final newStatus =
        hasConnection ? NetworkStatus.online : NetworkStatus.offline;

    if (newStatus != _currentStatus) {
      _currentStatus = newStatus;
      _statusController.add(_currentStatus);

      if (kDebugMode) {
        print('[ConnectivityMonitor] Status changed to: $newStatus');
      }

      // Trigger sync when going from offline to online
      if (wasOffline && newStatus == NetworkStatus.online) {
        if (kDebugMode) {
          print('[ConnectivityMonitor] Connectivity restored — triggering sync');
        }
        onConnectivityRestored?.call();
      }
    }
  }

  /// Temporarily set status to syncing (used by SyncEngine).
  void setSyncing() {
    if (_currentStatus == NetworkStatus.online) {
      _currentStatus = NetworkStatus.syncing;
      _statusController.add(_currentStatus);
    }
  }

  /// Reset status back to online after sync completes.
  void setSyncComplete() {
    if (_currentStatus == NetworkStatus.syncing) {
      _currentStatus = NetworkStatus.online;
      _statusController.add(_currentStatus);
    }
  }

  /// Dispose all resources.
  void dispose() {
    _subscription?.cancel();
    _statusController.close();
  }
}
