import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

/// Lightweight, layout-stable shimmer skeleton container.
/// Eliminates jarring full-screen loading spinners and prevents layout shift.
class SkeletonLoader extends StatefulWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final ShapeBorder? shape;

  const SkeletonLoader({
    super.key,
    this.width,
    this.height,
    this.borderRadius = AppSpacing.radiusSm,
    this.shape,
  });

  const SkeletonLoader.circular({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        borderRadius = 999.0,
        shape = const CircleBorder();

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: ShapeDecoration(
            color: Color.lerp(
              AppColors.shimmerBase,
              AppColors.shimmerHighlight,
              _animation.value,
            ),
            shape: widget.shape ??
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                ),
          ),
        );
      },
    );
  }
}

/// A pre-styled card placeholder for item lists.
class SkeletonItemCard extends StatelessWidget {
  const SkeletonItemCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            const SkeletonLoader(
              width: 44,
              height: 44,
              borderRadius: AppSpacing.radiusSm,
            ),
            const SizedBox(width: AppSpacing.md),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader(width: 140, height: 16),
                  SizedBox(height: 6),
                  SkeletonLoader(width: 80, height: 12),
                ],
              ),
            ),
            const SkeletonLoader(
              width: 60,
              height: 24,
              borderRadius: AppSpacing.radiusFull,
            ),
          ],
        ),
      ),
    );
  }
}

/// A placeholder grid of metric cards for the dashboard.
class SkeletonMetricsRow extends StatelessWidget {
  const SkeletonMetricsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (index) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index < 2 ? AppSpacing.sm : 0,
            ),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader.circular(size: 24),
                  SizedBox(height: 10),
                  SkeletonLoader(width: 40, height: 20),
                  SizedBox(height: 6),
                  SkeletonLoader(width: 60, height: 11),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
