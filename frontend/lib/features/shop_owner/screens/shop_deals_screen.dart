import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../controllers/shop_owner_controller.dart';
import '../models/shop_models.dart';

class ShopDealsScreen extends ConsumerStatefulWidget {
  const ShopDealsScreen({super.key});

  @override
  ConsumerState<ShopDealsScreen> createState() => _ShopDealsScreenState();
}

class _ShopDealsScreenState extends ConsumerState<ShopDealsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shopOwnerControllerProvider.notifier).loadDeals();
    });
  }

  void _showCreateDealDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final origPriceController = TextEditingController();
    final offerPriceController = TextEditingController();
    String dealType = 'DISCOUNT';
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Create Promotional Deal'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Deal Title *', hintText: 'e.g. 20% Off on Fresh Milk', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Description (Optional)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String>(
                    value: dealType,
                    decoration: const InputDecoration(labelText: 'Deal Type', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'DISCOUNT', child: Text('Flat Discount')),
                      DropdownMenuItem(value: 'BOGO', child: Text('Buy 1 Get 1')),
                      DropdownMenuItem(value: 'COMBO', child: Text('Combo Offer')),
                      DropdownMenuItem(value: 'CLEARANCE', child: Text('Clearance Sale')),
                    ],
                    onChanged: (v) => setDialogState(() => dealType = v ?? 'DISCOUNT'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: origPriceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Original Price (₹) *', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TextField(
                          controller: offerPriceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Deal Price (₹) *', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text('${startDate.day}/${startDate.month}'),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: startDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 1)),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) setDialogState(() => startDate = picked);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('to'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text('${endDate.day}/${endDate.month}'),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: endDate,
                              firstDate: startDate,
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) setDialogState(() => endDate = picked);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                onPressed: () async {
                  if (titleController.text.trim().isEmpty ||
                      origPriceController.text.trim().isEmpty ||
                      offerPriceController.text.trim().isEmpty) {
                    return;
                  }
                  final orig = double.parse(origPriceController.text.trim());
                  final offer = double.parse(offerPriceController.text.trim());
                  final discountPct = orig > 0 ? (((orig - offer) / orig) * 100).round() : 0;

                  final data = {
                    'title': titleController.text.trim(),
                    'description': descController.text.trim().isEmpty ? null : descController.text.trim(),
                    'dealType': dealType,
                    'originalPrice': orig,
                    'offerPrice': offer,
                    'discountPercent': discountPct > 0 ? discountPct : 0,
                    'startDate': startDate.toUtc().toIso8601String(),
                    'endDate': endDate.toUtc().toIso8601String(),
                  };

                  Navigator.pop(ctx);
                  await ref.read(shopOwnerControllerProvider.notifier).createDeal(data);
                },
                child: const Text('Publish Deal'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shopOwnerControllerProvider);
    final deals = state.deals;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Promotional Deals'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(shopOwnerControllerProvider.notifier).loadDeals(),
          ),
        ],
      ),
      body: deals.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('No Active Deals Yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text(
                    'Promote special offers, discounts, or bundles to attract nearby shoppers.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _showCreateDealDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Create Your First Deal'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => ref.read(shopOwnerControllerProvider.notifier).loadDeals(),
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: deals.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final deal = deals[index];
                  return _buildDealCard(context, deal);
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDealDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Deal'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildDealCard(BuildContext context, ShopDealModel deal) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text(
                    '${deal.discountPercent}% OFF',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.orange.shade800),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(deal.dealType, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                  onPressed: () => ref.read(shopOwnerControllerProvider.notifier).deleteDeal(deal.id),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(deal.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            if (deal.description != null && deal.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(deal.description!, style: const TextStyle(color: Colors.black54, fontSize: 13)),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '₹${deal.offerPrice.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green),
                ),
                const SizedBox(width: 8),
                Text(
                  '₹${deal.originalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    decoration: TextDecoration.lineThrough,
                    color: Colors.black45,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
