/// Canonical measurement unit normalization and household compatibility validator.
class UnitDictionary {
  static final Map<String, String> _synonyms = {
    // Kilogram
    'kg': 'kg',
    'kgs': 'kg',
    'kilo': 'kg',
    'kilos': 'kg',
    'kilogram': 'kg',
    'kilograms': 'kg',
    'kiloo': 'kg',
    'கிலோ': 'kg',

    // Gram
    'g': 'g',
    'gm': 'g',
    'gms': 'g',
    'gram': 'g',
    'grams': 'g',
    'கிராம்': 'g',
    'giram': 'g',

    // Litre
    'l': 'L',
    'ltr': 'L',
    'ltrs': 'L',
    'liter': 'L',
    'liters': 'L',
    'litre': 'L',
    'litres': 'L',
    'litru': 'L',
    'littar': 'L',
    'லிட்டர்': 'L',

    // Millilitre
    'ml': 'ml',
    'milli': 'ml',
    'milliliter': 'ml',
    'milliliters': 'ml',
    'millilitre': 'ml',
    'millilitres': 'ml',
    'மில்லி': 'ml',

    // Pieces / Count
    'pc': 'pcs',
    'pcs': 'pcs',
    'piece': 'pcs',
    'pieces': 'pcs',
    'peesu': 'pcs',
    'பீஸ்': 'pcs',

    // Packet
    'packet': 'packet',
    'packets': 'packet',
    'pack': 'packet',
    'packs': 'packet',
    'pkt': 'packet',
    'pkts': 'packet',
    'pakat': 'packet',
    'paaket': 'packet',
    'பாக்கெட்': 'packet',

    // Box
    'box': 'box',
    'boxes': 'box',
    'பெட்டி': 'box',
    'peti': 'box',

    // Bottle
    'bottle': 'bottle',
    'bottles': 'bottle',
    'பாட்டில்': 'bottle',
    'baattil': 'bottle',
    'bottil': 'bottle',

    // Can / Tin
    'can': 'can',
    'cans': 'can',
    'tin': 'can',
    'tins': 'can',
    'டின்': 'can',

    // Dozen
    'dozen': 'dozen',
    'dozens': 'dozen',
    'டஜன்': 'dozen',
    'dajan': 'dozen',
  };

  /// Allowed units per category/type to prevent nonsensical combinations (e.g. "2 bottles rice")
  static final Map<String, Set<String>> _categoryAllowedUnits = {
    'Grains': {'kg', 'g', 'packet', 'box', 'pcs'},
    'Flour & Batter': {'kg', 'g', 'packet', 'box', 'pcs'},
    'Pulses & Dal': {'kg', 'g', 'packet', 'box', 'pcs'},
    'Spices & Seasonings': {'g', 'kg', 'packet', 'box', 'pcs', 'bottle'},
    'Oils & Ghee': {'L', 'ml', 'bottle', 'packet', 'can', 'g', 'kg', 'pcs'},
    'Dairy': {'packet', 'L', 'ml', 'bottle', 'can', 'g', 'kg', 'pcs'},
    'Beverages': {'packet', 'g', 'kg', 'bottle', 'can', 'box', 'pcs'},
    'Vegetables': {'kg', 'g', 'pcs', 'packet'},
    'Eggs & Meat': {'pcs', 'dozen', 'packet', 'box', 'kg', 'g'},
    'Bakery': {'packet', 'box', 'pcs'},
    'Snacks': {'packet', 'box', 'pcs', 'g', 'kg'},
    'Personal Care': {'pcs', 'bottle', 'packet', 'box'},
    'Cleaning': {'L', 'ml', 'bottle', 'packet', 'can', 'kg', 'g', 'box', 'pcs'},
  };

  /// Normalizes a raw unit token into canonical string ('kg', 'g', 'L', 'ml', etc.)
  static String? normalize(String rawUnit) {
    return _synonyms[rawUnit.toLowerCase().trim()];
  }

  /// Checks if a word is a known unit variation
  static bool isUnit(String word) {
    return _synonyms.containsKey(word.toLowerCase().trim());
  }

  /// Checks if unit is compatible with the given category
  static bool isCompatible(String unit, String category) {
    final canonical = normalize(unit);
    if (canonical == null) return false;

    final allowed = _categoryAllowedUnits[category];
    if (allowed == null) return true; // General category accepts standard units
    return allowed.contains(canonical);
  }

  /// Returns sorted unit keys by descending length so multi-word or longer variants match first
  static List<String> get sortedUnitKeys {
    final keys = _synonyms.keys.toList();
    keys.sort((a, b) => b.length.compareTo(a.length));
    return keys;
  }
}
