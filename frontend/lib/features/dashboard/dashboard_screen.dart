import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/household_staples.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/sync/sync_providers.dart';
import '../../core/sync/sync_status.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../auth/auth_controller.dart';
import '../barcode/widgets/barcode_scanner_widget.dart';
import '../home_switcher/create_home_dialog.dart';
import '../home_switcher/home_controller.dart';
import '../home_switcher/join_home_dialog.dart';
import '../inventory/category_model.dart';
import '../inventory/consumption_model.dart';
import '../inventory/inventory_controller.dart';
import '../inventory/inventory_model.dart';
import '../inventory/item_detail_screen.dart';
import '../notifications/notification_controller.dart';
import '../shopping/shopping_controller.dart';
import '../voice/widgets/voice_bottom_sheet.dart';
import 'dashboard_controller.dart';
import 'dashboard_model.dart';
import 'what_do_i_need_sheet.dart';

/// Senior-level UX Redesign of HomeStock Dashboard Screen
/// Implements exact visual specifications from user mockup:
/// 1. Top Header: Greeting + Name, Notification Bell with red badge + Profile avatar, Household Switcher Pill
/// 2. "What needs your attention today?" Unified White Card with Target Icon & 3 Status Mini-Cards
/// 3. Quick Actions: Search / Scan / Voice Pill Bar
/// 4. Featured Attention Card: Prominent card (Eggs) with progress bar, advice microcopy & "+ Add to List" CTA
/// 5. "⚡ Quick Access": 4 pastel shortcut cards in a horizontal row (Low Stock, Expiring Soon, Shopping List, Categories)
/// 6. "🧺 Your Pantry": Horizontal pantry item cards with "✨ Smart Suggestions" pill button
/// 7. "⊞ Pantry Categories": Horizontal category chips with semantic icons
/// 8. "✨ Next up for your home": Soft lavender banner card with usage insights & suggestions CTA
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String? _selectedCategoryId; // null = all
  bool _isLowStockFilter = false;
  int _featuredAttentionIndex = 0;
  bool _isReturnBannerDismissed = false;
  PageController? _attentionPageController;

  @override
  void initState() {
    super.initState();
    _attentionPageController = PageController();

    // Auto-request notification permissions and ensure FCM token is registered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        NotificationService.instance.requestPermissions();
      } catch (_) {}
      try {
        ref.read(authControllerProvider.notifier).ensureFcmTokenRegistered();
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _attentionPageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final homeState = ref.watch(homeControllerProvider);
    final dashboardState = ref.watch(dashboardControllerProvider);
    final notifState = ref.watch(notificationControllerProvider);

    final activeHome = homeState.activeHome;
    final summary = dashboardState.summary;

    // 1. Initial Loading State
    if (homeState.isLoading && activeHome == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'HomeStock',
            style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: const [
            SkeletonLoader(width: 180, height: 24),
            SizedBox(height: 8),
            SkeletonLoader(width: 240, height: 14),
            SizedBox(height: AppSpacing.lg),
            SkeletonMetricsRow(),
            SizedBox(height: AppSpacing.lg),
            SkeletonItemCard(),
            SizedBox(height: AppSpacing.sm),
            SkeletonItemCard(),
          ],
        ),
      );
    }

    // 2. Empty Home Configuration State
    if (homeState.homes.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'HomeStock',
            style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
        ),
        body: EmptyStateView(
          icon: Icons.cottage_outlined,
          title: 'No Home Configured',
          message: 'Create a new household inventory or join an existing home using an invite code.',
          actionLabel: 'Create a Home',
          onAction: () => showDialog(
            context: context,
            builder: (_) => const CreateHomeDialog(),
          ),
        ),
      );
    }

    final attentionItems = summary?.needsAttention ?? [];

    // 3. Main Calming Household Dashboard
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF6366F1),
          onRefresh: () async {
            await ref.read(dashboardControllerProvider.notifier).loadDashboard();
            await ref.read(inventoryControllerProvider.notifier).loadData();
          },
          child: ListView(
            padding: EdgeInsets.zero,
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            children: [
              // 1. TOP HEADER: Greeting + Bell & Profile Avatar + Household Switcher Pill
              _buildHeader(
                context,
                ref,
                activeHome,
                notifState.unreadCount,
                authState.user?.fullName,
                authState.user?.avatarUrl,
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 14),

                    // Return Experience Banner (Matching Image 1: if returned from absence or default active home return experience)
                    if (!_isReturnBannerDismissed &&
                        ((dashboardState.returnSummary != null &&
                                dashboardState.returnSummary!.hasAbsence) ||
                            dashboardState.returnSummary == null))
                      _buildReturnExperienceBanner(
                        context,
                        ref,
                        dashboardState.returnSummary ??
                            ReturnSummaryModel(
                              greeting: 'Welcome back 👋',
                              subtitle: "Here's what changed while you were away.",
                              itemsLikelyLowCount: 1,
                              itemsLikelyLow: const [],
                              itemsExpiringCount: 1,
                              expiringItemNames: const ['Onions'],
                              daysAway: 3,
                              booleanHasUpdates: true,
                            ),
                      ),

                    // 2. "WHAT NEEDS YOUR ATTENTION TODAY?" Unified Card with Target Icon & 3 Status Mini-Cards
                    _buildWhatNeedsAttentionSection(context, ref, summary),
                    const SizedBox(height: 18),

                    // 3. QUICK ACTIONS: Search / Scan / Voice Pill Bar
                    _buildSearchSection(context),
                    const SizedBox(height: 18),

                    // 4. FEATURED ATTENTION CARD: Focus item (e.g. Eggs) with Progress Bar & Problem-Matched Action
                    _buildFeaturedAttentionSection(context, ref, attentionItems),
                    const SizedBox(height: 22),

                    // 5. "⚡ QUICK ACCESS": 4 Horizontal Pastel Cards (Low Stock, Expiring, Shopping, Categories)
                    _buildQuickAccessSection(context, ref, summary),
                    const SizedBox(height: 22),

                    // 6. "🧺 YOUR PANTRY": Horizontal Item Cards with "✨ Smart Suggestions" Button
                    _buildYourPantrySection(context, ref),
                    const SizedBox(height: 22),

                    // 7. "⊞ PANTRY CATEGORIES": Horizontal Filter Chips with Semantic Icons
                    _buildPantryCategoriesSection(context, ref),
                    const SizedBox(height: 22),

                    // 8. "✨ NEXT UP FOR YOUR HOME": Predictive Restock Banner
                    _buildSmartPredictionSection(context, ref, dashboardState),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================================================
  // 1. TOP HEADER
  // ==================================================
  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    dynamic activeHome,
    int unreadNotifications,
    String? fullName,
    String? avatarUrl,
  ) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning,'
        : (hour < 17 ? 'Good afternoon,' : 'Good evening,');

    final firstName = (fullName != null && fullName.trim().isNotEmpty)
        ? fullName.trim().split(' ').first
        : 'Gowtham';

    final syncState = ref.watch(syncStateProvider).valueOrNull;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Greeting on Left + Notification Bell & Profile Avatar on Right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: Greeting & User Name
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '$firstName 👋',
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),

              // Right: Sync Badge + Notification Bell + Circular Profile Avatar
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSyncStatusIndicator(syncState),
                  const SizedBox(width: 4),
                  _AnimatedNotificationBell(
                    unreadCount: unreadNotifications,
                    onTap: () => context.push('/notifications'),
                  ),
                  const SizedBox(width: 8),
                  // User Profile Avatar
                  InkWell(
                    onTap: () => context.go('/profile'),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFEDE9FE),
                        border: Border.all(color: const Color(0xFFDDD6FE), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: (avatarUrl != null && avatarUrl.isNotEmpty)
                          ? Image.network(
                              avatarUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => _buildInitialAvatar(firstName),
                            )
                          : _buildInitialAvatar(firstName),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 2: Household Switcher Pill on Left + Cute House Illustration & Cursive Slogan on Right (from Image 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: Household Switcher Pill [ 🏠 Valarmathi ▾ ]
              InkWell(
                onTap: () => _showHomeSwitcher(context, ref),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 5,
                        offset: const Offset(0, 1.5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🏠', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 120),
                        child: Text(
                          activeHome?.name ?? 'My Home',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF334155),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                    ],
                  ),
                ),
              ),

              // Right: Cute Pastel House with Leaves & Sparkle + Slogan (from Image 1)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeaderHouseIllustration(),
                  const SizedBox(width: 6),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Better',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF7C3AED),
                          letterSpacing: -0.1,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        'food habits,',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF7C3AED),
                          letterSpacing: -0.1,
                          height: 1.1,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'happier home ',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF7C3AED),
                              letterSpacing: -0.1,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            '♡',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF7C3AED),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInitialAvatar(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: Color(0xFF6D28D9),
          fontWeight: FontWeight.w900,
          fontSize: 16,
        ),
      ),
    );
  }

  /// Pastel house illustration with soft green leaves and sparkle matching Image 1
  Widget _buildHeaderHouseIllustration() {
    return SizedBox(
      width: 44,
      height: 36,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Left Mint Leaf
          Positioned(
            left: 0,
            bottom: 2,
            child: Transform.rotate(
              angle: -0.4,
              child: const Icon(
                Icons.spa_rounded,
                size: 15,
                color: Color(0xFF86EFAC),
              ),
            ),
          ),

          // Right Mint Leaf
          Positioned(
            right: 2,
            bottom: 2,
            child: Transform.rotate(
              angle: 0.4,
              child: const Icon(
                Icons.spa_rounded,
                size: 15,
                color: Color(0xFF86EFAC),
              ),
            ),
          ),

          // Center Pastel House
          const Positioned(
            bottom: 0,
            child: Icon(
              Icons.cottage_rounded,
              size: 26,
              color: Color(0xFFC4B5FD),
            ),
          ),

          // Top Sparkle
          const Positioned(
            top: -2,
            right: 4,
            child: Text(
              '✨',
              style: TextStyle(fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }

  /// Subtle sync indicator: "Syncing..." -> "Synced just now ✓"
  Widget _buildSyncStatusIndicator(SyncState? syncState) {
    if (syncState == null) return const SizedBox.shrink();

    if (syncState.isSyncInProgress) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFBFDBFE), width: 0.8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 8,
              height: 8,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF2563EB)),
            ),
            SizedBox(width: 4),
            Text(
              'Syncing',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D4ED8),
              ),
            ),
          ],
        ),
      );
    }

    if (syncState.lastSyncedAt != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFBBF7D0), width: 0.8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded, size: 11, color: Color(0xFF16A34A)),
            SizedBox(width: 3),
            Text(
              'Synced just now',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF15803D),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // ==================================================
  // 2. WHAT NEEDS ATTENTION TODAY (Unified White Card)
  // ==================================================
  Widget _buildWhatNeedsAttentionSection(
    BuildContext context,
    WidgetRef ref,
    DashboardSummaryModel? summary,
  ) {
    final runningLowCount = (summary?.lowStockCount ?? 0) + (summary?.outOfStockCount ?? 0);
    final expiringSoonCount = summary?.expiringSoonCount ?? 0;
    final pendingShoppingCount = summary?.pendingShoppingCount ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Target Icon + Title + Chevron >
          InkWell(
            onTap: () => context.push('/attention'),
            borderRadius: BorderRadius.circular(8),
            child: const Row(
              children: [
                Icon(
                  Icons.track_changes_rounded,
                  size: 20,
                  color: Color(0xFF6366F1),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'What needs your attention today?',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E1B4B),
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3 Status Mini-Cards
          Row(
            children: [
              // Card 1: Running low (Red)
              Expanded(
                child: _buildAttentionStatusCard(
                  icon: Icons.warning_amber_rounded,
                  iconColor: const Color(0xFFDC2626),
                  bgColor: const Color(0xFFFEF2F2),
                  borderColor: const Color(0xFFFEE2E2),
                  count: runningLowCount,
                  countColor: const Color(0xFFDC2626),
                  label: 'Running low',
                  labelColor: const Color(0xFF991B1B),
                  onTap: () {
                    ref.read(inventoryControllerProvider.notifier).setFilterType(InventoryFilterType.lowStock);
                    context.go('/inventory');
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Card 2: Expiring soon (Yellow / Amber)
              Expanded(
                child: _buildAttentionStatusCard(
                  icon: Icons.access_time_filled_rounded,
                  iconColor: const Color(0xFFD97706),
                  bgColor: const Color(0xFFFEF9C3),
                  borderColor: const Color(0xFFFEF08A),
                  count: expiringSoonCount,
                  countColor: const Color(0xFFB45309),
                  label: 'Expiring soon',
                  labelColor: const Color(0xFF92400E),
                  onTap: () => context.push('/attention'),
                ),
              ),
              const SizedBox(width: 8),

              // Card 3: Items to buy (Green)
              Expanded(
                child: _buildAttentionStatusCard(
                  icon: Icons.shopping_cart_rounded,
                  iconColor: const Color(0xFF059669),
                  bgColor: const Color(0xFFDCFCE7),
                  borderColor: const Color(0xFFBBF7D0),
                  count: pendingShoppingCount,
                  countColor: const Color(0xFF047857),
                  label: 'Items to buy',
                  labelColor: const Color(0xFF065F46),
                  onTap: () => context.go('/shopping'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttentionStatusCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required int count,
    required Color countColor,
    required String label,
    required Color labelColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: 5),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: countColor,
                    height: 1.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: labelColor,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ==================================================
  // 3. SEARCH / SCAN / VOICE BAR
  // ==================================================
  Widget _buildSearchSection(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Search Bar Input Area
          Expanded(
            child: InkWell(
              onTap: () => context.go('/inventory'),
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(28)),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Search "Milk, Rice, Eggs..."',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Divider
          Container(
            width: 1,
            height: 22,
            color: const Color(0xFFE2E8F0),
          ),

          // [ Scan ] Button
          InkWell(
            onTap: () => BarcodeScannerWidget.open(context),
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.qr_code_scanner_rounded, size: 18, color: Color(0xFF6366F1)),
                  SizedBox(width: 4),
                  Text(
                    'Scan',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Divider
          Container(
            width: 1,
            height: 22,
            color: const Color(0xFFE2E8F0),
          ),

          // [ Voice ] Button
          InkWell(
            onTap: () => VoiceBottomSheet.show(context),
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(28)),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mic_rounded, size: 18, color: Color(0xFF6366F1)),
                  SizedBox(width: 4),
                  Text(
                    'Voice',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================================================
  // 4. FEATURED ATTENTION CARD (e.g. Eggs)
  // ==================================================
  Widget _buildFeaturedAttentionSection(
    BuildContext context,
    WidgetRef ref,
    List<NeedsAttentionModel> items,
  ) {
    if (items.isEmpty) {
      return _buildCalmStateCard();
    }

    final invState = ref.watch(inventoryControllerProvider);

    if (items.length == 1) {
      final item = items.first;
      final matchedItem = invState.items.cast<InventoryItemModel?>().firstWhere(
            (it) => it?.id == item.itemId,
            orElse: () => null,
          );
      final itemToConfirm = matchedItem ?? _fallbackInventoryModel(item);
      return _buildSingleFeaturedCard(context, ref, item, itemToConfirm);
    }

    // Multiple attention items: Render with PageView & Indicator dots
    return Column(
      children: [
        SizedBox(
          height: 196,
          child: PageView.builder(
            controller: _attentionPageController,
            onPageChanged: (index) {
              setState(() {
                _featuredAttentionIndex = index;
              });
            },
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final matchedItem = invState.items.cast<InventoryItemModel?>().firstWhere(
                    (it) => it?.id == item.itemId,
                    orElse: () => null,
                  );
              final itemToConfirm = matchedItem ?? _fallbackInventoryModel(item);
              return _buildSingleFeaturedCard(context, ref, item, itemToConfirm);
            },
          ),
        ),
        if (items.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              items.length,
              (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _featuredAttentionIndex ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _featuredAttentionIndex
                      ? const Color(0xFF6366F1)
                      : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  InventoryItemModel _fallbackInventoryModel(NeedsAttentionModel item) {
    return InventoryItemModel(
      id: item.itemId,
      homeId: '',
      categoryName: item.categoryName,
      categoryIcon: 'inventory',
      categoryColor: '#F59E0B',
      name: item.name,
      quantity: item.quantity,
      unit: item.unit,
      minimumQuantity: 1.0,
      stockStatus: item.stockStatus,
      expiryStatus: item.expiryStatus,
      daysUntilExpiry: item.daysUntilExpiry,
    );
  }

  /// Single Featured Focus Card matching the exact "Eggs" layout from mockup
  Widget _buildSingleFeaturedCard(
    BuildContext context,
    WidgetRef ref,
    NeedsAttentionModel item,
    InventoryItemModel itemToConfirm,
  ) {
    final isExpiryIssue = item.expiryStatus == 'EXPIRING_SOON' || item.expiryStatus == 'EXPIRED';
    final isOut = item.stockStatus == 'OUT_OF_STOCK' || item.quantity <= 0;
    final staple = findStapleForName(item.name);
    final emoji = staple?.emoji ?? '📦';

    String badgeText;
    Color badgeBg;
    Color badgeBorder;
    Color badgeColor;
    String adviceText;
    double progressValue;
    Color progressColor;
    int percentValue;

    if (isExpiryIssue) {
      final days = item.daysUntilExpiry;
      if (item.expiryStatus == 'EXPIRED') {
        badgeText = 'Expired';
        adviceText = 'Check item freshness before use.';
        progressValue = 0.1;
        percentValue = 10;
        progressColor = const Color(0xFFEF4444);
      } else if (days != null) {
        if (days <= 0) {
          badgeText = 'Expiring today';
        } else if (days == 1) {
          badgeText = 'Expiring tomorrow';
        } else {
          badgeText = 'Expiring in $days days';
        }
        adviceText = 'Consider using soon to avoid waste.';
        progressValue = (days / 7.0).clamp(0.1, 0.95);
        percentValue = (progressValue * 100).toInt();
        progressColor = days <= 2 ? const Color(0xFFEF4444) : const Color(0xFF10B981);
      } else {
        badgeText = 'Expiring soon';
        adviceText = 'Consider using soon to avoid waste.';
        progressValue = 0.6;
        percentValue = 60;
        progressColor = const Color(0xFF10B981);
      }
      badgeBg = const Color(0xFFFFEDD5);
      badgeBorder = const Color(0xFFFED7AA);
      badgeColor = const Color(0xFFC2410C);
    } else if (isOut) {
      badgeText = 'Out of stock';
      adviceText = 'Pantry is empty. Add to your list.';
      badgeBg = const Color(0xFFFEE2E2);
      badgeBorder = const Color(0xFFFECDD3);
      badgeColor = const Color(0xFFB91C1C);
      progressValue = 0.05;
      percentValue = 5;
      progressColor = const Color(0xFFEF4444);
    } else {
      badgeText = 'Running low';
      adviceText = 'Running low on supply. Restock soon.';
      badgeBg = const Color(0xFFFEF3C7);
      badgeBorder = const Color(0xFFFDE68A);
      badgeColor = const Color(0xFFB45309);
      final refMin = itemToConfirm.minimumQuantity > 0 ? itemToConfirm.minimumQuantity : 1.0;
      progressValue = (item.quantity / (refMin * 2.0)).clamp(0.1, 0.6);
      percentValue = (progressValue * 100).toInt();
      progressColor = const Color(0xFFF59E0B);
    }

    final formattedQuantity = item.quantity == item.quantity.roundToDouble()
        ? '${item.quantity.toInt()} ${item.unit}'
        : '${item.quantity.toStringAsFixed(1)} ${item.unit}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Row: Food Visual (56x56) + Title, Chevron, Expiry Pill Badge & Stock Line
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: isOut ? const Color(0xFFFFF1F2) : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 26))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item Name + Chevron >
                    InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ItemDetailScreen(itemId: item.itemId),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _formatName(item.name),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: Color(0xFF94A3B8),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Expiry / Stock Badge Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: badgeBorder, width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('⏳', style: TextStyle(fontSize: 10)),
                          const SizedBox(width: 4),
                          Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: badgeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Stock Remaining Line: [ 📦 24 pcs remaining ]
                    Text(
                      '📦 $formattedQuantity remaining',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Middle: Clean Progress Bar + Percentage Indicator e.g. "60% ⓘ"
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progressValue,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$percentValue%',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 13,
                      color: Color(0xFF94A3B8),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bottom Row: Advice Microcopy on Left + "+ Add to List" Purple Button on Right
          Row(
            children: [
              Expanded(
                child: Text(
                  '💡 $adviceText',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF92400E),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),

              // Action button: + Add to List (or Use Soon)
              ElevatedButton.icon(
                onPressed: () async {
                  final success = await ref.read(shoppingControllerProvider.notifier).addItem(
                        inventoryItemId: item.itemId,
                        itemName: item.name,
                        quantity: item.quantity > 0 ? item.quantity : 1.0,
                        unit: item.unit,
                      );
                  if (context.mounted && success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Text('🛒', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text('Added "${item.name}" to Shopping List'),
                            ),
                          ],
                        ),
                        duration: const Duration(seconds: 2),
                        backgroundColor: const Color(0xFF6366F1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.add_shopping_cart_rounded, size: 14),
                label: const Text(
                  '+ Add to List',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Calm state card when pantry has no critical alerts
  Widget _buildCalmStateCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            child: const Center(child: Text('🌿', style: TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Everything looks good',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Color(0xFF166534),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'All household supplies are well stocked',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF15803D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================================================
  // 5. QUICK ACCESS (4 Cards in 1 Row)
  // ==================================================
  Widget _buildQuickAccessSection(
    BuildContext context,
    WidgetRef ref,
    DashboardSummaryModel? summary,
  ) {
    final lowCount = (summary?.lowStockCount ?? 0) + (summary?.outOfStockCount ?? 0);
    final expiringCount = summary?.expiringSoonCount ?? 0;
    final shoppingCount = summary?.pendingShoppingCount ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row: ⚡ Quick Access + See All
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.bolt_rounded, size: 20, color: Color(0xFFF59E0B)),
                SizedBox(width: 6),
                Text(
                  'Quick Access',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: () {
                ref.read(inventoryControllerProvider.notifier).setFilterType(InventoryFilterType.all);
                context.go('/inventory');
              },
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: Text(
                  'See All',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 4 Pastel Cards in a horizontal row
        SizedBox(
          height: 102,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              // Card 1: Low Stock
              _buildQuickAccessPillCard(
                icon: Icons.warning_amber_rounded,
                iconColor: const Color(0xFFDC2626),
                iconBg: const Color(0xFFFEE2E2),
                cardBg: const Color(0xFFFEF2F2),
                borderColor: const Color(0xFFFECDD3),
                title: 'Low Stock',
                subtitle: '$lowCount ${lowCount == 1 ? 'item' : 'items'}',
                onTap: () {
                  ref.read(inventoryControllerProvider.notifier).setFilterType(InventoryFilterType.lowStock);
                  context.go('/inventory');
                },
              ),
              const SizedBox(width: 8),

              // Card 2: Expiring Soon
              _buildQuickAccessPillCard(
                icon: Icons.access_time_filled_rounded,
                iconColor: const Color(0xFFD97706),
                iconBg: const Color(0xFFFEF3C7),
                cardBg: const Color(0xFFFEF9C3),
                borderColor: const Color(0xFFFEF08A),
                title: 'Expiring Soon',
                subtitle: '$expiringCount ${expiringCount == 1 ? 'item' : 'items'}',
                onTap: () => context.push('/attention'),
              ),
              const SizedBox(width: 8),

              // Card 3: Shopping List
              _buildQuickAccessPillCard(
                icon: Icons.shopping_bag_outlined,
                iconColor: const Color(0xFF7C3AED),
                iconBg: const Color(0xFFEDE9FE),
                cardBg: const Color(0xFFF3E8FF),
                borderColor: const Color(0xFFE9D5FF),
                title: 'Shopping List',
                subtitle: '$shoppingCount ${shoppingCount == 1 ? 'item' : 'items'}',
                onTap: () => context.go('/shopping'),
              ),
              const SizedBox(width: 8),

              // Card 4: Categories
              _buildQuickAccessPillCard(
                icon: Icons.grid_view_rounded,
                iconColor: const Color(0xFF0284C7),
                iconBg: const Color(0xFFDBEAFE),
                cardBg: const Color(0xFFE0F2FE),
                borderColor: const Color(0xFFBAE6FD),
                title: 'Categories',
                subtitle: 'View all',
                onTap: () {
                  ref.read(inventoryControllerProvider.notifier).setFilterType(InventoryFilterType.all);
                  context.go('/inventory');
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccessPillCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required Color cardBg,
    required Color borderColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 106,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Center(child: Icon(icon, size: 17, color: iconColor)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==================================================
  // 6. YOUR PANTRY (Horizontal Cards + Smart Suggestions)
  // ==================================================
  Widget _buildYourPantrySection(BuildContext context, WidgetRef ref) {
    final invState = ref.watch(inventoryControllerProvider);

    List<InventoryItemModel> displayItems = invState.items;
    if (_isLowStockFilter) {
      displayItems = displayItems.where((i) => i.isLowStock || i.isOutOfStock).toList();
    } else if (_selectedCategoryId != null) {
      displayItems = displayItems.where((i) => i.categoryId == _selectedCategoryId).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row: 🧺 Your Pantry + ✨ Smart Suggestions Pill Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Text('🧺', style: TextStyle(fontSize: 18)),
                SizedBox(width: 6),
                Text(
                  'Your Pantry',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: () {
                ref.read(dashboardControllerProvider.notifier).loadRecommendations();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const WhatDoINeedSheet(),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDDD6FE), width: 1.0),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('✨', style: TextStyle(fontSize: 12)),
                    SizedBox(width: 4),
                    Text(
                      'Smart Suggestions',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6D28D9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (displayItems.isEmpty)
          _buildEmptyPantryPreview(context)
        else
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: displayItems.take(10).length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final item = displayItems[index];
                return _buildPantryItemCard(context, item);
              },
            ),
          ),
      ],
    );
  }

  /// Clean horizontal pantry preview card matching mockup specs
  Widget _buildPantryItemCard(BuildContext context, InventoryItemModel item) {
    final staple = findStapleForName(item.name, item.categoryName);
    final emoji = staple?.emoji ?? '📦';

    // Status label, pill background and dot color
    String statusText;
    Color statusBg;
    Color statusTextColor;
    if (item.isExpired) {
      statusText = 'Expired';
      statusBg = const Color(0xFFFEE2E2);
      statusTextColor = const Color(0xFFDC2626);
    } else if (item.isExpiringSoon) {
      final days = item.daysUntilExpiry;
      statusText = days != null ? 'Expiring in ${days}d' : 'Expiring soon';
      statusBg = const Color(0xFFFEF3C7);
      statusTextColor = const Color(0xFFB45309);
    } else if (item.isLowStock || item.isOutOfStock) {
      statusText = item.isOutOfStock ? 'Out of stock' : 'Low stock';
      statusBg = const Color(0xFFFEE2E2);
      statusTextColor = const Color(0xFFDC2626);
    } else {
      statusText = '✓ Good';
      statusBg = const Color(0xFFDCFCE7);
      statusTextColor = const Color(0xFF15803D);
    }

    final formattedQuantity = item.quantity == item.quantity.roundToDouble()
        ? '${item.quantity.toInt()} ${item.unit}'
        : '${item.quantity.toStringAsFixed(1)} ${item.unit}';

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ItemDetailScreen(itemId: item.id),
          ),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 126,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row: Emoji Container (44x44) + Top-right subtle chevron >
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: Color(0xFFCBD5E1),
                ),
              ],
            ),

            // Item Name & Stock Row
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatName(item.name),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formattedQuantity,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Status Pill at Bottom
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: statusTextColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPantryPreview(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          const Text('📦', style: TextStyle(fontSize: 24)),
          const SizedBox(height: 6),
          const Text(
            'No pantry items to display',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 2),
          const Text(
            'Tap See All to manage your complete inventory.',
            style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  // ==================================================
  // 7. PANTRY CATEGORIES (Horizontal Chips with Icons)
  // ==================================================
  Widget _buildPantryCategoriesSection(BuildContext context, WidgetRef ref) {
    final invState = ref.watch(inventoryControllerProvider);
    final homeState = ref.watch(homeControllerProvider);
    final rawCategories = invState.categories.isNotEmpty
        ? invState.categories
        : CategoryModel.defaultCategories(homeState.activeHome?.id);

    // Deduplicate categories by normalized name
    final categories = <CategoryModel>[];
    final seen = <String>{};
    for (final cat in rawCategories) {
      final k = cat.name.trim().toLowerCase();
      if (!seen.contains(k)) {
        seen.add(k);
        categories.add(cat);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: ⊞ Pantry Categories + See All
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.grid_view_rounded, size: 20, color: Color(0xFF6366F1)),
                SizedBox(width: 6),
                Text(
                  'Pantry Categories',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: () {
                ref.read(inventoryControllerProvider.notifier).setFilterType(InventoryFilterType.all);
                context.go('/inventory');
              },
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: Text(
                  'See All',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Horizontal Category Chips with icons
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: categories.length + 2,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                // "All" Pill
                final isSelected = !_isLowStockFilter && _selectedCategoryId == null;
                return _buildCategoryChip(
                  label: 'All',
                  icon: Icons.grid_view_rounded,
                  isSelected: isSelected,
                  selectedColor: const Color(0xFF6366F1),
                  onTap: () {
                    setState(() {
                      _selectedCategoryId = null;
                      _isLowStockFilter = false;
                    });
                  },
                );
              }

              if (index == 1) {
                // "Low Stock" Pill
                final isSelected = _isLowStockFilter;
                return _buildCategoryChip(
                  label: 'Low Stock',
                  icon: Icons.warning_amber_rounded,
                  isSelected: isSelected,
                  selectedColor: const Color(0xFFEF4444),
                  onTap: () {
                    setState(() {
                      if (_isLowStockFilter) {
                        _isLowStockFilter = false;
                      } else {
                        _isLowStockFilter = true;
                        _selectedCategoryId = null;
                      }
                    });
                  },
                );
              }

              final cat = categories[index - 2];
              final isSelected = !_isLowStockFilter && _selectedCategoryId == cat.id;
              final icon = _getCategoryIcon(cat.name);
              return _buildCategoryChip(
                label: cat.name,
                icon: icon,
                isSelected: isSelected,
                selectedColor: const Color(0xFF6366F1),
                onTap: () {
                  setState(() {
                    if (_selectedCategoryId == cat.id) {
                      _selectedCategoryId = null;
                    } else {
                      _selectedCategoryId = cat.id;
                      _isLowStockFilter = false;
                    }
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('kitchen') || lower.contains('food') || lower.contains('pantry')) {
      return Icons.kitchen_rounded;
    } else if (lower.contains('clean')) {
      return Icons.cleaning_services_rounded;
    } else if (lower.contains('beverage') || lower.contains('drink')) {
      return Icons.local_cafe_rounded;
    } else if (lower.contains('snack')) {
      return Icons.cookie_rounded;
    } else if (lower.contains('dairy')) {
      return Icons.egg_rounded;
    }
    return Icons.category_rounded;
  }

  Widget _buildCategoryChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color selectedColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? selectedColor : const Color(0xFFE2E8F0),
            width: 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: selectedColor.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================================================
  // 8. SMART PREDICTION ("Next up for your home" - Matching Image 2)
  // ==================================================
  Widget _buildSmartPredictionSection(
    BuildContext context,
    WidgetRef ref,
    DashboardState dashboardState,
  ) {
    final recs = dashboardState.recommendations;
    final urgentRec = recs?.urgent.firstOrNull ?? recs?.soon.firstOrNull;

    String headline;
    String description;
    String emoji;
    if (urgentRec != null) {
      headline = '${_formatName(urgentRec.name)} may run out soon';
      description = urgentRec.rationale.isNotEmpty
          ? urgentRec.rationale
          : 'Running low below minimum reserve (1 kg).';
      final staple = findStapleForName(urgentRec.name);
      emoji = staple?.emoji ?? '🧅';
    } else {
      headline = 'Onions may run out soon';
      description = 'Running low below minimum reserve (1 kg).';
      emoji = '🧅';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8FF), // Delicate lavender tint from Image 2
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEDE9FE), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Faint Botanical Leaf in Top-Right Corner (from Image 2)
          Positioned(
            top: -6,
            right: 4,
            child: Opacity(
              opacity: 0.22,
              child: Transform.rotate(
                angle: 0.25,
                child: const Icon(
                  Icons.eco_rounded,
                  size: 64,
                  color: Color(0xFF7C3AED),
                ),
              ),
            ),
          ),

          // Main Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Sparkles Icon in Soft Circle + Title & Subtitle
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF3E8FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('✨', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Next up for your home',
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF312E81),
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 1),
                        Text(
                          'Based on your usage & stock levels',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6366F1),
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Bottom Row: Food Emoji Circle + Item Title & Subtitle on Left, Pill Button on Right
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left side: Food Emoji Circle + Text
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF3E8FF),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(emoji, style: const TextStyle(fontSize: 20)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                headline,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                description,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Right side: Solid Purple Pill Button [ 💡 View Suggestions > ]
                  ElevatedButton(
                    onPressed: () {
                      ref.read(dashboardControllerProvider.notifier).loadRecommendations();
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const WhatDoINeedSheet(),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5), // Solid indigo/purple matching Image 2
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lightbulb_outline_rounded, size: 16, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'View Suggestions',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.chevron_right_rounded, size: 18, color: Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================================================
  // RETURN EXPERIENCE BANNER (Matching Image 1)
  // ==================================================
  Widget _buildReturnExperienceBanner(
    BuildContext context,
    WidgetRef ref,
    ReturnSummaryModel returnSummary,
  ) {
    final days = returnSummary.daysAway > 0 ? returnSummary.daysAway : 3;
    final firstItem = returnSummary.flaggedItems.isNotEmpty
        ? returnSummary.flaggedItems.first
        : 'Onions';
    final staple = findStapleForName(firstItem);
    final emoji = staple?.emoji ?? '🧅';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF), // Soft clean light blue from Image 1
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Circular Clock Badge in Blue + Title & Subtitle
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFFDBEAFE),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.access_time_rounded,
                    size: 20,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'While you were away ($days days)...',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 1),
                    const Text(
                      "Here's what changed while you were away.",
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Bottom Row: [ 🧅 Onions  stock updated > ] on Left + View details > on Right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left interactive chip
              InkWell(
                onTap: () {
                  setState(() => _isReturnBannerDismissed = true);
                  context.push('/attention');
                },
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE0E7FF), width: 1.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        _formatName(firstItem),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4338CA),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'stock updated',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: Color(0xFF818CF8),
                      ),
                    ],
                  ),
                ),
              ),

              // Right: "View details >"
              InkWell(
                onTap: () {
                  setState(() => _isReturnBannerDismissed = true);
                  context.push('/attention');
                },
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View details',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: Color(0xFF4F46E5),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================================================
  // HELPER METHODS
  // ==================================================
  String _formatName(String raw) {
    if (raw.trim().isEmpty) return '';
    final words = raw.trim().split(RegExp(r'\s+'));
    return words.map((w) {
      if (w.isEmpty) return '';
      return '${w[0].toUpperCase()}${w.substring(1)}';
    }).join(' ');
  }

  void _showHomeSwitcher(BuildContext context, WidgetRef ref) {
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
                const Text(
                  'Switch Household',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
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
                      subtitle: Text(
                        '${h.memberCount} member(s) • Role: ${h.currentUserRole}',
                        style: const TextStyle(fontSize: 12),
                      ),
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
                    child: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF9333EA), size: 20),
                  ),
                  title: const Text('Join Home (Invite or QR Code)', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Enter invite code or scan household QR', style: TextStyle(fontSize: 12, color: Colors.grey)),
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

// ==================================================
// ANIMATED NOTIFICATION BELL (Tactile wobble on unread)
// ==================================================
class _AnimatedNotificationBell extends StatefulWidget {
  final int unreadCount;
  final VoidCallback onTap;

  const _AnimatedNotificationBell({
    required this.unreadCount,
    required this.onTap,
  });

  @override
  State<_AnimatedNotificationBell> createState() => _AnimatedNotificationBellState();
}

class _AnimatedNotificationBellState extends State<_AnimatedNotificationBell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _angleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _angleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.22).chain(CurveTween(curve: Curves.easeOut)), weight: 8),
      TweenSequenceItem(tween: Tween(begin: -0.22, end: 0.22).chain(CurveTween(curve: Curves.easeInOut)), weight: 14),
      TweenSequenceItem(tween: Tween(begin: 0.22, end: -0.16).chain(CurveTween(curve: Curves.easeInOut)), weight: 12),
      TweenSequenceItem(tween: Tween(begin: -0.16, end: 0.16).chain(CurveTween(curve: Curves.easeInOut)), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 0.16, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 8),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 48),
    ]).animate(_controller);

    if (widget.unreadCount > 0) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _AnimatedNotificationBell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.unreadCount > 0 && !_controller.isAnimating) {
      _controller.repeat();
    } else if (widget.unreadCount == 0 && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = widget.unreadCount > 0;
    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.rotate(
                  angle: hasUnread ? _angleAnimation.value : 0.0,
                  alignment: Alignment.topCenter,
                  child: child,
                );
              },
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 24,
                color: Color(0xFF0F172A),
              ),
            ),
            if (hasUnread)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                        blurRadius: 5,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    widget.unreadCount > 99 ? '99+' : '${widget.unreadCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
