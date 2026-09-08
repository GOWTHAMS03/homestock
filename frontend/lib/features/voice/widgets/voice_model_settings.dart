import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../controllers/voice_controller.dart';
import '../data/speech/offline_model_manager.dart';

/// Modal dialog and embedded widget for managing offline Whisper.cpp speech models.
/// Completely free, local, on-device speech recognition without OpenAI or internet.
class VoiceModelSettingsDialog extends ConsumerStatefulWidget {
  const VoiceModelSettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const VoiceModelSettingsDialog(),
    );
  }

  @override
  ConsumerState<VoiceModelSettingsDialog> createState() =>
      _VoiceModelSettingsDialogState();
}

class _VoiceModelSettingsDialogState
    extends ConsumerState<VoiceModelSettingsDialog> {
  String _selectedVariantId = 'base';

  @override
  Widget build(BuildContext context) {
    final modelInfoAsync = ref.watch(modelInfoProvider);
    final modelManager = ref.watch(offlineModelManagerProvider);

    final modelInfo = modelInfoAsync.value ?? modelManager.currentModel;
    final isInstalled = modelInfo.status == ModelStatus.installed ||
        modelInfo.status == ModelStatus.ready;
    final isDownloading = modelInfo.status == ModelStatus.downloading;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.surface,
      title: const Row(
        children: [
          Icon(Icons.offline_bolt, color: AppColors.primary, size: 24),
          SizedBox(width: 10),
          Text(
            'Offline Voice Model',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            _buildStatusCard(modelInfo, isInstalled, isDownloading),
            const SizedBox(height: 16),

            // Privacy Assurance Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.outlineVariant.withAlpha(80)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline, size: 16, color: AppColors.secondary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '100% Free & Private — Speech is recognized natively on-device via whisper.cpp. No API keys or internet needed.',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'SELECT MODEL VARIANT',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),

            // Available Models List
            ...OfflineModelManager.availableModels.map((variant) {
              final isSelected = variant.id == _selectedVariantId;
              final isCurrent = modelInfo.name.toLowerCase().contains(variant.displayName.toLowerCase()) && isInstalled;

              return InkWell(
                onTap: isDownloading
                    ? null
                    : () {
                        setState(() {
                          _selectedVariantId = variant.id;
                        });
                      },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryContainer.withAlpha(60)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.outlineVariant.withAlpha(80),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          size: 18,
                          color: isSelected ? AppColors.primary : AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  variant.displayName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${variant.approximateSizeMb} MB',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                if (variant.id == 'base') ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.inStockBg,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Recommended',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.inStockText,
                                      ),
                                    ),
                                  ),
                                ],
                                if (isCurrent) ...[
                                  const Spacer(),
                                  const Icon(Icons.check_circle,
                                      color: AppColors.inStockText, size: 16),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              variant.description,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 8),

            // Actions: Download or Delete
            if (isDownloading)
              _buildDownloadingWidget(modelInfo)
            else
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _startDownload(modelManager),
                      icon: Icon(
                        isInstalled ? Icons.sync : Icons.download,
                        size: 18,
                      ),
                      label: Text(
                        isInstalled ? 'Change Model' : 'Download Model',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  if (isInstalled) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Delete Model',
                      onPressed: () => _confirmDelete(context, modelManager),
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.outOfStockText),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.outOfStockBg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildStatusCard(
      ModelInfo modelInfo, bool isInstalled, bool isDownloading) {
    if (isDownloading) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.secondaryContainer.withAlpha(100),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.secondary.withAlpha(80)),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Downloading ${modelInfo.name}...',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondaryDark,
                    ),
                  ),
                  Text(
                    '${(modelInfo.downloadProgress * 100).toInt()}% completed',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (isInstalled) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.inStockBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.inStockBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.inStockText, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Installed: Whisper ${modelInfo.name}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.inStockText,
                    ),
                  ),
                  Text(
                    'Size: ${modelInfo.sizeMb} MB • Tamil + English Multilingual',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lowStockBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lowStockBorder),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.lowStockText, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No Voice Model Installed',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.lowStockText,
                  ),
                ),
                Text(
                  'Download a model below to enable 100% offline voice commands.',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadingWidget(ModelInfo modelInfo) {
    final pct = (modelInfo.downloadProgress * 100).toInt();
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: modelInfo.downloadProgress > 0 ? modelInfo.downloadProgress : null,
            backgroundColor: AppColors.outlineVariant.withAlpha(80),
            color: AppColors.primary,
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Downloading model... $pct%',
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
      ],
    );
  }

  void _startDownload(OfflineModelManager modelManager) {
    final variant = OfflineModelManager.availableModels
        .firstWhere((m) => m.id == _selectedVariantId);

    modelManager.downloadModel(variant);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading ${variant.displayName} voice model...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, OfflineModelManager modelManager) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Voice Model?'),
        content: const Text(
          'This will remove the downloaded voice model from your device storage. Voice commands will require an internet connection until you download it again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.outOfStockText,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await modelManager.deleteModel();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Voice model deleted.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
