import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/sync/sync_providers.dart';
import '../../core/storage/secure_storage_service.dart';
import '../auth/auth_controller.dart';
import 'home_model.dart';
import 'home_repository.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  final storage = ref.watch(secureStorageProvider);
  final db = ref.watch(databaseProvider);
  return HomeRepository(apiClient: client, storage: storage, database: db);
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

  Future<bool> updateHomeName(String homeId, String newName) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updated = await _repo.updateHome(homeId, newName);
      final updatedHomes = state.homes.map((h) => h.id == homeId ? updated : h).toList();
      state = state.copyWith(
        isLoading: false,
        homes: updatedHomes,
        activeHome: state.activeHome?.id == homeId ? updated : state.activeHome,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

class MembersState {
  final bool isLoading;
  final List<HomeMemberModel> members;
  final String? errorMessage;

  const MembersState({
    this.isLoading = false,
    this.members = const [],
    this.errorMessage,
  });

  MembersState copyWith({
    bool? isLoading,
    List<HomeMemberModel>? members,
    String? errorMessage,
  }) {
    return MembersState(
      isLoading: isLoading ?? this.isLoading,
      members: members ?? this.members,
      errorMessage: errorMessage,
    );
  }
}

final membersControllerProvider = StateNotifierProvider<MembersController, MembersState>((ref) {
  final repo = ref.watch(homeRepositoryProvider);
  final activeHome = ref.watch(homeControllerProvider).activeHome;
  return MembersController(repo, activeHome?.id);
});

class MembersController extends StateNotifier<MembersState> {
  final HomeRepository _repo;
  final String? _homeId;

  MembersController(this._repo, this._homeId) : super(const MembersState()) {
    if (_homeId != null) {
      loadMembers();
    }
  }

  Future<void> loadMembers() async {
    if (_homeId == null) return;
    state = state.copyWith(isLoading: state.members.isEmpty, errorMessage: null);
    try {
      final members = await _repo.getMembers(_homeId);
      state = state.copyWith(isLoading: false, members: members);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: state.members.isEmpty ? e.toString() : null);
    }
  }

  Future<bool> changeRole(String userId, String newRole) async {
    if (_homeId == null) return false;
    try {
      await _repo.updateMemberRole(_homeId, userId, newRole);
      final updated = state.members.map((m) {
        if (m.userId == userId) {
          return HomeMemberModel(
            id: m.id,
            userId: m.userId,
            fullName: m.fullName,
            email: m.email,
            avatarUrl: m.avatarUrl,
            role: newRole,
            joinedAt: m.joinedAt,
          );
        }
        return m;
      }).toList();
      state = state.copyWith(members: updated);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> removeMember(String userId) async {
    if (_homeId == null) return false;
    try {
      await _repo.removeMember(_homeId, userId);
      final updated = state.members.where((m) => m.userId != userId).toList();
      state = state.copyWith(members: updated);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }
}

