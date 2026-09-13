import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/widgets/homestock/homestock_app_bar.dart';
import 'location_deals_controller.dart';
import 'location_deals_models.dart';

/// Screen displaying a physical retail grocery store, confirmed items with prices,
/// unconfirmed items with "Price unavailable", and turn-by-turn navigation.
class NearbyShopDetailScreen extends ConsumerStatefulWidget {
  final NearbyShop? shop;
  final String? shopId;

  const NearbyShopDetailScreen({super.key, this.shop, this.shopId})
      : assert(shop != null || shopId != null, 'Either shop or shopId must be provided');

  @override
  ConsumerState<NearbyShopDetailScreen> createState() => _NearbyShopDetailScreenState();
}

class _NearbyShopDetailScreenState extends ConsumerState<NearbyShopDetailScreen> {
  bool _isLoading = true;
  NearbyShop? _shop;
  List<ShopDeal> _deals = [];

  @override
  void initState() {
    super.initState();
    _shop = widget.shop;
    _loadShopDeals();
  }

  Future<void> _loadShopDeals() async {
    final repo = ref.read(locationDealsRepositoryProvider);
    final targetId = widget.shop?.id ?? widget.shopId!;
    final result = await repo.getShopDetailsAndDeals(targetId);
    if (mounted) {
      setState(() {
        if (_shop == null && result['shop'] != null) {
          _shop = result['shop'] as NearbyShop;
        }
        _deals = result['confirmedDeals'] as List<ShopDeal>? ?? [];
        _isLoading = false;
      });
    }
  }

  void _launchDirections() async {
    if (_shop == null) return;
    final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${_shop!.latitude},${_shop!.longitude}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shop = _shop;

    if (shop == null && _isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: const HomeStockAppBar(title: 'Loading Shop...'),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF10B981))),
      );
    }

    if (shop == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: const HomeStockAppBar(title: 'Shop Details'),
        body: const Center(child: Text('Store details could not be found.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: HomeStockAppBar(
        title: shop.name,
        subtitle: '${shop.shopType} • ${shop.distanceLabel}',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. Store Header Info Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
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
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  shop.shopType,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
                              const SizedBox(width: 3),
                              Text(
                                '${shop.rating}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              Text(
                                ' (${shop.reviewCount})',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        shop.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${shop.address}, ${shop.area}, ${shop.city} ${shop.postalCode}',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 15,
                            color: shop.isOpen ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            shop.isOpen ? 'Open • ${shop.openingHours}' : 'Closed',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: shop.isOpen ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _launchDirections,
                          icon: const Icon(Icons.directions_rounded, size: 18),
                          label: Text('Get Directions (${shop.distanceLabel})'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF10B981),
                            side: const BorderSide(color: Color(0xFF10B981)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Verified Available Products
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 18),
                    const SizedBox(width: 6),
                    const Text(
                      'Verified Products & Prices',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_deals.length} items',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (_deals.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: const Center(
                      child: Text(
                        'No product prices currently verified for this store.',
                        style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                      ),
                    ),
                  )
                else
                  ..._deals.map((deal) => _buildDealCard(deal)),

                const SizedBox(height: 20),

                // 3. Unverified / Unknown Products Warning Note (Rule: Shop Presence != Availability)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Unconfirmed Items: Price Unavailable',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'HomeStock never invents prices. Any grocery item not shown above is not yet verified in this shop\'s stock.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF78350F), height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _buildDealCard(ShopDeal deal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.shopping_basket_rounded, color: Color(0xFF10B981), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deal.productName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${deal.brand ?? ''} • ${deal.packageSize != null ? deal.packageSize!.toStringAsFixed(0) : ''} ${deal.unit ?? ''}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        deal.freshnessLabel,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF059669)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${deal.price.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              if (deal.pricePerUnitLabel != null)
                Text(
                  deal.pricePerUnitLabel!,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
