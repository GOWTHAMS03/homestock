import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../controllers/customer_demand_controller.dart';
import '../controllers/shop_owner_controller.dart';
import '../models/customer_demand_models.dart';

class CustomerDemandScreen extends ConsumerStatefulWidget {
  const CustomerDemandScreen({super.key});

  @override
  ConsumerState<CustomerDemandScreen> createState() => _CustomerDemandScreenState();
}

class _CustomerDemandScreenState extends ConsumerState<CustomerDemandScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final shop = ref.read(shopOwnerControllerProvider).shop;
      if (shop != null) {
        ref.read(customerDemandControllerProvider.notifier).loadDashboard(shopId: shop.id);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final demandState = ref.watch(customerDemandControllerProvider);
    final shop = ref.watch(shopOwnerControllerProvider).shop;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer Demand', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              'Local neighborhood demand intelligence',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Demand',
            onPressed: () {
              if (shop != null) {
                ref.read(customerDemandControllerProvider.notifier).loadDashboard(shopId: shop.id);
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(
              icon: const Icon(Icons.lightbulb_outline, size: 20),
              text: 'Opportunities (${demandState.dashboard?.opportunities.length ?? 0})',
            ),
            const Tab(
              icon: Icon(Icons.trending_up, size: 20),
              text: 'Top Products',
            ),
            const Tab(
              icon: Icon(Icons.radar, size: 20),
              text: 'Demand Zones',
            ),
          ],
        ),
      ),
      body: demandState.isLoading && demandState.dashboard == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                if (shop != null) {
                  await ref.read(customerDemandControllerProvider.notifier).loadDashboard(shopId: shop.id);
                }
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Filter Chips (Time Window & Radius)
                    _buildFilterControls(demandState),
                    const SizedBox(height: AppSpacing.md),

                    // Natural Language Insight Banner
                    if (demandState.dashboard != null)
                      _buildSummaryInsightBanner(demandState.dashboard!),
                    const SizedBox(height: AppSpacing.md),

                    // Metric Counters
                    if (demandState.dashboard != null)
                      _buildMetricCounters(demandState.dashboard!),
                    const SizedBox(height: AppSpacing.md),

                    // Product Investigation Search Bar
                    _buildInvestigationSearchBar(demandState),
                    const SizedBox(height: AppSpacing.md),

                    // Search Investigation Result (if active)
                    if (demandState.searchDetail != null) ...[
                      _buildSearchResultCard(demandState.searchDetail!),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Tab View Content
                    SizedBox(
                      height: 520,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Tab 1: Actionable Opportunities
                          _buildOpportunitiesTab(demandState),
                          // Tab 2: Top Demanded Products
                          _buildTopProductsTab(demandState),
                          // Tab 3: Concentric Demand Zones
                          _buildDemandZonesTab(demandState),
                        ],
                      ),
                    ),

                    // Subscription Entitlement Preview Banner
                    if (demandState.dashboard?.isGated ?? false) ...[
                      const SizedBox(height: AppSpacing.md),
                      _buildSubscriptionUpgradeBanner(context),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFilterControls(CustomerDemandState state) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Filter
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.black54),
                const SizedBox(width: 6),
                const Text('Period: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: DemandPeriod.values.map((p) {
                        final isSelected = state.selectedPeriod == p;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(p.label, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.black87)),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            backgroundColor: Colors.grey.shade100,
                            onSelected: (_) => ref.read(customerDemandControllerProvider.notifier).setPeriod(p),
                            visualDensity: VisualDensity.compact,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 12),
            // Radius Filter
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.black54),
                const SizedBox(width: 6),
                const Text('Radius: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [1.0, 3.0, 5.0, 10.0].map((r) {
                        final isSelected = state.selectedRadiusKm == r;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text('${r.toInt()} km', style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.black87)),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            backgroundColor: Colors.grey.shade100,
                            onSelected: (_) => ref.read(customerDemandControllerProvider.notifier).setRadius(r),
                            visualDensity: VisualDensity.compact,
                          ),
                        );
                      }).toList(),
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

  Widget _buildSummaryInsightBanner(CustomerDemandDashboardModel dash) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.08), Colors.blue.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Neighborhood Intelligence Insight',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const SizedBox(height: 4),
                Text(
                  dash.summaryInsight,
                  style: const TextStyle(fontSize: 13, height: 1.35, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCounters(CustomerDemandDashboardModel dash) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            label: 'Local Signals',
            value: '${dash.totalDemandSignals}',
            icon: Icons.graphic_eq,
            color: Colors.indigo,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard(
            label: 'Catalog Gaps',
            value: '${dash.missingProductsCount}',
            icon: Icons.add_shopping_cart,
            color: Colors.orange.shade800,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard(
            label: 'Restock Alerts',
            value: '${dash.restockOpportunitiesCount}',
            icon: Icons.inventory,
            color: Colors.red.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestigationSearchBar(CustomerDemandState state) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search specific grocery or brand...',
              hintStyle: const TextStyle(fontSize: 13, color: Colors.black45),
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: state.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(customerDemandControllerProvider.notifier).clearSearch();
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            onSubmitted: (query) {
              if (query.trim().isNotEmpty) {
                ref.read(customerDemandControllerProvider.notifier).searchProduct(query.trim());
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {
            if (_searchController.text.trim().isNotEmpty) {
              ref.read(customerDemandControllerProvider.notifier).searchProduct(_searchController.text.trim());
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          child: const Text('Check', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildSearchResultCard(ProductDemandDetailModel detail) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Demand Analysis for "${detail.queryText}"',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => ref.read(customerDemandControllerProvider.notifier).clearSearch(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildBadge(
                label: '${detail.totalSignals} signals',
                color: Colors.blue.shade700,
                bg: Colors.white,
              ),
              const SizedBox(width: 8),
              _buildBadge(
                label: detail.inShopCatalog ? 'In Your Catalog' : 'Missing From Catalog',
                color: detail.inShopCatalog ? Colors.green.shade800 : Colors.orange.shade800,
                bg: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (detail.signalsByType.isNotEmpty) ...[
            const Text('Signal Breakdown:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              children: detail.signalsByType.entries.map((e) {
                return Chip(
                  label: Text('${e.key.replaceAll('_', ' ')}: ${e.value}', style: const TextStyle(fontSize: 10)),
                  backgroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                );
              }).toList(),
            ),
          ],
          if (!detail.inShopCatalog) ...[
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                context.push('/shop/products/add?name=${Uri.encodeComponent(detail.queryText)}');
              },
              icon: const Icon(Icons.add, size: 16),
              label: Text('Add "${detail.queryText}" to Catalog'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Tab 1: Actionable Opportunities
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildOpportunitiesTab(CustomerDemandState state) {
    final opps = state.dashboard?.opportunities ?? [];

    if (opps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 48, color: Colors.green.shade300),
            const SizedBox(height: 8),
            const Text(
              'No Urgent Catalog Opportunities',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            const Text(
              'Your catalog is well-stocked for current neighborhood demand.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: opps.length,
      separatorBuilder: (_, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final opp = opps[index];
        return _buildOpportunityCard(opp);
      },
    );
  }

  Widget _buildOpportunityCard(DemandOpportunityModel opp) {
    Color badgeColor;
    Color badgeBg;
    IconData icon;

    switch (opp.type) {
      case OpportunityType.missingProduct:
        badgeColor = Colors.blue.shade800;
        badgeBg = Colors.blue.shade50;
        icon = Icons.add_circle_outline;
        break;
      case OpportunityType.outOfStock:
        badgeColor = Colors.red.shade800;
        badgeBg = Colors.red.shade50;
        icon = Icons.error_outline;
        break;
      case OpportunityType.lowStock:
        badgeColor = Colors.orange.shade800;
        badgeBg = Colors.orange.shade50;
        icon = Icons.warning_amber_rounded;
        break;
      case OpportunityType.priceOpportunity:
        badgeColor = Colors.purple.shade800;
        badgeBg = Colors.purple.shade50;
        icon = Icons.price_change_outlined;
        break;
    }

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(6)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 14, color: badgeColor),
                      const SizedBox(width: 4),
                      Text(
                        opp.type.label,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: badgeColor),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '${opp.localDemandCount} searches',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              opp.title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              opp.description,
              style: const TextStyle(fontSize: 12, color: Colors.black54, height: 1.3),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    if (opp.type == OpportunityType.missingProduct) {
                      context.push('/shop/products/add?name=${Uri.encodeComponent(opp.productName)}');
                    } else {
                      context.push('/shop/products');
                    }
                  },
                  icon: Icon(
                    opp.type == OpportunityType.missingProduct ? Icons.add : Icons.edit,
                    size: 14,
                  ),
                  label: Text(opp.suggestedAction, style: const TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: badgeColor,
                    side: BorderSide(color: badgeColor),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Tab 2: Top Demanded Products
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildTopProductsTab(CustomerDemandState state) {
    final products = state.dashboard?.topDemandedProducts ?? [];

    if (products.isEmpty) {
      return const Center(
        child: Text('No demand recorded within selected radius.', style: TextStyle(color: Colors.black54)),
      );
    }

    return ListView.separated(
      itemCount: products.length,
      separatorBuilder: (_, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = products[index];
        return _buildProductDemandCard(item, index + 1);
      },
    );
  }

  Widget _buildProductDemandCard(ProductDemandItemModel item, int rank) {
    Color trendColor;
    IconData trendIcon;

    switch (item.trend) {
      case DemandTrend.highDemand:
        trendColor = Colors.red.shade700;
        trendIcon = Icons.local_fire_department;
        break;
      case DemandTrend.rising:
        trendColor = Colors.green.shade700;
        trendIcon = Icons.trending_up;
        break;
      case DemandTrend.normal:
        trendColor = Colors.blue.shade700;
        trendIcon = Icons.remove;
        break;
      case DemandTrend.falling:
        trendColor = Colors.grey.shade600;
        trendIcon = Icons.trending_down;
        break;
    }

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rank Number
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: rank <= 3 ? Colors.amber.shade100 : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Text(
                '#$rank',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: rank <= 3 ? Colors.amber.shade900 : Colors.black54,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.categoryName,
                    style: const TextStyle(fontSize: 11, color: Colors.black45),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      // In Catalog Status
                      _buildBadge(
                        label: item.inShopCatalog ? 'In Catalog' : 'Not Stocked',
                        color: item.inShopCatalog ? Colors.green.shade800 : Colors.grey.shade700,
                        bg: item.inShopCatalog ? Colors.green.shade50 : Colors.grey.shade100,
                      ),
                      // Trend badge
                      _buildBadge(
                        label: item.trend.label,
                        color: trendColor,
                        bg: trendColor.withOpacity(0.08),
                        icon: trendIcon,
                      ),
                      // Zone
                      _buildBadge(
                        label: item.topZone,
                        color: Colors.indigo.shade700,
                        bg: Colors.indigo.shade50,
                      ),
                      // Growth percentage if available
                      if (item.percentageGrowth != null)
                        _buildBadge(
                          label: '${item.percentageGrowth! >= 0 ? '+' : ''}${item.percentageGrowth!.toStringAsFixed(0)}%',
                          color: item.percentageGrowth! >= 0 ? Colors.green.shade800 : Colors.red.shade800,
                          bg: item.percentageGrowth! >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                        ),
                    ],
                  ),
                  if (item.lowDataWarning) ...[
                    const SizedBox(height: 4),
                    const Text(
                      '• Limited local signals — trend is developing',
                      style: TextStyle(fontSize: 10, color: Colors.black45, fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),

            // Demand Signals Count & CTA
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${item.totalSignals}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const Text(
                  'signals',
                  style: TextStyle(fontSize: 10, color: Colors.black45),
                ),
                const SizedBox(height: 8),
                if (!item.inShopCatalog)
                  InkWell(
                    onTap: () {
                      context.push('/shop/products/add?name=${Uri.encodeComponent(item.productName)}');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 12, color: Colors.white),
                          SizedBox(width: 2),
                          Text('Add', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
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
  }

  // ═══════════════════════════════════════════════════════════════════
  // Tab 3: Concentric Demand Zones
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildDemandZonesTab(CustomerDemandState state) {
    final zones = state.dashboard?.demandZones ?? [];

    if (zones.isEmpty) {
      return const Center(
        child: Text('No zone distribution data available.', style: TextStyle(color: Colors.black54)),
      );
    }

    return ListView.separated(
      itemCount: zones.length,
      separatorBuilder: (_, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final zone = zones[index];
        return _buildZoneCard(zone);
      },
    );
  }

  Widget _buildZoneCard(DemandZoneModel zone) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.radar, size: 18, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      zone.zoneLabel,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                Text(
                  '${zone.demandSharePercentage.toStringAsFixed(0)}% of demand',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (zone.demandSharePercentage / 100.0).clamp(0.0, 1.0),
                backgroundColor: Colors.grey.shade200,
                color: AppColors.primary,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${zone.totalEvents} interactions',
                  style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                if (zone.topSearchTerms.isNotEmpty) ...[
                  const Text('Top searches: ', style: TextStyle(fontSize: 11, color: Colors.black45)),
                  Text(
                    zone.topSearchTerms.join(', '),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildBadge({
    required String label,
    required Color color,
    required Color bg,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionUpgradeBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 28),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unlock Full Demand Intelligence',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                SizedBox(height: 2),
                Text(
                  'Upgrade to Starter or Business to see unlimited catalog gaps, 10km zones, and competitor pricing trends.',
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => context.push('/shop/settings'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.white,
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('Upgrade', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
