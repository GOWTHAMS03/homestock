import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/api_endpoints.dart';
import 'core/router/app_router.dart';
import 'core/storage/cache_service.dart';
import 'core/storage/secure_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'features/home_switcher/home_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final cacheService = CacheService();
  try {
    await cacheService.init();
  } catch (_) {}

  final secureStorage = SecureStorageService(cacheService: cacheService);
  try {
    final savedUrl = await secureStorage.getBaseUrl();
    if (savedUrl != null && savedUrl.trim().isNotEmpty) {
      ApiEndpoints.setBaseUrl(savedUrl.trim());
    }
  } catch (_) {}

  runApp(
    ProviderScope(
      overrides: [
        cacheServiceProvider.overrideWithValue(cacheService),
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
