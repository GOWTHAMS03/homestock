import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'location_exceptions.dart';
import 'location_models.dart';
import 'location_provider.dart';
import 'location_service.dart';
import 'location_state.dart';
import 'widgets/location_explanation_sheet.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final locationControllerProvider =
    StateNotifierProvider<LocationController, LocationState>((ref) {
  final service = ref.watch(locationServiceProvider);
  return LocationController(service);
});

/// Riverpod StateNotifier controlling location permission flow, lifecycle reconciliation,
/// and live device coordinates.
class LocationController extends StateNotifier<LocationState>
    with WidgetsBindingObserver {
  final LocationService _locationService;
  final LocationAccuracyPolicy accuracyPolicy;

  LocationController(
    this._locationService, {
    this.accuracyPolicy = LocationAccuracyPolicy.balanced,
    LocationState? initialState,
  }) : super(initialState ?? const LocationState()) {
    WidgetsBinding.instance.addObserver(this);
    // Silent initial inspection of permission and service state
    _inspectInitialStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// React to app lifecycle events (Settings -> App Resume reconciliation).
  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle == AppLifecycleState.resumed) {
      _reconcileOnResume();
    }
  }

  /// Automatically check if user enabled GPS or granted permission in OS Settings.
  Future<void> _reconcileOnResume() async {
    // Only re-check if user was in a blocked / denied / disabled state
    if (state.status == LocationStateEnum.LOCATION_SERVICES_DISABLED ||
        state.status == LocationStateEnum.LOCATION_PERMISSION_DENIED ||
        state.status == LocationStateEnum.LOCATION_PERMISSION_DENIED_FOREVER) {
      final serviceEnabled = await _locationService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(
          status: LocationStateEnum.LOCATION_SERVICES_DISABLED,
          errorMessage: 'Location services are turned off on your device.',
        );
        return;
      }

      final permission = await _locationService.checkPermission();
      if (permission.isGranted) {
        state = state.copyWith(
          status: LocationStateEnum.LOCATION_PERMISSION_GRANTED,
          clearErrorMessage: true,
        );
        // Automatically fetch current location
        await getCurrentLocation(forceRefresh: true);
      } else if (permission.isDeniedForever) {
        state = state.copyWith(
          status: LocationStateEnum.LOCATION_PERMISSION_DENIED_FOREVER,
        );
      } else {
        state = state.copyWith(
          status: LocationStateEnum.LOCATION_PERMISSION_DENIED,
        );
      }
    }
  }

  /// Silent status check without prompting the user.
  Future<void> _inspectInitialStatus() async {
    try {
      final serviceEnabled = await _locationService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(
          status: LocationStateEnum.LOCATION_SERVICES_DISABLED,
        );
        return;
      }

      final permission = await _locationService.checkPermission();
      if (permission.isGranted) {
        state = state.copyWith(
          status: LocationStateEnum.LOCATION_PERMISSION_GRANTED,
        );
        if (_locationService.hasFreshCachedLocation) {
          state = state.copyWith(
            status: LocationStateEnum.LOCATION_READY,
            currentLocation: _locationService.cachedLocation,
          );
        }
      } else if (permission.isDeniedForever) {
        state = state.copyWith(
          status: LocationStateEnum.LOCATION_PERMISSION_DENIED_FOREVER,
        );
      } else {
        state = state.copyWith(
          status: LocationStateEnum.LOCATION_PERMISSION_NOT_REQUESTED,
        );
      }
    } catch (_) {
      // Keep initial unrequested state
    }
  }

  /// Request permission with explanation sheet first (Requirement 2).
  /// OS dialog is ONLY triggered after user selects [Use My Location].
  Future<bool> requestLocationWithExplanation(BuildContext context) async {
    // 1. Show lightweight explanation sheet
    final bool? userChoice = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const LocationExplanationSheet(),
    );

    if (userChoice != true) {
      // User tapped [Choose Location Manually] or dismissed sheet
      return false;
    }

    // 2. User tapped [Use My Location] -> Check service & trigger OS prompt
    return await requestPermissionAndAcquire();
  }

  /// Request OS permission directly (or after explanation approval).
  Future<bool> requestPermissionAndAcquire() async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);

    try {
      final serviceEnabled = await _locationService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(
          isLoading: false,
          status: LocationStateEnum.LOCATION_SERVICES_DISABLED,
          errorMessage: 'Location services are turned off on your device.',
        );
        return false;
      }

      final permission = await _locationService.requestPermission();
      if (permission.isGranted) {
        state = state.copyWith(
          status: LocationStateEnum.LOCATION_PERMISSION_GRANTED,
        );
        await getCurrentLocation(forceRefresh: true);
        return true;
      } else if (permission.isDeniedForever) {
        state = state.copyWith(
          isLoading: false,
          status: LocationStateEnum.LOCATION_PERMISSION_DENIED_FOREVER,
          errorMessage:
              'Location access is turned off for HomeStock. Enable from Settings.',
        );
        return false;
      } else {
        state = state.copyWith(
          isLoading: false,
          status: LocationStateEnum.LOCATION_PERMISSION_DENIED,
          errorMessage:
              'Location permission is needed to find nearby shops and local deals.',
        );
        return false;
      }
    } on PermissionPermanentlyDeniedException {
      state = state.copyWith(
        isLoading: false,
        status: LocationStateEnum.LOCATION_PERMISSION_DENIED_FOREVER,
        errorMessage:
            'Location access is turned off for HomeStock. Enable from Settings.',
      );
      return false;
    } on LocationServicesDisabledException {
      state = state.copyWith(
        isLoading: false,
        status: LocationStateEnum.LOCATION_SERVICES_DISABLED,
        errorMessage: 'Location services are turned off.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        status: LocationStateEnum.LOCATION_ERROR,
        errorMessage: 'Unable to request location: $e',
      );
      return false;
    }
  }

  /// Retrieve device's real current location.
  Future<LocationResult?> getCurrentLocation({bool forceRefresh = false}) async {
    // If not forcing refresh and location is already fresh, return existing
    if (!forceRefresh && state.currentLocation != null && state.currentLocation!.isFresh()) {
      return state.currentLocation;
    }

    state = state.copyWith(isLoading: true, clearErrorMessage: true);

    try {
      final location = await _locationService.getCurrentLocation(
        forceRefresh: forceRefresh,
        policy: accuracyPolicy,
      );

      String? accuracyWarning;
      if (accuracyPolicy.isPoor(location.accuracyMeters)) {
        accuracyWarning =
            'Your location accuracy is low (${location.accuracyMeters.toStringAsFixed(0)}m). Move outdoors or enable precise location.';
      }

      state = state.copyWith(
        isLoading: false,
        status: LocationStateEnum.LOCATION_READY,
        currentLocation: location,
        cachedLocation: location,
        accuracyWarning: accuracyWarning,
        clearErrorMessage: true,
      );

      return location;
    } on LocationServicesDisabledException {
      state = state.copyWith(
        isLoading: false,
        status: LocationStateEnum.LOCATION_SERVICES_DISABLED,
        errorMessage: 'Location services are turned off.',
      );
      return null;
    } on PermissionPermanentlyDeniedException {
      state = state.copyWith(
        isLoading: false,
        status: LocationStateEnum.LOCATION_PERMISSION_DENIED_FOREVER,
        errorMessage:
            'Location access is turned off for HomeStock. Enable from Settings.',
      );
      return null;
    } on PermissionDeniedException {
      state = state.copyWith(
        isLoading: false,
        status: LocationStateEnum.LOCATION_PERMISSION_DENIED,
        errorMessage:
            'Location permission is needed to find nearby shops and local deals.',
      );
      return null;
    } on LocationTimeoutException {
      state = state.copyWith(
        isLoading: false,
        status: LocationStateEnum.LOCATION_TIMEOUT,
        errorMessage: "Couldn't get your current location.",
      );
      return null;
    } on LocationUnavailableException {
      state = state.copyWith(
        isLoading: false,
        status: LocationStateEnum.LOCATION_UNAVAILABLE,
        errorMessage: 'Device location is currently unavailable.',
      );
      return null;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        status: LocationStateEnum.LOCATION_ERROR,
        errorMessage: 'Failed to acquire location: $e',
      );
      return null;
    }
  }

  /// Subtle refresh action (Requirement 14) without blocking full screen.
  Future<void> refreshLocation() async {
    if (state.isRefreshing || state.isLoading) return;

    state = state.copyWith(isRefreshing: true, clearErrorMessage: true);

    try {
      final fresh = await _locationService.getCurrentLocation(
        forceRefresh: true,
        policy: accuracyPolicy,
      );

      state = state.copyWith(
        isRefreshing: false,
        status: LocationStateEnum.LOCATION_READY,
        currentLocation: fresh,
        cachedLocation: fresh,
        clearErrorMessage: true,
      );
    } catch (e) {
      state = state.copyWith(
        isRefreshing: false,
        // Keep active location if available, notify user of subtle failure
        errorMessage: 'Unable to refresh location at this moment.',
      );
    }
  }

  /// Set manual location fallback (Requirement 21).
  void setManualLocation(LocationResult manual) {
    final updated = manual.copyWith(source: LocationSource.MANUAL_LOCATION);
    _locationService.setManualLocation(updated);
    state = state.copyWith(
      status: LocationStateEnum.MANUAL_LOCATION_SELECTED,
      currentLocation: updated,
      cachedLocation: updated,
      clearErrorMessage: true,
      clearAccuracyWarning: true,
    );
  }

  /// Open device settings (e.g. for permanently denied).
  Future<void> openAppSettings() async {
    await _locationService.openAppSettings();
  }

  /// Open location services toggle.
  Future<void> openLocationSettings() async {
    await _locationService.openLocationSettings();
  }
}

