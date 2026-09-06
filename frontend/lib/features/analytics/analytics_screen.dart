import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../purchase/add_purchase_screen.dart';
import 'analytics_controller.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsState = ref.watch(analyticsControllerProvider);
    final data = analyticsState.data;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Household Spending & Analytics'),
      ),
      body: analyticsState.isLoading
          ? ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: const [
                SkeletonLoader(height: 120, borderRadius: AppSpacing.radiusMd),
                SizedBox(height: AppSpacing.xl),
                SkeletonLoader(height: 20, width: 160),
                SizedBox(height: AppSpacing.sm),
                SkeletonLoader(height: 140, borderRadius: AppSpacing.radiusMd),
                SizedBox(height: AppSpacing.xl),
                SkeletonLoader(height: 20, width: 140),
                SizedBox(height: AppSpacing.sm),
                SkeletonLoader(height: 100, borderRadius: AppSpacing.radiusMd),
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
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              border: Border.all(color: AppColors.outline),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'This Month Spending',
                                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '₹${data.monthlySpending.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Tracked across all household grocery and supply purchases',
                                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          // Category Spending Breakdown (Section 23)
                          const SectionHeader(
                            title: 'Spending by Category',
                            subtitle: 'Monthly category allocation',
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          if (data.categorySpending.isEmpty)
                            const Card(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: Text('Record your first purchase to see category spending breakdown.', style: TextStyle(color: AppColors.textMuted)),
                                ),
                              ),
                            )
                          else
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
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
                                              Text(cat.categoryName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                              Text(
                                                '₹${cat.amount.toStringAsFixed(2)} ($pctFormatted%)',
                                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: LinearProgressIndicator(
                                              value: pct,
                                              backgroundColor: AppColors.surfaceVariant,
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
                            ),
                          const SizedBox(height: AppSpacing.xl),

                          // Store Spending Breakdown
                          const SectionHeader(
                            title: 'Spending by Store',
                            subtitle: 'Where you shop most frequently',
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          if (data.storeSpending.isEmpty)
                            const Card(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: Text('No store records yet.', style: TextStyle(color: AppColors.textMuted)),
                                ),
                              ),
                            )
                          else
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Column(
                                  children: data.storeSpending.map((s) {
                                    return ListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      leading: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: const BoxDecoration(color: AppColors.primaryContainer, shape: BoxShape.circle),
                                        child: const Icon(Icons.store_rounded, size: 18, color: AppColors.primary),
                                      ),
                                      title: Text(s.storeName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                      trailing: Text('₹${s.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          const SizedBox(height: AppSpacing.xl),

                          // Most Purchased Items (Section 23: "Most Used / Purchased")
                          const SectionHeader(
                            title: 'Most Purchased Items',
                            subtitle: 'Frequently replenished household items',
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          if (data.mostPurchasedItems.isEmpty)
                            const Card(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: Text('No purchase trends yet.', style: TextStyle(color: AppColors.textMuted)),
                                ),
                              ),
                            )
                          else
                            ...data.mostPurchasedItems.asMap().entries.map((entry) {
                              final rank = entry.key + 1;
                              final item = entry.value;
                              return Card(
                                margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                                child: ListTile(
                                  dense: true,
                                  leading: Container(
                                    width: 28,
                                    height: 28,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: rank == 1 ? AppColors.primaryContainer : AppColors.surfaceVariant,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '#$rank',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 11,
                                        color: rank == 1 ? AppColors.primary : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                  subtitle: Text('Bought ${item.count} time(s)', style: const TextStyle(fontSize: 12)),
                                  trailing: Text(
                                    '${item.quantity == item.quantity.roundToDouble() ? item.quantity.toInt() : item.quantity} units',
                                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 13),
                                  ),
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
    );
  }
}
