import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

class QuantityStepper extends StatelessWidget {
  final double value;
  final String unit;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final bool compact;

  const QuantityStepper({
    super.key,
    required this.value,
    required this.unit,
    required this.onIncrement,
    required this.onDecrement,
    this.compact = false,
  });

  String _formatValue(double val) {
    if (val == val.roundToDouble()) {
      return val.toInt().toString();
    }
    return val.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 16),
            onPressed: onDecrement,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.all(compact ? 4 : 8),
            constraints: const BoxConstraints(),
            color: AppColors.textPrimary,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '${_formatValue(value)} $unit',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: compact ? 12 : 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 16),
            onPressed: onIncrement,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.all(compact ? 4 : 8),
            constraints: const BoxConstraints(),
            color: AppColors.textPrimary,
          ),
        ],
      ),
    );
  }
}
