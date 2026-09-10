import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary brand colors (Calm Purple Family)
  static const Color primary = Color(0xFF6C4AB6);
  static const Color primaryLight = Color(0xFF9F85E2);
  static const Color primaryDark = Color(0xFF523296);
  static const Color primaryContainer = Color(0xFFF3EFFF);
  static const Color onPrimaryContainer = Color(0xFF523296);

  // Subtle Status Accent Colors (Section 3)
  // ONLINE: Muted / warm red accent
  static const Color statusOnline = Color(0xFFC85C5C);
  // OFFLINE: Purple family
  static const Color statusOffline = Color(0xFF7653C6);

  // Offline backward-compatible tokens (Unified with Purple & Neutral, NOT an alarming red!)
  static const Color offlinePrimary = Color(0xFF7653C6);
  static const Color offlinePrimaryLight = Color(0xFF9F85E2);
  static const Color offlinePrimaryDark = Color(0xFF523296);
  static const Color offlinePrimaryContainer = Color(0xFFF3EFFF);

  // Secondary brand tokens (Muted Slate / Neutral)
  static const Color secondary = Color(0xFF64748B);
  static const Color secondaryLight = Color(0xFF94A3B8);
  static const Color secondaryDark = Color(0xFF334155);
  static const Color secondaryContainer = Color(0xFFF1F5F9);
  static const Color offlineSecondary = Color(0xFF64748B);
  static const Color offlineSecondaryContainer = Color(0xFFF1F5F9);

  // Background & Surfaces (Calm Soft Neutral)
  static const Color background = Color(0xFFFAF9FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFF8F8FA);
  static const Color surfaceVariant = Color(0xFFF4F4F7);
  static const Color outline = Color(0xFFE5E7EB);
  static const Color outlineVariant = Color(0xFFF1F2F4);
  static const Color borderLight = Color(0xFFE5E7EB);

  // Offline Background & Surfaces (Same calm neutral baseline)
  static const Color offlineBackground = Color(0xFFFAF9FC);
  static const Color offlineSurfaceVariant = Color(0xFFF4F4F7);
  static const Color offlineOutline = Color(0xFFE5E7EB);
  static const Color offlineOutlineVariant = Color(0xFFF1F2F4);

  // Text colors (Readable Dark Neutral & Muted Slate)
  static const Color textPrimary = Color(0xFF1E1E24);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // Stock Status Colors (Subtle & Quiet, not alarming or shouting)
  static const Color inStockBg = Color(0xFFF0FDF4);
  static const Color inStockText = Color(0xFF059669);
  static const Color inStockBorder = Color(0xFFDCFCE7);

  static const Color lowStockBg = Color(0xFFFFFBEB);
  static const Color lowStockText = Color(0xFFB45309);
  static const Color lowStockBorder = Color(0xFFFEF3C7);

  static const Color outOfStockBg = Color(0xFFFEF2F2);
  static const Color outOfStockText = Color(0xFFC85C5C);
  static const Color outOfStockBorder = Color(0xFFFEE2E2);

  // Expiry Colors (Muted)
  static const Color expiringSoonBg = Color(0xFFFFF7ED);
  static const Color expiringSoonText = Color(0xFFC2410C);
  static const Color expiringSoonBorder = Color(0xFFFFEDD5);
  static const Color expiredBg = Color(0xFFFEF2F2);
  static const Color expiredText = Color(0xFFC85C5C);
  static const Color expiredBorder = Color(0xFFFEE2E2);

  // Unified Category Accents (Calm Neutral / Subtle Slate, no rainbow UI)
  static const List<Color> categoryAccents = [
    Color(0xFF64748B), // Slate
    Color(0xFF6C4AB6), // Subtle Purple
    Color(0xFF475569), // Dark Slate
    Color(0xFF523296), // Deep Purple
    Color(0xFF64748B), // Slate
    Color(0xFF7653C6), // Purple
    Color(0xFF334155), // Deep Slate
  ];

  // Shimmer & Skeleton Loaders
  static const Color shimmerBase = Color(0xFFE5E7EB);
  static const Color shimmerHighlight = Color(0xFFF8FAFC);

  // Subtle interactive states
  static const Color cardBorder = Color(0xFFE5E7EB);
  static const Color cardBorderHover = Color(0xFFCBD5E1);
  static const Color chipBackground = Color(0xFFF4F4F7);

  // Replaced gradients with clean solid surfaces
  static const Color headerGradientStart = Color(0xFFFFFFFF);
  static const Color headerGradientEnd = Color(0xFFFFFFFF);
  static const Color offlineHeaderGradientStart = Color(0xFFFFFFFF);
  static const Color offlineHeaderGradientEnd = Color(0xFFFFFFFF);

  static const Color hsPurple = Color(0xFF6C4AB6);
  static const Color hsPurpleBg = Color(0xFFF3EFFF);
  static const Color hsPink = Color(0xFFC85C5C);
  static const Color hsGreen = Color(0xFF059669);
  static const Color hsGreenBg = Color(0xFFF0FDF4);
  static const Color hsYellow = Color(0xFFB45309);
  static const Color hsYellowBg = Color(0xFFFFFBEB);
  static const Color darkFloatingPill = Color(0xFF1E293B);
}
