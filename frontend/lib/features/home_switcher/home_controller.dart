import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/secure_storage_service.dart';
import '../auth/auth_controller.dart';
import 'home_model.dart';
import 'home_repository.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  final storage = ref.watch(secureStorageProvider);
  return HomeRepository(apiClient: client, storage: storage);
});

class HomeState {
  final bool isLoading;
  final List<HomeModel> homes;
  final HomeModel? activeHome;
  final String? errorMessage;

  const HomeState({
    this.isLoading = false,
    this.homes = const [],
    this.activeHome,
    this.errorMessage,
  });

  HomeState copyWith({
    bool? isLoading,
    List<HomeModel>? homes,
    HomeModel? activeHome,
    String? errorMessage,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      homes: homes ?? this.homes,
      activeHome: activeHome ?? this.activeHome,
      errorMessage: errorMessage,
    );
  }
}

final homeControllerProvider = StateNotifierProvider<HomeController, HomeState>((ref) {
  final repo = ref.watch(homeRepositoryProvider);
  final storage = ref.watch(secureStorageProvider);
  return HomeController(repo, storage);
});

class HomeController extends StateNotifier<HomeState> {
  final HomeRepository _repo;
  final SecureStorageService _storage;

  HomeController(this._repo, this._storage) : super(_computeInitialState(_storage));

  static HomeState _computeInitialState(SecureStorageService storage) {
    final cached = storage.getCachedHomesSync();
    if (cached != null && cached.isNotEmpty) {
      return HomeState(
        homes: cached,
        activeHome: cached.first,
      );
    }
    return const HomeState();
  }

  void reset() {
    state = const HomeState();
  }

  Future<void> loadHomes() async {
    if (state.homes.isEmpty) {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }
    try {
      final homes = await _repo.getMyHomes();
      final savedActiveId = await _storage.getActiveHomeId();

      HomeModel? active;
      if (homes.isNotEmpty) {
        active = homes.firstWhere(
          (h) => h.id == savedActiveId,
          orElse: () => homes.first,
        );
        await _storage.saveActiveHomeId(active.id);
      }

      state = state.copyWith(
        isLoading: false,
        homes: homes,
        activeHome: active,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: state.homes.isEmpty ? e.toString() : null);
    }
  }

  Future<void> switchHome(HomeModel home) async {
    await _storage.saveActiveHomeId(home.id);
    state = state.copyWith(activeHome: home);
  }

  Future<bool> createHome(String name) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final newHome = await _repo.createHome(name);
      final updatedHomes = [...state.homes, newHome];
      state = state.copyWith(
        isLoading: false,
        homes: updatedHomes,
        activeHome: newHome,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> joinHome(String inviteCode) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final joined = await _repo.joinHome(inviteCode);
      final updatedHomes = [...state.homes, joined];
      state = state.copyWith(
        isLoading: false,
        homes: updatedHomes,
        activeHome: joined,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}
