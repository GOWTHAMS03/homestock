import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../controllers/voice_controller.dart';
import '../data/speech/offline_model_manager.dart';
import '../data/speech/speech_engine.dart';
import 'voice_model_settings.dart';

/// Modal dialog for configuring Voice Recognition preferences
class VoiceSettingsDialog extends ConsumerWidget {
  const VoiceSettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const VoiceSettingsDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voiceState = ref.watch(voiceControllerProvider);
    final notifier = ref.read(voiceControllerProvider.notifier);
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
          Icon(Icons.tune, color: AppColors.primary),
          SizedBox(width: 10),
          Text(
            'Voice Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── OFFLINE MODEL STATUS CARD ───
            const Text(
              'OFFLINE VOICE ENGINE (WHISPER.CPP)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                Navigator.of(context).pop();
                VoiceModelSettingsDialog.show(context);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isInstalled
                      ? AppColors.inStockBg
                      : (isDownloading ? AppColors.secondaryContainer.withAlpha(100) : AppColors.lowStockBg),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isInstalled
                        ? AppColors.inStockBorder
                        : (isDownloading ? AppColors.secondary.withAlpha(100) : AppColors.lowStockBorder),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isInstalled
                          ? Icons.offline_bolt
                          : (isDownloading ? Icons.sync : Icons.download),
                      size: 24,
                      color: isInstalled
                          ? AppColors.inStockText
                          : (isDownloading ? AppColors.secondary : AppColors.lowStockText),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isInstalled
                                ? 'Whisper ${modelInfo.name} (${modelInfo.sizeMb} MB)'
                                : (isDownloading
                                    ? 'Downloading ${(modelInfo.downloadProgress * 100).toInt()}%'
                                    : 'No Model Installed'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isInstalled
                                  ? AppColors.inStockText
                                  : (isDownloading ? AppColors.secondaryDark : AppColors.lowStockText),
                            ),
                          ),
                          Text(
                            isInstalled
                                ? 'Ready for 100% offline Tamil + English'
                                : (isDownloading
                                    ? 'Please wait while model downloads'
                                    : 'Tap to download free offline model'),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 24),

            // ─── RECOGNITION MODE ───
            const Text(
              'SPEECH RECOGNITION MODE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            _buildModeTile(
              context: context,
              title: 'Auto (Recommended)',
              subtitle: 'Offline whisper.cpp first, cloud fallback only if needed',
              value: SpeechEngineMode.auto,
              selected: voiceState.engineMode,
              onSelected: notifier.setEngineMode,
            ),
            _buildModeTile(
              context: context,
              title: 'Offline Only',
              subtitle: '100% free whisper.cpp on device (no internet or API key)',
              value: SpeechEngineMode.offlineOnly,
              selected: voiceState.engineMode,
              onSelected: notifier.setEngineMode,
            ),
            _buildModeTile(
              context: context,
              title: 'Online Preferred',
              subtitle: 'Uses cloud Whisper when available',
              value: SpeechEngineMode.onlinePreferred,
              selected: voiceState.engineMode,
              onSelected: notifier.setEngineMode,
            ),
            const Divider(height: 24),

            // ─── PRIMARY LANGUAGE ───
            const Text(
              'PRIMARY LANGUAGE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildLangChip(
                  label: 'Auto (Tanglish/Tamil/English)',
                  code: 'auto',
                  current: voiceState.languageHint,
                  onSelected: notifier.setLanguageHint,
                ),
                _buildLangChip(
                  label: 'Tamil (தமிழ்)',
                  code: 'ta',
                  current: voiceState.languageHint,
                  onSelected: notifier.setLanguageHint,
                ),
                _buildLangChip(
                  label: 'English',
                  code: 'en',
                  current: voiceState.languageHint,
                  onSelected: notifier.setLanguageHint,
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildModeTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required SpeechEngineMode value,
    required SpeechEngineMode selected,
    required void Function(SpeechEngineMode) onSelected,
  }) {
    final isSelected = value == selected;
    return InkWell(
      onTap: () => onSelected(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryContainer.withAlpha(50) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outlineVariant.withAlpha(80),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: 20,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLangChip({
    required String label,
    required String code,
    required String current,
    required void Function(String) onSelected,
  }) {
    final isSelected = code == current;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      onSelected: (_) => onSelected(code),
      selectedColor: AppColors.primaryContainer,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
