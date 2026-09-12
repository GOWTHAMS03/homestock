import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/homestock/homestock_app_bar.dart';
import '../../../core/widgets/homestock/homestock_card.dart';
import '../controllers/bill_controller.dart';
import 'bill_confirmation_screen.dart';

class BillScannerScreen extends ConsumerStatefulWidget {
  const BillScannerScreen({super.key});

  @override
  ConsumerState<BillScannerScreen> createState() => _BillScannerScreenState();
}

class _BillScannerScreenState extends ConsumerState<BillScannerScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _rawTextController = TextEditingController();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnimation = CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rawTextController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.camera) {
        final XFile? photo = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 88,
        );
        if (photo != null) {
          ref.read(billScannerControllerProvider.notifier).addImages([photo.path]);
        }
      } else {
        final List<XFile> images = await _picker.pickMultiImage(
          imageQuality: 88,
        );
        if (images.isNotEmpty) {
          ref.read(billScannerControllerProvider.notifier).addImages(images.map((i) => i.path).toList());
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to select image: $e')),
        );
      }
    }
  }

  Future<void> _startScan() async {
    final controller = ref.read(billScannerControllerProvider.notifier);
    final success = await controller.scanBillImages();
    if (success && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const BillConfirmationScreen()),
      );
    }
  }

  void _showPasteTextDialog() {
    _rawTextController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Paste Bill / Receipt Text',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Paste text from an SMS, e-receipt, Kirana invoice, or OCR clipboard.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _rawTextController,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: 'e.g.\nRELIANCE RETAIL\n1. SUNFLOWER OIL 1L 130.00\n2. TATA SALT 1KG 28.00\nTOTAL 158.00',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Parse & Match Receipt Items', style: TextStyle(fontWeight: FontWeight.w600)),
                onPressed: () async {
                  Navigator.pop(ctx);
                  final success = await ref
                      .read(billScannerControllerProvider.notifier)
                      .scanReceiptText(_rawTextController.text);
                  if (success && mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BillConfirmationScreen()),
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(billScannerControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const HomeStockAppBar(
        title: 'Smart Bill Scanner',
        subtitle: 'Scan receipt to restock inventory & track spend',
      ),
      body: state.isScanning ? _buildScanningLoadingView() : _buildBody(state),
    );
  }

  Widget _buildScanningLoadingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.15 + (_pulseAnimation.value * 0.2)),
                        AppColors.secondary.withValues(alpha: 0.15 + (_pulseAnimation.value * 0.2)),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2 * _pulseAnimation.value),
                        blurRadius: 20 * _pulseAnimation.value,
                        spreadRadius: 6 * _pulseAnimation.value,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.document_scanner,
                      color: AppColors.primary,
                      size: 52,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 28),
            const Text(
              'Analyzing Grocery Bill...',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Extracting shop name, quantities, rates, discounts, and matching against household inventory & shopping list.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            const SizedBox(
              width: 140,
              child: LinearProgressIndicator(
                backgroundColor: Color(0xFFE2E8F0),
                color: AppColors.primary,
                minHeight: 5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BillScannerState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.errorMessage!,
                      style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF6D28D9), Color(0xFF4F46E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.receipt_long, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Instant Bill OCR & Restock',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Capture any DMart, Reliance Fresh, Kirana, or supermarket receipt. HomeStock parses items, maps prices per standard unit, and asks for your confirmation before touching inventory.',
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _buildPillChip(Icons.verified_outlined, 'Zero Blind Writes'),
                    const SizedBox(width: 8),
                    _buildPillChip(Icons.currency_rupee, 'Price History'),
                    const SizedBox(width: 8),
                    _buildPillChip(Icons.checklist, 'Auto Check-off'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Capture Actions
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.camera_alt_outlined,
                  title: 'Take Photo',
                  subtitle: 'Use camera',
                  color: AppColors.primary,
                  onTap: () => _pickImage(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.photo_library_outlined,
                  title: 'Choose Gallery',
                  subtitle: 'Multi-image support',
                  color: AppColors.secondary,
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Manual Paste Button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              backgroundColor: Colors.white,
            ),
            icon: const Icon(Icons.content_paste, color: AppColors.textPrimary, size: 20),
            label: const Text(
              'Paste Receipt Text Manually',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            ),
            onPressed: _showPasteTextDialog,
          ),

          const SizedBox(height: 24),

          // Image Thumbnails (if any selected)
          if (state.imagePaths.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Attached Bill Photos (${state.imagePaths.length})',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                TextButton(
                  onPressed: () => ref.read(billScannerControllerProvider.notifier).clearImages(),
                  child: const Text('Clear all', style: TextStyle(color: Colors.red, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: state.imagePaths.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final path = state.imagePaths[index];
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(path),
                          width: 90,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: InkWell(
                          onTap: () => ref
                              .read(billScannerControllerProvider.notifier)
                              .removeImage(index),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(Icons.close, color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
              ),
              icon: const Icon(Icons.document_scanner),
              label: Text(
                'Scan & Extract ${state.imagePaths.length} Bill Image(s)',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              onPressed: _startScan,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPillChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return HomeStockCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
