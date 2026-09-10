import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_endpoints.dart';
import '../network/lan_discovery_service.dart';
import 'sync_status.dart';

/// Monitors network connectivity and real server reachability.
/// Automatically detects OFFLINE ↔ ONLINE transitions for instant sync triggering.
/// Provides sub-1.5s active reachability checks and instant offline failover.
class ConnectivityMonitor {
  final Connectivity _connectivity;
  final StreamController<NetworkStatus> _statusController =
      StreamController<NetworkStatus>.broadcast();

  NetworkStatus _currentStatus = NetworkStatus.offline;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _heartbeatTimer;
  bool _isCheckingReachability = false;

  ConnectivityMonitor({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  /// Current network status (synchronous read).
  NetworkStatus get currentStatus => _currentStatus;

  /// Whether the device is currently online and server is reachable.
  bool get isOnline => _currentStatus == NetworkStatus.online;

  /// Stream of network status changes.
  Stream<NetworkStatus> get statusStream => _statusController.stream;

  /// Callback invoked when transitioning from offline to online.
  VoidCallback? onConnectivityRestored;

  /// Start monitoring connectivity and reachability.
  Future<void> start() async {
    // 1. Initial quick hardware check & reachability probe
    try {
      final results = await _connectivity.checkConnectivity();
      await _handleConnectivityChange(results);
    } catch (e) {
      if (kDebugMode) print('[ConnectivityMonitor] Initial check failed: $e');
      _setOffline();
    }

    // 2. Listen for network interface changes
    _subscription = _connectivity.onConnectivityChanged.listen(
      _handleConnectivityChange,
      onError: (e) {
        if (kDebugMode) print('[ConnectivityMonitor] Stream error: $e');
      },
    );

    // 3. Start non-intrusive background heartbeat check
    _startHeartbeat();
  }

  Future<void> _handleConnectivityChange(List<ConnectivityResult> results) async {
    final hasHardwareConnection = results.any((r) => r != ConnectivityResult.none);

    // Instant failover: no Wi-Fi / no cellular -> definitely offline (0ms delay)
    if (!hasHardwareConnection) {
      _setOffline();
      return;
    }

    // Has hardware connection: quickly verify if backend is reachable
    await checkRealReachability();
  }

  /// Callback invoked when an alternative backend URL is auto-discovered.
  ValueChanged<String>? onServerUrlDiscovered;

  /// Actively probe real backend reachability with a fast timeout (default 1500ms).
  Future<bool> checkRealReachability({
    Duration timeout = const Duration(milliseconds: 1500),
    bool allowDiscovery = true,
  }) async {
    if (_isCheckingReachability) return isOnline;
    _isCheckingReachability = true;

    try {
      final uri = Uri.tryParse(ApiEndpoints.baseUrl);
      if (uri == null || uri.host.isEmpty) {
        _setOffline();
        return false;
      }

      final port = uri.port > 0 ? uri.port : (uri.scheme == 'https' ? 443 : 80);

      // Method 1: Fast HTTP GET probe to /auth/ping to verify active Spring Boot API
      bool reachable = false;
      try {
        final client = HttpClient()..connectionTimeout = timeout;
        final pingUri = Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.ping}');
        final request = await client.getUrl(pingUri).timeout(timeout);
        final response = await request.close().timeout(timeout);
        reachable = response.statusCode == 200 || response.statusCode == 401;
        client.close();
      } catch (_) {
        // Method 2: Fast TCP socket connect fallback
        try {
          final socket = await Socket.connect(uri.host, port, timeout: timeout);
          socket.destroy();
          reachable = true;
        } catch (_) {
          reachable = false;
        }
      }

      // If currently configured baseUrl is unreachable, perform dynamic LAN discovery only when allowed
      if (!reachable && allowDiscovery) {
        final discovered = await LanDiscoveryService.discoverServer();
        if (discovered != null) {
          reachable = true;
          ApiEndpoints.setBaseUrl(discovered);
          onServerUrlDiscovered?.call(discovered);
          if (kDebugMode) {
            print('[ConnectivityMonitor] Dynamic LAN auto-discovery found: $discovered');
          }
        }
      }

      if (reachable) {
        _setOnline();
        return true;
      } else {
        _setOffline();
        return false;
      }
    } catch (_) {
      _setOffline();
      return false;
    } finally {
      _isCheckingReachability = false;
    }
  }

  /// Immediately mark as offline (called instantly by ApiClient on network errors/timeouts).
  void markOffline() {
    _setOffline();
  }

  /// Immediately mark as online (called when any network request succeeds).
  void markOnline() {
    _setOnline();
  }

  void _setOffline() {
    if (_currentStatus != NetworkStatus.offline) {
      _currentStatus = NetworkStatus.offline;
      _statusController.add(_currentStatus);
      if (kDebugMode) print('[ConnectivityMonitor] Switched to OFFLINE');
    }
  }

  void _setOnline() {
    final wasOffline = _currentStatus == NetworkStatus.offline;
    if (_currentStatus != NetworkStatus.online && _currentStatus != NetworkStatus.syncing) {
      _currentStatus = NetworkStatus.online;
      _statusController.add(_currentStatus);
      if (kDebugMode) print('[ConnectivityMonitor] Switched to ONLINE');

      if (wasOffline) {
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

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      // Don't interrupt while actively syncing
      if (_currentStatus == NetworkStatus.syncing) return;
      // Fast lightweight probe without heavy multi-phase LAN discovery when offline
      final isCurrentlyOffline = _currentStatus == NetworkStatus.offline;
      await checkRealReachability(
        timeout: isCurrentlyOffline
            ? const Duration(milliseconds: 2500)
            : const Duration(milliseconds: 2500),
        allowDiscovery: !isCurrentlyOffline,
      );
    });
  }

  /// Dispose all resources.
  void dispose() {
    _heartbeatTimer?.cancel();
    _subscription?.cancel();
    _statusController.close();
  }
}
