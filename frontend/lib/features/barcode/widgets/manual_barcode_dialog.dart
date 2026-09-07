import 'package:flutter/material.dart';
import 'package:homestock/core/constants/app_colors.dart';
import 'package:homestock/core/constants/app_spacing.dart';

class ManualBarcodeDialog extends StatefulWidget {
  final ValueChanged<String> onBarcodeSubmitted;

  const ManualBarcodeDialog({
    super.key,
    required this.onBarcodeSubmitted,
  });

  static Future<void> show(BuildContext context, ValueChanged<String> onBarcodeSubmitted) {
    return showDialog(
      context: context,
      builder: (_) => ManualBarcodeDialog(onBarcodeSubmitted: onBarcodeSubmitted),
    );
  }

  @override
  State<ManualBarcodeDialog> createState() => _ManualBarcodeDialogState();
}

class _ManualBarcodeDialogState extends State<ManualBarcodeDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final barcode = _controller.text.trim();
      Navigator.of(context).pop();
      widget.onBarcodeSubmitted(barcode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
      title: const Row(
        children: [
          Icon(Icons.keyboard_rounded, color: AppColors.primary),
          SizedBox(width: 8),
          Text('Enter Barcode Manually', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the numbers printed below the product barcode (e.g. EAN-13, UPC):',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'e.g. 8901725181222',
                prefixIcon: const Icon(Icons.qr_code_rounded, color: AppColors.primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter a barcode number';
                }
                if (val.trim().length < 4) {
                  return 'Barcode is too short';
                }
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
          ),
          child: const Text('Lookup Product'),
        ),
      ],
    );
  }
}
