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
import 'core/theme/app_theme.dart';
import 'features/home_switcher/home_controller.dart';

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

  // 4. Initialize ApiClient
  final apiClient = ApiClient(secureStorage: secureStorage);

  // 5. Initialize ConnectivityMonitor
  final connectivityMonitor = ConnectivityMonitor();
  await connectivityMonitor.start();

  // 6. Initialize SyncEngine
  final syncEngine = SyncEngine(
    database: database,
    apiClient: apiClient,
    connectivity: connectivityMonitor,
  );

  // 7. Start auto-sync (listens to connectivity changes & retry queues)
  syncEngine.startAutoSync();

  runApp(
    ProviderScope(
      overrides: [
        cacheServiceProvider.overrideWithValue(cacheService),
        databaseProvider.overrideWithValue(database),
        connectivityMonitorProvider.overrideWithValue(connectivityMonitor),
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
    // Pre-load homes on app boot
    Future.microtask(() => ref.read(homeControllerProvider.notifier).loadHomes());
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'HomeStock',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
