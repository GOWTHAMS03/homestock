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
import 'features/notifications/notification_controller.dart';
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
        await ref.read(localNotificationEngineProvider).scanInventory(activeHome.id);
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
