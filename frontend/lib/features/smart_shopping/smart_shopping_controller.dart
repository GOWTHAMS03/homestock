import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../auth/auth_controller.dart';
import 'smart_shopping_models.dart';
import 'smart_shopping_repository.dart';

final smartShoppingRepositoryProvider = Provider<SmartShoppingRepository>((ref) {
  return SmartShoppingRepository(
    apiClient: ref.watch(apiClientProvider),
  );
});

// ──── State ────

class SmartShoppingState {
  final bool isLoading;
  final PriceComparisonResult? result;
  final String? errorMessage;
  final bool isOffline;

  const SmartShoppingState({
    this.isLoading = false,
    this.result,
    this.errorMessage,
    this.isOffline = false,
  });

  SmartShoppingState copyWith({
    bool? isLoading,
    PriceComparisonResult? result,
    String? errorMessage,
    bool? isOffline,
  }) {
    return SmartShoppingState(
      isLoading: isLoading ?? this.isLoading,
      result: result ?? this.result,
      errorMessage: errorMessage,
      isOffline: isOffline ?? this.isOffline,
    );
  }
}

// ──── Controller ────

final smartShoppingControllerProvider =
    StateNotifierProvider.autoDispose<SmartShoppingController, SmartShoppingState>((ref) {
  final repo = ref.watch(smartShoppingRepositoryProvider);
  return SmartShoppingController(repo);
});

class SmartShoppingController extends StateNotifier<SmartShoppingState> {
  final SmartShoppingRepository _repo;

  SmartShoppingController(this._repo) : super(const SmartShoppingState());

  /// Fetch price comparison for a shopping item.
  Future<void> fetchOffers(String homeId, String itemId) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isOffline: false);

    try {
      final result = await _repo.fetchOffers(homeId, itemId);
      if (mounted) {
        state = state.copyWith(isLoading: false, result: result);
      }
    } catch (e) {
      if (mounted) {
        final message = e.toString();
        final isOffline = message.contains('SocketException') ||
            message.contains('Connection refused') ||
            message.contains('No route to host');

        state = state.copyWith(
          isLoading: false,
          errorMessage: isOffline
              ? 'Price comparison requires an internet connection.'
              : 'Unable to fetch prices. Please try again.',
          isOffline: isOffline,
        );
      }
    }
  }

  /// Record affiliate click and open the URL.
  Future<void> openAffiliateLink({
    required String homeId,
    required String shoppingItemId,
    required String provider,
    required String providerProductId,
    required String? fallbackUrl,
  }) async {
    // Record the click and get affiliate URL from backend
    final affiliateUrl = await _repo.recordAffiliateClick(
      homeId: homeId,
      shoppingItemId: shoppingItemId,
      provider: provider,
      providerProductId: providerProductId,
    );

    final urlToOpen = affiliateUrl ?? fallbackUrl;
    if (urlToOpen != null && urlToOpen.isNotEmpty) {
      try {
        final uri = Uri.parse(urlToOpen);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        // URL launch failed — non-fatal
      }
    }
  }
}
