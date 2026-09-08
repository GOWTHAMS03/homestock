class ApiEndpoints {
  ApiEndpoints._();

  // Android emulator uses 10.0.2.2, desktop/web uses localhost, physical phone uses PC LAN IP or 127.0.0.1 with adb reverse
  static const String currentWifiUrl = 'http://192.168.0.182:8080/api/v1';
  static const String usbAdbUrl = 'http://127.0.0.1:8080/api/v1';
  static const String emulatorUrl = 'http://10.0.2.2:8080/api/v1';
  static const String localhostUrl = 'http://localhost:8080/api/v1';

  static const String defaultUrl = currentWifiUrl;
  static String baseUrl = const String.fromEnvironment('API_BASE_URL', defaultValue: defaultUrl);

  static void setBaseUrl(String url) {
    baseUrl = url;
  }

  /// Candidate backend URLs to test in order of preference
  static List<String> get candidateUrls => {
        baseUrl,
        usbAdbUrl,
        currentWifiUrl,
        emulatorUrl,
        localhostUrl,
      }.toList();

  // Auth
  static const String ping = '/auth/ping';
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String inviteLogin = '/auth/invite-login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';

  // User
  static const String userMe = '/users/me';
  static const String deviceToken = '/users/me/device-tokens';

  // Homes
  static const String homes = '/homes';
  static const String joinHome = '/homes/join';
  static String homeById(String homeId) => '/homes/$homeId';
  static String homeMembers(String homeId) => '/homes/$homeId/members';
  static String memberRole(String homeId, String userId) => '/homes/$homeId/members/$userId/role';
  static String removeMember(String homeId, String userId) => '/homes/$homeId/members/$userId';

  // Categories
  static String categories(String homeId) => '/homes/$homeId/categories';

  // Inventory
  static String items(String homeId) => '/homes/$homeId/items';
  static String itemById(String homeId, String itemId) => '/homes/$homeId/items/$itemId';
  static String itemStock(String homeId, String itemId) => '/homes/$homeId/items/$itemId/stock';
  static String itemTransactions(String homeId, String itemId) => '/homes/$homeId/items/$itemId/transactions';
  static String itemImage(String homeId, String itemId) => '/homes/$homeId/items/$itemId/image';

  // Shopping Lists
  static String defaultShoppingList(String homeId) => '/homes/$homeId/shopping-lists/default';
  static String shoppingItems(String homeId, String listId) => '/homes/$homeId/shopping-lists/$listId/items';
  static String shoppingItemById(String homeId, String listId, String itemId) => '/homes/$homeId/shopping-lists/$listId/items/$itemId';
  static String toggleShoppingItem(String homeId, String listId, String itemId) => '/homes/$homeId/shopping-lists/$listId/items/$itemId/toggle';
  static String clearCompletedShopping(String homeId, String listId) => '/homes/$homeId/shopping-lists/$listId/clear-completed';

  // Stores & Purchases
  static String stores(String homeId) => '/homes/$homeId/stores';
  static String purchases(String homeId) => '/homes/$homeId/purchases';
  static String purchaseById(String homeId, String purchaseId) => '/homes/$homeId/purchases/$purchaseId';

  // Dashboard & Smart Recommendations
  static String dashboard(String homeId) => '/homes/$homeId/dashboard';
  static String whatDoINeed(String homeId) => '/homes/$homeId/dashboard/what-do-i-need';

  // Analytics
  static String analytics(String homeId) => '/homes/$homeId/analytics';

  // Notifications
  static const String notifications = '/notifications';
  static String readNotification(String id) => '/notifications/$id/read';
  static const String readAllNotifications = '/notifications/read-all';

  // Smart Shopping — Price Comparison
  static String itemOffers(String homeId, String itemId) =>
      '/homes/$homeId/shopping-list/items/$itemId/offers';
  static String basketCompare(String homeId) =>
      '/homes/$homeId/shopping/compare/basket';
  static String shoppingSessions(String homeId) =>
      '/homes/$homeId/shopping/sessions';
  static String completeShoppingSession(String homeId, String sessionId) =>
      '/homes/$homeId/shopping/sessions/$sessionId/complete';
  static String reportLocalPrice(String homeId) =>
      '/homes/$homeId/shopping/local-price';
  static String shoppingProviders(String homeId) =>
      '/homes/$homeId/shopping/providers';
  static String shoppingPriceHistory(String homeId) =>
      '/homes/$homeId/shopping/price-history';
  static String affiliateClick(String homeId) =>
      '/homes/$homeId/affiliate/click';
  static const String shoppingCompare = '/shopping/compare';

  // Voice & STT
  static const String voiceTranscribe = '/voice/transcribe';
  static const String voiceCommand = '/voice/command';
  static const String voiceProcessAudio = '/voice/process-audio';
  static const String voiceExecute = '/voice/execute';
}

