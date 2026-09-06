import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_controller.dart';
import 'notification_model.dart';
import 'notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return NotificationRepository(apiClient: client);
});

class NotificationState {
  final bool isLoading;
  final List<NotificationModel> notifications;
  final String? errorMessage;

  const NotificationState({
    this.isLoading = false,
    this.notifications = const [],
    this.errorMessage,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotificationState copyWith({
    bool? isLoading,
    List<NotificationModel>? notifications,
    String? errorMessage,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      notifications: notifications ?? this.notifications,
      errorMessage: errorMessage,
    );
  }
}

final notificationControllerProvider = StateNotifierProvider<NotificationController, NotificationState>((ref) {
  final repo = ref.watch(notificationRepositoryProvider);
  return NotificationController(repo);
});

class NotificationController extends StateNotifier<NotificationState> {
  final NotificationRepository _repo;

  NotificationController(this._repo) : super(const NotificationState()) {
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _repo.getNotifications();
      state = state.copyWith(isLoading: false, notifications: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _repo.markAsRead(id);
      final updated = state.notifications.map((n) {
        if (n.id == id) {
          return NotificationModel(
            id: n.id,
            homeId: n.homeId,
            type: n.type,
            title: n.title,
            body: n.body,
            isRead: true,
            createdAt: n.createdAt,
          );
        }
        return n;
      }).toList();
      state = state.copyWith(notifications: updated);
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      await _repo.markAllAsRead();
      final updated = state.notifications.map((n) {
        return NotificationModel(
          id: n.id,
          homeId: n.homeId,
          type: n.type,
          title: n.title,
          body: n.body,
          isRead: true,
          createdAt: n.createdAt,
        );
      }).toList();
      state = state.copyWith(notifications: updated);
    } catch (_) {}
  }
}
