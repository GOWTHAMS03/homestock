import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homestock/core/location/location_controller.dart';
import 'package:homestock/core/location/location_models.dart';
import 'package:homestock/core/location/location_state.dart';
import 'package:homestock/core/theme/app_theme.dart';
import 'package:homestock/features/smart_shopping/location_deals_controller.dart';
import 'package:homestock/features/smart_shopping/location_deals_models.dart';
import 'package:homestock/features/smart_shopping/location_deals_repository.dart';
import 'package:homestock/features/smart_shopping/location_service.dart' show UserLocationContext;
import 'package:homestock/features/smart_shopping/nearby_grocery_shops_screen.dart';

class FakeLocationDealsRepository implements LocationDealsRepository {
  final List<NearbyShop> stubbedShops;

  FakeLocationDealsRepository({this.stubbedShops = const []});

  @override
  Future<List<NearbyShop>> getNearbyShops({
    required double latitude,
    required double longitude,
    double radiusKm = 2.0,
    bool forceRefresh = false,
  }) async {
    return stubbedShops;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleLiveShops = [
    const NearbyShop(
      id: 'shop-1',
      osmId: 'node:101',
      name: 'Sri Lakshmi Stores',
      shopType: 'GROCERY',
      address: 'Main Bazaar Road, Mettur',
      area: 'Mettur Dam',
      city: 'Mettur',
      postalCode: '636401',
      latitude: 11.7968,
      longitude: 77.8013,
      distanceMeters: 650,
      distanceKm: 0.65,
      distanceLabel: '650 m',
      rating: 4.5,
      reviewCount: 24,
      openingHours: '8:00 AM - 9:30 PM',
      isOpen: true,
      isVerified: true,
      availableDealsCount: 3,
      source: 'OpenStreetMap',
      attribution: 'Data © OpenStreetMap contributors, ODbL',
      isOfflineCache: false,
    ),
    const NearbyShop(
      id: 'shop-2',
      osmId: 'way:202',
      name: 'Daily Fresh Supermarket',
      shopType: 'SUPERMARKET',
      address: 'Near Clock Tower, Mettur',
      area: 'Mettur',
      city: 'Mettur',
      postalCode: '636401',
      latitude: 11.7990,
      longitude: 77.8030,
      distanceMeters: 1200,
      distanceKm: 1.2,
      distanceLabel: '1.2 km',
      rating: 4.2,
      reviewCount: 15,
      openingHours: '7:30 AM - 10:00 PM',
      isOpen: true,
      isVerified: false,
      availableDealsCount: 0,
      source: 'OpenStreetMap',
      attribution: 'Data © OpenStreetMap contributors, ODbL',
      isOfflineCache: false,
    ),
  ];

  Widget createWidgetUnderTest({
    required LocationState locationState,
    required LocationDealsState dealsState,
    List<NearbyShop>? customShops,
  }) {
    return ProviderScope(
      overrides: [
        locationControllerProvider.overrideWith((ref) => LocationController(
              ref.read(locationServiceProvider),
              initialState: locationState,
            )),
        locationDealsControllerProvider.overrideWith((ref) {
          final repo = FakeLocationDealsRepository(stubbedShops: customShops ?? sampleLiveShops);
          final controller = LocationDealsController(
            repo,
            initialLocation: dealsState.location,
          );
          return controller;
        }),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const NearbyGroceryShopsScreen(),
      ),
    );
  }

  testWidgets('NearbyGroceryShopsScreen renders initial permission prompt card when not yet requested',
      (tester) async {
    const unrequestedLoc = LocationState(
      status: LocationStateEnum.LOCATION_PERMISSION_NOT_REQUESTED,
    );

    const unresolvedDealsState = LocationDealsState(
      location: UserLocationContext.unresolved,
      nearbyShops: [],
    );

    await tester.pumpWidget(createWidgetUnderTest(
      locationState: unrequestedLoc,
      dealsState: unresolvedDealsState,
      customShops: [],
    ));
    await tester.pumpAndSettle();

    expect(find.text('Nearby Grocery Shops'), findsOneWidget);
    expect(find.text('Find Grocery Shops Near You'), findsOneWidget);
    expect(
        find.text('Allow HomeStock to access your location to find nearby grocery stores and supermarkets.'),
        findsOneWidget);
    expect(find.text('Allow Location'), findsOneWidget);
    expect(find.text('Not Now'), findsOneWidget);
  });

  testWidgets('NearbyGroceryShopsScreen renders list of shops sorted by distance with Directions and OSM attribution',
      (tester) async {
    final readyLoc = LocationState(
      status: LocationStateEnum.LOCATION_READY,
      currentLocation: LocationResult(
        latitude: 11.7968,
        longitude: 77.8013,
        accuracyMeters: 12.0,
        timestamp: DateTime.now(),
        approximateArea: 'Mettur Dam',
        city: 'Mettur',
      ),
    );

    const readyDealsState = LocationDealsState(
      location: UserLocationContext(
        latitude: 11.7968,
        longitude: 77.8013,
        approximateArea: 'Mettur Dam',
        city: 'Mettur',
      ),
      nearbyShops: [],
    );

    await tester.pumpWidget(createWidgetUnderTest(
      locationState: readyLoc,
      dealsState: readyDealsState,
      customShops: sampleLiveShops,
    ));
    await tester.pumpAndSettle();

    // Verify shops appear
    expect(find.text('Sri Lakshmi Stores'), findsOneWidget);
    expect(find.text('650 m'), findsOneWidget);
    expect(find.text('Daily Fresh Supermarket'), findsOneWidget);
    expect(find.text('1.2 km'), findsOneWidget);

    // Verify directions action
    expect(find.text('Directions'), findsNWidgets(2));

    // Verify OpenStreetMap attribution banner
    await tester.scrollUntilVisible(
      find.text('Shop data © OpenStreetMap contributors (ODbL)'),
      100,
    );
    expect(find.text('Shop data © OpenStreetMap contributors (ODbL)'), findsOneWidget);

    // Verify radius chips
    expect(find.text('2 km'), findsOneWidget);
    expect(find.text('5 km'), findsOneWidget);
    expect(find.text('10 km'), findsOneWidget);
  });

  testWidgets('NearbyGroceryShopsScreen renders offline cache banner when data is from cache',
      (tester) async {
    final offlineShops = [
      sampleLiveShops[0].copyWith(isOfflineCache: true),
    ];

    final readyLoc = LocationState(
      status: LocationStateEnum.LOCATION_READY,
      currentLocation: LocationResult(
        latitude: 11.7968,
        longitude: 77.8013,
        accuracyMeters: 12.0,
        timestamp: DateTime.now(),
        approximateArea: 'Mettur Dam',
        city: 'Mettur',
      ),
    );

    const readyDealsState = LocationDealsState(
      location: UserLocationContext(
        latitude: 11.7968,
        longitude: 77.8013,
        approximateArea: 'Mettur Dam',
        city: 'Mettur',
      ),
      nearbyShops: [],
    );

    await tester.pumpWidget(createWidgetUnderTest(
      locationState: readyLoc,
      dealsState: readyDealsState,
      customShops: offlineShops,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Showing recently found shops (Offline mode)'), findsOneWidget);
    expect(find.text('Sri Lakshmi Stores'), findsOneWidget);
  });

  testWidgets('NearbyGroceryShopsScreen renders empty state when no shops within radius and allows 5km expansion',
      (tester) async {
    final readyLoc = LocationState(
      status: LocationStateEnum.LOCATION_READY,
      currentLocation: LocationResult(
        latitude: 11.7968,
        longitude: 77.8013,
        accuracyMeters: 12.0,
        timestamp: DateTime.now(),
        approximateArea: 'Mettur Dam',
        city: 'Mettur',
      ),
    );

    const readyDealsState = LocationDealsState(
      location: UserLocationContext(
        latitude: 11.7968,
        longitude: 77.8013,
        approximateArea: 'Mettur Dam',
        city: 'Mettur',
      ),
      nearbyShops: [],
    );

    await tester.pumpWidget(createWidgetUnderTest(
      locationState: readyLoc,
      dealsState: readyDealsState,
      customShops: [], // Empty list
    ));
    await tester.pumpAndSettle();

    expect(find.text('No grocery shops found nearby.'), findsOneWidget);
    expect(find.text('Search 5 km Area'), findsOneWidget);

    // Tap Search 5 km Area
    await tester.tap(find.text('Search 5 km Area'));
    await tester.pumpAndSettle();
  });
}
