/// Normalizer for Tanglish (Tamil-English mixed language), colloquial suffixes,
/// agglutinative postpositions, and common ASR transcription variations.
class TanglishNormalizer {
  /// Strips Tamil/Tanglish grammatical postpositions while preserving word roots.
  /// Examples:
  ///   "shopping-list-la" -> "shopping list"
  ///   "rice-ah" -> "rice"
  ///   "stock-lerundhu" -> "stock"
  ///   "arisi-a" -> "arisi"
  ///   "veetla" -> "veedu" or "veet"
  static String cleanPostpositions(String word) {
    if (word.isEmpty) return word;
    String clean = word.trim();

    // Strip hyphenated postpositions
    clean = clean.replaceAll(
      RegExp(r'-(?:la|ula|le|ule|ah|a|ai|oda|kku|ukku|ku|lerundhu|irundhu)$', caseSensitive: false),
      '',
    );

    // Strip agglutinated suffixes from longer words (length > 4)
    if (clean.length > 4) {
      clean = clean.replaceAll(
        RegExp(r'(?:lerundhu|irundhu|irundu)$', caseSensitive: false),
        '',
      );
      clean = clean.replaceAll(
        RegExp(r'(?:ukku|kku|oda)$', caseSensitive: false),
        '',
      );
      clean = clean.replaceAll(
        RegExp(r'(?:ula|la)$', caseSensitive: false),
        '',
      );
    }

    return clean.replaceAll('-', ' ').trim();
  }

  /// Fixes common speech-to-text transcription quirks for Tamil/Tanglish phrases.
  static String fixAsrMistakes(String text) {
    String clean = text;

    // Verb phonetic variants
    clean = clean.replaceAll(RegExp(r'\bad\s+pannu\b', caseSensitive: false), 'add pannu');
    clean = clean.replaceAll(RegExp(r'\bad\s+panu\b', caseSensitive: false), 'add pannu');
    clean = clean.replaceAll(RegExp(r'\bpannu\b', caseSensitive: false), 'pannu');
    clean = clean.replaceAll(RegExp(r'\bpanu\b', caseSensitive: false), 'pannu');
    clean = clean.replaceAll(RegExp(r'\bpodu\b', caseSensitive: false), 'podu');
    clean = clean.replaceAll(RegExp(r'\bpoodu\b', caseSensitive: false), 'podu');
    clean = clean.replaceAll(RegExp(r'\bvenum\b', caseSensitive: false), 'venum');
    clean = clean.replaceAll(RegExp(r'\bvaenum\b', caseSensitive: false), 'venum');
    clean = clean.replaceAll(RegExp(r'\bkaatu\b', caseSensitive: false), 'kaatu');
    clean = clean.replaceAll(RegExp(r'\bkaattu\b', caseSensitive: false), 'kaatu');

    // Unit phonetic variants
    clean = clean.replaceAll(RegExp(r'\bkiloo\b', caseSensitive: false), 'kilo');
    clean = clean.replaceAll(RegExp(r'\blittar\b', caseSensitive: false), 'litre');
    clean = clean.replaceAll(RegExp(r'\blitru\b', caseSensitive: false), 'litre');

    // Item name phonetic variants
    clean = clean.replaceAll(RegExp(r'\brais\b', caseSensitive: false), 'rice');
    clean = clean.replaceAll(RegExp(r'\braice\b', caseSensitive: false), 'rice');
    clean = clean.replaceAll(RegExp(r'\bricee\b', caseSensitive: false), 'rice');
    clean = clean.replaceAll(RegExp(r'\barisii\b', caseSensitive: false), 'arisi');
    clean = clean.replaceAll(RegExp(r'\boill\b', caseSensitive: false), 'oil');
    clean = clean.replaceAll(RegExp(r'\bpaalu\b', caseSensitive: false), 'paal');
    clean = clean.replaceAll(RegExp(r'\bsugar-u\b', caseSensitive: false), 'sugar');
    clean = clean.replaceAll(RegExp(r'\bsakkarai-a\b', caseSensitive: false), 'sakkarai');
    clean = clean.replaceAll(RegExp(r'\buppu-a\b', caseSensitive: false), 'uppu');

    return clean;
  }

  /// Normalizes a whole sentence: strips postpositions from tokens, fixes typos, cleans whitespace.
  static String normalizeSentence(String text) {
    if (text.trim().isEmpty) return '';

    String cleaned = fixAsrMistakes(text);

    // Split words, process individual tokens
    final tokens = cleaned.split(RegExp(r'\s+'));
    final processed = <String>[];

    for (final token in tokens) {
      if (token.isEmpty) continue;
      final cleanToken = cleanPostpositions(token);
      if (cleanToken.isNotEmpty) {
        processed.add(cleanToken);
      }
    }

    return processed.join(' ').trim();
  }
}
