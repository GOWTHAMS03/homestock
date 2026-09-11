import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/sync/sync_providers.dart';
import '../auth/auth_controller.dart';
import '../home_switcher/home_controller.dart';
import '../inventory/consumption_model.dart';
import 'dashboard_model.dart';
import 'dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  final inventoryDao = ref.watch(inventoryDaoProvider);
  final shoppingDao = ref.watch(shoppingDaoProvider);
  final connectivity = ref.watch(connectivityMonitorProvider);
  final syncDao = ref.watch(syncDaoProvider);
  return DashboardRepository(
    apiClient: client,
    inventoryDao: inventoryDao,
    shoppingDao: shoppingDao,
    connectivity: connectivity,
    syncDao: syncDao,
  );
});

class DashboardState {
  final bool isLoading;
  final DashboardSummaryModel? summary;
  final WhatDoINeedModel? recommendations;
  final HomeInsightModel? homeInsight;
  final ReturnSummaryModel? returnSummary;
  final String? errorMessage;

  const DashboardState({
    this.isLoading = false,
    this.summary,
    this.recommendations,
    this.homeInsight,
    this.returnSummary,
    this.errorMessage,
  });

  DashboardState copyWith({
    bool? isLoading,
    DashboardSummaryModel? summary,
    WhatDoINeedModel? recommendations,
    HomeInsightModel? homeInsight,
    ReturnSummaryModel? returnSummary,
    String? errorMessage,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      summary: summary ?? this.summary,
      recommendations: recommendations ?? this.recommendations,
      homeInsight: homeInsight ?? this.homeInsight,
      returnSummary: returnSummary ?? this.returnSummary,
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
  StreamSubscription? _inventorySub;
  StreamSubscription? _shoppingSub;

  DashboardController(this._repo, this._homeId, this._homeName) : super(const DashboardState()) {
    final homeId = _homeId;
    if (homeId != null) {
      loadDashboard();
      _inventorySub = _repo.watchInventoryItems(homeId).listen((_) {
        reloadLocalSummary();
      });
      _shoppingSub = _repo.watchShoppingItems(homeId).listen((_) {
        reloadLocalSummary();
      });
    }
  }

  @override
  void dispose() {
    _inventorySub?.cancel();
    _shoppingSub?.cancel();
    super.dispose();
  }

  /// Instant local recomputation of metrics when inventory changes
  Future<void> reloadLocalSummary() async {
    final homeId = _homeId;
    if (homeId == null) return;
    try {
      final localSummary = await _repo.getLocalSummary(homeId, homeName: _homeName ?? 'My Home');
      if (mounted) {
        state = state.copyWith(summary: localSummary);
      }
    } catch (_) {}
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
        final insights = await _repo.getHomeInsights(_homeId);
        final returnSum = await _repo.getReturnSummary(_homeId);
        final hasPending = await _repo.hasPendingSyncOperations(_homeId);
        if (mounted) {
          state = state.copyWith(
            summary: hasPending ? state.summary : (remoteSummary ?? state.summary),
            homeInsight: insights,
            returnSummary: returnSum,
          );
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
