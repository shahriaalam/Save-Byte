import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/location_constants.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/account_created_dialog.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../domain/auth_state.dart';
import 'auth_controller.dart';
import 'widgets/email_otp_verification_sheet.dart';

class RestaurantRegisterScreen extends ConsumerStatefulWidget {
  const RestaurantRegisterScreen({super.key});

  @override
  ConsumerState<RestaurantRegisterScreen> createState() =>
      _RestaurantRegisterScreenState();
}

class _RestaurantRegisterScreenState
    extends ConsumerState<RestaurantRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Owner details
  final _ownerNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Restaurant details (Section 30)
  final _restaurantNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _cuisineController = TextEditingController();

  String _selectedDivision = 'Dhaka';
  String? _selectedArea = 'Dhanmondi';

  bool _obscurePassword = true;

  @override
  void dispose() {
    _ownerNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _restaurantNameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _cuisineController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedArea == null || _selectedArea!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an Area for your restaurant location.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final email = _emailController.text.trim();

    // 1. Send OTP to email before creating account
    final otp = await ref
        .read(authControllerProvider.notifier)
        .sendRegistrationOtp(email);

    if (!mounted) return;

    // 2. Open OTP verification bottom sheet
    final isVerified = await EmailOtpVerificationSheet.show(
      context: context,
      email: email,
      initialOtp: otp,
    );

    if (!mounted) return;
    if (!isVerified) return; // User closed sheet without verifying

    // 3. Complete restaurant registration
    final success = await ref
        .read(authControllerProvider.notifier)
        .signUpRestaurant(
          email: email,
          password: _passwordController.text,
          fullName: _ownerNameController.text.trim(),
          phone: _phoneController.text.trim(),
          restaurantName: _restaurantNameController.text.trim(),
          description: _descriptionController.text.trim(),
          address: _addressController.text.trim(),
          cuisineType: _cuisineController.text.trim(),
          division: _selectedDivision,
          area: _selectedArea?.trim(),
        );

    if (!mounted) return;

    if (success) {
      await AccountCreatedDialog.show(
        context: context,
        email: email,
        role: AppConstants.roleRestaurant,
      );
    } else {
      final authState = ref.read(authControllerProvider);
      if (authState is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authState.message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is AuthLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Center(
            child: Material(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
              elevation: 0,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    context.go(AppRoutes.login);
                  }
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 15,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ),
          ),
        ),
        centerTitle: true,
        title: const Text(
          'Restaurant Registration',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFDFBF9),
              Color(0xFFF7F8FA),
              Color(0xFFEEF0F5),
            ],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Decorative background ambient orbs
            Positioned(
              top: -40,
              right: -30,
              child: Container(
                width: 230,
                height: 230,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.08),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      blurRadius: 90,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 300,
              left: -60,
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.amber.withValues(alpha: 0.06),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.09),
                      blurRadius: 90,
                      spreadRadius: 15,
                    ),
                  ],
                ),
              ),
            ),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header Badge Pill
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.20,
                                  ),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.05,
                                    ),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.storefront_rounded,
                                    size: 12,
                                    color: AppColors.primary,
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    '✨ Partner with SaveByte',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Heading
                          const Text(
                            'Partner with SaveBite',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Sell delicious meals and eliminate food waste efficiently.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 14),

                          // Moderation Notice Banner (Section 30)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7).withValues(
                                alpha: 0.65,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFFDE68A),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD97706).withValues(
                                      alpha: 0.15,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.verified_user_outlined,
                                    color: Color(0xFFD97706),
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Application Review Policy',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF92400E),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Restaurant accounts are registered with pending status. '
                                        'An administrator reviews each application before offers become visible.',
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: Color(0xFF78350F),
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // High-Focus Elevated Form Card
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0F172A).withValues(
                                    alpha: 0.07,
                                  ),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                  spreadRadius: -3,
                                ),
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.03,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Top Accent Gradient Line
                                  Container(
                                    height: 3,
                                    decoration: const BoxDecoration(
                                      gradient: AppColors.primaryGradient,
                                    ),
                                  ),

                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      18,
                                      16,
                                      18,
                                      20,
                                    ),
                                    child: Theme(
                                      data: Theme.of(context).copyWith(
                                        inputDecorationTheme:
                                            InputDecorationTheme(
                                          filled: true,
                                          fillColor: const Color(0xFFF8FAFC),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 10,
                                          ),
                                          hintStyle: TextStyle(
                                            color: const Color(0xFF94A3B8)
                                                .withValues(alpha: 0.65),
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w400,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: const BorderSide(
                                              color: Color(0xFFE2E8F0),
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: const BorderSide(
                                              color: Color(0xFFE2E8F0),
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: const BorderSide(
                                              color: AppColors.borderFocus,
                                              width: 2,
                                            ),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: const BorderSide(
                                              color: AppColors.error,
                                            ),
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          // Section: Owner Info Header
                                          _buildSectionHeader(
                                            icon: Icons.person_outline_rounded,
                                            title: 'Owner Information',
                                            subtitle:
                                                'Account manager & credentials',
                                          ),
                                          const SizedBox(height: 12),

                                          // Field 0: Owner Full Name
                                          AppTextField(
                                            label: 'Owner Full Name',
                                            hint: 'Rahman Khan',
                                            controller: _ownerNameController,
                                            prefixIcon: const Icon(
                                              Icons.person_outline,
                                              size: 19,
                                              color: Color(0xFF64748B),
                                            ),
                                            validator: (value) =>
                                                AppValidators.validateRequired(
                                                  value,
                                                  'owner name',
                                                ),
                                          ),
                                          const SizedBox(height: 10),

                                          // Field 1: Contact Email
                                          AppTextField(
                                            label: 'Contact Email',
                                            hint: 'contact@restaurant.com',
                                            controller: _emailController,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            prefixIcon: const Icon(
                                              Icons.email_outlined,
                                              size: 19,
                                              color: Color(0xFF64748B),
                                            ),
                                            validator:
                                                AppValidators.validateEmail,
                                          ),
                                          const SizedBox(height: 10),

                                          // Field 2: Phone Number
                                          AppTextField(
                                            label: 'Phone Number',
                                            hint: '017XXXXXXXX',
                                            controller: _phoneController,
                                            keyboardType: TextInputType.phone,
                                            prefixIcon: const Icon(
                                              Icons.phone_outlined,
                                              size: 19,
                                              color: Color(0xFF64748B),
                                            ),
                                            validator: (value) =>
                                                AppValidators.validatePhone(
                                                  value,
                                                  isRequired: true,
                                                ),
                                          ),
                                          const SizedBox(height: 10),

                                          // Field 3: Password
                                          AppTextField(
                                            label: 'Password',
                                            hint: '••••••••',
                                            controller: _passwordController,
                                            obscureText: _obscurePassword,
                                            prefixIcon: const Icon(
                                              Icons.lock_outline,
                                              size: 19,
                                              color: Color(0xFF64748B),
                                            ),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _obscurePassword
                                                    ? Icons.visibility_outlined
                                                    : Icons
                                                        .visibility_off_outlined,
                                                size: 19,
                                                color: const Color(0xFF64748B),
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _obscurePassword =
                                                      !_obscurePassword;
                                                });
                                              },
                                            ),
                                            validator:
                                                AppValidators.validatePassword,
                                          ),
                                          const SizedBox(height: 10),

                                          // Field 4: Confirm Password
                                          AppTextField(
                                            label: 'Confirm Password',
                                            hint: '••••••••',
                                            controller:
                                                _confirmPasswordController,
                                            obscureText: _obscurePassword,
                                            prefixIcon: const Icon(
                                              Icons.lock_outline,
                                              size: 19,
                                              color: Color(0xFF64748B),
                                            ),
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Please confirm your password';
                                              }
                                              if (value !=
                                                  _passwordController.text) {
                                                return 'Passwords do not match';
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 18),

                                          // Section Divider
                                          Container(
                                            height: 1,
                                            color: const Color(0xFFE2E8F0),
                                          ),
                                          const SizedBox(height: 16),

                                          // Section: Restaurant Info Header
                                          _buildSectionHeader(
                                            icon: Icons.storefront_outlined,
                                            title: 'Restaurant Details',
                                            subtitle:
                                                'Business listing & location details',
                                          ),
                                          const SizedBox(height: 12),

                                          // Field 5: Restaurant Name
                                          AppTextField(
                                            label: 'Restaurant Name',
                                            hint: "Rahman's Kitchen",
                                            controller:
                                                _restaurantNameController,
                                            prefixIcon: const Icon(
                                              Icons.storefront_outlined,
                                              size: 19,
                                              color: Color(0xFF64748B),
                                            ),
                                            validator: (value) =>
                                                AppValidators.validateRequired(
                                                  value,
                                                  'restaurant name',
                                                ),
                                          ),
                                          const SizedBox(height: 10),

                                          // Field 6: Description
                                          AppTextField(
                                            label: 'Description',
                                            hint:
                                                'Traditional Bengali cuisine and snacks',
                                            controller: _descriptionController,
                                            maxLines: 2,
                                            validator: (value) =>
                                                AppValidators.validateRequired(
                                                  value,
                                                  'description',
                                                ),
                                          ),
                                          const SizedBox(height: 10),

                                          // Division Selector
                                          DropdownButtonFormField<String>(
                                            initialValue: _selectedDivision,
                                            isExpanded: true,
                                            decoration: const InputDecoration(
                                              labelText: 'Division',
                                              prefixIcon: Icon(Icons.location_city_rounded, size: 19),
                                            ),
                                            items: [
                                              for (final div in LocationConstants.divisions)
                                                DropdownMenuItem(
                                                  value: div,
                                                  child: Text(div, overflow: TextOverflow.ellipsis),
                                                ),
                                            ],
                                            onChanged: (val) {
                                              if (val != null) {
                                                setState(() {
                                                  _selectedDivision = val;
                                                  _selectedArea = LocationConstants.getAreasForDivision(val).first;
                                                });
                                              }
                                            },
                                          ),
                                          const SizedBox(height: 10),

                                          // Area Selector
                                          DropdownButtonFormField<String>(
                                            initialValue: _selectedArea,
                                            isExpanded: true,
                                            decoration: const InputDecoration(
                                              labelText: 'Area',
                                              prefixIcon: Icon(Icons.place_rounded, size: 19),
                                            ),
                                            items: [
                                              for (final area in LocationConstants.getAreasForDivision(_selectedDivision))
                                                DropdownMenuItem(
                                                  value: area,
                                                  child: Text(area, overflow: TextOverflow.ellipsis),
                                                ),
                                            ],
                                            onChanged: (val) {
                                              if (val != null) {
                                                setState(() => _selectedArea = val);
                                              }
                                            },
                                          ),
                                          const SizedBox(height: 10),

                                          // Field 7: Address
                                          AppTextField(
                                            label: 'Address',
                                            hint:
                                                'House 12, Road 4, Dhanmondi, Dhaka',
                                            controller: _addressController,
                                            prefixIcon: const Icon(
                                              Icons.location_on_outlined,
                                              size: 19,
                                              color: Color(0xFF64748B),
                                            ),
                                            validator: (value) =>
                                                AppValidators.validateRequired(
                                                  value,
                                                  'address',
                                                ),
                                          ),
                                          const SizedBox(height: 10),

                                          // Field 8: Cuisine Type
                                          AppTextField(
                                            label: 'Cuisine Type',
                                            hint:
                                                'Bengali / Fast Food / Bakery',
                                            controller: _cuisineController,
                                            prefixIcon: const Icon(
                                              Icons.restaurant_outlined,
                                              size: 19,
                                              color: Color(0xFF64748B),
                                            ),
                                            validator: (value) =>
                                                AppValidators.validateRequired(
                                                  value,
                                                  'cuisine type',
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Submit Button
                          PrimaryButton(
                            text: 'Create Restaurant Account',
                            isLoading: isLoading,
                            onPressed: _handleRegister,
                          ),
                          const SizedBox(height: 12),

                          // Back to Login Link
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'Already registered?',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                              ),
                              TextButton(
                                onPressed: () => context.go(AppRoutes.login),
                                child: const Text(
                                  'Log In',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 17,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

