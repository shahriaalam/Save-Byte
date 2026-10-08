import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../router/app_routes.dart';
import 'app_logo.dart';
import 'primary_button.dart';

/// Modal dialog shown in the middle of the screen when any account is created successfully.
/// Displays the inverted brand logo and allows the user to proceed directly to the login page.
class AccountCreatedDialog extends StatelessWidget {
  const AccountCreatedDialog({
    required this.email,
    this.role = AppConstants.roleCustomer,
    super.key,
  });

  final String email;
  final String role;

  /// Helper to display the modal dialog in the middle of the screen.
  static Future<void> show({
    required BuildContext context,
    required String email,
    String role = AppConstants.roleCustomer,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AccountCreatedDialog(
        email: email,
        role: role,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRestaurant = role == AppConstants.roleRestaurant;

    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 12,
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Inverted Current Brand Logo
                const AppLogoIcon(
                  size: 80,
                  isInverted: true,
                ),
                const SizedBox(height: 20),

                // Success Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Success',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Heading
                Text(
                  'Account Created!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),

                // Description
                Text(
                  isRestaurant
                      ? 'Your restaurant partner account has been created. Please log in to manage your profile and track application verification.'
                      : 'Your customer account has been created successfully. Log in with your email and password to start exploring food offers!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Email confirmation chip
                if (email.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.email_outlined,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            email,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 26),

                // CTA Button to proceed to Login
                PrimaryButton(
                  text: 'Go to Login',
                  icon: const Icon(Icons.login_rounded, size: 20),
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.go(AppRoutes.login);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
