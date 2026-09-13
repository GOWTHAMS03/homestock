import 'location_exceptions.dart';
import 'location_provider.dart';

/// Centralized manager for handling OS-level location permissions & service status.
class LocationPermissionManager {
  final LocationProvider _provider;

  const LocationPermissionManager({LocationProvider? provider})
      : _provider = provider ?? const GeolocatorLocationProvider();

  /// Check current permission status without prompting user.
  Future<LocationPermissionStatus> checkPermission() {
    return _provider.checkPermission();
  }

  /// Check if hardware GPS / location services are active.
  Future<bool> isLocationServiceEnabled() {
    return _provider.isLocationServiceEnabled();
  }

  /// Request operating system permission.
  /// Throws [PermissionPermanentlyDeniedException] if permanently denied.
  Future<LocationPermissionStatus> requestPermission() async {
    final status = await _provider.requestPermission();
    if (status == LocationPermissionStatus.deniedForever) {
      throw const PermissionPermanentlyDeniedException();
    }
    return status;
  }

  /// Open device location settings (GPS toggle).
  Future<bool> openLocationSettings() {
    return _provider.openLocationSettings();
  }

  /// Open application app settings (app permissions).
  Future<bool> openAppSettings() {
    return _provider.openAppSettings();
  }
}

