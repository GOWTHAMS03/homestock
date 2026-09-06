import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import 'dashboard_model.dart';

class DashboardRepository {
  final ApiClient apiClient;

  DashboardRepository({required this.apiClient});

  Future<DashboardSummaryModel> getSummary(String homeId) async {
    final response = await apiClient.dio.get(ApiEndpoints.dashboard(homeId));
    return DashboardSummaryModel.fromJson(response.data['data']);
  }

  Future<WhatDoINeedModel> getRecommendations(String homeId) async {
    final response = await apiClient.dio.get(ApiEndpoints.whatDoINeed(homeId));
    return WhatDoINeedModel.fromJson(response.data['data']);
  }
}
