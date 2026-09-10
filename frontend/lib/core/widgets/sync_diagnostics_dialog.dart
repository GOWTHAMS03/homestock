import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../sync/sync_providers.dart';
import '../sync/sync_status.dart';

/// Diagnostics modal displaying deep synchronization metrics and debug triggers.
class SyncDiagnosticsDialog extends ConsumerWidget {
  const SyncDiagnosticsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const SyncDiagnosticsDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncStateProvider).valueOrNull ?? const SyncState();
    final syncDao = ref.watch(syncDaoProvider);
    final syncEngine = ref.watch(syncEngineProvider);

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.monitor_heart_rounded, color: AppColors.primary),
          SizedBox(width: 8),
          Text('Sync Diagnostics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRow('Lifecycle Status', syncState.syncStatus.name.toUpperCase()),
              _buildRow('Pending Operations', '${syncState.pendingOperationsCount}'),
              _buildRow('Last Synced', syncState.lastSyncedAgo),
              if (syncState.lastError != null)
                _buildRow('Last Error', syncState.lastError!, isError: true),
              const Divider(height: 24),
              const Text(
                'Pending Queue Operations',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              FutureBuilder(
                future: syncDao.getPendingOperations(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ));
                  }
                  final ops = snapshot.data ?? [];
                  if (ops.isEmpty) {
                    return const Text(
                      'No pending operations in local Drift queue.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: ops.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final op = ops[index];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          op.operationType,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                        subtitle: Text(
                          '${op.entityType} • ${op.createdAt.toIso8601String().substring(11, 19)}',
                          style: const TextStyle(fontSize: 10),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: op.status == 'PENDING'
                                ? Colors.amber.shade100
                                : Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            op.status,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: op.status == 'PENDING'
                                  ? Colors.amber.shade900
                                  : Colors.blue.shade900,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.sync, size: 16),
          label: const Text('Trigger Sync Now'),
          onPressed: () {
            Navigator.of(context).pop();
            syncEngine.syncAll();
          },
        ),
      ],
    );
  }

  Widget _buildRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isError ? Colors.red : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
