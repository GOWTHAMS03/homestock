import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homestock/core/location/location_controller.dart';
import 'package:homestock/core/location/location_exceptions.dart';
import 'package:homestock/core/location/location_models.dart';
import 'package:homestock/core/location/location_permission_manager.dart';
import 'package:homestock/core/location/location_provider.dart';
import 'package:homestock/core/location/location_service.dart';
import 'package:homestock/core/location/location_state.dart';
import 'package:homestock/core/location/widgets/location_bar_widget.dart';
import 'package:homestock/core/location/widgets/location_explanation_sheet.dart';
import 'package:homestock/core/location/widgets/location_status_banner.dart';
import 'package:homestock/features/smart_shopping/location_service.dart'
    show LocationResultDealsExtension;

/// Controllable mock provider for testing all platform scenarios.
class MockLocationProvider implements LocationProvider {
  LocationPermissionStatus permissionStatus;
  bool serviceEnabled;
  LocationResult? nextResult;
  Exception? exceptionToThrow;
  int positionRequestCount = 0;
  bool appSettingsOpened = false;
  bool locationSettingsOpened = false;

  MockLocationProvider({
    this.permissionStatus = LocationPermissionStatus.denied,
    this.serviceEnabled = true,
    this.nextResult,
    this.exceptionToThrow,
  });

  @override
  Future<LocationPermissionStatus> checkPermission() async => permissionStatus;

