import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import 'analytics_model.dart';

class AnalyticsRepository {
  final ApiClient apiClient;

  AnalyticsRepository({required this.apiClient});

  Future<AnalyticsOverviewModel> getAnalytics(String homeId) async {
    final response = await apiClient.dio.get(ApiEndpoints.analytics(homeId));
    return AnalyticsOverviewModel.fromJson(response.data['data']);
  }
}
