import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';

/// Interactive camera QR code scanner dialog for scanning household / room invite QR codes.
class InviteQrScannerDialog extends StatefulWidget {
  const InviteQrScannerDialog({super.key});

  /// Opens the QR scanner sheet and returns the detected invite code (if any).
  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      useSafeArea: true,
      builder: (_) => const InviteQrScannerDialog(),
    );
  }

  /// Robust parser to extract the invite code from any format:
  /// raw code, URL parameter, URL path, JSON, or shared text.
  static String? extractInviteCode(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    // 1. Direct raw code match (e.g. "7KQ9P4M2", "  ABC12345 ")
    if (RegExp(r'^[A-Za-z0-9]{6,12}$').hasMatch(trimmed)) {
      return trimmed.toUpperCase();
    }

    // 2. Check URL parameters e.g. ?code=XXXX or ?inviteCode=XXXX
    if (trimmed.contains('?')) {
      try {
        final uri = Uri.parse(trimmed);
        final code = uri.queryParameters['code'] ??
            uri.queryParameters['inviteCode'] ??
            uri.queryParameters['invite'];
        if (code != null && code.trim().isNotEmpty) {
          final clean = code.trim().toUpperCase();
          if (RegExp(r'^[A-Z0-9]{4,16}$').hasMatch(clean)) {
            return clean;
          }
        }
      } catch (_) {}
    }

    // 3. Check URL path e.g. /join/XXXX or homestock://join/XXXX
    if (trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        trimmed.startsWith('homestock://')) {
      try {
        final uri = Uri.parse(trimmed);
        final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
        if (segments.isNotEmpty) {
          final last = segments.last.trim().toUpperCase();
          if (RegExp(r'^[A-Z0-9]{4,16}$').hasMatch(last)) {
            return last;
          }
        }
      } catch (_) {}
    }

    // 4. Check JSON e.g. {"inviteCode":"XXXX"}
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      try {
        final map = jsonDecode(trimmed) as Map<String, dynamic>;
        final code = map['inviteCode'] ?? map['code'] ?? map['invite'];
        if (code != null) {
          final clean = code.toString().trim().toUpperCase();
          if (RegExp(r'^[A-Z0-9]{4,16}$').hasMatch(clean)) {
            return clean;
          }
        }
      } catch (_) {}
    }

    // 5. Look for keyword prefixed code in human text e.g. "invite code: 7KQ9P4M2", "code: 7KQ9P4M2"
    final keywordMatch = RegExp(
      r'(?:code|invite|room|household)[\s:=-]+([A-Za-z0-9]{6,12})\b',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (keywordMatch != null && keywordMatch.group(1) != null) {
      return keywordMatch.group(1)!.toUpperCase();
    }

    // 6. Look for standard mixed alphanumeric code (contains at least one letter and one number)
    final mixedTokenMatch = RegExp(
      r'\b(?=[A-Za-z0-9]{6,12}\b)(?=[A-Za-z0-9]*[0-9])(?=[A-Za-z0-9]*[A-Za-z])[A-Za-z0-9]+\b',
    ).firstMatch(trimmed);
    if (mixedTokenMatch != null && mixedTokenMatch.group(0) != null) {
      return mixedTokenMatch.group(0)!.toUpperCase();
    }

    // 7. Fallback: single word without sentence whitespace
    if (!trimmed.contains(RegExp(r'\s'))) {
      final clean = trimmed.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
      if (clean.length >= 6 && clean.length <= 12) {
        return clean;
      }
    }

    return null;
  }

  @override
  State<InviteQrScannerDialog> createState() => _InviteQrScannerDialogState();
}

class _InviteQrScannerDialogState extends State<InviteQrScannerDialog>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final MobileScannerController _cameraController;
  late final AnimationController _laserAnimController;
  late final Animation<double> _laserAnimation;
  bool _isProcessing = false;
  bool _isTorchOn = false;

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
    if (_isProcessing) return;

    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw != null && raw.isNotEmpty) {
        final code = InviteQrScannerDialog.extractInviteCode(raw);
        if (code != null && code.isNotEmpty) {
          _isProcessing = true;
          _laserAnimController.stop();
          Navigator.of(context).pop(code);
          break;
        }
      }
    }
  }

  void _toggleTorch() {
    setState(() {
      _isTorchOn = !_isTorchOn;
    });
    _cameraController.toggleTorch();
  }

  void _switchCamera() {
    _cameraController.switchCamera();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanBoxSize = (size.width * 0.72).clamp(240.0, 320.0);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera Preview
          MobileScanner(
            controller: _cameraController,
            onDetect: _onDetect,
          ),

          // 2. Translucent Vignette Overlay
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.65),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: Container(
                    color: Colors.black,
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: scanBoxSize,
                    height: scanBoxSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Viewfinder Target Corners & Laser
          Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: scanBoxSize,
              height: scanBoxSize,
              child: Stack(
                children: [
                  // Corner accent borders
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.6),
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),

                  // Animated scanning laser line
                  AnimatedBuilder(
                    animation: _laserAnimation,
                    builder: (context, child) {
                      return Positioned(
                        top: scanBoxSize * _laserAnimation.value,
                        left: 12,
                        right: 12,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppColors.primary,
                                Color(0xFF10B981),
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.8),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // 4. Header Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Scan Household QR',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: _toggleTorch,
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                            color: _isTorchOn ? const Color(0xFFFBBF24) : Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _switchCamera,
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 5. Instruction Bottom Banner
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 28, left: 24, right: 24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Point camera at the household QR code',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Shown on the room owner’s Members or Profile screen',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
