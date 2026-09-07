import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/widgets/sync_status_bar.dart';
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

    // 1. Initial Home Loading State
    if (homeState.isLoading || (dashboardState.isLoading && summary == null)) {
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

    // 3. Main Modern Dashboard Content
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: SafeArea(
        child: Column(
          children: [
            const SyncStatusBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await ref.read(dashboardControllerProvider.notifier).loadDashboard();
                  await ref.read(inventoryControllerProvider.notifier).loadData();
                },
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // A. Lavender Header Area
                    _buildHeader(context, ref, activeHome, notifState.unreadCount, authState.user?.fullName),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppSpacing.md),

                          // B. Dual Status Promo Cards
                          _buildDualPromoCards(context, ref, summary),
                          const SizedBox(height: AppSpacing.sm),

                          // C. Green Checkmark Pills Sub-row
                          _buildCheckmarkPillsRow(),
                          const SizedBox(height: AppSpacing.md),

                          // D. Highlight Banner
                          _buildSpecialNoticeBanner(context, ref, summary),
                          const SizedBox(height: AppSpacing.xl),

                          // E. Fresh Categories Section
                          _buildCategoriesSection(context, ref),
                          const SizedBox(height: AppSpacing.xl),

                          // F. Daily Essentials / Needs Attention Products
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

  /// Top header with lavender gradient, status headline, location dropdown & search pill
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
          colors: [
            Color(0xFFEDE9FE), // Soft pastel lavender
            Color(0xFFF5F3FF),
            Color(0xFFF6F7F9),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: ⚡ Status & Home Location Dropdown + Right Avatar/Actions
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ⚡ Bold Headline
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
        // Card 1: Purple-tinted "0 FEES" style card
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
                            fontSize: 14,
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

        // Card 2: Amber/Indigo-tinted "LOW PRICES" style card
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
                            fontSize: 14,
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

  /// Sub-row of green checkmarks
  Widget _buildCheckmarkPillsRow() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _CheckmarkBadge(label: 'Real-Time Sync'),
        _CheckmarkBadge(label: 'Family Shared'),
        _CheckmarkBadge(label: 'Low-Stock Alerts'),
      ],
    );
  }

  /// Yellow Highlight Notice Banner
  Widget _buildSpecialNoticeBanner(BuildContext context, WidgetRef ref, DashboardSummaryModel? summary) {
    final lowStock = summary?.lowStockCount ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.circle, size: 14, color: Color(0xFFF59E0B)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              lowStock > 0
                  ? 'ATTENTION: $lowStock ITEM(S) RUNNING LOW IN PANTRY'
                  : 'ALL HOUSEHOLD ITEMS AT OPTIMAL STOCK LEVELS',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Color(0xFF92400E),
                letterSpacing: 0.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.circle, size: 14, color: Color(0xFFF59E0B)),
        ],
      ),
    );
  }

  /// Categories Horizontal Scroll with badges
  Widget _buildCategoriesSection(BuildContext context, WidgetRef ref) {
    final invState = ref.watch(inventoryControllerProvider);
    final homeState = ref.watch(homeControllerProvider);
    final categories = invState.categories.isNotEmpty
        ? invState.categories
        : CategoryModel.defaultCategories(homeState.activeHome?.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'PANTRY ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF10B981),
                    letterSpacing: -0.4,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '@HOME',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: () {
                ref.read(inventoryControllerProvider.notifier).setFilterType(InventoryFilterType.all);
                context.go('/inventory');
              },
              child: const Text(
                'See All',
                style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        const Text(
          'Handpicked daily household essentials',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),

        // Horizontal Category Pills
        SizedBox(
          height: 86,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length + 1,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              if (index == 0) {
                // Special Low Stock Badge
                return _buildCategoryBadge(
                  icon: Icons.flash_on_rounded,
                  label: 'Low Stock',
                  iconColor: Colors.white,
                  bgColor: const Color(0xFFEC4899),
                  onTap: () {
                    ref.read(inventoryControllerProvider.notifier).setFilterType(InventoryFilterType.lowStock);
                    context.go('/inventory');
                  },
                );
              }

              final cat = categories[index - 1];
              return _buildCategoryBadge(
                icon: _getCategoryIcon(cat.name),
                label: cat.name,
                iconColor: AppColors.primary,
                bgColor: AppColors.primaryContainer,
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

  Widget _buildCategoryBadge({
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.outline.withValues(alpha: 0.6)),
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 64,
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

  /// Daily Essentials / Needs Attention Products with action button
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
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 13, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text(
                      'Smart Predict',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
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
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.82,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return _buildProductCard(context, ref, item);
          },
        ),
      ],
    );
  }

  /// Individual Product Card with high-res icon, green status pill & action button
  Widget _buildProductCard(BuildContext context, WidgetRef ref, InventoryItemModel item) {
    final isLow = item.isLowStock;
    final isOut = item.isOutOfStock;

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
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Image / Icon Area
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    _getCategoryIcon(item.categoryName),
                    size: 40,
                    color: isOut
                        ? AppColors.outOfStockText
                        : (isLow ? AppColors.lowStockText : AppColors.primary),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Item Name
            Text(
              item.name,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),

            // Package / Unit description
            Text(
              '${item.quantity == item.quantity.roundToDouble() ? item.quantity.toInt() : item.quantity} ${item.unit}',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),

            // Bottom Row: Green status pill + Action Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Green status pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.hsGreenBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.hsGreen.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    isOut ? 'Out of Stock' : (isLow ? 'Low Stock' : 'In Stock'),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.hsGreen,
                    ),
                  ),
                ),

                // Vibrant Action Button
                InkWell(
                  onTap: () async {
                    // Quick add to shopping list with feedback
                    final success = await ref.read(shoppingControllerProvider.notifier).addItem(
                          inventoryItemId: item.id,
                          itemName: item.name,
                          quantity: 1.0,
                        );
                    if (context.mounted && success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added "${item.name}" to Shopping List'),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFEC4899), width: 1.5),
                    ),
                    child: const Center(
                      child: Icon(Icons.add_rounded, color: Color(0xFFEC4899), size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String catName) {
    final lower = catName.toLowerCase();
    if (lower.contains('milk') || lower.contains('dair')) return Icons.local_drink_outlined;
    if (lower.contains('veg') || lower.contains('fruit')) return Icons.eco_outlined;
    if (lower.contains('oil') || lower.contains('ghee')) return Icons.opacity_outlined;
    if (lower.contains('spice') || lower.contains('salt')) return Icons.grain_outlined;
    if (lower.contains('snack') || lower.contains('biscuit')) return Icons.fastfood_outlined;
    if (lower.contains('beverag') || lower.contains('tea') || lower.contains('coffee')) return Icons.coffee_outlined;
    return Icons.inventory_2_outlined;
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

class _CheckmarkBadge extends StatelessWidget {
  final String label;

  const _CheckmarkBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.hsGreen),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
