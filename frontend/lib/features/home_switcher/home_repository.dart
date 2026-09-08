import 'package:drift/drift.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/database/app_database.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage_service.dart';
import 'home_model.dart';

class HomeRepository {
  final ApiClient apiClient;
  final SecureStorageService storage;
  final AppDatabase? database;

  HomeRepository({required this.apiClient, required this.storage, this.database});

  Future<List<HomeModel>> getMyHomes() async {
    final cached = storage.getCachedHomesSync();
    if (apiClient.connectivityMonitor != null && !apiClient.connectivityMonitor!.isOnline) {
      if (cached != null && cached.isNotEmpty) {
        await _cacheHomesLocally(cached);
        return cached;
      }
    }

    try {
      final response = await apiClient.dio.get(ApiEndpoints.homes);
      final list = response.data['data'] as List? ?? [];
      final homes = list.map((item) => HomeModel.fromJson(item as Map<String, dynamic>)).toList();
      await storage.saveHomes(homes);
      await _cacheHomesLocally(homes);
      return homes;
    } catch (_) {
      if (cached != null && cached.isNotEmpty) {
        await _cacheHomesLocally(cached);
        return cached;
      }
      rethrow;
    }
  }

  Future<void> _cacheHomesLocally(List<HomeModel> homes) async {
    if (database == null) return;
    for (final h in homes) {
      await database!.into(database!.localHomes).insertOnConflictUpdate(
        LocalHomesCompanion(
          id: Value(h.id),
          name: Value(h.name),
          inviteCode: Value(h.inviteCode),
          currentUserRole: Value(h.currentUserRole),
          memberCount: Value(h.memberCount),
          createdAt: Value(h.createdAt != null ? DateTime.tryParse(h.createdAt!) : null),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  Future<HomeModel> createHome(String name) async {
    final response = await apiClient.dio.post(
      ApiEndpoints.homes,
      data: {'name': name},
    );
    final model = HomeModel.fromJson(response.data['data']);
    await storage.saveActiveHomeId(model.id);
    await _cacheHomesLocally([model]);
    return model;
  }

  Future<HomeModel> joinHome(String inviteCode) async {
    final response = await apiClient.dio.post(
      ApiEndpoints.joinHome,
      data: {'inviteCode': inviteCode},
    );
    final model = HomeModel.fromJson(response.data['data']);
    await storage.saveActiveHomeId(model.id);
    await _cacheHomesLocally([model]);
    return model;
  }

  Future<HomeModel> updateHome(String homeId, String newName) async {
    final response = await apiClient.dio.put(
      ApiEndpoints.homeById(homeId),
      data: {'name': newName.trim()},
    );
    final model = HomeModel.fromJson(response.data['data']);
    await _cacheHomesLocally([model]);
    return model;
  }

  Future<List<HomeMemberModel>> getMembers(String homeId) async {
    try {
      final response = await apiClient.dio.get(ApiEndpoints.homeMembers(homeId));
      final list = response.data['data'] as List? ?? [];
      final members = list.map((item) => HomeMemberModel.fromJson(item)).toList();
      await _cacheMembersLocally(homeId, members);
      return members;
    } catch (e) {
      final localMembers = await _getCachedMembersLocally(homeId);
      if (localMembers.isNotEmpty) {
        return localMembers;
      }
      rethrow;
    }
  }

  Future<void> _cacheMembersLocally(String homeId, List<HomeMemberModel> members) async {
    if (database == null) return;
    for (final m in members) {
      await database!.into(database!.localHomeMembers).insertOnConflictUpdate(
        LocalHomeMembersCompanion(
          id: Value(m.id.isNotEmpty ? m.id : m.userId),
          homeId: Value(homeId),
          userId: Value(m.userId),
          fullName: Value(m.fullName),
          email: Value(m.email),
          avatarUrl: Value(m.avatarUrl),
          role: Value(m.role),
          joinedAt: Value(m.joinedAt),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  Future<List<HomeMemberModel>> _getCachedMembersLocally(String homeId) async {
    if (database == null) return [];
    final rows = await (database!.select(database!.localHomeMembers)
          ..where((t) => t.homeId.equals(homeId)))
        .get();
    return rows.map((r) => HomeMemberModel(
          id: r.id,
          userId: r.userId,
          fullName: r.fullName,
          email: r.email,
          avatarUrl: r.avatarUrl,
          role: r.role,
          joinedAt: r.joinedAt ?? '',
        )).toList();
  }

  Future<void> removeMember(String homeId, String userId) async {
    await apiClient.dio.delete(ApiEndpoints.removeMember(homeId, userId));
    if (database != null) {
      await (database!.delete(database!.localHomeMembers)
            ..where((t) => t.homeId.equals(homeId) & t.userId.equals(userId)))
          .go();
    }
  }

  Future<void> updateMemberRole(String homeId, String userId, String role) async {
    await apiClient.dio.put(
      ApiEndpoints.memberRole(homeId, userId),
      data: {'role': role},
    );
    if (database != null) {
      await (database!.update(database!.localHomeMembers)
            ..where((t) => t.homeId.equals(homeId) & t.userId.equals(userId)))
          .write(LocalHomeMembersCompanion(
            role: Value(role),
            updatedAt: Value(DateTime.now()),
          ));
    }
  }
}
