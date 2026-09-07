import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import 'voice_bottom_sheet.dart';

enum VoiceButtonVariant {
  iconOnly,
  floating,
  compactChip,
}

class VoiceInputButton extends StatelessWidget {
  final VoiceButtonVariant variant;
  final String? tooltip;
  final Color? color;
  final double size;

  const VoiceInputButton({
    super.key,
    this.variant = VoiceButtonVariant.iconOnly,
    this.tooltip = 'Speak voice command',
    this.color,
    this.size = 22.0,
  });

  const VoiceInputButton.floating({
    super.key,
    this.tooltip = 'Speak voice command',
    this.color,
    this.size = 26.0,
  }) : variant = VoiceButtonVariant.floating;

  const VoiceInputButton.compactChip({
    super.key,
    this.tooltip = 'Speak voice command',
    this.color,
    this.size = 18.0,
  }) : variant = VoiceButtonVariant.compactChip;

  void _onTap(BuildContext context) {
    HapticFeedback.lightImpact();
    VoiceBottomSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;

    switch (variant) {
      case VoiceButtonVariant.floating:
        return FloatingActionButton(
          heroTag: 'voice_fab_${DateTime.now().microsecondsSinceEpoch}',
          onPressed: () => _onTap(context),
          tooltip: tooltip,
          backgroundColor: effectiveColor,
          foregroundColor: Colors.white,
          elevation: 4,
          child: Icon(Icons.mic, size: size),
        );

      case VoiceButtonVariant.compactChip:
        return InkWell(
          onTap: () => _onTap(context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.mic, size: size, color: effectiveColor),
                const SizedBox(width: 4),
                Text(
                  'Voice',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: effectiveColor,
                  ),
                ),
              ],
            ),
          ),
        );

      case VoiceButtonVariant.iconOnly:
        return IconButton(
          icon: Icon(Icons.mic, size: size, color: effectiveColor),
          tooltip: tooltip,
          onPressed: () => _onTap(context),
        );
    }
  }
}
