import '../../../core/network/api_client.dart';
import '../../shop_owner/models/shop_models.dart';

class AdminShopRepository {
  final ApiClient _apiClient;

  AdminShopRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<ShopProfileModel>> getShopsByStatus(String status) async {
    final response = await _apiClient.dio.get(
      '/admin/shops',
      queryParameters: {'status': status},
    );
    final data = response.data['data'] as List<dynamic>? ?? [];
    return data.map((e) => ShopProfileModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ShopProfileModel> verifyShop(String shopId) async {
    final response = await _apiClient.dio.post('/admin/shops/$shopId/verify');
    final body = response.data['data'] as Map<String, dynamic>;
    return ShopProfileModel.fromJson(body);
  }

  Future<ShopProfileModel> rejectShop(String shopId, {String? reason}) async {
    final response = await _apiClient.dio.post(
      '/admin/shops/$shopId/reject',
      data: reason != null ? {'reason': reason} : null,
    );
    final body = response.data['data'] as Map<String, dynamic>;
    return ShopProfileModel.fromJson(body);
  }

  Future<ShopProfileModel> suspendShop(String shopId, {String? reason}) async {
    final response = await _apiClient.dio.post(
      '/admin/shops/$shopId/suspend',
      data: reason != null ? {'reason': reason} : null,
    );
    final body = response.data['data'] as Map<String, dynamic>;
    return ShopProfileModel.fromJson(body);
  }
}
