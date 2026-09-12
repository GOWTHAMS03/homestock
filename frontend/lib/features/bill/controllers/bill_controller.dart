import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/auth_controller.dart' show apiClientProvider;
import '../../home_switcher/home_controller.dart';
import '../models/bill_models.dart';
import '../services/bill_api_service.dart';

final billApiServiceProvider = Provider<BillApiService>((ref) {
  final client = ref.watch(apiClientProvider);
  return BillApiService(client);
});

@immutable
class BillScannerState {
  final bool isScanning;
  final bool isConfirming;
  final BillScanResponseDto? scanResult;
  final List<BillItemCandidateDto> editableItems;
  final String shopName;
  final String billNumber;
  final DateTime billDate;
  final double totalAmount;
  final List<String> imagePaths;
  final String? errorMessage;
  final BillResponseDto? lastConfirmedBill;

  const BillScannerState({
    this.isScanning = false,
    this.isConfirming = false,
    this.scanResult,
    this.editableItems = const [],
    this.shopName = '',
    this.billNumber = '',
    required this.billDate,
    this.totalAmount = 0.0,
    this.imagePaths = const [],
    this.errorMessage,
    this.lastConfirmedBill,
  });

  BillScannerState copyWith({
    bool? isScanning,
    bool? isConfirming,
    BillScanResponseDto? scanResult,
    List<BillItemCandidateDto>? editableItems,
    String? shopName,
    String? billNumber,
    DateTime? billDate,
    double? totalAmount,
    List<String>? imagePaths,
    String? errorMessage,
    BillResponseDto? lastConfirmedBill,
  }) {
    return BillScannerState(
      isScanning: isScanning ?? this.isScanning,
      isConfirming: isConfirming ?? this.isConfirming,
      scanResult: scanResult ?? this.scanResult,
      editableItems: editableItems ?? this.editableItems,
      shopName: shopName ?? this.shopName,
      billNumber: billNumber ?? this.billNumber,
      billDate: billDate ?? this.billDate,
      totalAmount: totalAmount ?? this.totalAmount,
      imagePaths: imagePaths ?? this.imagePaths,
      errorMessage: errorMessage,
      lastConfirmedBill: lastConfirmedBill ?? this.lastConfirmedBill,
    );
  }
}

class BillScannerController extends StateNotifier<BillScannerState> {
  final BillApiService _apiService;
  final String? _homeId;

  BillScannerController(this._apiService, this._homeId)
      : super(BillScannerState(billDate: DateTime.now()));

  void addImages(List<String> paths) {
    state = state.copyWith(imagePaths: [...state.imagePaths, ...paths]);
  }

  void removeImage(int index) {
    final updated = List<String>.from(state.imagePaths)..removeAt(index);
    state = state.copyWith(imagePaths: updated);
  }

  void clearImages() {
    state = state.copyWith(imagePaths: []);
  }

