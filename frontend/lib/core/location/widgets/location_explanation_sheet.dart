import 'package:flutter/material.dart';
import '../../constants/app_spacing.dart';

/// Pre-permission explanation modal bottom sheet.
/// Explains why location is needed before prompting the operating system permission dialog.
class LocationExplanationSheet extends StatelessWidget {
  const LocationExplanationSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final textColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final cardBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Icon + Title Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFF10B981),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Find Better Deals Near You',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Compare local grocery shops with online prices',
                        style: TextStyle(
                          fontSize: 13,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Benefits Container
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
              ),
              child: Column(
                children: [
                  _buildBenefitRow(
                    icon: Icons.storefront_rounded,
                    title: 'Discover nearby grocery shops',
                    subtitle: 'Find verified physical stores around you',
                    textColor: titleColor,
                    subColor: textColor,
                  ),
                  const SizedBox(height: 12),
                  _buildBenefitRow(
                    icon: Icons.compare_arrows_rounded,
                    title: 'Compare local and online prices',
                    subtitle: 'Know whether physical shops or delivery apps save more',
                    textColor: titleColor,
                    subColor: textColor,
                  ),
                  const SizedBox(height: 12),
                  _buildBenefitRow(
                    icon: Icons.local_offer_outlined,
                    title: 'Show deals available in your area',
                    subtitle: 'Filter promotions and seasonal discounts by locality',
                    textColor: titleColor,
                    subColor: textColor,
                  ),
                  const SizedBox(height: 12),
                  _buildBenefitRow(
                    icon: Icons.near_me_outlined,
                    title: 'Estimate distance to shops',
                    subtitle: 'Factor in travel distance when calculating best basket',
                    textColor: titleColor,
                    subColor: textColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Privacy guarantee note
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, size: 18, color: Color(0xFF2563EB)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Privacy first: Your precise location is only used when needed and is never shared with room or family members.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Primary Action: [Use My Location]
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.my_location_rounded, size: 18),
              label: const Text(
                'Use My Location',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
            const SizedBox(height: 10),

            // Secondary Action: [Choose Location Manually]
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                side: BorderSide(color: cardBorder),
              ),
              child: Text(
                'Choose Location Manually',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF334155),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildBenefitRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color textColor,
    required Color subColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF10B981)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: subColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
