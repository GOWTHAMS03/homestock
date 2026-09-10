import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/auth_controller.dart' show apiClientProvider;
import '../sync/sync_providers.dart';
import 'local_notification_engine.dart';
import 'notification_service.dart';
import '../../features/notifications/notification_repository.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService.instance;
});

final localNotificationEngineProvider = Provider<LocalNotificationEngine>((ref) {
  final invDao = ref.watch(inventoryDaoProvider);
  final notifDao = ref.watch(notificationDaoProvider);
  final service = ref.watch(notificationServiceProvider);
  return LocalNotificationEngine(
    inventoryDao: invDao,
    notificationDao: notifDao,
    notificationService: service,
  );
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  final dao = ref.watch(notificationDaoProvider);
  final conn = ref.watch(connectivityMonitorProvider);
  return NotificationRepository(
    apiClient: client,
    notificationDao: dao,
    connectivityMonitor: conn,
  );
});

