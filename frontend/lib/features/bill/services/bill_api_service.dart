import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../models/bill_models.dart';

class BillApiService {
  final ApiClient _apiClient;

  BillApiService(this._apiClient);

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

    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.billScan(homeId),
      data: payload,
    );

    if (response.statusCode == 200 && response.data != null) {
      return BillScanResponseDto.fromJson(response.data!);
    }
    throw Exception('Failed to scan bill: ${response.statusCode}');
  }

  /// Confirm scanned bill items after human review to commit inventory & purchase records
  Future<BillResponseDto> confirmBill(
    String homeId,
    BillConfirmRequestDto request,
  ) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.billConfirm(homeId),
      data: request.toJson(),
    );

    if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
      return BillResponseDto.fromJson(response.data!);
    }
    throw Exception('Failed to confirm bill: ${response.statusCode}');
  }

  /// Fetch past confirmed bills
  Future<List<BillResponseDto>> getBills(
    String homeId, {
    int page = 0,
    int size = 20,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.bills(homeId),
      queryParameters: {'page': page, 'size': size},
    );

    if (response.statusCode == 200 && response.data != null) {
      final content = response.data!['content'] as List<dynamic>? ?? [];
      return content.map((e) => BillResponseDto.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Fetch single bill details
  Future<BillResponseDto> getBillDetails(String homeId, String billId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.billById(homeId, billId),
    );

    if (response.statusCode == 200 && response.data != null) {
      return BillResponseDto.fromJson(response.data!);
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

    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.monthlyExpenseReport(homeId),
      queryParameters: query.isEmpty ? null : query,
    );

    if (response.statusCode == 200 && response.data != null) {
      return MonthlyExpenseReportDto.fromJson(response.data!);
    }
    throw Exception('Failed to load monthly expense report');
  }

  /// Fetch store spending and price comparison
  Future<List<StoreComparisonDto>> getStoreComparison(String homeId) async {
    final response = await _apiClient.get<List<dynamic>>(
      ApiEndpoints.storePriceComparison(homeId),
    );

    if (response.statusCode == 200 && response.data != null) {
      return response.data!
          .map((e) => StoreComparisonDto.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Fetch product price history
  Future<ProductPriceHistoryDto> getProductPriceHistory(String homeId, String productId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.productPriceHistory(homeId, productId),
    );

    if (response.statusCode == 200 && response.data != null) {
      return ProductPriceHistoryDto.fromJson(response.data!);
    }
    throw Exception('Failed to load product price history');
  }
}
