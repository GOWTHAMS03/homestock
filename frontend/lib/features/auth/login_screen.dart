import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/theme/theme_provider.dart' show isOnlineProvider;
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/homestock/homestock_card.dart';
import '../../core/widgets/server_config_dialog.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'auth_controller.dart';
import 'widgets/invite_qr_scanner_dialog.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _inviteCodeController = TextEditingController();
  final _fullNameController = TextEditingController();
  bool _obscurePassword = true;
  int _selectedTab = 0; // 0: Account Login, 1: Join with Code / QR

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _inviteCodeController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authControllerProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );

    if (success && mounted) {
      context.go('/');
    }
  }

  Future<void> _scanQrCode() async {
    final scannedCode = await InviteQrScannerDialog.show(context);
    if (scannedCode != null && scannedCode.isNotEmpty && mounted) {
      setState(() {
        _inviteCodeController.text = scannedCode;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('Scanned code: $scannedCode'),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _submitInviteLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authControllerProvider.notifier).loginWithInviteCode(
          inviteCode: _inviteCodeController.text.trim(),
          fullName: _fullNameController.text.trim(),
        );

    if (success && mounted) {
      context.go('/');
    }
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      final googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
      final account = await googleSignIn.signIn();
      if (account == null) return; // User cancelled
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not retrieve Google ID token')),
          );
        }
        return;
      }
      final success = await ref.read(authControllerProvider.notifier).loginWithGoogle(
            idToken,
            email: account.email,
            displayName: account.displayName,
            avatarUrl: account.photoUrl,
          );
      if (success && mounted) {
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google sign-in error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isOnline = ref.watch(isOnlineProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.headerGradientStart, Color(0xFFF6F7F9)],
            begin: Alignment.topCenter,
            end: Alignment.center,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // App Icon & Brand Bubble
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.outline.withValues(alpha: 0.8)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.cottage_rounded,
                          size: 44,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const Text(
                      '⚡ Welcome to HomeStock',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Buy only what you need. Never run out of essentials.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    if (authState.isUserNotFound || authState.verificationNotice != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF87171)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 22),
                                SizedBox(width: 8),
                                Text(
                                  'Account Verification Notice',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF991B1B),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              authState.verificationNotice ??
                                  "We couldn't verify your HomeStock account.\n\nYour account may have been removed or your session is no longer valid.\n\nPlease sign in again to continue.",
                              style: const TextStyle(
                                color: Color(0xFF7F1D1D),
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ] else if (authState.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.outOfStockText, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                authState.errorMessage!,
                                style: const TextStyle(color: AppColors.outOfStockText, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Mode Switcher: Account Login vs Join with Code / QR
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: AppColors.outline.withValues(alpha: 0.8)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedTab = 0),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _selectedTab == 0 ? AppColors.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Account Login',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _selectedTab == 0 ? Colors.white : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedTab = 1),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _selectedTab == 1 ? AppColors.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.qr_code_scanner_rounded,
                                      size: 15,
                                      color: _selectedTab == 1 ? Colors.white : AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Join with Code / QR',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: _selectedTab == 1 ? Colors.white : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Input Form Card
                    HomeStockCard(
                      padding: const EdgeInsets.all(20),
                      child: _selectedTab == 0
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AppTextField(
                                  controller: _emailController,
                                  label: 'Email or Username',
                                  hint: 'you@example.com or username',
                                  prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                                  validator: (val) {
                                    if (_selectedTab == 0) {
                                      if (val == null || val.trim().isEmpty) return 'Enter your email or username';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppSpacing.lg),

                                AppTextField(
                                  controller: _passwordController,
                                  label: 'Password',
                                  hint: '••••••••',
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
                                    if (_selectedTab == 0 && (val == null || val.isEmpty)) {
                                      return 'Enter your password';
                                    }
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
                                        : const Text('Sign In', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),

                                const Row(
                                  children: [
                                    Expanded(child: Divider()),
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 12),
                                      child: Text(
                                        'OR',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textMuted,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ),
                                    Expanded(child: Divider()),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md),

                                SizedBox(
                                  height: 50,
                                  child: OutlinedButton(
                                    onPressed: authState.isLoading ? null : _handleGoogleSignIn,
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: AppColors.outline.withValues(alpha: 0.8)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                                      backgroundColor: Colors.white,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 20,
                                          height: 20,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color(0xFF4285F4),
                                          ),
                                          alignment: Alignment.center,
                                          child: const Text(
                                            'G',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        const Text(
                                          'Continue with Google',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // QR Scan Action Hero Card
                                InkWell(
                                  onTap: _scanQrCode,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryContainer.withValues(alpha: 0.7),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.qr_code_scanner_rounded,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        const Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Scan Household QR Code',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w800,
                                                  color: AppColors.primaryDark,
                                                ),
                                              ),
                                              SizedBox(height: 2),
                                              Text(
                                                'Scan camera over the room invite QR',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primary),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.lg),

                                const Row(
                                  children: [
                                    Expanded(child: Divider()),
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 12),
                                      child: Text(
                                        'OR ENTER INVITE CODE',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.8),
                                      ),
                                    ),
                                    Expanded(child: Divider()),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md),

                                // Household Invite Code Field
                                AppTextField(
                                  controller: _inviteCodeController,
                                  label: 'Household Invite Code',
                                  hint: 'e.g. 7KQ9P4M2',
                                  textCapitalization: TextCapitalization.characters,
                                  prefixIcon: const Icon(Icons.vpn_key_rounded, size: 20),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary, size: 22),
                                    tooltip: 'Scan QR Code',
                                    onPressed: _scanQrCode,
                                  ),
                                  validator: (val) {
                                    if (_selectedTab == 1 && (val == null || val.trim().isEmpty)) {
                                      return 'Enter your household invite code';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppSpacing.lg),

                                // Full Name Field
                                AppTextField(
                                  controller: _fullNameController,
                                  label: 'Your Name',
                                  hint: 'e.g. Gowtham',
                                  prefixIcon: const Icon(Icons.person_rounded, size: 20),
                                  validator: (val) {
                                    if (_selectedTab == 1 && (val == null || val.trim().isEmpty)) {
                                      return 'Enter your name';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppSpacing.xl),

                                // Join Button
                                SizedBox(
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: authState.isLoading ? null : _submitInviteLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                                      elevation: 2,
                                    ),
                                    child: authState.isLoading
                                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                        : const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.meeting_room_rounded, size: 20),
                                              SizedBox(width: 8),
                                              Text('Join & Enter Household', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                                            ],
                                          ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _selectedTab == 0 ? "Don't have an account? " : "Already have an account? ",
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (_selectedTab == 0) {
                              context.push('/register');
                            } else {
                              setState(() => _selectedTab = 0);
                            }
                          },
                          child: Text(
                            _selectedTab == 0 ? 'Create one' : 'Account Login',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Server Connection Configuration Pill
                    Center(
                      child: InkWell(
                        onTap: _showServerConfigDialog,
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(
                              color: isOnline
                                  ? const Color(0xFF10B981).withValues(alpha: 0.4)
                                  : const Color(0xFFF59E0B).withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isOnline ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  isOnline
                                      ? 'Connected: ${ApiEndpoints.baseUrl}'
                                      : 'Connecting / Offline: ${ApiEndpoints.baseUrl}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isOnline ? const Color(0xFF065F46) : const Color(0xFF92400E),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.settings_outlined, size: 12, color: AppColors.textMuted),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showServerConfigDialog() async {
    await showServerConfigDialog(context, ref);
    if (mounted) {
      setState(() {});
    }
  }
}
