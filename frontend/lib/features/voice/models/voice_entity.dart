/// Extracted named entity from voice command
class VoiceEntity {
  final String name;
  final String type; // 'PRODUCT', 'QUANTITY', 'UNIT', 'BRAND', 'PRICE', 'CATEGORY', 'LOCATION'
  final dynamic value;
  final double confidence;
  final String? rawSpan;

  const VoiceEntity({
    required this.name,
    required this.type,
    required this.value,
    this.confidence = 1.0,
    this.rawSpan,
  });

  factory VoiceEntity.fromJson(Map<String, dynamic> json) {
    return VoiceEntity(
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'PRODUCT',
      value: json['value'],
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      rawSpan: json['rawSpan'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'value': value,
      'confidence': confidence,
      if (rawSpan != null) 'rawSpan': rawSpan,
    };
  }
}
