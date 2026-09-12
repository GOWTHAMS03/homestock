import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../database/app_database.dart';
import '../sync/sync_providers.dart';
import '../sync/sync_status.dart';

/// Diagnostics modal displaying deep synchronization metrics and debug triggers.
/// Supports inspecting all 5 sync operation states:
/// pending, syncing, synced, failed, conflict.
class SyncDiagnosticsDialog extends ConsumerStatefulWidget {
  const SyncDiagnosticsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const SyncDiagnosticsDialog(),
    );
  }

  @override
  ConsumerState<SyncDiagnosticsDialog> createState() =>
      _SyncDiagnosticsDialogState();
}

class _SyncDiagnosticsDialogState
    extends ConsumerState<SyncDiagnosticsDialog> {
  String _selectedFilter = 'ALL'; // ALL, PENDING, SYNCING, SYNCED, FAILED, CONFLICT

  @override
  Widget build(BuildContext context) {
    final syncState =
        ref.watch(syncStateProvider).valueOrNull ?? const SyncState();
    final syncDao = ref.watch(syncDaoProvider);
    final syncEngine = ref.watch(syncEngineProvider);
    final summaryAsync = ref.watch(syncQueueSummaryProvider);
    final summary = summaryAsync.valueOrNull ?? const SyncQueueSummary();

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.monitor_heart_rounded,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Sync Diagnostics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close',
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Status Metrics Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _buildMetricRow('Lifecycle State',
                        syncState.syncStatus.name.toUpperCase()),
                    _buildMetricRow('Network Status',
                        syncState.status.name.toUpperCase()),
                    _buildMetricRow('Last Synced', syncState.lastSyncedAgo),
                    if (syncState.lastError != null &&
                        syncState.lastError!.isNotEmpty)
                      _buildMetricRow('Last Engine Error', syncState.lastError!,
                          isError: true),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Status Summary Badges (Requirement 16: pending, syncing, synced, failed, conflict)
              const Text(
                'Operation Queue Health',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildFilterChip('ALL', 'All', summary.totalTracked, Colors.grey),
                  _buildFilterChip('PENDING', 'Pending', summary.pending, Colors.amber),
                  _buildFilterChip('SYNCING', 'Syncing', summary.syncing, Colors.blue),
                  _buildFilterChip('SYNCED', 'Synced', summary.synced, Colors.green),
                  _buildFilterChip('FAILED', 'Failed', summary.failed, Colors.red),
                  _buildFilterChip('CONFLICT', 'Conflict', summary.conflict, Colors.purple),
                ],
              ),
              const SizedBox(height: 14),

              // Filtered Queue List Header & Action Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$_selectedFilter Operations',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  if (_selectedFilter == 'FAILED' || summary.hasFailures)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.refresh_rounded, size: 14),
                      label: const Text('Retry Failed',
                          style: TextStyle(fontSize: 11)),
                      onPressed: () async {
                        await syncEngine.retryFailedOperations();
                        if (mounted) setState(() {});
                      },
                    ),
                ],
              ),
              const SizedBox(height: 6),

              // Queue Operation List
              FutureBuilder<List<SyncQueueEntry>>(
                future: _fetchOperations(syncDao),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  final ops = snapshot.data ?? [];
                  if (ops.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'No $_selectedFilter operations found in local Drift queue.',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: ops.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final op = ops[index];
                      return _buildOperationCard(op);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (summary.synced > 0)
          TextButton(
            onPressed: () async {
              await syncEngine.clearSyncedHistory();
              if (mounted) setState(() {});
            },
            child: const Text('Clear Synced', style: TextStyle(fontSize: 12)),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.sync, size: 16),
          label: const Text('Sync Now'),
          onPressed: () {
            Navigator.of(context).pop();
            syncEngine.syncAll();
          },
        ),
      ],
    );
  }

  Future<List<SyncQueueEntry>> _fetchOperations(dynamic syncDao) async {
    if (_selectedFilter == 'ALL') {
      final pending = await syncDao.getPendingOperations();
      final syncing = await syncDao.getSyncingOperations();
      final failed = await syncDao.getFailedOperations(maxRetries: 999);
      final conflict = await syncDao.getConflictOperations();
      final synced = await syncDao.getSyncedOperations(limit: 20);
      return [...pending, ...syncing, ...failed, ...conflict, ...synced];
    } else if (_selectedFilter == 'PENDING') {
      return syncDao.getPendingOperations();
    } else if (_selectedFilter == 'SYNCING') {
      return syncDao.getSyncingOperations();
    } else if (_selectedFilter == 'SYNCED') {
      return syncDao.getSyncedOperations(limit: 50);
    } else if (_selectedFilter == 'FAILED') {
      return syncDao.getFailedOperations(maxRetries: 999);
    } else if (_selectedFilter == 'CONFLICT') {
      return syncDao.getConflictOperations();
    }
    return syncDao.getOperationsByStatus(_selectedFilter);
  }

  Widget _buildFilterChip(
      String filterKey, String label, int count, Color color) {
    final isSelected = _selectedFilter == filterKey;
    return FilterChip(
      selected: isSelected,
      showCheckmark: false,
      label: Text('$label ($count)'),
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? Colors.white : Colors.black87,
      ),
      selectedColor: color is MaterialColor ? color.shade700 : color,
      backgroundColor: color.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected
              ? Colors.transparent
              : color.withValues(alpha: 0.3),
        ),
      ),
      onSelected: (_) {
        setState(() {
          _selectedFilter = filterKey;
        });
      },
    );
  }

  Widget _buildOperationCard(SyncQueueEntry op) {
    Color badgeColor;
    Color textColor;

    switch (op.status) {
      case 'PENDING':
        badgeColor = Colors.amber.shade100;
        textColor = Colors.amber.shade900;
        break;
      case 'SYNCING':
        badgeColor = Colors.blue.shade100;
        textColor = Colors.blue.shade900;
        break;
      case 'SYNCED':
        badgeColor = Colors.green.shade100;
        textColor = Colors.green.shade900;
        break;
      case 'FAILED':
        badgeColor = Colors.red.shade100;
        textColor = Colors.red.shade900;
        break;
      case 'CONFLICT':
        badgeColor = Colors.purple.shade100;
        textColor = Colors.purple.shade900;
        break;
      default:
        badgeColor = Colors.grey.shade200;
        textColor = Colors.black87;
    }

    String timeStr = '';
    try {
      timeStr = op.createdAt.toLocal().toIso8601String().substring(11, 19);
    } catch (_) {}

    Map<String, dynamic> payloadMap = {};
    try {
      payloadMap = jsonDecode(op.payload) as Map<String, dynamic>;
    } catch (_) {}

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  op.operationType,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  op.status,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${op.entityType} • ID: ${op.entityId.length > 8 ? op.entityId.substring(0, 8) : op.entityId}... • $timeStr',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
          ),
          if (op.operationId.isNotEmpty)
            Text(
              'opId: ${op.operationId.length > 12 ? op.operationId.substring(0, 12) : op.operationId}...',
              style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
            ),
          if (payloadMap.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                payloadMap.entries
                    .take(3)
                    .map((e) => '${e.key}: ${e.value}')
                    .join(', '),
                style: const TextStyle(fontSize: 9, fontFamily: 'monospace'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          if (op.lastError != null && op.lastError!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Error (Retries: ${op.retryCount}): ${op.lastError}',
              style: const TextStyle(
                  fontSize: 10,
                  color: Colors.red,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
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
