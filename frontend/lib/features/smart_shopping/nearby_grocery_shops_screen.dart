import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/location/location_controller.dart';
import '../../core/location/location_state.dart';
import '../../core/location/widgets/location_status_banner.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/homestock/homestock_app_bar.dart';
import '../../core/widgets/skeleton_loader.dart';
import 'location_deals_controller.dart';
import 'location_deals_models.dart';
import 'location_service.dart' show UserLocationContext;
import 'nearby_shop_detail_screen.dart';
import 'widgets/manual_location_dialog.dart';

/// Screen for completely free nearby grocery shop discovery using OpenStreetMap (Overpass API).
/// Calm, minimal design adhering to HomeStock's design language.
/// Strictly enforces: Zero fake ratings, zero fake prices, nearest-first sorting,
/// graceful permission denial, offline cached shop indicators, and turn-by-turn directions.
class NearbyGroceryShopsScreen extends ConsumerStatefulWidget {
  const NearbyGroceryShopsScreen({super.key});

  @override
  ConsumerState<NearbyGroceryShopsScreen> createState() => _NearbyGroceryShopsScreenState();
}

class _NearbyGroceryShopsScreenState extends ConsumerState<NearbyGroceryShopsScreen> {
  double _selectedRadiusKm = 2.0;
  bool _dismissedInitialPrompt = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  void _initialize() {
    final coreLoc = ref.read(locationControllerProvider);
    if (coreLoc.status.isReady && coreLoc.currentLocation != null) {
      final loc = coreLoc.currentLocation!;
      ref.read(locationDealsControllerProvider.notifier).setLocation(
            UserLocationContext(
              latitude: loc.latitude,
              longitude: loc.longitude,
              approximateArea: loc.approximateArea,
              city: loc.city,
              postalCode: loc.postalCode,
              isManual: loc.isManual,
            ),
          );
    }
  }

  Future<void> _handlePermissionRequest() async {
    final coreNotifier = ref.read(locationControllerProvider.notifier);
    final granted = await coreNotifier.requestPermissionAndAcquire();
    if (granted) {
      final loc = ref.read(locationControllerProvider).currentLocation;
      if (loc != null) {
        ref.read(locationDealsControllerProvider.notifier).setLocation(
              UserLocationContext(
                latitude: loc.latitude,
                longitude: loc.longitude,
                approximateArea: loc.approximateArea,
                city: loc.city,
                postalCode: loc.postalCode,
                isManual: loc.isManual,
              ),
            );
      }
    }
  }

  Future<void> _openManualLocationDialog() async {
    final locDealsState = ref.read(locationDealsControllerProvider);
    final locDealsNotifier = ref.read(locationDealsControllerProvider.notifier);
    final coreLocNotifier = ref.read(locationControllerProvider.notifier);

    final selected = await showDialog<UserLocationContext>(
      context: context,
      builder: (_) => ManualLocationDialog(
        currentContext: locDealsState.location,
        onSearchAreas: (q) => locDealsNotifier.searchAreas(q),
      ),
    );

    if (selected != null) {
      locDealsNotifier.setLocation(selected);
      coreLocNotifier.setManualLocation(selected.toLocationResult());
    }
  }

