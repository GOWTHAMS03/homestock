import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String? homeId;
  final String name;
  final String icon;
  final String colorHex;
  final int displayOrder;

  CategoryModel({
    required this.id,
    this.homeId,
    required this.name,
    required this.icon,
    required this.colorHex,
    required this.displayOrder,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? '',
      homeId: json['homeId'],
      name: json['name'] ?? '',
      icon: json['icon'] ?? 'category',
      colorHex: json['colorHex'] ?? '#6366F1',
      displayOrder: json['displayOrder'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'homeId': homeId,
    'name': name,
    'icon': icon,
    'colorHex': colorHex,
    'displayOrder': displayOrder,
  };

  Color get color {
    try {
      final hex = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF6366F1);
    }
  }

  IconData get iconData {
    switch (icon) {
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'cleaning_services':
        return Icons.cleaning_services_rounded;
      case 'bathtub':
        return Icons.bathtub_rounded;
      case 'face':
        return Icons.face_rounded;
      case 'fastfood':
        return Icons.fastfood_rounded;
      default:
        return Icons.inventory_2_rounded;
    }
  }

  /// Standard default household categories matching the backend defaults.
  /// Available immediately even when completely offline.
  static List<CategoryModel> defaultCategories([String? homeId]) => [
    CategoryModel(
      id: 'default_kitchen_${homeId ?? "offline"}',
      homeId: homeId,
      name: 'Kitchen',
      icon: 'restaurant',
      colorHex: '#F59E0B',
      displayOrder: 1,
    ),
    CategoryModel(
      id: 'default_cleaning_${homeId ?? "offline"}',
      homeId: homeId,
      name: 'Cleaning',
      icon: 'cleaning_services',
      colorHex: '#3B82F6',
      displayOrder: 2,
    ),
    CategoryModel(
      id: 'default_bathroom_${homeId ?? "offline"}',
      homeId: homeId,
      name: 'Bathroom',
      icon: 'bathtub',
      colorHex: '#10B981',
      displayOrder: 3,
    ),
    CategoryModel(
      id: 'default_personal_care_${homeId ?? "offline"}',
      homeId: homeId,
      name: 'Personal Care',
      icon: 'face',
      colorHex: '#EC4899',
      displayOrder: 4,
    ),
    CategoryModel(
      id: 'default_pantry_${homeId ?? "offline"}',
      homeId: homeId,
      name: 'Pantry & Snacks',
      icon: 'fastfood',
      colorHex: '#8B5CF6',
      displayOrder: 5,
    ),
    CategoryModel(
      id: 'default_others_${homeId ?? "offline"}',
      homeId: homeId,
      name: 'Others',
      icon: 'inventory_2',
      colorHex: '#6B7280',
      displayOrder: 6,
    ),
  ];
}
