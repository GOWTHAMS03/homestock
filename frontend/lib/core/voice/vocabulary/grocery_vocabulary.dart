/// Comprehensive household grocery vocabulary for HomeStock voice recognition.
/// Maps English, Tamil script, Tanglish spelling variants, and colloquial terms
/// to canonical item definitions, default units, and categories.
class GroceryItemDefinition {
  final String canonicalName;
  final String category;
  final String defaultUnit;
  final List<String> variations;

  const GroceryItemDefinition({
    required this.canonicalName,
    required this.category,
    required this.defaultUnit,
    required this.variations,
  });
}

class GroceryVocabulary {
  static final Map<String, GroceryItemDefinition> _lookup = {};
  static final List<GroceryItemDefinition> _catalog = [];

  static bool _initialized = false;

  static void ensureInitialized() {
    if (_initialized) return;
    _initialized = true;

    // Grains & Flours
    _register('Rice', 'Grains', 'kg', [
      'rice', 'arisi', 'arici', 'அரிசி', 'சாப்பாடு அரிசி', 'பச்சரிசி', 'புழுங்கல் அரிசி',
      'basmati', 'basmati rice', 'sona masoori', 'ponni rice', 'raw rice', 'boiled rice',
      'idli rice', 'dosa rice', 'brown rice', 'rais', 'raice', 'arisii', 'ricee', 'rice-a', 'arisi-a',
    ]);
    _register('Atta', 'Flour & Batter', 'kg', [
      'atta', 'wheat flour', 'gothumai maavu', 'ஆட்டா', 'கோதுமை மாவு', 'மாவு', 'wheat',
      'chakki atta', 'aashirvaad atta', 'godhumai', 'atta maavu',
    ]);
    _register('Maida', 'Flour & Batter', 'kg', [
      'maida', 'all purpose flour', 'மைதா', 'maida maavu',
    ]);
    _register('Besan', 'Flour & Batter', 'kg', [
      'besan', 'gram flour', 'kadalai maavu', 'கடலை மாவு', 'senaga pindi',
    ]);
    _register('Rava', 'Flour & Batter', 'kg', [
      'rava', 'sooji', 'semolina', 'ரவை', 'ravai',
    ]);

    // Cooking Oils & Ghee
    _register('Cooking Oil', 'Oils & Ghee', 'L', [
      'oil', 'oill', 'ennai', 'enna', 'cooking oil', 'ஆயில்', 'எண்ணெய்', 'சமையல் எண்ணெய்',
      'sunflower oil', 'groundnut oil', 'sesame oil', 'gingelly oil', 'mustard oil', 'coconut oil',
      'நல்லெண்ணெய்', 'கடலை எண்ணெய்', 'தேங்காய் எண்ணெய்', 'oil-u', 'oil-a', 'ennai-a',
    ]);
    _register('Ghee', 'Dairy', 'g', [
      'ghee', 'nei', 'neyyi', 'நெய்', 'cow ghee', 'amul ghee',
    ]);

    // Dairy
    _register('Milk', 'Dairy', 'packet', [
      'milk', 'paal', 'பால்', 'மில்க்', 'milk-u', 'paalu', 'toned milk', 'full cream milk',
      'aavin milk', 'amul milk', 'milk packet', 'paal packet', 'cow milk',
    ]);
    _register('Curd', 'Dairy', 'packet', [
      'curd', 'thayir', 'தயிர்', 'yogurt', 'curd packet', 'thayir packet',
    ]);
    _register('Butter', 'Dairy', 'g', [
      'butter', 'vennei', 'வெண்ணெய்', 'amul butter', 'salted butter',
    ]);
    _register('Paneer', 'Dairy', 'g', [
      'paneer', 'பன்னீர்', 'cottage cheese',
    ]);
    _register('Cheese', 'Dairy', 'packet', [
      'cheese', 'சீஸ்', 'cheese slices', 'cheese cube',
    ]);

    // Pulses & Dal
    _register('Toor Dal', 'Pulses & Dal', 'kg', [
      'toor dal', 'thoor dhal', 'thuvaram paruppu', 'துவரம் பருப்பு', 'paruppu', 'பருப்பு',
      'dal', 'dhal', 'sambhar paruppu',
    ]);
    _register('Moong Dal', 'Pulses & Dal', 'kg', [
      'moong dal', 'paasi paruppu', 'பாசி பருப்பு', 'pasi paruppu', 'yellow dal',
    ]);
    _register('Urad Dal', 'Pulses & Dal', 'kg', [
      'urad dal', 'ulundham paruppu', 'உளுந்தம் பருப்பு', 'ulunthu', 'black dal',
    ]);
    _register('Chana Dal', 'Pulses & Dal', 'kg', [
      'chana dal', 'kadalai paruppu', 'கடலை பருப்பு', 'bengal gram',
    ]);

    // Spices & Seasonings
    _register('Sugar', 'Spices & Seasonings', 'kg', [
      'sugar', 'sakkarai', 'sarkkarai', 'சீனி', 'சர்க்கரை', 'sugar-u', 'nattu sakkarai', 'brown sugar',
    ]);
    _register('Salt', 'Spices & Seasonings', 'kg', [
      'salt', 'uppu', 'உப்பு', 'salt-u', 'tata salt', 'iodized salt', 'kallu uppu',
    ]);
    _register('Turmeric Powder', 'Spices & Seasonings', 'g', [
      'turmeric', 'turmeric powder', 'manjal thool', 'மஞ்சள் தூள்', 'manjal',
    ]);
    _register('Chilli Powder', 'Spices & Seasonings', 'g', [
      'chilli powder', 'milagai thool', 'மிளகாய் தூள்', 'red chilli powder', 'milagai podi',
    ]);
    _register('Coriander Powder', 'Spices & Seasonings', 'g', [
      'coriander powder', 'dhaniya thool', 'மல்லி தூள்', 'kothamalli thool',
    ]);
    _register('Mustard Seeds', 'Spices & Seasonings', 'g', [
      'mustard', 'mustard seeds', 'kadugu', 'கடுகு',
    ]);
    _register('Cumin Seeds', 'Spices & Seasonings', 'g', [
      'cumin', 'cumin seeds', 'jeeragam', 'சீரகம்', 'zeera',
    ]);
    _register('Pepper', 'Spices & Seasonings', 'g', [
      'pepper', 'black pepper', 'milagu', 'மிளகு',
    ]);

    // Beverages
    _register('Tea', 'Beverages', 'packet', [
      'tea', 'theenir', 'டீ', 'tea powder', 'taj mahal tea', 'red label', 'chakra gold', 'tea thool',
    ]);
    _register('Coffee', 'Beverages', 'packet', [
      'coffee', 'kaapi', 'காபி', 'coffee powder', 'bru', 'sunrise', 'filter coffee powder',
    ]);

    // Vegetables & Fresh Produce
    _register('Onion', 'Vegetables', 'kg', [
      'onion', 'onions', 'vengayam', 'வெங்காயம்', 'vengayam-u', 'chinna vengayam', 'periya vengayam', 'shallots',
    ]);
    _register('Tomato', 'Vegetables', 'kg', [
      'tomato', 'tomatoes', 'thakkali', 'தக்காளி', 'thakkaali',
    ]);
    _register('Potato', 'Vegetables', 'kg', [
      'potato', 'potatoes', 'urulaikizhangu', 'உருளைக்கிழங்கு', 'urulai', 'aloo',
    ]);
    _register('Ginger', 'Vegetables', 'g', [
      'ginger', 'inji', 'இஞ்சி', 'adrak',
    ]);
    _register('Garlic', 'Vegetables', 'g', [
      'garlic', 'poondu', 'பூண்டு', 'lahsun',
    ]);
    _register('Green Chilli', 'Vegetables', 'g', [
      'green chilli', 'pachai milagai', 'பச்சை மிளகாய்', 'green chillies',
    ]);
    _register('Coriander Leaves', 'Vegetables', 'packet', [
      'coriander', 'coriander leaves', 'kothamalli', 'கொத்தமல்லி', 'cilantro',
    ]);
    _register('Curry Leaves', 'Vegetables', 'packet', [
      'curry leaves', 'karuveppilai', 'கறிவேப்பிலை', 'karivepila',
    ]);

    // Bakery & Breakfast
    _register('Bread', 'Bakery', 'packet', [
      'bread', 'ரொட்டி', 'bread-u', 'white bread', 'wheat bread', 'brown bread', 'bread packet',
    ]);
    _register('Egg', 'Eggs & Meat', 'pcs', [
      'egg', 'eggs', 'muttai', 'mutta', 'முட்டை', 'country egg', 'nattu muttai',
    ]);
    _register('Biscuits', 'Snacks', 'packet', [
      'biscuit', 'biscuits', 'பிஸ்கட்', 'cookies', 'parle g', 'marie gold',
    ]);

    // Cleaning & Personal Care
    _register('Soap', 'Personal Care', 'pcs', [
      'soap', 'soappu', 'சோப்பு', 'bathing soap', 'body soap',
    ]);
    _register('Shampoo', 'Personal Care', 'bottle', [
      'shampoo', 'ஷாம்பு', 'hair shampoo',
    ]);
    _register('Toothpaste', 'Personal Care', 'pcs', [
      'toothpaste', 'paste', 'பற்பசை', 'colgate', 'close up',
    ]);
    _register('Detergent', 'Cleaning', 'kg', [
      'detergent', 'surf', 'washing powder', 'சலவை தூள்', 'surf excel', 'ariel', 'detergent powder',
    ]);
    _register('Dishwash Liquid', 'Cleaning', 'bottle', [
      'dishwash', 'dishwash liquid', 'vim', 'vim gel', 'பாத்திரம் கழுவும் திரவம்',
    ]);
  }

