import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../location_deals_models.dart';
import '../nearby_shop_detail_screen.dart';

/// Interactive Radar / Map View of Nearby Grocery Shops (Section 22).
/// Displays radial distances, shop pins, and an interactive shop details preview card with directions.
class ShopRadarMapView extends StatefulWidget {
  final List<NearbyShop> shops;
  final double radiusKm;
  final String locationLabel;

  const ShopRadarMapView({
    super.key,
    required this.shops,
    this.radiusKm = 5.0,
    required this.locationLabel,
  });

  @override
  State<ShopRadarMapView> createState() => _ShopRadarMapViewState();
}

class _ShopRadarMapViewState extends State<ShopRadarMapView> {
  NearbyShop? _selectedShop;

  @override
  void initState() {
    super.initState();
    if (widget.shops.isNotEmpty) {
      _selectedShop = widget.shops.first;
    }
  }

  void _launchDirections(NearbyShop shop) async {
    final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${shop.latitude},${shop.longitude}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.shops.isEmpty) {
      return Container(
        height: 320,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_off_rounded, size: 40, color: Color(0xFF9CA3AF)),
              SizedBox(height: 12),
              Text(
                'No grocery shops found within selected radius.',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // 1. Interactive Visual Radar Canvas
        Container(
          height: 300,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFBBF7D0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Radar Rings & Grid
                CustomPaint(
                  size: const Size(double.infinity, 300),
                  painter: _RadarCanvasPainter(radiusKm: widget.radiusKm),
                ),

                // Center Pin: User's location
                const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.my_location_rounded, color: Color(0xFF10B981), size: 26),
                      SizedBox(height: 2),
                      Text(
                        'You',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF065F46),
                        ),
                      ),
                    ],
                  ),
                ),

                // Shop Pins distributed radially
                ..._buildShopPins(context),

                // Top Location Label Badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFD1FAE5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.radar_rounded, size: 14, color: Color(0xFF10B981)),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.shops.length} Shops near ${widget.locationLabel}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF065F46),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // 2. Selected Shop Bottom Floating Card
        if (_selectedShop != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.store_rounded, color: Color(0xFF10B981), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedShop!.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                          Text(
                            '${_selectedShop!.shopType} • ${_selectedShop!.distanceLabel}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
                        const SizedBox(width: 2),
                        Text(
                          '${_selectedShop!.rating}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      '${_selectedShop!.availableDealsCount} verified deals in stock',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _selectedShop!.isOpen ? 'Open Now' : 'Closed',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _selectedShop!.isOpen ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _launchDirections(_selectedShop!),
                        icon: const Icon(Icons.directions_rounded, size: 16),
                        label: const Text('Directions'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF374151),
                          side: const BorderSide(color: Color(0xFFD1D5DB)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => NearbyShopDetailScreen(shop: _selectedShop!),
                            ),
                          );
                        },
                        icon: const Icon(Icons.local_offer_rounded, size: 16),
                        label: const Text('View Deals'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  List<Widget> _buildShopPins(BuildContext context) {
    List<Widget> pins = [];
    final double maxRadiusKm = widget.radiusKm > 0 ? widget.radiusKm : 5.0;

    for (int i = 0; i < widget.shops.length; i++) {
      final shop = widget.shops[i];
      final isSelected = _selectedShop?.id == shop.id;

      // Radial distribution around center
      double distanceRatio = (shop.distanceKm / maxRadiusKm).clamp(0.2, 0.88);
      double angle = (2 * math.pi / widget.shops.length) * i - (math.pi / 2);

      // Convert polar to cartesian centered at (150, 150)
      double cx = 150 + (115 * distanceRatio) * math.cos(angle);
      double cy = 150 + (115 * distanceRatio) * math.sin(angle);

      pins.add(
        Positioned(
          left: cx - 18,
          top: cy - 18,
          child: GestureDetector(
            onTap: () => setState(() => _selectedShop = shop),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF10B981) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : const Color(0xFF10B981),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isSelected ? const Color(0xFF10B981) : Colors.black).withValues(alpha: 0.25),
                    blurRadius: isSelected ? 8 : 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.store_rounded,
                size: isSelected ? 20 : 16,
                color: isSelected ? Colors.white : const Color(0xFF10B981),
              ),
            ),
          ),
        ),
      );
    }

    return pins;
  }
}

class _RadarCanvasPainter extends CustomPainter {
  final double radiusKm;

  _RadarCanvasPainter({required this.radiusKm});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paintRing = Paint()
      ..color = const Color(0xFF86EFAC).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final paintCross = Paint()
      ..color = const Color(0xFF86EFAC).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Cross lines
    canvas.drawLine(Offset(center.dx, 15), Offset(center.dx, size.height - 15), paintCross);
    canvas.drawLine(Offset(15, center.dy), Offset(size.width - 15, center.dy), paintCross);

    // Concentric Radar Rings
    const List<double> ringFractions = [0.3, 0.6, 0.9];
    for (double f in ringFractions) {
      double r = 120 * f;
      canvas.drawCircle(center, r, paintRing);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
