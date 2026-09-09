import 'package:flutter/material.dart';
import 'master_product_staples.dart';

export 'master_product_staples.dart';

/// Core definition of common household staples across pantry, fridge, and cleaning supplies.
class HouseholdStaple {
  final String name;
  final String? tamilName;
  final double defaultQty;
  final String defaultUnit;
  final String emoji;
  final IconData? icon;
  final String category;
  final String? subCategory;
  final String storageLocation;
  final double minimumQuantity;

  final List<double>? customQuantities;
  final List<String>? customBrands;
  final List<String>? commonNames;
  final bool isPackaged;
  final bool isLoose;
  final bool barcodeSupport;
  final String? barcodeType;
  final String? soldBy;

  const HouseholdStaple({
    required this.name,
    this.tamilName,
    required this.defaultQty,
    required this.defaultUnit,
    required this.emoji,
    this.icon,
    required this.category,
    this.subCategory,
    this.storageLocation = 'Pantry',
    this.minimumQuantity = 1.0,
    this.customQuantities,
    this.customBrands,
    this.commonNames,
    this.isPackaged = true,
    this.isLoose = false,
    this.barcodeSupport = true,
    this.barcodeType,
    this.soldBy,
  });

  double get qty => defaultQty;
  String get unit => defaultUnit;

  /// User-facing display title including authentic Tamil script when available
  String get displayName => tamilName != null && tamilName!.isNotEmpty
      ? '$name ($tamilName)'
      : name;

  /// Material icon resolver with category fallback
  IconData get iconData {
    if (icon != null) return icon!;
    return iconForCategory(category);
  }

  static IconData iconForCategory(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('dairy') || c.contains('milk') || c.contains('egg')) return Icons.egg_rounded;
    if (c.contains('veg') || c.contains('fruit')) return Icons.eco_rounded;
    if (c.contains('grain') || c.contains('rice') || c.contains('dal') || c.contains('flour') || c.contains('oil')) return Icons.grain_rounded;
    if (c.contains('spice') || c.contains('masala') || c.contains('salt') || c.contains('sweet')) return Icons.soup_kitchen_rounded;
    if (c.contains('beverage') || c.contains('tea') || c.contains('coffee') || c.contains('drink')) return Icons.local_cafe_rounded;
    if (c.contains('snack') || c.contains('breakfast') || c.contains('bakery')) return Icons.bakery_dining_rounded;
    if (c.contains('clean') || c.contains('laundry')) return Icons.cleaning_services_rounded;
    if (c.contains('personal') || c.contains('bath') || c.contains('beauty')) return Icons.spa_rounded;
    if (c.contains('baby')) return Icons.child_care_rounded;
    if (c.contains('pet')) return Icons.pets_rounded;
    return Icons.inventory_2_rounded;
  }

  /// Quantity presets tailored to the specific product type
  List<double> get suggestedQuantities {
    if (customQuantities != null && customQuantities!.isNotEmpty) {
      return customQuantities!;
    }
    final u = defaultUnit.toLowerCase().trim();
    final n = name.toLowerCase().trim();

    if (n.contains('egg')) {
      return const [6.0, 12.0, 18.0, 24.0, 30.0];
    }
    if (n.contains('banana') || n.contains('lemon')) {
      return const [2.0, 4.0, 6.0, 12.0];
    }
    if (u == 'l' || u == 'litre' || u == 'liter') {
      return const [0.5, 1.0, 2.0, 3.0, 5.0];
    }
    if (u == 'ml') {
      return const [200.0, 500.0, 750.0, 1000.0];
    }
    if (u == 'kg') {
      if (n.contains('atta') || n.contains('rice') || n.contains('flour')) {
        return const [1.0, 2.0, 5.0, 10.0, 25.0];
      }
      return const [0.5, 1.0, 2.0, 3.0, 5.0];
    }
    if (u == 'g') {
      if (n.contains('butter') || n.contains('paneer') || n.contains('curd')) {
        return const [100.0, 200.0, 400.0, 500.0, 1000.0];
      }
      return const [50.0, 100.0, 200.0, 250.0, 500.0];
    }
    if (u == 'pcs' || u == 'pc') {
      return const [1.0, 2.0, 4.0, 6.0, 12.0];
    }
    return const [1.0, 2.0, 3.0, 4.0, 5.0];
  }

  /// Popular brand presets for quick selection
  List<String> get suggestedBrands {
    if (customBrands != null && customBrands!.isNotEmpty) {
      return customBrands!;
    }
    final n = name.toLowerCase().trim();
    if (n.contains('milk') || n.contains('butter') || n.contains('paneer') || n.contains('curd') || n.contains('cheese')) {
      return const ['Amul', 'Nandini', 'Mother Dairy', 'Britannia', 'Milky Mist'];
    }
    if (n.contains('bread')) {
      return const ['Britannia', 'Modern', 'English Oven', 'Harvest Gold'];
    }
    if (n.contains('rice')) {
      return const ['India Gate', 'Daawat', 'Fortune', 'Kohinoor', 'BB Royal'];
    }
    if (n.contains('atta') || n.contains('flour')) {
      return const ['Aashirvaad', 'Pillsbury', 'Fortune', 'Nature Fresh'];
    }
    if (n.contains('oil') || n.contains('ghee')) {
      return const ['Fortune', 'Saffola', 'Dhara', 'Amul', 'Sundrop', 'Patanjali'];
    }
    if (n.contains('dal') || n.contains('poha') || n.contains('suji') || n.contains('besan')) {
      return const ['Tata Sampann', 'Fortune', 'BB Royal', 'Organic Tattva'];
    }
    if (n.contains('salt')) {
      return const ['Tata Salt', 'Aashirvaad', 'Patanjali', 'Catch'];
    }
    if (n.contains('sugar')) {
      return const ['Madhur', 'Parry', 'Trust', 'Dhampure'];
    }
    if (n.contains('tea') || n.contains('chai')) {
      return const ['Tata Tea', 'Red Label', 'Taj Mahal', 'Wagh Bakri', 'Society'];
    }
    if (n.contains('coffee')) {
      return const ['Nescafé', 'Bru', 'Tata Coffee Grand', 'Davidoff', 'Continental'];
    }
    if (n.contains('spice') || n.contains('masala') || n.contains('turmeric') || n.contains('chilli') || n.contains('cumin') || n.contains('pepper')) {
      return const ['Everest', 'MDH', 'Catch', 'Badshah', 'Tata Sampann'];
    }
    if (n.contains('soap') || n.contains('body lotion') || n.contains('face wash')) {
      return const ['Dove', 'Dettol', 'Pears', 'Lifebuoy', 'Nivea', 'Himalaya'];
    }
    if (n.contains('toothpaste')) {
      return const ['Colgate', 'Sensodyne', 'Close-Up', 'Dabur Red', 'Pepsodent'];
    }
    if (n.contains('shampoo')) {
      return const ['Head & Shoulders', 'Dove', 'Pantene', 'Clinic Plus', 'Tresemme'];
    }
    if (n.contains('dish') || n.contains('detergent') || n.contains('cleaner')) {
      return const ['Vim', 'Pril', 'Surf Excel', 'Ariel', 'Lizol', 'Harpic', 'Colin'];
    }
    return const [];
  }
}

