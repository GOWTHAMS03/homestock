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
}
