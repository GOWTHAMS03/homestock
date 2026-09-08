import 'voice_models.dart' show DisambiguationOption, VoiceIntentType;

/// The canonical, unified command object produced by the deterministic command parser,
/// whether running on-device offline or online.
class NormalizedVoiceCommand {
  final String operationId;
  final VoiceIntentType intent;
  final String? productId;
  final String? productName;
  final String productQuery;
  final double? quantity;
  final String? unit;
  final String? brand;
  final double? price;
  final String? category;
  final double confidence; // overall confidence
  final double intentConfidence;
  final double productConfidence;
  final double quantityConfidence;
  final double unitConfidence;
  final bool requiresConfirmation;
  final String? confirmationMessage;
  final List<DisambiguationOption> disambiguationOptions;
  final bool isOffline;
  final String rawTranscript;

  const NormalizedVoiceCommand({
    required this.operationId,
    required this.intent,
    this.productId,
    this.productName,
    required this.productQuery,
    this.quantity,
    this.unit,
    this.brand,
    this.price,
    this.category,
    this.confidence = 1.0,
    this.intentConfidence = 1.0,
    this.productConfidence = 1.0,
    this.quantityConfidence = 1.0,
    this.unitConfidence = 1.0,
    this.requiresConfirmation = false,
    this.confirmationMessage,
    this.disambiguationOptions = const [],
    this.isOffline = false,
    this.rawTranscript = '',
  });

  factory NormalizedVoiceCommand.fromJson(Map<String, dynamic> json) {
    return NormalizedVoiceCommand(
      operationId: json['operationId'] as String? ?? '',
      intent: VoiceIntentType.fromString(json['intent'] as String?),
      productId: json['productId'] as String?,
      productName: json['productName'] as String?,
      productQuery: json['productQuery'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      brand: json['brand'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      category: json['category'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      intentConfidence: (json['intentConfidence'] as num?)?.toDouble() ?? 1.0,
      productConfidence: (json['productConfidence'] as num?)?.toDouble() ?? 1.0,
      quantityConfidence: (json['quantityConfidence'] as num?)?.toDouble() ?? 1.0,
      unitConfidence: (json['unitConfidence'] as num?)?.toDouble() ?? 1.0,
      requiresConfirmation: json['requiresConfirmation'] as bool? ?? false,
      confirmationMessage: json['confirmationMessage'] as String?,
      disambiguationOptions: (json['disambiguationOptions'] as List<dynamic>?)
              ?.map((e) => DisambiguationOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      isOffline: json['isOffline'] as bool? ?? false,
      rawTranscript: json['rawTranscript'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'operationId': operationId,
      'intent': intent.toServerString(),
      if (productId != null) 'productId': productId,
      if (productName != null) 'productName': productName,
      'productQuery': productQuery,
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (brand != null) 'brand': brand,
      if (price != null) 'price': price,
      if (category != null) 'category': category,
      'confidence': confidence,
      'intentConfidence': intentConfidence,
      'productConfidence': productConfidence,
      'quantityConfidence': quantityConfidence,
      'unitConfidence': unitConfidence,
      'requiresConfirmation': requiresConfirmation,
      if (confirmationMessage != null) 'confirmationMessage': confirmationMessage,
      'disambiguationOptions': disambiguationOptions.map((o) => o.toJson()).toList(),
      'isOffline': isOffline,
      'rawTranscript': rawTranscript,
    };
  }

  NormalizedVoiceCommand copyWith({
    String? operationId,
    VoiceIntentType? intent,
    String? productId,
    String? productName,
    String? productQuery,
    double? quantity,
    String? unit,
    String? brand,
    double? price,
    String? category,
    double? confidence,
    double? intentConfidence,
    double? productConfidence,
    double? quantityConfidence,
    double? unitConfidence,
    bool? requiresConfirmation,
    String? confirmationMessage,
    List<DisambiguationOption>? disambiguationOptions,
    bool? isOffline,
    String? rawTranscript,
  }) {
    return NormalizedVoiceCommand(
      operationId: operationId ?? this.operationId,
      intent: intent ?? this.intent,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productQuery: productQuery ?? this.productQuery,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      brand: brand ?? this.brand,
      price: price ?? this.price,
      category: category ?? this.category,
      confidence: confidence ?? this.confidence,
      intentConfidence: intentConfidence ?? this.intentConfidence,
      productConfidence: productConfidence ?? this.productConfidence,
      quantityConfidence: quantityConfidence ?? this.quantityConfidence,
      unitConfidence: unitConfidence ?? this.unitConfidence,
      requiresConfirmation: requiresConfirmation ?? this.requiresConfirmation,
      confirmationMessage: confirmationMessage ?? this.confirmationMessage,
      disambiguationOptions: disambiguationOptions ?? this.disambiguationOptions,
      isOffline: isOffline ?? this.isOffline,
      rawTranscript: rawTranscript ?? this.rawTranscript,
    );
  }
}
