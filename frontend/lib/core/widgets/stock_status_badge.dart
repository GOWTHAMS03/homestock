import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

enum StockStatusType { inStock, lowStock, outOfStock }

class StockStatusBadge extends StatelessWidget {
  final StockStatusType status;
  final bool compact;

  const StockStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  factory StockStatusBadge.fromString(String? statusStr, {bool compact = false}) {
    if (statusStr == 'OUT_OF_STOCK') {
      return StockStatusBadge(status: StockStatusType.outOfStock, compact: compact);
    } else if (statusStr == 'LOW_STOCK') {
      return StockStatusBadge(status: StockStatusType.lowStock, compact: compact);
    }
    return StockStatusBadge(status: StockStatusType.inStock, compact: compact);
  }

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    Color border;
    String label;
    IconData icon;

    switch (status) {
      case StockStatusType.outOfStock:
        bg = AppColors.outOfStockBg;
        text = AppColors.outOfStockText;
        border = AppColors.outOfStockBorder;
        label = 'Out of stock';
        icon = Icons.cancel_outlined;
        break;
      case StockStatusType.lowStock:
        bg = AppColors.lowStockBg;
        text = AppColors.lowStockText;
        border = AppColors.lowStockBorder;
        label = 'Low stock';
        icon = Icons.warning_amber_rounded;
        break;
      case StockStatusType.inStock:
        bg = AppColors.inStockBg;
        text = AppColors.inStockText;
        border = AppColors.inStockBorder;
        label = 'In stock';
        icon = Icons.check_circle_outline_rounded;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 11 : 13, color: text),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: text,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// A glanceable badge that communicates expiry urgency clearly.
class ExpiryUrgencyBadge extends StatelessWidget {
  final String? expiryDateStr;
  final bool compact;

  const ExpiryUrgencyBadge({
    super.key,
    required this.expiryDateStr,
    this.compact = true,
  });

  @override
  Widget build(BuildContext context) {
    if (expiryDateStr == null) return const SizedBox.shrink();

    final date = DateTime.tryParse(expiryDateStr!);
    if (date == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diffDays = target.difference(today).inDays;

    Color bg;
    Color text;
    Color border;
    String label;
    IconData icon;

    if (diffDays < 0) {
      bg = AppColors.expiredBg;
      text = AppColors.expiredText;
      border = AppColors.outOfStockBorder;
      label = diffDays == -1 ? 'Expired yesterday' : 'Expired ${-diffDays}d ago';
      icon = Icons.error_outline_rounded;
    } else if (diffDays == 0) {
      bg = AppColors.expiringSoonBg;
      text = AppColors.expiringSoonText;
      border = AppColors.lowStockBorder;
      label = 'Expires today';
      icon = Icons.access_time_filled_rounded;
    } else if (diffDays <= 3) {
      bg = AppColors.expiringSoonBg;
      text = AppColors.expiringSoonText;
      border = AppColors.lowStockBorder;
      label = 'Expires in ${diffDays}d';
      icon = Icons.access_time_rounded;
    } else if (diffDays <= 7) {
      bg = AppColors.lowStockBg;
      text = AppColors.lowStockText;
      border = AppColors.lowStockBorder;
      label = 'Expires in ${diffDays}d';
      icon = Icons.date_range_rounded;
    } else {
      return const SizedBox.shrink(); // Far in the future, don't clutter the card
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 10 : 12, color: text),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: text,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
