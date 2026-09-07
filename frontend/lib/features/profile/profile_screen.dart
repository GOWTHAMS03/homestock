import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../auth/auth_controller.dart';
import '../home_switcher/create_home_dialog.dart';
import '../home_switcher/home_controller.dart';
import '../home_switcher/join_home_dialog.dart';
import '../home_switcher/members_screen.dart';
import '../purchase/purchases_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final homeState = ref.watch(homeControllerProvider);

    final user = authState.user;
    final activeHome = homeState.activeHome;
    final displayName = user?.fullName.isNotEmpty == true ? user!.fullName : 'Gowtham';
    final displayPhone = user?.phoneNumber ?? '+91 93455 33912';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          children: [
            // 1. Top Bar with Circular Back Button
            Row(
              children: [
                InkWell(
                  onTap: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      context.go('/');
                    }
                  },
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.outline.withValues(alpha: 0.8)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.chevron_left_rounded, size: 24, color: AppColors.textPrimary),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                const Text(
                  'Profile',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // 2. User Avatar & Info Row (HomeStock modern style)
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFA855F7), Color(0xFF7C3AED)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.person_rounded, color: Colors.white, size: 32),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        displayPhone,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // 3. Three-Card Quick Action Row (HomeStock quick grid)
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Icons.shopping_bag_outlined,
                    label: 'Your\nPurchases',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PurchasesScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Icons.people_outline_rounded,
                    label: 'Family\nMembers',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MembersScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Icons.favorite_border_rounded,
                    label: 'Shopping\nList',
                    onTap: () => context.go('/shopping'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // 4. Promo Banner (HomeStock sync banner)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outline.withValues(alpha: 0.7)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.settings_suggest_outlined, size: 22, color: AppColors.textPrimary),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Inventory Sync Active',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
                        ),
                        SizedBox(height: 1),
                        Text(
                          'Offline changes sync automatically online',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.hsGreen,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Live',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.hsPink),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // 5. Section: Household & Active Home
            const Text(
              'Household & Home',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.2),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outline.withValues(alpha: 0.8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _showHomeManager(context, ref),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.cottage_outlined, size: 22, color: AppColors.textPrimary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activeHome?.name ?? 'My Home',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
                              ),
                              Text(
                                '${homeState.homes.length} registered home(s) • ${activeHome?.currentUserRole ?? "Owner"}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          'Switch',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // 6. Section: Your Information (Grouped rounded card)
            const Text(
              'Your Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.2),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outline.withValues(alpha: 0.8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildListRow(
                    icon: Icons.currency_rupee_rounded,
                    title: 'Purchase History & Bills',
                    subtitle: 'All recorded grocery expenses',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PurchasesScreen()),
                    ),
                  ),
                  _buildDottedDivider(),
                  _buildListRow(
                    icon: Icons.favorite_border_rounded,
                    title: 'Shared Shopping List',
                    subtitle: 'Items to buy and price comparisons',
                    onTap: () => context.go('/shopping'),
                  ),
                  _buildDottedDivider(),
                  _buildListRow(
                    icon: Icons.people_outline_rounded,
                    title: 'Family Members & Roles',
                    subtitle: 'Manage household member permissions',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MembersScreen()),
                    ),
                  ),
                  if (activeHome != null) ...[
                    _buildDottedDivider(),
                    _buildListRow(
                      icon: Icons.vpn_key_outlined,
                      title: 'Home Invite Code',
                      subtitle: activeHome.inviteCode,
                      trailingWidget: InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: activeHome.inviteCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Invite code "${activeHome.inviteCode}" copied to clipboard!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Copy', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ),
                      ),
                    ),
                  ],
                  _buildDottedDivider(),
                  _buildListRow(
                    icon: Icons.notifications_none_rounded,
                    title: 'Alerts & Notifications',
                    subtitle: 'Low stock and expiry reminders',
                    onTap: () => context.push('/notifications'),
                  ),
                  _buildDottedDivider(),
                  _buildListRow(
                    icon: Icons.info_outline_rounded,
                    title: 'About HomeStock',
                    subtitle: 'Version 1.0.0 • Offline-First Engine',
                    onTap: () {},
                  ),
                  _buildDottedDivider(),
                  _buildListRow(
                    icon: Icons.logout_rounded,
                    title: 'Log Out',
                    subtitle: 'Sign out from this device',
                    titleColor: AppColors.outOfStockText,
                    iconColor: AppColors.outOfStockText,
                    onTap: () => _confirmSignOut(context, ref),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 26, color: AppColors.textPrimary),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListRow({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? titleColor,
    Color? iconColor,
    Widget? trailingWidget,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 22, color: iconColor ?? AppColors.textPrimary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: titleColor ?? AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              trailingWidget ?? const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDottedDivider() {
    return Divider(
      height: 1,
      thickness: 0.6,
      color: AppColors.outline.withValues(alpha: 0.6),
      indent: 16,
      endIndent: 16,
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out from HomeStock? Your offline data is safely stored.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.outOfStockText,
              foregroundColor: Colors.white,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(authControllerProvider.notifier).logout();
      if (context.mounted) context.go('/login');
    }
  }

  void _showHomeManager(BuildContext context, WidgetRef ref) {
    final homeState = ref.read(homeControllerProvider);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text('Household Manager', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.md),
                ...homeState.homes.map((h) => ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.cottage_rounded, color: AppColors.primary, size: 20),
                      ),
                      title: Text(h.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${h.memberCount} member(s) • Role: ${h.currentUserRole}', style: const TextStyle(fontSize: 12)),
                      trailing: h.id == homeState.activeHome?.id
                          ? const Icon(Icons.check_circle_rounded, color: AppColors.hsGreen)
                          : null,
                      onTap: () {
                        ref.read(homeControllerProvider.notifier).switchHome(h);
                        Navigator.pop(context);
                      },
                    )),
                const Divider(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add_home_rounded, color: AppColors.secondary, size: 20),
                  ),
                  title: const Text('Create New Home', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(context: context, builder: (_) => const CreateHomeDialog());
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.group_add_rounded, color: Color(0xFF9333EA), size: 20),
                  ),
                  title: const Text('Join Home with Invite Code', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(context: context, builder: (_) => const JoinHomeDialog());
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
