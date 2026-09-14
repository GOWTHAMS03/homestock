import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../models/ai_voice_settings.dart';

/// Modal dialog displaying AI Voice Assistant preferences only
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
    final aiVoiceSettings = ref.watch(aiVoiceSettingsProvider);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.surface,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          const Text(
            'AI Voice Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text(
                      'Voice responses',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Speak spoken answers using neural AI voice',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    value: aiVoiceSettings.voiceResponsesEnabled,
                    activeTrackColor: AppColors.primary,
                    onChanged: (val) =>
                        ref.read(aiVoiceSettingsProvider.notifier).setVoiceResponsesEnabled(val),
                  ),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text(
                      'Auto-play',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Automatically speak after voice commands',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    value: aiVoiceSettings.autoPlayEnabled,
                    activeTrackColor: AppColors.primary,
                    onChanged: (val) =>
                        ref.read(aiVoiceSettingsProvider.notifier).setAutoPlayEnabled(val),
                  ),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text(
                      'Voice',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Natural female assistant (English, Tamil & Tanglish)',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                      ),
                      child: const Text(
                        'Cute Female',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Speaking speed',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Cadence multiplier',
                              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                        Row(
                          children: [0.8, 1.0, 1.2].map((speed) {
                            final isSel = (aiVoiceSettings.speakingSpeed - speed).abs() < 0.05;
                            return Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: InkWell(
                                onTap: () =>
                                    ref.read(aiVoiceSettingsProvider.notifier).setSpeakingSpeed(speed),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSel ? AppColors.primary : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSel ? AppColors.primary : const Color(0xFFCBD5E1),
                                    ),
                                  ),
                                  child: Text(
                                    '${speed}x',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isSel ? Colors.white : const Color(0xFF475569),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
}
