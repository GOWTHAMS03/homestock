import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import 'smart_shopping_models.dart';

/// Modal bottom sheet allowing users to review and confirm ambiguous product matches.
class ProductMatchReviewSheet extends StatelessWidget {
  final String queryItemName;
  final ProductOfferModel offer;
  final ValueChanged<bool> onMatchDecision;

  const ProductMatchReviewSheet({
    super.key,
    required this.queryItemName,
    required this.offer,
    required this.onMatchDecision,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String queryItemName,
    required ProductOfferModel offer,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (_) => ProductMatchReviewSheet(
        queryItemName: queryItemName,
        offer: offer,
        onMatchDecision: (isMatch) => Navigator.of(context).pop(isMatch),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final confidencePct = ((offer.matchConfidence ?? 0.7) * 100).toInt();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Row(
            children: [
              Icon(Icons.help_outline_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Confirm Product Match',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'We found a similar product with $confidencePct% match confidence. Please verify if this matches your shopping item.',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),

          // Comparison box
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your List: ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Expanded(
                      child: Text(
                        queryItemName,
                        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Store Offer: ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Expanded(
                      child: Text(
                        offer.productName,
                        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
                if (offer.brand != null) ...[
                  const SizedBox(height: 4),
                  Text('Brand: ${offer.brand}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
                if (offer.packageSize != null) ...[
                  const SizedBox(height: 2),
                  Text('Size: ${offer.packageSize} ${offer.unit ?? ''}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
                const SizedBox(height: 6),
                Text(
                  'Price: ₹${offer.effectivePrice.toStringAsFixed(0)} on ${offer.provider}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => onMatchDecision(false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Not This Item', style: TextStyle(color: AppColors.textSecondary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => onMatchDecision(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Yes, Matches'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
