import 'dart:async';
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

    try {
      final LocationAccuracy accuracy = policy.accuracyMode == 'HIGH'
          ? LocationAccuracy.high
          : LocationAccuracy.medium;

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          timeLimit: policy.timeout,
        ),
      );

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
    } on TimeoutException catch (e) {
      throw LocationTimeoutException('Location request timed out after ${policy.timeout.inSeconds}s', e);
    } on LocationServiceDisabledException catch (e) {
      throw LocationServicesDisabledException('Location services disabled', e);
    } on PermissionDeniedException {
      rethrow;
    } catch (e) {
      throw LocationProviderException('Failed to obtain device location: $e', e);
    }
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
