import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../controllers/voice_controller.dart';
import '../data/speech/speech_engine.dart';

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
              subtitle: 'Online accuracy with instant offline fallback',
              value: SpeechEngineMode.auto,
              selected: voiceState.engineMode,
              onSelected: notifier.setEngineMode,
            ),
            _buildModeTile(
              context: context,
              title: 'Offline Only',
              subtitle: 'Processes everything locally on device',
              value: SpeechEngineMode.offlineOnly,
              selected: voiceState.engineMode,
              onSelected: notifier.setEngineMode,
            ),
            _buildModeTile(
              context: context,
              title: 'Online Preferred',
              subtitle: 'Uses cloud Whisper whenever available',
              value: SpeechEngineMode.onlinePreferred,
              selected: voiceState.engineMode,
              onSelected: notifier.setEngineMode,
            ),
            const Divider(height: 28),
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
