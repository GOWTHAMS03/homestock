import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../sync/sync_providers.dart';
import '../sync/sync_status.dart';

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
    // If online and no pending changes, hide completely
    if (syncState.isOnline && syncState.pendingOperationsCount == 0) {
      return const SizedBox.shrink();
    }

    final Color bgColor;
    final Color textColor;
    final IconData icon;
    final String message;
    final bool isSpinning;

    if (syncState.isSyncing) {
      bgColor = AppColors.primaryContainer;
      textColor = AppColors.primaryDark;
      icon = Icons.sync_rounded;
      message = syncState.pendingOperationsCount > 0
          ? 'Syncing ${syncState.pendingOperationsCount} change(s)...'
          : 'Syncing with server...';
      isSpinning = true;
    } else if (syncState.isOffline) {
      bgColor = const Color(0xFFFEF3C7); // Amber 100
      textColor = const Color(0xFF92400E); // Amber 800
      icon = Icons.cloud_off_rounded;
      message = syncState.pendingOperationsCount > 0
          ? 'Offline • ${syncState.pendingOperationsCount} change(s) saved locally'
          : 'Offline • Changes will sync when online';
      isSpinning = false;
    } else {
      // Online but pending sync
      bgColor = const Color(0xFFE0E7FF); // Indigo 100
      textColor = const Color(0xFF3730A3); // Indigo 800
      icon = Icons.cloud_queue_rounded;
      message = '${syncState.pendingOperationsCount} change(s) waiting to sync';
      isSpinning = false;
    }

    if (compact) {
      return AnimatedContainer(
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
      );
    }

    return InkWell(
      onTap: syncState.isSyncing
          ? null
          : () {
              ref.read(syncEngineProvider).syncAll();
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
              if (syncState.isOffline && syncState.lastSyncedAt != null)
                Text(
                  syncState.lastSyncedAgo,
                  style: TextStyle(
                    fontSize: 11,
                    color: textColor.withValues(alpha: 0.8),
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
                ),
            ],
          ),
        ),
      ),
    );
  }
}
