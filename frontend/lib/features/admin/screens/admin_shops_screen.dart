import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../controllers/admin_shop_controller.dart';
import '../../shop_owner/models/shop_models.dart';

class AdminShopsScreen extends ConsumerStatefulWidget {
  const AdminShopsScreen({super.key});

  @override
  ConsumerState<AdminShopsScreen> createState() => _AdminShopsScreenState();
}

class _AdminShopsScreenState extends ConsumerState<AdminShopsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _statuses = ['PENDING', 'VERIFIED', 'REJECTED', 'SUSPENDED'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statuses.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        ref.read(adminShopControllerProvider.notifier).loadShops(_statuses[_tabController.index]);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _promptReject(ShopProfileModel shop) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reject "${shop.name}"?'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(labelText: 'Reason for rejection', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(adminShopControllerProvider.notifier).rejectShop(shop.id, reason: reasonController.text.trim());
            },
            child: const Text('Reject Shop'),
          ),
        ],
      ),
    );
  }

  void _promptSuspend(ShopProfileModel shop) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Suspend "${shop.name}"?'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(labelText: 'Reason for suspension', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(adminShopControllerProvider.notifier).suspendShop(shop.id, reason: reasonController.text.trim());
            },
            child: const Text('Suspend Shop'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminShopControllerProvider);
    final shops = state.shops;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin — Shop Verification Portal'),
        backgroundColor: const Color(0xFF1E1B4B),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Verified'),
            Tab(text: 'Rejected'),
            Tab(text: 'Suspended'),
          ],
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : shops.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(
                        'No ${_statuses[_tabController.index].toLowerCase()} shops found',
                        style: const TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => ref.read(adminShopControllerProvider.notifier).loadShops(_statuses[_tabController.index]),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: shops.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final shop = shops[index];
                      return _buildShopCard(context, shop);
                    },
                  ),
                ),
    );
  }

  Widget _buildShopCard(BuildContext context, ShopProfileModel shop) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    shop.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                _statusPill(shop.verificationStatus),
              ],
            ),
            const SizedBox(height: 4),
            Text('Owner: ${shop.ownerName ?? "Unknown"} • ${shop.category ?? shop.shopType}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
            const SizedBox(height: 4),
            Text('${shop.address}, ${shop.city} ${shop.postalCode}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
            if (shop.phone != null) Text('Phone: ${shop.phone}', style: const TextStyle(fontSize: 12, color: Colors.black87)),
            if (shop.gstNumber != null) Text('GSTIN: ${shop.gstNumber}', style: const TextStyle(fontSize: 12, color: Colors.black87)),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (shop.verificationStatus == 'PENDING') ...[
                  OutlinedButton(
                    onPressed: () => _promptReject(shop),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Reject'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => ref.read(adminShopControllerProvider.notifier).verifyShop(shop.id),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    child: const Text('Approve & Verify'),
                  ),
                ] else if (shop.verificationStatus == 'VERIFIED') ...[
                  OutlinedButton(
                    onPressed: () => _promptSuspend(shop),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.orange),
                    child: const Text('Suspend Shop'),
                  ),
                ] else if (shop.verificationStatus == 'SUSPENDED') ...[
                  ElevatedButton(
                    onPressed: () => ref.read(adminShopControllerProvider.notifier).verifyShop(shop.id),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    child: const Text('Re-verify'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusPill(String status) {
    Color bg;
    Color fg;

    switch (status) {
      case 'VERIFIED':
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        break;
      case 'REJECTED':
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        break;
      case 'SUSPENDED':
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade700;
        break;
      default:
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg)),
    );
  }
}
