import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sync/connectivity_monitor.dart';
import '../sync/sync_providers.dart';
import '../sync/sync_status.dart';
import 'feature_capability.dart';

/// State tracking backend service health / availability.
/// When a service returns 503, timeout, or circuit breaker opens,
/// that service can be marked unavailable to prevent exposing actions that fail.
class ServiceHealthState {
  final Map<String, bool> services;

  const ServiceHealthState({
    this.services = const {},
  });

  bool isServiceAvailable(String? serviceKey) {
    if (serviceKey == null) return true;
    return services[serviceKey] ?? true;
  }

  ServiceHealthState copyWith({Map<String, bool>? services}) {
    return ServiceHealthState(services: services ?? this.services);
  }
}

/// Notifier to manage individual service health and reachability.
class ServiceHealthNotifier extends StateNotifier<ServiceHealthState> {
  ServiceHealthNotifier() : super(const ServiceHealthState());

  void markServiceUnavailable(String serviceKey) {
    final updated = Map<String, bool>.from(state.services);
    updated[serviceKey] = false;
    state = state.copyWith(services: updated);
  }

  void markServiceAvailable(String serviceKey) {
    final updated = Map<String, bool>.from(state.services);
    updated[serviceKey] = true;
    state = state.copyWith(services: updated);
  }

  void resetAll() {
    state = const ServiceHealthState();
  }
}

/// Provider for service health status.
final serviceHealthProvider =
    StateNotifierProvider<ServiceHealthNotifier, ServiceHealthState>((ref) {
  return ServiceHealthNotifier();
});

/// Computes whether the device is online with reactive Stream updates
/// from [networkStatusProvider] or [syncStateProvider], with fallback to [ConnectivityMonitor.isOnline].
final isOnlineProvider = Provider<bool>((ref) {
  // 1. Check networkStatusProvider stream if available
  final networkStatusAsync = ref.watch(networkStatusProvider);
  final fromNetwork = networkStatusAsync.valueOrNull;
  if (fromNetwork != null) {
    return fromNetwork == NetworkStatus.online || fromNetwork == NetworkStatus.syncing;
  }

  // 2. Check syncStateProvider stream (which also tracks NetworkStatus)
  final syncStateAsync = ref.watch(syncStateProvider);
  final fromSync = syncStateAsync.valueOrNull;
  if (fromSync != null) {
    return fromSync.status == NetworkStatus.online || fromSync.status == NetworkStatus.syncing;
  }

  // 3. Fallback to connectivity monitor singleton if available
  try {
    final monitor = ref.read(connectivityMonitorProvider);
    return monitor.isOnline;
  } catch (_) {
    // If running in an un-configured test environment without overrides,
    // default to true so tests that do not inject connectivity see full online features.
    return true;
  }
});

/// The core reactive capability provider.
/// Dynamically calculates all currently USABLE features.
/// If offline, ALL online-only features are completely excluded.
final availableCapabilitiesProvider = Provider<Set<FeatureCapability>>((ref) {
  final isOnline = ref.watch(isOnlineProvider);
  final health = ref.watch(serviceHealthProvider);

  if (!isOnline) {
    // OFFLINE: Only features that work 100% offline
    return FeatureCapability.values
        .where((c) => c.isOfflineSupported)
        .toSet();
  }

  // ONLINE: All offline-capable features + available online services
  final result = <FeatureCapability>{};
  for (final capability in FeatureCapability.values) {
    if (capability.isOfflineSupported) {
      result.add(capability);
    } else {
      final serviceKey = capability.requiredServiceKey;
      if (health.isServiceAvailable(serviceKey)) {
        result.add(capability);
      }
    }
  }
  return result;
});

/// Fast family provider to check a single capability.
final isCapabilityAvailableProvider =
    Provider.family<bool, FeatureCapability>((ref, capability) {
  final available = ref.watch(availableCapabilitiesProvider);
  return available.contains(capability);
});

/// Returns the prioritized list of [CapabilityDescriptor] to render on the
/// Home Screen (Dashboard) based strictly on current capabilities.
final activeHomeCapabilitiesProvider =
    Provider<List<CapabilityDescriptor>>((ref) {
  final isOnline = ref.watch(isOnlineProvider);
  final available = ref.watch(availableCapabilitiesProvider);

  final targetOrder = isOnline
      ? const [
          FeatureCapability.voice,
          FeatureCapability.billScan,
          FeatureCapability.deals,
          FeatureCapability.nearbyShops,
          FeatureCapability.onlineSearch,
        ]
      : const [
          FeatureCapability.inventory,
          FeatureCapability.shoppingList,
          FeatureCapability.history,
          FeatureCapability.reminders,
          FeatureCapability.manualAddEdit,
        ];

  final result = <CapabilityDescriptor>[];
  for (final cap in targetOrder) {
    if (available.contains(cap)) {
      final desc = CapabilityDescriptor.descriptors[cap];
      if (desc != null) {
        result.add(desc);
      }
    }
  }
  return result;
});

/// Declarative widget that conditionally renders its [child] ONLY
/// when [capability] is currently available.
/// If the capability is unavailable, renders [fallback] (defaulting to [SizedBox.shrink]).
/// Never renders disabled cards or greyed-out buttons.
class CapabilityAware extends ConsumerWidget {
  final FeatureCapability capability;
  final Widget child;
  final Widget fallback;

  const CapabilityAware({
    super.key,
    required this.capability,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAvailable = ref.watch(isCapabilityAvailableProvider(capability));
    return isAvailable ? child : fallback;
  }
}

/// Extension on [WidgetRef] for convenient capability checks.
extension CapabilityRefExtension on WidgetRef {
  bool isCapabilityAvailable(FeatureCapability capability) {
    return watch(isCapabilityAvailableProvider(capability));
  }
}
