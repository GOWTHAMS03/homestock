import 'package:flutter/material.dart';

/// Maps catalog iconKey identifiers to Material IconData and Emojis.
class ProductIconMapper {
  static const Map<String, IconData> _keyToIcon = {
    'rice': Icons.grain_rounded,
    'grain': Icons.grain_rounded,
    'grains': Icons.grain_rounded,
    'dal': Icons.circle,
    'oil': Icons.opacity_rounded,
    'masala': Icons.soup_kitchen_rounded,
    'spice': Icons.soup_kitchen_rounded,
    'condiment': Icons.dinner_dining_rounded,
    'fresh_produce': Icons.eco_rounded,
    'fruit': Icons.apple_rounded,
    'vegetable': Icons.eco_rounded,
    'dairy': Icons.egg_rounded,
    'beverage': Icons.local_cafe_rounded,
    'snacks': Icons.bakery_dining_rounded,
    'cleaning': Icons.cleaning_services_rounded,
    'personal_care': Icons.spa_rounded,
    'baby_care': Icons.child_care_rounded,
    'pets': Icons.pets_rounded,
    'hardware': Icons.build_rounded,
    'pooja': Icons.wb_sunny_rounded,
    'staple': Icons.inventory_2_rounded,
    'packaged_food': Icons.inventory_2_rounded,
  };

  static const Map<String, String> _keyToEmoji = {
    'rice': '🌾',
    'grain': '🌾',
    'grains': '🌾',
    'dal': '🥣',
    'oil': '🫒',
    'masala': '🌶️',
    'spice': '🌶️',
    'condiment': '🥫',
    'fresh_produce': '🥬',
    'fruit': '🍎',
    'vegetable': '🥦',
    'dairy': '🥛',
    'beverage': '☕',
    'snacks': '🍪',
    'cleaning': '🧹',
    'personal_care': '🧴',
    'baby_care': '🍼',
    'pets': '🐾',
    'hardware': '💡',
    'pooja': '🪔',
    'staple': '📦',
    'packaged_food': '🍱',
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

