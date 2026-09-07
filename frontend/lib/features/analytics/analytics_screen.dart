import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/homestock/homestock_app_bar.dart';
import '../../core/widgets/homestock/homestock_card.dart';
import '../../core/widgets/homestock/homestock_pill_badge.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../purchase/add_purchase_screen.dart';
import 'analytics_controller.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _AnalyticsContent();
  }
}

class _AnalyticsContent extends ConsumerWidget {
  const _AnalyticsContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsState = ref.watch(analyticsControllerProvider);
    final data = analyticsState.data;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: const HomeStockAppBar(
        title: 'Spending & Analytics',
        subtitle: 'Household budget trends & breakdown',
      ),
      body: analyticsState.isLoading
          ? ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: const [
                SkeletonLoader(height: 120, borderRadius: 16),
                SizedBox(height: AppSpacing.xl),
                SkeletonLoader(height: 20, width: 160),
                SizedBox(height: AppSpacing.sm),
                SkeletonLoader(height: 140, borderRadius: 16),
                SizedBox(height: AppSpacing.xl),
                SkeletonLoader(height: 20, width: 140),
                SizedBox(height: AppSpacing.sm),
                SkeletonLoader(height: 100, borderRadius: 16),
              ],
            )
          : data == null
              ? const Center(child: Text('Unable to load analytics'))
              : (data.monthlySpending == 0 && data.categorySpending.isEmpty && data.mostPurchasedItems.isEmpty)
                  ? EmptyStateView(
                      icon: Icons.insights_rounded,
                      title: 'No spending insights yet',
                      message: 'Record your grocery and household purchases to unlock monthly budget trends, store breakdowns, and top items.',
                      actionLabel: 'Record First Purchase',
                      onAction: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AddPurchaseScreen()),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref.read(analyticsControllerProvider.notifier).loadAnalytics(),
                      child: ListView(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        children: [
                          // Monthly Total Hero Card
                          HomeStockCard(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'This Month Spending',
                                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w700),
                                    ),
                                    HomeStockPillBadge(
                                      label: data.monthlySpending > 0 ? 'Active Budget' : 'No Expenses',
                                      variant: HomeStockPillVariant.green,
                                      fontSize: 10,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '₹${data.monthlySpending.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Tracked across all grocery receipts and restock records',
                                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          // Category Spending Breakdown
                          const SectionHeader(
                            title: 'Spending by Category',
                            subtitle: 'Monthly category allocation',
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          if (data.categorySpending.isEmpty)
                            const HomeStockCard(
                              padding: EdgeInsets.all(20.0),
                              child: Center(
                                child: Text('Record your first purchase to see category spending.', style: TextStyle(color: AppColors.textMuted)),
                              ),
                            )
                          else
                            HomeStockCard(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: data.categorySpending.map((cat) {
                                  final pct = data.monthlySpending > 0 ? (cat.amount / data.monthlySpending) : 0.0;
                                  final pctFormatted = (pct * 100).toStringAsFixed(0);
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(cat.categoryName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
                                            Text(
                                              '₹${cat.amount.toStringAsFixed(2)} ($pctFormatted%)',
                                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textPrimary),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: pct,
                                            backgroundColor: const Color(0xFFF1F5F9),
                                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                                            minHeight: 7,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          const SizedBox(height: AppSpacing.xl),

                          // Store Spending Breakdown
                          const SectionHeader(
                            title: 'Spending by Store',
                            subtitle: 'Where you shop most frequently',
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          if (data.storeSpending.isEmpty)
                            const HomeStockCard(
                              padding: EdgeInsets.all(20.0),
                              child: Center(
                                child: Text('No store records logged yet.', style: TextStyle(color: AppColors.textMuted)),
                              ),
                            )
                          else
                            HomeStockCard(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  for (int i = 0; i < data.storeSpending.length; i++) ...[
                                    if (i > 0) const HomeStockDottedDivider(height: 14),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: AppColors.outline.withValues(alpha: 0.6)),
                                          ),
                                          child: const Icon(Icons.store_rounded, size: 18, color: AppColors.primary),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            data.storeSpending[i].storeName,
                                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
                                          ),
                                        ),
                                        Text(
                                          '₹${data.storeSpending[i].amount.toStringAsFixed(2)}',
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimary),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          const SizedBox(height: AppSpacing.xl),

                          // Top Purchased Items
                          const SectionHeader(
                            title: 'Most Purchased Products',
                            subtitle: 'Ranked by frequency and quantity',
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          if (data.mostPurchasedItems.isEmpty)
                            const HomeStockCard(
                              padding: EdgeInsets.all(20.0),
                              child: Center(
                                child: Text('No item purchase history yet.', style: TextStyle(color: AppColors.textMuted)),
                              ),
                            )
                          else
                            HomeStockCard(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  for (int i = 0; i < data.mostPurchasedItems.length; i++) ...[
                                    if (i > 0) const HomeStockDottedDivider(height: 14),
                                    Row(
                                      children: [
                                        Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: i == 0 ? AppColors.primary : const Color(0xFFF1F5F9),
                                            shape: BoxShape.circle,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            '#${i + 1}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: i == 0 ? Colors.white : AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            data.mostPurchasedItems[i].name,
                                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
                                          ),
                                        ),
                                        Text(
                                          '${data.mostPurchasedItems[i].quantity.toStringAsFixed(0)} units',
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          const SizedBox(height: AppSpacing.xxl),
                        ],
                      ),
                    ),
    );
  }
}
