import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import 'category_model.dart';
import 'inventory_model.dart';

class InventoryRepository {
  final ApiClient apiClient;

  InventoryRepository({required this.apiClient});

  Future<List<InventoryItemModel>> getItems(
    String homeId, {
    String? categoryId,
    String? query,
  }) async {
    final response = await apiClient.dio.get(
      ApiEndpoints.items(homeId),
      queryParameters: {
        'categoryId': ?categoryId,
        if (query != null && query.isNotEmpty) 'query': query,
        'size': 100,
      },
    );

    final data = response.data['data'];
    final content = data['content'] as List? ?? [];
    return content.map((item) => InventoryItemModel.fromJson(item)).toList();
  }

  Future<InventoryItemModel> getItemById(String homeId, String itemId) async {
    final response = await apiClient.dio.get(ApiEndpoints.itemById(homeId, itemId));
    return InventoryItemModel.fromJson(response.data['data']);
  }

  Future<InventoryItemModel> createItem(String homeId, Map<String, dynamic> data) async {
    final response = await apiClient.dio.post(
      ApiEndpoints.items(homeId),
      data: data,
    );
    return InventoryItemModel.fromJson(response.data['data']);
  }

  Future<InventoryItemModel> updateItem(
      String homeId, String itemId, Map<String, dynamic> data) async {
    final response = await apiClient.dio.put(
      ApiEndpoints.itemById(homeId, itemId),
      data: data,
    );
    return InventoryItemModel.fromJson(response.data['data']);
  }

  Future<InventoryItemModel> updateStock(
    String homeId,
    String itemId, {
    required String transactionType,
    required double quantityChange,
    String? reason,
  }) async {
    final response = await apiClient.dio.post(
      ApiEndpoints.itemStock(homeId, itemId),
      data: {
        'transactionType': transactionType,
        'quantityChange': quantityChange,
        'reason': reason,
      },
    );
    return InventoryItemModel.fromJson(response.data['data']);
  }

  Future<List<StockTransactionModel>> getTransactions(String homeId, String itemId) async {
    final response = await apiClient.dio.get(
      ApiEndpoints.itemTransactions(homeId, itemId),
      queryParameters: {'size': 50},
    );
    final list = response.data['data']['content'] as List? ?? [];
    return list.map((item) => StockTransactionModel.fromJson(item)).toList();
  }

  Future<List<CategoryModel>> getCategories(String homeId) async {
    final response = await apiClient.dio.get(ApiEndpoints.categories(homeId));
    final list = response.data['data'] as List? ?? [];
    return list.map((item) => CategoryModel.fromJson(item)).toList();
  }

  Future<void> deleteItem(String homeId, String itemId) async {
    await apiClient.dio.delete(ApiEndpoints.itemById(homeId, itemId));
  }

  Future<String?> uploadImage(String homeId, String itemId, XFile file) async {
    final bytes = await file.readAsBytes();
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: file.name),
    });

    final response = await apiClient.dio.post(
      ApiEndpoints.itemImage(homeId, itemId),
      data: formData,
    );
    return response.data['data']['imageUrl'] as String?;
  }
}
