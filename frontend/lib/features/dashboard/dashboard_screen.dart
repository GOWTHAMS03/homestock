import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/offline_wifi_badge.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../auth/auth_controller.dart';
import '../barcode/widgets/barcode_scanner_widget.dart';
import '../home_switcher/create_home_dialog.dart';
import '../home_switcher/home_controller.dart';
import '../home_switcher/join_home_dialog.dart';
import '../inventory/category_model.dart';
import '../inventory/inventory_controller.dart';
import '../inventory/inventory_model.dart';
import '../notifications/notification_controller.dart';
import '../shopping/shopping_controller.dart';
import '../voice/widgets/voice_input_button.dart';
import 'dashboard_controller.dart';
import 'dashboard_model.dart';
import 'what_do_i_need_sheet.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final homeState = ref.watch(homeControllerProvider);
    final dashboardState = ref.watch(dashboardControllerProvider);
    final notifState = ref.watch(notificationControllerProvider);

    final activeHome = homeState.activeHome;
    final summary = dashboardState.summary;

    // 1. Initial Home Loading State (only if no active home is cached yet)
    if (homeState.isLoading && activeHome == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F7F9),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text('HomeStock', style: TextStyle(fontWeight: FontWeight.w800)),
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
        backgroundColor: const Color(0xFFF6F7F9),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text('HomeStock', style: TextStyle(fontWeight: FontWeight.w800)),
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

    // 3. Main Modern Dashboard Content (Clean, Minimal, Non-disruptive)
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await ref.read(dashboardControllerProvider.notifier).loadDashboard();
                  await ref.read(inventoryControllerProvider.notifier).loadData();
                },
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // A. Lavender Header Area with Non-disruptive Offline Wifi Icon
                    _buildHeader(context, ref, activeHome, notifState.unreadCount, authState.user?.fullName),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppSpacing.md),

                          // B. Dual Status Promo Cards (Shopping & Pantry)
                          _buildDualPromoCards(context, ref, summary),

                          // C. Subtle Low-Stock Alert Banner (only shown when low stock exists)
                          _buildSpecialNoticeBanner(context, ref, summary),
                          const SizedBox(height: AppSpacing.lg),

                          // D. 3D-styled Categories Section
                          _buildCategoriesSection(context, ref),
                          const SizedBox(height: AppSpacing.xl),

                          // E. Daily Essentials / Pantry Products with Animated Smart Predict
                          _buildDailyEssentialsSection(context, ref, summary),
                          const SizedBox(height: AppSpacing.xxl),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Top header with lavender gradient, location dropdown, clean non-disruptive wifi badge & search pill
  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    dynamic activeHome,
    int unreadNotifications,
    String? fullName,
  ) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.headerGradientStart, AppColors.headerGradientEnd],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Status Headline, Home Switcher Dropdown, Offline Wifi Badge, Bell & Avatar
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Headline
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt_rounded, size: 24, color: AppColors.textPrimary),
                        SizedBox(width: 4),
                        Text(
                          'Home Stock Active',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),

                    // Location / Home Switcher Dropdown
                    InkWell(
                      onTap: () => _showHomeSwitcher(context, ref),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                'Home - ${activeHome?.name ?? "My Home"}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Simple non-disruptive Wi-Fi offline indicator
              const OfflineWifiBadge(),

              // Notification bell
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded, size: 24, color: AppColors.textPrimary),
                    tooltip: 'Notifications',
                    onPressed: () => context.push('/notifications'),
                  ),
                  if (unreadNotifications > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.outOfStockText,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '$unreadNotifications',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 4),

              // Circular User Avatar
              GestureDetector(
                onTap: () => context.go('/profile'),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFA855F7), Color(0xFF7C3AED)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.person_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Row 2: Modern Pill Search Bar (with embedded Barcode Scanner & Voice Input)
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.outline.withValues(alpha: 0.8)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => context.go('/inventory'),
                    child: Text(
                      'Search "Milk", "Tata Salt", "Atta"...',
                      style: TextStyle(
                        color: AppColors.textMuted.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Container(
                  height: 20,
                  width: 1,
                  color: AppColors.outline,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                ),
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 20, color: AppColors.primary),
                  tooltip: 'Scan Barcode',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () => BarcodeScannerWidget.open(context),
                ),
                const VoiceInputButton(
                  tooltip: 'Voice command',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Dual Quick Promo Cards side-by-side
  Widget _buildDualPromoCards(BuildContext context, WidgetRef ref, DashboardSummaryModel? summary) {
    final pendingShopping = summary?.pendingShoppingCount ?? 0;
    final totalInventory = summary?.totalInventoryItems ?? 0;

    return Row(
      children: [
        // Card 1: Purple-tinted Shopping List summary
        Expanded(
          child: InkWell(
            onTap: () => context.go('/shopping'),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDDD6FE)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF7C3AED), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pendingShopping > 0 ? '$pendingShopping TO BUY' : '0 PENDING',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF5B21B6),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 1),
                        const Text(
                          'Shopping List',
                          style: TextStyle(fontSize: 11, color: Color(0xFF7C3AED), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Card 2: Indigo-tinted Inventory count summary
        Expanded(
          child: InkWell(
            onTap: () => context.go('/inventory'),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFC7D2FE)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E7FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$totalInventory ITEMS',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryDark,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 1),
                        const Text(
                          'Pantry Stocked',
                          style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Minimal, non-intrusive alert banner (shown ONLY when items are running low)
  Widget _buildSpecialNoticeBanner(BuildContext context, WidgetRef ref, DashboardSummaryModel? summary) {
    final lowStock = summary?.lowStockCount ?? 0;
    if (lowStock == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: InkWell(
        onTap: () {
          ref.read(inventoryControllerProvider.notifier).setFilterType(InventoryFilterType.lowStock);
          context.go('/inventory');
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFDE68A), width: 0.9),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFD97706)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$lowStock item(s) running low in pantry • Tap to restock',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF92400E),
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFFD97706)),
            ],
          ),
        ),
      ),
    );
  }

  /// Categories Horizontal Scroll with rich 3D-styled badges
  Widget _buildCategoriesSection(BuildContext context, WidgetRef ref) {
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
        // Title Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pantry Categories',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Quick access to home supplies',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            InkWell(
              onTap: () {
                ref.read(inventoryControllerProvider.notifier).setFilterType(InventoryFilterType.all);
                context.go('/inventory');
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: Text(
                  'See All',
                  style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Horizontal 3D-style Category Pills
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length + 1,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              if (index == 0) {
                // Special Low Stock 3D Badge
                final theme = _getCategoryTheme('Low Stock');
                return _buildCategoryBadge(
                  icon: theme.icon,
                  label: 'Low Stock',
                  gradientColors: theme.gradientColors,
                  shadowColor: theme.shadowColor,
                  onTap: () {
                    ref.read(inventoryControllerProvider.notifier).setFilterType(InventoryFilterType.lowStock);
                    context.go('/inventory');
                  },
                );
              }

              final cat = categories[index - 1];
              final theme = _getCategoryTheme(cat.name);
              return _buildCategoryBadge(
                icon: theme.icon,
                label: cat.name,
                gradientColors: theme.gradientColors,
                shadowColor: theme.shadowColor,
                onTap: () {
                  ref.read(inventoryControllerProvider.notifier).selectCategory(cat.id);
                  context.go('/inventory');
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// 3D-styled Category Badge with vivid gradients, subtle inner highlight and soft glow
  Widget _buildCategoryBadge({
    required IconData icon,
    required String label,
    required List<Color> gradientColors,
    required Color shadowColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 1.2,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 7),
          SizedBox(
            width: 68,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Daily Essentials / Needs Attention Products with animated Smart Predict button
  Widget _buildDailyEssentialsSection(BuildContext context, WidgetRef ref, DashboardSummaryModel? summary) {
    final invState = ref.watch(inventoryControllerProvider);
    final items = invState.items.take(6).toList();

    if (items.isEmpty && (summary?.needsAttention.isEmpty ?? true)) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outline),
        ),
        child: const Center(
          child: Text(
            'No inventory items recorded yet.\nTap + Add Item in Inventory or scan a barcode!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Your Pantry Items',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.2),
            ),
            _AnimatedSmartPredictButton(
              onTap: () {
                ref.read(dashboardControllerProvider.notifier).loadRecommendations();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const WhatDoINeedSheet(),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // 2-Column Product Cards Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.84,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return _buildProductCard(context, ref, item, index);
          },
        ),
      ],
    );
  }

  /// Individual Product Card with subtle entrance micro-animation, title case, and animated button
  Widget _buildProductCard(BuildContext context, WidgetRef ref, InventoryItemModel item, int index) {
    final isLow = item.isLowStock;
    final isOut = item.isOutOfStock;
    final formattedName = _formatName(item.name);
    final productIcon = _getProductIcon(item.name, item.categoryName);
    final catTheme = _getCategoryTheme(item.categoryName);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 250 + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - value)),
            child: child,
          ),
        );
      },
      child: InkWell(
        onTap: () => context.push('/inventory/detail/${item.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outline.withValues(alpha: 0.75), width: 0.9),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Product Visual Container
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: catTheme.gradientColors.first.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: catTheme.gradientColors.first.withValues(alpha: 0.2),
                      width: 0.8,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      productIcon,
                      size: 38,
                      color: catTheme.gradientColors.last,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Item Name (Title Cased)
              Text(
                formattedName,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),

              // Unit / Quantity
              Text(
                '${item.quantity == item.quantity.roundToDouble() ? item.quantity.toInt() : item.quantity} ${item.unit} in pantry',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // Bottom Row: Status Pill + Animated Add Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Status Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: isOut
                          ? const Color(0xFFFFF1F2)
                          : (isLow ? const Color(0xFFFFFBEB) : const Color(0xFFECFDF5)),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isOut
                            ? const Color(0xFFFECDD3)
                            : (isLow ? const Color(0xFFFDE68A) : const Color(0xFFA7F3D0)),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isOut
                                ? const Color(0xFFE11D48)
                                : (isLow ? const Color(0xFFD97706) : const Color(0xFF10B981)),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isOut ? 'Out' : (isLow ? 'Low' : 'In Stock'),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: isOut
                                ? const Color(0xFFBE123C)
                                : (isLow ? const Color(0xFFB45309) : const Color(0xFF047857)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Animated Add Action Button
                  _AnimatedAddButton(
                    onTap: () async {
                      final success = await ref.read(shoppingControllerProvider.notifier).addItem(
                            inventoryItemId: item.id,
                            itemName: item.name,
                            quantity: 1.0,
                          );
                      if (context.mounted && success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added "$formattedName" to Shopping List'),
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatName(String raw) {
    if (raw.trim().isEmpty) return '';
    final words = raw.trim().split(RegExp(r'\s+'));
    return words.map((w) {
      if (w.isEmpty) return '';
      return '${w[0].toUpperCase()}${w.substring(1)}';
    }).join(' ');
  }

  IconData _getProductIcon(String name, String catName) {
    final lower = '$name $catName'.toLowerCase();
    if (lower.contains('rice') || lower.contains('grain') || lower.contains('biryani') || lower.contains('basmati')) {
      return Icons.rice_bowl_rounded;
    }
    if (lower.contains('milk') || lower.contains('dairy') || lower.contains('curd') || lower.contains('cheese')) {
      return Icons.local_drink_rounded;
    }
    if (lower.contains('oil') || lower.contains('ghee') || lower.contains('butter')) {
      return Icons.opacity_rounded;
    }
    if (lower.contains('bread') || lower.contains('biscuit') || lower.contains('snack') || lower.contains('cookie')) {
      return Icons.bakery_dining_rounded;
    }
    if (lower.contains('fruit') || lower.contains('apple') || lower.contains('banana') || lower.contains('mango')) {
      return Icons.apple_rounded;
    }
    if (lower.contains('vegetable') || lower.contains('tomato') || lower.contains('potato') || lower.contains('onion')) {
      return Icons.eco_rounded;
    }
    if (lower.contains('soap') || lower.contains('wash') || lower.contains('detergent') || lower.contains('clean')) {
      return Icons.cleaning_services_rounded;
    }
    if (lower.contains('shampoo') || lower.contains('paste') || lower.contains('cream') || lower.contains('lotion')) {
      return Icons.spa_rounded;
    }
    if (lower.contains('coffee') || lower.contains('tea')) {
      return Icons.coffee_rounded;
    }
    if (lower.contains('water') || lower.contains('juice') || lower.contains('soda')) {
      return Icons.water_drop_rounded;
    }
    return _getCategoryTheme(catName).icon;
  }

  _CategoryTheme _getCategoryTheme(String catName) {
    final lower = catName.toLowerCase();
    if (lower.contains('low') || lower.contains('stock') || lower.contains('alert')) {
      return const _CategoryTheme(
        icon: Icons.bolt_rounded,
        gradientColors: [Color(0xFFFF3366), Color(0xFFE11D48)],
        shadowColor: Color(0x40FF3366),
      );
    }
    if (lower.contains('kitchen') || lower.contains('cook') || lower.contains('dish')) {
      return const _CategoryTheme(
        icon: Icons.restaurant_rounded,
        gradientColors: [Color(0xFFFB923C), Color(0xFFEA580C)],
        shadowColor: Color(0x35FB923C),
      );
    }
    if (lower.contains('clean') || lower.contains('wash') || lower.contains('detergent')) {
      return const _CategoryTheme(
        icon: Icons.auto_awesome_rounded,
        gradientColors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
        shadowColor: Color(0x3538BDF8),
      );
    }
    if (lower.contains('bath') || lower.contains('toilet') || lower.contains('shower')) {
      return const _CategoryTheme(
        icon: Icons.bathtub_rounded,
        gradientColors: [Color(0xFF34D399), Color(0xFF059669)],
        shadowColor: Color(0x3534D399),
      );
    }
    if (lower.contains('person') || lower.contains('care') || lower.contains('beauty') || lower.contains('skin')) {
      return const _CategoryTheme(
        icon: Icons.spa_rounded,
        gradientColors: [Color(0xFFF472B6), Color(0xFFDB2777)],
        shadowColor: Color(0x35F472B6),
      );
    }
    if (lower.contains('pantr') || lower.contains('snack') || lower.contains('biscuit') || lower.contains('sweet')) {
      return const _CategoryTheme(
        icon: Icons.cookie_rounded,
        gradientColors: [Color(0xFFA78BFA), Color(0xFF7C3AED)],
        shadowColor: Color(0x35A78BFA),
      );
    }
    if (lower.contains('milk') || lower.contains('dair') || lower.contains('drink') || lower.contains('beverag')) {
      return const _CategoryTheme(
        icon: Icons.local_drink_rounded,
        gradientColors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
        shadowColor: Color(0x3560A5FA),
      );
    }
    if (lower.contains('oil') || lower.contains('ghee')) {
      return const _CategoryTheme(
        icon: Icons.opacity_rounded,
        gradientColors: [Color(0xFFFBBF24), Color(0xFFD97706)],
        shadowColor: Color(0x35FBBF24),
      );
    }
    if (lower.contains('spice') || lower.contains('grain') || lower.contains('rice') || lower.contains('flour')) {
      return const _CategoryTheme(
        icon: Icons.rice_bowl_rounded,
        gradientColors: [Color(0xFFF59E0B), Color(0xFFB45309)],
        shadowColor: Color(0x35F59E0B),
      );
    }
    return const _CategoryTheme(
      icon: Icons.inventory_2_rounded,
      gradientColors: [Color(0xFF818CF8), Color(0xFF4F46E5)],
      shadowColor: Color(0x35818CF8),
    );
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
                const Text('Switch Household', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

/// 3D Category Theme definition
class _CategoryTheme {
  final IconData icon;
  final List<Color> gradientColors;
  final Color shadowColor;

  const _CategoryTheme({
    required this.icon,
    required this.gradientColors,
    required this.shadowColor,
  });
}

/// Animated Smart Predict button with gently pulsing and rotating sparkle icon
class _AnimatedSmartPredictButton extends StatefulWidget {
  final VoidCallback onTap;

  const _AnimatedSmartPredictButton({required this.onTap});

  @override
  State<_AnimatedSmartPredictButton> createState() => _AnimatedSmartPredictButtonState();
}

class _AnimatedSmartPredictButtonState extends State<_AnimatedSmartPredictButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFC7D2FE), width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final scale = 1.0 + (_controller.value * 0.22);
                final rotation = (_controller.value - 0.5) * 0.3;
                return Transform.scale(
                  scale: scale,
                  child: Transform.rotate(
                    angle: rotation,
                    child: child,
                  ),
                );
              },
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 14,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 5),
            const Text(
              'Smart Predict',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated Plus Button with tactile spring feedback on tap
class _AnimatedAddButton extends StatefulWidget {
  final VoidCallback onTap;

  const _AnimatedAddButton({required this.onTap});

  @override
  State<_AnimatedAddButton> createState() => _AnimatedAddButtonState();
}

class _AnimatedAddButtonState extends State<_AnimatedAddButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFFDF2F8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFF472B6), width: 1.2),
          ),
          child: const Center(
            child: Icon(Icons.add_rounded, color: Color(0xFFDB2777), size: 19),
          ),
        ),
      ),
    );
  }
}
