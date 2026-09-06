import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_controller.dart';
import '../home_switcher/home_controller.dart';
import 'analytics_model.dart';
import 'analytics_repository.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return AnalyticsRepository(apiClient: client);
});

class AnalyticsState {
  final bool isLoading;
  final AnalyticsOverviewModel? data;
  final String? errorMessage;

  const AnalyticsState({
    this.isLoading = false,
    this.data,
    this.errorMessage,
  });

  AnalyticsState copyWith({
    bool? isLoading,
    AnalyticsOverviewModel? data,
    String? errorMessage,
  }) {
    return AnalyticsState(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      errorMessage: errorMessage,
    );
  }
}

final analyticsControllerProvider = StateNotifierProvider<AnalyticsController, AnalyticsState>((ref) {
  final repo = ref.watch(analyticsRepositoryProvider);
  final homeState = ref.watch(homeControllerProvider);
  return AnalyticsController(repo, homeState.activeHome?.id);
});

class AnalyticsController extends StateNotifier<AnalyticsState> {
  final AnalyticsRepository _repo;
  final String? _homeId;

  AnalyticsController(this._repo, this._homeId) : super(const AnalyticsState()) {
    if (_homeId != null) {
      loadAnalytics();
    }
  }

  Future<void> loadAnalytics() async {
    if (_homeId == null) return;
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final data = await _repo.getAnalytics(_homeId);
      state = state.copyWith(isLoading: false, data: data);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}
