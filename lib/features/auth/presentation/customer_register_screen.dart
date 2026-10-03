import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/account_created_dialog.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../domain/auth_state.dart';
import 'auth_controller.dart';
import 'widgets/email_otp_verification_sheet.dart';

class CustomerRegisterScreen extends ConsumerStatefulWidget {
  const CustomerRegisterScreen({super.key});

  @override
  ConsumerState<CustomerRegisterScreen> createState() =>
      _CustomerRegisterScreenState();
}

class _CustomerRegisterScreenState
    extends ConsumerState<CustomerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedGender;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

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

    // 3. Complete customer account creation
    final success = await ref
        .read(authControllerProvider.notifier)
        .signUpCustomer(
          email: email,
          password: _passwordController.text,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          gender: _selectedGender,
          phone: _phoneController.text.trim(),
        );

    if (!mounted) return;

    if (success) {
      await AccountCreatedDialog.show(
        context: context,
        email: email,
        role: AppConstants.roleCustomer,
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
        centerTitle: true,
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
        title: const Text(
          'Customer Sign Up',
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
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.08),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.14),
                      blurRadius: 90,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 260,
              left: -60,
              child: Container(
                width: 180,
                height: 180,
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
                  padding: const EdgeInsets.fromLTRB(20, kToolbarHeight + 6, 20, 20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
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
                                vertical: 3,
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
                                    Icons.auto_awesome_rounded,
                                    size: 11,
                                    color: AppColors.primary,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Join SaveByte • Eat Fresh',
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
                          const SizedBox(height: 6),

                          Text(
                            'Create Your Customer Account',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Discover fresh, discounted surplus food near you.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),

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
                                      18,
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
                                          // First Name & Last Name in Row
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: AppTextField(
                                                  label: 'First Name',
                                                  hint: 'Rahim',
                                                  controller:
                                                      _firstNameController,
                                                  prefixIcon: const Icon(
                                                    Icons.person_outline,
                                                    size: 19,
                                                  ),
                                                  validator: (value) =>
                                                      AppValidators
                                                          .validateRequired(
                                                    value,
                                                    'first name',
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: AppTextField(
                                                  label: 'Last Name',
                                                  hint: 'Ahmed',
                                                  controller:
                                                      _lastNameController,
                                                  prefixIcon: const Icon(
                                                    Icons.person_outline,
                                                    size: 19,
                                                  ),
                                                  validator: (value) =>
                                                      AppValidators
                                                          .validateRequired(
                                                    value,
                                                    'last name',
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),

                                          // Gender Selector
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Gender',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                              const SizedBox(height: 6),
                                              DropdownButtonFormField<String>(
                                                initialValue: _selectedGender,
                                                hint: Text(
                                                  'Select your gender',
                                                  style: TextStyle(
                                                    color: const Color(
                                                      0xFF94A3B8,
                                                    ).withValues(alpha: 0.65),
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                                decoration: InputDecoration(
                                                  prefixIcon: const Icon(
                                                    Icons.wc_outlined,
                                                    size: 19,
                                                    color: Color(0xFF64748B),
                                                  ),
                                                  filled: true,
                                                  fillColor:
                                                      const Color(0xFFF8FAFC),
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 14,
                                                    vertical: 10,
                                                  ),
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(12),
                                                    borderSide: const BorderSide(
                                                      color: Color(0xFFE2E8F0),
                                                    ),
                                                  ),
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(12),
                                                    borderSide: const BorderSide(
                                                      color: Color(0xFFE2E8F0),
                                                    ),
                                                  ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
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
                                                dropdownColor: Colors.white,
                                            icon: const Icon(
                                              Icons.keyboard_arrow_down_rounded,
                                              size: 20,
                                              color: Color(0xFF64748B),
                                            ),
                                            items: const [
                                              DropdownMenuItem(
                                                value: 'Male',
                                                child: Text('Male'),
                                              ),
                                              DropdownMenuItem(
                                                value: 'Female',
                                                child: Text('Female'),
                                              ),
                                              DropdownMenuItem(
                                                value: 'Other',
                                                child: Text('Other'),
                                              ),
                                              DropdownMenuItem(
                                                value: 'Prefer not to say',
                                                child:
                                                    Text('Prefer not to say'),
                                              ),
                                            ],
                                            onChanged: (val) {
                                              setState(() {
                                                _selectedGender = val;
                                              });
                                            },
                                            validator: (val) => val == null
                                                ? 'Please select your gender'
                                                : null,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),

                                          // Email Address with strict format validation
                                          AppTextField(
                                            label: 'Email',
                                            hint: 'name@example.com',
                                            controller: _emailController,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            prefixIcon: const Icon(
                                              Icons.email_outlined,
                                              size: 19,
                                            ),
                                            validator:
                                                AppValidators.validateEmail,
                                          ),
                                          const SizedBox(height: 10),

                                          // Phone Number with strict validation
                                          AppTextField(
                                            label: 'Phone Number',
                                            hint: '017XXXXXXXX',
                                            controller: _phoneController,
                                            keyboardType: TextInputType.phone,
                                            prefixIcon: const Icon(
                                              Icons.phone_outlined,
                                              size: 19,
                                            ),
                                            validator: (value) =>
                                                AppValidators.validatePhone(
                                              value,
                                              isRequired: true,
                                            ),
                                          ),
                                          const SizedBox(height: 10),

                                          // Password
                                          AppTextField(
                                            label: 'Password',
                                            hint: '••••••••',
                                            controller: _passwordController,
                                            obscureText: _obscurePassword,
                                            prefixIcon: const Icon(
                                              Icons.lock_outline,
                                              size: 19,
                                            ),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _obscurePassword
                                                    ? Icons.visibility_outlined
                                                    : Icons
                                                        .visibility_off_outlined,
                                                size: 19,
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

                                          // Confirm Password
                                          AppTextField(
                                            label: 'Confirm Password',
                                            hint: '••••••••',
                                            controller:
                                                _confirmPasswordController,
                                            obscureText: _obscurePassword,
                                            prefixIcon: const Icon(
                                              Icons.lock_outline,
                                              size: 19,
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
                                          const SizedBox(height: 14),

                                          // Submit Button
                                          PrimaryButton(
                                            text: 'Create Account',
                                            isLoading: isLoading,
                                            onPressed: _handleRegister,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Already have an account link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account?',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  foregroundColor: AppColors.primary,
                                ),
                                onPressed: () => context.go(AppRoutes.login),
                                child: const Text(
                                  'Log In',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
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
            ),
          ],
        ),
      ),
    );
  }
}
