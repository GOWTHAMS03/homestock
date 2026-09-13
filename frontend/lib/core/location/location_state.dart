// ignore_for_file: constant_identifier_names
import 'package:flutter/foundation.dart';
import 'location_models.dart';

/// 11 discrete states of the HomeStock location state machine.
enum LocationStateEnum {
  LOCATION_UNKNOWN,
  LOCATION_PERMISSION_NOT_REQUESTED,
  LOCATION_PERMISSION_GRANTED,
  LOCATION_PERMISSION_DENIED,
  LOCATION_PERMISSION_DENIED_FOREVER,
  LOCATION_SERVICES_DISABLED,
  LOCATION_UNAVAILABLE,
  LOCATION_TIMEOUT,
  LOCATION_ERROR,
  MANUAL_LOCATION_SELECTED,
  LOCATION_READY;

  bool get isReady =>
      this == LocationStateEnum.LOCATION_READY ||
      this == LocationStateEnum.MANUAL_LOCATION_SELECTED;

  bool get hasError =>
      this == LocationStateEnum.LOCATION_PERMISSION_DENIED ||
      this == LocationStateEnum.LOCATION_PERMISSION_DENIED_FOREVER ||
      this == LocationStateEnum.LOCATION_SERVICES_DISABLED ||
      this == LocationStateEnum.LOCATION_UNAVAILABLE ||
      this == LocationStateEnum.LOCATION_TIMEOUT ||
      this == LocationStateEnum.LOCATION_ERROR;

  bool get canRetry =>
      this == LocationStateEnum.LOCATION_PERMISSION_DENIED ||
      this == LocationStateEnum.LOCATION_TIMEOUT ||
      this == LocationStateEnum.LOCATION_UNAVAILABLE ||
      this == LocationStateEnum.LOCATION_ERROR;

  bool get requiresSettings =>
      this == LocationStateEnum.LOCATION_PERMISSION_DENIED_FOREVER;

  bool get requiresLocationServices =>
      this == LocationStateEnum.LOCATION_SERVICES_DISABLED;
}

/// Immutable state containing the current location status, coordinates, and metadata.
@immutable
class LocationState {
  final LocationStateEnum status;
  final LocationResult? currentLocation;
  final LocationResult? cachedLocation;
  final bool isLoading;
  final bool isRefreshing;
  final String? errorMessage;
  final String? accuracyWarning;

  const LocationState({
    this.status = LocationStateEnum.LOCATION_PERMISSION_NOT_REQUESTED,
    this.currentLocation,
    this.cachedLocation,
    this.isLoading = false,
    this.isRefreshing = false,
    this.errorMessage,
    this.accuracyWarning,
  });

  /// Active resolved location (or cached fallback if present).
  LocationResult? get activeLocation => currentLocation ?? cachedLocation;

  bool get hasLocation => activeLocation != null && activeLocation!.isResolved;

  LocationState copyWith({
    LocationStateEnum? status,
    LocationResult? currentLocation,
    bool clearCurrentLocation = false,
    LocationResult? cachedLocation,
    bool clearCachedLocation = false,
    bool? isLoading,
    bool? isRefreshing,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? accuracyWarning,
    bool clearAccuracyWarning = false,
  }) {
    return LocationState(
      status: status ?? this.status,
      currentLocation: clearCurrentLocation
          ? null
          : (currentLocation ?? this.currentLocation),
      cachedLocation: clearCachedLocation
          ? null
          : (cachedLocation ?? this.cachedLocation),
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      accuracyWarning: clearAccuracyWarning
          ? null
          : (accuracyWarning ?? this.accuracyWarning),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          currentLocation == other.currentLocation &&
          cachedLocation == other.cachedLocation &&
          isLoading == other.isLoading &&
          isRefreshing == other.isRefreshing &&
          errorMessage == other.errorMessage &&
          accuracyWarning == other.accuracyWarning;

  @override
  int get hashCode =>
      status.hashCode ^
      currentLocation.hashCode ^
      cachedLocation.hashCode ^
      isLoading.hashCode ^
      isRefreshing.hashCode ^
      errorMessage.hashCode ^
      accuracyWarning.hashCode;

  @override
  String toString() {
    return 'LocationState(status: $status, location: ${activeLocation?.displayLabel}, isLoading: $isLoading, refreshing: $isRefreshing)';
  }
}
