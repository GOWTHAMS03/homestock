import '../../../../core/voice/unit_normalizer/unit_dictionary.dart';

/// Result of unit extraction
class UnitParseResult {
  final String? unit; // Canonical unit e.g. 'kg', 'L', 'g', 'packet', 'pcs'
  final double confidence;
  final String? rawSpan;
  final String textWithoutUnit;
  final bool isCompatible;

  const UnitParseResult({
    this.unit,
    this.confidence = 1.0,
    this.rawSpan,
    required this.textWithoutUnit,
    this.isCompatible = true,
  });
}

/// Unit parser that identifies measurement tokens and checks compatibility
class UnitParser {
  /// Extracts the unit from [text] and removes the unit token.
  static UnitParseResult parse(String text, {String? categoryContext}) {
    if (text.trim().isEmpty) {
      return UnitParseResult(
        unit: null,
        confidence: 0.0,
        textWithoutUnit: text,
      );
    }

    final lower = text.toLowerCase();

    // Iterate through sorted unit keys (longest first to match e.g. 'kilograms' before 'g')
    for (final key in UnitDictionary.sortedUnitKeys) {
      final pattern = _createWordPattern(key);
      final match = pattern.firstMatch(lower);
      if (match != null) {
        final canonical = UnitDictionary.normalize(key);
        final remainder = text.replaceRange(match.start, match.end, ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

        bool compatible = true;
        if (canonical != null && categoryContext != null && categoryContext.isNotEmpty) {
          compatible = UnitDictionary.isCompatible(canonical, categoryContext);
        }

        return UnitParseResult(
          unit: canonical,
          confidence: 0.98,
          rawSpan: match.group(0),
          textWithoutUnit: remainder,
          isCompatible: compatible,
        );
      }
    }

    // Default unit when none specified
    return UnitParseResult(
      unit: null,
      confidence: 0.0,
      textWithoutUnit: text,
      isCompatible: true,
    );
  }

  static RegExp _createWordPattern(String word) {
    final isAscii = RegExp(r'^[\x00-\x7F]+$').hasMatch(word);
    if (isAscii) {
      return RegExp('\\b${RegExp.escape(word)}\\b', caseSensitive: false);
    } else {
      return RegExp(
        '(?:^|(?<=[\\s,;.!?:()\\-_]))${RegExp.escape(word)}(?=[\\s,;.!?:()\\-_]|\$)',
        caseSensitive: false,
      );
    }
  }
}
