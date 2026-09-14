import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/sync/sync_providers.dart' show connectivityMonitorProvider;
import '../models/ai_voice_settings.dart';
import '../services/ai_voice_service.dart';

class AiVoiceResponseCard extends ConsumerStatefulWidget {
  final String text;
  final String? language;
  final bool isVoiceInteraction;
  final VoidCallback? onDismiss;
  final EdgeInsetsGeometry? margin;
  final DateTime? timestamp;

  const AiVoiceResponseCard({
    super.key,
    required this.text,
    this.language,
    this.isVoiceInteraction = false,
    this.onDismiss,
    this.margin,
    this.timestamp,
  });

  @override
  ConsumerState<AiVoiceResponseCard> createState() => _AiVoiceResponseCardState();
}

class _AiVoiceResponseCardState extends ConsumerState<AiVoiceResponseCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;
  late final DateTime _cardTime;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _cardTime = widget.timestamp ?? DateTime.now();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..repeat(reverse: true);

    // Automatically play female voice response for voice interactions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final settings = ref.read(aiVoiceSettingsProvider);

      if (widget.isVoiceInteraction && settings.autoPlayEnabled && !settings.isMuted) {
        ref.read(aiVoiceServiceProvider.notifier).play(
              text: widget.text,
              language: widget.language,
              isVoiceInteraction: true,
            );
      }
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  bool get _isLongText => widget.text.length > 160;

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inSeconds < 45) {
      return 'Just now';
    }
    return DateFormat('hh:mm a').format(time);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOnline = ref.watch(connectivityMonitorProvider).isOnline;
    final showVoiceControls = isOnline || widget.isVoiceInteraction;
    final playbackState = ref.watch(aiVoiceServiceProvider);
    final settings = ref.watch(aiVoiceSettingsProvider);

    final summary = AiVoiceService.getVoiceSummary(widget.text);
    final isThisCardSpeaking = playbackState.isSpeaking && playbackState.currentText == summary;
    final isThisCardLoading = playbackState.isLoading && playbackState.currentText == summary;

    return Container(
      margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isThisCardSpeaking
              ? AppColors.primary.withValues(alpha: 0.5)
              : const Color(0xFFE2E8F0),
          width: isThisCardSpeaking ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isThisCardSpeaking
                ? AppColors.primary.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: isThisCardSpeaking ? 18 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header: Homie AI Badge, Screen Time & Language Pill ───
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 12, top: 14, bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left: Assistant Icon & Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withValues(alpha: 0.75),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HomeStock AI',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          showVoiceControls ? 'Cute Female Voice' : 'Text Response',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: showVoiceControls ? AppColors.primary : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Right: Screen Time & Language Badges
                Row(
                  children: [
                    // Screen Time Chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.schedule_rounded, size: 11, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(_cardTime),
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Language Tag
                    if (widget.language != null && widget.language!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          widget.language!.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),

                    if (widget.onDismiss != null) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                        onPressed: widget.onDismiss,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ─── Main Text Response ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isLongText && !_isExpanded
                      ? '${widget.text.substring(0, 150)}...'
                      : widget.text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                    height: 1.45,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                if (_isLongText) ...[
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _isExpanded = !_isExpanded);
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isExpanded ? 'Read less' : 'Read more',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Icon(
                            _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ─── Voice Controls (ONLINE ONLY) / Clean Minimal Footer (OFFLINE) ───
          if (showVoiceControls)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(21)),
                border: Border(
                  top: BorderSide(color: Color(0xFFF1F5F9)),
                ),
              ),
              child: Row(
                children: [
                  // Speaking / Loading / Idle Indicator
                  if (isThisCardSpeaking) ...[
                    _buildSubtleWaveform(),
                    const SizedBox(width: 8),
                    const Text(
                      'Speaking cute voice...',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ] else if (isThisCardLoading) ...[
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Preparing voice...',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ] else ...[
                    Icon(
                      settings.isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                      size: 16,
                      color: const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      settings.isMuted ? 'Muted' : 'Female Voice',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Action Buttons: Play / Stop / Replay
                  if (isThisCardSpeaking) ...[
                    _buildControlButton(
                      icon: Icons.pause_rounded,
                      label: 'Stop',
                      color: const Color(0xFFE11D48),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        ref.read(aiVoiceServiceProvider.notifier).stop();
                      },
                    ),
                  ] else ...[
                    _buildControlButton(
                      icon: Icons.play_arrow_rounded,
                      label: 'Play',
                      color: AppColors.primary,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        ref.read(aiVoiceServiceProvider.notifier).play(
                              text: widget.text,
                              language: widget.language,
                              isVoiceInteraction: true,
                            );
                      },
                    ),
                    const SizedBox(width: 6),
                    _buildControlButton(
                      icon: Icons.replay_rounded,
                      label: 'Replay',
                      color: const Color(0xFF475569),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        ref.read(aiVoiceServiceProvider.notifier).play(
                              text: widget.text,
                              language: widget.language,
                              isVoiceInteraction: true,
                            );
                      },
                    ),
                  ],

                  // Mute Quick Toggle
                  IconButton(
                    icon: Icon(
                      settings.isMuted ? Icons.volume_off_rounded : Icons.volume_up_outlined,
                      size: 18,
                      color: settings.isMuted ? const Color(0xFFE11D48) : const Color(0xFF94A3B8),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    tooltip: settings.isMuted ? 'Unmute' : 'Mute',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      ref.read(aiVoiceSettingsProvider.notifier).toggleMute();
                    },
                  ),
                ],
              ),
            )
          else
            // OFFLINE MODE: Voice model is completely removed; only discreet clean note shown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(21)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off_rounded, size: 13, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 6),
                  Text(
                    'Offline — voice response available online',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtleWaveform() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        final val = _waveController.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBar(7 + (val * 8)),
            const SizedBox(width: 2.5),
            _buildBar(14 - (val * 7)),
            const SizedBox(width: 2.5),
            _buildBar(9 + (val * 7)),
            const SizedBox(width: 2.5),
            _buildBar(6 + (val * 6)),
          ],
        );
      },
    );
  }

  Widget _buildBar(double height) {
    return Container(
      width: 3,
      height: height.clamp(4.0, 18.0),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
  }
}
