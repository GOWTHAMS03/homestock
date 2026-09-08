import '../../../../core/voice/number_parser/number_words.dart';

/// Result of quantity extraction
class QuantityParseResult {
  final double? quantity;
  final double confidence;
  final String? rawSpan;
  final String textWithoutQuantity;

  const QuantityParseResult({
    this.quantity,
    this.confidence = 1.0,
    this.rawSpan,
    required this.textWithoutQuantity,
  });
}

/// Robust quantity parser supporting numeric digits, decimals, spoken English,
/// Tamil script, and Tanglish numerals and fractions.
class QuantityParser {
  /// Extracts the primary quantity from [text].
  static QuantityParseResult parse(String text) {
    if (text.trim().isEmpty) {
      return QuantityParseResult(
        quantity: null,
        confidence: 0.0,
        textWithoutQuantity: text,
      );
    }

    final lower = text.toLowerCase();

    // 1. First check sorted multi-word compound phrases (e.g. "one and a half", "two and half", "one-and-a-half")
    for (final entry in NumberWords.sortedEntries) {
      if (entry.key.contains(' ') || entry.key.contains('-')) {
        final pattern = _createWordPattern(entry.key);
        final match = pattern.firstMatch(lower);
        if (match != null) {
          final remainder = text.replaceRange(match.start, match.end, ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
          return QuantityParseResult(
            quantity: entry.value,
            confidence: 0.98,
            rawSpan: match.group(0),
            textWithoutQuantity: remainder,
          );
        }
      }
    }

    // 2. Check numeric digits & decimals (e.g. "2", "2.5", "0.5", "1/2")
    final numericPattern = RegExp(r'\b(\d+(?:\.\d+)?)\b');
    final numMatch = numericPattern.firstMatch(text);
    if (numMatch != null) {
      final valStr = numMatch.group(1)!;
      final val = double.tryParse(valStr);
      if (val != null) {
        final remainder = text.replaceRange(numMatch.start, numMatch.end, ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
        return QuantityParseResult(
          quantity: val,
          confidence: 1.0,
          rawSpan: valStr,
          textWithoutQuantity: remainder,
        );
      }
    }

    // 3. Check single-word spoken numbers, Tamil numbers, Tanglish fractions (e.g. "rendu", "moonu", "arai", "half")
    for (final entry in NumberWords.sortedEntries) {
      final pattern = _createWordPattern(entry.key);
      final match = pattern.firstMatch(lower);
      if (match != null) {
        final remainder = text.replaceRange(match.start, match.end, ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
        return QuantityParseResult(
          quantity: entry.value,
          confidence: 0.95,
          rawSpan: match.group(0),
          textWithoutQuantity: remainder,
        );
      }
    }

    // No quantity detected
    return QuantityParseResult(
      quantity: null,
      confidence: 0.0,
      textWithoutQuantity: text,
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
