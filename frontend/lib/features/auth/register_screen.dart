import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/location/location_controller.dart';
import '../../core/location/location_models.dart';
import '../../core/location/location_state.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/homestock/homestock_app_bar.dart';
import '../../core/widgets/homestock/homestock_card.dart';
import 'auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // 'USER' for household members, 'SHOP_OWNER' for physical retail shop owners
  String _accountType = 'USER';

  // Location configuration for Shop Owner
  // 'GPS' = live hardware fix, 'MANUAL' = custom edited location
  String _locationMode = 'GPS';
  bool _isEditingLocation = false;
  bool _isDetectingGps = false;
  double? _shopLat;
  double? _shopLon;
  String? _shopArea;
  String? _shopCity;
  String? _shopPostalCode;
  String? _shopAddress;
  double? _gpsAccuracy;
  String? _gpsError;
  bool _isGpsFixed = false;

  // Controllers for editing / entering shop location
  final _shopAreaController = TextEditingController();
  final _shopCityController = TextEditingController();
  final _shopAddressController = TextEditingController();
  final _shopLatController = TextEditingController();
  final _shopLonController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _shopAreaController.dispose();
    _shopCityController.dispose();
    _shopAddressController.dispose();
    _shopLatController.dispose();
    _shopLonController.dispose();
    super.dispose();
  }

  void _onSelectAccountType(String type) {
    if (_accountType == type) return;
    setState(() {
      _accountType = type;
    });

    // Automatically detect GPS location when switching to Shop Owner if not already fixed
    if (type == 'SHOP_OWNER' && _shopLat == null && !_isDetectingGps && !_isEditingLocation) {
      _autoDetectShopGpsLocation();
    }
  }

  Future<void> _autoDetectShopGpsLocation() async {
    setState(() {
      _isDetectingGps = true;
      _gpsError = null;
      _locationMode = 'GPS';
      _isEditingLocation = false;
    });

    try {
      final locController = ref.read(locationControllerProvider.notifier);
      final locService = ref.read(locationServiceProvider);

      // Check if location services (GPS toggle) are active
      final isServiceEnabled = await locService.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        if (mounted) {
          setState(() {
            _gpsError = 'Device GPS / Location is turned OFF in phone settings. Please turn on Location in Quick Settings or enter store details manually.';
            _isDetectingGps = false;
          });
        }
        return;
      }

      await locController.requestPermissionAndAcquire();
      LocationResult? loc = ref.read(locationControllerProvider).currentLocation;
      loc ??= await locController.getCurrentLocation(forceRefresh: true);

      if (loc != null && mounted) {
        final fixedLoc = loc;
        setState(() {
          _shopLat = fixedLoc.latitude;
          _shopLon = fixedLoc.longitude;
          _shopArea = fixedLoc.approximateArea;
          _shopCity = fixedLoc.city;
          _shopPostalCode = fixedLoc.postalCode;
          _gpsAccuracy = fixedLoc.accuracyMeters;
          _isGpsFixed = true;
          _gpsError = null;

          _shopAreaController.text = (_shopArea != null && _shopArea != 'Current Location') ? _shopArea! : '';
          _shopCityController.text = (_shopCity != null && _shopCity != 'Nearby') ? _shopCity! : '';
          _shopLatController.text = fixedLoc.latitude.toStringAsFixed(6);
          _shopLonController.text = fixedLoc.longitude.toStringAsFixed(6);
        });
      } else if (mounted) {
        final locState = ref.read(locationControllerProvider);
        String customMsg;
        if (locState.status == LocationStateEnum.LOCATION_SERVICES_DISABLED) {
          customMsg = 'Device location is turned off. Turn on GPS in Settings or enter your store location manually.';
        } else if (locState.status == LocationStateEnum.LOCATION_PERMISSION_DENIED ||
            locState.status == LocationStateEnum.LOCATION_PERMISSION_DENIED_FOREVER) {
          customMsg = 'Location permission is needed to auto-detect your physical storefront. You can enter your shop location manually.';
        } else {
          customMsg = 'Could not acquire GPS fix indoors. You can enter your shop location manually below.';
        }
        setState(() {
          _gpsError = customMsg;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _gpsError = 'GPS acquisition error. You can enter your store location manually.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isDetectingGps = false);
      }
    }
  }

  void _saveManualLocation() {
    final area = _shopAreaController.text.trim();
    final city = _shopCityController.text.trim();
    final address = _shopAddressController.text.trim();
    final lat = double.tryParse(_shopLatController.text.trim()) ?? 12.9716;
    final lon = double.tryParse(_shopLonController.text.trim()) ?? 77.5946;

    setState(() {
      _shopArea = area.isNotEmpty ? area : 'Selected Store Area';
      _shopCity = city.isNotEmpty ? city : 'Local City';
      _shopAddress = address.isNotEmpty ? address : null;
      _shopLat = lat;
      _shopLon = lon;
      _locationMode = 'MANUAL';
      _isGpsFixed = false;
      _isEditingLocation = false;
      _gpsError = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Shop location saved! Customers nearby will discover your store.'),
          ],
        ),
        backgroundColor: Color(0xFF0D9488),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openCoordinatesInMap() async {
    if (_shopLat == null || _shopLon == null) return;
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$_shopLat,$_shopLon');
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // If still in manual edit mode, apply inputs before submitting
    if (_isEditingLocation) {
      _saveManualLocation();
    }

    final success = await ref.read(authControllerProvider.notifier).register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _nameController.text.trim(),
          username: _usernameController.text.trim().isEmpty ? null : _usernameController.text.trim(),
          confirmPassword: _confirmPasswordController.text,
          phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          accountType: _accountType,
        );

    if (success && mounted) {
      if (_accountType == 'SHOP_OWNER') {
        // Pre-fill onboarding with real or custom selected shop location
        final uri = Uri(
          path: '/shop/onboarding',
          queryParameters: {
            if (_shopLat != null) 'lat': _shopLat!.toStringAsFixed(6),
            if (_shopLon != null) 'lon': _shopLon!.toStringAsFixed(6),
            if (_shopArea != null && _shopArea!.isNotEmpty && _shopArea != 'Current Location') 'area': _shopArea!,
            if (_shopCity != null && _shopCity!.isNotEmpty && _shopCity != 'Nearby') 'city': _shopCity!,
            if (_shopPostalCode != null && _shopPostalCode!.isNotEmpty) 'postalCode': _shopPostalCode!,
            if (_shopAddress != null && _shopAddress!.isNotEmpty) 'address': _shopAddress!,
          },
        );
        context.go(uri.toString());
      } else {
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isShop = _accountType == 'SHOP_OWNER';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: HomeStockAppBar(
        title: 'Create Account',
        subtitle: isShop ? 'Retailer & physical store registration' : 'New household member profile',
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Animated Dynamic Title
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      key: ValueKey<bool>(isShop),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isShop ? '🏪 Register Your Physical Shop' : '⚡ Get started with HomeStock',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isShop
                                ? 'Set your storefront so nearby customers can discover your catalog & buy essentials.'
                                : 'Manage household pantry inventory and shared shopping lists seamlessly.',
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Account Type Selection Header
                  const Text(
                    'I WANT TO REGISTER AS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMuted,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Dual Choice Cards: User vs Shop
                  Row(
                    children: [
                      // Household User Card
                      Expanded(
                        child: _buildAccountTypeCard(
                          type: 'USER',
                          title: 'Household User',
                          subtitle: 'Pantry & Shopping Lists',
                          icon: Icons.cottage_rounded,
                          isSelected: !isShop,
                          accentColor: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Shop Owner Card
                      Expanded(
                        child: _buildAccountTypeCard(
                          type: 'SHOP_OWNER',
                          title: 'Shop Owner',
                          subtitle: 'Retail Store & Catalog',
                          icon: Icons.storefront_rounded,
                          isSelected: isShop,
                          accentColor: const Color(0xFF0D9488),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Shop Location Section (Live GPS or Custom Edited Location)
                  if (isShop) ...[
                    _buildShopLocationSection(),
                    const SizedBox(height: AppSpacing.md),
                  ] else ...[
                    // Household info pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.kitchen_rounded, size: 16, color: AppColors.primary),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Household accounts track kitchen pantry stock, expiry dates & shared lists.',
                              style: TextStyle(fontSize: 12, color: AppColors.primaryDark, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  if (authState.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Text(
                        authState.errorMessage!,
                        style: const TextStyle(color: AppColors.outOfStockText, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Form Input Card
                  HomeStockCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppTextField(
                          controller: _nameController,
                          label: isShop ? 'Owner / Manager Full Name' : 'Full Name',
                          hint: isShop ? 'e.g. Gowtham (Store Owner)' : 'e.g. Gowtham Sekar',
                          prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Enter your name';
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),

                        AppTextField(
                          controller: _usernameController,
                          label: isShop ? 'Shop Handle / Username (Optional)' : 'Username (Optional)',
                          hint: isShop ? 'e.g. gowtham_mart' : 'e.g. gowtham03',
                          prefixIcon: const Icon(Icons.alternate_email_rounded, size: 20),
                          validator: (val) {
                            if (val != null && val.trim().isNotEmpty && val.trim().length < 3) {
                              return 'Username must be at least 3 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),

                        AppTextField(
                          controller: _emailController,
                          label: isShop ? 'Business / Contact Email' : 'Email Address',
                          hint: 'you@example.com',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Enter your email';
                            if (!val.contains('@')) return 'Enter a valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),

                        AppTextField(
                          controller: _phoneController,
                          label: isShop ? 'Store Phone / Contact Number' : 'Phone Number (Optional)',
                          hint: '+91 98765 43210',
                          keyboardType: TextInputType.phone,
                          prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        AppTextField(
                          controller: _passwordController,
                          label: 'Password',
                          hint: 'At least 6 characters',
                          obscureText: _obscurePassword,
                          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 20,
                              color: AppColors.textMuted,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          validator: (val) {
                            if (val == null || val.length < 6) return 'Password must be at least 6 characters';
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),

                        AppTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirm Password',
                          hint: 'Repeat your password',
                          obscureText: _obscureConfirmPassword,
                          prefixIcon: const Icon(Icons.lock_clock_outlined, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 20,
                              color: AppColors.textMuted,
                            ),
                            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Please confirm your password';
                            if (val != _passwordController.text) return 'Passwords do not match';
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Action Button
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: authState.isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isShop ? const Color(0xFF0D9488) : AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                              elevation: 2,
                            ),
                            child: authState.isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(isShop ? Icons.storefront_rounded : Icons.person_add_rounded, size: 19),
                                      const SizedBox(width: 8),
                                      Text(
                                        isShop ? 'Create Shop Owner Account' : 'Create Household Account',
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account? ', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: const Text(
                          'Sign In',
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountTypeCard({
    required String type,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required Color accentColor,
  }) {
    return InkWell(
      onTap: () => _onSelectAccountType(type),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accentColor : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? accentColor : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
                Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  size: 20,
                  color: isSelected ? accentColor : const Color(0xFFCBD5E1),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? accentColor : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section Header with Option Switcher
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'PHYSICAL STORE LOCATION',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textMuted,
                letterSpacing: 0.8,
              ),
            ),
            // Mode toggle button
            GestureDetector(
              onTap: () {
                setState(() {
                  _isEditingLocation = !_isEditingLocation;
                  if (_isEditingLocation) {
                    _locationMode = 'MANUAL';
                    if (_shopArea != null && _shopAreaController.text.isEmpty) {
                      _shopAreaController.text = _shopArea!;
                    }
                    if (_shopCity != null && _shopCityController.text.isEmpty) {
                      _shopCityController.text = _shopCity!;
                    }
                    if (_shopLat != null && _shopLatController.text.isEmpty) {
                      _shopLatController.text = _shopLat!.toStringAsFixed(6);
                    }
                    if (_shopLon != null && _shopLonController.text.isEmpty) {
                      _shopLonController.text = _shopLon!.toStringAsFixed(6);
                    }
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isEditingLocation ? Icons.my_location_rounded : Icons.edit_location_alt_rounded,
                      size: 13,
                      color: const Color(0xFF0D9488),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isEditingLocation ? 'Use Live GPS' : 'Edit / Enter Manually',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0D9488),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Nearby customers will discover and view products from your shop based on this location.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),

        // Show Editable form if user chose "Edit / Enter Manually"
        if (_isEditingLocation)
          _buildManualLocationEditor()
        else
          _buildShopGpsCard(),
      ],
    );
  }

  Widget _buildManualLocationEditor() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF0D9488).withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: const [
              Icon(Icons.edit_location_rounded, size: 18, color: Color(0xFF0D9488)),
              SizedBox(width: 8),
              Text(
                'Enter Shop Location Details',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Area / Locality
          TextFormField(
            controller: _shopAreaController,
            decoration: const InputDecoration(
              labelText: 'Shop Locality / Area *',
              hintText: 'e.g. Indiranagar, Anna Nagar, T. Nagar',
              prefixIcon: Icon(Icons.store_rounded, size: 18),
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),

          // City
          TextFormField(
            controller: _shopCityController,
            decoration: const InputDecoration(
              labelText: 'City *',
              hintText: 'e.g. Bengaluru, Chennai, Mumbai',
              prefixIcon: Icon(Icons.location_city_rounded, size: 18),
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),

          // Street Address (Optional)
          TextFormField(
            controller: _shopAddressController,
            decoration: const InputDecoration(
              labelText: 'Street Address (Optional)',
              hintText: 'e.g. Shop #45, 100ft Road',
              prefixIcon: Icon(Icons.signpost_rounded, size: 18),
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),

          // Latitude and Longitude
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _shopLatController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Latitude',
                    hintText: '12.9716',
                    prefixIcon: Icon(Icons.explore_outlined, size: 16),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _shopLonController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Longitude',
                    hintText: '77.5946',
                    prefixIcon: Icon(Icons.explore_outlined, size: 16),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _saveManualLocation,
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Save Shop Location'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _autoDetectShopGpsLocation,
                icon: const Icon(Icons.my_location_rounded, size: 16),
                label: const Text('Live GPS'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0D9488),
                  side: const BorderSide(color: Color(0xFF0D9488)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShopGpsCard() {
    // 1. Loading State
    if (_isDetectingGps) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0D9488).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF0D9488).withValues(alpha: 0.25)),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0D9488)),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Detecting live store GPS coordinates...',
                style: TextStyle(fontSize: 12, color: Color(0xFF0F766E), fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    // 2. Fixed / Selected State (Either from GPS or from manual edit)
    if (_shopLat != null && _shopLon != null) {
      final areaDisplay = (_shopArea != null && _shopArea!.isNotEmpty && _shopArea != 'Current Location')
          ? '$_shopArea, ${_shopCity ?? "Local City"}'
          : 'Physical Store Location Set';

      final isGps = _locationMode == 'GPS' && _isGpsFixed;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isGps ? Icons.my_location_rounded : Icons.store_rounded,
                    size: 18,
                    color: const Color(0xFF059669),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              areaDisplay,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF10B981)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_shopLat!.toStringAsFixed(4)}, ${_shopLon!.toStringAsFixed(4)}${_gpsAccuracy != null && isGps ? " (±${_gpsAccuracy!.toStringAsFixed(0)}m)" : ""} • ${isGps ? "Live GPS Fixed" : "Custom Shop Location"}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF047857), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                // Edit button
                IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 18, color: Color(0xFF0D9488)),
                  tooltip: 'Edit Location',
                  onPressed: () {
                    setState(() {
                      _isEditingLocation = true;
                      _shopAreaController.text = _shopArea ?? '';
                      _shopCityController.text = _shopCity ?? '';
                      _shopLatController.text = _shopLat?.toStringAsFixed(6) ?? '';
                      _shopLonController.text = _shopLon?.toStringAsFixed(6) ?? '';
                    });
                  },
                ),
                // Re-detect live GPS button
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF0D9488)),
                  tooltip: 'Re-detect Live GPS',
                  onPressed: _autoDetectShopGpsLocation,
                ),
              ],
            ),
            const Divider(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Nearby customers will discover this shop',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                GestureDetector(
                  onTap: _openCoordinatesInMap,
                  child: const Row(
                    children: [
                      Icon(Icons.map_rounded, size: 12, color: Color(0xFF0D9488)),
                      SizedBox(width: 4),
                      Text(
                        'Verify on Map',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0D9488)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // 3. Fallback / Store-Centric Prompt State
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D9488).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF0D9488).withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _gpsError != null ? Icons.info_outline_rounded : Icons.store_mall_directory_rounded,
                size: 16,
                color: _gpsError != null ? Colors.orange.shade800 : const Color(0xFF0D9488),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _gpsError ?? 'Set your physical shop location so nearby customers can find your store.',
                  style: TextStyle(
                    fontSize: 11,
                    color: _gpsError != null ? Colors.orange.shade900 : const Color(0xFF0F766E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (_gpsError != null &&
              ref.read(locationControllerProvider).status ==
                  LocationStateEnum.LOCATION_SERVICES_DISABLED) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => ref
                    .read(locationControllerProvider.notifier)
                    .openLocationSettings(),
                icon: const Icon(Icons.location_on_outlined, size: 14),
                label: const Text('Turn On Location / GPS in Android Settings'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange.shade900,
                  side: BorderSide(color: Colors.orange.shade400),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  textStyle: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
          if (_gpsError != null &&
              ref.read(locationControllerProvider).status ==
                  LocationStateEnum.LOCATION_PERMISSION_DENIED_FOREVER) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => ref
                    .read(locationControllerProvider.notifier)
                    .openAppSettings(),
                icon: const Icon(Icons.settings_applications_rounded, size: 14),
                label: const Text('Open App Settings to Enable Permission'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange.shade900,
                  side: BorderSide(color: Colors.orange.shade400),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  textStyle: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _autoDetectShopGpsLocation,
                  icon: const Icon(Icons.my_location_rounded, size: 14),
                  label: const Text('Use Live GPS Location'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _isEditingLocation = true;
                    _locationMode = 'MANUAL';
                  });
                },
                icon: const Icon(Icons.edit_location_alt_rounded, size: 14),
                label: const Text('Edit / Enter Manually'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0D9488),
                  side: const BorderSide(color: Color(0xFF0D9488)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
