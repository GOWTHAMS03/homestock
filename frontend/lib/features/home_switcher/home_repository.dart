import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage_service.dart';
import 'home_model.dart';

class HomeRepository {
  final ApiClient apiClient;
  final SecureStorageService storage;

  HomeRepository({required this.apiClient, required this.storage});

  Future<List<HomeModel>> getMyHomes() async {
    final cached = storage.getCachedHomesSync();
    try {
      final response = await apiClient.dio.get(ApiEndpoints.homes);
      final list = response.data['data'] as List? ?? [];
      final homes = list.map((item) => HomeModel.fromJson(item as Map<String, dynamic>)).toList();
      await storage.saveHomes(homes);
      return homes;
    } catch (_) {
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
      rethrow;
    }
  }

  Future<HomeModel> createHome(String name) async {
    final response = await apiClient.dio.post(
      ApiEndpoints.homes,
      data: {'name': name},
    );
    final model = HomeModel.fromJson(response.data['data']);
    await storage.saveActiveHomeId(model.id);
    return model;
  }

  Future<HomeModel> joinHome(String inviteCode) async {
    final response = await apiClient.dio.post(
      ApiEndpoints.joinHome,
      data: {'inviteCode': inviteCode},
    );
    final model = HomeModel.fromJson(response.data['data']);
    await storage.saveActiveHomeId(model.id);
    return model;
  }

  Future<List<HomeMemberModel>> getMembers(String homeId) async {
    final response = await apiClient.dio.get(ApiEndpoints.homeMembers(homeId));
    final list = response.data['data'] as List? ?? [];
    return list.map((item) => HomeMemberModel.fromJson(item)).toList();
  }

  Future<void> removeMember(String homeId, String userId) async {
    await apiClient.dio.delete(ApiEndpoints.removeMember(homeId, userId));
  }

  Future<void> updateMemberRole(String homeId, String userId, String role) async {
    await apiClient.dio.put(
      ApiEndpoints.memberRole(homeId, userId),
      data: {'role': role},
    );
  }
}
