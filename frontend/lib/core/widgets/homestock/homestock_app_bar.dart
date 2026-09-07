import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';

/// Reusable HomeStock top AppBar featuring the signature quick-commerce aesthetic:
/// - Soft pastel lavender gradient header
/// - 38x38dp circular elevated back button
/// - High-contrast title and subtitle/status headline
/// - Actions aligned with clean spacing
class HomeStockAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final Widget? subtitleWidget;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBack;
  final bool useGradient;

  const HomeStockAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleWidget,
    this.actions,
    this.showBackButton = true,
    this.onBack,
    this.useGradient = true,
  });

  @override
  Size get preferredSize => Size.fromHeight(subtitle != null || subtitleWidget != null ? 70 : 58);

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return Container(
      decoration: BoxDecoration(
        color: useGradient ? null : Colors.white,
        gradient: useGradient
            ? const LinearGradient(
                colors: [AppColors.headerGradientStart, AppColors.headerGradientEnd],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : null,
        border: Border(
          bottom: BorderSide(
            color: AppColors.outline.withValues(alpha: 0.6),
            width: 0.8,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
          child: Row(
            children: [
              // Circular Back Button
              if (showBackButton && (canPop || onBack != null)) ...[
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onBack ?? () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.outline.withValues(alpha: 0.8)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        size: 24,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],

              // Title and optional subtitle
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ] else if (subtitleWidget != null) ...[
                      const SizedBox(height: 2),
                      subtitleWidget!,
                    ],
                  ],
                ),
              ),

              // Actions
              if (actions != null) ...actions!,
            ],
          ),
        ),
      ),
    );
  }
}
