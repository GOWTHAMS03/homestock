import 'package:flutter/material.dart';
import '../location_state.dart';

/// Contextual, non-blocking notification banner rendering location warnings,
/// permission denial notices, and actionable recovery buttons.
class LocationStatusBanner extends StatelessWidget {
  final LocationState state;
  final VoidCallback onTryAgain;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenLocationSettings;
  final VoidCallback onChooseManually;

  const LocationStatusBanner({
    super.key,
    required this.state,
    required this.onTryAgain,
    required this.onOpenSettings,
    required this.onOpenLocationSettings,
    required this.onChooseManually,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Accuracy Warning
    if (state.accuracyWarning != null && state.status == LocationStateEnum.LOCATION_READY) {
      return _buildBanner(
        context: context,
        icon: Icons.gps_not_fixed_rounded,
        iconColor: const Color(0xFFD97706),
        bgColor: const Color(0xFFFFFBEB),
        borderColor: const Color(0xFFFDE68A),
        textColor: const Color(0xFF92400E),
        message: state.accuracyWarning!,
        primaryActionLabel: null,
        onPrimaryAction: null,
        secondaryActionLabel: null,
        onSecondaryAction: null,
      );
    }

    // 2. Services Disabled (GPS off)
    if (state.status == LocationStateEnum.LOCATION_SERVICES_DISABLED) {
      return _buildBanner(
        context: context,
        icon: Icons.location_off_rounded,
        iconColor: const Color(0xFFDC2626),
        bgColor: const Color(0xFFFEF2F2),
        borderColor: const Color(0xFFFECACA),
        textColor: const Color(0xFF991B1B),
        message: 'Location services are turned off.',
        primaryActionLabel: 'Turn On Location',
        onPrimaryAction: onOpenLocationSettings,
        secondaryActionLabel: 'Choose Manually',
        onSecondaryAction: onChooseManually,
      );
    }

    // 3. Permission Permanently Denied
    if (state.status == LocationStateEnum.LOCATION_PERMISSION_DENIED_FOREVER) {
      return _buildBanner(
        context: context,
        icon: Icons.settings_suggest_rounded,
        iconColor: const Color(0xFFD97706),
        bgColor: const Color(0xFFFFFBEB),
        borderColor: const Color(0xFFFDE68A),
        textColor: const Color(0xFF92400E),
        message: 'Location access is turned off. Enable from Settings to discover nearby shops.',
        primaryActionLabel: 'Open Settings',
        onPrimaryAction: onOpenSettings,
        secondaryActionLabel: 'Choose Manually',
        onSecondaryAction: onChooseManually,
      );
    }

    // 4. Permission Denied (Soft)
    if (state.status == LocationStateEnum.LOCATION_PERMISSION_DENIED) {
      return _buildBanner(
        context: context,
        icon: Icons.location_disabled_rounded,
        iconColor: const Color(0xFF4B5563),
        bgColor: const Color(0xFFF9FAFB),
        borderColor: const Color(0xFFE5E7EB),
        textColor: const Color(0xFF374151),
        message: 'Location permission is needed to find nearby shops and local deals.',
        primaryActionLabel: 'Try Again',
        onPrimaryAction: onTryAgain,
        secondaryActionLabel: 'Choose Location',
        onSecondaryAction: onChooseManually,
      );
    }

    // 5. Timeout
    if (state.status == LocationStateEnum.LOCATION_TIMEOUT) {
      return _buildBanner(
        context: context,
        icon: Icons.timer_outlined,
        iconColor: const Color(0xFFD97706),
        bgColor: const Color(0xFFFFFBEB),
        borderColor: const Color(0xFFFDE68A),
        textColor: const Color(0xFF92400E),
        message: "Couldn't get your current location.",
        primaryActionLabel: 'Try Again',
        onPrimaryAction: onTryAgain,
        secondaryActionLabel: 'Choose Location',
        onSecondaryAction: onChooseManually,
      );
    }

    // 6. Generic Error or Unavailable
    if (state.status == LocationStateEnum.LOCATION_ERROR ||
        state.status == LocationStateEnum.LOCATION_UNAVAILABLE) {
      return _buildBanner(
        context: context,
        icon: Icons.error_outline_rounded,
        iconColor: const Color(0xFFDC2626),
        bgColor: const Color(0xFFFEF2F2),
        borderColor: const Color(0xFFFECACA),
        textColor: const Color(0xFF991B1B),
        message: state.errorMessage ?? 'Unable to acquire current location.',
        primaryActionLabel: 'Try Again',
        onPrimaryAction: onTryAgain,
        secondaryActionLabel: 'Choose Location',
        onSecondaryAction: onChooseManually,
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildBanner({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
    required String message,
    String? primaryActionLabel,
    VoidCallback? onPrimaryAction,
    String? secondaryActionLabel,
    VoidCallback? onSecondaryAction,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          if (primaryActionLabel != null || secondaryActionLabel != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (secondaryActionLabel != null)
                  TextButton(
                    onPressed: onSecondaryAction,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(
                      secondaryActionLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                if (primaryActionLabel != null) ...[
                  const SizedBox(width: 6),
                  ElevatedButton(
                    onPressed: onPrimaryAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: iconColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      visualDensity: VisualDensity.compact,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      primaryActionLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

