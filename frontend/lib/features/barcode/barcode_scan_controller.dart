import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home_switcher/home_controller.dart';
import '../shopping/shopping_model.dart';
import 'barcode_models.dart';
import 'barcode_repository.dart';

const int kBarcodeScanDebounceMs = 1500;

class BarcodeScanState {
  final ScanSessionState sessionState;
  final bool isScanning;
  final bool isLoading;
  final bool isFlashOn;
  final bool isQuickScanMode;
  final bool? hasCameraPermission;
  final BarcodeLookupResult? lastResult;
  final ShoppingItemModel? targetShoppingItem;
  final bool packageSizeMismatch;
  final List<QuickScanSessionItem> quickScanItems;
  final String? errorMessage;

  const BarcodeScanState({
    this.sessionState = ScanSessionState.scanning,
    this.isScanning = true,
    this.isLoading = false,
    this.isFlashOn = false,
    this.isQuickScanMode = false,
    this.hasCameraPermission,
    this.lastResult,
    this.targetShoppingItem,
    this.packageSizeMismatch = false,
    this.quickScanItems = const [],
    this.errorMessage,
  });

  BarcodeScanState copyWith({
    ScanSessionState? sessionState,
    bool? isScanning,
    bool? isLoading,
    bool? isFlashOn,
    bool? isQuickScanMode,
    bool? hasCameraPermission,
    BarcodeLookupResult? Function()? lastResult,
    ShoppingItemModel? Function()? targetShoppingItem,
    bool? packageSizeMismatch,
    List<QuickScanSessionItem>? quickScanItems,
    String? Function()? errorMessage,
  }) {
    return BarcodeScanState(
      sessionState: sessionState ?? this.sessionState,
      isScanning: isScanning ?? this.isScanning,
      isLoading: isLoading ?? this.isLoading,
      isFlashOn: isFlashOn ?? this.isFlashOn,
      isQuickScanMode: isQuickScanMode ?? this.isQuickScanMode,
      hasCameraPermission: hasCameraPermission ?? this.hasCameraPermission,
      lastResult: lastResult != null ? lastResult() : this.lastResult,
      targetShoppingItem: targetShoppingItem != null ? targetShoppingItem() : this.targetShoppingItem,
      packageSizeMismatch: packageSizeMismatch ?? this.packageSizeMismatch,
      quickScanItems: quickScanItems ?? this.quickScanItems,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }
}

final barcodeScanControllerProvider =
    StateNotifierProvider.autoDispose<BarcodeScanController, BarcodeScanState>((ref) {
  return BarcodeScanController(
    repository: ref.watch(barcodeRepositoryProvider),
    ref: ref,
  );
});

class BarcodeScanController extends StateNotifier<BarcodeScanState> {
  final BarcodeRepository _repository;
  final Ref _ref;

  String? _lastScannedBarcode;
  DateTime? _lastScanTime;

  BarcodeScanController({
    required BarcodeRepository repository,
    required Ref ref,
  })  : _repository = repository,
        _ref = ref,
        super(const BarcodeScanState());

  void setCameraPermission(bool granted) {
    state = state.copyWith(hasCameraPermission: granted);
  }

  void setTargetShoppingItem(ShoppingItemModel? item) {
    state = state.copyWith(
      targetShoppingItem: () => item,
      packageSizeMismatch: false,
    );
  }

  void toggleFlash() {
    state = state.copyWith(isFlashOn: !state.isFlashOn);
  }

  void toggleQuickScanMode() {
    state = state.copyWith(
      isQuickScanMode: !state.isQuickScanMode,
      lastResult: () => null,
    );
  }

