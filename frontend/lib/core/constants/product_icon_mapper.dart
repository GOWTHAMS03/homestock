import 'package:flutter/material.dart';

/// Maps catalog iconKey identifiers to Material IconData and Emojis.
class ProductIconMapper {
  static const Map<String, IconData> _keyToIcon = {
    'rice': Icons.grain_rounded,
    'grain': Icons.grain_rounded,
    'grains': Icons.grain_rounded,
    'groceries': Icons.inventory_2_rounded,
    'staple': Icons.inventory_2_rounded,
    'packaged_food': Icons.inventory_2_rounded,
    'baking': Icons.bakery_dining_rounded,
    'dal': Icons.circle,
    'oil': Icons.opacity_rounded,
    'masala': Icons.soup_kitchen_rounded,
    'spice': Icons.soup_kitchen_rounded,
    'spices': Icons.soup_kitchen_rounded,
    'salt': Icons.soup_kitchen_rounded,
    'condiment': Icons.dinner_dining_rounded,
    'condiments': Icons.dinner_dining_rounded,
    'fresh_produce': Icons.eco_rounded,
    'fruit': Icons.eco_rounded,
    'fruits': Icons.eco_rounded,
    'vegetable': Icons.eco_rounded,
    'vegetables': Icons.eco_rounded,
    'dairy': Icons.egg_rounded,
    'beverage': Icons.local_cafe_rounded,
    'beverages': Icons.local_cafe_rounded,
    'breakfast': Icons.bakery_dining_rounded,
    'snacks': Icons.bakery_dining_rounded,
    'cleaning': Icons.cleaning_services_rounded,
    'laundry': Icons.local_laundry_service_rounded,
    'paper': Icons.receipt_long_rounded,
    'kitchen': Icons.kitchen_rounded,
    'utility': Icons.build_rounded,
    'personal_care': Icons.spa_rounded,
    'baby': Icons.child_care_rounded,
    'baby_care': Icons.child_care_rounded,
    'pet': Icons.pets_rounded,
    'pets': Icons.pets_rounded,
    'hardware': Icons.build_rounded,
    'pooja': Icons.wb_sunny_rounded,
    'meat': Icons.restaurant_rounded,
    'seafood': Icons.set_meal_rounded,
  };

  static const Map<String, String> _keyToEmoji = {
    'rice': '🌾',
    'grain': '🌾',
    'grains': '🌾',
    'groceries': '🛒',
    'staple': '📦',
    'packaged_food': '🍱',
    'baking': '🧁',
    'dal': '🥣',
    'oil': '🫒',
    'masala': '🌶️',
    'spice': '🌶️',
    'spices': '🌶️',
    'salt': '🧂',
    'condiment': '🥫',
    'condiments': '🥫',
    'fresh_produce': '🥬',
    'fruit': '🍎',
    'fruits': '🍎',
    'vegetable': '🥦',
    'vegetables': '🥦',
    'dairy': '🥛',
    'beverage': '☕',
    'beverages': '☕',
    'breakfast': '🥣',
    'snacks': '🍪',
    'cleaning': '🧹',
    'laundry': '🧺',
    'paper': '🧻',
    'kitchen': '🍳',
    'utility': '🔧',
    'personal_care': '🧴',
    'baby': '🍼',
    'baby_care': '🍼',
    'pet': '🐾',
    'pets': '🐾',
    'hardware': '💡',
    'pooja': '🪔',
    'meat': '🍗',
    'seafood': '🐟',
  };

  /// Returns the corresponding [IconData] for an [iconKey], with fallback to [Icons.inventory_2_rounded].
  static IconData getIcon(String? iconKey) {
    if (iconKey == null) return Icons.inventory_2_rounded;
    return _keyToIcon[iconKey.toLowerCase()] ?? Icons.inventory_2_rounded;
  }

  /// Returns the corresponding emoji string for an [iconKey], with fallback to '📦'.
  static String getEmoji(String? iconKey) {
    if (iconKey == null) return '📦';
    return _keyToEmoji[iconKey.toLowerCase()] ?? '📦';
  }
}
