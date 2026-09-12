import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/homestock/homestock_app_bar.dart';
import '../../core/widgets/homestock/homestock_card.dart';
import 'auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authControllerProvider.notifier).register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _nameController.text.trim(),
          username: _usernameController.text.trim().isEmpty ? null : _usernameController.text.trim(),
          confirmPassword: _confirmPasswordController.text,
          phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        );

    if (success && mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: const HomeStockAppBar(
        title: 'Create Account',
        subtitle: 'New household member profile',
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '⚡ Get started with HomeStock',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Manage your household inventory and shared shopping lists seamlessly.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  if (authState.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Text(
                        authState.errorMessage!,
                        style: const TextStyle(color: AppColors.outOfStockText, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  HomeStockCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppTextField(
                          controller: _nameController,
                          label: 'Full Name',
                          hint: 'e.g. Gowtham Sekar',
                          prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Enter your name';
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),

                        AppTextField(
                          controller: _usernameController,
                          label: 'Username (Optional)',
                          hint: 'e.g. gowtham03',
                          prefixIcon: const Icon(Icons.alternate_email_rounded, size: 20),
                          validator: (val) {
                            if (val != null && val.trim().isNotEmpty && val.trim().length < 3) {
                              return 'Username must be at least 3 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),

                        AppTextField(
                          controller: _emailController,
                          label: 'Email Address',
                          hint: 'you@example.com',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Enter your email';
                            if (!val.contains('@')) return 'Enter a valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),

                        AppTextField(
                          controller: _phoneController,
                          label: 'Phone Number (Optional)',
                          hint: '+91 98765 43210',
                          keyboardType: TextInputType.phone,
                          prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        AppTextField(
                          controller: _passwordController,
                          label: 'Password',
                          hint: 'At least 6 characters',
                          obscureText: _obscurePassword,
                          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 20,
                              color: AppColors.textMuted,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          validator: (val) {
                            if (val == null || val.length < 6) return 'Password must be at least 6 characters';
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),

                        AppTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirm Password',
                          hint: 'Repeat your password',
                          obscureText: _obscureConfirmPassword,
                          prefixIcon: const Icon(Icons.lock_clock_outlined, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 20,
                              color: AppColors.textMuted,
                            ),
                            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Please confirm your password';
                            if (val != _passwordController.text) return 'Passwords do not match';
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: authState.isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                              elevation: 2,
                            ),
                            child: authState.isLoading
                                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Create Account', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account? ', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: const Text(
                          'Sign In',
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
