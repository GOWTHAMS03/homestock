import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:homestock/core/constants/app_colors.dart';
import 'package:homestock/core/constants/app_spacing.dart';
import 'package:homestock/features/barcode/barcode_models.dart';
import 'package:homestock/features/barcode/barcode_repository.dart';
import 'package:homestock/features/barcode/widgets/manual_barcode_dialog.dart';
import 'package:homestock/features/home_switcher/home_controller.dart';
import 'shopping_model.dart';

class ShoppingContinuousScannerScreen extends ConsumerStatefulWidget {
  final List<ShoppingItemModel> items;
  final Map<String, bool> inCart;
  final Function(ShoppingItemModel item) onToggleInCart;
  final Function(ProductCatalogModel product)? onAddUnlistedProduct;

  const ShoppingContinuousScannerScreen({
    super.key,
    required this.items,
    required this.inCart,
    required this.onToggleInCart,
    this.onAddUnlistedProduct,
  });

  static Future<void> open(
    BuildContext context, {
    required List<ShoppingItemModel> items,
    required Map<String, bool> inCart,
    required Function(ShoppingItemModel item) onToggleInCart,
    Function(ProductCatalogModel product)? onAddUnlistedProduct,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ShoppingContinuousScannerScreen(
          items: items,
          inCart: inCart,
          onToggleInCart: onToggleInCart,
          onAddUnlistedProduct: onAddUnlistedProduct,
        ),
      ),
    );
  }

  @override
  ConsumerState<ShoppingContinuousScannerScreen> createState() =>
      _ShoppingContinuousScannerScreenState();
}

