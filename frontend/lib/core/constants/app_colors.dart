import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary brand colors (Warm Indigo / Deep Slate)
  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF3730A3);
  static const Color primaryContainer = Color(0xFFEEF2FF);

  // Secondary brand colors (Teal / Sky Blue)
  static const Color secondary = Color(0xFF0284C7);
  static const Color secondaryLight = Color(0xFF38BDF8);
  static const Color secondaryDark = Color(0xFF0369A1);
  static const Color secondaryContainer = Color(0xFFE0F2FE);

  // Background & Surfaces
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color outline = Color(0xFFE2E8F0);
  static const Color outlineVariant = Color(0xFFCBD5E1);

  // Text colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);

  // Stock Status Colors
  static const Color inStockBg = Color(0xFFECFDF5);
  static const Color inStockText = Color(0xFF059669);
  static const Color inStockBorder = Color(0xFFA7F3D0);

  static const Color lowStockBg = Color(0xFFFFFBEB);
  static const Color lowStockText = Color(0xFFD97706);
  static const Color lowStockBorder = Color(0xFFFDE68A);

  static const Color outOfStockBg = Color(0xFFFEF2F2);
  static const Color outOfStockText = Color(0xFFDC2626);
  static const Color outOfStockBorder = Color(0xFFFECACA);

  // Expiry Colors
  static const Color expiringSoonBg = Color(0xFFFFF7ED);
  static const Color expiringSoonText = Color(0xFFEA580C);
  static const Color expiredBg = Color(0xFFFEF2F2);
  static const Color expiredText = Color(0xFFB91C1C);

  // Accent Colors for Categories
  static const List<Color> categoryAccents = [
    Color(0xFFF59E0B), // Amber
    Color(0xFF3B82F6), // Blue
    Color(0xFF10B981), // Emerald
    Color(0xFFEC4899), // Pink
    Color(0xFF8B5CF6), // Purple
    Color(0xFF06B6D4), // Cyan
    Color(0xFF64748B), // Slate
  ];

  // Shimmer & Skeleton Loaders
  static const Color shimmerBase = Color(0xFFE2E8F0);
  static const Color shimmerHighlight = Color(0xFFF8FAFC);

  // Subtle interactive states
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color cardBorderHover = Color(0xFFCBD5E1);
  static const Color chipBackground = Color(0xFFF1F5F9);

  // Modern HomeStock header & vibrant accent tokens
  static const Color headerGradientStart = Color(0xFFF3E8FF); // Soft pastel lavender
  static const Color headerGradientEnd = Color(0xFFF8FAFC);
  static const Color hsPurple = Color(0xFF8B5CF6);
  static const Color hsPurpleBg = Color(0xFFF5F3FF);
  static const Color hsPink = Color(0xFFEC4899);
  static const Color hsGreen = Color(0xFF10B981);
  static const Color hsGreenBg = Color(0xFFECFDF5);
  static const Color hsYellow = Color(0xFFF59E0B);
  static const Color hsYellowBg = Color(0xFFFEF3C7);
  static const Color darkFloatingPill = Color(0xFF1E293B);
}
