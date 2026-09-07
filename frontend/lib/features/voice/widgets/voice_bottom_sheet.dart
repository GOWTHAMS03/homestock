import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../controllers/voice_controller.dart';
import '../models/voice_models.dart';

class VoiceBottomSheet extends ConsumerStatefulWidget {
  const VoiceBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const VoiceBottomSheet(),
    );
  }

  @override
  ConsumerState<VoiceBottomSheet> createState() => _VoiceBottomSheetState();
}

class _VoiceBottomSheetState extends ConsumerState<VoiceBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final TextEditingController _textEditingController = TextEditingController();
  bool _isEditingTranscript = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // Auto-start recording on bottom sheet presentation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(voiceControllerProvider.notifier).startRecording();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceControllerProvider);
    final theme = Theme.of(context);

    // Auto-dismiss on success after short delay
    ref.listen<VoiceState>(voiceControllerProvider, (previous, next) {
      if (next.status == VoiceStatus.success && previous?.status != VoiceStatus.success) {
        HapticFeedback.mediumImpact();
        final nav = next.executionResponse?.navigation;
        final navigator = Navigator.of(context);
        final router = GoRouter.of(context);
        Future.delayed(const Duration(milliseconds: 1600), () {
          if (!mounted) return;
          if (navigator.canPop()) {
            navigator.pop();
            if (nav != null && nav['route'] != null) {
              final route = nav['route'] as String;
              router.push(route);
            }
          }
        });
      }
    });

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 16,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 24,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header with Language hint selector
          _buildHeader(voiceState),
          const SizedBox(height: 20),

          // Body based on state
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildStateContent(voiceState, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(VoiceState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 16,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'HomeStock Voice',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        // Language mode badge
        PopupMenuButton<String>(
          initialValue: state.languageHint,
          onSelected: (lang) {
            ref.read(voiceControllerProvider.notifier).setLanguageHint(lang);
          },
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outline),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.language,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  _getLangLabel(state.languageHint),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Icon(
                  Icons.arrow_drop_down,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
          itemBuilder: (ctx) => [
            const PopupMenuItem(
              value: 'auto',
              child: Text('Auto (English / தமிழ்)'),
            ),
            const PopupMenuItem(
              value: 'en',
              child: Text('English Only'),
            ),
            const PopupMenuItem(
              value: 'ta',
              child: Text('தமிழ் மட்டும்'),
            ),
          ],
        ),
      ],
    );
  }

  String _getLangLabel(String hint) {
    switch (hint) {
      case 'ta':
        return 'தமிழ்';
      case 'en':
        return 'English';
      default:
        return 'EN / தமிழ்';
    }
  }

  Widget _buildStateContent(VoiceState state, ThemeData theme) {
    switch (state.status) {
      case VoiceStatus.listening:
        return _buildListeningView(state);
      case VoiceStatus.processing:
        return _buildProcessingView('Transcribing speech with Whisper...');
      case VoiceStatus.executing:
        return _buildProcessingView('Executing action...');
      case VoiceStatus.parsed:
        return _buildParsedCommandView(state);
      case VoiceStatus.success:
        return _buildSuccessView(state);
      case VoiceStatus.error:
        return _buildErrorView(state);
      case VoiceStatus.idle:
        return _buildIdleView();
    }
  }

  Widget _buildListeningView(VoiceState state) {
    final seconds = state.recordingDuration.inSeconds;
    final durationStr = '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';

    return Column(
      key: const ValueKey('listening'),
      children: [
        const SizedBox(height: 12),
        // Pulsing Microphone Core
        Center(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              ref.read(voiceControllerProvider.notifier).stopRecordingAndProcess();
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer breathing glow rings
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final dynamicScale = 1.0 + (_pulseController.value * 0.25) + (state.amplitude * 0.2);
                    final opacity = (0.35 - (_pulseController.value * 0.2)).clamp(0.05, 0.4);
                    return Container(
                      width: 110 * dynamicScale,
                      height: 110 * dynamicScale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: opacity),
                      ),
                    );
                  },
                ),
                // Inner ring
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryLight, AppColors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mic,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Duration & Status text
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              durationStr,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        const Text(
          'Listening... Speak naturally in English, Tamil, or Tanglish',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 18),

        // Audio Waveform Visualizer
        _buildWaveformBars(state.amplitude),
        const SizedBox(height: 20),

        // Spoken prompt hints
        _buildPromptChips(),
        const SizedBox(height: 20),

        // Action Buttons: Done / Cancel
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  ref.read(voiceControllerProvider.notifier).cancelRecording();
                  Navigator.of(context).pop();
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  ref.read(voiceControllerProvider.notifier).stopRecordingAndProcess();
                },
                icon: const Icon(Icons.stop_circle_outlined),
                label: const Text('Done Speaking'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWaveformBars(double amplitude) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(15, (index) {
        final phase = (index - 7).abs() / 7.0;
        final barHeight = (8.0 + (amplitude * 32.0 * (1.0 - phase * 0.4))).clamp(4.0, 42.0);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 3.5,
          height: barHeight,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: (0.5 + (amplitude * 0.5)).clamp(0.0, 1.0)),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  Widget _buildPromptChips() {
    final hints = [
      'Add 2L oil to shopping list',
      'Rice 5 kg stock la irukku',
      'Milk 2 packets theerndhuduchu',
      'What is running low?',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: hints.map((h) {
        return InkWell(
          onTap: () {
            ref.read(voiceControllerProvider.notifier).parseTextCommand(h);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outline),
            ),
            child: Text(
              '"$h"',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProcessingView(String message) {
    return Column(
      key: const ValueKey('processing'),
      children: [
        const SizedBox(height: 32),
        const SizedBox(
          width: 56,
          height: 56,
          child: CircularProgressIndicator(
            strokeWidth: 3.5,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          message,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Processing multilingual natural speech...',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildParsedCommandView(VoiceState state) {
    final cmd = state.commandResult!;
    final entities = cmd.entities;

    return Column(
      key: const ValueKey('parsed'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Transcript Card with Edit Button
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'YOU SAID',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isEditingTranscript = !_isEditingTranscript;
                        _textEditingController.text = state.transcript;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        children: [
                          Icon(
                            _isEditingTranscript ? Icons.check : Icons.edit_outlined,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isEditingTranscript ? 'Done' : 'Edit',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (_isEditingTranscript)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textEditingController,
                        autofocus: true,
                        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                          border: UnderlineInputBorder(),
                        ),
                        onSubmitted: (val) {
                          setState(() => _isEditingTranscript = false);
                          ref.read(voiceControllerProvider.notifier).parseTextCommand(val);
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, size: 18, color: AppColors.primary),
                      onPressed: () {
                        setState(() => _isEditingTranscript = false);
                        ref.read(voiceControllerProvider.notifier).parseTextCommand(_textEditingController.text);
                      },
                    ),
                  ],
                )
              else
                Text(
                  '"${state.transcript}"',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Smart Action Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primaryContainer, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Intent Chip
              Row(
                children: [
                  _getIntentIcon(cmd.intent),
                  const SizedBox(width: 8),
                  Text(
                    cmd.intent.displayName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Message from parser
              Text(
                cmd.message,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),

              // Entity extraction summary if present
              if (entities != null && (entities.itemName != null || entities.quantity != null)) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      if (entities.quantity != null) ...[
                        Text(
                          '${entities.quantity} ${entities.unit ?? 'pcs'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('•', style: TextStyle(color: AppColors.textMuted)),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          entities.matchedInventoryItemName ?? entities.itemName ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Disambiguation Option Selector
              if (cmd.disambiguationOptions.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text(
                  'Choose an option:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                ...cmd.disambiguationOptions.map((opt) {
                  final isSelected = state.selectedOptionId == opt.id;
                  return InkWell(
                    onTap: () {
                      ref.read(voiceControllerProvider.notifier).selectOption(opt.id);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryContainer : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.outline,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            size: 16,
                            color: isSelected ? AppColors.primary : AppColors.textMuted,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  opt.label,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    fontSize: 13,
                                    color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                                  ),
                                ),
                                if (opt.subLabel != null)
                                  Text(
                                    opt.subLabel!,
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
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Action Buttons
        Row(
          children: [
            Expanded(
              flex: 2,
              child: OutlinedButton.icon(
                onPressed: () {
                  ref.read(voiceControllerProvider.notifier).startRecording();
                },
                icon: const Icon(Icons.mic, size: 18),
                label: const Text('Speak Again'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.heavyImpact();
                  ref.read(voiceControllerProvider.notifier).confirmAndExecute();
                },
                icon: const Icon(Icons.check_circle_outline, size: 20),
                label: const Text('Confirm Action'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _getIntentIcon(VoiceIntentType intent) {
    IconData icon;
    Color color;

    switch (intent) {
      case VoiceIntentType.addShoppingItem:
      case VoiceIntentType.getShoppingList:
      case VoiceIntentType.openShoppingList:
        icon = Icons.shopping_cart_outlined;
        color = const Color(0xFF10B981);
        break;
      case VoiceIntentType.removeShoppingItem:
        icon = Icons.remove_shopping_cart_outlined;
        color = Colors.redAccent;
        break;
      case VoiceIntentType.completeShoppingItem:
        icon = Icons.task_alt;
        color = Colors.green;
        break;
      case VoiceIntentType.stockIn:
        icon = Icons.add_circle_outline;
        color = AppColors.primary;
        break;
      case VoiceIntentType.stockOut:
        icon = Icons.remove_circle_outline;
        color = Colors.orange;
        break;
      case VoiceIntentType.updateStock:
        icon = Icons.tune;
        color = Colors.indigo;
        break;
      case VoiceIntentType.getLowStockItems:
        icon = Icons.warning_amber_rounded;
        color = Colors.amber.shade800;
        break;
      case VoiceIntentType.getExpiringItems:
        icon = Icons.hourglass_bottom;
        color = Colors.deepOrange;
        break;
      case VoiceIntentType.searchInventory:
      case VoiceIntentType.getItemStatus:
        icon = Icons.search;
        color = Colors.blue;
        break;
      default:
        icon = Icons.flash_on;
        color = AppColors.primary;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }

  Widget _buildSuccessView(VoiceState state) {
    final response = state.executionResponse;
    final message = response?.message ?? 'Command executed successfully!';

    return Column(
      key: const ValueKey('success'),
      children: [
        const SizedBox(height: 24),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.inStockBg,
            border: Border.all(color: AppColors.inStockBorder, width: 2),
          ),
          child: const Icon(
            Icons.check_rounded,
            color: AppColors.inStockText,
            size: 38,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Success!',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _buildErrorView(VoiceState state) {
    return Column(
      key: const ValueKey('error'),
      children: [
        const SizedBox(height: 16),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.outOfStockBg,
            border: Border.all(color: AppColors.outOfStockBorder),
          ),
          child: const Icon(
            Icons.error_outline,
            color: AppColors.outOfStockText,
            size: 32,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Could Not Complete Command',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          state.errorMessage ?? 'Something went wrong. Please try again.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  ref.read(voiceControllerProvider.notifier).reset();
                  Navigator.of(context).pop();
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Close'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(voiceControllerProvider.notifier).startRecording();
                },
                icon: const Icon(Icons.mic),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIdleView() {
    return Column(
      key: const ValueKey('idle'),
      children: [
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () {
            ref.read(voiceControllerProvider.notifier).startRecording();
          },
          icon: const Icon(Icons.mic),
          label: const Text('Start Speaking'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
