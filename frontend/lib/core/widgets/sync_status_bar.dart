import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../sync/sync_providers.dart';
import '../sync/sync_status.dart';
import 'sync_diagnostics_dialog.dart';

/// A sleek, non-intrusive status banner displaying current offline/syncing status.
///
/// Automatically hides when online with no pending changes.
/// Shows animated indicator when syncing, and persistent warning when offline.
class SyncStatusBar extends ConsumerWidget {
  final bool compact;

  const SyncStatusBar({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStateAsync = ref.watch(syncStateProvider);

    return syncStateAsync.when(
      data: (syncState) => _buildBar(context, ref, syncState),
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }

  Widget _buildBar(BuildContext context, WidgetRef ref, SyncState syncState) {
    // If synced or online with no pending changes, hide completely
    if (syncState.isSynced && syncState.pendingOperationsCount == 0) {
      return const SizedBox.shrink();
    }
    if (syncState.isOnline && syncState.pendingOperationsCount == 0 && !syncState.isSyncing) {
      return const SizedBox.shrink();
    }

    final Color bgColor;
    final Color textColor;
    final IconData icon;
    final String message;
    final bool isSpinning;

    switch (syncState.syncStatus) {
      case SyncStatus.syncingPush:
        bgColor = AppColors.primaryContainer;
        textColor = AppColors.primaryDark;
        icon = Icons.cloud_upload_rounded;
        message = syncState.pendingOperationsCount > 0
            ? 'Uploading ${syncState.pendingOperationsCount} change(s)...'
            : 'Uploading changes to server...';
        isSpinning = true;
        break;
      case SyncStatus.syncingPull:
        bgColor = AppColors.primaryContainer;
        textColor = AppColors.primaryDark;
        icon = Icons.cloud_download_rounded;
        message = 'Checking for remote updates...';
        isSpinning = true;
        break;
      case SyncStatus.reconciling:
        bgColor = const Color(0xFFEDE9FE); // Purple 100
        textColor = const Color(0xFF5B21B6); // Purple 800
        icon = Icons.sync_rounded;
        message = 'Reconciling data with server...';
        isSpinning = true;
        break;
      case SyncStatus.networkAvailable:
        bgColor = const Color(0xFFE0E7FF); // Indigo 100
        textColor = const Color(0xFF3730A3); // Indigo 800
        icon = Icons.wifi_rounded;
        message = syncState.pendingOperationsCount > 0
            ? 'Network available • Syncing ${syncState.pendingOperationsCount} changes soon'
            : 'Network available • Connecting...';
        isSpinning = false;
        break;
      case SyncStatus.authRequired:
        bgColor = const Color(0xFFFFE4E6); // Rose 100
        textColor = const Color(0xFF9F1239); // Rose 800
        icon = Icons.lock_outline_rounded;
        message = 'Session expired • Sign in to sync changes';
        isSpinning = false;
        break;
      case SyncStatus.error:
        bgColor = const Color(0xFFFEE2E2); // Red 100
        textColor = const Color(0xFF991B1B); // Red 800
        icon = Icons.error_outline_rounded;
        message = syncState.lastError != null && syncState.lastError!.isNotEmpty
            ? 'Sync error: ${syncState.lastError}'
            : 'Sync error • Retrying shortly';
        isSpinning = false;
        break;
      case SyncStatus.offline:
        bgColor = const Color(0xFFFEF3C7); // Amber 100
        textColor = const Color(0xFF92400E); // Amber 800
        icon = Icons.cloud_off_rounded;
        message = syncState.pendingOperationsCount > 0
            ? 'Offline • ${syncState.pendingOperationsCount} change(s) saved locally'
            : 'Offline • Operating smoothly from local data';
        isSpinning = false;
        break;
      case SyncStatus.synced:
        bgColor = const Color(0xFFDCFCE7); // Green 100
        textColor = const Color(0xFF166534); // Green 800
        icon = Icons.cloud_done_rounded;
        message = 'All changes synced';
        isSpinning = false;
        break;
    }

    if (compact) {
      return GestureDetector(
        onLongPress: () => SyncDiagnosticsDialog.show(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              isSpinning
                  ? SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(textColor),
                      ),
                    )
                  : Icon(icon, size: 14, color: textColor),
              const SizedBox(width: 6),
              Text(
                message,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onLongPress: () => SyncDiagnosticsDialog.show(context),
      onTap: syncState.isSyncing
          ? null
          : () async {
              if (syncState.isOffline) {
                final reachable = await ref.read(connectivityMonitorProvider).checkRealReachability();
                if (reachable) {
                  ref.read(syncEngineProvider).syncAll();
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Server is not reachable. Operating smoothly in offline mode.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } else {
                ref.read(syncEngineProvider).syncAll();
              }
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: bgColor,
        child: SafeArea(
          top: false,
          bottom: false,
          child: Row(
            children: [
              isSpinning
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(textColor),
                      ),
                    )
                  : Icon(icon, size: 16, color: textColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
              if (syncState.isOffline || syncState.syncStatus == SyncStatus.error)
                Text(
                  'Tap to retry',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    decoration: TextDecoration.underline,
                  ),
                )
              else if (!syncState.isSyncing && syncState.pendingOperationsCount > 0)
                Text(
                  'Tap to sync',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    decoration: TextDecoration.underline,
                  ),
                )
              else if (syncState.lastSyncedAt != null)
                Text(
                  syncState.lastSyncedAgo,
                  style: TextStyle(
                    fontSize: 11,
                    color: textColor.withValues(alpha: 0.8),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
