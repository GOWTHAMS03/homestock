import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import 'notification_model.dart';

class NotificationRepository {
  final ApiClient apiClient;

  NotificationRepository({required this.apiClient});

  Future<List<NotificationModel>> getNotifications() async {
    final response = await apiClient.dio.get(
      ApiEndpoints.notifications,
      queryParameters: {'size': 50},
    );
    final list = response.data['data']['content'] as List? ?? [];
    return list.map((item) => NotificationModel.fromJson(item)).toList();
  }

  Future<void> markAsRead(String id) async {
    await apiClient.dio.patch(ApiEndpoints.readNotification(id));
  }

  Future<void> markAllAsRead() async {
    await apiClient.dio.post(ApiEndpoints.readAllNotifications);
  }
}
