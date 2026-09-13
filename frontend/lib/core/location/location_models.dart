// ignore_for_file: constant_identifier_names
import 'package:flutter/foundation.dart';

/// Distinct source indicating how the location was obtained.
enum LocationSource {
  CURRENT_DEVICE_LOCATION,
  MANUAL_LOCATION,
  CACHED_LOCATION,
  UNKNOWN;

  String get displayName {
    switch (this) {
      case LocationSource.CURRENT_DEVICE_LOCATION:
        return 'Current location';
      case LocationSource.MANUAL_LOCATION:
        return 'Selected location';
      case LocationSource.CACHED_LOCATION:
        return 'Cached location';
      case LocationSource.UNKNOWN:
        return 'Unknown location';
    }
  }
}

/// Accuracy configuration and thresholds for location requests.
@immutable
class LocationAccuracyPolicy {
  final double acceptableAccuracyMeters;
  final double poorAccuracyThresholdMeters;
  final Duration timeout;
  final String accuracyMode; // BALANCED, HIGH, LOW

  const LocationAccuracyPolicy({
    this.acceptableAccuracyMeters = 100.0,
    this.poorAccuracyThresholdMeters = 500.0,
    this.timeout = const Duration(seconds: 12),
    this.accuracyMode = 'BALANCED',
  });

  /// Default balanced policy for nearby shops and grocery deals discovery.
  static const LocationAccuracyPolicy balanced = LocationAccuracyPolicy(
    acceptableAccuracyMeters: 100.0,
    poorAccuracyThresholdMeters: 500.0,
    timeout: Duration(seconds: 12),
    accuracyMode: 'BALANCED',
  );

  /// High accuracy policy when precision is strictly required.
  static const LocationAccuracyPolicy high = LocationAccuracyPolicy(
    acceptableAccuracyMeters: 30.0,
    poorAccuracyThresholdMeters: 200.0,
    timeout: Duration(seconds: 15),
    accuracyMode: 'HIGH',
  );

  /// Quick passive / low-power policy for rough approximations.
  static const LocationAccuracyPolicy low = LocationAccuracyPolicy(
    acceptableAccuracyMeters: 1000.0,
    poorAccuracyThresholdMeters: 2000.0,
    timeout: Duration(seconds: 8),
    accuracyMode: 'LOW',
  );

  bool isAcceptable(double accuracy) => accuracy <= acceptableAccuracyMeters;
  bool isPoor(double accuracy) => accuracy > poorAccuracyThresholdMeters;
}

/// Production-grade model capturing device or manual location.
@immutable
class LocationResult {
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final DateTime timestamp;
  final double? altitude;
  final double? speed;
  final double? heading;
  final LocationSource source;
  final String approximateArea;
  final String city;
  final String postalCode;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.timestamp,
    this.altitude,
    this.speed,
    this.heading,
    this.source = LocationSource.CURRENT_DEVICE_LOCATION,
    this.approximateArea = '',
    this.city = '',
    this.postalCode = '',
  });

  bool get isResolved => (latitude.abs() > 0.0001 || longitude.abs() > 0.0001);

  bool get isManual => source == LocationSource.MANUAL_LOCATION;

  /// Check whether the location fix is within the freshness duration.
  bool isFresh([Duration maxAge = const Duration(minutes: 5)]) {
    final difference = DateTime.now().difference(timestamp);
    return difference >= Duration.zero && difference <= maxAge;
  }

  /// Human-readable time-ago label for freshness.
  String get freshnessLabel {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 45) {
      return 'Updated just now';
    } else if (diff.inMinutes < 1) {
      return 'Updated ${diff.inSeconds} seconds ago';
    } else if (diff.inMinutes == 1) {
      return 'Updated 1 min ago';
    } else if (diff.inMinutes < 60) {
      return 'Updated ${diff.inMinutes} min ago';
    } else if (diff.inHours == 1) {
      return 'Updated 1 hr ago';
    } else {
      return 'Updated ${diff.inHours} hrs ago';
    }
  }

  /// Formatted area and city for UI display.
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

  /// Subtitle indicator showing source and freshness.
  String get sourceLabel {
    if (source == LocationSource.MANUAL_LOCATION) {
      return 'Manual location';
    }
    if (source == LocationSource.CACHED_LOCATION) {
      return 'Last location: $freshnessLabel';
    }
    return freshnessLabel;
  }

  LocationResult copyWith({
    double? latitude,
    double? longitude,
    double? accuracyMeters,
    DateTime? timestamp,
    double? altitude,
    double? speed,
    double? heading,
    LocationSource? source,
    String? approximateArea,
    String? city,
    String? postalCode,
  }) {
    return LocationResult(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracyMeters: accuracyMeters ?? this.accuracyMeters,
      timestamp: timestamp ?? this.timestamp,
      altitude: altitude ?? this.altitude,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      source: source ?? this.source,
      approximateArea: approximateArea ?? this.approximateArea,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'accuracyMeters': accuracyMeters,
        'timestamp': timestamp.toIso8601String(),
        if (altitude != null) 'altitude': altitude,
        if (speed != null) 'speed': speed,
        if (heading != null) 'heading': heading,
        'source': source.name,
        'approximateArea': approximateArea,
        'city': city,
        'postalCode': postalCode,
      };

  factory LocationResult.fromJson(Map<String, dynamic> json) {
    return LocationResult(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      accuracyMeters: (json['accuracyMeters'] as num?)?.toDouble() ?? 0.0,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      altitude: (json['altitude'] as num?)?.toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
      source: LocationSource.values.firstWhere(
        (e) => e.name == json['source'],
        orElse: () => LocationSource.CURRENT_DEVICE_LOCATION,
      ),
      approximateArea: json['approximateArea']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      postalCode: json['postalCode']?.toString() ?? '',
    );
  }

  /// Initial detecting state
  static final LocationResult detecting = LocationResult(
    latitude: 0.0,
    longitude: 0.0,
    accuracyMeters: 0.0,
    timestamp: DateTime.now(),
    source: LocationSource.UNKNOWN,
    approximateArea: 'Finding your location...',
    city: '',
  );

  /// Unresolved state when permission is not requested or denied
  static final LocationResult unresolved = LocationResult(
    latitude: 0.0,
    longitude: 0.0,
    accuracyMeters: 0.0,
    timestamp: DateTime.now(),
    source: LocationSource.UNKNOWN,
    approximateArea: 'Choose Location',
    city: '',
  );
}