const List<String> kHouseholdStapleCategories = [
  'All',
  'Dairy & Bakery',
  'Veg & Fruits',
  'Grains & Oils',
  'Pantry & Spices',
  'Beverages & Snacks',
  'Breakfast & Spreads',
  'Cleaning',
  'Personal Care',
];

/// Curated quick household staples with authentic Tamil names and icons
const List<HouseholdStaple> kCuratedStaples = [
  HouseholdStaple(
    name: 'Milk',
    tamilName: 'பால்',
    defaultQty: 1.0,
    defaultUnit: 'L',
    emoji: '🥛',
    icon: Icons.local_drink_rounded,
    category: 'Dairy & Bakery',
    storageLocation: 'Fridge',
    minimumQuantity: 1.0,
  ),
  HouseholdStaple(
    name: 'Eggs',
    tamilName: 'முட்டை',
    defaultQty: 12.0,
    defaultUnit: 'pcs',
    emoji: '🥚',
    icon: Icons.egg_rounded,
    category: 'Dairy & Bakery',
    storageLocation: 'Fridge',
    minimumQuantity: 6.0,
  ),
  HouseholdStaple(
    name: 'Bread',
    tamilName: 'ரொட்டி / பிரெட்',
    defaultQty: 1.0,
    defaultUnit: 'pk',
    emoji: '🍞',
    icon: Icons.bakery_dining_rounded,
    category: 'Dairy & Bakery',
    storageLocation: 'Pantry',
    minimumQuantity: 1.0,
  ),
  HouseholdStaple(
    name: 'Butter',
    tamilName: 'வெண்ணெய்',
    defaultQty: 500.0,
    defaultUnit: 'g',
    emoji: '🧈',
    icon: Icons.lunch_dining_rounded,
    category: 'Dairy & Bakery',
    storageLocation: 'Fridge',
    minimumQuantity: 200.0,
  ),
  HouseholdStaple(
    name: 'Paneer',
    tamilName: 'பன்னீர்',
    defaultQty: 200.0,
    defaultUnit: 'g',
    emoji: '🧀',
    icon: Icons.kitchen_rounded,
    category: 'Dairy & Bakery',
    storageLocation: 'Fridge',
    minimumQuantity: 200.0,
  ),
  HouseholdStaple(
    name: 'Curd / Dahi',
    tamilName: 'தயிர்',
    defaultQty: 500.0,
    defaultUnit: 'g',
    emoji: '🥣',
    icon: Icons.local_cafe_rounded,
    category: 'Dairy & Bakery',
    storageLocation: 'Fridge',
    minimumQuantity: 500.0,
  ),
  HouseholdStaple(
    name: 'Cheese Slices',
    tamilName: 'சீஸ் துண்டுகள்',
    defaultQty: 200.0,
    defaultUnit: 'g',
    emoji: '🧀',
    icon: Icons.kitchen_rounded,
    category: 'Dairy & Bakery',
    storageLocation: 'Fridge',
    minimumQuantity: 100.0,
  ),
  HouseholdStaple(
    name: 'Greek Yogurt',
    tamilName: 'கிரேக்க தயிர்',
    defaultQty: 400.0,
    defaultUnit: 'g',
    emoji: '🥛',
    icon: Icons.local_drink_rounded,
    category: 'Dairy & Bakery',
    storageLocation: 'Fridge',
    minimumQuantity: 200.0,
  ),
  HouseholdStaple(
    name: 'Brown Bread',
    tamilName: 'பிரவுன் பிரெட்',
    defaultQty: 1.0,
    defaultUnit: 'pk',
    emoji: '🍞',
    icon: Icons.bakery_dining_rounded,
    category: 'Dairy & Bakery',
    storageLocation: 'Pantry',
    minimumQuantity: 1.0,
  ),
  HouseholdStaple(
    name: 'Tofu',
    tamilName: 'டோஃபு',
    defaultQty: 200.0,
    defaultUnit: 'g',
    emoji: '🧊',
    icon: Icons.kitchen_rounded,
    category: 'Dairy & Bakery',
    storageLocation: 'Fridge',
    minimumQuantity: 200.0,
  ),
  HouseholdStaple(
    name: 'Onions',
    tamilName: 'வெங்காயம்',
    defaultQty: 1.0,
    defaultUnit: 'kg',
    emoji: '🧅',
    icon: Icons.eco_rounded,
    category: 'Veg & Fruits',
    storageLocation: 'Pantry Basket',
    minimumQuantity: 1.0,
  ),
  HouseholdStaple(
    name: 'Tomatoes',
    tamilName: 'தக்காளி',
    defaultQty: 1.0,
    defaultUnit: 'kg',
    emoji: '🍅',
    icon: Icons.eco_rounded,
    category: 'Veg & Fruits',
    storageLocation: 'Fridge',
    minimumQuantity: 1.0,
  ),
  HouseholdStaple(
    name: 'Potatoes',
    tamilName: 'உருளைக்கிழங்கு',
    defaultQty: 1.0,
    defaultUnit: 'kg',
    emoji: '🥔',
    icon: Icons.eco_rounded,
    category: 'Veg & Fruits',
    storageLocation: 'Pantry Basket',
    minimumQuantity: 1.0,
  ),
  HouseholdStaple(
    name: 'Bananas',
    tamilName: 'வாழைப்பழம்',
    defaultQty: 6.0,
    defaultUnit: 'pcs',
    emoji: '🍌',
    icon: Icons.apple_rounded,
    category: 'Veg & Fruits',
    storageLocation: 'Fruit Bowl',
    minimumQuantity: 3.0,
  ),
  HouseholdStaple(
    name: 'Apples',
    tamilName: 'ஆப்பிள்',
    defaultQty: 1.0,
    defaultUnit: 'kg',
    emoji: '🍎',
    icon: Icons.apple_rounded,
    category: 'Veg & Fruits',
    storageLocation: 'Fruit Bowl',
    minimumQuantity: 1.0,
  ),
  HouseholdStaple(
    name: 'Ginger',
    tamilName: 'இஞ்சி',
    defaultQty: 100.0,
    defaultUnit: 'g',
    emoji: '🫚',
    icon: Icons.eco_rounded,
    category: 'Veg & Fruits',
    storageLocation: 'Fridge Crisper',
    minimumQuantity: 50.0,
  ),
  HouseholdStaple(
    name: 'Garlic',
    tamilName: 'பூண்டு',
    defaultQty: 100.0,
    defaultUnit: 'g',
    emoji: '🧄',
    icon: Icons.eco_rounded,
    category: 'Veg & Fruits',
    storageLocation: 'Pantry Basket',
    minimumQuantity: 50.0,
  ),
  HouseholdStaple(
    name: 'Green Chillies',
    tamilName: 'பச்சை மிளகாய்',
    defaultQty: 100.0,
    defaultUnit: 'g',
    emoji: '🌶️',
    icon: Icons.local_fire_department_rounded,
    category: 'Veg & Fruits',
    storageLocation: 'Fridge Crisper',
    minimumQuantity: 50.0,
  ),
  HouseholdStaple(
    name: 'Lemons',
    tamilName: 'எலுமிச்சை',
    defaultQty: 4.0,
    defaultUnit: 'pcs',
    emoji: '🍋',
    icon: Icons.eco_rounded,
    category: 'Veg & Fruits',
    storageLocation: 'Fridge Crisper',
    minimumQuantity: 2.0,
  ),
  HouseholdStaple(
    name: 'Coriander',
    tamilName: 'கொத்தமல்லி தழை',
    defaultQty: 1.0,
    defaultUnit: 'pk',
    emoji: '🌿',
    icon: Icons.grass_rounded,
    category: 'Veg & Fruits',
    storageLocation: 'Fridge Crisper',
    minimumQuantity: 1.0,
  ),
  HouseholdStaple(
    name: 'Spinach / Palak',
    tamilName: 'கீரை / பாலக்',
    defaultQty: 1.0,
    defaultUnit: 'pk',
    emoji: '🥬',
    icon: Icons.grass_rounded,
    category: 'Veg & Fruits',
    storageLocation: 'Fridge Crisper',
    minimumQuantity: 1.0,
  ),
  HouseholdStaple(
    name: 'Carrots',
    tamilName: 'கேரட்',
    defaultQty: 500.0,
    defaultUnit: 'g',
    emoji: '🥕',
    icon: Icons.eco_rounded,
    category: 'Veg & Fruits',
    storageLocation: 'Fridge Crisper',
    minimumQuantity: 250.0,
  ),
  HouseholdStaple(
    name: 'Capsicum',
    tamilName: 'குடைமிளகாய்',
    defaultQty: 500.0,
    defaultUnit: 'g',
    emoji: '🫑',
    icon: Icons.eco_rounded,
    category: 'Veg & Fruits',
    storageLocation: 'Fridge Crisper',
    minimumQuantity: 250.0,
  ),
  HouseholdStaple(
    name: 'Cucumber',
    tamilName: 'வெள்ளரிக்காய்',
    defaultQty: 500.0,
    defaultUnit: 'g',
    emoji: '🥒',
    icon: Icons.eco_rounded,
    category: 'Veg & Fruits',
    storageLocation: 'Fridge Crisper',
    minimumQuantity: 250.0,
  ),
  HouseholdStaple(
    name: 'Mushrooms',
    tamilName: 'காளான்',
    defaultQty: 200.0,
    defaultUnit: 'g',
    emoji: '🍄',
    icon: Icons.eco_rounded,
    category: 'Veg & Fruits',
    storageLocation: 'Fridge',
    minimumQuantity: 200.0,
  ),
  HouseholdStaple(
    name: 'Aashirvaad Atta',
    tamilName: 'ஆசிர்வாத் கோதுமை மாவு',
    defaultQty: 5.0,
    defaultUnit: 'kg',
    emoji: '🫓',
    icon: Icons.grain_rounded,
    category: 'Grains & Oils',
    storageLocation: 'Pantry Shelf',
    minimumQuantity: 2.0,
  ),
  HouseholdStaple(
    name: 'Basmati Rice',
    tamilName: 'பாசுமதி அரிசி',
    defaultQty: 5.0,
    defaultUnit: 'kg',
    emoji: '🌾',
    icon: Icons.grain_rounded,
    category: 'Grains & Oils',
    storageLocation: 'Pantry Shelf',
    minimumQuantity: 2.0,
  ),
  HouseholdStaple(
    name: 'Sunflower Oil',
    tamilName: 'சூரியகாந்தி எண்ணெய்',
    defaultQty: 1.0,
    defaultUnit: 'L',
    emoji: '🌻',
    icon: Icons.opacity_rounded,
    category: 'Grains & Oils',
    storageLocation: 'Pantry Shelf',
    minimumQuantity: 1.0,
  ),
  HouseholdStaple(
    name: 'Toor Dal',
    tamilName: 'துவரம் பருப்பு',
    defaultQty: 1.0,
    defaultUnit: 'kg',
    emoji: '🥣',
    icon: Icons.grain_rounded,
    category: 'Grains & Oils',
    storageLocation: 'Pantry Shelf',
    minimumQuantity: 1.0,
  ),
  HouseholdStaple(
    name: 'Moong Dal',
    tamilName: 'பாசிப் பருப்பு',
    defaultQty: 1.0,
    defaultUnit: 'kg',
    emoji: '🫘',
    icon: Icons.grain_rounded,
    category: 'Grains & Oils',
    storageLocation: 'Pantry Shelf',
    minimumQuantity: 1.0,
  ),
  HouseholdStaple(
    name: 'Mustard Oil',
    tamilName: 'கடுகு எண்ணெய்',
    defaultQty: 1.0,
    defaultUnit: 'L',
    emoji: '🫒',
    icon: Icons.opacity_rounded,
    category: 'Grains & Oils',
    storageLocation: 'Pantry Shelf',
    minimumQuantity: 1.0,
  ),
  HouseholdStaple(
    name: 'Poha',
    tamilName: 'அவல்',
    defaultQty: 500.0,
    defaultUnit: 'g',
    emoji: '🥣',
    icon: Icons.grain_rounded,
    category: 'Grains & Oils',
    storageLocation: 'Pantry Shelf',
    minimumQuantity: 250.0,
  ),
  HouseholdStaple(
    name: 'Suji / Rava',
    tamilName: 'ரவை',
    defaultQty: 500.0,
    defaultUnit: 'g',
    emoji: '🌾',
    icon: Icons.grain_rounded,
    category: 'Grains & Oils',
    storageLocation: 'Pantry Shelf',
    minimumQuantity: 250.0,
  ),
  HouseholdStaple(
    name: 'Chana Dal',
    tamilName: 'கடலைப் பருப்பு',
    defaultQty: 1.0,
    defaultUnit: 'kg',
    emoji: '🥣',
    icon: Icons.grain_rounded,
    category: 'Grains & Oils',
    storageLocation: 'Pantry Shelf',
    minimumQuantity: 1.0,
  ),
  HouseholdStaple(
    name: 'Besan',
    tamilName: 'கடலை மாவு',
    defaultQty: 500.0,
    defaultUnit: 'g',
    emoji: '🌾',
    icon: Icons.grain_rounded,
    category: 'Grains & Oils',
    storageLocation: 'Pantry Shelf',
    minimumQuantity: 250.0,
  ),
  HouseholdStaple(
    name: 'Olive Oil',
    tamilName: 'ஆலிவ் எண்ணெய்',
    defaultQty: 500.0,
    defaultUnit: 'ml',
    emoji: '🫒',
    icon: Icons.opacity_rounded,
    category: 'Grains & Oils',
    storageLocation: 'Pantry Shelf',
    minimumQuantity: 200.0,
  ),
  HouseholdStaple(
    name: 'Desi Ghee',
    tamilName: 'நாட்டு நெய்',
    defaultQty: 500.0,
    defaultUnit: 'ml',
    emoji: '🧈',
    icon: Icons.opacity_rounded,
    category: 'Grains & Oils',
    storageLocation: 'Pantry Shelf',
    minimumQuantity: 200.0,
  ),
  HouseholdStaple(
    name: 'Tata Salt',
    tamilName: 'டாடா உப்பு',
    defaultQty: 1.0,
    defaultUnit: 'kg',
    emoji: '🧂',
    icon: Icons.soup_kitchen_rounded,
    category: 'Pantry & Spices',
    storageLocation: 'Spice Rack',
    minimumQuantity: 1.0,
  ),
  HouseholdStaple(
    name: 'Sugar',
    tamilName: 'சர்க்கரை',
    defaultQty: 1.0,
    defaultUnit: 'kg',
    emoji: '🍬',
    icon: Icons.cake_rounded,
    category: 'Pantry & Spices',
    storageLocation: 'Pantry Shelf',
    minimumQuantity: 1.0,
  ),
  HouseholdStaple(
    name: 'Tea / Chai',
    tamilName: 'தேநீர் / டீ தூள்',
    defaultQty: 250.0,
    defaultUnit: 'g',
    emoji: '☕',
    icon: Icons.local_cafe_rounded,
    category: 'Pantry & Spices',
    storageLocation: 'Spice Rack',
    minimumQuantity: 100.0,
  ),
  HouseholdStaple(
    name: 'Coffee',
    tamilName: 'காபி தூள்',
    defaultQty: 100.0,
    defaultUnit: 'g',
    emoji: '☕',
    icon: Icons.local_cafe_rounded,
    category: 'Pantry & Spices',
    storageLocation: 'Spice Rack',
    minimumQuantity: 50.0,
  ),
  HouseholdStaple(
    name: 'Turmeric Powder',
    tamilName: 'மஞ்சள் தூள்',
    defaultQty: 200.0,
    defaultUnit: 'g',
    emoji: '🟡',
    icon: Icons.soup_kitchen_rounded,
    category: 'Pantry & Spices',
    storageLocation: 'Spice Rack',
    minimumQuantity: 100.0,
  ),
  HouseholdStaple(
    name: 'Red Chilli Powder',
    tamilName: 'மிளகாய் தூள்',
    defaultQty: 200.0,
    defaultUnit: 'g',
    emoji: '🌶️',
    icon: Icons.local_fire_department_rounded,
    category: 'Pantry & Spices',
    storageLocation: 'Spice Rack',
    minimumQuantity: 100.0,
  ),
  HouseholdStaple(
    name: 'Jeera / Cumin',
    tamilName: 'சீரகம்',
    defaultQty: 100.0,
    defaultUnit: 'g',
    emoji: '🌿',
    icon: Icons.soup_kitchen_rounded,
    category: 'Pantry & Spices',
    storageLocation: 'Spice Rack',
    minimumQuantity: 50.0,
  ),
  HouseholdStaple(
    name: 'Garam Masala',
    tamilName: 'கரம் மசாலா',
    defaultQty: 100.0,
    defaultUnit: 'g',
    emoji: '🥘',
    icon: Icons.soup_kitchen_rounded,
    category: 'Pantry & Spices',
    storageLocation: 'Spice Rack',
    minimumQuantity: 50.0,
  ),
  HouseholdStaple(
    name: 'Mustard Seeds',
    tamilName: 'கடுகு',
    defaultQty: 100.0,
    defaultUnit: 'g',
    emoji: '🟡',
    icon: Icons.soup_kitchen_rounded,
    category: 'Pantry & Spices',
    storageLocation: 'Spice Rack',
    minimumQuantity: 50.0,
  ),
  HouseholdStaple(
    name: 'Coriander Powder',
    tamilName: 'மல்லித் தூள்',
    defaultQty: 200.0,
    defaultUnit: 'g',
    emoji: '🌿',
    icon: Icons.soup_kitchen_rounded,
    category: 'Pantry & Spices',
    storageLocation: 'Spice Rack',
    minimumQuantity: 100.0,
  ),
  HouseholdStaple(
    name: 'Kasuri Methi',
    tamilName: 'கஸ்தூரி மேத்தி',
    defaultQty: 50.0,
    defaultUnit: 'g',
    emoji: '🍃',
    icon: Icons.grass_rounded,
    category: 'Pantry & Spices',
    storageLocation: 'Spice Rack',
    minimumQuantity: 25.0,
  ),
  HouseholdStaple(
    name: 'Elaichi / Cardamom',
    tamilName: 'ஏலக்காய்',
    defaultQty: 50.0,
    defaultUnit: 'g',
    emoji: '🟢',
    icon: Icons.soup_kitchen_rounded,
    category: 'Pantry & Spices',
    storageLocation: 'Spice Rack',
    minimumQuantity: 25.0,
  ),
  HouseholdStaple(
    name: 'Black Pepper',
    tamilName: 'கருப்பு மிளகு',
    defaultQty: 100.0,
    defaultUnit: 'g',
    emoji: '🫒',
    icon: Icons.soup_kitchen_rounded,
    category: 'Pantry & Spices',
    storageLocation: 'Spice Rack',
    minimumQuantity: 50.0,
  ),
  HouseholdStaple(
    name: 'Jaggery / Gur',
    tamilName: 'வெல்லம்',
    defaultQty: 500.0,
    defaultUnit: 'g',
    emoji: '🍯',
    icon: Icons.cake_rounded,
    category: 'Pantry & Spices',
    storageLocation: 'Pantry Shelf',
    minimumQuantity: 250.0,
  ),
  HouseholdStaple(
    name: 'Biscuits / Cookies',
    tamilName: 'பிஸ்கட் / குக்கீஸ்',
    defaultQty: 1.0,
    defaultUnit: 'pk',
    emoji: '🍪',
    icon: Icons.cookie_rounded,
    category: 'Beverages & Snacks',
    storageLocation: 'Snack Shelf',
    minimumQuantity: 1.0,
  ),
  HouseholdStaple(
    name: 'Green Tea',
    tamilName: 'பச்சை தேநீர்',
    defaultQty: 25.0,
    defaultUnit: 'pcs',
    emoji: '🍵',
    icon: Icons.local_cafe_rounded,
    category: 'Beverages & Snacks',
    storageLocation: 'Pantry Shelf',
    minimumQuantity: 10.0,
  ),
  HouseholdStaple(
    name: 'Potato Chips',
    tamilName: 'உருளைக்கிழங்கு சிப்ஸ்',
    defaultQty: 1.0,
    defaultUnit: 'pk',
    emoji: '🥔',
    icon: Icons.fastfood_rounded,
    category: 'Beverages & Snacks',
    storageLocation: 'Snack Shelf',
    minimumQuantity: 1.0,
  ),
  HouseholdStaple(
    name: 'Almonds / Badam',
    tamilName: 'பாதாம் பருப்பு',
    defaultQty: 250.0,
    defaultUnit: 'g',
    emoji: '🥜',
    icon: Icons.grain_rounded,
    category: 'Beverages & Snacks',
    storageLocation: 'Pantry Shelf',
    minimumQuantity: 100.0,
  ),
  HouseholdStaple(
    name: 'Cashews / Kaju',
    tamilName: 'முந்திரி பருப்பு',
    defaultQty: 250.0,
    defaultUnit: 'g',
    emoji: '🥜',
    icon: Icons.grain_rounded,
    category: 'Beverages & Snacks',
    storageLocation: 'Pantry Shelf',
    minimumQuantity: 100.0,
  ),
  HouseholdStaple(
    name: 'Instant Noodles',
    tamilName: 'நூடுல்ஸ்',
    defaultQty: 4.0,
    defaultUnit: 'pk',
    emoji: '🍜',
    icon: Icons.ramen_dining_rounded,
    category: 'Beverages & Snacks',
    storageLocation: 'Pantry Shelf',
    minimumQuantity: 2.0,
  ),
  HouseholdStaple(
    name: 'Dark Chocolate',
    tamilName: 'டார்க் சாக்லேட்',
    defaultQty: 1.0,
    defaultUnit: 'pk',
    emoji: '🍫',
    icon: Icons.icecream_rounded,
    category: 'Beverages & Snacks',
    storageLocation: 'Fridge',
    minimumQuantity: 1.0,
  ),
  HouseholdStaple(
    name: 'Fruit Juice',
    tamilName: 'பழச்சாறு',
    defaultQty: 1.0,
    defaultUnit: 'L',
    emoji: '🧃',
    icon: Icons.local_drink_rounded,
    category: 'Beverages & Snacks',
    storageLocation: 'Fridge',
    minimumQuantity: 1.0,
  ),
  HouseholdStaple(
    name: 'Peanut Butter',
    tamilName: 'வேர்க்கடலை வெண்ணெய்',
    defaultQty: 350.0,
    defaultUnit: 'g',
    emoji: '🥜',
    icon: Icons.lunch_dining_rounded,
    category: 'Breakfast & Spreads',
    storageLocation: 'Pantry Shelf',
    minimumQuantity: 100.0,
  ),
  HouseholdStaple(
    name: 'Fruit Jam',
    tamilName: 'பழ ஜாம்',
    defaultQty: 500.0,
    defaultUnit: 'g',
    emoji: '🍓',
    icon: Icons.breakfast_dining_rounded,
    category: 'Breakfast & Spreads',
    storageLocation: 'Fridge',
    minimumQuantity: 150.0,
  ),
  HouseholdStaple(
    name: 'Pure Honey',
    tamilName: 'சுத்தமான தேன்',
    defaultQty: 250.0,
    defaultUnit: 'g',
    emoji: '🍯',
    icon: Icons.hive_rounded,
    category: 'Breakfast & Spreads',
    storageLocation: 'Pantry Shelf',
    minimumQuantity: 100.0,
  ),
  HouseholdStaple(
    name: 'Corn Flakes',
    tamilName: 'சோள அவல்',
    defaultQty: 500.0,
    defaultUnit: 'g',
    emoji: '🥣',
    icon: Icons.breakfast_dining_rounded,
    category: 'Breakfast & Spreads',
    storageLocation: 'Pantry Shelf',
    minimumQuantity: 200.0,
  ),
  HouseholdStaple(
    name: 'Rolled Oats',
    tamilName: 'ஓட்ஸ்',
    defaultQty: 1.0,
    defaultUnit: 'kg',
    emoji: '🌾',
    icon: Icons.breakfast_dining_rounded,
    category: 'Breakfast & Spreads',
    storageLocation: 'Pantry Shelf',
    minimumQuantity: 500.0,
  ),
  HouseholdStaple(
    name: 'Dishwash Gel',
    tamilName: 'பாத்திரம் கழுவும் ஜெல்',
    defaultQty: 500.0,
    defaultUnit: 'ml',
    emoji: '🧼',
    icon: Icons.cleaning_services_rounded,
    category: 'Cleaning',
    storageLocation: 'Under Sink',
    minimumQuantity: 250.0,
  ),
  HouseholdStaple(
    name: 'Detergent Powder',
    tamilName: 'சலவை பவுடர்',
    defaultQty: 1.0,
    defaultUnit: 'kg',
    emoji: '🧺',
    icon: Icons.local_laundry_service_rounded,
    category: 'Cleaning',
    storageLocation: 'Laundry Area',
    minimumQuantity: 1.0,
  ),
  HouseholdStaple(
    name: 'Floor Cleaner',
    tamilName: 'தரை சுத்தப்படுத்தி',
    defaultQty: 1.0,
    defaultUnit: 'L',
    emoji: '🧹',
    icon: Icons.cleaning_services_rounded,
    category: 'Cleaning',
    storageLocation: 'Utility Closet',
    minimumQuantity: 1.0,
  ),
  HouseholdStaple(
    name: 'Garbage Bags',
    tamilName: 'குப்பை பைகள்',
    defaultQty: 30.0,
    defaultUnit: 'pcs',
    emoji: '🗑️',
    icon: Icons.delete_outline_rounded,
    category: 'Cleaning',
    storageLocation: 'Under Sink',
    minimumQuantity: 10.0,
  ),
  HouseholdStaple(
    name: 'Toilet Cleaner',
    tamilName: 'கழிப்பறை கிளீனர்',
    defaultQty: 500.0,
    defaultUnit: 'ml',
    emoji: '🚽',
    icon: Icons.cleaning_services_rounded,
    category: 'Cleaning',
    storageLocation: 'Bathroom Shelf',
    minimumQuantity: 250.0,
  ),
  HouseholdStaple(
    name: 'Kitchen Towel',
    tamilName: 'சமையலறை துண்டு',
    defaultQty: 2.0,
    defaultUnit: 'pk',
    emoji: '🧻',
    icon: Icons.cleaning_services_rounded,
    category: 'Cleaning',
    storageLocation: 'Kitchen Counter',
    minimumQuantity: 1.0,
  ),
  HouseholdStaple(
    name: 'Scrub Sponge',
    tamilName: 'துடைக்கும் ஸ்பாஞ்ச்',
    defaultQty: 3.0,
    defaultUnit: 'pk',
    emoji: '🧽',
    icon: Icons.cleaning_services_rounded,
    category: 'Cleaning',
    storageLocation: 'Under Sink',
    minimumQuantity: 1.0,
  ),
  HouseholdStaple(
    name: 'Aluminum Foil',
    tamilName: 'அலுமினியம் ஃபாயில்',
    defaultQty: 1.0,
    defaultUnit: 'pk',
    emoji: '📄',
    icon: Icons.kitchen_rounded,
    category: 'Cleaning',
    storageLocation: 'Kitchen Drawer',
    minimumQuantity: 1.0,
  ),
  HouseholdStaple(
    name: 'Laundry Liquid',
    tamilName: 'திரவ சலவை சோப்பு',
    defaultQty: 1.0,
    defaultUnit: 'L',
    emoji: '🧴',
    icon: Icons.local_laundry_service_rounded,
    category: 'Cleaning',
    storageLocation: 'Laundry Area',
    minimumQuantity: 1.0,
  ),
  HouseholdStaple(
    name: 'Handwash Refill',
    tamilName: 'கை கழுவும் திரவம்',
    defaultQty: 750.0,
    defaultUnit: 'ml',
    emoji: '🧴',
    icon: Icons.sanitizer_rounded,
    category: 'Personal Care',
    storageLocation: 'Bathroom Cabinet',
    minimumQuantity: 250.0,
  ),
  HouseholdStaple(
    name: 'Bath Soap',
    tamilName: 'குளியல் சோப்பு',
    defaultQty: 3.0,
    defaultUnit: 'pk',
    emoji: '🧼',
    icon: Icons.soap_rounded,
    category: 'Personal Care',
    storageLocation: 'Bathroom Cabinet',
    minimumQuantity: 1.0,
  ),
  HouseholdStaple(
    name: 'Toothpaste',
    tamilName: 'பற்பசை',
    defaultQty: 150.0,
    defaultUnit: 'g',
    emoji: '🪥',
    icon: Icons.health_and_safety_rounded,
    category: 'Personal Care',
    storageLocation: 'Bathroom Cabinet',
    minimumQuantity: 100.0,
  ),
  HouseholdStaple(
    name: 'Shampoo',
    tamilName: 'ஷாம்பு',
    defaultQty: 200.0,
    defaultUnit: 'ml',
    emoji: '🧴',
    icon: Icons.shower_rounded,
    category: 'Personal Care',
    storageLocation: 'Bathroom Shelf',
    minimumQuantity: 100.0,
  ),
  HouseholdStaple(
    name: 'Body Lotion',
    tamilName: 'உடல் லோஷன்',
    defaultQty: 200.0,
    defaultUnit: 'ml',
    emoji: '🧴',
    icon: Icons.spa_rounded,
    category: 'Personal Care',
    storageLocation: 'Dressing Table',
    minimumQuantity: 100.0,
  ),
  HouseholdStaple(
    name: 'Face Wash',
    tamilName: 'முக கழுவும் ஜெல்',
    defaultQty: 100.0,
    defaultUnit: 'ml',
    emoji: '🫧',
    icon: Icons.face_rounded,
    category: 'Personal Care',
    storageLocation: 'Bathroom Shelf',
    minimumQuantity: 50.0,
  ),
];

