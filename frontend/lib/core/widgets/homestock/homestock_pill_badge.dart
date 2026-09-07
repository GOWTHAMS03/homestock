import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

enum HomeStockPillVariant {
  green,
  purple,
  yellow,
  pink,
  neutral,
}

class HomeStockPillBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final HomeStockPillVariant variant;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const HomeStockPillBadge({
    super.key,
    required this.label,
    this.icon,
    this.variant = HomeStockPillVariant.green,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Color border;

    switch (variant) {
      case HomeStockPillVariant.green:
        bg = AppColors.hsGreenBg;
        fg = AppColors.hsGreen;
        border = AppColors.hsGreen.withValues(alpha: 0.35);
        break;
      case HomeStockPillVariant.purple:
        bg = AppColors.hsPurpleBg;
        fg = AppColors.hsPurple;
        border = AppColors.hsPurple.withValues(alpha: 0.35);
        break;
      case HomeStockPillVariant.yellow:
        bg = AppColors.hsYellowBg;
        fg = AppColors.hsYellow;
        border = AppColors.hsYellow.withValues(alpha: 0.35);
        break;
      case HomeStockPillVariant.pink:
        bg = const Color(0xFFFDF2F8);
        fg = AppColors.hsPink;
        border = AppColors.hsPink.withValues(alpha: 0.35);
        break;
      case HomeStockPillVariant.neutral:
        bg = AppColors.surfaceVariant;
        fg = AppColors.textSecondary;
        border = AppColors.outline.withValues(alpha: 0.5);
        break;
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 1, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: fg,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
