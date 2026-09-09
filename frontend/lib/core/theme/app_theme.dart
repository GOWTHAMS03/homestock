import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

/// Custom theme extension holding HomeStock specific ambient colors.
/// Interpolates smoothly between the Online (Purple) and Offline (Red) palettes.
@immutable
class HomeStockThemeColors extends ThemeExtension<HomeStockThemeColors> {
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color secondary;
  final Color secondaryContainer;
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color outline;
  final Color outlineVariant;
  final Color headerGradientStart;
  final Color headerGradientEnd;
  final bool isOffline;

  const HomeStockThemeColors({
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.secondaryContainer,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.outline,
    required this.outlineVariant,
    required this.headerGradientStart,
    required this.headerGradientEnd,
    required this.isOffline,
  });

  /// Online Palette: Royal Amethyst Purple with Near-White
  static const online = HomeStockThemeColors(
    primary: AppColors.primary, // 0xFF7C3AED
    primaryLight: AppColors.primaryLight, // 0xFFA78BFA
    primaryDark: AppColors.primaryDark, // 0xFF5B21B6
    primaryContainer: AppColors.primaryContainer, // 0xFFF3E8FF
    onPrimaryContainer: AppColors.primaryDark,
    secondary: AppColors.secondary,
    secondaryContainer: AppColors.secondaryContainer,
    background: AppColors.background, // 0xFFFAF8FF
    surface: AppColors.surface, // 0xFFFFFFFF
    surfaceVariant: AppColors.surfaceVariant, // 0xFFF5F3FF
    outline: AppColors.outline, // 0xFFE9D5FF
    outlineVariant: AppColors.outlineVariant,
    headerGradientStart: AppColors.headerGradientStart, // 0xFFF3E8FF
    headerGradientEnd: AppColors.headerGradientEnd, // 0xFFFAF8FF
    isOffline: false,
  );

  /// Offline Palette: Warm Crimson Rose Red with Near-White
  static const offline = HomeStockThemeColors(
    primary: AppColors.offlinePrimary, // 0xFFE11D48
    primaryLight: AppColors.offlinePrimaryLight, // 0xFFFB7185
    primaryDark: AppColors.offlinePrimaryDark, // 0xFF9F1239
    primaryContainer: AppColors.offlinePrimaryContainer, // 0xFFFFE4E6
    onPrimaryContainer: AppColors.offlinePrimaryDark,
    secondary: AppColors.offlineSecondary, // 0xFFD97706
    secondaryContainer: AppColors.offlineSecondaryContainer, // 0xFFFEF3C7
    background: AppColors.offlineBackground, // 0xFFFFF9F9
    surface: AppColors.surface, // 0xFFFFFFFF
    surfaceVariant: AppColors.offlineSurfaceVariant, // 0xFFFFF1F2
    outline: AppColors.offlineOutline, // 0xFFFECDD3
    outlineVariant: AppColors.offlineOutlineVariant,
    headerGradientStart: AppColors.offlineHeaderGradientStart, // 0xFFFFE4E6
    headerGradientEnd: AppColors.offlineHeaderGradientEnd, // 0xFFFFF9F9
    isOffline: true,
  );

  @override
  HomeStockThemeColors copyWith({
    Color? primary,
    Color? primaryLight,
    Color? primaryDark,
    Color? primaryContainer,
    Color? onPrimaryContainer,
    Color? secondary,
    Color? secondaryContainer,
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? outline,
    Color? outlineVariant,
    Color? headerGradientStart,
    Color? headerGradientEnd,
    bool? isOffline,
  }) {
    return HomeStockThemeColors(
      primary: primary ?? this.primary,
      primaryLight: primaryLight ?? this.primaryLight,
      primaryDark: primaryDark ?? this.primaryDark,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      onPrimaryContainer: onPrimaryContainer ?? this.onPrimaryContainer,
      secondary: secondary ?? this.secondary,
      secondaryContainer: secondaryContainer ?? this.secondaryContainer,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      outline: outline ?? this.outline,
      outlineVariant: outlineVariant ?? this.outlineVariant,
      headerGradientStart: headerGradientStart ?? this.headerGradientStart,
      headerGradientEnd: headerGradientEnd ?? this.headerGradientEnd,
      isOffline: isOffline ?? this.isOffline,
    );
  }

  @override
  HomeStockThemeColors lerp(ThemeExtension<HomeStockThemeColors>? other, double t) {
    if (other is! HomeStockThemeColors) return this;
    return HomeStockThemeColors(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      primaryContainer: Color.lerp(primaryContainer, other.primaryContainer, t)!,
      onPrimaryContainer: Color.lerp(onPrimaryContainer, other.onPrimaryContainer, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      secondaryContainer: Color.lerp(secondaryContainer, other.secondaryContainer, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      headerGradientStart: Color.lerp(headerGradientStart, other.headerGradientStart, t)!,
      headerGradientEnd: Color.lerp(headerGradientEnd, other.headerGradientEnd, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      outlineVariant: Color.lerp(outlineVariant, other.outlineVariant, t)!,
      isOffline: t < 0.5 ? isOffline : other.isOffline,
    );
  }
}

extension BuildContextColors on BuildContext {
  /// Quick helper to access current ambient HomeStock colors from any widget.
  HomeStockThemeColors get hsColors =>
      Theme.of(this).extension<HomeStockThemeColors>() ??
      (Theme.of(this).colorScheme.primary == HomeStockThemeColors.offline.primary
          ? HomeStockThemeColors.offline
          : HomeStockThemeColors.online);
}

class AppTheme {
  AppTheme._();

  /// Online Theme: Royal Amethyst Purple with Near-White
  static ThemeData get onlineTheme => _buildTheme(colors: HomeStockThemeColors.online);

  /// Offline Theme: Warm Crimson Rose Red with Near-White
  static ThemeData get offlineTheme => _buildTheme(colors: HomeStockThemeColors.offline);

  /// Backward compatible default theme
  static ThemeData get lightTheme => onlineTheme;

  static ThemeData _buildTheme({required HomeStockThemeColors colors}) {
    TextTheme baseTextTheme;
    try {
      baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();
    } catch (_) {
      baseTextTheme = ThemeData.light().textTheme;
    }

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      extensions: [colors],
      colorScheme: ColorScheme.light(
        primary: colors.primary,
        onPrimary: Colors.white,
        primaryContainer: colors.primaryContainer,
        onPrimaryContainer: colors.onPrimaryContainer,
        secondary: colors.secondary,
        onSecondary: Colors.white,
        secondaryContainer: colors.secondaryContainer,
        surface: colors.surface,
        onSurface: AppColors.textPrimary,
        outline: colors.outline,
        outlineVariant: colors.outlineVariant,
      ),
      scaffoldBackgroundColor: colors.background,
      textTheme: baseTextTheme.copyWith(
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: AppColors.textPrimary,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          color: AppColors.textMuted,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: BorderSide(color: colors.outline, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: BorderSide(color: colors.outline),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: colors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: colors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.outOfStockText),
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.surface,
        selectedItemColor: colors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: colors.outline,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surface,
        side: BorderSide(color: colors.outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        contentTextStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }
}
