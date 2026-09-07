import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homestock/features/inventory/category_model.dart';
import 'package:homestock/features/inventory/inventory_model.dart';

void main() {
  group('Offline Category Model & Fallbacks', () {
    test('defaultCategories returns 6 predefined household categories', () {
      final categories = CategoryModel.defaultCategories('test-home-123');
      expect(categories.length, 6);

      final names = categories.map((c) => c.name).toList();
      expect(names, containsAll([
        'Kitchen',
        'Cleaning',
        'Bathroom',
        'Personal Care',
        'Pantry & Snacks',
        'Others',
      ]));

      // Verify each category has a valid homeId, icon, and non-empty colorHex
      for (final cat in categories) {
        expect(cat.homeId, 'test-home-123');
        expect(cat.icon, isNotEmpty);
        expect(cat.colorHex.startsWith('#'), isTrue);
        expect(cat.displayOrder, greaterThan(0));
        // Verify color getter parses without exception
        expect(cat.color, isA<Color>());
        expect(cat.iconData, isA<IconData>());
      }
    });

    test('defaultCategories handles null homeId gracefully', () {
      final categories = CategoryModel.defaultCategories(null);
      expect(categories.length, 6);
      expect(categories.first.id, contains('offline'));
    });

    test('InventoryItemModel category parsed getters work correctly', () {
      final item = InventoryItemModel(
        id: 'item-1',
        homeId: 'home-1',
        categoryName: 'Kitchen',
        categoryIcon: 'restaurant',
        categoryColor: '#F59E0B',
        name: 'Olive Oil',
        quantity: 2.0,
        unit: 'bottle',
        minimumQuantity: 1.0,
        stockStatus: 'IN_STOCK',
        expiryStatus: 'SAFE',
      );

      expect(item.categoryColorParsed, const Color(0xFFF59E0B));
      expect(item.categoryIconData, Icons.restaurant_rounded);
    });

    test('InventoryItemModel handles invalid category color gracefully', () {
      final item = InventoryItemModel(
        id: 'item-2',
        homeId: 'home-1',
        categoryName: 'Unknown',
        categoryIcon: 'unknown_icon',
        categoryColor: 'invalid_hex',
        name: 'Item',
        quantity: 1.0,
        unit: 'pcs',
        minimumQuantity: 1.0,
        stockStatus: 'IN_STOCK',
        expiryStatus: 'SAFE',
      );

      // Falls back to default primary color and inventory_2 icon
      expect(item.categoryColorParsed, const Color(0xFF6366F1));
      expect(item.categoryIconData, Icons.inventory_2_rounded);
    });
  });
}
