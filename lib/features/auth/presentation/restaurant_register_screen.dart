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

    final email = _emailController.text.trim();
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
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Restaurant Registration')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Partner with SaveBite',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sell surplus food and eliminate food waste efficiently.',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),

                    // Moderation Notice Banner (Section 30)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.warning,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Restaurant accounts are registered with pending status. '
                              'An administrator reviews each application before offers become visible.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppColors.textPrimary,
                                    height: 1.4,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section: Owner Info
                    Text(
                      'Owner Information',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    AppTextField(
                      label: 'Owner Full Name',
                      hint: 'Rahman Khan',
                      controller: _ownerNameController,
                      prefixIcon: const Icon(Icons.person_outline, size: 20),
                      validator: (value) =>
                          AppValidators.validateRequired(value, 'owner name'),
                    ),
                    const SizedBox(height: 12),

                    AppTextField(
                      label: 'Contact Email',
                      hint: 'contact@restaurant.com',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(Icons.email_outlined, size: 20),
                      validator: AppValidators.validateEmail,
                    ),
                    const SizedBox(height: 12),

                    AppTextField(
                      label: 'Phone Number',
                      hint: '017XXXXXXXX',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                      validator: (value) =>
                          AppValidators.validatePhone(value, isRequired: true),
                    ),
                    const SizedBox(height: 12),

                    AppTextField(
                      label: 'Password',
                      hint: '••••••••',
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      validator: AppValidators.validatePassword,
                    ),
                    const SizedBox(height: 12),

                    AppTextField(
                      label: 'Confirm Password',
                      hint: '••••••••',
                      controller: _confirmPasswordController,
                      obscureText: _obscurePassword,
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Section: Restaurant Info
                    Text(
                      'Restaurant Details',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    AppTextField(
                      label: 'Restaurant Name',
                      hint: "Rahman's Kitchen",
                      controller: _restaurantNameController,
                      prefixIcon: const Icon(
                        Icons.storefront_outlined,
                        size: 20,
                      ),
                      validator: (value) =>
                          AppValidators.validateRequired(value, 'restaurant name'),
                    ),
                    const SizedBox(height: 12),

                    AppTextField(
                      label: 'Description',
                      hint: 'Traditional Bengali cuisine and snacks',
                      controller: _descriptionController,
                      maxLines: 2,
                      validator: (value) =>
                          AppValidators.validateRequired(value, 'description'),
                    ),
                    const SizedBox(height: 12),

                    AppTextField(
                      label: 'Address',
                      hint: 'House 12, Road 4, Dhanmondi, Dhaka',
                      controller: _addressController,
                      prefixIcon: const Icon(
                        Icons.location_on_outlined,
                        size: 20,
                      ),
                      validator: (value) =>
                          AppValidators.validateRequired(value, 'address'),
                    ),
                    const SizedBox(height: 12),

                    AppTextField(
                      label: 'Cuisine Type',
                      hint: 'Bengali / Fast Food / Bakery',
                      controller: _cuisineController,
                      prefixIcon: const Icon(
                        Icons.restaurant_outlined,
                        size: 20,
                      ),
                      validator: (value) =>
                          AppValidators.validateRequired(value, 'cuisine type'),
                    ),
                    const SizedBox(height: 28),

                    // Submit Button
                    PrimaryButton(
                      text: 'Create Restaurant Account',
                      isLoading: isLoading,
                      onPressed: _handleRegister,
                    ),
                    const SizedBox(height: 16),

                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Already registered?',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        TextButton(
                          onPressed: () => context.go(AppRoutes.login),
                          child: const Text('Log In'),
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
    );
  }
}