  static void _register(String canonical, String category, String defaultUnit, List<String> variations) {
    final def = GroceryItemDefinition(
      canonicalName: canonical,
      category: category,
      defaultUnit: defaultUnit,
      variations: variations,
    );
    _catalog.add(def);

    // Register all lowercase variations
    for (final v in variations) {
      _lookup[v.toLowerCase().trim()] = def;
    }
    // Also register canonical name itself
    _lookup[canonical.toLowerCase().trim()] = def;
  }

  /// Dynamically registers a custom product name from user's inventory
  static void registerCustomProduct(String name, {String category = 'General', String defaultUnit = 'pcs'}) {
    ensureInitialized();
    final lower = name.toLowerCase().trim();
    if (_lookup.containsKey(lower)) return;

    final def = GroceryItemDefinition(
      canonicalName: name,
      category: category,
      defaultUnit: defaultUnit,
      variations: [lower],
    );
    _catalog.add(def);
    _lookup[lower] = def;
  }

  /// Looks up an exact match in the dictionary
  static GroceryItemDefinition? lookup(String query) {
    ensureInitialized();
    return _lookup[query.toLowerCase().trim()];
  }

  /// Searches the dictionary for any definition whose variations contain [query] as a word
  static GroceryItemDefinition? findMatch(String text) {
    ensureInitialized();
    final lower = text.toLowerCase().trim();

    // 1. Direct exact match
    if (_lookup.containsKey(lower)) {
      return _lookup[lower];
    }

    // 2. Word substring match (longest matching variation first)
    GroceryItemDefinition? bestDef;
    int bestLength = 0;

    for (final def in _catalog) {
      for (final v in def.variations) {
        if (v.length > bestLength) {
          bool matched = false;
          // If v is purely ASCII, word boundary \b works
          if (RegExp(r'^[\x00-\x7F]+$').hasMatch(v)) {
            matched = RegExp('\\b${RegExp.escape(v)}\\b', caseSensitive: false).hasMatch(lower);
          } else {
            // For Unicode scripts (like Tamil), check containment
            matched = lower.contains(v.toLowerCase());
          }
          if (matched) {
            bestDef = def;
            bestLength = v.length;
          }
        }
      }
    }

    return bestDef;
  }

  /// Returns all registered definitions
  static List<GroceryItemDefinition> get allCatalog {
    ensureInitialized();
    return List.unmodifiable(_catalog);
  }
}
