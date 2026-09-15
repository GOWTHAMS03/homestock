import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/location/location_controller.dart';
import '../controllers/shop_owner_controller.dart';
import '../models/shop_models.dart';

class ShopSettingsScreen extends ConsumerStatefulWidget {
  const ShopSettingsScreen({super.key});

  @override
  ConsumerState<ShopSettingsScreen> createState() => _ShopSettingsScreenState();
}

class _ShopSettingsScreenState extends ConsumerState<ShopSettingsScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _addressController = TextEditingController();
  final _areaController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _latController = TextEditingController();
  final _lonController = TextEditingController();
  final _openTimeController = TextEditingController();
  final _closeTimeController = TextEditingController();

  bool _isDetectingLocation = false;
  double? _detectedAccuracy;
  bool _locationVerified = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final shop = ref.read(shopOwnerControllerProvider).shop;
      if (shop != null) {
        _nameController.text = shop.name;
        _phoneController.text = shop.phone ?? '';
        _whatsappController.text = shop.whatsappNumber ?? '';
        _addressController.text = shop.address;
        _areaController.text = shop.area;
        _cityController.text = shop.city;
        _postalCodeController.text = shop.postalCode;
        _latController.text = shop.latitude.toString();
        _lonController.text = shop.longitude.toString();
        _openTimeController.text = shop.openingTime ?? '08:00';
        _closeTimeController.text = shop.closingTime ?? '22:00';
      }
      ref.read(shopOwnerControllerProvider.notifier).loadSubscription();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _addressController.dispose();
    _areaController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _latController.dispose();
    _lonController.dispose();
    _openTimeController.dispose();
    _closeTimeController.dispose();
    super.dispose();
  }

  Future<void> _detectRealGpsLocation() async {
    setState(() => _isDetectingLocation = true);
    try {
      final loc = await ref.read(locationControllerProvider.notifier).getCurrentLocation(forceRefresh: true);
      if (loc != null && mounted) {
        setState(() {
          _latController.text = loc.latitude.toStringAsFixed(6);
          _lonController.text = loc.longitude.toStringAsFixed(6);
          _detectedAccuracy = loc.accuracyMeters;
          _locationVerified = true;

          if (_areaController.text.trim().isEmpty && loc.approximateArea.isNotEmpty && loc.approximateArea != 'Current Location') {
            _areaController.text = loc.approximateArea;
          }
          if (_cityController.text.trim().isEmpty && loc.city.isNotEmpty && loc.city != 'Nearby') {
            _cityController.text = loc.city;
          }
          if (_postalCodeController.text.trim().isEmpty && loc.postalCode.isNotEmpty) {
            _postalCodeController.text = loc.postalCode;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Real GPS location updated: ${loc.latitude.toStringAsFixed(5)}, ${loc.longitude.toStringAsFixed(5)} (±${loc.accuracyMeters.toStringAsFixed(0)}m accuracy)',
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (mounted) {
        final locState = ref.read(locationControllerProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(locState.errorMessage ?? 'Could not acquire GPS position. Ensure location services are enabled.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to detect GPS location: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDetectingLocation = false);
    }
  }

  Future<void> _openCoordinatesInMap() async {
    final lat = double.tryParse(_latController.text.trim());
    final lon = double.tryParse(_lonController.text.trim());
    if (lat == null || lon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid latitude and longitude first')),
      );
      return;
    }
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lon');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open map: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    final lat = double.tryParse(_latController.text.trim());
    final lon = double.tryParse(_lonController.text.trim());

    final data = {
      'shopName': _nameController.text.trim(),
      'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      'whatsappNumber': _whatsappController.text.trim().isEmpty ? null : _whatsappController.text.trim(),
      'address': _addressController.text.trim(),
      'area': _areaController.text.trim().isEmpty ? null : _areaController.text.trim(),
      'city': _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
      'postalCode': _postalCodeController.text.trim().isEmpty ? null : _postalCodeController.text.trim(),
      'latitude': ?lat,
      'longitude': ?lon,
      'openingTime': _openTimeController.text.trim().isEmpty ? null : '${_openTimeController.text.trim()}:00',
      'closingTime': _closeTimeController.text.trim().isEmpty ? null : '${_closeTimeController.text.trim()}:00',
    };

    final success = await ref.read(shopOwnerControllerProvider.notifier).updateShopProfile(data);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shop settings & location updated successfully!'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shopOwnerControllerProvider);
    final sub = state.subscription;
    final plans = state.availablePlans;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Settings & Plan'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Subscription Plan Section
            const Text('Subscription & Tier Limits', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.sm),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              color: AppColors.primaryContainer.withValues(alpha: 0.3),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${sub?.planDisplayName ?? "FREE"} PLAN',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Text(
                            sub?.status ?? 'ACTIVE',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.green.shade800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Product Limit: ${sub?.currentProductCount ?? 0} / ${sub?.maxProducts ?? 50} items'),
                    const SizedBox(height: 4),
                    Text('Analytics Insights: ${sub?.analyticsEnabled == true ? "Enabled" : "Basic"}'),
                    Text('Featured Discovery: ${sub?.featuredEnabled == true ? "Active" : "Standard"}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Plan Options Grid
            if (plans.isNotEmpty) ...[
              const Text('Available Plans', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.sm),
              ...plans.map((plan) => _buildPlanOption(context, plan, sub?.planName == plan.name)),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Profile Edit Section
            const Text('Edit Shop Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Shop Name', prefixIcon: Icon(Icons.storefront_rounded), border: OutlineInputBorder()),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_rounded), border: OutlineInputBorder()),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _whatsappController,
              decoration: const InputDecoration(labelText: 'WhatsApp Number', prefixIcon: Icon(Icons.chat_rounded), border: OutlineInputBorder()),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on_rounded), border: OutlineInputBorder()),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _areaController,
                    decoration: const InputDecoration(labelText: 'Area / Locality', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: _cityController,
                    decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _postalCodeController,
              decoration: const InputDecoration(labelText: 'Postal Code', border: OutlineInputBorder()),
            ),
            const SizedBox(height: AppSpacing.md),

            // Location & Coordinates Card
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Shop GPS Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                if (_detectedAccuracy != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.gps_fixed_rounded, size: 12, color: Color(0xFF047857)),
                        const SizedBox(width: 4),
                        Text(
                          '±${_detectedAccuracy!.toStringAsFixed(0)}m accuracy',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF047857)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Your exact coordinates help nearby customers find and navigate to your physical store.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF0D9488).withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isDetectingLocation ? null : _detectRealGpsLocation,
                      icon: _isDetectingLocation
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.my_location_rounded, size: 16),
                      label: Text(_isDetectingLocation ? 'Acquiring GPS...' : 'Detect Real Location (GPS)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _openCoordinatesInMap,
                    icon: const Icon(Icons.map_rounded, size: 16),
                    label: const Text('View on Map'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F766E),
                      side: const BorderSide(color: Color(0xFF0D9488)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _latController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Latitude (GPS)',
                      prefixIcon: const Icon(Icons.explore_rounded, size: 20),
                      border: const OutlineInputBorder(),
                      suffixIcon: _locationVerified
                          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: _lonController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Longitude (GPS)',
                      prefixIcon: const Icon(Icons.explore_rounded, size: 20),
                      border: const OutlineInputBorder(),
                      suffixIcon: _locationVerified
                          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18)
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _openTimeController,
                    decoration: const InputDecoration(labelText: 'Opening Time', prefixIcon: Icon(Icons.schedule_rounded), border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: _closeTimeController,
                    decoration: const InputDecoration(labelText: 'Closing Time', prefixIcon: Icon(Icons.schedule_rounded), border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            ElevatedButton(
              onPressed: state.isLoading ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: state.isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanOption(BuildContext context, SubscriptionPlanModel plan, bool isCurrent) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: isCurrent ? AppColors.primary : Colors.grey.shade200, width: isCurrent ? 2 : 1),
      ),
      child: ListTile(
        title: Row(
          children: [
            Text(plan.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (isCurrent) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)),
                child: const Text('Current', style: TextStyle(color: Colors.white, fontSize: 10)),
              ),
            ],
          ],
        ),
        subtitle: Text('Up to ${plan.maxProducts} products • ${plan.priceMonthly > 0 ? "₹${plan.priceMonthly.toInt()}/mo" : "Free"}'),
        trailing: isCurrent
            ? null
            : TextButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final ok = await ref.read(shopOwnerControllerProvider.notifier).upgradePlan(plan.name);
                  if (ok && mounted) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Switched to ${plan.displayName}!'), backgroundColor: Colors.green),
                    );
                  }
                },
                child: const Text('Select'),
              ),
      ),
    );
  }
}
