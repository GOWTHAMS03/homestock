import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../models/voice_models.dart';
import '../services/ai_voice_service.dart';

class VoiceFeedbackWidget extends ConsumerWidget {
  final VoiceCommandResult result;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final ValueChanged<num>? onQuantityChanged;
  final ValueChanged<String>? onOptionSelected;
  final bool isVoiceInteraction;

  const VoiceFeedbackWidget({
    super.key,
    required this.result,
    this.onConfirm,
    this.onCancel,
    this.onQuantityChanged,
    this.onOptionSelected,
    this.isVoiceInteraction = false,
  });

  void _showEditQuantityDialog(BuildContext context, QuantityConfirmationInfo info) {
    final textController = TextEditingController(
      text: info.requestedQuantity.toString(),
    );

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Edit Quantity'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Adjust quantity for ${info.productName}:'),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Quantity',
                suffixText: info.requestedUnit,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(textController.text.trim());
              if (val != null && val > 0) {
                Navigator.of(dialogCtx).pop();
                if (onQuantityChanged != null) {
                  onQuantityChanged!(val);
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityConfirmationCard(
    BuildContext context,
    ThemeData theme,
    QuantityConfirmationInfo info,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  info.promptTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: const Color(0xFF92400E),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFCD34D).withValues(alpha: 0.6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.promptCurrent,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF451A03),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  info.promptProjected,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF047857),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (info.warningReason != null) ...[
            const SizedBox(height: 8),
            Text(
              info.warningReason!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFFB45309),
                fontSize: 11,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (onCancel != null)
                TextButton(
                  onPressed: onCancel,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF78350F),
                  ),
                  child: const Text('Cancel'),
                ),
              const SizedBox(width: 6),
              OutlinedButton.icon(
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit quantity'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFB45309),
                  side: const BorderSide(color: Color(0xFFF59E0B)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                onPressed: () => _showEditQuantityDialog(context, info),
              ),
              const SizedBox(width: 6),
              if (onConfirm != null)
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Confirm'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: onConfirm,
                ),
            ],
          ),
        ],
      ),
    );
  }

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
              ? AppColors.lowStockText.withValues(alpha: 0.5)
              : AppColors.primary.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                  color: AppColors.primary.withValues(alpha: 0.1),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  result.message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.volume_up_rounded, size: 20, color: AppColors.primary),
                tooltip: 'Listen to Homie',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () {
                  ref.read(aiVoiceServiceProvider.notifier).play(
                        text: result.message,
                        language: result.detectedLanguage,
                        isVoiceInteraction: true,
                      );
                },
              ),
            ],
          ),

          // Quantity Confirmation Card (Household Sanity Safeguard)
          if (result.quantityConfirmation != null) ...[
            _buildQuantityConfirmationCard(context, theme, result.quantityConfirmation!),
          ] else if (entities != null && entities.itemName != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
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
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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

          // Standard Confirmation Buttons (only if not already handled by quantityConfirmation card)
          if (result.quantityConfirmation == null && (result.requiresConfirmation || result.needsQuantity)) ...[
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
        color: color.withValues(alpha: 0.1),
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

