import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_controller.dart';
import '../home_switcher/home_controller.dart';
import 'dashboard_model.dart';
import 'dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return DashboardRepository(apiClient: client);
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
  return DashboardController(repo, homeState.activeHome?.id);
});

class DashboardController extends StateNotifier<DashboardState> {
  final DashboardRepository _repo;
  final String? _homeId;

  DashboardController(this._repo, this._homeId) : super(const DashboardState()) {
    if (_homeId != null) {
      loadDashboard();
    }
  }

  Future<void> loadDashboard() async {
    if (_homeId == null) return;
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final summary = await _repo.getSummary(_homeId);
      state = state.copyWith(isLoading: false, summary: summary);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> loadRecommendations() async {
    if (_homeId == null) return;
    try {
      final recs = await _repo.getRecommendations(_homeId);
      state = state.copyWith(recommendations: recs);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }
}
