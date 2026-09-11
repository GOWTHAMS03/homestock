import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/api_endpoints.dart';
import 'core/database/app_database.dart';
import 'core/network/api_client.dart';
import 'core/router/app_router.dart';
import 'core/storage/cache_service.dart';
import 'core/storage/secure_storage_service.dart';
import 'core/sync/connectivity_monitor.dart';
import 'core/sync/sync_engine.dart';
import 'core/sync/sync_providers.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/auth_controller.dart' show apiClientProvider, secureStorageProvider;
import 'features/home_switcher/home_controller.dart';
import 'core/notifications/notification_service.dart';
import 'core/notifications/notification_providers.dart';
import 'core/widgets/in_app_notification_banner.dart';
import 'features/notifications/notification_controller.dart';
import 'features/notifications/notification_repository.dart';
import 'package:go_router/go_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Drift SQLite database (immediate local access)
  final database = AppDatabase();

  // 2. Initialize Hive cache for auth tokens and simple KV settings
  final cacheService = CacheService();
  try {
    await cacheService.init();
  } catch (_) {}

  // 3. Initialize secure storage & base URL
  final secureStorage = SecureStorageService(cacheService: cacheService);
  try {
    final savedUrl = await secureStorage.getBaseUrl();
    if (savedUrl != null && savedUrl.trim().isNotEmpty) {
      ApiEndpoints.setBaseUrl(savedUrl.trim());
    }
  } catch (_) {}

  // 4. Initialize ConnectivityMonitor
  final connectivityMonitor = ConnectivityMonitor();

  // 5. Initialize ApiClient with fast reachability feedback and discovery listener
  final apiClient = ApiClient(
    secureStorage: secureStorage,
    connectivityMonitor: connectivityMonitor,
  );

  // 6. Start monitoring and dynamic server discovery
  await connectivityMonitor.start();

  // 6. Initialize SyncEngine
  final syncEngine = SyncEngine(
    database: database,
    apiClient: apiClient,
    connectivity: connectivityMonitor,
  );

  // 7. Start auto-sync (listens to connectivity changes & retry queues)
  syncEngine.startAutoSync();

  // 8. Initialize NotificationService
  try {
    await NotificationService.instance.initialize(
      navigateCallback: (route) {
        rootNavigatorKey.currentContext?.push(route);
      },
      silentSyncCallback: (homeId) {
        syncEngine.syncHome(homeId);
      },
      tokenCallback: (token) async {
        debugPrint('[Main] FCM Token acquired: ${token.substring(0, 10)}... Registering with backend');
        try {
          final notifRepo = NotificationRepository(
            apiClient: apiClient,
            connectivityMonitor: connectivityMonitor,
          );
          await notifRepo.registerDeviceToken(
            token: token,
            platform: 'ANDROID',
          );
        } catch (e) {
          debugPrint('[Main] Token registration failed on startup: $e');
        }
      },
      payloadTapCallback: (payload) {
        // Payload-based navigation will be handled by NotificationRouter
        // at tap time within the widget tree (requires WidgetRef).
        // This fallback uses the legacy route-string approach.
        final entityId = payload['entityId']?.toString() ?? payload['itemId']?.toString();
        final type = (payload['type']?.toString() ?? '').toUpperCase();
        String route = '/notifications';
        if (entityId != null && entityId.isNotEmpty &&
            (type.contains('STOCK') || type.contains('EXPIR') || type == 'SMART_RESTOCK_SUGGESTION')) {
          route = '/inventory/detail/$entityId';
        } else if (type == 'SHOPPING_LIST_UPDATE') {
          route = '/shopping';
        } else if (type == 'WEEKLY_INSIGHT' || type == 'MONTHLY_REPORT') {
          route = '/analytics';
        }
        rootNavigatorKey.currentContext?.push(route);
      },
      foregroundNotificationCallback: (title, body, data) {
        final context = rootNavigatorKey.currentContext;
        if (context == null) return;
        final type = (data['type']?.toString() ?? 'SYSTEM').toUpperCase();
        final entityId = data['entityId']?.toString() ?? data['itemId']?.toString();

        InAppNotificationBanner.show(
          context: context,
          title: title,
          body: body,
          type: type,
          entityId: entityId,
          payload: data,
          onTap: () {
            String route = '/notifications';
            if (entityId != null && entityId.isNotEmpty &&
                (type.contains('STOCK') || type.contains('EXPIR') || type == 'SMART_RESTOCK_SUGGESTION')) {
              route = '/inventory/detail/$entityId';
            } else if (type == 'SHOPPING_LIST_UPDATE') {
              route = '/shopping';
            } else if (type == 'WEEKLY_INSIGHT' || type == 'MONTHLY_REPORT') {
              route = '/analytics';
            }
            rootNavigatorKey.currentContext?.push(route);
          },
          onActionTap: () {
            if (type.contains('STOCK') || type == 'SMART_RESTOCK_SUGGESTION') {
              rootNavigatorKey.currentContext?.push('/shopping');
            } else if (type.contains('EXPIR')) {
              if (entityId != null && entityId.isNotEmpty) {
                rootNavigatorKey.currentContext?.push('/inventory/detail/$entityId');
              }
            } else if (type == 'SHOPPING_LIST_UPDATE') {
              rootNavigatorKey.currentContext?.push('/shopping');
            }
          },
        );
      },
    );
  } catch (e) {
    debugPrint('[Main] NotificationService initialization warning: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        cacheServiceProvider.overrideWithValue(cacheService),
        secureStorageProvider.overrideWithValue(secureStorage),
        databaseProvider.overrideWithValue(database),
        connectivityMonitorProvider.overrideWithValue(connectivityMonitor),
        apiClientProvider.overrideWithValue(apiClient),
        syncEngineProvider.overrideWithValue(syncEngine),
      ],
      child: const HomeStockApp(),
    ),
  );
}

class HomeStockApp extends ConsumerStatefulWidget {
  const HomeStockApp({super.key});

  @override
  ConsumerState<HomeStockApp> createState() => _HomeStockAppState();
}

class _HomeStockAppState extends ConsumerState<HomeStockApp> {
  @override
  void initState() {
    super.initState();
    // Pre-load homes on app boot & run offline notification checks
    Future.microtask(() async {
      await ref.read(homeControllerProvider.notifier).loadHomes();
      final activeHome = ref.read(homeControllerProvider).activeHome;
      if (activeHome != null) {
        await ref.read(localNotificationEngineProvider).scanInventory(
          activeHome.id,
          showSystemNotification: false,
        );
      }
      ref.read(notificationControllerProvider.notifier).loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final theme = ref.watch(appThemeProvider);

    return MaterialApp.router(
      title: 'HomeStock',
      debugShowCheckedModeBanner: false,
      theme: theme,
      routerConfig: router,
    );
  }
}
