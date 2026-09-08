/// Raw and cleaned speech recognition transcript metadata
class VoiceTranscript {
  final String rawText;
  final String cleanText;
  final String language;
  final double confidence;
  final bool isOffline;
  final int durationMs;

  const VoiceTranscript({
    required this.rawText,
    required this.cleanText,
    this.language = 'auto',
    this.confidence = 1.0,
    this.isOffline = false,
    this.durationMs = 0,
  });

  factory VoiceTranscript.fromJson(Map<String, dynamic> json) {
    final raw = json['rawText'] as String? ?? json['transcript'] as String? ?? '';
    return VoiceTranscript(
      rawText: raw,
      cleanText: json['cleanText'] as String? ?? raw.trim(),
      language: json['language'] as String? ?? 'auto',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      isOffline: json['isOffline'] as bool? ?? false,
      durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rawText': rawText,
      'cleanText': cleanText,
      'language': language,
      'confidence': confidence,
      'isOffline': isOffline,
      'durationMs': durationMs,
    };
  }

  VoiceTranscript copyWith({
    String? rawText,
    String? cleanText,
    String? language,
    double? confidence,
    bool? isOffline,
    int? durationMs,
  }) {
    return VoiceTranscript(
      rawText: rawText ?? this.rawText,
      cleanText: cleanText ?? this.cleanText,
      language: language ?? this.language,
      confidence: confidence ?? this.confidence,
      isOffline: isOffline ?? this.isOffline,
      durationMs: durationMs ?? this.durationMs,
    );
  }
}
