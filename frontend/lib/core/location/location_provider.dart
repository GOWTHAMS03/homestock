import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart'
    hide PermissionDeniedException;
import 'location_exceptions.dart';
import 'location_models.dart';

/// Permission status enumeration independent of platform plugins.
enum LocationPermissionStatus {
  denied,
  deniedForever,
  whileInUse,
  always,
  unableToDetermine;

  bool get isGranted =>
      this == LocationPermissionStatus.whileInUse ||
      this == LocationPermissionStatus.always;

  bool get isDeniedForever => this == LocationPermissionStatus.deniedForever;
}

/// Abstract provider interface decoupling HomeStock from platform plugins.
abstract class LocationProvider {
  Future<LocationPermissionStatus> checkPermission();
  Future<LocationPermissionStatus> requestPermission();
  Future<bool> isLocationServiceEnabled();
  Future<LocationResult> getCurrentPosition({
    required LocationAccuracyPolicy policy,
  });
  Future<LocationResult?> getLastKnownPosition();
  Future<bool> openLocationSettings();
  Future<bool> openAppSettings();
}

/// Production implementation of LocationProvider backed by Geolocator.
class GeolocatorLocationProvider implements LocationProvider {
  const GeolocatorLocationProvider();

  @override
  Future<LocationPermissionStatus> checkPermission() async {
    try {
      final status = await Geolocator.checkPermission();
      return _mapPermission(status);
    } catch (e) {
      return LocationPermissionStatus.unableToDetermine;
    }
  }

  @override
  Future<LocationPermissionStatus> requestPermission() async {
    try {
      final status = await Geolocator.requestPermission();
      return _mapPermission(status);
    } catch (e) {
      throw LocationProviderException('Failed to request location permission: $e', e);
    }
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      return false;
    }
  }

  @override
  Future<LocationResult> getCurrentPosition({
    required LocationAccuracyPolicy policy,
  }) async {
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServicesDisabledException();
    }

    final permission = await checkPermission();
    if (permission == LocationPermissionStatus.deniedForever) {
      throw const PermissionPermanentlyDeniedException();
    }
    if (permission == LocationPermissionStatus.denied) {
      throw const PermissionDeniedException();
    }

    Position? position;

    // Tier 1: Instant cache check.
    // If the device already has a recent location (< 3 minutes old), use it immediately.
    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        final age = DateTime.now().difference(lastKnown.timestamp);
        if (age.inMinutes < 3) {
          position = lastKnown;
        }
      }
    } catch (_) {
      // Continue to live acquisition
    }

    // Tier 2: Live GPS/Fused location with platform-optimized settings
    if (position == null) {
      final requestedAccuracy = policy.accuracyMode == 'HIGH'
          ? LocationAccuracy.high
          : LocationAccuracy.medium;

      LocationSettings settings;
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        settings = AndroidSettings(
          accuracy: requestedAccuracy,
          distanceFilter: 0,
          forceLocationManager: false, // Uses Google Play Services Fused Location Provider
          intervalDuration: const Duration(seconds: 1),
          timeLimit: const Duration(seconds: 8),
        );
      } else if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.macOS)) {
        settings = AppleSettings(
          accuracy: requestedAccuracy,
          distanceFilter: 0,
          timeLimit: const Duration(seconds: 8),
        );
      } else {
        settings = LocationSettings(
          accuracy: requestedAccuracy,
          timeLimit: const Duration(seconds: 8),
        );
      }

      try {
        position = await Geolocator.getCurrentPosition(locationSettings: settings);
      } catch (_) {
        // Tier 3: Fallback - if Fused/High accuracy timed out or user granted coarse location,
        // retry with native LocationManager and low/balanced accuracy
        try {
          if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
            position = await Geolocator.getCurrentPosition(
              locationSettings: AndroidSettings(
                accuracy: LocationAccuracy.low,
                distanceFilter: 0,
                forceLocationManager: true, // Native Android provider fallback
                intervalDuration: const Duration(seconds: 1),
                timeLimit: const Duration(seconds: 6),
              ),
            );
          } else {
            position = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.low,
                timeLimit: Duration(seconds: 6),
              ),
            );
          }
        } catch (_) {
          // Live acquisition attempts exhausted
        }
      }
    }

    // Tier 4: Fallback to last known position even if older
    if (position == null) {
      try {
        position = await Geolocator.getLastKnownPosition();
      } catch (_) {}
    }

    // If still null after all 4 tiers
    if (position == null) {
      throw LocationTimeoutException(
        'Location request timed out after ${policy.timeout.inSeconds}s. Could not acquire satellite or network location.',
      );
    }

    return LocationResult(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyMeters: position.accuracy,
      timestamp: position.timestamp,
      altitude: position.altitude,
      speed: position.speed,
      heading: position.heading,
      source: LocationSource.CURRENT_DEVICE_LOCATION,
    );
  }

  @override
  Future<LocationResult?> getLastKnownPosition() async {
    try {
      final Position? position = await Geolocator.getLastKnownPosition();
      if (position == null) return null;

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
        timestamp: position.timestamp,
        altitude: position.altitude,
        speed: position.speed,
        heading: position.heading,
        source: LocationSource.CACHED_LOCATION,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (_) {
      return false;
    }
  }

  LocationPermissionStatus _mapPermission(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.denied:
        return LocationPermissionStatus.denied;
      case LocationPermission.deniedForever:
        return LocationPermissionStatus.deniedForever;
      case LocationPermission.whileInUse:
        return LocationPermissionStatus.whileInUse;
      case LocationPermission.always:
        return LocationPermissionStatus.always;
      case LocationPermission.unableToDetermine:
        return LocationPermissionStatus.unableToDetermine;
    }
  }
}
