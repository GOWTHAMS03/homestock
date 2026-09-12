import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/homestock/homestock_app_bar.dart';
import '../../../core/widgets/homestock/homestock_card.dart';
import '../controllers/bill_controller.dart';
import '../models/bill_models.dart';
import 'bill_scanner_screen.dart';

class ExpenseIntelligenceScreen extends ConsumerWidget {
  const ExpenseIntelligenceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(expenseIntelligenceControllerProvider);
    final report = state.report;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: HomeStockAppBar(
        title: 'Expense Intelligence',
        subtitle: 'Grocery spending patterns, store prices & price spikes',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(expenseIntelligenceControllerProvider.notifier).loadData(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.document_scanner),
        label: const Text('Scan Bill', style: TextStyle(fontWeight: FontWeight.w700)),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const BillScannerScreen()),
          );
        },
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: () => ref.read(expenseIntelligenceControllerProvider.notifier).loadData(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Month Navigator
                    _buildMonthNavigator(context, ref, state),
                    const SizedBox(height: 16),

                    if (report == null || report.totalBills == 0)
                      _buildEmptyState(context)
                    else ...[
                      // KPI Card: Total spend & MoM
                      _buildSummaryCard(report),
                      const SizedBox(height: 16),

                      // Inflation / Price Hike Alerts
                      if (report.priceAnomalies.isNotEmpty) ...[
                        _buildPriceAnomaliesSection(report.priceAnomalies),
                        const SizedBox(height: 16),
                      ],

                      // Category Breakdown
                      _buildCategoryBreakdown(report.categoryBreakdown),
                      const SizedBox(height: 16),

                      // Top Supermarkets & Retailers
                      _buildTopRetailers(report.topRetailers, state.storeComparison),
                      const SizedBox(height: 32),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMonthNavigator(BuildContext context, WidgetRef ref, ExpenseIntelligenceState state) {
    final monthName = DateFormat('MMMM').format(DateTime(state.selectedYear, state.selectedMonth));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary),
            onPressed: () => ref.read(expenseIntelligenceControllerProvider.notifier).previousMonth(),
          ),
          Row(
            children: [
              const Icon(Icons.calendar_month, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                '$monthName ${state.selectedYear}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: AppColors.textPrimary),
            onPressed: () => ref.read(expenseIntelligenceControllerProvider.notifier).nextMonth(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(MonthlyExpenseReportDto report) {
    final isIncrease = report.momPercentageChange > 0;
    final isZero = report.momPercentageChange == 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Household Spend',
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text('Rs. ', style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w600)),
              Text(
                report.totalSpend.toStringAsFixed(2),
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (!isZero) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isIncrease ? const Color(0xFFDC2626).withValues(alpha: 0.2) : const Color(0xFF059669).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isIncrease ? Icons.trending_up : Icons.trending_down,
                        color: isIncrease ? const Color(0xFFF87171) : const Color(0xFF34D399),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${report.momPercentageChange.abs().toStringAsFixed(1)}% vs last month',
                        style: TextStyle(
                          color: isIncrease ? const Color(0xFFF87171) : const Color(0xFF34D399),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Text(
                '${report.totalBills} bills  •  ${report.totalItemsPurchased} items restocked',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceAnomaliesSection(List<PriceAnomalyDto> anomalies) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.trending_up, color: Color(0xFFDC2626), size: 18),
            SizedBox(width: 8),
            Text(
              'Price Spike & Inflation Alerts (>10%)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...anomalies.map((a) {
          return HomeStockCard(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_upward, color: Color(0xFFDC2626), size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.productName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      Text(
                        'Previous: Rs. ${a.previousPrice.toStringAsFixed(2)}  ➔  Now: Rs. ${a.currentPrice.toStringAsFixed(2)} / ${a.unit}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+${a.percentageChange.toStringAsFixed(0)}%',
                    style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCategoryBreakdown(List<CategoryExpenseDto> categories) {
    return HomeStockCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Spending by Category',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          if (categories.isEmpty)
            const Text('No category data available', style: TextStyle(color: AppColors.textMuted))
          else
            ...categories.map((c) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${c.category} (${c.itemCount} items)',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Rs. ${c.totalSpend.toStringAsFixed(2)} (${c.percentageOfTotal.toStringAsFixed(1)}%)',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (c.percentageOfTotal / 100).clamp(0.0, 1.0),
                        backgroundColor: const Color(0xFFF1F5F9),
                        color: _getCategoryColor(c.category),
                        minHeight: 8,
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

  Widget _buildTopRetailers(List<TopRetailerDto> topRetailers, List<StoreComparisonDto> stores) {
    return HomeStockCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Retailers & Supermarkets',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          if (topRetailers.isEmpty)
            const Text('No store spend recorded yet', style: TextStyle(color: AppColors.textMuted))
          else
            ...topRetailers.map((r) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.storefront, color: AppColors.primary, size: 20),
                ),
                title: Text(r.retailerName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: Text('${r.billCount} bills visited (${r.percentageOfTotal.toStringAsFixed(1)}% of spend)'),
                trailing: Text(
                  'Rs. ${r.totalSpend.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
                ),
              );
            }),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('dairy') || lower.contains('milk')) return const Color(0xFF0284C7);
    if (lower.contains('grain') || lower.contains('staple') || lower.contains('oil')) return const Color(0xFFD97706);
    if (lower.contains('snack') || lower.contains('beverage')) return const Color(0xFFE11D48);
    if (lower.contains('veg') || lower.contains('fruit')) return const Color(0xFF059669);
    if (lower.contains('clean') || lower.contains('household')) return const Color(0xFF7C3AED);
    return const Color(0xFF64748B);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text(
              'No bills scanned for this month',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Scan receipts using the Smart Bill Scanner to see automatic expense breakdowns and price trends.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.document_scanner),
              label: const Text('Scan First Bill'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BillScannerScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