  Future<void> _launchDirections(NearbyShop shop) async {
    // Try geo: URI scheme first
    final geoUri = Uri.parse(
        'geo:${shop.latitude},${shop.longitude}?q=${Uri.encodeComponent(shop.name)}');

    // Fallback to web navigation
    final webUri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${shop.latitude},${shop.longitude}');

    try {
      if (await canLaunchUrl(geoUri)) {
        await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open map navigation application.')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open map navigation application.')),
        );
      }
    }
  }

  void _onRadiusSelected(double radiusKm) {
    setState(() => _selectedRadiusKm = radiusKm);
    ref.read(locationDealsControllerProvider.notifier).setRadius(radiusKm);
  }

  @override
  Widget build(BuildContext context) {
    final coreLocState = ref.watch(locationControllerProvider);
    final coreLocNotifier = ref.read(locationControllerProvider.notifier);
    final locDealsState = ref.watch(locationDealsControllerProvider);
    final locDealsNotifier = ref.read(locationDealsControllerProvider.notifier);
    final hsColors = context.hsColors;

    final bool isPermissionNotRequested =
        coreLocState.status == LocationStateEnum.LOCATION_PERMISSION_NOT_REQUESTED &&
            !_dismissedInitialPrompt &&
            !locDealsState.location.isResolved;

    final List<NearbyShop> shops = locDealsState.nearbyShops;
    final bool isOfflineData = shops.isNotEmpty && shops.any((s) => s.isOfflineCache);

    return Scaffold(
      backgroundColor: hsColors.background,
      appBar: const HomeStockAppBar(
        title: 'Nearby Grocery Shops',
        subtitle: 'Find physical grocery stores near you',
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF10B981),
          onRefresh: () async {
            if (coreLocState.status.isReady) {
              await coreLocNotifier.refreshLocation();
            }
            await locDealsNotifier.loadNearbyShops(forceRefresh: true);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // 1. Top Location Header Bar
              _buildLocationHeader(
                locDealsState: locDealsState,
                coreLocState: coreLocState,
                coreLocNotifier: coreLocNotifier,
                locDealsNotifier: locDealsNotifier,
                hsColors: hsColors,
              ),

              const SizedBox(height: 12),

              // 2. Radius Filter Chips (2 km, 5 km, 10 km)
              _buildRadiusSelector(hsColors),

              const SizedBox(height: 14),

              // 3. Status / Permission Warning Banners (if any)
              if (coreLocState.status != LocationStateEnum.LOCATION_READY &&
                  coreLocState.status != LocationStateEnum.MANUAL_LOCATION_SELECTED &&
                  coreLocState.status != LocationStateEnum.LOCATION_PERMISSION_NOT_REQUESTED)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: LocationStatusBanner(
                    state: coreLocState,
                    onTryAgain: () async {
                      final granted = await coreLocNotifier.requestPermissionAndAcquire();
                      if (granted) {
                        final loc = ref.read(locationControllerProvider).currentLocation;
                        if (loc != null) {
                          locDealsNotifier.setLocation(UserLocationContext(
                            latitude: loc.latitude,
                            longitude: loc.longitude,
                            approximateArea: loc.approximateArea,
                            city: loc.city,
                            postalCode: loc.postalCode,
                            isManual: loc.isManual,
                          ));
                        }
                      }
                    },
                    onOpenSettings: () => coreLocNotifier.openAppSettings(),
                    onOpenLocationSettings: () => coreLocNotifier.openLocationSettings(),
                    onChooseManually: _openManualLocationDialog,
                  ),
                ),

              // 4. Initial Permission Explanation Prompt Card (Prompt #2 & #23)
              if (isPermissionNotRequested)
                _buildPermissionPromptCard(hsColors),

              // 5. Offline Cache Notification Banner (Prompt #14 & #16)
              if (isOfflineData)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildOfflineCacheBanner(),
                ),

              // 6. Loading State (Skeleton Loaders)
              if (locDealsState.isLoading && shops.isEmpty)
                _buildLoadingSkeletons()

              // 7. Error State (Network failure without cache)
              else if (locDealsState.errorMessage != null && shops.isEmpty)
                _buildErrorCard(locDealsNotifier, hsColors)

              // 8. Empty State (No shops within selected radius)
              else if (shops.isEmpty && !isPermissionNotRequested)
                _buildEmptyState(locDealsNotifier, hsColors)

              // 9. Success List of Shops
              else if (shops.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 2),
                  child: Row(
                    children: [
                      Text(
                        'Found ${shops.length} grocery ${shops.length == 1 ? 'store' : 'stores'}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Sorted nearest first',
                        style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                      ),
                    ],
                  ),
                ),
                ...shops.map((shop) => _buildShopCard(shop, hsColors)),
                const SizedBox(height: 16),
                _buildOsmAttribution(),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // --- Sub-Widgets ---

  Widget _buildLocationHeader({
    required LocationDealsState locDealsState,
    required LocationState coreLocState,
    required LocationController coreLocNotifier,
    required LocationDealsController locDealsNotifier,
    required HomeStockThemeColors hsColors,
  }) {
    final locationLabel = locDealsState.location.isResolved
        ? locDealsState.location.displayLabel
        : 'Select Location';

    final sourceLabel = locDealsState.location.isManual
        ? 'Selected location'
        : (coreLocState.currentLocation?.freshnessLabel ?? 'GPS Location');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_on_rounded, color: Color(0xFF10B981), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locationLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  sourceLabel,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          // Subtle inline refresh button
          IconButton(
            tooltip: 'Refresh shops',
            icon: coreLocState.isRefreshing || locDealsState.isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)),
                  )
                : const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFF6B7280)),
            onPressed: () async {
              if (coreLocState.status.isReady) {
                await coreLocNotifier.refreshLocation();
              }
              await locDealsNotifier.loadNearbyShops(forceRefresh: true);
            },
          ),
          // Change Location Button
          TextButton(
            onPressed: _openManualLocationDialog,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: const Color(0xFF10B981),
            ),
            child: const Text(
              'Change',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadiusSelector(HomeStockThemeColors hsColors) {
    final radii = [
      {'label': '2 km', 'value': 2.0},
      {'label': '5 km', 'value': 5.0},
      {'label': '10 km', 'value': 10.0},
    ];

    return Row(
      children: [
        const Text(
          'Search radius:',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
        ),
        const SizedBox(width: 8),
        ...radii.map((r) {
          final isSelected = (_selectedRadiusKm == r['value']);
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: Text(r['label'] as String),
              selected: isSelected,
              showCheckmark: false,
              selectedColor: const Color(0xFF10B981).withValues(alpha: 0.15),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFF047857) : const Color(0xFF4B5563),
              ),
              side: BorderSide(
                color: isSelected ? const Color(0xFF10B981) : const Color(0xFFE5E7EB),
                width: isSelected ? 1.5 : 1.0,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              onSelected: (_) => _onRadiusSelected(r['value'] as double),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPermissionPromptCard(HomeStockThemeColors hsColors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.storefront_rounded, color: Color(0xFF10B981), size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Find Grocery Shops Near You',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Allow HomeStock to access your location to find nearby grocery stores and supermarkets.',
            style: TextStyle(fontSize: 13, color: Color(0xFF4B5563), height: 1.4),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _handlePermissionRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Allow Location', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () {
                  setState(() => _dismissedInitialPrompt = true);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6B7280),
                  side: const BorderSide(color: Color(0xFFD1D5DB)),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Not Now'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineCacheBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Row(
        children: [
          Icon(Icons.cloud_off_rounded, color: Color(0xFFD97706), size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Showing recently found shops (Offline mode)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeletons() {
    return Column(
      children: List.generate(
        4,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonLoader(width: 160, height: 16),
              SizedBox(height: 8),
              SkeletonLoader(width: 220, height: 12),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonLoader(width: 60, height: 12),
                  SkeletonLoader(width: 90, height: 28),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(LocationDealsController notifier, HomeStockThemeColors hsColors) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          const Icon(Icons.wifi_off_rounded, size: 40, color: Color(0xFF9CA3AF)),
          const SizedBox(height: 12),
          const Text(
            "Couldn't load nearby shops.",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Please check your internet connection and try again.',
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => notifier.loadNearbyShops(forceRefresh: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(LocationDealsController notifier, HomeStockThemeColors hsColors) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded, size: 44, color: Color(0xFF9CA3AF)),
          const SizedBox(height: 12),
          const Text(
            'No grocery shops found nearby.',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 6),
          Text(
            'No shops found within $_selectedRadiusKm km of your location. Try searching a wider area.',
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () => _onRadiusSelected(5.0),
            icon: const Icon(Icons.radar_rounded, size: 18),
            label: const Text('Search 5 km Area', style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopCard(NearbyShop shop, HomeStockThemeColors hsColors) {
    IconData categoryIcon = Icons.storefront_rounded;
    Color iconColor = const Color(0xFF10B981);

    final upperType = shop.shopType.toUpperCase();
    if (upperType == 'SUPERMARKET' || upperType == 'HYPERMARKET') {
      categoryIcon = Icons.shopping_cart_rounded;
      iconColor = const Color(0xFF2563EB);
    } else if (upperType == 'PROVISION' || upperType == 'CONVENIENCE') {
      categoryIcon = Icons.inventory_2_rounded;
      iconColor = const Color(0xFFF59E0B);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => NearbyShopDetailScreen(shop: shop)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Shop Icon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(categoryIcon, color: iconColor, size: 22),
                    ),
                    const SizedBox(width: 12),

                    // Shop Name & Category
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shop.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  shop.shopType,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF4B5563),
                                  ),
                                ),
                              ),
                              if (shop.availableDealsCount > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${shop.availableDealsCount} verified deals',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF059669),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Distance Badge (Prominent)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        shop.distanceLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ),
                  ],
                ),

                // Address Subtitle (if available)
                if (shop.address.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Text(
                      shop.address,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],

                // Opening hours (if available)
                if (shop.openingHours.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF9CA3AF)),
                      const SizedBox(width: 4),
                      Text(
                        shop.openingHours,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF3F4F6)),
                const SizedBox(height: 8),

                // Action Row: Directions Button + View Catalog CTA
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tap to view details & verified deals',
                      style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _launchDirections(shop),
                      icon: const Icon(Icons.directions_rounded, size: 16),
                      label: const Text('Directions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF10B981),
                        side: const BorderSide(color: Color(0xFF10B981)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOsmAttribution() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF9CA3AF)),
          SizedBox(width: 6),
          Text(
            'Shop data © OpenStreetMap contributors (ODbL)',
            style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }
}
