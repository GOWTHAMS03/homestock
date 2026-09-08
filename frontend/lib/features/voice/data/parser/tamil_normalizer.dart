/// Normalizer for Tamil Unicode script text, handling Tamil declensions,
/// case endings (வேற்றுமை உருபுகள்), and verb forms.
class TamilNormalizer {
  /// Strips Tamil grammatical suffixes (e.g. ஐ for accusative, இல் for locative).
  static String cleanTamilSuffixes(String word) {
    if (word.isEmpty) return word;
    String clean = word.trim();

    // Suffix -ஐ (Accusative marker: அரிசியை -> அரிசி, எண்ணெயை -> எண்ணெய்)
    if (clean.endsWith('யை') && clean.length > 3) {
      clean = '${clean.substring(0, clean.length - 2)}ய்';
    } else if (clean.endsWith('யை') && clean.length > 2) {
      clean = clean.substring(0, clean.length - 1);
    } else if (clean.endsWith('வை') && clean.length > 3) {
      clean = '${clean.substring(0, clean.length - 2)}வு';
    } else if (clean.endsWith('ளை') && clean.length > 3) {
      clean = '${clean.substring(0, clean.length - 2)}ள்';
    } else if (clean.endsWith('ை') && clean.length > 2) {
      clean = clean.substring(0, clean.length - 1);
    }

    // Suffix -இல் / -ல் (Locative: வீட்டில் -> வீடு, பட்டியலில் -> பட்டியல்)
    if (clean.endsWith('லில்') && clean.length > 3) {
      clean = '${clean.substring(0, clean.length - 3)}ல்';
    } else if (clean.endsWith('ட்டில்') && clean.length > 4) {
      clean = '${clean.substring(0, clean.length - 4)}டு';
    } else if (clean.endsWith('இல்') && clean.length > 3) {
      clean = clean.substring(0, clean.length - 2);
    } else if (clean.endsWith('-ல்') || clean.endsWith('-ல')) {
      clean = clean.replaceAll(RegExp(r'-[ல்|ல]$'), '');
    }

    // Suffix -இருந்து (Ablative)
    if (clean.endsWith('இருந்து') && clean.length > 6) {
      clean = clean.substring(0, clean.length - 6);
    } else if (clean.endsWith('லிருந்து') && clean.length > 7) {
      clean = clean.substring(0, clean.length - 7);
    }

    // Suffix -க்கு / -உக்கு (Dative)
    if (clean.endsWith('க்கு') && clean.length > 3) {
      clean = clean.substring(0, clean.length - 3);
    } else if (clean.endsWith('உக்கு') && clean.length > 4) {
      clean = clean.substring(0, clean.length - 4);
    }

    return clean.trim();
  }

  /// Normalizes Tamil verbs into canonical english intent cues
  static String normalizeTamilVerbs(String text) {
    String clean = text;

    // Add verbs
    clean = clean.replaceAll(RegExp(r'\b(சேர்க்கவும்|சேர்க்க|சேர்|போடு|போடவும்|வைக்கவும்)\b'), 'add');

    // Remove verbs
    clean = clean.replaceAll(RegExp(r'\b(நீக்கவும்|நீக்கு|எடுக்கவும்|எடு|அழிக்கவும்)\b'), 'remove');

    // Check verbs / questions
    clean = clean.replaceAll(RegExp(r'\b(எவ்வளவு இருக்கிறது|எவ்வளவு இருக்கு|இருக்கிறதா|இருக்கா|காட்டவும்|காட்டு)\b'), 'check');

    // Finished / bought
    clean = clean.replaceAll(RegExp(r'\b(வாங்கியாயிற்று|வாங்கிவிட்டேன்|முடிந்தது|தீர்ந்துவிட்டது|காலி)\b'), 'completed');

    return clean;
  }
}
