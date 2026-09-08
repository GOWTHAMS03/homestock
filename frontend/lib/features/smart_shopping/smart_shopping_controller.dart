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
  final BasketComparisonResult? basketResult;
  final ShoppingSessionModel? currentSession;
  final List<ProviderCapabilityModel> providers;
  final String? selectedOptionType;
  final Set<String> dismissedWarnings;
  final String? errorMessage;
  final bool isOffline;

  const SmartShoppingState({
    this.isLoading = false,
    this.result,
    this.basketResult,
    this.currentSession,
    this.providers = const [],
    this.selectedOptionType,
    this.dismissedWarnings = const {},
    this.errorMessage,
    this.isOffline = false,
  });

  SmartShoppingState copyWith({
    bool? isLoading,
    PriceComparisonResult? result,
    BasketComparisonResult? basketResult,
    ShoppingSessionModel? currentSession,
    List<ProviderCapabilityModel>? providers,
    String? selectedOptionType,
    Set<String>? dismissedWarnings,
    String? errorMessage,
    bool? isOffline,
  }) {
    return SmartShoppingState(
      isLoading: isLoading ?? this.isLoading,
      result: result ?? this.result,
      basketResult: basketResult ?? this.basketResult,
      currentSession: currentSession ?? this.currentSession,
      providers: providers ?? this.providers,
      selectedOptionType: selectedOptionType ?? this.selectedOptionType,
      dismissedWarnings: dismissedWarnings ?? this.dismissedWarnings,
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

  /// Fetch price comparison for a single shopping item.
  Future<void> fetchOffers(String homeId, String itemId) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isOffline: false);

    try {
      final result = await _repo.fetchOffers(homeId, itemId);
      final providers = await _repo.fetchProviders(homeId);
      if (mounted) {
        state = state.copyWith(isLoading: false, result: result, providers: providers);
      }
    } catch (e) {
      _handleError(e, 'Unable to fetch prices. Please try again.');
    }
  }

  /// Fetch multi-item basket comparison with split vs single-store optimization.
  Future<void> fetchBasketComparison(
    String homeId, {
    List<String>? itemIds,
    String rankingStrategy = 'BEST_PRICE',
    String? preferredStore,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isOffline: false);

    try {
      final basket = await _repo.fetchBasketComparison(
        homeId,
        itemIds: itemIds,
        rankingStrategy: rankingStrategy,
        preferredStore: preferredStore,
      );
      final providers = await _repo.fetchProviders(homeId);

      // Default selected option: recommended option or first option
      final defaultOption = basket.recommendedOption?.optionType ??
          (basket.options.isNotEmpty ? basket.options.first.optionType : null);

      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          basketResult: basket,
          providers: providers,
          selectedOptionType: defaultOption,
        );
      }
    } catch (e) {
      _handleError(e, 'Unable to compare basket prices. Please try again.');
    }
  }

  void selectBasketOption(String optionType) {
    state = state.copyWith(selectedOptionType: optionType);
  }

  void dismissWarning(String itemId) {
    final updated = Set<String>.from(state.dismissedWarnings)..add(itemId);
    state = state.copyWith(dismissedWarnings: updated);
  }

  /// Start a shopping session.
  Future<ShoppingSessionModel?> startSession(
    String homeId, {
    List<String>? itemIds,
    String? selectedProviders,
    double? estimatedTotal,
    String? recommendedOption,
  }) async {
    try {
      final session = await _repo.createSession(
        homeId,
        itemIds: itemIds,
        selectedProviders: selectedProviders,
        estimatedTotal: estimatedTotal,
        recommendedOption: recommendedOption,
      );
      state = state.copyWith(currentSession: session);
      return session;
    } catch (e) {
      return null;
    }
  }

  /// Complete shopping session and record purchase.
  Future<bool> completeSession(
    String homeId,
    String sessionId,
    Map<String, dynamic> payload,
  ) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repo.completeSession(homeId, sessionId, payload);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to complete purchase: $e');
      return false;
    }
  }

  /// Report local offline price.
  Future<bool> reportLocalPrice(String homeId, Map<String, dynamic> payload) async {
    try {
      await _repo.reportLocalPrice(homeId, payload);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Record affiliate click and open the URL.
  Future<void> openAffiliateLink({
    required String homeId,
    required String shoppingItemId,
    required String provider,
    required String providerProductId,
    required String? fallbackUrl,
    String? sessionId,
    String? sourceScreen,
  }) async {
    final affiliateUrl = await _repo.recordAffiliateClick(
      homeId: homeId,
      shoppingItemId: shoppingItemId,
      provider: provider,
      providerProductId: providerProductId,
      sessionId: sessionId,
      sourceScreen: sourceScreen,
    );

    final urlToOpen = affiliateUrl ?? fallbackUrl;
    if (urlToOpen != null && urlToOpen.isNotEmpty) {
      try {
        final uri = Uri.parse(urlToOpen);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        // Non-fatal
      }
    }
  }

  void _handleError(Object e, String fallbackMsg) {
    if (!mounted) return;
    final message = e.toString();
    final isOffline = message.contains('SocketException') ||
        message.contains('Connection refused') ||
        message.contains('No route to host');

    state = state.copyWith(
      isLoading: false,
      errorMessage: isOffline
          ? 'Price comparison requires an internet connection.'
          : fallbackMsg,
      isOffline: isOffline,
    );
  }
}
