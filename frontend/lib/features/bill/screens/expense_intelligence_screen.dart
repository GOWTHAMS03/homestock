import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/homestock/homestock_app_bar.dart';
import '../../../core/widgets/homestock/homestock_card.dart';
import '../controllers/bill_controller.dart';
import '../models/bill_models.dart';
import '../../home_switcher/home_controller.dart';
import 'bill_scanner_screen.dart';

class ExpenseIntelligenceScreen extends ConsumerStatefulWidget {
  const ExpenseIntelligenceScreen({super.key});

  @override
  ConsumerState<ExpenseIntelligenceScreen> createState() => _ExpenseIntelligenceScreenState();
}

class _ExpenseIntelligenceScreenState extends ConsumerState<ExpenseIntelligenceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(expenseIntelligenceControllerProvider.notifier).loadData();
    });
  }

  Future<void> _openBillScanner() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BillScannerScreen()),
    );
    if (mounted) {
      ref.read(expenseIntelligenceControllerProvider.notifier).loadData();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expenseIntelligenceControllerProvider);
    final report = state.report;
    final monthName = DateFormat('MMMM').format(DateTime(state.selectedYear, state.selectedMonth));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: HomeStockAppBar(
        title: 'Expense Intelligence',
        subtitle: '$monthName ${state.selectedYear} • Grocery Budget & Trends',
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined, color: AppColors.primary),
            tooltip: 'Choose Month',
            onPressed: () => _showMonthPickerSheet(context, state),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.read(expenseIntelligenceControllerProvider.notifier).loadData(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.document_scanner),
        label: const Text('Scan Bill', style: TextStyle(fontWeight: FontWeight.w700)),
        onPressed: _openBillScanner,
      ),
      body: state.isLoading
          ? _buildLoadingSkeleton()
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => ref.read(expenseIntelligenceControllerProvider.notifier).loadData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Month Navigator
                    _buildMonthNavigator(context, state),
                    const SizedBox(height: 14),

                    if (report == null || (report.totalBills == 0 && report.totalSpend == 0))
                      _buildEmptyState(context, monthName, state.selectedYear, report)
                    else ...[
                      // 2. Executive Hero Spend Card
                      _buildHeroCard(report),
                      const SizedBox(height: 16),

                      // 3. Segmented Pill Tab Bar
                      _buildCustomTabBar(report, state),
                      const SizedBox(height: 16),

                      // 4. Tab Views
                      AnimatedBuilder(
                        animation: _tabController,
                        builder: (context, _) {
                          switch (_tabController.index) {
                            case 0:
                              return _buildOverviewTab(report, state);
                            case 1:
                              return _buildBillsTab(report, state);
                            case 2:
                              return _buildCategoriesTab(report.categoryBreakdown);
                            case 3:
                              return _buildStoresTab(state, report);
                            case 4:
                              return _buildWatchdogTab(report.priceAnomalies);
                            default:
                              return _buildOverviewTab(report, state);
                          }
                        },
                      ),
                      const SizedBox(height: 80), // Fab space
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  // ──────────────────────── Month Navigator ────────────────────────

  Widget _buildMonthNavigator(BuildContext context, ExpenseIntelligenceState state) {
    final now = DateTime.now();
    final isCurrentMonth = state.selectedYear == now.year && state.selectedMonth == now.month;
    final monthName = DateFormat('MMMM').format(DateTime(state.selectedYear, state.selectedMonth));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary, size: 22),
            tooltip: 'Previous Month',
            onPressed: () => ref.read(expenseIntelligenceControllerProvider.notifier).previousMonth(),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _showMonthPickerSheet(context, state),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.calendar_month, color: AppColors.primary, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$monthName ${state.selectedYear}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, color: AppColors.textMuted, size: 20),
                  ],
                ),
              ),
            ),
          ),
          if (!isCurrentMonth)
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                ref.read(expenseIntelligenceControllerProvider.notifier).loadData(
                      year: now.year,
                      month: now.month,
                    );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Current',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: AppColors.textPrimary, size: 22),
            tooltip: 'Next Month',
            onPressed: isCurrentMonth
                ? null
                : () => ref.read(expenseIntelligenceControllerProvider.notifier).nextMonth(),
          ),
        ],
      ),
    );
  }

  // ──────────────────────── Hero Card ────────────────────────

  Widget _buildHeroCard(MonthlyExpenseReportDto report) {
    final isIncrease = report.momPercentageChange > 0;
    final isZero = report.momPercentageChange == 0;
    final momDiff = (report.totalSpend - report.previousMonthSpend).abs();

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E1B4B),
            Color(0xFF311042),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E1B4B).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.pie_chart_outline, color: Color(0xFFA78BFA), size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Total Household Spend',
                      style: TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                if (!isZero)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isIncrease
                          ? const Color(0xFFDC2626).withValues(alpha: 0.25)
                          : const Color(0xFF059669).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isIncrease ? const Color(0xFFF87171) : const Color(0xFF34D399),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isIncrease ? Icons.trending_up : Icons.trending_down,
                          color: isIncrease ? const Color(0xFFFCA5A5) : const Color(0xFF6EE7B7),
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${isIncrease ? '+' : '-'}${report.momPercentageChange.abs().toStringAsFixed(1)}% vs last month',
                          style: TextStyle(
                            color: isIncrease ? const Color(0xFFFCA5A5) : const Color(0xFF6EE7B7),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                const Text(
                  '₹ ',
                  style: TextStyle(
                    color: Color(0xFFA78BFA),
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  report.totalSpend.toStringAsFixed(2),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            if (report.previousMonthSpend > 0) ...[
              const SizedBox(height: 4),
              Text(
                isIncrease
                    ? '₹${NumberFormat('#,##0').format(momDiff)} more than previous month (₹${NumberFormat('#,##0').format(report.previousMonthSpend)})'
                    : 'Saved ₹${NumberFormat('#,##0').format(momDiff)} compared to previous month (₹${NumberFormat('#,##0').format(report.previousMonthSpend)})',
                style: TextStyle(
                  color: isIncrease ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 14),

            // 3 Quick Metrics Row
            Row(
              children: [
                _buildHeroStatChip(
                  icon: Icons.receipt_long,
                  label: 'Bills',
                  value: '${report.totalBills}',
                ),
                const SizedBox(width: 8),
                _buildHeroStatChip(
                  icon: Icons.inventory_2_outlined,
                  label: 'Items',
                  value: '${report.totalItemsPurchased}',
                ),
                const SizedBox(width: 8),
                _buildHeroStatChip(
                  icon: Icons.scale_outlined,
                  label: 'Avg / Bill',
                  value: '₹${report.averageBillAmount.toStringAsFixed(0)}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroStatChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFFCBD5E1), size: 13),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  DateTime? _parseBillDateTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final clean = raw.trim();
    final direct = DateTime.tryParse(clean);
    if (direct != null) return direct;

    final slashParts = clean.split(RegExp(r'[/.-]'));
    if (slashParts.length == 3) {
      final p1 = int.tryParse(slashParts[0]);
      final p2 = int.tryParse(slashParts[1]);
      final p3 = int.tryParse(slashParts[2]);
      if (p1 != null && p2 != null && p3 != null) {
        if (p3 > 1000) {
          return DateTime(p3, p2, p1);
        } else if (p1 > 1000) {
          return DateTime(p1, p2, p3);
        }
      }
    }
    return null;
  }

  List<MonthlyBillSummaryDto> _getFilteredBills(MonthlyExpenseReportDto? report, int year, int month) {
    if (report == null) return const [];
    return report.bills.where((b) {
      final dt = _parseBillDateTime(b.billDate) ?? b.createdAt;
      if (dt == null) return true;
      return dt.year == year && dt.month == month;
    }).toList();
  }

  // ──────────────────────── Segmented Tabs ────────────────────────

  Widget _buildCustomTabBar(MonthlyExpenseReportDto report, ExpenseIntelligenceState state) {
    final alertCount = report.priceAnomalies.length;
    final catCount = report.categoryBreakdown.length;
    final monthlyBills = _getFilteredBills(report, state.selectedYear, state.selectedMonth);
    final billCount = monthlyBills.isNotEmpty ? monthlyBills.length : report.totalBills;
    final storeCount = state.storeComparison.isNotEmpty
        ? state.storeComparison.length
        : report.topRetailers.length;

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        tabs: [
          const Tab(text: 'Overview'),
          Tab(text: 'Bills ($billCount)'),
          Tab(text: 'Categories ($catCount)'),
          Tab(text: 'Stores ($storeCount)'),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Watchdog'),
                if (alertCount > 0) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$alertCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────── Tab 1: Overview ────────────────────────

  Widget _buildOverviewTab(MonthlyExpenseReportDto report, ExpenseIntelligenceState state) {
    final topCategory = report.categoryBreakdown.isNotEmpty ? report.categoryBreakdown.first : null;
    final topStore = report.topRetailers.isNotEmpty
        ? report.topRetailers.first
        : (state.storeComparison.isNotEmpty ? state.storeComparison.first.storeName : null);
    final daysInMonth = DateTime(state.selectedYear, state.selectedMonth + 1, 0).day;
    final dailySpend = report.totalSpend > 0 ? report.totalSpend / daysInMonth : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 2x2 Metric Cards Grid
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'Top Category',
                value: topCategory?.category ?? 'N/A',
                subtitle: topCategory != null
                    ? '₹${topCategory.totalSpend.toStringAsFixed(0)} (${topCategory.percentageOfTotal.toStringAsFixed(0)}%)'
                    : 'None yet',
                icon: Icons.category,
                accentColor: const Color(0xFF059669),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricTile(
                title: 'Primary Store',
                value: topStore is TopRetailerDto
                    ? topStore.retailerName
                    : (topStore?.toString() ?? 'N/A'),
                subtitle: topStore is TopRetailerDto
                    ? '${topStore.billCount} visits • ₹${topStore.totalSpend.toStringAsFixed(0)}'
                    : 'None yet',
                icon: Icons.storefront,
                accentColor: const Color(0xFF0284C7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'Daily Velocity',
                value: '₹${dailySpend.toStringAsFixed(0)} / day',
                subtitle: 'Based on $daysInMonth days',
                icon: Icons.speed,
                accentColor: const Color(0xFFD97706),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricTile(
                title: 'Price Watchdog',
                value: report.priceAnomalies.isNotEmpty
                    ? '${report.priceAnomalies.length} Alerts'
                    : 'All Stable',
                subtitle: report.priceAnomalies.isNotEmpty
                    ? 'Price spike detected'
                    : 'Prices within range',
                icon: report.priceAnomalies.isNotEmpty
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline,
                accentColor: report.priceAnomalies.isNotEmpty
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF059669),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // AI Grocery Insights Card
        _buildSmartInsightsCard(report),
        const SizedBox(height: 16),

        // Price Spike & Inflation Alerts Preview
        if (report.priceAnomalies.isNotEmpty) ...[
          const Row(
            children: [
              Icon(Icons.trending_up, color: Color(0xFFDC2626), size: 16),
              SizedBox(width: 6),
              Text(
                'Price Spike & Inflation Alerts (>10%)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...report.priceAnomalies.take(2).map((a) => _buildAnomalyCard(a)),
          const SizedBox(height: 16),
        ],

        // Bills in this Month Preview Card
        () {
          final monthlyBills = _getFilteredBills(report, state.selectedYear, state.selectedMonth);
          if (monthlyBills.isEmpty) return const SizedBox.shrink();
          return Column(
            children: [
              HomeStockCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.receipt_long, color: AppColors.primary, size: 16),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Bills in this Month (${monthlyBills.length})',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () => _tabController.animateTo(1),
                          child: const Text(
                            'View All',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...monthlyBills.take(3).map((b) => _buildMonthlyBillCard(b)),
                    if (monthlyBills.length > 3)
                      Center(
                        child: TextButton.icon(
                          icon: const Icon(Icons.arrow_forward, size: 14),
                          label: Text('View all ${monthlyBills.length} bills'),
                          onPressed: () => _tabController.animateTo(1),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        }(),

        // Category Preview Card
        if (report.categoryBreakdown.isNotEmpty) ...[
          HomeStockCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Spending by Category',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    InkWell(
                      onTap: () => _tabController.animateTo(2),
                      child: const Text(
                        'View All',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...report.categoryBreakdown.take(3).map((c) => _buildCategoryRow(c)),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Top Store Preview Card
        if (report.topRetailers.isNotEmpty) ...[
          HomeStockCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Top Retailers & Supermarkets',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    InkWell(
                      onTap: () => _tabController.animateTo(3),
                      child: const Text(
                        'Compare',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...report.topRetailers.take(3).map((r) => _buildStoreTile(r)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSmartInsightsCard(MonthlyExpenseReportDto report) {
    final insights = <Map<String, dynamic>>[];

    if (report.categoryBreakdown.isNotEmpty) {
      final topCat = report.categoryBreakdown.first;
      insights.add({
        'icon': Icons.insights,
        'color': const Color(0xFF7C3AED),
        'text': '${topCat.category} accounted for ${topCat.percentageOfTotal.toStringAsFixed(0)}% of total grocery spend (₹${topCat.totalSpend.toStringAsFixed(0)}).',
      });
    }

    if (report.totalBills > 0) {
      insights.add({
        'icon': Icons.shopping_bag_outlined,
        'color': const Color(0xFF0284C7),
        'text': 'Your household recorded ${report.totalBills} shopping trip(s) with an average basket size of ₹${report.averageBillAmount.toStringAsFixed(0)}.',
      });
    }

    if (report.priceAnomalies.isNotEmpty) {
      final spikes = report.priceAnomalies.where((a) => a.alertType == 'PRICE_HIKE').length;
      if (spikes > 0) {
        insights.add({
          'icon': Icons.trending_up,
          'color': const Color(0xFFDC2626),
          'text': 'Detected $spikes product(s) with >10% price hikes compared to previous purchases.',
        });
      }
    } else {
      insights.add({
        'icon': Icons.verified_outlined,
        'color': const Color(0xFF059669),
        'text': 'Grocery purchase prices remained stable without unusual price inflation.',
      });
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDD6FE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.primary, size: 18),
              SizedBox(width: 8),
              Text(
                'AI Spending Insights',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...insights.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 15),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item['text'] as String,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ──────────────────────── Tab 1: Monthly Bills ────────────────────────

  Widget _buildBillsTab(MonthlyExpenseReportDto report, ExpenseIntelligenceState state) {
    final bills = _getFilteredBills(report, state.selectedYear, state.selectedMonth);

    if (bills.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long_outlined, size: 40, color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            const Text(
              'No bills recorded for this month',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Scan receipts or record supermarket purchases to see your monthly bills.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.document_scanner, size: 16),
              label: const Text('Scan a Bill', style: TextStyle(fontWeight: FontWeight.w700)),
              onPressed: _openBillScanner,
            ),
          ],
        ),
      );
    }

    final totalFilteredBillsSpend = bills.fold<double>(0.0, (sum, b) => sum + b.totalAmount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Summary Header Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEFF6FF), Color(0xFFF8FAFC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFDBEAFE)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_long, color: Color(0xFF2563EB), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${bills.length} ${bills.length == 1 ? "Bill" : "Bills"} in ${report.monthName ?? "Month"}',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1E3A8A), fontSize: 14),
                  ),
                ],
              ),
              Text(
                'Total: ₹${totalFilteredBillsSpend.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1D4ED8), fontSize: 15),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // List of all monthly bills
        ...bills.map((bill) => _buildMonthlyBillCard(bill)),
      ],
    );
  }

  Widget _buildMonthlyBillCard(MonthlyBillSummaryDto bill) {
    String formattedDate = bill.billDate ?? '';
    final dateObj = bill.createdAt ?? (bill.billDate != null ? DateTime.tryParse(bill.billDate!) : null);
    if (dateObj != null) {
      final localDate = dateObj.toLocal();
      final hasTime = bill.createdAt != null || (localDate.hour != 0 || localDate.minute != 0);
      formattedDate = hasTime
          ? DateFormat('dd MMM yyyy, hh:mm a').format(localDate)
          : DateFormat('dd MMM yyyy').format(localDate);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 22),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  bill.shopName,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '₹${bill.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                if (formattedDate.isNotEmpty) ...[
                  Text(
                    formattedDate,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                  ),
                  const Text(' · ', style: TextStyle(color: AppColors.textMuted)),
                ],
                Text(
                  '${bill.itemsCount} ${bill.itemsCount == 1 ? "item" : "items"}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                ),
                if (bill.billNumber != 'N/A' && bill.billNumber.isNotEmpty) ...[
                  const Text(' · ', style: TextStyle(color: AppColors.textMuted)),
                  Flexible(
                    child: Text(
                      bill.billNumber,
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
          children: [
            const Divider(color: Color(0xFFF1F5F9), height: 1),
            const SizedBox(height: 12),
            if (bill.items.isEmpty)
              const Text(
                'No itemized products available for this receipt.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontStyle: FontStyle.italic),
              )
            else ...[
              ...bill.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6, right: 8),
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item.itemName,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 2)} ${item.unit}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '₹${item.finalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  // ──────────────────────── Tab 2: Categories ────────────────────────

  Widget _buildCategoriesTab(List<CategoryExpenseDto> categories) {
    if (categories.isEmpty) {
      return const HomeStockCard(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text('No category spending recorded for this month', style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }

    return HomeStockCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spending by Category',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              Text(
                'Tap for details',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...categories.map((c) => _buildCategoryRow(c, isInteractive: true)),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(CategoryExpenseDto c, {bool isInteractive = false}) {
    final catColor = _getCategoryColor(c.category);
    final icon = _getCategoryIcon(c.category);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: isInteractive ? () => _showCategoryDetailSheet(context, c) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: catColor, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.category,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      Text(
                        '${c.itemCount} items purchased',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${c.totalSpend.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    Text(
                      '${c.percentageOfTotal.toStringAsFixed(1)}%',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: catColor),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (c.percentageOfTotal / 100).clamp(0.0, 1.0),
                backgroundColor: const Color(0xFFF1F5F9),
                valueColor: AlwaysStoppedAnimation<Color>(catColor),
                minHeight: 7,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────── Tab 3: Stores ────────────────────────

  Widget _buildStoresTab(ExpenseIntelligenceState state, MonthlyExpenseReportDto report) {
    final stores = report.topRetailers;

    if (stores.isEmpty && state.storeComparison.isEmpty) {
      return const HomeStockCard(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text('No store spending recorded for this month', style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeStockCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Retailers & Supermarkets Ranked',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              const Text(
                'Spending distribution across supermarkets and local stores',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ...stores.asMap().entries.map((entry) {
                final index = entry.key;
                final retailer = entry.value;
                return _buildStoreRankCard(retailer, rank: index + 1);
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStoreRankCard(TopRetailerDto r, {required int rank}) {
    Color rankColor;
    if (rank == 1) {
      rankColor = const Color(0xFFD97706); // Gold
    } else if (rank == 2) {
      rankColor = const Color(0xFF64748B); // Silver
    } else if (rank == 3) {
      rankColor = const Color(0xFFB45309); // Bronze
    } else {
      rankColor = AppColors.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(color: rankColor, fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        r.retailerName,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (rank == 1)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Primary',
                          style: TextStyle(color: Color(0xFFB45309), fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${r.billCount} bill(s) • ${r.percentageOfTotal.toStringAsFixed(1)}% of total grocery spend',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '₹${r.totalSpend.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreTile(TopRetailerDto r) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.storefront, color: AppColors.primary, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.retailerName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                Text('${r.billCount} visits • ${r.percentageOfTotal.toStringAsFixed(1)}% spend',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text(
            '₹${r.totalSpend.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  // ──────────────────────── Tab 4: Price Watchdog ────────────────────────

  Widget _buildWatchdogTab(List<PriceAnomalyDto> anomalies) {
    final spikes = anomalies.where((a) => a.alertType == 'PRICE_HIKE').toList();
    final drops = anomalies.where((a) => a.alertType == 'PRICE_DROP').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header explanation card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.shield_outlined, color: Color(0xFF0284C7), size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Price Watchdog compares standard unit prices (e.g. ₹/kg, ₹/L) across consecutive receipts to alert you of sudden price spikes or grocery savings.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF1E3A8A), height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (anomalies.isEmpty)
          HomeStockCard(
            padding: const EdgeInsets.all(28),
            child: Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_outline, color: Color(0xFF059669), size: 36),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No Price Spikes Detected',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'All items scanned this month remained stable within their historical purchase prices.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          )
        else ...[
          if (spikes.isNotEmpty) ...[
            const Row(
              children: [
                Icon(Icons.trending_up, color: Color(0xFFDC2626), size: 16),
                SizedBox(width: 6),
                Text(
                  'Price Spike Alerts (>10% Inflation)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...spikes.map((a) => _buildAnomalyCard(a)),
            const SizedBox(height: 16),
          ],
          if (drops.isNotEmpty) ...[
            const Row(
              children: [
                Icon(Icons.trending_down, color: Color(0xFF059669), size: 16),
                SizedBox(width: 6),
                Text(
                  'Price Drops & Savings',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...drops.map((a) => _buildAnomalyCard(a)),
          ],
        ],
      ],
    );
  }

  Widget _buildAnomalyCard(PriceAnomalyDto a) {
    final isHike = a.alertType == 'PRICE_HIKE';
    final accentColor = isHike ? const Color(0xFFDC2626) : const Color(0xFF059669);
    final bgColor = isHike ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5);
    final badgeColor = isHike ? const Color(0xFFFEE2E2) : const Color(0xFFD1FAE5);

    return HomeStockCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isHike ? Icons.arrow_upward : Icons.arrow_downward,
                  color: accentColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.productName,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (a.storeName != null)
                      Text(
                        'Store: ${a.storeName}${a.detectedAt != null ? ' • ${a.detectedAt}' : ''}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${isHike ? '+' : ''}${a.percentageChange.toStringAsFixed(0)}%',
                  style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Was: ₹${a.previousPrice.toStringAsFixed(2)} / ${a.unit}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const Icon(Icons.arrow_forward, size: 14, color: AppColors.textMuted),
                Text(
                  'Now: ₹${a.currentPrice.toStringAsFixed(2)} / ${a.unit}',
                  style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          if (a.productId != null || a.inventoryItemId != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: AppColors.primary,
                ),
                icon: const Icon(Icons.history, size: 14),
                label: const Text('View Price History', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                onPressed: () => _showPriceHistorySheet(context, a),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ──────────────────────── Price History Sheet ────────────────────────

  void _showPriceHistorySheet(BuildContext context, PriceAnomalyDto anomaly) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.75,
          ),
          child: FutureBuilder<ProductPriceHistoryDto>(
            future: _fetchPriceHistory(anomaly),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
              }

              if (snapshot.hasError || snapshot.data == null) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 36),
                    const SizedBox(height: 12),
                    Text('Could not load price history: ${snapshot.error ?? "No data"}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close'),
                    ),
                  ],
                );
              }

              final history = snapshot.data!;
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      history.productName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Unit: ${history.unit} • Current standard: ₹${history.currentPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),

                    // Price Range Summary
                    Row(
                      children: [
                        Expanded(
                          child: _buildPriceStatBox(
                            label: 'Lowest Price',
                            value: '₹${history.lowestPrice.toStringAsFixed(2)}',
                            color: const Color(0xFF059669),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildPriceStatBox(
                            label: 'Average Price',
                            value: '₹${history.averagePrice.toStringAsFixed(2)}',
                            color: const Color(0xFF0284C7),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildPriceStatBox(
                            label: 'Highest Price',
                            value: '₹${history.highestPrice.toStringAsFixed(2)}',
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                    if (history.recommendedStore != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.thumb_up_alt_outlined, color: Color(0xFF059669), size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Recommended for Best Value: ${history.recommendedStore}',
                                style: const TextStyle(color: Color(0xFF065F46), fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    const Text(
                      'Past Purchases Timeline',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 10),
                    if (history.pricePoints.isEmpty)
                      const Text('No previous purchases recorded yet', style: TextStyle(color: AppColors.textMuted))
                    else
                      ...history.pricePoints.map((p) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.store, size: 14, color: AppColors.primary),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.storeName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                    Text('${p.purchaseDate} • ${p.quantity} ${p.unit}',
                                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₹${p.standardUnitPrice.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: p.isHigherThanUsual ? const Color(0xFFDC2626) : AppColors.textPrimary,
                                    ),
                                  ),
                                  Text('/ ${p.unit}', style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<ProductPriceHistoryDto> _fetchPriceHistory(PriceAnomalyDto anomaly) async {
    final api = ref.read(billApiServiceProvider);
    final activeHomeId = ref.read(homeControllerProvider).activeHome?.id ?? '';
    if (anomaly.productId != null && anomaly.productId!.isNotEmpty) {
      return api.getProductPriceHistory(activeHomeId, anomaly.productId!);
    } else if (anomaly.inventoryItemId != null && anomaly.inventoryItemId!.isNotEmpty) {
      return api.getItemPriceHistory(activeHomeId, anomaly.inventoryItemId!);
    }
    throw Exception('No identifier available for product');
  }

  Widget _buildPriceStatBox({required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  // ──────────────────────── Category Detail Sheet ────────────────────────

  void _showCategoryDetailSheet(BuildContext context, CategoryExpenseDto c) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final catColor = _getCategoryColor(c.category);
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_getCategoryIcon(c.category), color: catColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.category, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                        Text('${c.itemCount} items purchased this month',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Text(
                    '₹${c.totalSpend.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'This category represents ${c.percentageOfTotal.toStringAsFixed(1)}% of your total grocery budget this month.',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
      },
    );
  }

  // ──────────────────────── Month Picker Sheet ────────────────────────

  void _showMonthPickerSheet(BuildContext context, ExpenseIntelligenceState state) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        int tempSelectedYear = state.selectedYear;
        return StatefulBuilder(
          builder: (context, setModalState) {
            final currentYear = DateTime.now().year;
            final periodYears = state.report?.availablePeriods.map((p) => p.year) ?? [];
            final years = <int>{currentYear - 1, currentYear, ...periodYears}.toList()..sort();

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Select Statement Month',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Months with scanned bills are highlighted',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),

                  // Year switcher
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: years.map((y) {
                      final isSel = y == tempSelectedYear;
                      final billsInYear = (state.report?.availablePeriods ?? [])
                          .where((p) => p.year == y)
                          .fold<int>(0, (sum, p) => sum + p.billsCount);

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: ChoiceChip(
                          label: Text(billsInYear > 0 ? '$y ($billsInYear)' : '$y'),
                          selected: isSel,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() {
                                tempSelectedYear = y;
                              });
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  // 12 Months Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 2.0,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      final monthNum = index + 1;
                      final monthLabel = DateFormat('MMM').format(DateTime(2026, monthNum));
                      final isSelected = state.selectedYear == tempSelectedYear && state.selectedMonth == monthNum;

                      BillingPeriodDto? periodForMonth;
                      for (final p in state.report?.availablePeriods ?? <BillingPeriodDto>[]) {
                        if (p.year == tempSelectedYear && p.month == monthNum) {
                          periodForMonth = p;
                          break;
                        }
                      }
                      final hasBills = periodForMonth != null && periodForMonth.billsCount > 0;

                      return InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          ref.read(expenseIntelligenceControllerProvider.notifier).loadData(
                                year: tempSelectedYear,
                                month: monthNum,
                              );
                          Navigator.pop(ctx);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : (hasBills ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : (hasBills ? const Color(0xFF93C5FD) : Colors.transparent),
                              width: hasBills ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                monthLabel,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : (hasBills ? const Color(0xFF1D4ED8) : AppColors.textPrimary),
                                  fontWeight: isSelected || hasBills ? FontWeight.w800 : FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              if (hasBills) ...[
                                const SizedBox(height: 2),
                                Text(
                                  '₹${periodForMonth.totalSpend.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected ? Colors.white70 : const Color(0xFF1E40AF),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ──────────────────────── Empty State ────────────────────────

  Widget _buildEmptyState(
    BuildContext context,
    String monthName,
    int year,
    MonthlyExpenseReportDto? report,
  ) {
    final availablePeriods = report?.availablePeriods ?? <BillingPeriodDto>[];

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
        child: Column(
          children: [
            if (availablePeriods.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEFF6FF), Color(0xFFF0FDF4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Scanned Bills Found!',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E3A8A),
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Bills were extracted with their original printed receipt dates:',
                                style: TextStyle(color: Color(0xFF475569), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ...availablePeriods.map((period) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFDBEAFE)),
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
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.receipt_long, color: AppColors.primary, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${period.monthName} ${period.year}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${period.billsCount} ${period.billsCount == 1 ? "bill" : "bills"} · Total ₹${period.totalSpend.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: Color(0xFF10B981),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 1,
                              ),
                              icon: const Icon(Icons.arrow_forward, size: 16),
                              label: const Text(
                                'View',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                              onPressed: () {
                                ref.read(expenseIntelligenceControllerProvider.notifier).loadData(
                                      year: period.year,
                                      month: period.month,
                                    );
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],

            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long_outlined, size: 52, color: AppColors.primary),
            ),
            const SizedBox(height: 18),
            Text(
              'No bills scanned for $monthName $year',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Scan retail and supermarket bills using the AI Bill Scanner to unlock automatic spending breakdowns, price spike alerts, and store comparisons.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 3,
              ),
              icon: const Icon(Icons.document_scanner),
              label: const Text('Scan First Bill', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              onPressed: _openBillScanner,
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────── Loading Skeleton ────────────────────────

  Widget _buildLoadingSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ],
    );
  }

  // ──────────────────────── Helpers ────────────────────────

  Color _getCategoryColor(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('dairy') || lower.contains('milk')) return const Color(0xFF0284C7); // Sky blue
    if (lower.contains('grain') || lower.contains('staple') || lower.contains('oil') || lower.contains('flour')) {
      return const Color(0xFFD97706); // Amber
    }
    if (lower.contains('snack') || lower.contains('beverage') || lower.contains('tea') || lower.contains('coffee')) {
      return const Color(0xFFE11D48); // Rose
    }
    if (lower.contains('veg') || lower.contains('fruit') || lower.contains('produce')) {
      return const Color(0xFF059669); // Emerald
    }
    if (lower.contains('clean') || lower.contains('household') || lower.contains('detergent')) {
      return const Color(0xFF7C3AED); // Purple
    }
    if (lower.contains('meat') || lower.contains('chicken') || lower.contains('fish')) {
      return const Color(0xFFDC2626); // Red
    }
    if (lower.contains('personal') || lower.contains('care') || lower.contains('beauty')) {
      return const Color(0xFF0D9488); // Teal
    }
    return const Color(0xFF64748B); // Slate
  }

  IconData _getCategoryIcon(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('dairy') || lower.contains('milk')) return Icons.water_drop_outlined;
    if (lower.contains('grain') || lower.contains('staple') || lower.contains('oil') || lower.contains('flour')) {
      return Icons.grain_outlined;
    }
    if (lower.contains('snack') || lower.contains('beverage')) return Icons.fastfood_outlined;
    if (lower.contains('veg') || lower.contains('fruit') || lower.contains('produce')) return Icons.eco_outlined;
    if (lower.contains('clean') || lower.contains('household')) return Icons.cleaning_services_outlined;
    if (lower.contains('meat') || lower.contains('chicken')) return Icons.restaurant_outlined;
    if (lower.contains('personal')) return Icons.spa_outlined;
    return Icons.category_outlined;
  }
}
