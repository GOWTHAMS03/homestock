import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../sync/sync_providers.dart';
import '../sync/sync_status.dart';

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
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),
        ),
      );
    }

    // Clean, minimal Wi-Fi off badge
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
          padding: EdgeInsets.symmetric(horizontal: showText ? 8 : 6, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFECACA), width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                size: 14,
                color: Color(0xFFDC2626),
              ),
              if (showText) ...[
                const SizedBox(width: 4),
                const Text(
                  'Offline',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFDC2626),
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