  Future<void> onBarcodeDetected(String rawBarcode) async {
    final now = DateTime.now();
    final normalized = _repository.normalizer.normalizeBarcode(rawBarcode);

    if (normalized.isEmpty) return;

    // Debounce: protect against duplicate rapid detection
    if (_lastScannedBarcode == normalized &&
        _lastScanTime != null &&
        now.difference(_lastScanTime!).inMilliseconds < kBarcodeScanDebounceMs) {
      return;
    }

    _lastScannedBarcode = normalized;
    _lastScanTime = now;

    // Haptic feedback to give immediate sensory confirmation
    HapticFeedback.mediumImpact();

    final homeId = _ref.read(homeControllerProvider).activeHome?.id ?? '';
    state = state.copyWith(
      sessionState: ScanSessionState.lookingUp,
      isLoading: true,
      isScanning: false,
      errorMessage: () => null,
    );

    try {
      final result = await _repository.lookupBarcode(normalized, homeId: homeId);

      bool sizeMismatch = false;
      if (state.targetShoppingItem != null && result.product != null) {
        sizeMismatch = !result.product!.matchesPackageSize(
          state.targetShoppingItem!.quantity,
          state.targetShoppingItem!.unit,
        );
      }

      final nextSession = result.found
          ? ScanSessionState.found
          : ScanSessionState.notFound;

      if (state.isQuickScanMode) {
        // In Quick Scan mode: accumulate into session without blocking
        _addToQuickScanSession(result);
        state = state.copyWith(
          sessionState: nextSession,
          isLoading: false,
          isScanning: true, // continue scanning immediately in quick scan mode
          lastResult: () => result,
          packageSizeMismatch: sizeMismatch,
        );
      } else {
        // In Single Scan mode: show smart confirmation sheet
        state = state.copyWith(
          sessionState: nextSession,
          isLoading: false,
          lastResult: () => result,
          packageSizeMismatch: sizeMismatch,
        );
      }
    } catch (e) {
      state = state.copyWith(
        sessionState: ScanSessionState.error,
        isLoading: false,
        isScanning: true,
        errorMessage: () => 'Failed to resolve barcode: $e',
      );
    }
  }

  void _addToQuickScanSession(BarcodeLookupResult result) {
    final barcode = result.barcode;
    final name = result.product?.name ??
        result.existingInventory?.name ??
        'Scanned Item ($barcode)';
    final brand = result.product?.brand;
    final unit = result.product?.unit ?? result.existingInventory?.unit ?? 'pcs';
    final existingId = result.existingInventory?.id;

    final existingIndex = state.quickScanItems.indexWhere((i) => i.barcode == barcode);
    if (existingIndex >= 0) {
      final updated = List<QuickScanSessionItem>.from(state.quickScanItems);
      final current = updated[existingIndex];
      updated[existingIndex] = current.copyWith(quantity: current.quantity + 1.0);
      state = state.copyWith(quickScanItems: updated);
    } else {
      final newItem = QuickScanSessionItem(
        barcode: barcode,
        name: name,
        brand: brand,
        quantity: 1.0,
        unit: unit,
        existingInventoryItemId: existingId,
      );
      state = state.copyWith(quickScanItems: [...state.quickScanItems, newItem]);
    }
  }

  void updateQuickScanQuantity(String barcode, double quantity) {
    if (quantity <= 0) {
      removeQuickScanItem(barcode);
      return;
    }
    final updated = state.quickScanItems.map((item) {
      if (item.barcode == barcode) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();
    state = state.copyWith(quickScanItems: updated);
  }

  void removeQuickScanItem(String barcode) {
    final updated = state.quickScanItems.where((i) => i.barcode != barcode).toList();
    state = state.copyWith(quickScanItems: updated);
  }

  void clearQuickScanSession() {
    state = state.copyWith(quickScanItems: const []);
  }

  /// Resumes scanning (e.g. after bottom sheet dismissed)
  void resumeScanning() {
    _lastScannedBarcode = null;
    state = state.copyWith(
      sessionState: ScanSessionState.scanning,
      isScanning: true,
      isLoading: false,
      packageSizeMismatch: false,
      lastResult: () => null,
      errorMessage: () => null,
    );
  }
}
