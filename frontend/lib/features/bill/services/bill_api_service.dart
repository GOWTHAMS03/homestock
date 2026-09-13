import 'package:dio/dio.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../models/bill_models.dart';

class BillApiService {
  final ApiClient _apiClient;

  BillApiService(this._apiClient);

  Map<String, dynamic> _extractData(dynamic responseData) {
    if (responseData is Map) {
      final map = Map<String, dynamic>.from(responseData);
      if (map['data'] is Map) {
        return Map<String, dynamic>.from(map['data'] as Map);
      }
      return map;
    }
    return {};
  }

  List<dynamic> _extractList(dynamic responseData) {
    if (responseData is List) return responseData;
    if (responseData is Map) {
      final map = Map<String, dynamic>.from(responseData);
      if (map['data'] is List) return map['data'] as List;
      if (map['content'] is List) return map['content'] as List;
    }
    return [];
  }

  /// Scan a receipt by sending OCR text, single base64 image, or multiple images
  Future<BillScanResponseDto> scanBill(
    String homeId, {
    String? rawText,
    String? base64Image,
    List<String>? base64Images,
    String? storeName,
    DateTime? billDate,
  }) async {
    final payload = <String, dynamic>{};
    if (rawText != null) payload['rawText'] = rawText;
    if (base64Image != null) payload['base64Image'] = base64Image;
    if (base64Images != null && base64Images.isNotEmpty) payload['base64Images'] = base64Images;
    if (storeName != null) payload['storeName'] = storeName;
    if (billDate != null) {
      payload['billDate'] =
          '${billDate.year.toString().padLeft(4, '0')}-${billDate.month.toString().padLeft(2, '0')}-${billDate.day.toString().padLeft(2, '0')}';
    }

    final response = await _apiClient.post<dynamic>(
      ApiEndpoints.billScan(homeId),
      data: payload,
      options: Options(
        sendTimeout: const Duration(seconds: 45),
        receiveTimeout: const Duration(seconds: 45),
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final data = _extractData(response.data);
      return BillScanResponseDto.fromJson(data);
    }
    throw Exception('Failed to scan bill: ${response.statusCode}');
  }

  /// Confirm scanned bill items after human review to commit inventory & purchase records
  Future<BillResponseDto> confirmBill(
    String homeId,
    BillConfirmRequestDto request,
  ) async {
    final response = await _apiClient.post<dynamic>(
      ApiEndpoints.billConfirm(homeId),
      data: request.toJson(),
      options: Options(
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
      final data = _extractData(response.data);
      return BillResponseDto.fromJson(data);
    }
    throw Exception('Failed to confirm bill: ${response.statusCode}');
  }

  /// Fetch past confirmed bills
  Future<List<BillResponseDto>> getBills(
    String homeId, {
    int page = 0,
    int size = 20,
  }) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.bills(homeId),
      queryParameters: {'page': page, 'size': size},
    );

    if (response.statusCode == 200 && response.data != null) {
      final data = _extractData(response.data);
      final content = (data['content'] as List<dynamic>?) ?? _extractList(response.data);
      return content.map((e) => BillResponseDto.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    }
    return [];
  }

  /// Fetch single bill details
  Future<BillResponseDto> getBillDetails(String homeId, String billId) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.billById(homeId, billId),
    );

    if (response.statusCode == 200 && response.data != null) {
      final data = _extractData(response.data);
      return BillResponseDto.fromJson(data);
    }
    throw Exception('Failed to load bill details');
  }

  /// Fetch monthly expense report with MoM change, category breakdown, & inflation anomalies
  Future<MonthlyExpenseReportDto> getMonthlyExpenseReport(
    String homeId, {
    int? year,
    int? month,
  }) async {
    final query = <String, dynamic>{};
    if (year != null) query['year'] = year;
    if (month != null) query['month'] = month;

    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.monthlyExpenseReport(homeId),
      queryParameters: query.isEmpty ? null : query,
    );

    if (response.statusCode == 200 && response.data != null) {
      final data = _extractData(response.data);
      return MonthlyExpenseReportDto.fromJson(data);
    }
    throw Exception('Failed to load monthly expense report');
  }

  /// Fetch store spending and price comparison
  Future<List<StoreComparisonDto>> getStoreComparison(String homeId) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.storePriceComparison(homeId),
    );

    if (response.statusCode == 200 && response.data != null) {
      final list = _extractList(response.data);
      return list
          .map((e) => StoreComparisonDto.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return [];
  }

  /// Fetch product price history
  Future<ProductPriceHistoryDto> getProductPriceHistory(String homeId, String productId) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.productPriceHistory(homeId, productId),
    );

    if (response.statusCode == 200 && response.data != null) {
      final data = _extractData(response.data);
      return ProductPriceHistoryDto.fromJson(data);
    }
    throw Exception('Failed to load product price history');
  }

  /// Fetch inventory item price history
  Future<ProductPriceHistoryDto> getItemPriceHistory(String homeId, String itemId) async {
    final response = await _apiClient.get<dynamic>(
      '/homes/$homeId/analytics/inventory/$itemId/price-history',
    );

    if (response.statusCode == 200 && response.data != null) {
      final data = _extractData(response.data);
      return ProductPriceHistoryDto.fromJson(data);
    }
    throw Exception('Failed to load item price history');
  }
}
