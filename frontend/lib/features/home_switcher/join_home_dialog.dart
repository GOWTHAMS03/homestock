import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import 'home_controller.dart';

class JoinHomeDialog extends ConsumerStatefulWidget {
  const JoinHomeDialog({super.key});

  @override
  ConsumerState<JoinHomeDialog> createState() => _JoinHomeDialogState();
}

class _JoinHomeDialogState extends ConsumerState<JoinHomeDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final success = await ref
        .read(homeControllerProvider.notifier)
        .joinHome(_controller.text.trim());

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Join Existing Home',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Enter the 8-character invite code shared by your family member.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                controller: _controller,
                label: 'Invite Code',
                hint: 'e.g. 7KQ9P4M2',
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter invite code';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(
                    width: 120,
                    child: AppButton(
                      label: 'Join',
                      onPressed: _submit,
                      isLoading: _isLoading,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
