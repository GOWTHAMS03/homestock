import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/database/app_database.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../core/sync/sync_operation.dart';
import 'home_model.dart';

const _uuid = Uuid();

class HomeRepository {
  final ApiClient apiClient;
  final SecureStorageService storage;
  final AppDatabase? database;

  HomeRepository({required this.apiClient, required this.storage, this.database});

  Future<List<HomeModel>> getMyHomes() async {
    final cached = storage.getCachedHomesSync();
    final isOffline = apiClient.connectivityMonitor != null && !apiClient.connectivityMonitor!.isOnline;

    if (isOffline) {
      if (cached != null && cached.isNotEmpty) {
        await _cacheHomesLocally(cached);
        return cached;
      }
      if (database != null) {
        final localRows = await database!.select(database!.localHomes).get();
        if (localRows.isNotEmpty) {
          final localHomes = localRows
              .map((r) => HomeModel(
                    id: r.id,
                    name: r.name,
                    inviteCode: r.inviteCode,
                    currentUserRole: r.currentUserRole,
                    memberCount: r.memberCount,
                    createdAt: r.createdAt?.toIso8601String(),
                  ))
              .toList();
          return localHomes;
        }
      }
      return [];
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
      if (database != null) {
        final localRows = await database!.select(database!.localHomes).get();
        if (localRows.isNotEmpty) {
          return localRows
              .map((r) => HomeModel(
                    id: r.id,
                    name: r.name,
                    inviteCode: r.inviteCode,
                    currentUserRole: r.currentUserRole,
                    memberCount: r.memberCount,
                    createdAt: r.createdAt?.toIso8601String(),
                  ))
              .toList();
        }
      }
      return [];
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
    final now = DateTime.now();
    final opId = _uuid.v4();

    if (database != null) {
      await database!.transaction(() async {
        await (database!.update(database!.localHomes)..where((t) => t.id.equals(homeId)))
            .write(LocalHomesCompanion(
              name: Value(newName.trim()),
              updatedAt: Value(now),
            ));

        await database!.into(database!.syncQueueEntries).insert(SyncQueueEntriesCompanion(
          operationId: Value(opId),
          operationType: const Value(SyncOperationType.updateHomeName),
          entityType: const Value(SyncEntityType.home),
          entityId: Value(homeId),
          payload: Value(jsonEncode({'name': newName.trim()})),
          createdAt: Value(now),
          homeId: Value(homeId),
        ));
      });
    }

    final isOnline = apiClient.connectivityMonitor?.isOnline ?? false;
    if (isOnline) {
      try {
        final response = await apiClient.dio.put(
          ApiEndpoints.homeById(homeId),
          data: {'name': newName.trim()},
        );
        final model = HomeModel.fromJson(response.data['data']);
        await _cacheHomesLocally([model]);
        if (database != null) {
          await (database!.update(database!.syncQueueEntries)
                ..where((t) => t.operationId.equals(opId)))
              .write(const SyncQueueEntriesCompanion(status: Value('SYNCED')));
        }
        return model;
      } catch (_) {}
    }

    return HomeModel(
      id: homeId,
      name: newName.trim(),
      inviteCode: '',
      currentUserRole: 'ADMIN',
      memberCount: 1,
    );
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
    final now = DateTime.now();
    final opId = _uuid.v4();

    if (database != null) {
      await database!.transaction(() async {
        await (database!.delete(database!.localHomeMembers)
              ..where((t) => t.homeId.equals(homeId) & t.userId.equals(userId)))
            .go();

        await database!.into(database!.syncQueueEntries).insert(SyncQueueEntriesCompanion(
          operationId: Value(opId),
          operationType: const Value(SyncOperationType.removeMember),
          entityType: const Value(SyncEntityType.homeMember),
          entityId: Value(userId),
          payload: Value(jsonEncode({'userId': userId})),
          createdAt: Value(now),
          homeId: Value(homeId),
        ));
      });
    }

    final isOnline = apiClient.connectivityMonitor?.isOnline ?? false;
    if (isOnline) {
      try {
        await apiClient.dio.delete(ApiEndpoints.removeMember(homeId, userId));
        if (database != null) {
          await (database!.update(database!.syncQueueEntries)
                ..where((t) => t.operationId.equals(opId)))
              .write(const SyncQueueEntriesCompanion(status: Value('SYNCED')));
        }
      } catch (_) {}
    }
  }

  Future<void> updateMemberRole(String homeId, String userId, String role) async {
    final now = DateTime.now();
    final opId = _uuid.v4();

    if (database != null) {
      await database!.transaction(() async {
        await (database!.update(database!.localHomeMembers)
              ..where((t) => t.homeId.equals(homeId) & t.userId.equals(userId)))
            .write(LocalHomeMembersCompanion(
              role: Value(role),
              updatedAt: Value(now),
            ));

        await database!.into(database!.syncQueueEntries).insert(SyncQueueEntriesCompanion(
          operationId: Value(opId),
          operationType: const Value(SyncOperationType.changeMemberRole),
          entityType: const Value(SyncEntityType.homeMember),
          entityId: Value(userId),
          payload: Value(jsonEncode({'userId': userId, 'role': role})),
          createdAt: Value(now),
          homeId: Value(homeId),
        ));
      });
    }

    final isOnline = apiClient.connectivityMonitor?.isOnline ?? false;
    if (isOnline) {
      try {
        await apiClient.dio.put(
          ApiEndpoints.memberRole(homeId, userId),
          data: {'role': role},
        );
        if (database != null) {
          await (database!.update(database!.syncQueueEntries)
                ..where((t) => t.operationId.equals(opId)))
              .write(const SyncQueueEntriesCompanion(status: Value('SYNCED')));
        }
      } catch (_) {}
    }
  }
}
