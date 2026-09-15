import '../../../core/network/api_client.dart';
import '../models/customer_demand_models.dart';

class CustomerDemandRepository {
  final ApiClient _apiClient;

  CustomerDemandRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetches aggregated customer demand intelligence for the given shop
  Future<CustomerDemandDashboardModel> getDemandDashboard(
    String shopId, {
    DemandPeriod period = DemandPeriod.last7Days,
    double radiusKm = 5.0,
  }) async {
    final response = await _apiClient.dio.get(
      '/shop-owner/$shopId/demand',
      queryParameters: {
        'period': period.apiValue,
        'radius': radiusKm,
      },
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return CustomerDemandDashboardModel.fromJson(data);
  }

  /// Investigates specific product demand details around the shop
  Future<ProductDemandDetailModel> searchProductDemand(
    String shopId,
    String query, {
    double radiusKm = 5.0,
  }) async {
    final response = await _apiClient.dio.get(
      '/shop-owner/$shopId/demand/search',
      queryParameters: {
        'query': query,
        'radius': radiusKm,
      },
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return ProductDemandDetailModel.fromJson(data);
  }
}
