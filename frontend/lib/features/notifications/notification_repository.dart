import 'package:flutter/foundation.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/database/daos/notification_dao.dart';
import '../../core/network/api_client.dart';
import '../../core/sync/connectivity_monitor.dart';
import 'notification_model.dart';
import 'notification_preference_model.dart';

class NotificationRepository {
  final ApiClient apiClient;
  final NotificationDao? notificationDao;
  final ConnectivityMonitor? connectivityMonitor;

  NotificationRepository({
    required this.apiClient,
    this.notificationDao,
    this.connectivityMonitor,
  });

  bool get _isOnline => connectivityMonitor?.isOnline ?? true;

  /// Get notifications with offline SQLite cache fallback.
  Future<List<NotificationModel>> getNotifications() async {
    if (_isOnline) {
      try {
        final response = await apiClient.dio.get(
          ApiEndpoints.notifications,
          queryParameters: {'size': 50},
        );
        final list = response.data['data']['content'] as List? ?? [];
        final models = list.map((item) => NotificationModel.fromJson(item)).toList();

        // Cache into local SQLite
        if (notificationDao != null) {
          final companions = models.map((m) => m.toLocalCompanion('current_user')).toList();
          await notificationDao!.upsertNotifications(companions);
        }

        return models;
      } catch (e) {
        debugPrint('[NotificationRepository] Remote fetch failed, falling back to local SQLite: $e');
      }
    }

    // Offline / fallback to local DB
    if (notificationDao != null) {
      final locals = await notificationDao!.getNotifications();
      return locals.map((l) => NotificationModel.fromLocal(l)).toList();
    }

    return [];
  }

  /// Get unread notification count with offline fallback.
  Future<int> getUnreadCount() async {
    if (_isOnline) {
      try {
        final response = await apiClient.dio.get(ApiEndpoints.notificationUnreadCount);
        return response.data['data']['count'] as int? ?? 0;
      } catch (_) {}
    }

    if (notificationDao != null) {
      return await notificationDao!.getUnreadCount();
    }
    return 0;
  }

  /// Mark single notification as read.
  Future<void> markAsRead(String id) async {
    if (notificationDao != null) {
      await notificationDao!.markAsRead(id);
    }
    if (_isOnline) {
      try {
        await apiClient.dio.patch(ApiEndpoints.readNotification(id));
      } catch (e) {
        debugPrint('[NotificationRepository] Remote markAsRead failed: $e');
      }
    }
  }

  /// Mark all notifications as read.
  Future<void> markAllAsRead() async {
    if (notificationDao != null) {
      await notificationDao!.markAllAsRead();
    }
    if (_isOnline) {
      try {
        await apiClient.dio.post(ApiEndpoints.readAllNotifications);
      } catch (e) {
        debugPrint('[NotificationRepository] Remote markAllAsRead failed: $e');
      }
    }
  }

  /// Delete a notification.
  Future<void> deleteNotification(String id) async {
    if (notificationDao != null) {
      await notificationDao!.deleteNotification(id);
    }
    if (_isOnline) {
      try {
        await apiClient.dio.delete(ApiEndpoints.deleteNotification(id));
      } catch (e) {
        debugPrint('[NotificationRepository] Remote deleteNotification failed: $e');
      }
    }
  }

  /// Get user notification preferences.
  Future<NotificationPreferenceModel> getPreferences() async {
    if (_isOnline) {
      try {
        final response = await apiClient.dio.get(ApiEndpoints.notificationPreferences);
        final data = response.data['data'] as Map<String, dynamic>?;
        if (data != null) {
          return NotificationPreferenceModel.fromJson(data);
        }
      } catch (e) {
        debugPrint('[NotificationRepository] Remote getPreferences failed: $e');
      }
    }
    return const NotificationPreferenceModel();
  }

  /// Update user notification preferences.
  Future<NotificationPreferenceModel> updatePreferences(NotificationPreferenceModel preferences) async {
    if (_isOnline) {
      try {
        final response = await apiClient.dio.put(
          ApiEndpoints.notificationPreferences,
          data: preferences.toJson(),
        );
        final data = response.data['data'] as Map<String, dynamic>?;
        if (data != null) {
          return NotificationPreferenceModel.fromJson(data);
        }
      } catch (e) {
        debugPrint('[NotificationRepository] Remote updatePreferences failed: $e');
        rethrow;
      }
    }
    return preferences;
  }

  /// Register FCM device token with backend.
  Future<void> registerDeviceToken({
    required String token,
    required String platform,
    String? deviceModel,
    String? appVersion,
  }) async {
    if (!_isOnline) return;
    try {
      await apiClient.dio.post(
        ApiEndpoints.notificationDeviceToken,
        data: {
          'token': token,
          'platform': platform,
          'deviceModel': deviceModel,
          'appVersion': appVersion,
        },
      );
    } catch (e) {
      debugPrint('[NotificationRepository] Device token registration failed: $e');
    }
  }

  /// Deactivate device token on logout.
  Future<void> deactivateDeviceToken(String token) async {
    if (!_isOnline) return;
    try {
      await apiClient.dio.delete(
        ApiEndpoints.notificationDeviceToken,
        queryParameters: {'token': token},
      );
    } catch (e) {
      debugPrint('[NotificationRepository] Device token deactivation failed: $e');
    }
  }
}
