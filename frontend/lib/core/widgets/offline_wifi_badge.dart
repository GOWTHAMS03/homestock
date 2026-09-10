import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../sync/sync_providers.dart';
import '../sync/sync_status.dart';

/// Subtle, calm status indicator answering:
/// - Online: ● Online (muted red dot #C85C5C)
/// - Offline: ● Offline · Changes will sync automatically (purple dot #7653C6)
/// Non-intrusive, offline is NOT an error.
class SubtleStatusIndicator extends ConsumerWidget {
  final bool showSyncNote;

  const SubtleStatusIndicator({
    super.key,
    this.showSyncNote = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStateAsync = ref.watch(syncStateProvider);

    return syncStateAsync.when(
      data: (syncState) => _buildIndicator(context, ref, syncState),
      loading: () => _buildOnlineIndicator(),
      error: (_, _) => _buildOfflineIndicator(context, ref, 0),
    );
  }

  Widget _buildIndicator(BuildContext context, WidgetRef ref, SyncState syncState) {
    if (syncState.isSyncing) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 8,
            height: 8,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'Syncing...',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      );
    }

    if (syncState.isOnline) {
      return _buildOnlineIndicator();
    }

    return _buildOfflineIndicator(context, ref, syncState.pendingOperationsCount);
  }

  Widget _buildOnlineIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: AppColors.statusOnline,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        const Text(
          'Online',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildOfflineIndicator(BuildContext context, WidgetRef ref, int pendingCount) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              pendingCount > 0
                  ? '$pendingCount change(s) saved locally. Syncing will resume automatically when connected.'
                  : 'Working offline: Everything is saved locally on your phone.',
              style: const TextStyle(fontSize: 12.5),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF1E293B),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Retry',
              textColor: AppColors.primaryLight,
              onPressed: () => ref.read(syncEngineProvider).syncAll(),
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: AppColors.statusOffline,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              showSyncNote
                  ? 'Offline · Changes will sync automatically'
                  : 'Offline',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A sleek, non-disruptive offline indicator that renders a simple wifi icon
/// without pushing or disrupting the UI.
class OfflineWifiBadge extends ConsumerWidget {
  final bool showText;

  const OfflineWifiBadge({
    super.key,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStateAsync = ref.watch(syncStateProvider);

    return syncStateAsync.when(
      data: (syncState) => _buildIndicator(context, ref, syncState),
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildIndicator(BuildContext context, WidgetRef ref, SyncState syncState) {
    // If online and not syncing, do not disrupt the UI at all
    if (syncState.isOnline && !syncState.isSyncing) {
      return const SizedBox.shrink();
    }

    if (syncState.isSyncing) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Tooltip(
          message: 'Syncing changes...',
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),
        ),
      );
    }

    // Clean, minimal Wi-Fi off badge with calm purple accent (Offline != Error)
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      syncState.pendingOperationsCount > 0
                          ? 'Offline: ${syncState.pendingOperationsCount} change(s) saved locally'
                          : 'Working offline: Everything is saved locally on your phone',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF1E293B),
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Retry',
                textColor: AppColors.primaryLight,
                onPressed: () => ref.read(syncEngineProvider).syncAll(),
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: showText ? 8 : 6, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outline, width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                size: 13,
                color: AppColors.statusOffline,
              ),
              if (showText) ...[
                const SizedBox(width: 4),
                const Text(
                  'Offline',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
