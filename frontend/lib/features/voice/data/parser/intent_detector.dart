import '../../models/voice_models.dart' show VoiceIntentType;

/// Result of intent detection
class IntentDetectionResult {
  final VoiceIntentType intent;
  final double confidence;
  final String matchedPattern;

  const IntentDetectionResult({
    required this.intent,
    this.confidence = 1.0,
    required this.matchedPattern,
  });
}

/// Detects voice command intent from clean normalized transcript
class IntentDetector {
  /// Analyzes normalized [text] and returns detected intent with confidence score.
  static IntentDetectionResult detect(String text) {
    final lower = text.toLowerCase().trim();

    // 1. Navigation & Screen Switching
    if (_matchesAny(lower, [
      'open shopping list', 'go to shopping list', 'shopping list open',
      'shopping list kaatu', 'show shopping list', 'view shopping list',
      'பட்டியலை காட்டு', 'பட்டியல் திற',
    ])) {
      return const IntentDetectionResult(
        intent: VoiceIntentType.openShoppingList,
        confidence: 0.98,
        matchedPattern: 'open_shopping_list',
      );
    }

    if (_matchesAny(lower, [
      'open inventory', 'go to inventory', 'open pantry', 'inventory open',
      'inventory kaatu', 'show inventory', 'பண்டகசாலை', 'சரக்கு இருப்பு',
    ])) {
      return const IntentDetectionResult(
        intent: VoiceIntentType.openInventory,
        confidence: 0.98,
        matchedPattern: 'open_inventory',
      );
    }

    if (_matchesAny(lower, [
      'open analytics', 'show analytics', 'spending', 'expenses', 'selavu',
      'selavu evlo', 'spending analytics', 'செலவு', 'பகுப்பாய்வு',
    ])) {
      return const IntentDetectionResult(
        intent: VoiceIntentType.openAnalytics,
        confidence: 0.95,
        matchedPattern: 'open_analytics',
      );
    }

    if (_matchesAny(lower, [
      'shopping mode start', 'start shopping mode', 'in store mode',
      'store mode', 'kadai mode', 'shopping mode',
    ])) {
      return const IntentDetectionResult(
        intent: VoiceIntentType.startShoppingMode,
        confidence: 0.98,
        matchedPattern: 'start_shopping_mode',
      );
    }

    // 2. Destructive Operations: Clear / Delete All
    if (_matchesAny(lower, [
      'delete all shopping', 'clear all shopping', 'clear shopping list',
      'delete shopping list', 'remove all shopping', 'முழுவதும் நீக்கு',
    ])) {
      return const IntentDetectionResult(
        intent: VoiceIntentType.clearShoppingList,
        confidence: 0.98,
        matchedPattern: 'clear_shopping_list',
      );
    }

    // 3. Purchase History & Spending
    if (_matchesAny(lower, [
      'purchase history', 'recent purchases', 'history kaatu',
      'recents kaatu', 'vaangina list',
    ])) {
      return const IntentDetectionResult(
        intent: VoiceIntentType.getPurchaseHistory,
        confidence: 0.95,
        matchedPattern: 'purchase_history',
      );
    }

    // 4. Smart Queries (Low stock, out of stock, expiring, what do I need)
    if (_matchesAny(lower, [
      'what do i need', 'enna vanganu', 'enna vaanganum', 'what should i buy',
      'recommend restock', 'recommendation', 'என்ன வாங்க வேண்டும்',
    ])) {
      return const IntentDetectionResult(
        intent: VoiceIntentType.whatDoINeed,
        confidence: 0.96,
        matchedPattern: 'what_do_i_need',
      );
    }

    if (_matchesAny(lower, [
      'running low', 'low stock', 'kammiya irukku', 'theera pogudhu',
      'what is running low', 'low stock items', 'குறைவாக இருக்கிறது', 'குறைவு',
    ])) {
      return const IntentDetectionResult(
        intent: VoiceIntentType.getLowStockItems,
        confidence: 0.96,
        matchedPattern: 'low_stock',
      );
    }

    if (_matchesAny(lower, [
      'out of stock', 'stock out', 'kaali aayiduchu', 'kaali aachu',
      'theendhuduchu', 'mudinjuruchu', 'தீர்ந்துவிட்டது', 'காலி',
    ]) && !_hasQuantity(lower)) {
      return const IntentDetectionResult(
        intent: VoiceIntentType.getOutOfStockItems,
        confidence: 0.94,
        matchedPattern: 'out_of_stock',
      );
    }

    if (_matchesAny(lower, [
      'expiring soon', 'expiring items', 'what is expiring',
      'expire aaga pogudhu', 'காலாவதி',
    ])) {
      return const IntentDetectionResult(
        intent: VoiceIntentType.getExpiringItems,
        confidence: 0.96,
        matchedPattern: 'expiring',
      );
    }

    // 5. Price Comparison / Smart Price Check
    if (_matchesAny(lower, [
      'cheapest price', 'cheapest enga', 'where can i buy', 'find cheapest',
      'price comparison', 'compare price', 'compare prices', 'best offer',
      'enga kammiya kedaikkum', 'vilai', 'விலை',
    ])) {
      return const IntentDetectionResult(
        intent: VoiceIntentType.smartPriceCheck,
        confidence: 0.95,
        matchedPattern: 'smart_price_check',
      );
    }

    // 6. Complete Shopping Item / Mark Bought
    if (_matchesAny(lower, [
      'bought', 'vaangiyachu', 'eduthachu', 'mark as bought', 'purchased already',
      'mark bought', 'vaangi aachu', 'வாங்கியாயிற்று',
    ])) {
      return const IntentDetectionResult(
        intent: VoiceIntentType.completeShoppingItem,
        confidence: 0.94,
        matchedPattern: 'mark_bought',
      );
    }

    // 7. Stock Queries ("Veetla rice evlo irukku?", "How much rice at home?")
    if (_matchesAny(lower, [
      'evlo irukku', 'evvalavu irukku', 'how much', 'is there', 'irukka',
      'irukkaa', 'veetla', 'veetil', 'stock check', 'check stock', 'do we have',
      'இருக்கிறதா', 'எவ்வளவு இருக்கிறது',
    ]) && !_hasStockMutationVerb(lower)) {
      return const IntentDetectionResult(
        intent: VoiceIntentType.getItemStatus,
        confidence: 0.95,
        matchedPattern: 'check_stock',
      );
    }

    // 8. Explicit Stock In / Stock Add ("rice stock la 2 kilo add pannu", "oil stock la add pannu")
    if ((lower.contains('stock') || lower.contains('inventory')) &&
        _matchesAny(lower, ['add', 'podu', 'serthu', 'in', 'restock', 'சேர்க்கவும்'])) {
      return const IntentDetectionResult(
        intent: VoiceIntentType.stockIn,
        confidence: 0.96,
        matchedPattern: 'stock_in',
      );
    }

    // 9. Explicit Stock Out / Stock Remove ("2 kilo rice stock la irundhu remove pannu", "used 500 ml oil")
    if (_matchesAny(lower, [
      'used', 'consumed', 'use panniten', 'stock la irundhu remove', 'stock out',
      'stock lerundhu', 'stock la remove', 'கழி', 'பயன்படுத்தினேன்',
    ])) {
      return const IntentDetectionResult(
        intent: VoiceIntentType.stockOut,
        confidence: 0.95,
        matchedPattern: 'stock_out',
      );
    }

    // 10. Update Stock Quantity ("rice stock 5 kg", "set stock")
    if (lower.contains('stock') && _matchesAny(lower, ['set', 'update', 'mathu', 'மாற்று'])) {
      return const IntentDetectionResult(
        intent: VoiceIntentType.updateStock,
        confidence: 0.92,
        matchedPattern: 'update_stock',
      );
    }

    // 11. Remove from Shopping List ("rice remove pannu", "sugar thooku", "remove sugar from shopping list")
    if (_matchesAny(lower, [
          'remove from shopping', 'delete from shopping', 'remove pannu',
          'thooku', 'delete pannu', 'vendam', 'eduthudu', 'நீக்கு',
        ]) ||
        ((lower.contains('remove') || lower.contains('delete')) &&
         (lower.contains('shopping') || lower.contains('list') || lower.contains('பட்டியல்')))) {
      return const IntentDetectionResult(
        intent: VoiceIntentType.removeShoppingItem,
        confidence: 0.94,
        matchedPattern: 'remove_shopping_item',
      );
    }

    // 12. Update Shopping Quantity ("rice quantity 4 kilo mathu")
    if (lower.contains('shopping') && _matchesAny(lower, ['quantity', 'alavu', 'mathu', 'update', 'change'])) {
      return const IntentDetectionResult(
        intent: VoiceIntentType.updateShoppingQuantity,
        confidence: 0.92,
        matchedPattern: 'update_shopping_quantity',
      );
    }

    // 13. Default: Add to Shopping List (Primary core action)
    // Matches "2 kilo rice add pannu", "add 2 kg rice", "rice rendu kilo venum", "2 kilo rice", etc.
    return const IntentDetectionResult(
      intent: VoiceIntentType.addShoppingItem,
      confidence: 0.95,
      matchedPattern: 'default_add_shopping_item',
    );
  }

  static bool _matchesAny(String input, List<String> phrases) {
    for (final p in phrases) {
      if (input.contains(p)) {
        return true;
      }
    }
    return false;
  }

  static bool _hasQuantity(String input) {
    return RegExp(r'\b\d+(\.\d+)?\b').hasMatch(input) ||
        _matchesAny(input, ['kilo', 'litre', 'packet', 'gram', 'onnu', 'rendu', 'moonu', 'half', 'arai']);
  }

  static bool _hasStockMutationVerb(String input) {
    return _matchesAny(input, ['add', 'remove', 'podu', 'used', 'use panniten', 'serthu']);
  }
}
