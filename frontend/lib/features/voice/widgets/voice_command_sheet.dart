import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../providers/voice_command_provider.dart';
import '../services/ai_voice_service.dart';
import 'ai_voice_response_card.dart';
import 'voice_feedback_widget.dart';
import 'voice_settings_dialog.dart';

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
  bool _lastInteractionWasVoice = true;
  String? _currentSessionResponseText;
  DateTime? _responseTimestamp;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(aiVoiceServiceProvider.notifier).stop();
      ref.read(voiceAiControllerProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    Future.microtask(() {
      try {
        ref.read(aiVoiceServiceProvider.notifier).stop();
      } catch (_) {}
    });
    _pulseController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(voiceAiControllerProvider);
    final theme = Theme.of(context);

    // Stop audio immediately whenever listening starts; capture fresh response on success
    ref.listen<VoiceAiState>(voiceAiControllerProvider, (prev, next) {
      if (next.status == VoiceAiStatus.listening) {
        Future.microtask(() {
          if (mounted) {
            ref.read(aiVoiceServiceProvider.notifier).stop();
          }
        });
      }
      if (next.status == VoiceAiStatus.success && prev?.status != VoiceAiStatus.success) {
        HapticFeedback.mediumImpact();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _currentSessionResponseText =
                  next.executionResponse?.message ?? next.commandResult?.message ?? 'Action completed!';
              _responseTimestamp = DateTime.now();
            });
          }
        });
      }
    });

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 18,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 42,
            height: 4.5,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 16),

          // Header: Assistant Title, Language Mode, Settings & Close
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Homie AI',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      state.detectedLanguage.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.tune_rounded, size: 19, color: Color(0xFF64748B)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                    tooltip: 'AI Voice Settings',
                    onPressed: () => VoiceSettingsDialog.show(context),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                    tooltip: 'Close Homie',
                    onPressed: () {
                      ref.read(aiVoiceServiceProvider.notifier).stop();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 1. AI Voice Response Card (ONLY rendered when response is ready for the current session)
          if (state.status == VoiceAiStatus.success && _currentSessionResponseText != null) ...[
            AiVoiceResponseCard(
              text: _currentSessionResponseText!,
              language: state.detectedLanguage,
              isVoiceInteraction: _lastInteractionWasVoice,
              timestamp: _responseTimestamp,
            ),
            const SizedBox(height: 14),
          ],

          // 3. Error Message Banner
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
                  const Icon(Icons.info_outline_rounded, color: Color(0xFFE11D48), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.errorMessage ?? 'Could not process voice command.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFFBE123C),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // 4. Disambiguation / Confirmation Widget
          if (state.status == VoiceAiStatus.confirming && state.commandResult != null) ...[
            VoiceFeedbackWidget(
              result: state.commandResult!,
              isVoiceInteraction: _lastInteractionWasVoice,
              onConfirm: () {
                ref.read(aiVoiceServiceProvider.notifier).stop();
                ref.read(voiceAiControllerProvider.notifier).executeCommand();
              },
              onCancel: () {
                ref.read(aiVoiceServiceProvider.notifier).stop();
                ref.read(voiceAiControllerProvider.notifier).cancel();
              },
              onOptionSelected: (optId) {
                ref.read(aiVoiceServiceProvider.notifier).stop();
                ref.read(voiceAiControllerProvider.notifier).executeCommand(selectedOptionId: optId);
              },
            ),
            const SizedBox(height: 14),
          ],

          // 5. Mic Recording Button & Dynamic Visualizer
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
                          color: Colors.red.withValues(alpha: 0.15),
                        ),
                      ),
                    GestureDetector(
                      onTap: () {
                        if (state.isRecording) {
                          ref.read(voiceAiControllerProvider.notifier).stopListeningAndProcess();
                        } else {
                          // Immediately kill any active speech and clear previous response card!
                          ref.read(aiVoiceServiceProvider.notifier).stop();
                          setState(() {
                            _currentSessionResponseText = null;
                            _lastInteractionWasVoice = true;
                          });
                          ref.read(voiceAiControllerProvider.notifier).startListening();
                        }
                      },
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: state.isRecording
                                ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                                : (state.isProcessing
                                    ? [AppColors.secondary, AppColors.secondary.withValues(alpha: 0.8)]
                                    : [AppColors.primary, AppColors.primary.withValues(alpha: 0.85)]),
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (state.isRecording ? Colors.red : AppColors.primary).withValues(alpha: 0.3),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          state.isRecording
                              ? Icons.stop_rounded
                              : (state.isProcessing ? Icons.auto_awesome : Icons.mic_rounded),
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

          // Status caption
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
              color: state.isRecording ? const Color(0xFFDC2626) : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 16),

          if (!state.isProcessing) _buildSuggestionChips(ref, theme),
        ],
      ),
    );
  }

  Widget _buildSuggestionChips(WidgetRef ref, ThemeData theme) {
    final suggestions = [
      'Add 2 kg rice',
      'Milk low stock',
      'Show my shopping list',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: suggestions.map((phrase) {
        return InkWell(
          onTap: () {
            ref.read(aiVoiceServiceProvider.notifier).stop();
            setState(() {
              _currentSessionResponseText = null;
              _lastInteractionWasVoice = false;
            });
            ref.read(voiceAiControllerProvider.notifier).processText(phrase);
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.chat_bubble_outline_rounded, size: 12, color: Color(0xFF64748B)),
                const SizedBox(width: 5),
                Text(
                  phrase,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF334155),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
