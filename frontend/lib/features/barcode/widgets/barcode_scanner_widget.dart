import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:homestock/core/constants/app_colors.dart';
import 'package:homestock/core/constants/app_spacing.dart';
import 'package:homestock/features/shopping/shopping_model.dart';
import '../barcode_scan_controller.dart';
import 'barcode_result_bottom_sheet.dart';
import 'manual_barcode_dialog.dart';
import 'quick_scan_sheet.dart';

class BarcodeScannerWidget extends ConsumerStatefulWidget {
  final ShoppingItemModel? targetShoppingItem;

  const BarcodeScannerWidget({super.key, this.targetShoppingItem});

  static Future<void> open(BuildContext context, {ShoppingItemModel? targetShoppingItem}) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BarcodeScannerWidget(targetShoppingItem: targetShoppingItem),
      ),
    );
  }

  @override
  ConsumerState<BarcodeScannerWidget> createState() => _BarcodeScannerWidgetState();
}

class _BarcodeScannerWidgetState extends ConsumerState<BarcodeScannerWidget>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late MobileScannerController _cameraController;
  late AnimationController _laserAnimController;
  late Animation<double> _laserAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (widget.targetShoppingItem != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(barcodeScanControllerProvider.notifier).setTargetShoppingItem(widget.targetShoppingItem);
      });
    }

    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _laserAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
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

  void _onDetect(BarcodeCapture capture) {
    final state = ref.read(barcodeScanControllerProvider);
    if (!state.isScanning || state.isLoading) return;

    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue;
      if (code != null && code.isNotEmpty) {
        ref.read(barcodeScanControllerProvider.notifier).onBarcodeDetected(code);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(barcodeScanControllerProvider);

    // If a result is ready in single-scan mode, open the result sheet
    ref.listen<BarcodeScanState>(barcodeScanControllerProvider, (prev, next) {
      if (!next.isQuickScanMode && next.lastResult != null && (prev?.lastResult == null || prev?.isLoading == true)) {
        BarcodeResultBottomSheet.show(
          context,
          next.lastResult!,
          onDismissed: () {
            ref.read(barcodeScanControllerProvider.notifier).resumeScanning();
          },
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera Preview
          MobileScanner(
            controller: _cameraController,
            onDetect: _onDetect,
            errorBuilder: (context, error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 64),
                      const SizedBox(height: AppSpacing.md),
                      const Text(
                        'Camera Permission Required',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const Text(
                        'Please allow camera access to scan product barcodes.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ElevatedButton.icon(
                        onPressed: () => _cameraController.start(),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton.icon(
                        onPressed: () {
                          ManualBarcodeDialog.show(
                            context,
                            (barcode) => ref.read(barcodeScanControllerProvider.notifier).onBarcodeDetected(barcode),
                          );
                        },
                        icon: const Icon(Icons.keyboard_rounded, color: Colors.white, size: 18),
                        label: const Text('Enter Barcode Manually', style: TextStyle(color: Colors.white)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white54),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // 2. Viewfinder Overlay with Animated Laser
          LayoutBuilder(
            builder: (context, constraints) {
              final scanBoxSize = constraints.maxWidth * 0.75;
              final topOffset = (constraints.maxHeight - scanBoxSize) / 2 - 40;

              return Stack(
                children: [
                  // Dark semi-transparent scrim around scan area
                  ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.6),
                      BlendMode.srcOut,
                    ),
                    child: Stack(
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            color: Colors.transparent,
                            backgroundBlendMode: BlendMode.dstOut,
                          ),
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: Container(
                            margin: EdgeInsets.only(top: topOffset > 0 ? topOffset * 0.4 : 0),
                            width: scanBoxSize,
                            height: scanBoxSize * 0.65,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Viewfinder Border & Animated Laser Line
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      margin: EdgeInsets.only(top: topOffset > 0 ? topOffset * 0.4 : 0),
                      width: scanBoxSize,
                      height: scanBoxSize * 0.65,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primaryLight, width: 2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedBuilder(
                          animation: _laserAnimation,
                          builder: (context, child) {
                            return Align(
                              alignment: Alignment(0, _laserAnimation.value * 2 - 1),
                              child: Container(
                                width: double.infinity,
                                height: 3,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      AppColors.primary,
                                      AppColors.primaryLight,
                                      Colors.transparent,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.7),
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

                  // Instructions text below viewfinder
                  Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: EdgeInsets.only(top: (topOffset > 0 ? topOffset * 0.4 : 0) + scanBoxSize * 0.65 + 24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Align barcode within frame',
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // 3. Top Controls (Back, Title, Flashlight, Quick Scan Mode, Target Item)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 26),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Scan Product',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      // Flash Toggle
                      IconButton(
                        icon: Icon(
                          scanState.isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                          color: scanState.isFlashOn ? Colors.amber : Colors.white70,
                          size: 24,
                        ),
                        tooltip: 'Flashlight',
                        onPressed: () {
                          _cameraController.toggleTorch();
                          ref.read(barcodeScanControllerProvider.notifier).toggleFlash();
                        },
                      ),
                      // Quick Scan Mode Toggle
                      IconButton(
                        icon: Icon(
                          scanState.isQuickScanMode ? Icons.playlist_add_check_circle_rounded : Icons.playlist_add_rounded,
                          color: scanState.isQuickScanMode ? AppColors.primaryLight : Colors.white70,
                          size: 26,
                        ),
                        tooltip: scanState.isQuickScanMode ? 'Quick Scan Mode ON' : 'Single Scan Mode',
                        onPressed: () => ref.read(barcodeScanControllerProvider.notifier).toggleQuickScanMode(),
                      ),
                    ],
                  ),
                  if (scanState.targetShoppingItem != null)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.8)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Target Item: ${scanState.targetShoppingItem!.itemName} (${scanState.targetShoppingItem!.quantity.toInt()} ${scanState.targetShoppingItem!.unit})',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          InkWell(
                            onTap: () => ref.read(barcodeScanControllerProvider.notifier).setTargetShoppingItem(null),
                            child: const Icon(Icons.close_rounded, color: Colors.white70, size: 16),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 4. Loading Indicator Overlay
          if (scanState.isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 12),
                    Text(
                      'Identifying product...',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),

          // 5. Bottom Controls: Manual Entry & Quick Scan Running List
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Quick Scan Drawer if in quick scan mode
                  if (scanState.isQuickScanMode)
                    const QuickScanSheet()
                  else
                    // Manual entry button
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: TextButton.icon(
                        onPressed: () {
                          ManualBarcodeDialog.show(
                            context,
                            (barcode) => ref.read(barcodeScanControllerProvider.notifier).onBarcodeDetected(barcode),
                          );
                        },
                        icon: const Icon(Icons.keyboard_rounded, color: Colors.white70, size: 18),
                        label: const Text(
                          'Enter barcode manually',
                          style: TextStyle(color: Colors.white70, fontSize: 13, decoration: TextDecoration.underline),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
