import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../controllers/discovery_controller.dart';

class ShopProfileScreen extends ConsumerStatefulWidget {
  final String shopId;

  const ShopProfileScreen({super.key, required this.shopId});

  @override
  ConsumerState<ShopProfileScreen> createState() => _ShopProfileScreenState();
}

class _ShopProfileScreenState extends ConsumerState<ShopProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(discoveryControllerProvider.notifier).loadShopDetails(widget.shopId);
    });
  }

  Future<void> _launchUrl(String uriString) async {
    final uri = Uri.parse(uriString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(discoveryControllerProvider);
    final shop = state.selectedShop;
    final products = state.selectedShopProducts;
    final deals = state.selectedShopDeals;

    if (state.isLoading && shop == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (shop == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Shop Profile')),
        body: const Center(child: Text('Shop details not found')),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Collapsible Header
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                shop.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF5B21B6), Color(0xFF7C3AED)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Icon(Icons.storefront_rounded, size: 72, color: Colors.white.withOpacity(0.3)),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Verification & Distance row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified, size: 14, color: Colors.green.shade700),
                            const SizedBox(width: 4),
                            Text(
                              'Verified Local Shop',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.green.shade700),
                            ),
                          ],
                        ),
                      ),
                      if (shop.distanceKm != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${shop.distanceKm!.toStringAsFixed(1)} km away',
                            style: TextStyle(fontSize: 11, color: Colors.blue.shade800, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Address & Hours
                  Text(shop.address, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                  if (shop.area.isNotEmpty || shop.city.isNotEmpty)
                    Text('${shop.area}, ${shop.city} ${shop.postalCode}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                  const SizedBox(height: 4),
                  if (shop.openingTime != null && shop.closingTime != null)
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: Colors.black45),
                        const SizedBox(width: 4),
                        Text(
                          'Open: ${shop.openingTime} - ${shop.closingTime}',
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  const SizedBox(height: AppSpacing.md),

                  // Contact action buttons
                  Row(
                    children: [
                      if (shop.phone != null && shop.phone!.isNotEmpty)
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.phone, size: 18),
                            label: const Text('Call'),
                            onPressed: () => _launchUrl('tel:${shop.phone}'),
                          ),
                        ),
                      if (shop.phone != null && shop.phone!.isNotEmpty && shop.whatsappNumber != null)
                        const SizedBox(width: 8),
                      if (shop.whatsappNumber != null && shop.whatsappNumber!.isNotEmpty)
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.chat, size: 18),
                            label: const Text('WhatsApp'),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white),
                            onPressed: () => _launchUrl('https://wa.me/${shop.whatsappNumber!.replaceAll(RegExp(r'[^0-9]'), '')}'),
                          ),
                        ),
                      const SizedBox(width: 8),
                      IconButton.outlined(
                        icon: const Icon(Icons.directions, color: AppColors.primary),
                        onPressed: () => _launchUrl('https://www.google.com/maps/search/?api=1&query=${shop.latitude},${shop.longitude}'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Deals section
                  if (deals.isNotEmpty) ...[
                    const Text('Special Offers & Deals', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      height: 110,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: deals.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final deal = deals[index];
                          return Container(
                            width: 200,
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${deal.discountPercent}% OFF',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade900, fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  deal.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text('₹${deal.offerPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Product catalog
                  Text('Available Products (${products.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: AppSpacing.sm),
                  if (products.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('No products listed in catalog yet', style: TextStyle(color: Colors.black54))),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: products.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary),
                          ),
                          title: Text(product.rawProductName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            product.availabilityStatus == 'AVAILABLE' ? 'In Stock' : 'Low Stock',
                            style: TextStyle(
                              fontSize: 12,
                              color: product.availabilityStatus == 'AVAILABLE' ? Colors.green : Colors.orange,
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${product.effectivePrice.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green),
                              ),
                              if (product.mrp != null && product.mrp! > product.price)
                                Text(
                                  '₹${product.mrp!.toStringAsFixed(2)}',
                                  style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.black45, fontSize: 12),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