/// Complete master product catalog containing 587+ items
const List<HouseholdStaple> kMasterHouseholdStaples = kMasterProductCatalogStaples;

/// Combined list of all household staples (curated staples + full master catalog)
const List<HouseholdStaple> kHouseholdStaples = [
  ...kCuratedStaples,
  ...kMasterProductCatalogStaples,
];

final Map<String, HouseholdStaple?> _stapleLookupCache = {};

/// Finds the matching household staple for any item name (with fast memoized cache).
HouseholdStaple? findStapleForName(String name, [String? category]) {
  final cleanName = name.trim();
  if (cleanName.isEmpty) return null;
  final cacheKey = cleanName.toLowerCase();

  if (_stapleLookupCache.containsKey(cacheKey)) {
    return _stapleLookupCache[cacheKey];
  }

  // 1. Direct exact name match
  for (final s in kHouseholdStaples) {
    if (s.name.toLowerCase() == cacheKey) {
      _stapleLookupCache[cacheKey] = s;
      return s;
    }
  }

  // 2. Exact Tamil name match
  for (final s in kHouseholdStaples) {
    if (s.tamilName != null && s.tamilName!.toLowerCase() == cacheKey) {
      _stapleLookupCache[cacheKey] = s;
      return s;
    }
  }

  // 3. Alias / common names match
  for (final s in kHouseholdStaples) {
    if (s.commonNames != null) {
      for (final alias in s.commonNames!) {
        if (alias.toLowerCase() == cacheKey) {
          _stapleLookupCache[cacheKey] = s;
          return s;
        }
      }
    }
  }

  // 4. Substring match (e.g., item name is "Butter", staple is "Butter / Amul" or vice versa)
  for (final s in kHouseholdStaples) {
    final sName = s.name.toLowerCase();
    if (sName.contains(cacheKey) || cacheKey.contains(sName)) {
      _stapleLookupCache[cacheKey] = s;
      return s;
    }
  }

  // 5. Token / keyword match (e.g. "White Whole Urad Dal" contains "urad" -> matches Urad Dal)
  final tokens = cacheKey.split(RegExp(r'[\s/,\-\(\)]+')).where((t) => t.length > 2).toList();
  for (final s in kHouseholdStaples) {
    final sName = s.name.toLowerCase();
    int matchCount = 0;
    for (final token in tokens) {
      if (sName.contains(token)) matchCount++;
    }
    if (matchCount >= 2 || (tokens.length == 1 && matchCount == 1)) {
      _stapleLookupCache[cacheKey] = s;
      return s;
    }
  }

  _stapleLookupCache[cacheKey] = null;
  return null;
}