class _ShoppingContinuousScannerScreenState
    extends ConsumerState<ShoppingContinuousScannerScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late MobileScannerController _cameraController;
  late AnimationController _laserAnimController;
  late Animation<double> _laserAnimation;

  String? _lastScannedBarcode;
  DateTime? _lastScanTime;
  String? _lastDetectedMessage;
  bool _isFlashOn = false;
  bool _isProcessing = false;
  ProductCatalogModel? _unlistedProduct;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _laserAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _laserAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.resumed) {
      _cameraController.start();
    } else if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _cameraController.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _laserAnimController.dispose();
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> _handleBarcodeDetected(String rawCode) async {
    final now = DateTime.now();
    final repo = ref.read(barcodeRepositoryProvider);
    final normalized = repo.normalizer.normalizeBarcode(rawCode);

    if (normalized.isEmpty || _isProcessing) return;

    // Debounce duplicate reads within 1.8s
    if (_lastScannedBarcode == normalized &&
        _lastScanTime != null &&
        now.difference(_lastScanTime!).inMilliseconds < 1800) {
      return;
    }

    _lastScannedBarcode = normalized;
    _lastScanTime = now;
    HapticFeedback.mediumImpact();

    setState(() {
      _isProcessing = true;
      _unlistedProduct = null;
    });

    final homeId = ref.read(homeControllerProvider).activeHome?.id ?? '';

    // Step 1: Check if any item in shopping list directly matches this barcode
    ShoppingItemModel? matchedItem;
    for (final item in widget.items) {
      if (item.barcode != null &&
          repo.normalizer.normalizeBarcode(item.barcode!) == normalized) {
        matchedItem = item;
        break;
      }
    }

    // Step 2: If no direct barcode match, look up the product catalog & match by name
    ProductCatalogModel? resolvedProduct;
    if (matchedItem == null) {
      final lookup = await repo.lookupBarcode(normalized, homeId: homeId);
      if (lookup.product != null) {
        resolvedProduct = lookup.product;
        final scannedName = resolvedProduct!.name.toLowerCase().trim();
        for (final item in widget.items) {
          final itemName = item.itemName.toLowerCase().trim();
          if (scannedName.contains(itemName) || itemName.contains(scannedName)) {
            matchedItem = item;
            break;
          }
        }
      }
    }

    if (!mounted) return;

    if (matchedItem != null) {
      // Direct hit on shopping list! Check it off in cart
      widget.onToggleInCart(matchedItem);
      setState(() {
        _isProcessing = false;
        _lastDetectedMessage = '✓ Checked ${matchedItem!.itemName} into cart!';
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _lastDetectedMessage?.contains(matchedItem!.itemName) == true) {
          setState(() => _lastDetectedMessage = null);
        }
      });
    } else if (resolvedProduct != null) {
      // Product resolved but not on list: offer to add to cart
      setState(() {
        _isProcessing = false;
        _unlistedProduct = resolvedProduct;
      });
    } else {
      // Completely unknown barcode
      setState(() {
        _isProcessing = false;
        _lastDetectedMessage = 'Barcode $normalized not found on list';
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _lastDetectedMessage = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = widget.inCart.values.where((v) => v).length;
    final totalCount = widget.items.length;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera View
          MobileScanner(
            controller: _cameraController,
            onDetect: (capture) {
              for (final b in capture.barcodes) {
                final code = b.rawValue;
                if (code != null && code.isNotEmpty) {
                  _handleBarcodeDetected(code);
                  break;
                }
              }
            },
          ),

          // 2. Viewfinder & Animated Laser
          LayoutBuilder(
            builder: (context, constraints) {
              final boxSize = constraints.maxWidth * 0.76;
              return Stack(
                children: [
                  Center(
                    child: Container(
                      width: boxSize,
                      height: boxSize * 0.6,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.hsGreen, width: 2.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: AnimatedBuilder(
                          animation: _laserAnimation,
                          builder: (context, child) {
                            return Align(
                              alignment: Alignment(0, _laserAnimation.value * 2 - 1),
                              child: Container(
                                width: double.infinity,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: AppColors.hsGreen,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.hsGreen.withValues(alpha: 0.8),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: EdgeInsets.only(top: boxSize * 0.6 + 24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Scan items off shelves continuously',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // 3. Top Floating Status Banner & Controls
          SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Continuous Shelf Scan 🛒',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '$cartCount of $totalCount items in cart',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      // Flashlight toggle
                      IconButton(
                        icon: Icon(
                          _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                          color: _isFlashOn ? Colors.amber : Colors.white70,
                        ),
                        onPressed: () {
                          _cameraController.toggleTorch();
                          setState(() => _isFlashOn = !_isFlashOn);
                        },
                      ),
                    ],
                  ),
                ),

                // Success/Alert Notification Toast
                if (_lastDetectedMessage != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _lastDetectedMessage!,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // 4. Unlisted Item Prompt (if scanned an item not in shopping list)
          if (_unlistedProduct != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 120,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.add_shopping_cart_rounded, color: AppColors.primary, size: 24),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _unlistedProduct!.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Not currently on your shopping list',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => setState(() => _unlistedProduct = null),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (widget.onAddUnlistedProduct != null) {
                            widget.onAddUnlistedProduct!(_unlistedProduct!);
                          }
                          setState(() {
                            _lastDetectedMessage = '✓ Added ${_unlistedProduct!.name} to cart!';
                            _unlistedProduct = null;
                          });
                        },
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add to This Shopping Trip'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 5. Bottom Live Checklist Overlay
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle and Summary Row
                    Row(
                      children: [
                        const Icon(Icons.checklist_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '$cartCount / $totalCount in Cart',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimary),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () {
                            ManualBarcodeDialog.show(
                              context,
                              (barcode) => _handleBarcodeDetected(barcode),
                            );
                          },
                          icon: const Icon(Icons.keyboard_rounded, size: 16),
                          label: const Text('Type Code', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Horizontal pills of remaining items
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.items.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final item = widget.items[index];
                          final inCart = widget.inCart[item.id] ?? false;

                          return InkWell(
                            onTap: () => widget.onToggleInCart(item),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: inCart ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: inCart ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    inCart ? Icons.check_circle_rounded : Icons.circle_outlined,
                                    size: 16,
                                    color: inCart ? const Color(0xFF10B981) : Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    item.itemName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: inCart ? const Color(0xFF15803D) : AppColors.textPrimary,
                                      decoration: inCart ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Finish / Return to Summary Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.check_rounded, size: 20),
                        label: Text('Done Scanning ($cartCount in cart)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
