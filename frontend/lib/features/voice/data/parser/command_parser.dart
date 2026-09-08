import 'package:uuid/uuid.dart';

import '../../models/normalized_voice_command.dart';
import '../../models/voice_models.dart' show DisambiguationOption, VoiceIntentType;
import 'entity_extractor.dart';
import 'intent_detector.dart';
import 'product_resolver.dart';
import 'tamil_normalizer.dart';
import 'tanglish_normalizer.dart';

/// The central deterministic voice command parser used identically for both online and offline speech recognition.
class CommandParser {
  static const _uuid = Uuid();

  /// Parses a speech transcript into a fully structured [NormalizedVoiceCommand].
  static NormalizedVoiceCommand parse(
    String rawTranscript, {
    List<ProductCandidate> userInventory = const [],
    List<ProductCandidate> userShoppingList = const [],
    bool isOffline = false,
  }) {
    if (rawTranscript.trim().isEmpty) {
      return NormalizedVoiceCommand(
        operationId: _uuid.v4(),
        intent: VoiceIntentType.unknown,
        productQuery: '',
        confidence: 0.0,
        intentConfidence: 0.0,
        productConfidence: 0.0,
        quantityConfidence: 0.0,
        unitConfidence: 0.0,
        isOffline: isOffline,
        rawTranscript: rawTranscript,
        confirmationMessage: "Sorry, I couldn't hear that. Please try speaking again.",
      );
    }

    // 1. Language Normalization (Tanglish postpositions, Tamil script declensions)
    String cleanText = TanglishNormalizer.normalizeSentence(rawTranscript);
    cleanText = TamilNormalizer.normalizeTamilVerbs(cleanText);

    // 2. Intent Detection
    final intentResult = IntentDetector.detect(cleanText);
    final intent = intentResult.intent;
    final intentConf = intentResult.confidence;

    // 3. For pure screen navigation or empty queries, return early
    if (intent == VoiceIntentType.openShoppingList ||
        intent == VoiceIntentType.openInventory ||
        intent == VoiceIntentType.openAnalytics ||
        intent == VoiceIntentType.startShoppingMode ||
        intent == VoiceIntentType.getShoppingList ||
        intent == VoiceIntentType.getLowStockItems ||
        intent == VoiceIntentType.getOutOfStockItems ||
        intent == VoiceIntentType.getExpiringItems ||
        intent == VoiceIntentType.getPurchaseHistory ||
        intent == VoiceIntentType.whatDoINeed) {
      return NormalizedVoiceCommand(
        operationId: _uuid.v4(),
        intent: intent,
        productQuery: '',
        confidence: intentConf,
        intentConfidence: intentConf,
        productConfidence: 1.0,
        quantityConfidence: 1.0,
        unitConfidence: 1.0,
        requiresConfirmation: false,
        isOffline: isOffline,
        rawTranscript: rawTranscript,
      );
    }

    // 4. For destructive operations, require confirmation
    if (intent == VoiceIntentType.clearShoppingList) {
      return NormalizedVoiceCommand(
        operationId: _uuid.v4(),
        intent: intent,
        productQuery: '',
        confidence: intentConf,
        intentConfidence: intentConf,
        productConfidence: 1.0,
        quantityConfidence: 1.0,
        unitConfidence: 1.0,
        requiresConfirmation: true,
        confirmationMessage: 'Are you sure you want to clear your shopping list?',
        isOffline: isOffline,
        rawTranscript: rawTranscript,
      );
    }

    // 5. Entity Extraction (Quantity, Unit, Brand, Price, Product Query)
    final entities = EntityExtractor.extract(cleanText);

    // 6. Product Resolution
    final productResolution = ProductResolver.resolve(
      entities.productQuery,
      userInventory: userInventory,
      userShoppingList: userShoppingList,
    );

    final resolvedProduct = productResolution.resolvedName;
    final resolvedId = productResolution.resolvedId;
    final productCategory = productResolution.category;
    final productConf = productResolution.confidence;

    // 7. Unit Resolution & Compatibility
    String effectiveUnit;
    double unitConf = entities.unitConfidence;
    bool unitIncompatible = false;

    if (entities.unit != null) {
      effectiveUnit = entities.unit!;
      // Check unit compatibility (e.g. "2 bottles rice" -> incompatible!)
      if (productCategory == 'Grains' || productCategory == 'Pulses & Dal') {
        if (effectiveUnit == 'bottle' || effectiveUnit == 'can' || effectiveUnit == 'L' || effectiveUnit == 'ml') {
          unitIncompatible = true;
        }
      }
    } else {
      effectiveUnit = productResolution.defaultUnit;
      unitConf = 0.90; // Default unit inferred from product category
    }

    // 8. Quantity Resolution
    double? effectiveQuantity = entities.quantity;
    double qtyConf = entities.quantityConfidence;

    if (effectiveQuantity == null) {
      // Default to 1 if adding to shopping or stock, but record lower qty confidence
      if (intent == VoiceIntentType.addShoppingItem || intent == VoiceIntentType.stockIn) {
        effectiveQuantity = 1.0;
        qtyConf = 0.70; // Inferred default
      }
    }

    // 9. Overall Confidence Calculation
    final overallConfidence = (intentConf * 0.35) +
        (productConf * 0.35) +
        (qtyConf * 0.15) +
        (unitConf * 0.15);

    // 10. Confirmation Rules & Warnings
    bool requiresConfirmation = false;
    String? confirmMsg;
    List<DisambiguationOption> disambiguation = [];

    if (productResolution.isAmbiguous) {
      requiresConfirmation = true;
      confirmMsg = 'Which $resolvedProduct do you mean?';
      disambiguation = productResolution.disambiguationOptions;
    } else if (unitIncompatible) {
      requiresConfirmation = true;
      confirmMsg = '$resolvedProduct is usually measured in kg or packets. Did you mean $effectiveQuantity kg?';
    } else if (effectiveQuantity != null && effectiveQuantity >= 50) {
      requiresConfirmation = true;
      confirmMsg = 'Add $effectiveQuantity $effectiveUnit $resolvedProduct? That is a large quantity.';
    } else if (intent == VoiceIntentType.removeShoppingItem) {
      requiresConfirmation = false; // Fast removal for simple items
    }

    return NormalizedVoiceCommand(
      operationId: _uuid.v4(),
      intent: intent,
      productId: resolvedId,
      productName: resolvedProduct,
      productQuery: entities.productQuery.isEmpty ? resolvedProduct : entities.productQuery,
      quantity: effectiveQuantity,
      unit: effectiveUnit,
      brand: entities.brand,
      price: entities.price,
      category: productCategory,
      confidence: double.parse(overallConfidence.toStringAsFixed(3)),
      intentConfidence: intentConf,
      productConfidence: productConf,
      quantityConfidence: qtyConf,
      unitConfidence: unitConf,
      requiresConfirmation: requiresConfirmation,
      confirmationMessage: confirmMsg,
      disambiguationOptions: disambiguation,
      isOffline: isOffline,
      rawTranscript: rawTranscript,
    );
  }
}
