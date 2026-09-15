import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/location/location_controller.dart';
import '../controllers/shop_owner_controller.dart';

class ShopOnboardingScreen extends ConsumerStatefulWidget {
  final String? initialLat;
  final String? initialLon;
  final String? initialArea;
  final String? initialCity;
  final String? initialPostalCode;
  final String? initialAddress;

  const ShopOnboardingScreen({
    super.key,
    this.initialLat,
    this.initialLon,
    this.initialArea,
    this.initialCity,
    this.initialPostalCode,
    this.initialAddress,
  });

  @override
  ConsumerState<ShopOnboardingScreen> createState() => _ShopOnboardingScreenState();
}

class _ShopOnboardingScreenState extends ConsumerState<ShopOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _areaController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _gstController = TextEditingController();
  late final TextEditingController _latController;
  late final TextEditingController _lonController;
  final _openTimeController = TextEditingController(text: '08:00');
  final _closeTimeController = TextEditingController(text: '22:00');

  bool _isDetectingLocation = false;
  double? _detectedAccuracy;
  bool _locationVerified = false;

  String _shopType = 'GROCERY';
  String _category = 'Supermarket';

  final List<String> _shopTypes = ['GROCERY', 'SUPERMARKET', 'CONVENIENCE', 'ORGANIC', 'KIRANA', 'SPECIALTY'];
  final List<String> _categories = ['Supermarket', 'Organic Food', 'Dairy & Bakery', 'General Store', 'Produce', 'Fruits & Vegetables'];

  @override
  void initState() {
    super.initState();
    _latController = TextEditingController(text: widget.initialLat ?? '12.9716');
    _lonController = TextEditingController(text: widget.initialLon ?? '77.5946');
    if (widget.initialArea != null) _areaController.text = widget.initialArea!;
    if (widget.initialCity != null) _cityController.text = widget.initialCity!;
    if (widget.initialPostalCode != null) _postalCodeController.text = widget.initialPostalCode!;
    if (widget.initialAddress != null) _addressController.text = widget.initialAddress!;
    if (widget.initialLat != null && widget.initialLon != null) {
      _locationVerified = true;
    } else {
      // Auto-detect GPS location on load if none passed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _detectRealGpsLocation();
      });
    }
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
                    'Real GPS location set: ${loc.latitude.toStringAsFixed(5)}, ${loc.longitude.toStringAsFixed(5)} (±${loc.accuracyMeters.toStringAsFixed(0)}m accuracy)',
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

  @override
  void dispose() {
    _nameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _areaController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _gstController.dispose();
    _latController.dispose();
    _lonController.dispose();
    _openTimeController.dispose();
    _closeTimeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final lat = double.tryParse(_latController.text.trim()) ?? 12.9716;
    final lon = double.tryParse(_lonController.text.trim()) ?? 77.5946;

    final data = {
      'shopName': _nameController.text.trim(),
      'ownerName': _ownerNameController.text.trim(),
      'shopType': _shopType,
      'shopCategory': _category,
      'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      'whatsappNumber': _whatsappController.text.trim().isEmpty ? null : _whatsappController.text.trim(),
      'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      'address': _addressController.text.trim(),
      'area': _areaController.text.trim(),
      'city': _cityController.text.trim(),
      'state': _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
      'postalCode': _postalCodeController.text.trim(),
      'latitude': lat,
      'longitude': lon,
      'openingTime': _openTimeController.text.trim().isEmpty ? null : '${_openTimeController.text.trim()}:00',
      'closingTime': _closeTimeController.text.trim().isEmpty ? null : '${_closeTimeController.text.trim()}:00',
      'gstNumber': _gstController.text.trim().isEmpty ? null : _gstController.text.trim(),
    };

    final success = await ref.read(shopOwnerControllerProvider.notifier).registerShop(data);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shop registered successfully! Pending admin verification.'),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/shop/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shopOwnerControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Physical Shop'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Card(
                elevation: 0,
                color: AppColors.primaryContainer.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Grow Your Retail Reach',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Connect with thousands of nearby households searching for groceries in real-time.',
                              style: TextStyle(fontSize: 13, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Basic Info
              const Text('Shop Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Shop Name *',
                  hintText: 'e.g. Fresh Valley Supermarket',
                  prefixIcon: Icon(Icons.store),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Shop name is required' : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _ownerNameController,
                decoration: const InputDecoration(
                  labelText: 'Owner / Contact Person *',
                  hintText: 'e.g. Ramesh Kumar',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Owner name is required' : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _shopType,
                      decoration: const InputDecoration(labelText: 'Shop Type', border: OutlineInputBorder()),
                      items: _shopTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (v) => setState(() => _shopType = v ?? 'GROCERY'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _category,
                      decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setState(() => _category = v ?? 'Supermarket'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Contact Info
              const Text('Contact & Channels', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'e.g. +91 9876543210',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _whatsappController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'WhatsApp Number (for customer queries)',
                  hintText: 'e.g. +91 9876543210',
                  prefixIcon: Icon(Icons.chat),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Business Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Location & Coordinates
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Shop Location & Coordinates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                'Accurate GPS coordinates allow local customers within 1km–10km to find your shop and navigate directly to it.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Real GPS Auto-Detect Button Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF0D9488).withValues(alpha: 0.25)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D9488),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.my_location_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Detect Real GPS Location',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F766E)),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Auto-fills current latitude, longitude, area, and postal code from your device.',
                                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isDetectingLocation ? null : _detectRealGpsLocation,
                            icon: _isDetectingLocation
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.gps_fixed_rounded, size: 16),
                            label: Text(_isDetectingLocation ? 'Fixing GPS Position...' : 'Use My Real GPS Location'),
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
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Full Street Address *',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Address is required' : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _areaController,
                      decoration: const InputDecoration(labelText: 'Area / Locality *', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Area is required' : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(labelText: 'City *', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.trim().isEmpty ? 'City is required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stateController,
                      decoration: const InputDecoration(labelText: 'State', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextFormField(
                      controller: _postalCodeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Postal Code *', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Postal code is required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Latitude (GPS) *',
                        prefixIcon: const Icon(Icons.explore_rounded, size: 20),
                        border: const OutlineInputBorder(),
                        suffixIcon: _locationVerified
                            ? const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18)
                            : null,
                      ),
                      validator: (v) => v == null || double.tryParse(v) == null ? 'Valid latitude required' : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextFormField(
                      controller: _lonController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Longitude (GPS) *',
                        prefixIcon: const Icon(Icons.explore_rounded, size: 20),
                        border: const OutlineInputBorder(),
                        suffixIcon: _locationVerified
                            ? const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18)
                            : null,
                      ),
                      validator: (v) => v == null || double.tryParse(v) == null ? 'Valid longitude required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Operational Info
              const Text('Operating Hours & Legal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _openTimeController,
                      decoration: const InputDecoration(labelText: 'Opening Time', hintText: '08:00', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextFormField(
                      controller: _closeTimeController,
                      decoration: const InputDecoration(labelText: 'Closing Time', hintText: '22:00', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _gstController,
                decoration: const InputDecoration(
                  labelText: 'GSTIN / Business Registration (Optional)',
                  hintText: 'e.g. 29ABCDE1234F1Z5',
                  prefixIcon: Icon(Icons.receipt_long),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              if (state.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(
                    state.errorMessage!,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),

              ElevatedButton(
                onPressed: state.isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: state.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Register Shop & Enter Portal',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
