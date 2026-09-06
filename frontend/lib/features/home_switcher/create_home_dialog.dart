import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import 'home_controller.dart';

class CreateHomeDialog extends ConsumerStatefulWidget {
  const CreateHomeDialog({super.key});

  @override
  ConsumerState<CreateHomeDialog> createState() => _CreateHomeDialogState();
}

class _CreateHomeDialogState extends ConsumerState<CreateHomeDialog> {
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
        .createHome(_controller.text.trim());

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
                'Create New Home',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Give your household a friendly name (e.g., My Home, Parents Home).',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                controller: _controller,
                label: 'Home Name',
                hint: 'e.g. Sekar Residence',
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter a home name';
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
                      label: 'Create',
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
