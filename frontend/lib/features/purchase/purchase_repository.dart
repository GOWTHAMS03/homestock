import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import 'purchase_model.dart';

class PurchaseRepository {
  final ApiClient apiClient;

  PurchaseRepository({required this.apiClient});

  Future<List<PurchaseModel>> getPurchases(String homeId) async {
    final response = await apiClient.dio.get(
      ApiEndpoints.purchases(homeId),
      queryParameters: {'size': 50},
    );
    final list = response.data['data']['content'] as List? ?? [];
    return list.map((item) => PurchaseModel.fromJson(item)).toList();
  }

  Future<PurchaseModel> recordPurchase(String homeId, Map<String, dynamic> data) async {
    final response = await apiClient.dio.post(
      ApiEndpoints.purchases(homeId),
      data: data,
    );
    return PurchaseModel.fromJson(response.data['data']);
  }

  Future<List<StoreModel>> getStores(String homeId) async {
    final response = await apiClient.dio.get(ApiEndpoints.stores(homeId));
    final list = response.data['data'] as List? ?? [];
    return list.map((item) => StoreModel.fromJson(item)).toList();
  }

  Future<StoreModel> createStore(String homeId, String name, String? location) async {
    final response = await apiClient.dio.post(
      ApiEndpoints.stores(homeId),
      data: {'name': name, 'location': ?location},
    );
    return StoreModel.fromJson(response.data['data']);
  }
}