  Future<bool> scanBillImages({String? storeName, DateTime? billDate}) async {
    if (_homeId == null) {
      state = state.copyWith(errorMessage: 'No active household selected');
      return false;
    }
    if (state.imagePaths.isEmpty) {
      state = state.copyWith(errorMessage: 'Please select or take at least one photo of your bill');
      return false;
    }

    state = state.copyWith(isScanning: true, errorMessage: null);

    try {
      final List<String> base64Images = [];
      for (final path in state.imagePaths) {
        final file = File(path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          base64Images.add(base64Encode(bytes));
        }
      }

      final result = await _apiService.scanBill(
        _homeId,
        base64Images: base64Images,
        storeName: storeName,
        billDate: billDate,
      );

      DateTime parsedDate = DateTime.now();
      if (result.billDate != null) {
        try {
          parsedDate = DateTime.parse(result.billDate!);
        } catch (_) {}
      }

      state = state.copyWith(
        isScanning: false,
        scanResult: result,
        editableItems: result.items,
        shopName: result.shopName ?? 'Retail Store',
        billNumber: result.billNumber ?? '',
        billDate: parsedDate,
        totalAmount: result.totalAmount,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isScanning: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> scanReceiptText(String text, {String? storeName, DateTime? billDate}) async {
    if (_homeId == null) {
      state = state.copyWith(errorMessage: 'No active household selected');
      return false;
    }
    if (text.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Receipt text cannot be empty');
      return false;
    }

    state = state.copyWith(isScanning: true, errorMessage: null);

    try {
      final result = await _apiService.scanBill(
        _homeId,
        rawText: text,
        storeName: storeName,
        billDate: billDate,
      );

      DateTime parsedDate = DateTime.now();
      if (result.billDate != null) {
        try {
          parsedDate = DateTime.parse(result.billDate!);
        } catch (_) {}
      }

      state = state.copyWith(
        isScanning: false,
        scanResult: result,
        editableItems: result.items,
        shopName: result.shopName ?? 'Retail Store',
        billNumber: result.billNumber ?? '',
        billDate: parsedDate,
        totalAmount: result.totalAmount,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isScanning: false, errorMessage: e.toString());
      return false;
    }
  }

  void updateShopName(String name) {
    state = state.copyWith(shopName: name);
  }

  void updateBillNumber(String num) {
    state = state.copyWith(billNumber: num);
  }

  void updateBillDate(DateTime date) {
    state = state.copyWith(billDate: date);
  }

  void updateItem(int index, BillItemCandidateDto updatedItem) {
    if (index >= 0 && index < state.editableItems.length) {
      final updatedList = List<BillItemCandidateDto>.from(state.editableItems);
      updatedList[index] = updatedItem;

      // Recompute total amount
      final sum = updatedList.fold<double>(0.0, (acc, item) => acc + item.finalPrice);
      state = state.copyWith(editableItems: updatedList, totalAmount: sum);
    }
  }

  void removeItem(int index) {
    if (index >= 0 && index < state.editableItems.length) {
      final updatedList = List<BillItemCandidateDto>.from(state.editableItems)..removeAt(index);
      final sum = updatedList.fold<double>(0.0, (acc, item) => acc + item.finalPrice);
      state = state.copyWith(editableItems: updatedList, totalAmount: sum);
    }
  }

  void assignMatch(int index, ExistingProductMatchDto match) {
    if (index >= 0 && index < state.editableItems.length) {
      final current = state.editableItems[index];
      final updated = current.copyWith(
        matchedProductId: match.productId,
        matchedInventoryItemId: match.inventoryItemId,
        matchedExistingProductName: match.productName,
        matchStatus: 'AUTO_MATCHED',
        matchConfidence: match.matchScore,
        isNewProductCandidate: false,
      );
      updateItem(index, updated);
    }
  }

  void setAsNewProduct(int index, String newName, {String? category}) {
    if (index >= 0 && index < state.editableItems.length) {
      final current = state.editableItems[index];
      final updated = current.copyWith(
        normalizedItemName: newName,
        matchedProductId: null,
        matchedInventoryItemId: null,
        matchedExistingProductName: null,
        matchStatus: 'NEW_PRODUCT',
        isNewProductCandidate: true,
      );
      updateItem(index, updated);
    }
  }

  Future<BillResponseDto?> confirmBill() async {
    if (_homeId == null) {
      state = state.copyWith(errorMessage: 'No active household');
      return null;
    }
    if (state.editableItems.isEmpty) {
      state = state.copyWith(errorMessage: 'Cannot confirm empty bill. Add at least one item.');
      return null;
    }

    state = state.copyWith(isConfirming: true, errorMessage: null);

    try {
      final dateStr =
          '${state.billDate.year.toString().padLeft(4, '0')}-${state.billDate.month.toString().padLeft(2, '0')}-${state.billDate.day.toString().padLeft(2, '0')}';

      final confirmItems = state.editableItems.map((item) {
        return BillConfirmItemDto(
          rawItemName: item.rawItemName.isNotEmpty ? item.rawItemName : item.normalizedItemName,
          productId: item.matchedProductId,
          inventoryItemId: item.matchedInventoryItemId,
          shoppingListItemId: item.matchedShoppingListItemId,
          createNewProduct: item.isNewProductCandidate || item.matchedProductId == null,
          newProductName: item.normalizedItemName,
          quantity: item.quantity,
          unit: item.unit,
          mrp: item.mrp,
          unitPrice: item.unitPrice,
          discount: item.discount,
          tax: item.tax,
          finalPrice: item.finalPrice,
        );
      }).toList();

      final req = BillConfirmRequestDto(
        shopName: state.shopName.isNotEmpty ? state.shopName : 'Supermarket',
        billNumber: state.billNumber.isNotEmpty ? state.billNumber : null,
        billDate: dateStr,
        totalAmount: state.totalAmount,
        items: confirmItems,
      );

      final confirmed = await _apiService.confirmBill(_homeId, req);

      state = state.copyWith(
        isConfirming: false,
        lastConfirmedBill: confirmed,
        editableItems: [],
        imagePaths: [],
        scanResult: null,
      );

      return confirmed;
    } catch (e) {
      state = state.copyWith(isConfirming: false, errorMessage: e.toString());
      return null;
    }
  }

  void reset() {
    state = BillScannerState(billDate: DateTime.now());
  }
}

final billScannerControllerProvider =
    StateNotifierProvider<BillScannerController, BillScannerState>((ref) {
  final service = ref.watch(billApiServiceProvider);
  final homeState = ref.watch(homeControllerProvider);
  return BillScannerController(service, homeState.activeHome?.id);
});

// ──────────────── Expense Intelligence Controller ────────────────

@immutable
class ExpenseIntelligenceState {
  final bool isLoading;
  final int selectedYear;
  final int selectedMonth;
  final MonthlyExpenseReportDto? report;
  final List<StoreComparisonDto> storeComparison;
  final String? errorMessage;

  const ExpenseIntelligenceState({
    this.isLoading = false,
    required this.selectedYear,
    required this.selectedMonth,
    this.report,
    this.storeComparison = const [],
    this.errorMessage,
  });

  ExpenseIntelligenceState copyWith({
    bool? isLoading,
    int? selectedYear,
    int? selectedMonth,
    MonthlyExpenseReportDto? report,
    List<StoreComparisonDto>? storeComparison,
    String? errorMessage,
  }) {
    return ExpenseIntelligenceState(
      isLoading: isLoading ?? this.isLoading,
      selectedYear: selectedYear ?? this.selectedYear,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      report: report ?? this.report,
      storeComparison: storeComparison ?? this.storeComparison,
      errorMessage: errorMessage,
    );
  }
}

class ExpenseIntelligenceController extends StateNotifier<ExpenseIntelligenceState> {
  final BillApiService _apiService;
  final String? _homeId;

  ExpenseIntelligenceController(this._apiService, this._homeId)
      : super(ExpenseIntelligenceState(
          selectedYear: DateTime.now().year,
          selectedMonth: DateTime.now().month,
        )) {
    if (_homeId != null) {
      loadData();
    }
  }

  Future<void> loadData({int? year, int? month}) async {
    if (_homeId == null) return;

    final targetYear = year ?? state.selectedYear;
    final targetMonth = month ?? state.selectedMonth;

    state = state.copyWith(
      isLoading: true,
      selectedYear: targetYear,
      selectedMonth: targetMonth,
      errorMessage: null,
    );

    try {
      final results = await Future.wait([
        _apiService.getMonthlyExpenseReport(_homeId, year: targetYear, month: targetMonth),
        _apiService.getStoreComparison(_homeId),
      ]);

      state = state.copyWith(
        isLoading: false,
        report: results[0] as MonthlyExpenseReportDto,
        storeComparison: results[1] as List<StoreComparisonDto>,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void previousMonth() {
    int y = state.selectedYear;
    int m = state.selectedMonth - 1;
    if (m < 1) {
      m = 12;
      y--;
    }
    loadData(year: y, month: m);
  }

  void nextMonth() {
    int y = state.selectedYear;
    int m = state.selectedMonth + 1;
    if (m > 12) {
      m = 1;
      y++;
    }
    loadData(year: y, month: m);
  }
}

final expenseIntelligenceControllerProvider =
    StateNotifierProvider<ExpenseIntelligenceController, ExpenseIntelligenceState>((ref) {
  final service = ref.watch(billApiServiceProvider);
  final homeState = ref.watch(homeControllerProvider);
  return ExpenseIntelligenceController(service, homeState.activeHome?.id);
});
