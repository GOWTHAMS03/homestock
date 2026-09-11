import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/notifications/local_notification_engine.dart';
import '../../core/notifications/notification_providers.dart';
import 'notification_model.dart';
import 'notification_preference_model.dart';
import 'notification_repository.dart';

class NotificationState {
  final bool isLoading;
  final bool isPreferencesLoading;
  final List<NotificationModel> notifications;
  final NotificationPreferenceModel preferences;
  final int unreadCount;
  final String? errorMessage;

  const NotificationState({
    this.isLoading = false,
    this.isPreferencesLoading = false,
    this.notifications = const [],
    this.preferences = const NotificationPreferenceModel(),
    this.unreadCount = 0,
    this.errorMessage,
  });

  NotificationState copyWith({
    bool? isLoading,
    bool? isPreferencesLoading,
    List<NotificationModel>? notifications,
    NotificationPreferenceModel? preferences,
    int? unreadCount,
    String? errorMessage,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      isPreferencesLoading: isPreferencesLoading ?? this.isPreferencesLoading,
      notifications: notifications ?? this.notifications,
      preferences: preferences ?? this.preferences,
      unreadCount: unreadCount ?? this.unreadCount,
      errorMessage: errorMessage,
    );
  }
}

final notificationControllerProvider =
    StateNotifierProvider<NotificationController, NotificationState>((ref) {
  final repo = ref.watch(notificationRepositoryProvider);
  final engine = ref.watch(localNotificationEngineProvider);
  return NotificationController(repo, engine);
});

class NotificationController extends StateNotifier<NotificationState> {
  final NotificationRepository _repo;
  final LocalNotificationEngine _engine;

  NotificationController(this._repo, this._engine) : super(const NotificationState()) {
    loadNotifications();
    loadPreferences();
  }

  /// Load notification list and refresh unread count
  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _repo.getNotifications();
      final unread = list.where((n) => !n.isRead).length;
      state = state.copyWith(
        isLoading: false,
        notifications: list,
        unreadCount: unread,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Mark single notification as read
  Future<void> markAsRead(String id) async {
    try {
      await _repo.markAsRead(id);
      final updated = state.notifications.map((n) {
        if (n.id == id) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();
      final unread = updated.where((n) => !n.isRead).length;
      state = state.copyWith(notifications: updated, unreadCount: unread);
    } catch (_) {}
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      await _repo.markAllAsRead();
      final updated = state.notifications.map((n) => n.copyWith(isRead: true)).toList();
      state = state.copyWith(notifications: updated, unreadCount: 0);
    } catch (_) {}
  }

  /// Delete a notification
  Future<void> deleteNotification(String id) async {
    try {
      await _repo.deleteNotification(id);
      final updated = state.notifications.where((n) => n.id != id).toList();
      final unread = updated.where((n) => !n.isRead).length;
      state = state.copyWith(notifications: updated, unreadCount: unread);
    } catch (_) {}
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      await _repo.clearAllNotifications();
      state = state.copyWith(notifications: [], unreadCount: 0);
    } catch (_) {}
  }

  /// Restore a deleted notification (Undo action)
  Future<void> restoreNotification(NotificationModel notif) async {
    try {
      if (_repo.notificationDao != null) {
        await _repo.notificationDao!.upsertNotification(notif.toLocalCompanion('current_user'));
      }
      final updated = [notif, ...state.notifications];
      final unread = updated.where((n) => !n.isRead).length;
      state = state.copyWith(notifications: updated, unreadCount: unread);
    } catch (_) {}
  }

  /// Load notification preferences
  Future<void> loadPreferences() async {
    state = state.copyWith(isPreferencesLoading: true);
    try {
      final prefs = await _repo.getPreferences();
      state = state.copyWith(isPreferencesLoading: false, preferences: prefs);
    } catch (_) {
      state = state.copyWith(isPreferencesLoading: false);
    }
  }

  /// Update notification preferences
  Future<void> updatePreferences(NotificationPreferenceModel updatedPrefs) async {
    state = state.copyWith(preferences: updatedPrefs);
    try {
      final saved = await _repo.updatePreferences(updatedPrefs);
      state = state.copyWith(preferences: saved);
    } catch (e) {
      // Revert or show error
      state = state.copyWith(errorMessage: 'Failed to update preferences: $e');
    }
  }

  /// Run offline inventory check and refresh notifications
  Future<void> runLocalScan(String homeId, {String? userId}) async {
    await _engine.scanInventory(homeId, userId: userId);
    await loadNotifications();
  }
}
