import 'package:flutter/material.dart';
import '../../constants/app_spacing.dart';
import '../location_state.dart';

/// Compact, production-grade location bar showing:
/// - 📍 Current location area or manual selection
/// - Clear source indicator ("Current location" vs "Selected location" vs "Updated X min ago")
/// - Subtle refresh button (↻) without full-screen blocking
/// - Change location button
/// - Radius selector (1 KM, 3 KM, 5 KM, 10 KM)
class LocationBarWidget extends StatelessWidget {
  final LocationState locationState;
  final double radiusKm;
  final ValueChanged<double>? onRadiusChanged;
  final VoidCallback onRefreshLocation;
  final VoidCallback onChangeLocation;
  final Widget? trailing;

  const LocationBarWidget({
    super.key,
    required this.locationState,
    this.radiusKm = 5.0,
    this.onRadiusChanged,
    required this.onRefreshLocation,
    required this.onChangeLocation,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final pillBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);

    final activeLoc = locationState.activeLocation;
    final isManual = activeLoc?.isManual ?? false;
    final displayLabel = activeLoc?.displayLabel ??
        (locationState.isLoading ? 'Finding your location...' : 'Select Location');
    final sourceLabel = activeLoc?.sourceLabel ??
        (locationState.isLoading ? 'Detecting GPS...' : '');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          // 1. Location Pill with Pin Icon, Label, and Source Tag
          Expanded(
            child: InkWell(
              onTap: onChangeLocation,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: pillBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Icon(
                      isManual
                          ? Icons.location_on_rounded
                          : Icons.my_location_rounded,
                      size: 16,
                      color: isManual
                          ? const Color(0xFFD97706)
                          : const Color(0xFF10B981),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            displayLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          if (sourceLabel.isNotEmpty)
                            Text(
                              sourceLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Change',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: theme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // 2. Subtle Refresh Location Button (↻)
          if (!isManual)
            IconButton(
              onPressed: locationState.isRefreshing ? null : onRefreshLocation,
              tooltip: locationState.isRefreshing
                  ? 'Updating location...'
                  : 'Refresh location',
              visualDensity: VisualDensity.compact,
              icon: locationState.isRefreshing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                      ),
                    )
                  : const Icon(
                      Icons.refresh_rounded,
                      size: 18,
                      color: Color(0xFF64748B),
                    ),
            ),

          // 3. Radius Selector
          if (onRadiusChanged != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: pillBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<double>(
                  value: radiusKm,
                  isDense: true,
                  icon: const Icon(Icons.arrow_drop_down_rounded, size: 18),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  items: const [
                    DropdownMenuItem(value: 1.0, child: Text('1 KM')),
                    DropdownMenuItem(value: 3.0, child: Text('3 KM')),
                    DropdownMenuItem(value: 5.0, child: Text('5 KM')),
                    DropdownMenuItem(value: 10.0, child: Text('10 KM')),
                    DropdownMenuItem(value: 20.0, child: Text('20 KM')),
                  ],
                  onChanged: (newRadius) {
                    if (newRadius != null) {
                      onRadiusChanged!(newRadius);
                    }
                  },
                ),
              ),
            ),
          ],

          // 4. Trailing Slot (e.g. List / Map view mode buttons)
          if (trailing != null) ...[
            const SizedBox(width: 6),
            trailing!,
          ],
        ],
      ),
    );
  }
}
