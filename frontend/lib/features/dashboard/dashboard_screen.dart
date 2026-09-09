import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/sync/sync_providers.dart';
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
import '../inventory/smart_confirmation_sheet.dart';
import '../notifications/notification_controller.dart';
import '../shopping/shopping_controller.dart';
import '../voice/widgets/voice_bottom_sheet.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/constants/household_staples.dart';
import 'dashboard_controller.dart';
import 'dashboard_model.dart';
import 'dashboard_svg_icons.dart';
import 'what_do_i_need_sheet.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String? _selectedCategoryId; // null = all
  bool _isLowStockFilter = false;

  @override
  Widget build(BuildContext context) {
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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

                          // 1. Return Experience Banner (if returning after an absence)
                          if (dashboardState.returnSummary != null && dashboardState.returnSummary!.hasAbsence)
                            _buildReturnExperienceBanner(context, ref, dashboardState.returnSummary!),

                          // 2. Dual Status Promo Cards (Shopping & Pantry)
                          _buildDualPromoCards(context, ref, summary),
                          const SizedBox(height: AppSpacing.md),


                          // 3. Smart Things Needing Attention Section (Actionable confirmations or "Everything looks good 🌿")
                          _buildThingsNeedingAttentionSection(context, ref, summary),

                          // 4. HomeStock Habit & Consumption Insights Card
                          if (dashboardState.homeInsight != null && dashboardState.homeInsight!.insights.isNotEmpty)
                            _buildHomeStockInsightCard(context, ref, dashboardState.homeInsight!),

                          const SizedBox(height: AppSpacing.lg),

                          // 5. 3D-styled Categories Section
                          _buildCategoriesSection(context, ref),
                          const SizedBox(height: AppSpacing.xl),

                          // 6. Daily Essentials / Pantry Products with Animated Smart Predict
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

  /// Top header with lavender gradient, readable greeting, animated bell, 3D avatar with health progress ring & interactive typewriter search bar
  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    dynamic activeHome,
    int unreadNotifications,
    String? fullName,
  ) {
    final hour = DateTime.now().hour;
    final (greeting, timeSvg) = hour < 12
        ? ('Good morning', DashboardSvgIcons.sunMorning)
        : (hour < 17
            ? ('Good afternoon', DashboardSvgIcons.sunAfternoon)
            : ('Good evening', DashboardSvgIcons.moonEvening));
    final firstName = (fullName != null && fullName.trim().isNotEmpty)
        ? fullName.trim().split(' ').first
        : 'There';
    final hsColors = context.hsColors;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [hsColors.headerGradientStart, hsColors.headerGradientEnd],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Greeting & Name, Location Dropdown Chip, Animated Bell & 3D Avatar
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sub-Greeting with Time-of-Day Animated SVG
                    Row(
                      children: [
                        SizedBox(
                          width: 15,
                          height: 15,
                          child: SvgPicture.string(timeSvg),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          greeting,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),

                    // Prominent Name + Animated SVG Waving Hand ("Say Hello")
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            firstName,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const _AnimatedWavingHandSvgWidget(),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // Modern Location / Home Switcher Chip with Home Cottage SVG
                    InkWell(
                      onTap: () => _showHomeSwitcher(context, ref),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.outline.withValues(alpha: 0.6), width: 0.8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 13,
                              height: 13,
                              child: SvgPicture.string(DashboardSvgIcons.homeCottage),
                            ),
                            const SizedBox(width: 5),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 130),
                              child: Text(
                                activeHome?.name ?? 'My Home',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Animated Notification Bell (wobbles like a real bell if unread)
              _AnimatedNotificationBell(
                unreadCount: unreadNotifications,
                onTap: () => context.push('/notifications'),
              ),
              const SizedBox(width: 8),

              // 3D Animated "Say Hello" Avatar with Inventory Health Progress Ring
              const _ProfileHealthAvatar(),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Row 2: Modern Interactive Search Bar with Typewriter Suggestion & Animated Icons
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.outline.withValues(alpha: 0.85)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.035),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Animated Search Icon with subtle breathing pulse
                const _AnimatedSearchIcon(),
                const SizedBox(width: 10),

                // Interactive Auto-Typing Suggestion (Typewriter effect)
                Expanded(
                  child: InkWell(
                    onTap: () => context.go('/inventory'),
                    child: const _AnimatedSearchTypewriter(),
                  ),
                ),

                Container(
                  height: 20,
                  width: 1,
                  color: AppColors.outline,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                ),

                // Animated SVG Barcode Scanner Icon with glowing laser scan line
                _AnimatedBarcodeIcon(
                  onTap: () => BarcodeScannerWidget.open(context),
                ),
                const SizedBox(width: 4),

                // Animated SVG Microphone Icon with pulsing soundwaves
                _AnimatedMicIcon(
                  onTap: () => VoiceBottomSheet.show(context),
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
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Center(
                      child: _AnimatedPromoCardSvg(
                        svgString: DashboardSvgIcons.shoppingBagCard,
                        animationType: _CardAnimationType.float,
                      ),
                    ),
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

        // Card 2: Indigo-tinted Inventory count summary with Animated SVG
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
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E7FF),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Center(
                      child: _AnimatedPromoCardSvg(
                        svgString: DashboardSvgIcons.pantryStockedCard,
                        animationType: _CardAnimationType.pulse,
                      ),
                    ),
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

  /// Return Experience Banner for users returning after an absence
  Widget _buildReturnExperienceBanner(
    BuildContext context,
    WidgetRef ref,
    ReturnSummaryModel returnSummary,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFFDBEAFE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.flight_land_rounded, size: 16, color: Color(0xFF1D4ED8)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'While you were away (${returnSummary.daysAway} days)...',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: Color(0xFF1E40AF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            returnSummary.message,
            style: const TextStyle(fontSize: 12, color: Color(0xFF1E3A8A), height: 1.3),
          ),
          if (returnSummary.flaggedItems.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: returnSummary.flaggedItems.map((name) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  name,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8)),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  /// Things Needing Attention section with fast 1-tap confirmation or calm "Everything looks good 🌿" state
  Widget _buildThingsNeedingAttentionSection(
    BuildContext context,
    WidgetRef ref,
    DashboardSummaryModel? summary,
  ) {
    final invState = ref.watch(inventoryControllerProvider);
    final items = summary?.needsAttention ?? [];

    if (items.isEmpty) {
      // Reassuring, zero-clutter calm card
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Center(child: Text('🌿', style: TextStyle(fontSize: 18))),
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
                      fontSize: 13.5,
                      color: Color(0xFF166534),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'All household supplies are well stocked',
                    style: TextStyle(
                      fontSize: 11.5,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header with Interactive "Explore All" Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: () => context.push('/attention'),
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF59E0B),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${items.length} ${items.length == 1 ? 'Thing Needs' : 'Things Need'} Attention',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${items.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Interactive "Explore All" Button to open the dedicated full attention screen
            InkWell(
              onTap: () => context.push('/attention'),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFDE68A), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                      blurRadius: 4,
                      offset: const Offset(0, 1.5),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Explore All',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFB45309),
                      ),
                    ),
                    SizedBox(width: 3),
                    Icon(Icons.arrow_forward_rounded, size: 13, color: Color(0xFFB45309)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Horizontal Swipeable Attention Cards (Compact height ~154px instead of 550px+ vertical scroll)
        SizedBox(
          height: 154,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final attentionItem = items[index];
              final matchedItem = invState.items.cast<InventoryItemModel?>().firstWhere(
                    (it) => it?.id == attentionItem.itemId,
                    orElse: () => null,
                  );

              final itemToConfirm = matchedItem ??
                  InventoryItemModel(
                    id: attentionItem.itemId,
                    homeId: '',
                    categoryName: attentionItem.categoryName,
                    categoryIcon: 'inventory',
                    categoryColor: '#F59E0B',
                    name: attentionItem.name,
                    quantity: attentionItem.quantity,
                    unit: attentionItem.unit,
                    minimumQuantity: 1.0,
                    stockStatus: attentionItem.stockStatus,
                    expiryStatus: attentionItem.expiryStatus,
                    daysUntilExpiry: attentionItem.daysUntilExpiry,
                  );

              final isOut = attentionItem.stockStatus == 'OUT_OF_STOCK' || attentionItem.quantity <= 0;
              final staple = findStapleForName(attentionItem.name);
              final emoji = staple?.emoji ?? '📦';

              final refCap = (matchedItem != null && matchedItem.maximumQuantity != null && matchedItem.maximumQuantity! > 0)
                  ? matchedItem.maximumQuantity!
                  : (matchedItem != null && matchedItem.minimumQuantity > 0
                      ? matchedItem.minimumQuantity * 2.0
                      : (attentionItem.quantity > 0 ? attentionItem.quantity * 1.5 : 2.0));

              final stockRatio = refCap > 0 ? (attentionItem.quantity / refCap).clamp(0.0, 1.0) : 0.0;

              return Container(
                width: 268,
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isOut
                        ? [Colors.white, const Color(0xFFFFF5F5)]
                        : [Colors.white, const Color(0xFFFFFDF5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isOut ? const Color(0xFFFECDD3) : const Color(0xFFFDE68A),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isOut ? Colors.red : Colors.amber).withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () => SmartConfirmationSheet.show(context, itemToConfirm),
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Row: Emoji Avatar + Title & Reason + Arrow
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isOut ? const Color(0xFFFFF1F2) : const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(
                                color: isOut ? const Color(0xFFFECDD3) : const Color(0xFFFDE68A),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(emoji, style: const TextStyle(fontSize: 18)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatName(attentionItem.name),
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: isOut ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    isOut
                                        ? 'Out of stock'
                                        : (attentionItem.reasonMessage.isNotEmpty
                                            ? attentionItem.reasonMessage
                                            : 'Running low'),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isOut ? const Color(0xFFB91C1C) : const Color(0xFFB45309),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
                        ],
                      ),

                      // Middle: Stock progress meter
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isOut
                                    ? '0 ${attentionItem.unit} remaining'
                                    : '${attentionItem.quantity == attentionItem.quantity.roundToDouble() ? attentionItem.quantity.toInt() : attentionItem.quantity.toStringAsFixed(1)} ${attentionItem.unit} remaining',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: isOut ? const Color(0xFFE11D48) : Colors.grey.shade700,
                                ),
                              ),
                              Text(
                                '${(stockRatio * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isOut ? const Color(0xFFE11D48) : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: isOut ? 0.04 : stockRatio.clamp(0.04, 1.0),
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isOut
                                    ? const Color(0xFFEF4444)
                                    : (stockRatio < 0.3
                                        ? const Color(0xFFF59E0B)
                                        : const Color(0xFF10B981)),
                              ),
                              minHeight: 4,
                            ),
                          ),
                        ],
                      ),

                      // Bottom Row: Two Fast Action Buttons (Still enough & + Add)
                      Row(
                        children: [
                          // Action 1: Still have enough (Immediately updates stock quantity in Drift SQLite!)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                final rawQty = refCap * 0.85;
                                final isDiscrete = attentionItem.unit.toLowerCase().contains('pc') ||
                                    attentionItem.unit.toLowerCase().contains('pack') ||
                                    attentionItem.unit.toLowerCase().contains('bottle') ||
                                    attentionItem.unit.toLowerCase().contains('can') ||
                                    attentionItem.unit.toLowerCase().contains('box');
                                final finalQty = isDiscrete
                                    ? rawQty.roundToDouble().clamp(1.0, 9999.0)
                                    : double.parse(rawQty.toStringAsFixed(1));

                                try {
                                  // 1. Immediately reflect updated quantity in local Drift inventory!
                                  await ref.read(inventoryControllerProvider.notifier).updateItem(
                                    attentionItem.itemId,
                                    {
                                      'quantity': finalQty,
                                      'quantityStatus': 'ALMOST_FULL',
                                      'stockStatus': 'IN_STOCK',
                                    },
                                  );

                                  // 2. Sync to API backend (non-blocking, online only)
                                  final conn = ref.read(connectivityMonitorProvider);
                                  if (conn.isOnline) {
                                    final api = ref.read(apiClientProvider);
                                    unawaited(() async {
                                      try {
                                        await api.post('/items/${attentionItem.itemId}/confirm-status', data: {
                                          'action': 'STILL_HAVE_ENOUGH',
                                        });
                                      } catch (_) {}
                                    }());
                                  }

                                  // 3. Background refresh
                                  ref.read(inventoryControllerProvider.notifier).loadData();
                                  ref.read(dashboardControllerProvider.notifier).loadDashboard();

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            const Text('🌿', style: TextStyle(fontSize: 16)),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Confirmed "${attentionItem.name}" stocked: $finalQty ${attentionItem.unit} 👍',
                                                style: const TextStyle(fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                          ],
                                        ),
                                        duration: const Duration(seconds: 2),
                                        backgroundColor: AppColors.hsGreen,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                } catch (_) {}
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.hsGreen,
                                side: const BorderSide(color: Color(0xFF86EFAC)),
                                backgroundColor: const Color(0xFFF0FDF4),
                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                visualDensity: VisualDensity.compact,
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline_rounded, size: 13, color: AppColors.hsGreen),
                                  SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      'Still enough',
                                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),

                          // Action 2: Add to Shopping
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                final success = await ref.read(shoppingControllerProvider.notifier).addItem(
                                      inventoryItemId: attentionItem.itemId,
                                      itemName: attentionItem.name,
                                      quantity: attentionItem.quantity > 0 ? attentionItem.quantity : 1.0,
                                      unit: attentionItem.unit,
                                    );
                                if (context.mounted && success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Text('🛒', style: TextStyle(fontSize: 16)),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text('Added "${attentionItem.name}" to Shopping List'),
                                          ),
                                        ],
                                      ),
                                      duration: const Duration(seconds: 2),
                                      backgroundColor: AppColors.primary,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                visualDensity: VisualDensity.compact,
                                elevation: 0,
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_shopping_cart_rounded, size: 13, color: Colors.white),
                                  SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      '+ Add',
                                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// HomeStock learned household habits and consumption insight card
  Widget _buildHomeStockInsightCard(
    BuildContext context,
    WidgetRef ref,
    HomeInsightModel homeInsight,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.md),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF5F3FF), Color(0xFFEDE9FE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDD6FE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFF8B5CF6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lightbulb_outline_rounded, size: 14, color: Colors.white),
              ),
              const SizedBox(width: 8),
              const Text(
                'Household Stock Memory',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: Color(0xFF5B21B6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...homeInsight.insights.take(2).map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.bold)),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF4C1D95), height: 1.3),
                  ),
                ),
              ],
            ),
          )),
        ],
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

        // Horizontal Animated Category Selector
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length + 2,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                // "All" Category Pill with SVG
                final isSelected = !_isLowStockFilter && _selectedCategoryId == null;
                return _CategoryBadgeItem(
                  svgString: DashboardSvgIcons.catAll,
                  label: 'All',
                  gradientColors: const [Color(0xFF6366F1), Color(0xFF4F46E5)],
                  shadowColor: const Color(0x406366F1),
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      _selectedCategoryId = null;
                      _isLowStockFilter = false;
                    });
                  },
                );
              }

              if (index == 1) {
                // Special Low Stock 3D Badge with SVG
                final theme = _getCategoryTheme('Low Stock');
                final isSelected = _isLowStockFilter;
                return _CategoryBadgeItem(
                  svgString: DashboardSvgIcons.catLowStock,
                  label: 'Low Stock',
                  gradientColors: theme.gradientColors,
                  shadowColor: theme.shadowColor,
                  isSelected: isSelected,
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
              final theme = _getCategoryTheme(cat.name);
              final isSelected = !_isLowStockFilter && _selectedCategoryId == cat.id;
              return _CategoryBadgeItem(
                svgString: DashboardSvgIcons.getCategorySvg(cat.name),
                label: cat.name,
                gradientColors: theme.gradientColors,
                shadowColor: theme.shadowColor,
                isSelected: isSelected,
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

  /// Daily Essentials / Needs Attention Products with animated Smart Predict button
  Widget _buildDailyEssentialsSection(BuildContext context, WidgetRef ref, DashboardSummaryModel? summary) {
    final invState = ref.watch(inventoryControllerProvider);

    // Filter items based on category or low stock selection
    List<InventoryItemModel> displayItems = invState.items;
    String sectionTitle = 'Your Pantry Items';
    bool hasActiveFilter = false;

    if (_isLowStockFilter) {
      hasActiveFilter = true;
      displayItems = displayItems.where((i) => i.isLowStock || i.isOutOfStock).toList();
      sectionTitle = 'Low Stock Items (${displayItems.length})';
    } else if (_selectedCategoryId != null) {
      hasActiveFilter = true;
      final selectedCat = invState.categories.where((c) => c.id == _selectedCategoryId).firstOrNull;
      final catName = selectedCat?.name ?? 'Category';
      displayItems = displayItems.where((i) => i.categoryId == _selectedCategoryId).toList();
      sectionTitle = '$catName Items (${displayItems.length})';
    } else {
      // Default: show top 6 items on home page
      displayItems = displayItems.take(6).toList();
    }

    if (displayItems.isEmpty && (summary?.needsAttention.isEmpty ?? true)) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.outline.withValues(alpha: 0.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 26),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              hasActiveFilter ? 'No items in this category' : 'No pantry items recorded yet',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              hasActiveFilter
                  ? 'Try selecting another category or tap Show All.'
                  : 'Tap + Add Item in Inventory or scan a barcode to stock up!',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
            ),
            if (hasActiveFilter) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedCategoryId = null;
                    _isLowStockFilter = false;
                  });
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Show All Items', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      sectionTitle,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasActiveFilter) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _selectedCategoryId = null;
                          _isLowStockFilter = false;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Clear',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(width: 3),
                            Icon(Icons.close_rounded, size: 13, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
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

        // Animated 2-Column Product Cards Grid
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey('pantry_grid_${_isLowStockFilter ? "low" : (_selectedCategoryId ?? "all")}_${displayItems.length}'),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayItems.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.78,
              ),
              itemBuilder: (context, index) {
                final item = displayItems[index];
                return _buildProductCard(context, ref, item, index);
              },
            ),
          ),
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
    final staple = findStapleForName(item.name, item.categoryName);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 200 + (index * 40)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: child,
          ),
        );
      },
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ItemDetailScreen(itemId: item.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.outline.withValues(alpha: 0.7), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Product Visual Container with soft gradient & showcase pedestal
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        catTheme.gradientColors.first.withValues(alpha: 0.08),
                        catTheme.gradientColors.last.withValues(alpha: 0.16),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: catTheme.gradientColors.first.withValues(alpha: 0.2),
                      width: 0.8,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.95),
                        boxShadow: [
                          BoxShadow(
                            color: catTheme.shadowColor.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: staple != null
                            ? Text(
                                staple.emoji,
                                style: const TextStyle(fontSize: 34),
                              )
                            : Icon(
                                productIcon,
                                size: 28,
                                color: catTheme.gradientColors.last,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Item Name (Title Cased, up to 2 lines so names never get clipped)
              Text(
                formattedName,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                  height: 1.22,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),

              // Human-friendly stock display (e.g. ~2 kg left or Likely enough for 3–4 days)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.humanQuantityDisplay,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: item.isEstimated ? const Color(0xFF92400E) : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (item.isEstimated)
                    Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Est.',
                        style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 7),

              // Bottom Row: Status Pill (tappable for 2-tap confirm) + Animated Add Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Status Pill with 2-tap stock confirmation
                  InkWell(
                    onTap: () => SmartConfirmationSheet.show(context, item),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
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

/// Animated 3D-styled Category Badge Item with tactile bounce, glowing halo, active indicator, and SVG animation
class _CategoryBadgeItem extends StatefulWidget {
  final String svgString;
  final String label;
  final List<Color> gradientColors;
  final Color shadowColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryBadgeItem({
    required this.svgString,
    required this.label,
    required this.gradientColors,
    required this.shadowColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_CategoryBadgeItem> createState() => _CategoryBadgeItemState();
}

class _CategoryBadgeItemState extends State<_CategoryBadgeItem>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late final AnimationController _hoverController;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSel = widget.isSelected;
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.90 : (isSel ? 1.05 : 1.0),
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutBack,
        child: SizedBox(
          width: 68,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge Icon Container
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isSel
                        ? widget.gradientColors
                        : [
                            widget.gradientColors.first.withValues(alpha: 0.16),
                            widget.gradientColors.last.withValues(alpha: 0.26),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: isSel
                      ? [
                          BoxShadow(
                            color: widget.shadowColor.withValues(alpha: 0.55),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                            spreadRadius: 1,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                  border: Border.all(
                    color: isSel
                        ? Colors.white
                        : widget.gradientColors.first.withValues(alpha: 0.3),
                    width: isSel ? 2.2 : 1.0,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _hoverController,
                      builder: (context, child) {
                        return _buildSemanticCategoryAnimation(
                          context,
                          child!,
                          _hoverController.value,
                          isSel,
                        );
                      },
                      child: SizedBox(
                        width: 26,
                        height: 26,
                        child: SvgPicture.string(widget.svgString),
                      ),
                    ),
                    if (isSel)
                      Positioned(
                        top: 5,
                        right: 5,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: widget.gradientColors.last.withValues(alpha: 0.8),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // Category Label
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                  color: isSel ? widget.gradientColors.last : AppColors.textPrimary,
                  letterSpacing: isSel ? -0.2 : 0,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                child: Text(widget.label, textAlign: TextAlign.center),
              ),

              // Smooth Active Indicator Pill below label
              const SizedBox(height: 3),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: isSel ? 16 : 0,
                height: 3,
                decoration: BoxDecoration(
                  color: widget.gradientColors.last,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Semantic animation tailor-crafted for each category's real-world nature
  Widget _buildSemanticCategoryAnimation(
    BuildContext context,
    Widget child,
    double t,
    bool isSelected,
  ) {
    final label = widget.label.toLowerCase();

    if (label == 'all') {
      // 2x2 App Grid: subtle diagonal breathing twist & micro-scale
      final angle = isSelected ? (sin(t * 2 * pi) * 0.08) : (sin(t * 2 * pi) * 0.05);
      final scale = 1.0 + (sin(t * 2 * pi) * 0.05);
      return Transform.rotate(
        angle: angle,
        alignment: Alignment.center,
        child: Transform.scale(scale: scale, child: child),
      );
    }

    if (label.contains('low stock') || label.contains('out of stock')) {
      // Warning Alert: Urgent Heartbeat Pulse (Thump-Thump double-beat like an alert siren)
      final beatT = (t * 2) % 1.0;
      double scale = 1.0;
      if (beatT < 0.25) {
        scale = 1.0 + sin(beatT * 4 * pi) * 0.16; // First thump
      } else if (beatT < 0.5) {
        scale = 1.0 + sin((beatT - 0.25) * 4 * pi) * 0.10; // Second thump
      }
      return Transform.scale(
        scale: isSelected ? (scale * 1.05) : scale,
        alignment: Alignment.center,
        child: child,
      );
    }

    if (label.contains('clean') || label.contains('wash') || label.contains('detergent')) {
      // Spray Bottle: Forward spritz tilt + pump compression
      final tiltAngle = sin(t * 2 * pi) * -0.14; // tilts forward like aiming to spray
      final pumpScaleY = 1.0 - (sin(t * 4 * pi).clamp(0.0, 1.0) * 0.06); // trigger pump
      return Transform.rotate(
        angle: tiltAngle,
        alignment: Alignment.bottomCenter,
        child: Transform.scale(
          scaleY: pumpScaleY,
          alignment: Alignment.bottomCenter,
          child: child,
        ),
      );
    }

    if (label.contains('kitchen') || label.contains('storage') || label.contains('general') || label.contains('staple')) {
      // Pantry Storage Box: Lid opening / peeking lift & slight perspective tilt
      final openAngle = -sin(t * 2 * pi).clamp(0.0, 1.0) * 0.12;
      final liftY = -sin(t * 2 * pi).clamp(0.0, 1.0) * 1.8;
      return Transform(
        transform: Matrix4.identity()
          ..setTranslationRaw(0, liftY, 0)
          ..rotateZ(openAngle),
        alignment: Alignment.bottomLeft,
        child: child,
      );
    }

    if (label.contains('produce') || label.contains('veg') || label.contains('fruit')) {
      // Fresh Produce: Gentle organic leaf breeze sway (from base)
      final swayAngle = sin(t * 2 * pi) * 0.14;
      return Transform.rotate(
        angle: swayAngle,
        alignment: Alignment.bottomCenter,
        child: child,
      );
    }

    if (label.contains('dairy') || label.contains('milk') || label.contains('bakery') || label.contains('bread')) {
      // Milk Bottle / Dairy: Gentle liquid sloshing rock back & forth
      final rockAngle = sin(t * 2 * pi) * 0.11;
      final bob = sin(t * 4 * pi) * 0.8;
      return Transform.translate(
        offset: Offset(0, bob),
        child: Transform.rotate(
          angle: rockAngle,
          alignment: Alignment.center,
          child: child,
        ),
      );
    }

    if (label.contains('grain') || label.contains('rice') || label.contains('flour') || label.contains('atta')) {
      // Hot Bowl of Grains: Warm steam drift upward
      final driftX = sin(t * 2 * pi) * 1.0;
      final driftY = -sin((t * 2 * pi).abs()) * 1.8;
      return Transform.translate(
        offset: Offset(driftX, driftY),
        child: child,
      );
    }

    if (label.contains('oil') || label.contains('ghee')) {
      // Golden Oil: Viscous drop stretch & flow
      final scaleY = 1.0 + (sin(t * 2 * pi) * 0.08);
      final scaleX = 1.0 - (sin(t * 2 * pi) * 0.04);
      return Transform.scale(
        scaleX: scaleX,
        scaleY: scaleY,
        alignment: Alignment.center,
        child: child,
      );
    }

    if (label.contains('spice') || label.contains('masala')) {
      // Spice Mortar/Shaker: Quick sprinkle vibration
      final shakeAngle = sin(t * 6 * pi) * 0.09;
      return Transform.rotate(
        angle: shakeAngle,
        alignment: const Alignment(0, 0.5),
        child: child,
      );
    }

    if (label.contains('snack') || label.contains('biscuit') || label.contains('sweet')) {
      // Cookie / Snack: Playful energetic hop & wiggle
      final hopY = -sin((t * 2 * pi).abs()) * 2.0;
      final wiggle = sin(t * 4 * pi) * 0.08;
      return Transform(
        transform: Matrix4.identity()
          ..setTranslationRaw(0, hopY, 0)
          ..rotateZ(wiggle),
        alignment: Alignment.center,
        child: child,
      );
    }

    if (label.contains('beverag') || label.contains('tea') || label.contains('coffee')) {
      // Hot Cup of Tea/Coffee: Steam rising lift
      final steamLift = -sin(t * 2 * pi) * 1.6;
      final steamTilt = sin(t * 2 * pi) * 0.06;
      return Transform(
        transform: Matrix4.identity()
          ..setTranslationRaw(0, steamLift, 0)
          ..rotateZ(steamTilt),
        alignment: Alignment.center,
        child: child,
      );
    }

    if (label.contains('person') || label.contains('bath') || label.contains('care') || label.contains('soap')) {
      // Bath / Spa Lotus: Floating bubble shimmer float
      final floatX = sin(t * 2 * pi) * 1.2;
      final floatY = -cos(t * 2 * pi) * 1.2;
      final scale = 1.0 + (sin(t * 2 * pi) * 0.06);
      return Transform.translate(
        offset: Offset(floatX, floatY),
        child: Transform.scale(scale: scale, child: child),
      );
    }

    // Default: Gentle natural organic float & micro-rotate
    final dy = sin(t * 2 * pi) * 1.4;
    final rotate = sin(t * 2 * pi) * 0.04;
    return Transform(
      transform: Matrix4.identity()
        ..setTranslationRaw(0, dy, 0)
        ..rotateZ(rotate),
      alignment: Alignment.center,
      child: child,
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
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.25), width: 1.1),
          ),
          child: const Center(
            child: Icon(Icons.add_rounded, color: AppColors.primary, size: 19),
          ),
        ),
      ),
    );
  }
}

/// Animated Notification Bell with ringing swing wobble when notifications exist
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

    // Sequence: swing left-right-left-right like an actual bell, then pause
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
                size: 25,
                color: AppColors.textPrimary,
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

/// 3D Animated "Say Hello" Avatar with Gamified Crown Tiers and Sliding Crown Animation
class _ProfileHealthAvatar extends ConsumerStatefulWidget {
  const _ProfileHealthAvatar();

  @override
  ConsumerState<_ProfileHealthAvatar> createState() => _ProfileHealthAvatarState();
}

class _ProfileHealthAvatarState extends ConsumerState<_ProfileHealthAvatar>
    with TickerProviderStateMixin {
  late final AnimationController _waveController;
  late final AnimationController _crownSlideController;
  late final AnimationController _depthPulseController;

  @override
  void initState() {
    super.initState();
    // 1. Waving hand rotation (Say Hello)
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);

    // 2. Crown sliding/floating horizontal & vertical motion
    _crownSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    // 3. 3D depth perspective & breathing pulse
    _depthPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _waveController.dispose();
    _crownSlideController.dispose();
    _depthPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invState = ref.watch(inventoryControllerProvider);
    final items = invState.items;
    final total = items.length;
    final outOfStock = items.where((i) => i.isOutOfStock).length;
    final lowStock = items.where((i) => i.isLowStock).length;
    final healthy = items.where((i) => !i.isLowStock && !i.isOutOfStock).length;
    final healthScore = total == 0 ? 1.0 : (healthy / total).clamp(0.0, 1.0);
    final percent = (healthScore * 100).round();

    // Gamified Crown Tier Determination based on inventory health
    final String crownSvg;
    final String tierName;
    final Color tierColor;

    if (healthScore >= 0.85) {
      crownSvg = DashboardSvgIcons.kingCrown;
      tierName = 'Royal Pantry King 👑';
      tierColor = const Color(0xFFD97706);
    } else if (healthScore >= 0.65) {
      crownSvg = DashboardSvgIcons.masterCrown;
      tierName = 'Pantry Master 🥈';
      tierColor = const Color(0xFF059669);
    } else {
      crownSvg = DashboardSvgIcons.normalCrown;
      tierName = 'Pantry Apprentice 🥉';
      tierColor = const Color(0xFFEA580C);
    }

    return GestureDetector(
      onTap: () {
        _showHealthSheet(
          context,
          percent,
          healthy,
          lowStock,
          outOfStock,
          total,
          crownSvg,
          tierName,
          tierColor,
          healthScore,
        );
      },
      child: Tooltip(
        message: '$tierName ($percent% Health) - Tap to inspect',
        child: SizedBox(
          width: 52,
          height: 56,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Circular Progress Ring indicating Inventory Health
              Positioned(
                top: 8,
                child: CustomPaint(
                  size: const Size(46, 46),
                  painter: _HealthRingPainter(
                    healthScore: healthScore,
                  ),
                ),
              ),

              // 3D Styled Avatar with Depth Gradient & Breathing Scale
              Positioned(
                top: 13,
                child: AnimatedBuilder(
                  animation: _depthPulseController,
                  builder: (context, child) {
                    final scale = 1.0 + (_depthPulseController.value * 0.035);
                    return Transform.scale(
                      scale: scale,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        center: Alignment(-0.35, -0.35),
                        radius: 0.95,
                        colors: [
                          Color(0xFFC084FC),
                          Color(0xFF8B5CF6),
                          Color(0xFF4C1D95),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: tierColor.withValues(alpha: 0.35),
                          blurRadius: 7,
                          offset: const Offset(0, 2.5),
                        ),
                        BoxShadow(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                      border: Border.all(color: Colors.white, width: 1.8),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.face_retouching_natural_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),

              // Gamified Sliding & Floating Crown (slides and tilts continuously above avatar)
              Positioned(
                top: 0,
                child: AnimatedBuilder(
                  animation: _crownSlideController,
                  builder: (context, child) {
                    final t = _crownSlideController.value;
                    final slideX = (t - 0.5) * 5.0; // slides -2.5px to +2.5px horizontally
                    final slideY = sin(t * pi) * 1.5; // gentle vertical bob
                    final angle = (t - 0.5) * 0.12; // tilt with sliding
                    return Transform.translate(
                      offset: Offset(slideX, -slideY),
                      child: Transform.rotate(
                        angle: angle,
                        alignment: Alignment.bottomCenter,
                        child: child,
                      ),
                    );
                  },
                  child: SizedBox(
                    width: 26,
                    height: 20,
                    child: SvgPicture.string(crownSvg),
                  ),
                ),
              ),

              // Animated "Say Hello" Waving Hand SVG Badge
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 18,
                  height: 18,
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _waveController,
                      builder: (context, child) {
                        final angle = (sin(_waveController.value * pi * 2) * 0.32);
                        return Transform.rotate(
                          angle: angle,
                          alignment: const Alignment(0.0, 0.95), // Natural wrist base pivot
                          child: child,
                        );
                      },
                      child: SvgPicture.string(DashboardSvgIcons.wavingHand),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHealthSheet(
    BuildContext context,
    int percent,
    int healthy,
    int lowStock,
    int outOfStock,
    int total,
    String crownSvg,
    String tierName,
    Color tierColor,
    double healthScore,
  ) {
    // Calculate items needed for next tier
    final neededForKing = ((0.85 * total) - healthy).ceil().clamp(1, 99);
    final neededForMaster = ((0.65 * total) - healthy).ceil().clamp(1, 99);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sheet Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Crown Pedestal Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    tierColor.withValues(alpha: 0.08),
                    const Color(0xFFF8FAFC),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: tierColor.withValues(alpha: 0.25), width: 1.2),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: tierColor.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      border: Border.all(color: tierColor.withValues(alpha: 0.3), width: 1),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 38,
                        height: 30,
                        child: SvgPicture.string(crownSvg),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              tierName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: tierColor,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          healthScore >= 0.85
                              ? 'Royal Status! Your household inventory is fully stocked & optimal.'
                              : (healthScore >= 0.65
                                  ? 'Stock $neededForKing more item${neededForKing > 1 ? 's' : ''} to reach the Royal King Crown 👑!'
                                  : 'Restock $neededForMaster items for Master 🥈 or $neededForKing for King 👑!'),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Crown Achievement Progress Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pantry Health Progress',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      Text(
                        '$percent% / 100%',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: tierColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: healthScore,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(tierColor),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '🥉 Apprentice (<65%)',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: healthScore < 0.65 ? FontWeight.w800 : FontWeight.w500,
                          color: healthScore < 0.65 ? const Color(0xFFEA580C) : AppColors.textMuted,
                        ),
                      ),
                      Text(
                        '🥈 Master (65-84%)',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: (healthScore >= 0.65 && healthScore < 0.85) ? FontWeight.w800 : FontWeight.w500,
                          color: (healthScore >= 0.65 && healthScore < 0.85) ? const Color(0xFF059669) : AppColors.textMuted,
                        ),
                      ),
                      Text(
                        '👑 King (85%+)',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: healthScore >= 0.85 ? FontWeight.w800 : FontWeight.w500,
                          color: healthScore >= 0.85 ? const Color(0xFFD97706) : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 3-Part Health Metric Counters
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.outline),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildHealthMetric('Well Stocked', '$healthy', const Color(0xFF10B981)),
                  Container(width: 1, height: 28, color: Colors.grey.shade200),
                  _buildHealthMetric('Low Stock', '$lowStock', const Color(0xFFF59E0B)),
                  Container(width: 1, height: 28, color: Colors.grey.shade200),
                  _buildHealthMetric('Out of Stock', '$outOfStock', const Color(0xFFEF4444)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/profile');
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('View Profile', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.go('/inventory');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Manage Items', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

/// Custom Painter for the Circular Inventory Health Ring with Gamified Tier Colors
class _HealthRingPainter extends CustomPainter {
  final double healthScore;

  _HealthRingPainter({required this.healthScore});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 1.8;

    // Background track
    final trackPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(center, radius, trackPaint);

    if (healthScore <= 0) return;

    // Active progress arc
    final sweepAngle = 2 * pi * healthScore;
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.2;

    // Dynamic Gradient based on Gamified Crown Health Tiers
    final List<Color> colors;
    if (healthScore >= 0.85) {
      // Royal King Tier: Golden Amber
      colors = const [Color(0xFFFDE047), Color(0xFFF59E0B), Color(0xFFD97706)];
    } else if (healthScore >= 0.65) {
      // Master Tier: Emerald & Teal
      colors = const [Color(0xFF34D399), Color(0xFF10B981), Color(0xFF06B6D4)];
    } else {
      // Apprentice Tier: Coral & Orange
      colors = const [Color(0xFFFB923C), Color(0xFFF97316), Color(0xFFEF4444)];
    }

    final rect = Rect.fromCircle(center: center, radius: radius);
    arcPaint.shader = SweepGradient(
      startAngle: -pi / 2,
      endAngle: (3 * pi) / 2,
      colors: colors,
      tileMode: TileMode.clamp,
    ).createShader(rect);

    canvas.drawArc(rect, -pi / 2, sweepAngle, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant _HealthRingPainter oldDelegate) {
    return oldDelegate.healthScore != healthScore;
  }
}

/// Animated SVG Waving Hand ("Say Hello") Widget with smooth pendulum wave
class _AnimatedWavingHandSvgWidget extends StatefulWidget {
  const _AnimatedWavingHandSvgWidget();

  @override
  State<_AnimatedWavingHandSvgWidget> createState() => _AnimatedWavingHandSvgWidgetState();
}

class _AnimatedWavingHandSvgWidgetState extends State<_AnimatedWavingHandSvgWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Natural waving oscillation anchored at the wrist base
        final angle = (sin(_controller.value * 2 * pi) * 0.32);
        return Transform.rotate(
          angle: angle,
          alignment: const Alignment(0.0, 0.95), // Pivots realistically at the wrist!
          child: child,
        );
      },
      child: SizedBox(
        width: 22,
        height: 22,
        child: SvgPicture.string(DashboardSvgIcons.wavingHand),
      ),
    );
  }
}

/// Animation mode for dual promo card SVG icons
enum _CardAnimationType { float, pulse }

/// Animated SVG Vector for Promo Cards (Shopping List & Pantry Stocked)
class _AnimatedPromoCardSvg extends StatefulWidget {
  final String svgString;
  final _CardAnimationType animationType;

  const _AnimatedPromoCardSvg({
    required this.svgString,
    required this.animationType,
  });

  @override
  State<_AnimatedPromoCardSvg> createState() => _AnimatedPromoCardSvgState();
}

class _AnimatedPromoCardSvgState extends State<_AnimatedPromoCardSvg>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        if (widget.animationType == _CardAnimationType.float) {
          // Shopping Bag: Real Handbag Pendulum Swing anchored at the top handle
          final swingAngle = sin(t * 2 * pi) * 0.16; // -9 to +9 deg handle swing
          final liftY = -sin((t * 2 * pi).abs()) * 1.4; // subtle centrifugal lift
          return Transform(
            transform: Matrix4.identity()
              ..setTranslationRaw(0, liftY, 0)
              ..rotateZ(swingAngle),
            alignment: Alignment.topCenter, // Pivots by the bag handle!
            child: child,
          );
        } else {
          // Pantry Stocked: Stacked cupboard shelf organizing & settling motion
          final shelfSway = sin(t * 2 * pi) * 1.2;
          final breatheScale = 1.0 + (sin(t * 2 * pi) * 0.05);
          return Transform.translate(
            offset: Offset(shelfSway, 0),
            child: Transform.scale(
              scale: breatheScale,
              alignment: Alignment.center,
              child: child,
            ),
          );
        }
      },
      child: SizedBox(
        width: 24,
        height: 24,
        child: SvgPicture.string(widget.svgString),
      ),
    );
  }
}

/// Interactive Search Bar with Typewriter Suggestion Effect
class _AnimatedSearchTypewriter extends StatefulWidget {
  const _AnimatedSearchTypewriter();

  @override
  State<_AnimatedSearchTypewriter> createState() => _AnimatedSearchTypewriterState();
}

class _AnimatedSearchTypewriterState extends State<_AnimatedSearchTypewriter> {
  static const List<String> _suggestions = [
    'Search "Milk, Curd & Butter"...',
    'Search "Basmati Rice & Atta"...',
    'Search "Tata Salt & Sugar"...',
    'Search "Sunflower Cooking Oil"...',
    'Search "Toor Dal & Moong Dal"...',
    'Search "Tea, Coffee & Snacks"...',
    'Search "Dishwash & Detergent"...',
    'Search "Bath Soap & Shampoo"...',
  ];

  int _suggestionIndex = 0;
  String _displayedText = '';
  int _charIndex = 0;
  bool _isDeleting = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTypewriter();
  }

  void _startTypewriter() {
    const typingSpeed = Duration(milliseconds: 70);
    const deletingSpeed = Duration(milliseconds: 35);
    const pauseAtFull = Duration(milliseconds: 1800);
    const pauseAtEmpty = Duration(milliseconds: 400);

    final currentTarget = _suggestions[_suggestionIndex];

    if (!_isDeleting) {
      if (_charIndex < currentTarget.length) {
        _charIndex++;
        setState(() {
          _displayedText = currentTarget.substring(0, _charIndex);
        });
        _timer = Timer(typingSpeed, _startTypewriter);
      } else {
        _timer = Timer(pauseAtFull, () {
          if (mounted) {
            _isDeleting = true;
            _startTypewriter();
          }
        });
      }
    } else {
      if (_charIndex > 0) {
        _charIndex--;
        setState(() {
          _displayedText = currentTarget.substring(0, _charIndex);
        });
        _timer = Timer(deletingSpeed, _startTypewriter);
      } else {
        _isDeleting = false;
        _suggestionIndex = (_suggestionIndex + 1) % _suggestions.length;
        _timer = Timer(pauseAtEmpty, _startTypewriter);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            _displayedText,
            style: TextStyle(
              color: AppColors.textMuted.withValues(alpha: 0.95),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _BlinkingCursor(),
      ],
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Opacity(
          opacity: _controller.value > 0.5 ? 1.0 : 0.0,
          child: const Text(
            '|',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      },
    );
  }
}

/// Animated SVG Search Icon with breathing scale pulse & lens gleam
class _AnimatedSearchIcon extends StatefulWidget {
  const _AnimatedSearchIcon();

  @override
  State<_AnimatedSearchIcon> createState() => _AnimatedSearchIconState();
}

class _AnimatedSearchIconState extends State<_AnimatedSearchIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const String _searchSvg = '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="11" cy="11" r="7" stroke="#4F46E5" stroke-width="2.2" stroke-linecap="round"/>
  <line x1="16.5" y1="16.5" x2="21.5" y2="21.5" stroke="#4F46E5" stroke-width="2.4" stroke-linecap="round"/>
  <path d="M8 8C9 7 10 7 11 7" stroke="#818CF8" stroke-width="1.5" stroke-linecap="round"/>
</svg>
''';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 1.0 + (_controller.value * 0.12);
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: SvgPicture.string(
        _searchSvg,
        width: 20,
        height: 20,
      ),
    );
  }
}

/// Animated SVG Barcode Scanner Icon with glowing laser scanning line & tactile tap
class _AnimatedBarcodeIcon extends StatefulWidget {
  final VoidCallback onTap;

  const _AnimatedBarcodeIcon({required this.onTap});

  @override
  State<_AnimatedBarcodeIcon> createState() => _AnimatedBarcodeIconState();
}

class _AnimatedBarcodeIconState extends State<_AnimatedBarcodeIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scanController;
  bool _isPressed = false;

  static const String _barcodeSvg = '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M3 8V5C3 3.89543 3.89543 3 5 3H8" stroke="#4F46E5" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M16 3H19C20.1046 3 21 3.89543 21 5V8" stroke="#4F46E5" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M3 16V19C3 20.1046 3.89543 21 5 21H8" stroke="#4F46E5" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M16 21H19C20.1046 21 21 20.1046 21 19V16" stroke="#4F46E5" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
  <line x1="7" y1="7" x2="7" y2="17" stroke="#4F46E5" stroke-width="1.8" stroke-linecap="round"/>
  <line x1="10.5" y1="7" x2="10.5" y2="17" stroke="#4F46E5" stroke-width="1.2" stroke-linecap="round"/>
  <line x1="13.5" y1="7" x2="13.5" y2="17" stroke="#4F46E5" stroke-width="2.2" stroke-linecap="round"/>
  <line x1="17" y1="7" x2="17" y2="17" stroke="#4F46E5" stroke-width="1.5" stroke-linecap="round"/>
</svg>
''';

  @override
  void initState() {
    super.initState();
    // Continuous smooth laser scan animation
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Scan Barcode',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.88 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: Container(
            width: 36,
            height: 36,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFC7D2FE), width: 0.9),
            ),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                // Base SVG Barcode
                Center(
                  child: SvgPicture.string(
                    _barcodeSvg,
                    width: 22,
                    height: 22,
                  ),
                ),
                // Animated Glowing Red Laser Line moving up and down across the barcode
                AnimatedBuilder(
                  animation: _scanController,
                  builder: (context, _) {
                    final curvedVal = Curves.easeInOut.transform(_scanController.value);
                    final topPos = 2.0 + (curvedVal * 18.0);
                    return Positioned(
                      top: topPos,
                      left: 1,
                      right: 1,
                      child: Container(
                        height: 1.8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(1),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0x00EF4444),
                              Color(0xFFEF4444),
                              Color(0xFFFF3366),
                              Color(0xFFEF4444),
                              Color(0x00EF4444),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.85),
                              blurRadius: 3,
                              spreadRadius: 0.8,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated SVG Microphone Icon with pulsing soundwave halo & dancing voice bars
class _AnimatedMicIcon extends StatefulWidget {
  final VoidCallback onTap;

  const _AnimatedMicIcon({required this.onTap});

  @override
  State<_AnimatedMicIcon> createState() => _AnimatedMicIconState();
}

class _AnimatedMicIconState extends State<_AnimatedMicIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  bool _isPressed = false;

  static const String _micSvg = '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="9" y="3" width="6" height="11" rx="3" fill="#7C3AED" stroke="#7C3AED" stroke-width="1.2"/>
  <path d="M5 10C5 13.866 8.13401 17 12 17C15.866 17 19 13.866 19 10" stroke="#7C3AED" stroke-width="2" stroke-linecap="round"/>
  <line x1="12" y1="17" x2="12" y2="21" stroke="#7C3AED" stroke-width="2" stroke-linecap="round"/>
  <line x1="8" y1="21" x2="16" y2="21" stroke="#7C3AED" stroke-width="2" stroke-linecap="round"/>
</svg>
''';

  @override
  void initState() {
    super.initState();
    // Continuous breathing / speech wave pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Voice command',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.88 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Animated Soundwave Halo
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final val = _pulseController.value;
                    return Container(
                      width: 26 + (val * 8),
                      height: 26 + (val * 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.12 * (1.0 - val * 0.4)),
                      ),
                    );
                  },
                ),
                // SVG Microphone
                SvgPicture.string(
                  _micSvg,
                  width: 21,
                  height: 21,
                ),
                // Animated Left & Right Equalizer Audio Waves
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, _) {
                        final val = _pulseController.value;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Left wave bar
                            Container(
                              width: 2,
                              height: 4 + (val * 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFA855F7).withValues(alpha: 0.7 + (val * 0.3)),
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                            // Right wave bar
                            Container(
                              width: 2,
                              height: 5 + ((1.0 - val) * 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFA855F7).withValues(alpha: 0.7 + ((1.0 - val) * 0.3)),
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
