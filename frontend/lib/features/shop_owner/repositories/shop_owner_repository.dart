import '../../../core/network/api_client.dart';
import '../models/shop_models.dart';

class ShopOwnerRepository {
  final ApiClient _apiClient;

  ShopOwnerRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  // ═══════════════════════════════════════════
  // Shop Registration & Profile
  // ═══════════════════════════════════════════

  Future<ShopProfileModel> registerShop(Map<String, dynamic> data) async {
    final response = await _apiClient.dio.post(
      '/shop-owner/register',
      data: data,
    );
    final body = response.data['data'] as Map<String, dynamic>;
    return ShopProfileModel.fromJson(body);
  }

  Future<ShopProfileModel?> getMyShop() async {
    try {
      final response = await _apiClient.dio.get('/shop-owner/my-shop');
      final body = response.data['data'] as Map<String, dynamic>?;
      if (body == null) return null;
      return ShopProfileModel.fromJson(body);
    } catch (e) {
      return null;
    }
  }

  Future<ShopProfileModel> getShopById(String shopId) async {
    final response = await _apiClient.dio.get('/shop-owner/$shopId');
    final body = response.data['data'] as Map<String, dynamic>;
    return ShopProfileModel.fromJson(body);
  }

  Future<ShopProfileModel> updateShopProfile(String shopId, Map<String, dynamic> data) async {
    final response = await _apiClient.dio.put(
      '/shop-owner/$shopId',
      data: data,
    );
    final body = response.data['data'] as Map<String, dynamic>;
    return ShopProfileModel.fromJson(body);
  }

  // ═══════════════════════════════════════════
  // Product Catalog Management
  // ═══════════════════════════════════════════

  Future<List<ShopProductModel>> getShopProducts(String shopId) async {
    final response = await _apiClient.dio.get('/shop-owner/$shopId/products');
    final data = response.data['data'] as List<dynamic>? ?? [];
    return data.map((e) => ShopProductModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ShopProductModel> addProduct(String shopId, Map<String, dynamic> data) async {
    final response = await _apiClient.dio.post(
      '/shop-owner/$shopId/products',
      data: data,
    );
    final body = response.data['data'] as Map<String, dynamic>;
    return ShopProductModel.fromJson(body);
  }

  Future<ShopProductModel> updateProduct(String shopId, String productId, Map<String, dynamic> data) async {
    final response = await _apiClient.dio.put(
      '/shop-owner/$shopId/products/$productId',
      data: data,
    );
    final body = response.data['data'] as Map<String, dynamic>;
    return ShopProductModel.fromJson(body);
  }

  Future<void> deleteProduct(String shopId, String productId) async {
    await _apiClient.dio.delete('/shop-owner/$shopId/products/$productId');
  }

  // ═══════════════════════════════════════════
  // Deals Management
  // ═══════════════════════════════════════════

  Future<List<ShopDealModel>> getShopDeals(String shopId) async {
    final response = await _apiClient.dio.get('/shop-owner/$shopId/deals');
    final data = response.data['data'] as List<dynamic>? ?? [];
    return data.map((e) => ShopDealModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ShopDealModel> createDeal(String shopId, Map<String, dynamic> data) async {
    final response = await _apiClient.dio.post(
      '/shop-owner/$shopId/deals',
      data: data,
    );
    final body = response.data['data'] as Map<String, dynamic>;
    return ShopDealModel.fromJson(body);
  }

  Future<ShopDealModel> updateDeal(String shopId, String dealId, Map<String, dynamic> data) async {
    final response = await _apiClient.dio.put(
      '/shop-owner/$shopId/deals/$dealId',
      data: data,
    );
    final body = response.data['data'] as Map<String, dynamic>;
    return ShopDealModel.fromJson(body);
  }

  Future<void> deleteDeal(String shopId, String dealId) async {
    await _apiClient.dio.delete('/shop-owner/$shopId/deals/$dealId');
  }

  // ═══════════════════════════════════════════
  // Dashboard & Analytics
  // ═══════════════════════════════════════════

  Future<ShopDashboardModel> getDashboard(String shopId) async {
    final response = await _apiClient.dio.get('/shop-owner/$shopId/dashboard');
    final body = response.data['data'] as Map<String, dynamic>;
    return ShopDashboardModel.fromJson(body);
  }

  // ═══════════════════════════════════════════
  // Subscriptions & Plans
  // ═══════════════════════════════════════════

  Future<List<SubscriptionPlanModel>> getSubscriptionPlans() async {
    final response = await _apiClient.dio.get('/subscription-plans');
    final data = response.data['data'] as List<dynamic>? ?? [];
    return data.map((e) => SubscriptionPlanModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ShopSubscriptionModel> getShopSubscription(String shopId) async {
    final response = await _apiClient.dio.get('/shop-owner/$shopId/subscription');
    final body = response.data['data'] as Map<String, dynamic>;
    return ShopSubscriptionModel.fromJson(body);
  }

  Future<ShopSubscriptionModel> upgradePlan(String shopId, String planName) async {
    final response = await _apiClient.dio.post(
      '/shop-owner/$shopId/subscription/upgrade',
      queryParameters: {'plan': planName},
    );
    final body = response.data['data'] as Map<String, dynamic>;
    return ShopSubscriptionModel.fromJson(body);
  }
}
