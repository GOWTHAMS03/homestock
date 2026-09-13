import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/location/location_exceptions.dart';
import '../../core/location/location_models.dart';
import '../../core/location/location_service.dart' as core_loc;
import '../../core/location/widgets/location_explanation_sheet.dart';

export '../../core/location/location_controller.dart';
export '../../core/location/location_exceptions.dart';
export '../../core/location/location_models.dart';
export '../../core/location/location_permission_manager.dart';
export '../../core/location/location_provider.dart';
export '../../core/location/location_service.dart';
export '../../core/location/location_state.dart';
export '../../core/location/widgets/location_bar_widget.dart';
export '../../core/location/widgets/location_explanation_sheet.dart';
export '../../core/location/widgets/location_status_banner.dart';

/// Extension enabling seamless conversion from LocationResult to UserLocationContext
extension LocationResultDealsExtension on LocationResult {
  UserLocationContext toUserLocationContext() {
    return UserLocationContext.fromLocationResult(this);
  }
}

/// Privacy-First Location Context for HomeStock Deals.
/// Retained for backward compatibility across existing shopping screens and tests.
class UserLocationContext {
  final double latitude;
  final double longitude;
  final String approximateArea;
  final String city;
  final String postalCode;
  final bool isManual;

  const UserLocationContext({
    required this.latitude,
    required this.longitude,
    required this.approximateArea,
    required this.city,
    this.postalCode = '',
    this.isManual = false,
  });

  bool get isResolved => (latitude.abs() > 0.0001 || longitude.abs() > 0.0001);

  String get displayLabel {
    if (!isResolved) {
      return approximateArea.isNotEmpty ? approximateArea : 'Select Location';
    }
    if (approximateArea.isNotEmpty && city.isNotEmpty) {
      if (approximateArea.toLowerCase() == city.toLowerCase()) {
        return city;
      }
      return '$approximateArea, $city';
    } else if (approximateArea.isNotEmpty) {
      return approximateArea;
    } else if (city.isNotEmpty) {
      return city;
    }
    return 'Current Location';
  }

  LocationResult toLocationResult() {
    return LocationResult(
      latitude: latitude,
      longitude: longitude,
      accuracyMeters: isManual ? 0.0 : 15.0,
      timestamp: DateTime.now(),
      approximateArea: approximateArea,
      city: city,
      postalCode: postalCode,
      source: isManual
          ? LocationSource.MANUAL_LOCATION
          : LocationSource.CURRENT_DEVICE_LOCATION,
    );
  }

  factory UserLocationContext.fromLocationResult(LocationResult result) {
    return UserLocationContext(
      latitude: result.latitude,
      longitude: result.longitude,
      approximateArea: result.approximateArea,
      city: result.city,
      postalCode: result.postalCode,
      isManual: result.isManual,
    );
  }

  // Initial detecting state
  static const UserLocationContext detecting = UserLocationContext(
    latitude: 0.0,
    longitude: 0.0,
    approximateArea: 'Detecting Location...',
    city: '',
    postalCode: '',
    isManual: false,
  );

  // Unresolved state when location permission is not granted
  static const UserLocationContext unresolved = UserLocationContext(
    latitude: 0.0,
    longitude: 0.0,
    approximateArea: 'Choose Location',
    city: '',
    postalCode: '',
    isManual: false,
  );
}

/// Service bridge delegating to the centralized core location architecture.
class LocationService {
  final core_loc.LocationService _coreService;

  LocationService({
    core_loc.LocationService? coreService,
    Dio? dio,
  })  : _coreService = coreService ??
            core_loc.LocationService(
              dio: dio,
            );

  core_loc.LocationService get coreService => _coreService;

  /// Check if permission was already granted
  Future<bool> hasLocationPermission() async {
    final status = await _coreService.checkPermission();
    return status.isGranted;
  }

  /// Explain why location is needed and prompt user with explanation sheet
  Future<bool> showPrePermissionPrompt(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const LocationExplanationSheet(),
    );

    return result ?? false;
  }

  /// Attempt to obtain GPS position with full failure handling
  Future<UserLocationContext?> requestGpsLocation({required BuildContext context}) async {
    try {
      final locResult = await _coreService.getCurrentLocation(
        forceRefresh: true,
        policy: LocationAccuracyPolicy.balanced,
      );
      return UserLocationContext.fromLocationResult(locResult);
    } on LocationServicesDisabledException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Location service is disabled. Turn on GPS to find nearby shops.'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => _coreService.openLocationSettings(),
            ),
          ),
        );
      }
      return null;
    } on PermissionPermanentlyDeniedException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Location permission permanently denied. Enable from Settings or choose manually.'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => _coreService.openAppSettings(),
            ),
          ),
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Reverse Geocoding using OpenStreetMap Nominatim
  Future<UserLocationContext?> reverseGeocode(double lat, double lon) async {
    final result = await _coreService.reverseGeocode(lat, lon);
    if (result != null) {
      return UserLocationContext.fromLocationResult(result);
    }
    return null;
  }

  /// Acquire real current location using device services
  Future<UserLocationContext?> getRealLiveLocation() async {
    try {
      final loc = await _coreService.getCurrentLocation(
        forceRefresh: false,
        policy: LocationAccuracyPolicy.balanced,
      );
      return UserLocationContext.fromLocationResult(loc);
    } catch (_) {
      return null;
    }
  }
}
