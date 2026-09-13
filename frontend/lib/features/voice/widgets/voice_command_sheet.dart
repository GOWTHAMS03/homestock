import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../models/voice_models.dart';
import '../providers/voice_command_provider.dart';
import 'voice_feedback_widget.dart';

class VoiceCommandSheet extends ConsumerStatefulWidget {
  const VoiceCommandSheet({super.key});

  static Future<void> show(BuildContext context) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const VoiceCommandSheet(),
    );
  }

  @override
  ConsumerState<VoiceCommandSheet> createState() => _VoiceCommandSheetState();
}

class _VoiceCommandSheetState extends ConsumerState<VoiceCommandSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(voiceAiControllerProvider.notifier).reset();
      ref.read(voiceAiControllerProvider.notifier).startListening();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(voiceAiControllerProvider);
    final theme = Theme.of(context);

    // Haptic feedback on success (manual close, no auto-dismiss)
    ref.listen<VoiceAiState>(voiceAiControllerProvider, (prev, next) {
      if (next.status == VoiceAiStatus.success && prev?.status != VoiceAiStatus.success) {
        HapticFeedback.mediumImpact();
      }
    });

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 20,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Title & Language Mode & Close Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Homie',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      state.detectedLanguage,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    tooltip: 'Close Homie',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 1. Success Message Banner (retains response while letting user speak next command)
          if (state.status == VoiceAiStatus.success) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.executionResponse?.message ?? state.commandResult?.message ?? 'Action completed!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF15803D),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // 2. Error Message Banner
          if (state.status == VoiceAiStatus.error) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFECDD3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Color(0xFFE11D48), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.errorMessage ?? 'Something went wrong',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFFBE123C),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // 3. Transcript or Status Display - Only show current transcript when NOT listening or searching freshly
          if (state.transcript.isNotEmpty && !state.isRecording && !state.isProcessing && state.status != VoiceAiStatus.success) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '"${state.transcript}"',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // 4. Parsed Feedback Card if confirmation is required
          if (state.commandResult != null && state.status == VoiceAiStatus.confirming)
            VoiceFeedbackWidget(
              result: state.commandResult!,
              onConfirm: () => ref.read(voiceAiControllerProvider.notifier).executeCommand(),
              onCancel: () => ref.read(voiceAiControllerProvider.notifier).cancel(),
              onOptionSelected: (optId) => ref.read(voiceAiControllerProvider.notifier).executeCommand(selectedOptionId: optId),
            )
          else ...[
            // 5. Waveform / Mic recording visualizer - ALWAYS available for continuous conversation!
            Center(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale = state.isRecording
                      ? 1.0 + (state.amplitude * 0.3) + (_pulseController.value * 0.1)
                      : 1.0;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      if (state.isRecording)
                        Container(
                          width: 100 * scale,
                          height: 100 * scale,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withOpacity(0.15),
                          ),
                        ),
                      GestureDetector(
                        onTap: () {
                          if (state.isRecording) {
                            ref.read(voiceAiControllerProvider.notifier).stopListeningAndProcess();
                          } else {
                            ref.read(voiceAiControllerProvider.notifier).startListening();
                          }
                        },
                        child: CircleAvatar(
                          radius: 36,
                          backgroundColor: state.isRecording
                              ? Colors.red
                              : (state.isProcessing ? AppColors.secondary : AppColors.primary),
                          child: Icon(
                            state.isRecording
                                ? Icons.mic
                                : (state.isProcessing ? Icons.auto_awesome : Icons.mic_none),
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            Text(
              state.isRecording
                  ? 'Listening... Tap to stop'
                  : (state.isProcessing
                      ? 'Homie understanding speech...'
                      : (state.status == VoiceAiStatus.success
                          ? 'Tap mic to ask next command'
                          : 'Tap mic to speak')),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: state.isRecording ? AppColors.primary : theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            if (!state.isProcessing) _buildSuggestionChips(ref, theme),
          ],
        ],
      ),
    );
  }

  Widget _buildSuggestionChips(WidgetRef ref, ThemeData theme) {
    const suggestions = [
      '2 kilo rice shopping list la add pannu',
      '1 litre oil inventory la add pannu',
      'inventory la rice stock evlo irukku?',
      'shopping list la sugar add pannu',
      'naan 5 kilo rice vangiten',
      'shopping list la irukura oil remove pannu',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(Icons.lightbulb_outline, size: 14, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              'Try saying (or tap to test):',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: suggestions.map((phrase) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  backgroundColor: AppColors.primaryContainer.withOpacity(0.5),
                  side: BorderSide(color: AppColors.primary.withOpacity(0.2)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  label: Text(
                    phrase,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ref.read(voiceAiControllerProvider.notifier).processText(phrase);
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