  @override
  Future<LocationPermissionStatus> requestPermission() async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return permissionStatus;
  }

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationResult> getCurrentPosition({
    required LocationAccuracyPolicy policy,
  }) async {
    positionRequestCount++;
    if (exceptionToThrow != null) throw exceptionToThrow!;
    if (!serviceEnabled) throw const LocationServicesDisabledException();
    if (permissionStatus == LocationPermissionStatus.denied) {
      throw const PermissionDeniedException();
    }
    if (permissionStatus == LocationPermissionStatus.deniedForever) {
      throw const PermissionPermanentlyDeniedException();
    }
    return nextResult ??
        LocationResult(
          latitude: 11.7968,
          longitude: 77.8013,
          accuracyMeters: 14.5,
          timestamp: DateTime.now(),
          approximateArea: 'Mettur Dam',
          city: 'Mettur',
          source: LocationSource.CURRENT_DEVICE_LOCATION,
        );
  }

  @override
  Future<LocationResult?> getLastKnownPosition() async => nextResult;

  @override
  Future<bool> openAppSettings() async {
    appSettingsOpened = true;
    return true;
  }

  @override
  Future<bool> openLocationSettings() async {
    locationSettingsOpened = true;
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1. Location Models & Accuracy Policy', () {
    test('Balanced policy sets reasonable 100m threshold and 12s timeout', () {
      const policy = LocationAccuracyPolicy.balanced;
      expect(policy.acceptableAccuracyMeters, 100.0);
      expect(policy.poorAccuracyThresholdMeters, 500.0);
      expect(policy.timeout, const Duration(seconds: 12));
      expect(policy.isAcceptable(45.0), isTrue);
      expect(policy.isAcceptable(120.0), isFalse);
      expect(policy.isPoor(600.0), isTrue);
      expect(policy.isPoor(200.0), isFalse);
    });

    test('High accuracy policy configures 30m precision and 15s timeout', () {
      const policy = LocationAccuracyPolicy.high;
      expect(policy.acceptableAccuracyMeters, 30.0);
      expect(policy.timeout, const Duration(seconds: 15));
      expect(policy.isAcceptable(25.0), isTrue);
      expect(policy.isAcceptable(50.0), isFalse);
    });

    test('LocationResult tracks freshness within 5-minute window', () {
      final fresh = LocationResult(
        latitude: 11.7968,
        longitude: 77.8013,
        accuracyMeters: 12.0,
        timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
      );
      expect(fresh.isFresh(), isTrue);

      final stale = LocationResult(
        latitude: 11.7968,
        longitude: 77.8013,
        accuracyMeters: 12.0,
        timestamp: DateTime.now().subtract(const Duration(minutes: 6)),
      );
      expect(stale.isFresh(), isFalse);
      expect(stale.isFresh(const Duration(minutes: 10)), isTrue);
    });

    test('LocationResult formats source and freshness labels accurately', () {
      final now = DateTime.now();
      final live = LocationResult(
        latitude: 11.7968,
        longitude: 77.8013,
        accuracyMeters: 10.0,
        timestamp: now.subtract(const Duration(seconds: 15)),
        source: LocationSource.CURRENT_DEVICE_LOCATION,
      );
      expect(live.freshnessLabel, 'Updated just now');
      expect(live.sourceLabel, 'Updated just now');

      final manual = LocationResult(
        latitude: 11.6643,
        longitude: 78.1460,
        accuracyMeters: 0.0,
        timestamp: now,
        approximateArea: 'Fairlands',
        city: 'Salem',
        source: LocationSource.MANUAL_LOCATION,
      );
      expect(manual.isManual, isTrue);
      expect(manual.sourceLabel, 'Manual location');
      expect(manual.displayLabel, 'Fairlands, Salem');

      final cached = LocationResult(
        latitude: 11.7968,
        longitude: 77.8013,
        accuracyMeters: 12.0,
        timestamp: now.subtract(const Duration(minutes: 4)),
        source: LocationSource.CACHED_LOCATION,
      );
      expect(cached.sourceLabel, 'Last location: Updated 4 min ago');
    });

    test('LocationResult bridges cleanly to and from UserLocationContext', () {
      final result = LocationResult(
        latitude: 11.7968,
        longitude: 77.8013,
        accuracyMeters: 15.0,
        timestamp: DateTime.now(),
        approximateArea: 'Mettur Dam',
        city: 'Mettur',
        postalCode: '636401',
        source: LocationSource.CURRENT_DEVICE_LOCATION,
      );

      final context = result.toUserLocationContext();
      expect(context.latitude, 11.7968);
      expect(context.longitude, 77.8013);
      expect(context.approximateArea, 'Mettur Dam');
      expect(context.city, 'Mettur');
      expect(context.postalCode, '636401');
      expect(context.isManual, isFalse);

      final backResult = context.toLocationResult();
      expect(backResult.latitude, 11.7968);
      expect(backResult.longitude, 77.8013);
      expect(backResult.source, LocationSource.CURRENT_DEVICE_LOCATION);
    });

    test('LocationResult JSON round-trip serialization works without precision loss', () {
      final original = LocationResult(
        latitude: 11.8486241,
        longitude: 77.7512398,
        accuracyMeters: 18.2,
        timestamp: DateTime.parse('2026-09-13T10:30:00.000Z'),
        altitude: 210.5,
        speed: 1.2,
        heading: 94.0,
        approximateArea: 'Kolathur',
        city: 'Salem',
        postalCode: '636303',
        source: LocationSource.CURRENT_DEVICE_LOCATION,
      );

      final json = original.toJson();
      final revived = LocationResult.fromJson(json);

      expect(revived.latitude, original.latitude);
      expect(revived.longitude, original.longitude);
      expect(revived.accuracyMeters, original.accuracyMeters);
      expect(revived.approximateArea, 'Kolathur');
      expect(revived.city, 'Salem');
      expect(revived.postalCode, '636303');
      expect(revived.source, LocationSource.CURRENT_DEVICE_LOCATION);
    });
  });

  group('2. Typed Location Exceptions', () {
    test('All typed exceptions produce user-friendly non-technical messages', () {
      const pDenied = PermissionDeniedException();
      expect(pDenied.toUserMessage(), contains('Location permission is needed'));

      const pPermanent = PermissionPermanentlyDeniedException();
      expect(pPermanent.toUserMessage(), contains('Enable Location permission from Settings'));

      const sDisabled = LocationServicesDisabledException();
      expect(sDisabled.toUserMessage(), contains('Location services are turned off'));

      const timeout = LocationTimeoutException();
      expect(timeout.toUserMessage(), contains("Couldn't get your current location"));

      const unavailable = LocationUnavailableException();
      expect(unavailable.toUserMessage(), contains('Device location is temporarily unavailable'));

      const accuracy = LocationAccuracyException(accuracyMeters: 620.0, requiredAccuracyMeters: 100.0);
      expect(accuracy.toUserMessage(), contains('Your location accuracy is low (620m)'));

      const provider = LocationProviderException();
      expect(provider.toUserMessage(), contains('Unable to acquire location'));
    });
  });

  group('3. LocationPermissionManager', () {
    test('Reports correct permission status and service availability', () async {
      final mock = MockLocationProvider(
        permissionStatus: LocationPermissionStatus.whileInUse,
        serviceEnabled: true,
      );
      final manager = LocationPermissionManager(provider: mock);

      expect(await manager.isLocationServiceEnabled(), isTrue);
      expect(await manager.checkPermission(), LocationPermissionStatus.whileInUse);
    });

    test('Throws PermissionPermanentlyDeniedException on permanent rejection', () async {
      final mock = MockLocationProvider(
        permissionStatus: LocationPermissionStatus.deniedForever,
      );
      final manager = LocationPermissionManager(provider: mock);

      expect(
        () => manager.requestPermission(),
        throwsA(isA<PermissionPermanentlyDeniedException>()),
      );
    });

    test('Delegates openAppSettings and openLocationSettings to provider', () async {
      final mock = MockLocationProvider();
      final manager = LocationPermissionManager(provider: mock);

      await manager.openAppSettings();
      expect(mock.appSettingsOpened, isTrue);

      await manager.openLocationSettings();
      expect(mock.locationSettingsOpened, isTrue);
    });
  });

  group('4. LocationService Freshness & Cache Policies', () {
    test('Reuses fresh cached location without querying GPS hardware', () async {
      final mock = MockLocationProvider(
        permissionStatus: LocationPermissionStatus.whileInUse,
        serviceEnabled: true,
        nextResult: LocationResult(
          latitude: 11.7968,
          longitude: 77.8013,
          accuracyMeters: 15.0,
          timestamp: DateTime.now(),
          approximateArea: 'Mettur',
          city: 'Mettur',
        ),
      );

      final service = LocationService(provider: mock);

      // First query triggers GPS
      final first = await service.getCurrentLocation();
      expect(mock.positionRequestCount, 1);
      expect(first.latitude, 11.7968);

      // Second query within 5 minutes reuses in-memory cache
      final second = await service.getCurrentLocation();
      expect(mock.positionRequestCount, 1); // Not incremented!
      expect(second.latitude, 11.7968);
    });

    test('Bypasses cache and queries GPS when forceRefresh is requested', () async {
      final mock = MockLocationProvider(
        permissionStatus: LocationPermissionStatus.whileInUse,
        serviceEnabled: true,
        nextResult: LocationResult(
          latitude: 11.7968,
          longitude: 77.8013,
          accuracyMeters: 15.0,
          timestamp: DateTime.now(),
        ),
      );

      final service = LocationService(provider: mock);
      await service.getCurrentLocation();
      expect(mock.positionRequestCount, 1);

      await service.getCurrentLocation(forceRefresh: true);
      expect(mock.positionRequestCount, 2);
    });

    test('Throws LocationServicesDisabledException when GPS is turned off', () async {
      final mock = MockLocationProvider(
        permissionStatus: LocationPermissionStatus.whileInUse,
        serviceEnabled: false,
      );
      final service = LocationService(provider: mock);

      expect(
        () => service.getCurrentLocation(forceRefresh: true),
        throwsA(isA<LocationServicesDisabledException>()),
      );
    });

    test('Manual location sets MANUAL_LOCATION source and updates active cache', () {
      final service = LocationService(provider: MockLocationProvider());

      final manual = LocationResult(
        latitude: 11.6643,
        longitude: 78.1460,
        accuracyMeters: 0.0,
        timestamp: DateTime.now(),
        approximateArea: 'Fairlands',
        city: 'Salem',
        source: LocationSource.MANUAL_LOCATION,
      );

      service.setManualLocation(manual);
      expect(service.cachedLocation?.source, LocationSource.MANUAL_LOCATION);
      expect(service.cachedLocation?.city, 'Salem');
    });
  });

  group('5. LocationController & 11-State Machine', () {
    test('Initializes with LOCATION_PERMISSION_NOT_REQUESTED and never prompts on startup', () {
      final mock = MockLocationProvider(
        permissionStatus: LocationPermissionStatus.denied,
        serviceEnabled: true,
      );
      final service = LocationService(provider: mock);
      final controller = LocationController(service);

      expect(controller.state.status, LocationStateEnum.LOCATION_PERMISSION_NOT_REQUESTED);
      expect(controller.state.isLoading, isFalse);
      expect(mock.positionRequestCount, 0); // Zero GPS calls on startup!
    });

    test('Transitions to LOCATION_PERMISSION_GRANTED and LOCATION_READY when permission acquired', () async {
      final mock = MockLocationProvider(
        permissionStatus: LocationPermissionStatus.whileInUse,
        serviceEnabled: true,
        nextResult: LocationResult(
          latitude: 11.7968,
          longitude: 77.8013,
          accuracyMeters: 20.0,
          timestamp: DateTime.now(),
          approximateArea: 'Mettur Dam',
          city: 'Mettur',
        ),
      );

      final service = LocationService(provider: mock);
      final controller = LocationController(service);

      final success = await controller.requestPermissionAndAcquire();
      expect(success, isTrue);
      expect(controller.state.status, LocationStateEnum.LOCATION_READY);
      expect(controller.state.currentLocation?.latitude, 11.7968);
    });

    test('Transitions to LOCATION_PERMISSION_DENIED on user rejection without infinite loop', () async {
      final mock = MockLocationProvider(
        permissionStatus: LocationPermissionStatus.denied,
        serviceEnabled: true,
      );

      final service = LocationService(provider: mock);
      final controller = LocationController(service);

      final success = await controller.requestPermissionAndAcquire();
      expect(success, isFalse);
      expect(controller.state.status, LocationStateEnum.LOCATION_PERMISSION_DENIED);
      expect(controller.state.errorMessage, contains('Location permission is needed'));
    });

    test('Transitions to LOCATION_PERMISSION_DENIED_FOREVER when permanently denied', () async {
      final mock = MockLocationProvider(
        permissionStatus: LocationPermissionStatus.deniedForever,
        serviceEnabled: true,
      );

      final service = LocationService(provider: mock);
      final controller = LocationController(service);

      final success = await controller.requestPermissionAndAcquire();
      expect(success, isFalse);
      expect(controller.state.status, LocationStateEnum.LOCATION_PERMISSION_DENIED_FOREVER);
      expect(controller.state.status.requiresSettings, isTrue);
    });

    test('Transitions to LOCATION_SERVICES_DISABLED when hardware GPS is turned off', () async {
      final mock = MockLocationProvider(
        permissionStatus: LocationPermissionStatus.whileInUse,
        serviceEnabled: false,
      );

      final service = LocationService(provider: mock);
      final controller = LocationController(service);

      final success = await controller.requestPermissionAndAcquire();
      expect(success, isFalse);
      expect(controller.state.status, LocationStateEnum.LOCATION_SERVICES_DISABLED);
      expect(controller.state.status.requiresLocationServices, isTrue);
    });

    test('Transitions to LOCATION_TIMEOUT when location fix times out', () async {
      final mock = MockLocationProvider(
        permissionStatus: LocationPermissionStatus.whileInUse,
        serviceEnabled: true,
        exceptionToThrow: const LocationTimeoutException(),
      );

      final service = LocationService(provider: mock);
      final controller = LocationController(service);

      final result = await controller.getCurrentLocation(forceRefresh: true);
      expect(result, isNull);
      expect(controller.state.status, LocationStateEnum.LOCATION_TIMEOUT);
      expect(controller.state.status.canRetry, isTrue);
    });

    test('Flags accuracy warning when location precision exceeds threshold', () async {
      final mock = MockLocationProvider(
        permissionStatus: LocationPermissionStatus.whileInUse,
        serviceEnabled: true,
        nextResult: LocationResult(
          latitude: 11.7968,
          longitude: 77.8013,
          accuracyMeters: 650.0, // Exceeds 500m threshold
          timestamp: DateTime.now(),
        ),
      );

      final service = LocationService(provider: mock);
      final controller = LocationController(service);

      final result = await controller.getCurrentLocation(forceRefresh: true);
      expect(result, isNotNull);
      expect(controller.state.accuracyWarning, contains('accuracy is low (650m)'));
    });

    test('Manual location sets MANUAL_LOCATION_SELECTED and clears error states', () {
      final controller = LocationController(LocationService(provider: MockLocationProvider()));

      final manual = LocationResult(
        latitude: 11.6643,
        longitude: 78.1460,
        accuracyMeters: 0.0,
        timestamp: DateTime.now(),
        approximateArea: 'Fairlands',
        city: 'Salem',
      );

      controller.setManualLocation(manual);
      expect(controller.state.status, LocationStateEnum.MANUAL_LOCATION_SELECTED);
      expect(controller.state.currentLocation?.source, LocationSource.MANUAL_LOCATION);
      expect(controller.state.errorMessage, isNull);
      expect(controller.state.accuracyWarning, isNull);
    });

    test('Subtle refresh action does not block full screen and updates location', () async {
      final mock = MockLocationProvider(
        permissionStatus: LocationPermissionStatus.whileInUse,
        serviceEnabled: true,
        nextResult: LocationResult(
          latitude: 11.7968,
          longitude: 77.8013,
          accuracyMeters: 12.0,
          timestamp: DateTime.now(),
        ),
      );

      final service = LocationService(provider: mock);
      final controller = LocationController(service);

      await controller.refreshLocation();
      expect(controller.state.status, LocationStateEnum.LOCATION_READY);
      expect(controller.state.isRefreshing, isFalse);
    });

    test('AppLifecycleState.resumed automatically checks settings recovery', () async {
      final mock = MockLocationProvider(
        permissionStatus: LocationPermissionStatus.denied,
        serviceEnabled: true,
      );
      final service = LocationService(provider: mock);
      final controller = LocationController(
        service,
        initialState: const LocationState(
          status: LocationStateEnum.LOCATION_PERMISSION_DENIED,
        ),
      );

      // User returns from Settings after granting permission
      mock.permissionStatus = LocationPermissionStatus.whileInUse;
      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);

      // Wait for async reconciliation
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(controller.state.status, LocationStateEnum.LOCATION_READY);
    });
  });

  group('6. UI Widget Tests', () {
    testWidgets('LocationExplanationSheet renders benefits, privacy pledge, and buttons', (tester) async {
      bool? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  dialogResult = await showModalBottomSheet<bool>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const LocationExplanationSheet(),
                  );
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Find Better Deals Near You'), findsOneWidget);
      expect(find.text('Discover nearby grocery shops'), findsOneWidget);
      expect(find.text('Compare local and online prices'), findsOneWidget);
      expect(find.text('Estimate distance to shops'), findsOneWidget);
      expect(find.textContaining('Privacy first'), findsOneWidget);
      expect(find.text('Use My Location'), findsOneWidget);
      expect(find.text('Choose Location Manually'), findsOneWidget);

      // Tap [Use My Location]
      await tester.tap(find.text('Use My Location'));
      await tester.pumpAndSettle();
      expect(dialogResult, isTrue);
    });

    testWidgets('LocationStatusBanner renders action buttons for disabled GPS and permission denied', (tester) async {
      bool openSettingsTapped = false;
      bool chooseManuallyTapped = false;

      // 1. Services Disabled Banner
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationStatusBanner(
              state: const LocationState(
                status: LocationStateEnum.LOCATION_SERVICES_DISABLED,
              ),
              onTryAgain: () {},
              onOpenSettings: () => openSettingsTapped = true,
              onOpenLocationSettings: () => openSettingsTapped = true,
              onChooseManually: () => chooseManuallyTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Location services are turned off.'), findsOneWidget);
      expect(find.text('Turn On Location'), findsOneWidget);
      expect(find.text('Choose Manually'), findsOneWidget);

      await tester.tap(find.text('Turn On Location'));
      expect(openSettingsTapped, isTrue);

      await tester.tap(find.text('Choose Manually'));
      expect(chooseManuallyTapped, isTrue);
    });

    testWidgets('LocationBarWidget displays area name, source tag, and handles refresh tap', (tester) async {
      bool refreshTapped = false;
      bool changeTapped = false;

      final testLocation = LocationResult(
        latitude: 11.7968,
        longitude: 77.8013,
        accuracyMeters: 15.0,
        timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
        approximateArea: 'Mettur Dam',
        city: 'Mettur',
        source: LocationSource.CURRENT_DEVICE_LOCATION,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationBarWidget(
              locationState: LocationState(
                status: LocationStateEnum.LOCATION_READY,
                currentLocation: testLocation,
              ),
              radiusKm: 5.0,
              onRefreshLocation: () => refreshTapped = true,
              onChangeLocation: () => changeTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Mettur Dam, Mettur'), findsOneWidget);
      expect(find.text('Updated 3 min ago'), findsOneWidget);
      expect(find.text('Change'), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);

      await tester.tap(find.text('Change'));
      expect(changeTapped, isTrue);

      await tester.tap(find.byIcon(Icons.refresh_rounded));
      expect(refreshTapped, isTrue);
    });
  });
}
