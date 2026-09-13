import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'location_exceptions.dart';
import 'location_models.dart';
import 'location_permission_manager.dart';
import 'location_provider.dart';

/// Centralized Location Service orchestrating permissions, GPS fixes, reverse geocoding,
/// accuracy policy enforcement, and battery-friendly freshness caching.
class LocationService {
  final LocationProvider _provider;
  final LocationPermissionManager _permissionManager;
  final Dio _dio;
  final Duration freshnessDuration;

  LocationResult? _cachedLocation;

  LocationService({
    LocationProvider? provider,
    LocationPermissionManager? permissionManager,
    Dio? dio,
    this.freshnessDuration = const Duration(minutes: 5),
  })  : _provider = provider ?? const GeolocatorLocationProvider(),
        _permissionManager = permissionManager ??
            LocationPermissionManager(provider: provider ?? const GeolocatorLocationProvider()),
        _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 4),
                receiveTimeout: const Duration(seconds: 4),
                headers: {'User-Agent': 'HomeStockApp/1.0 (LiveLocationDeals)'},
              ),
            );

  LocationPermissionManager get permissionManager => _permissionManager;
  LocationResult? get cachedLocation => _cachedLocation;

  /// Check whether we currently have a fresh cached fix available without querying GPS.
  bool get hasFreshCachedLocation =>
      _cachedLocation != null && _cachedLocation!.isFresh(freshnessDuration);

  /// Check permission without triggering OS prompt.
  Future<LocationPermissionStatus> checkPermission() {
    return _permissionManager.checkPermission();
  }

  /// Check if hardware GPS / location services are active.
  Future<bool> isLocationServiceEnabled() {
    return _permissionManager.isLocationServiceEnabled();
  }

  /// Request operating system permission.
  Future<LocationPermissionStatus> requestPermission() {
    return _permissionManager.requestPermission();
  }

  /// Open application app settings.
  Future<bool> openAppSettings() => _permissionManager.openAppSettings();

  /// Open device location services settings.
  Future<bool> openLocationSettings() => _permissionManager.openLocationSettings();

  /// Acquire real current location with accuracy enforcement, timeout, and reverse geocoding.
  /// If [forceRefresh] is false and cached location is fresh (< 5m), returns cached fix immediately.
  Future<LocationResult> getCurrentLocation({
    bool forceRefresh = false,
    LocationAccuracyPolicy policy = LocationAccuracyPolicy.balanced,
  }) async {
    // 1. Check in-memory fresh cache
    if (!forceRefresh && _cachedLocation != null && _cachedLocation!.isFresh(freshnessDuration)) {
      return _cachedLocation!;
    }

    // 2. Verify location service enabled
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServicesDisabledException();
    }

    // 3. Verify permission state
    final permission = await checkPermission();
    if (permission == LocationPermissionStatus.deniedForever) {
      throw const PermissionPermanentlyDeniedException();
    }
    if (permission == LocationPermissionStatus.denied) {
      throw const PermissionDeniedException();
    }

    // 4. Query physical device location
    final LocationResult rawFix = await _provider.getCurrentPosition(policy: policy);

    // 5. Reverse-geocode live coordinates to human area/city
    final geocoded = await reverseGeocode(rawFix.latitude, rawFix.longitude);

    final finalResult = rawFix.copyWith(
      approximateArea: geocoded?.approximateArea ?? 'Current Location',
      city: geocoded?.city ?? 'Nearby',
      postalCode: geocoded?.postalCode ?? '',
      source: LocationSource.CURRENT_DEVICE_LOCATION,
    );

    // 6. Update local private cache
    _cachedLocation = finalResult;

    return finalResult;
  }

  /// Reverse geocode coordinates using OpenStreetMap Nominatim with resilience.
  Future<LocationResult?> reverseGeocode(double lat, double lon) async {
    if (lat.abs() < 0.0001 && lon.abs() < 0.0001) return null;

    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'format': 'jsonv2',
          'lat': lat,
          'lon': lon,
        },
      );

      final dynamic raw = response.data;
      final Map<String, dynamic> data = raw is Map<String, dynamic>
          ? raw
          : (raw is String ? jsonDecode(raw) : <String, dynamic>{});

      final address = data['address'] as Map<String, dynamic>? ?? {};

      final area = address['village'] ??
          address['suburb'] ??
          address['neighbourhood'] ??
          address['hamlet'] ??
          address['town'] ??
          address['road'] ??
          'Local Area';

      final city = address['city'] ??
          address['town'] ??
          address['county'] ??
          address['state_district'] ??
          'Local';

      final postalCode = address['postcode']?.toString() ?? '';

      return LocationResult(
        latitude: lat,
        longitude: lon,
        accuracyMeters: 0.0,
        timestamp: DateTime.now(),
        approximateArea: area.toString(),
        city: city.toString(),
        postalCode: postalCode,
        source: LocationSource.CURRENT_DEVICE_LOCATION,
      );
    } catch (e) {
      // Network lookup failed; return basic coordinate representation
      return null;
    }
  }

  /// Set manual location as active shopping context.
  void setManualLocation(LocationResult manualLocation) {
    _cachedLocation = manualLocation.copyWith(
      source: LocationSource.MANUAL_LOCATION,
    );
  }

  /// Invalidate cache (e.g., when user switches home or explicitly clears location)
  void clearCache() {
    _cachedLocation = null;
  }
}
