import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import 'shopping_model.dart';

class ShoppingRepository {
  final ApiClient apiClient;

  ShoppingRepository({required this.apiClient});

  Future<ShoppingListModel> getDefaultList(String homeId) async {
    final response = await apiClient.dio.get(ApiEndpoints.defaultShoppingList(homeId));
    return ShoppingListModel.fromJson(response.data['data']);
  }

  Future<ShoppingItemModel> addItem(
    String homeId,
    String listId, {
    String? inventoryItemId,
    required String itemName,
    String? categoryId,
    required double quantity,
    String unit = 'pcs',
    String? notes,
  }) async {
    final response = await apiClient.dio.post(
      ApiEndpoints.shoppingItems(homeId, listId),
      data: {
        'inventoryItemId': ?inventoryItemId,
        'itemName': itemName,
        'categoryId': ?categoryId,
        'quantity': quantity,
        'unit': unit,
        'notes': ?notes,
      },
    );
    return ShoppingItemModel.fromJson(response.data['data']);
  }

  Future<ShoppingItemModel> toggleItem(String homeId, String listId, String itemId) async {
    final response = await apiClient.dio.patch(
      ApiEndpoints.toggleShoppingItem(homeId, listId, itemId),
    );
    return ShoppingItemModel.fromJson(response.data['data']);
  }

  Future<void> deleteItem(String homeId, String listId, String itemId) async {
    await apiClient.dio.delete(ApiEndpoints.shoppingItemById(homeId, listId, itemId));
  }

  Future<void> clearCompleted(String homeId, String listId) async {
    await apiClient.dio.post(ApiEndpoints.clearCompletedShopping(homeId, listId));
  }
}
