/// Typed exceptions for HomeStock location operations.
abstract class LocationException implements Exception {
  final String message;
  final Object? cause;

  const LocationException(this.message, [this.cause]);

  @override
  String toString() => '$runtimeType: $message';

  /// Human-friendly user explanation for UI banners and snackbars.
  String toUserMessage() => message;
}

class PermissionDeniedException extends LocationException {
  const PermissionDeniedException([
    super.message = 'Location permission is needed to find nearby shops and local deals.',
    super.cause,
  ]);

  @override
  String toUserMessage() =>
      'Location permission is needed to find nearby shops and local deals.';
}

class PermissionPermanentlyDeniedException extends LocationException {
  const PermissionPermanentlyDeniedException([
    super.message = 'Location access is turned off for HomeStock. Enable Location permission from Settings to find nearby shops.',
    super.cause,
  ]);

  @override
  String toUserMessage() =>
      'Location access is turned off for HomeStock. Enable Location permission from Settings to find nearby shops.';
}

class LocationServicesDisabledException extends LocationException {
  const LocationServicesDisabledException([
    super.message = 'Location services are turned off on your device.',
    super.cause,
  ]);

  @override
  String toUserMessage() =>
      'Location services are turned off. Turn on GPS to discover stores around you.';
}

class LocationTimeoutException extends LocationException {
  const LocationTimeoutException([
    super.message = 'Timed out waiting for location fix.',
    super.cause,
  ]);

  @override
  String toUserMessage() =>
      "Couldn't get your current location. Please try again or choose manually.";
}

class LocationUnavailableException extends LocationException {
  const LocationUnavailableException([
    super.message = 'Device location is currently unavailable.',
    super.cause,
  ]);

  @override
  String toUserMessage() =>
      'Device location is temporarily unavailable. Check if GPS is enabled.';
}

class LocationAccuracyException extends LocationException {
  final double accuracyMeters;
  final double requiredAccuracyMeters;

  const LocationAccuracyException({
    required this.accuracyMeters,
    required this.requiredAccuracyMeters,
    String message = 'Location accuracy is insufficient.',
    Object? cause,
  }) : super(message, cause);

  @override
  String toUserMessage() =>
      'Your location accuracy is low (${accuracyMeters.toStringAsFixed(0)}m). Move outdoors or enable precise location.';
}

class LocationProviderException extends LocationException {
  const LocationProviderException([
    super.message = 'An unexpected location provider error occurred.',
    super.cause,
  ]);

  @override
  String toUserMessage() =>
      'Unable to acquire location. Please try again or choose location manually.';
}
