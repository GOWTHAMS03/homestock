import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../sync/sync_providers.dart';
import '../sync/sync_status.dart';
import 'app_theme.dart';

/// Provider for current online connectivity status.
/// Yields true when the device is online and can reach the backend.
final isOnlineProvider = Provider<bool>((ref) {
  final asyncStatus = ref.watch(networkStatusProvider);
  return asyncStatus.maybeWhen(
    data: (status) => status == NetworkStatus.online || status == NetworkStatus.syncing,
    orElse: () {
      try {
        final monitor = ref.watch(connectivityMonitorProvider);
        return monitor.isOnline;
      } catch (_) {
        // Fallback for tests/environments without connectivity monitor
        return true;
      }
    },
  );
});

/// Dynamic theme provider that yields AppTheme.onlineTheme (Purple) when online,
/// and AppTheme.offlineTheme (Warm Red) when offline.
final appThemeProvider = Provider<ThemeData>((ref) {
  final isOnline = ref.watch(isOnlineProvider);
  return isOnline ? AppTheme.onlineTheme : AppTheme.offlineTheme;
});
