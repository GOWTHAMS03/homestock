import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../controllers/shop_owner_controller.dart';
import '../models/shop_models.dart';

class ShopDashboardScreen extends ConsumerStatefulWidget {
  const ShopDashboardScreen({super.key});

  @override
  ConsumerState<ShopDashboardScreen> createState() => _ShopDashboardScreenState();
}

class _ShopDashboardScreenState extends ConsumerState<ShopDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shopOwnerControllerProvider.notifier).loadMyShop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shopOwnerControllerProvider);

    if (state.isLoading && state.shop == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.shop == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Shop Owner Portal')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.store_outlined, size: 72, color: Colors.grey),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'No Shop Registered Yet',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Register your physical retail store to manage products, pricing, deals, and get discovered by local customers.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton.icon(
                  onPressed: () => context.push('/shop/onboarding'),
                  icon: const Icon(Icons.add_business),
                  label: const Text('Register My Shop'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final shop = state.shop!;
    final dashboard = state.dashboard ?? const ShopDashboardModel();
    final subscription = state.subscription;

    return Scaffold(
      appBar: AppBar(
        title: Text(shop.name),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(shopOwnerControllerProvider.notifier).loadMyShop(),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/shop/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(shopOwnerControllerProvider.notifier).loadMyShop(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Verification status banner
              _buildVerificationBanner(shop),
              const SizedBox(height: AppSpacing.md),

              // Subscription & Quota Card
              _buildSubscriptionCard(context, shop, subscription),
              const SizedBox(height: AppSpacing.md),

              // KPI Metrics Grid
              _buildMetricsGrid(dashboard),
              const SizedBox(height: AppSpacing.lg),

              // Quick Actions
              const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.sm),
              _buildQuickActions(context),
              const SizedBox(height: AppSpacing.lg),

              // Local Demand Intelligence
              Row(
                children: [
                  const Icon(Icons.trending_up, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  const Text('Customer Demand Intelligence', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => context.push('/shop/demand'),
                    icon: const Icon(Icons.arrow_forward, size: 14),
                    label: const Text('Explore', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Understand what local households near your shop are actively searching for',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (dashboard.nearbyDemand.isNotEmpty)
                _buildDemandList(dashboard.nearbyDemand)
              else
                InkWell(
                  onTap: () => context.push('/shop/demand'),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.radar, color: AppColors.primary, size: 22),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'View real-time neighborhood demand signals, catalog gap alerts, and restock opportunities',
                            style: TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Colors.black45),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),

              // Popular Products in Shop
              if (dashboard.popularProducts.isNotEmpty) ...[
                const Text('Most Viewed in Your Catalog', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.sm),
                _buildPopularProductsList(dashboard.popularProducts),
                const SizedBox(height: AppSpacing.lg),
              ],

              // Attention Items
              if (dashboard.productsNeedingAttention.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    const Text('Needs Attention', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildAttentionList(dashboard.productsNeedingAttention),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.black54,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 1) context.push('/shop/products');
          if (index == 2) context.push('/shop/deals');
          if (index == 3) context.push('/shop/settings');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Products'),
          BottomNavigationBarItem(icon: Icon(Icons.local_offer), label: 'Deals'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildVerificationBanner(ShopProfileModel shop) {
    Color bg;
    Color border;
    IconData icon;
    String title;
    String desc;

    if (shop.isApproved) {
      bg = Colors.green.shade50;
      border = Colors.green.shade200;
      icon = Icons.verified;
      title = 'Verified Shop Partner';
      desc = 'Your physical store is verified and active on customer nearby discovery maps.';
    } else if (shop.isRejected) {
      bg = Colors.red.shade50;
      border = Colors.red.shade200;
      icon = Icons.error_outline;
      title = 'Verification Rejected';
      desc = 'Please review your shop details and contact support to re-verify.';
    } else if (shop.isSuspended) {
      bg = Colors.orange.shade50;
      border = Colors.orange.shade200;
      icon = Icons.pause_circle_outline;
      title = 'Shop Suspended';
      desc = 'Your shop is temporarily hidden from customer discovery.';
    } else {
      bg = Colors.amber.shade50;
      border = Colors.amber.shade200;
      icon = Icons.pending_outlined;
      title = 'Verification Pending';
      desc = 'Admin review is in progress. Your products and deals are saved and will go live upon approval.';
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: shop.isApproved ? Colors.green : shop.isRejected ? Colors.red : Colors.orange, size: 24),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 12, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(BuildContext context, ShopProfileModel shop, ShopSubscriptionModel? sub) {
    final max = sub?.maxProducts ?? shop.maxProducts;
    final current = shop.productCount;
    final pct = (current / (max > 0 ? max : 1)).clamp(0.0, 1.0);

    return Card(
      elevation: 1,
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${sub?.planDisplayName ?? shop.subscriptionPlan ?? "FREE"} PLAN',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('$current / $max products', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                  ],
                ),
                TextButton(
                  onPressed: () => context.push('/shop/settings'),
                  child: const Text('Upgrade Plan'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.grey.shade200,
              color: pct > 0.9 ? Colors.red : AppColors.primary,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(ShopDashboardModel dashboard) {
    return Row(
      children: [
        Expanded(child: _metricCard('Today\'s Views', '${dashboard.todayViews}', Icons.visibility, Colors.blue)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: _metricCard('Product Views', '${dashboard.productViews}', Icons.local_mall, Colors.purple)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: _metricCard('Active Deals', '${dashboard.activeDeals}', Icons.local_offer, Colors.green)),
      ],
    );
  }

  Widget _metricCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _actionButton(
                icon: Icons.add,
                label: 'Add Product',
                color: AppColors.primary,
                onTap: () => context.push('/shop/products/add'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _actionButton(
                icon: Icons.inventory,
                label: 'All Products',
                color: Colors.indigo,
                onTap: () => context.push('/shop/products'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _actionButton(
                icon: Icons.radar,
                label: 'Customer Demand',
                color: Colors.teal.shade700,
                onTap: () => context.push('/shop/demand'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _actionButton(
                icon: Icons.percent,
                label: 'New Deal',
                color: Colors.orange.shade800,
                onTap: () => context.push('/shop/deals'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildDemandList(List<DemandItem> items) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        return ActionChip(
          avatar: const CircleAvatar(
            backgroundColor: AppColors.primary,
            child: Icon(Icons.search, size: 12, color: Colors.white),
          ),
          label: Text('${item.searchTerm} (${item.searchCount})'),
          backgroundColor: AppColors.primaryContainer.withOpacity(0.5),
          onPressed: () => context.push('/shop/demand'),
        );
      }).toList(),
    );
  }

  Widget _buildPopularProductsList(List<PopularProductItem> items) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text('#${index + 1}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
            title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
            trailing: Text('${item.viewCount} views', style: const TextStyle(color: Colors.black54, fontSize: 13)),
          );
        },
      ),
    );
  }

  Widget _buildAttentionList(List<AttentionItem> items) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange.shade200),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            leading: const Icon(Icons.error_outline, color: Colors.orange),
            title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(item.reason, style: const TextStyle(fontSize: 12, color: Colors.red)),
            trailing: TextButton(
              onPressed: () => context.push('/shop/products'),
              child: const Text('Update'),
            ),
          );
        },
      ),
    );
  }
}
