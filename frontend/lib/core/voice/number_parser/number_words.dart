/// Spoken number and fraction normalization across English, Tamil script, and Tanglish.
class NumberWords {
  static final Map<String, double> _numbers = {
    // English words
    'zero': 0.0,
    'one': 1.0,
    'two': 2.0,
    'three': 3.0,
    'four': 4.0,
    'five': 5.0,
    'six': 6.0,
    'seven': 7.0,
    'eight': 8.0,
    'nine': 9.0,
    'ten': 10.0,
    'eleven': 11.0,
    'twelve': 12.0,
    'thirteen': 13.0,
    'fourteen': 14.0,
    'fifteen': 15.0,
    'sixteen': 16.0,
    'seventeen': 17.0,
    'eighteen': 18.0,
    'nineteen': 19.0,
    'twenty': 20.0,
    'twenty five': 25.0,
    'twenty-five': 25.0,
    'thirty': 30.0,
    'forty': 40.0,
    'fifty': 50.0,
    'hundred': 100.0,
    'a': 1.0,
    'an': 1.0,

    // English fractions & compound spoken numbers
    'half': 0.5,
    'quarter': 0.25,
    'one and half': 1.5,
    'one and a half': 1.5,
    'one-and-a-half': 1.5,
    'two and half': 2.5,
    'two and a half': 2.5,
    'three and half': 3.5,
    'four and half': 4.5,
    'five and half': 5.5,

    // Tamil Script Numbers (Formal & Colloquial)
    'பூஜ்ஜியம்': 0.0,
    'ஒன்று': 1.0,
    'ஒரு': 1.0,
    'ஒன்னு': 1.0,
    'இரண்டு': 2.0,
    'ரெண்டு': 2.0,
    'மூன்று': 3.0,
    'மூணு': 3.0,
    'நான்கு': 4.0,
    'நாலு': 4.0,
    'ஐந்து': 5.0,
    'அஞ்சு': 5.0,
    'ஆறு': 6.0,
    'ஏழு': 7.0,
    'எட்டு': 8.0,
    'ஒன்பது': 9.0,
    'பத்து': 10.0,
    'பதினொன்று': 11.0,
    'பன்னிரண்டு': 12.0,
    'பதினைந்து': 15.0,
    'இருபது': 20.0,
    'இருபத்தைந்து': 25.0,
    'முப்பது': 30.0,
    'நாற்பது': 40.0,
    'ஐம்பது': 50.0,
    'நூறு': 100.0,

    // Tamil Script Fractions
    'அரை': 0.5,
    'கால்': 0.25,
    'முக்கால்': 0.75,
    'ஒன்றரை': 1.5,
    'இரண்டரை': 2.5,
    'மூன்றரை': 3.5,

    // Tanglish Numbers
    'onnu': 1.0,
    'oru': 1.0,
    'ore': 1.0,
    'orey': 1.0,
    'rendu': 2.0,
    'irandu': 2.0,
    'erandu': 2.0,
    'moonu': 3.0,
    'moonru': 3.0,
    'naalu': 4.0,
    'naangu': 4.0,
    'nallu': 4.0,
    'anju': 5.0,
    'aindhu': 5.0,
    'ayndhu': 5.0,
    'aaru': 6.0,
    'ezhu': 7.0,
    'yelu': 7.0,
    'ettu': 8.0,
    'onbadhu': 9.0,
    'onpathu': 9.0,
    'ombadhu': 9.0,
    'ombathu': 9.0,
    'pathu': 10.0,
    'padhinonnu': 11.0,
    'pannirendu': 12.0,
    'padhinanju': 15.0,
    'iruvadhu': 20.0,
    'irubadhu': 20.0,
    'irupathu': 20.0,
    'iruvathi anju': 25.0,
    'irubathi anju': 25.0,
    'muppadhu': 30.0,
    'naappadhu': 40.0,
    'aimbadhu': 50.0,
    'aimbathu': 50.0,
    'nooru': 100.0,

    // Tanglish Fractions & Compounds
    'ara': 0.5,
    'arai': 0.5,
    'arra': 0.5,
    'arrai': 0.5,
    'kaal': 0.25,
    'mukkaal': 0.75,
    'mukaal': 0.75,
    'onnara': 1.5,
    'onnarai': 1.5,
    'ondrai': 1.5,
    'orara': 1.5,
    'orarai': 1.5,
    'rendara': 2.5,
    'rendarai': 2.5,
    'irandara': 2.5,
    'moonara': 3.5,
    'moonarai': 3.5,
    'naalara': 4.5,
    'anjara': 5.5,
  };

  /// Direct match for a single word or compound phrase
  static double? lookup(String word) {
    return _numbers[word.toLowerCase().trim()];
  }

  /// Check if the word is a known number or fraction word
  static bool isNumberWord(String word) {
    return _numbers.containsKey(word.toLowerCase().trim());
  }

  /// All entries ordered by descending length so compound phrases match first
  static List<MapEntry<String, double>> get sortedEntries {
    final list = _numbers.entries.toList();
    list.sort((a, b) => b.key.length.compareTo(a.key.length));
    return list;
  }
}
