import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../models/voice_models.dart';

class VoiceFeedbackWidget extends ConsumerWidget {
  final VoiceCommandResult result;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final ValueChanged<String>? onOptionSelected;

  const VoiceFeedbackWidget({
    super.key,
    required this.result,
    this.onConfirm,
    this.onCancel,
    this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final entities = result.entities;
    final isAmbiguous = result.disambiguationOptions.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: result.requiresConfirmation
              ? AppColors.lowStockText.withOpacity(0.5)
              : AppColors.primary.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Spoken language + Confidence badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  result.detectedLanguage,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.intent.displayName,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildConfidenceBadge(result.confidence),
            ],
          ),
          const SizedBox(height: 12),

          // Message / Question from Voice AI
          Text(
            result.message,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),

          if (entities != null && entities.itemName != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shopping_bag_outlined, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${entities.quantity != null ? '${entities.quantity} ' : ''}'
                      '${entities.unit != null ? '${entities.unit} ' : ''}'
                      '${entities.itemName}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Disambiguation candidates if any
          if (isAmbiguous) ...[
            const SizedBox(height: 12),
            Text(
              'Select the correct item:',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: result.disambiguationOptions.map((opt) {
                return ChoiceChip(
                  label: Text(opt.label),
                  selected: false,
                  onSelected: (_) {
                    if (onOptionSelected != null) {
                      onOptionSelected!(opt.id);
                    }
                  },
                );
              }).toList(),
            ),
          ],

          // Confirmation Buttons
          if (result.requiresConfirmation || result.needsQuantity) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onCancel != null)
                  TextButton(
                    onPressed: onCancel,
                    child: const Text('Cancel'),
                  ),
                const SizedBox(width: 8),
                if (onConfirm != null)
                  ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Confirm'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConfidenceBadge(double confidence) {
    final pct = (confidence * 100).toInt();
    final isHigh = confidence >= 0.90;
    final isMedium = confidence >= 0.75 && confidence < 0.90;

    final color = isHigh
        ? Colors.green
        : (isMedium ? Colors.orange : Colors.red);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$pct% confidence',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

