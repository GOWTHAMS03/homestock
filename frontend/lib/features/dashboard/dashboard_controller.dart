import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/sync/sync_providers.dart';
import '../auth/auth_controller.dart';
import '../home_switcher/home_controller.dart';
import 'dashboard_model.dart';
import 'dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  final inventoryDao = ref.watch(inventoryDaoProvider);
  final shoppingDao = ref.watch(shoppingDaoProvider);
  final connectivity = ref.watch(connectivityMonitorProvider);
  return DashboardRepository(
    apiClient: client,
    inventoryDao: inventoryDao,
    shoppingDao: shoppingDao,
    connectivity: connectivity,
  );
});

class DashboardState {
  final bool isLoading;
  final DashboardSummaryModel? summary;
  final WhatDoINeedModel? recommendations;
  final String? errorMessage;

  const DashboardState({
    this.isLoading = false,
    this.summary,
    this.recommendations,
    this.errorMessage,
  });

  DashboardState copyWith({
    bool? isLoading,
    DashboardSummaryModel? summary,
    WhatDoINeedModel? recommendations,
    String? errorMessage,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      summary: summary ?? this.summary,
      recommendations: recommendations ?? this.recommendations,
      errorMessage: errorMessage,
    );
  }
}

final dashboardControllerProvider = StateNotifierProvider<DashboardController, DashboardState>((ref) {
  final repo = ref.watch(dashboardRepositoryProvider);
  final homeState = ref.watch(homeControllerProvider);
  return DashboardController(repo, homeState.activeHome?.id, homeState.activeHome?.name);
});

class DashboardController extends StateNotifier<DashboardState> {
  final DashboardRepository _repo;
  final String? _homeId;
  final String? _homeName;

  DashboardController(this._repo, this._homeId, this._homeName) : super(const DashboardState()) {
    if (_homeId != null) {
      loadDashboard();
    }
  }

  Future<void> loadDashboard() async {
    if (_homeId == null) return;

    // 1. Instant local SQLite display (0ms wait, no loading screen)
    try {
      final localSummary = await _repo.getLocalSummary(_homeId, homeName: _homeName ?? 'My Home');
      if (mounted) {
        state = state.copyWith(summary: localSummary, isLoading: false, errorMessage: null);
      }
    } catch (_) {}

    // 2. If online: silently refresh from server in background without blocking UI
    if (_repo.isOnline) {
      try {
        final remoteSummary = await _repo.fetchRemoteSummary(_homeId);
        if (mounted && remoteSummary != null) {
          state = state.copyWith(summary: remoteSummary);
        }
      } catch (e) {
        // Keep existing local summary intact
      }
    }
  }

  Future<void> loadRecommendations() async {
    if (_homeId == null) return;

    // 1. Instant local heuristics
    try {
      final localRecs = await _repo.getLocalRecommendations(_homeId);
      if (mounted) {
        state = state.copyWith(recommendations: localRecs);
      }
    } catch (_) {}

    // 2. If online: fetch smart server recommendations in background
    if (_repo.isOnline) {
      try {
        final remoteRecs = await _repo.fetchRemoteRecommendations(_homeId);
        if (mounted && remoteRecs != null) {
          state = state.copyWith(recommendations: remoteRecs);
        }
      } catch (_) {}
    }
  }
}
