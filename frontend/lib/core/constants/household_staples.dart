/// Core definition of common household staples across pantry, fridge, and cleaning supplies.
class HouseholdStaple {
  final String name;
  final double defaultQty;
  final String defaultUnit;
  final String emoji;
  final String category;
  final String storageLocation;
  final double minimumQuantity;

  final List<double>? customQuantities;
  final List<String>? customBrands;

  const HouseholdStaple({
    required this.name,
    required this.defaultQty,
    required this.defaultUnit,
    required this.emoji,
    required this.category,
    this.storageLocation = 'Pantry',
    this.minimumQuantity = 1.0,
    this.customQuantities,
    this.customBrands,
  });

  double get qty => defaultQty;
  String get unit => defaultUnit;

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
    // Default for pk, bottle, can, box, etc.
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

const List<HouseholdStaple> kHouseholdStaples = [
  // Dairy & Bakery
  HouseholdStaple(name: 'Milk', defaultQty: 1.0, defaultUnit: 'L', emoji: '🥛', category: 'Dairy & Bakery', storageLocation: 'Fridge', minimumQuantity: 1.0),
  HouseholdStaple(name: 'Eggs', defaultQty: 12.0, defaultUnit: 'pcs', emoji: '🥚', category: 'Dairy & Bakery', storageLocation: 'Fridge', minimumQuantity: 6.0),
  HouseholdStaple(name: 'Bread', defaultQty: 1.0, defaultUnit: 'pk', emoji: '🍞', category: 'Dairy & Bakery', storageLocation: 'Pantry', minimumQuantity: 1.0),
  HouseholdStaple(name: 'Butter', defaultQty: 500.0, defaultUnit: 'g', emoji: '🧈', category: 'Dairy & Bakery', storageLocation: 'Fridge', minimumQuantity: 200.0),
  HouseholdStaple(name: 'Paneer', defaultQty: 200.0, defaultUnit: 'g', emoji: '🧀', category: 'Dairy & Bakery', storageLocation: 'Fridge', minimumQuantity: 200.0),
  HouseholdStaple(name: 'Curd / Dahi', defaultQty: 500.0, defaultUnit: 'g', emoji: '🥣', category: 'Dairy & Bakery', storageLocation: 'Fridge', minimumQuantity: 500.0),
  HouseholdStaple(name: 'Cheese Slices', defaultQty: 200.0, defaultUnit: 'g', emoji: '🧀', category: 'Dairy & Bakery', storageLocation: 'Fridge', minimumQuantity: 100.0),
  HouseholdStaple(name: 'Greek Yogurt', defaultQty: 400.0, defaultUnit: 'g', emoji: '🥛', category: 'Dairy & Bakery', storageLocation: 'Fridge', minimumQuantity: 200.0),
  HouseholdStaple(name: 'Brown Bread', defaultQty: 1.0, defaultUnit: 'pk', emoji: '🍞', category: 'Dairy & Bakery', storageLocation: 'Pantry', minimumQuantity: 1.0),
  HouseholdStaple(name: 'Tofu', defaultQty: 200.0, defaultUnit: 'g', emoji: '🧊', category: 'Dairy & Bakery', storageLocation: 'Fridge', minimumQuantity: 200.0),

  // Veg & Fruits
  HouseholdStaple(name: 'Onions', defaultQty: 1.0, defaultUnit: 'kg', emoji: '🧅', category: 'Veg & Fruits', storageLocation: 'Pantry Basket', minimumQuantity: 1.0),
  HouseholdStaple(name: 'Tomatoes', defaultQty: 1.0, defaultUnit: 'kg', emoji: '🍅', category: 'Veg & Fruits', storageLocation: 'Fridge', minimumQuantity: 1.0),
  HouseholdStaple(name: 'Potatoes', defaultQty: 1.0, defaultUnit: 'kg', emoji: '🥔', category: 'Veg & Fruits', storageLocation: 'Pantry Basket', minimumQuantity: 1.0),
  HouseholdStaple(name: 'Bananas', defaultQty: 6.0, defaultUnit: 'pcs', emoji: '🍌', category: 'Veg & Fruits', storageLocation: 'Fruit Bowl', minimumQuantity: 3.0),
  HouseholdStaple(name: 'Apples', defaultQty: 1.0, defaultUnit: 'kg', emoji: '🍎', category: 'Veg & Fruits', storageLocation: 'Fruit Bowl', minimumQuantity: 1.0),
  HouseholdStaple(name: 'Ginger', defaultQty: 100.0, defaultUnit: 'g', emoji: '🫚', category: 'Veg & Fruits', storageLocation: 'Fridge Crisper', minimumQuantity: 50.0),
  HouseholdStaple(name: 'Garlic', defaultQty: 100.0, defaultUnit: 'g', emoji: '🧄', category: 'Veg & Fruits', storageLocation: 'Pantry Basket', minimumQuantity: 50.0),
  HouseholdStaple(name: 'Green Chillies', defaultQty: 100.0, defaultUnit: 'g', emoji: '🌶️', category: 'Veg & Fruits', storageLocation: 'Fridge Crisper', minimumQuantity: 50.0),
  HouseholdStaple(name: 'Lemons', defaultQty: 4.0, defaultUnit: 'pcs', emoji: '🍋', category: 'Veg & Fruits', storageLocation: 'Fridge Crisper', minimumQuantity: 2.0),
  HouseholdStaple(name: 'Coriander', defaultQty: 1.0, defaultUnit: 'pk', emoji: '🌿', category: 'Veg & Fruits', storageLocation: 'Fridge Crisper', minimumQuantity: 1.0),
  HouseholdStaple(name: 'Spinach / Palak', defaultQty: 1.0, defaultUnit: 'pk', emoji: '🥬', category: 'Veg & Fruits', storageLocation: 'Fridge Crisper', minimumQuantity: 1.0),
  HouseholdStaple(name: 'Carrots', defaultQty: 500.0, defaultUnit: 'g', emoji: '🥕', category: 'Veg & Fruits', storageLocation: 'Fridge Crisper', minimumQuantity: 250.0),
  HouseholdStaple(name: 'Capsicum', defaultQty: 500.0, defaultUnit: 'g', emoji: '🫑', category: 'Veg & Fruits', storageLocation: 'Fridge Crisper', minimumQuantity: 250.0),
  HouseholdStaple(name: 'Cucumber', defaultQty: 500.0, defaultUnit: 'g', emoji: '🥒', category: 'Veg & Fruits', storageLocation: 'Fridge Crisper', minimumQuantity: 250.0),
  HouseholdStaple(name: 'Mushrooms', defaultQty: 200.0, defaultUnit: 'g', emoji: '🍄', category: 'Veg & Fruits', storageLocation: 'Fridge', minimumQuantity: 200.0),

  // Grains & Oils
  HouseholdStaple(name: 'Aashirvaad Atta', defaultQty: 5.0, defaultUnit: 'kg', emoji: '🫓', category: 'Grains & Oils', storageLocation: 'Pantry Shelf', minimumQuantity: 2.0),
  HouseholdStaple(name: 'Basmati Rice', defaultQty: 5.0, defaultUnit: 'kg', emoji: '🌾', category: 'Grains & Oils', storageLocation: 'Pantry Shelf', minimumQuantity: 2.0),
  HouseholdStaple(name: 'Sunflower Oil', defaultQty: 1.0, defaultUnit: 'L', emoji: '🌻', category: 'Grains & Oils', storageLocation: 'Pantry Shelf', minimumQuantity: 1.0),
  HouseholdStaple(name: 'Toor Dal', defaultQty: 1.0, defaultUnit: 'kg', emoji: '🥣', category: 'Grains & Oils', storageLocation: 'Pantry Shelf', minimumQuantity: 1.0),
  HouseholdStaple(name: 'Moong Dal', defaultQty: 1.0, defaultUnit: 'kg', emoji: '🫘', category: 'Grains & Oils', storageLocation: 'Pantry Shelf', minimumQuantity: 1.0),
  HouseholdStaple(name: 'Mustard Oil', defaultQty: 1.0, defaultUnit: 'L', emoji: '🫒', category: 'Grains & Oils', storageLocation: 'Pantry Shelf', minimumQuantity: 1.0),
  HouseholdStaple(name: 'Poha', defaultQty: 500.0, defaultUnit: 'g', emoji: '🥣', category: 'Grains & Oils', storageLocation: 'Pantry Shelf', minimumQuantity: 250.0),
  HouseholdStaple(name: 'Suji / Rava', defaultQty: 500.0, defaultUnit: 'g', emoji: '🌾', category: 'Grains & Oils', storageLocation: 'Pantry Shelf', minimumQuantity: 250.0),
  HouseholdStaple(name: 'Chana Dal', defaultQty: 1.0, defaultUnit: 'kg', emoji: '🥣', category: 'Grains & Oils', storageLocation: 'Pantry Shelf', minimumQuantity: 1.0),
  HouseholdStaple(name: 'Besan', defaultQty: 500.0, defaultUnit: 'g', emoji: '🌾', category: 'Grains & Oils', storageLocation: 'Pantry Shelf', minimumQuantity: 250.0),
  HouseholdStaple(name: 'Olive Oil', defaultQty: 500.0, defaultUnit: 'ml', emoji: '🫒', category: 'Grains & Oils', storageLocation: 'Pantry Shelf', minimumQuantity: 200.0),
  HouseholdStaple(name: 'Desi Ghee', defaultQty: 500.0, defaultUnit: 'ml', emoji: '🧈', category: 'Grains & Oils', storageLocation: 'Pantry Shelf', minimumQuantity: 200.0),

  // Pantry & Spices
  HouseholdStaple(name: 'Tata Salt', defaultQty: 1.0, defaultUnit: 'kg', emoji: '🧂', category: 'Pantry & Spices', storageLocation: 'Spice Rack', minimumQuantity: 1.0),
  HouseholdStaple(name: 'Sugar', defaultQty: 1.0, defaultUnit: 'kg', emoji: '🍬', category: 'Pantry & Spices', storageLocation: 'Pantry Shelf', minimumQuantity: 1.0),
  HouseholdStaple(name: 'Tea / Chai', defaultQty: 250.0, defaultUnit: 'g', emoji: '☕', category: 'Pantry & Spices', storageLocation: 'Spice Rack', minimumQuantity: 100.0),
  HouseholdStaple(name: 'Coffee', defaultQty: 100.0, defaultUnit: 'g', emoji: '☕', category: 'Pantry & Spices', storageLocation: 'Spice Rack', minimumQuantity: 50.0),
  HouseholdStaple(name: 'Turmeric Powder', defaultQty: 200.0, defaultUnit: 'g', emoji: '🟡', category: 'Pantry & Spices', storageLocation: 'Spice Rack', minimumQuantity: 100.0),
  HouseholdStaple(name: 'Red Chilli Powder', defaultQty: 200.0, defaultUnit: 'g', emoji: '🌶️', category: 'Pantry & Spices', storageLocation: 'Spice Rack', minimumQuantity: 100.0),
  HouseholdStaple(name: 'Jeera / Cumin', defaultQty: 100.0, defaultUnit: 'g', emoji: '🌿', category: 'Pantry & Spices', storageLocation: 'Spice Rack', minimumQuantity: 50.0),
  HouseholdStaple(name: 'Garam Masala', defaultQty: 100.0, defaultUnit: 'g', emoji: '🥘', category: 'Pantry & Spices', storageLocation: 'Spice Rack', minimumQuantity: 50.0),
  HouseholdStaple(name: 'Mustard Seeds', defaultQty: 100.0, defaultUnit: 'g', emoji: '🟡', category: 'Pantry & Spices', storageLocation: 'Spice Rack', minimumQuantity: 50.0),
  HouseholdStaple(name: 'Coriander Powder', defaultQty: 200.0, defaultUnit: 'g', emoji: '🌿', category: 'Pantry & Spices', storageLocation: 'Spice Rack', minimumQuantity: 100.0),
  HouseholdStaple(name: 'Kasuri Methi', defaultQty: 50.0, defaultUnit: 'g', emoji: '🍃', category: 'Pantry & Spices', storageLocation: 'Spice Rack', minimumQuantity: 25.0),
  HouseholdStaple(name: 'Elaichi / Cardamom', defaultQty: 50.0, defaultUnit: 'g', emoji: '🟢', category: 'Pantry & Spices', storageLocation: 'Spice Rack', minimumQuantity: 25.0),
  HouseholdStaple(name: 'Black Pepper', defaultQty: 100.0, defaultUnit: 'g', emoji: '🫒', category: 'Pantry & Spices', storageLocation: 'Spice Rack', minimumQuantity: 50.0),
  HouseholdStaple(name: 'Jaggery / Gur', defaultQty: 500.0, defaultUnit: 'g', emoji: '🍯', category: 'Pantry & Spices', storageLocation: 'Pantry Shelf', minimumQuantity: 250.0),

  // Beverages & Snacks
  HouseholdStaple(name: 'Biscuits / Cookies', defaultQty: 1.0, defaultUnit: 'pk', emoji: '🍪', category: 'Beverages & Snacks', storageLocation: 'Snack Shelf', minimumQuantity: 1.0),
  HouseholdStaple(name: 'Green Tea', defaultQty: 25.0, defaultUnit: 'pcs', emoji: '🍵', category: 'Beverages & Snacks', storageLocation: 'Pantry Shelf', minimumQuantity: 10.0),
  HouseholdStaple(name: 'Potato Chips', defaultQty: 1.0, defaultUnit: 'pk', emoji: '🥔', category: 'Beverages & Snacks', storageLocation: 'Snack Shelf', minimumQuantity: 1.0),
  HouseholdStaple(name: 'Almonds / Badam', defaultQty: 250.0, defaultUnit: 'g', emoji: '🥜', category: 'Beverages & Snacks', storageLocation: 'Pantry Shelf', minimumQuantity: 100.0),
  HouseholdStaple(name: 'Cashews / Kaju', defaultQty: 250.0, defaultUnit: 'g', emoji: '🥜', category: 'Beverages & Snacks', storageLocation: 'Pantry Shelf', minimumQuantity: 100.0),
  HouseholdStaple(name: 'Instant Noodles', defaultQty: 4.0, defaultUnit: 'pk', emoji: '🍜', category: 'Beverages & Snacks', storageLocation: 'Pantry Shelf', minimumQuantity: 2.0),
  HouseholdStaple(name: 'Dark Chocolate', defaultQty: 1.0, defaultUnit: 'pk', emoji: '🍫', category: 'Beverages & Snacks', storageLocation: 'Fridge', minimumQuantity: 1.0),
  HouseholdStaple(name: 'Fruit Juice', defaultQty: 1.0, defaultUnit: 'L', emoji: '🧃', category: 'Beverages & Snacks', storageLocation: 'Fridge', minimumQuantity: 1.0),

  // Breakfast & Spreads
  HouseholdStaple(name: 'Peanut Butter', defaultQty: 350.0, defaultUnit: 'g', emoji: '🥜', category: 'Breakfast & Spreads', storageLocation: 'Pantry Shelf', minimumQuantity: 100.0),
  HouseholdStaple(name: 'Fruit Jam', defaultQty: 500.0, defaultUnit: 'g', emoji: '🍓', category: 'Breakfast & Spreads', storageLocation: 'Fridge', minimumQuantity: 150.0),
  HouseholdStaple(name: 'Pure Honey', defaultQty: 250.0, defaultUnit: 'g', emoji: '🍯', category: 'Breakfast & Spreads', storageLocation: 'Pantry Shelf', minimumQuantity: 100.0),
  HouseholdStaple(name: 'Corn Flakes', defaultQty: 500.0, defaultUnit: 'g', emoji: '🥣', category: 'Breakfast & Spreads', storageLocation: 'Pantry Shelf', minimumQuantity: 200.0),
  HouseholdStaple(name: 'Rolled Oats', defaultQty: 1.0, defaultUnit: 'kg', emoji: '🌾', category: 'Breakfast & Spreads', storageLocation: 'Pantry Shelf', minimumQuantity: 500.0),

  // Cleaning
  HouseholdStaple(name: 'Dishwash Gel', defaultQty: 500.0, defaultUnit: 'ml', emoji: '🧼', category: 'Cleaning', storageLocation: 'Under Sink', minimumQuantity: 250.0),
  HouseholdStaple(name: 'Detergent Powder', defaultQty: 1.0, defaultUnit: 'kg', emoji: '🧺', category: 'Cleaning', storageLocation: 'Laundry Area', minimumQuantity: 1.0),
  HouseholdStaple(name: 'Floor Cleaner', defaultQty: 1.0, defaultUnit: 'L', emoji: '🧹', category: 'Cleaning', storageLocation: 'Utility Closet', minimumQuantity: 1.0),
  HouseholdStaple(name: 'Garbage Bags', defaultQty: 30.0, defaultUnit: 'pcs', emoji: '🗑️', category: 'Cleaning', storageLocation: 'Under Sink', minimumQuantity: 10.0),
  HouseholdStaple(name: 'Toilet Cleaner', defaultQty: 500.0, defaultUnit: 'ml', emoji: '🚽', category: 'Cleaning', storageLocation: 'Bathroom Shelf', minimumQuantity: 250.0),
  HouseholdStaple(name: 'Kitchen Towel', defaultQty: 2.0, defaultUnit: 'pk', emoji: '🧻', category: 'Cleaning', storageLocation: 'Kitchen Counter', minimumQuantity: 1.0),
  HouseholdStaple(name: 'Scrub Sponge', defaultQty: 3.0, defaultUnit: 'pk', emoji: '🧽', category: 'Cleaning', storageLocation: 'Under Sink', minimumQuantity: 1.0),
  HouseholdStaple(name: 'Aluminum Foil', defaultQty: 1.0, defaultUnit: 'pk', emoji: '📄', category: 'Cleaning', storageLocation: 'Kitchen Drawer', minimumQuantity: 1.0),
  HouseholdStaple(name: 'Laundry Liquid', defaultQty: 1.0, defaultUnit: 'L', emoji: '🧴', category: 'Cleaning', storageLocation: 'Laundry Area', minimumQuantity: 1.0),

  // Personal Care
  HouseholdStaple(name: 'Handwash Refill', defaultQty: 750.0, defaultUnit: 'ml', emoji: '🧴', category: 'Personal Care', storageLocation: 'Bathroom Cabinet', minimumQuantity: 250.0),
  HouseholdStaple(name: 'Bath Soap', defaultQty: 3.0, defaultUnit: 'pk', emoji: '🧼', category: 'Personal Care', storageLocation: 'Bathroom Cabinet', minimumQuantity: 1.0),
  HouseholdStaple(name: 'Toothpaste', defaultQty: 150.0, defaultUnit: 'g', emoji: '🪥', category: 'Personal Care', storageLocation: 'Bathroom Cabinet', minimumQuantity: 100.0),
  HouseholdStaple(name: 'Shampoo', defaultQty: 200.0, defaultUnit: 'ml', emoji: '🧴', category: 'Personal Care', storageLocation: 'Bathroom Shelf', minimumQuantity: 100.0),
  HouseholdStaple(name: 'Body Lotion', defaultQty: 200.0, defaultUnit: 'ml', emoji: '🧴', category: 'Personal Care', storageLocation: 'Dressing Table', minimumQuantity: 100.0),
  HouseholdStaple(name: 'Face Wash', defaultQty: 100.0, defaultUnit: 'ml', emoji: '🫧', category: 'Personal Care', storageLocation: 'Bathroom Shelf', minimumQuantity: 50.0),
];
