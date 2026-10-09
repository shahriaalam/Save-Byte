import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/colors/account_colors.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/double_pull_reload.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../auth/domain/user_profile.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/widgets/email_otp_verification_sheet.dart';
import '../location/widgets/customer_location_sheet.dart';
import '../shell/customer_shell_screen.dart';
import '../../shared/data/admin_financial_controller.dart';
import '../../shared/presentation/payment_portal_sheet.dart';
import 'data/customer_favorites_controller.dart';
import 'data/customer_membership_controller.dart';
import '../orders/presentation/customer_orders_sheet.dart';
import 'widgets/change_avatar_sheet.dart';

/// Customer Account management screen (Section 26 & Account update).
/// Replaces the legacy simple profile screen with the full-featured Account UI
/// matching the brand design with:
/// - Warm peach gradient profile header with View Profile action
/// - Super Saver membership banner & subscription details
/// - 7 Quick Action tiles (Orders, Addresses, Favourites, Vouchers, Rewards, Help Center, Contact Us)
/// - Account options list (Super Saver, Refund Policy, Privacy Policy, About, Log Out, Delete account)
class CustomerProfileScreen extends ConsumerStatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  ConsumerState<CustomerProfileScreen> createState() =>
      _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends ConsumerState<CustomerProfileScreen> {
  // ==========================================
  // PROFILE & AVATAR EDITING ACTIONS
  // ==========================================

  Future<void> _showChangeAvatarModal(
      BuildContext context, UserProfile profile) async {
    ref.read(customerNavbarVisibleProvider.notifier).hide();
    final targetContext = rootNavigatorKey.currentContext ?? context;
    try {
      await showModalBottomSheet<void>(
        context: targetContext,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (bottomSheetContext) => ChangeAvatarSheet(profile: profile),
      );
    } finally {
      ref.read(customerNavbarVisibleProvider.notifier).show();
    }
  }

  Future<void> _showViewProfileSheet(
      BuildContext context, UserProfile profile) async {
    ref.read(customerNavbarVisibleProvider.notifier).hide();
    final targetContext = rootNavigatorKey.currentContext ?? context;

    String initialFirstName = profile.firstName ?? '';
    String initialLastName = profile.lastName ?? '';
    if (initialFirstName.isEmpty &&
        initialLastName.isEmpty &&
        profile.fullName != null) {
      final parts = profile.fullName!.trim().split(' ');
      initialFirstName = parts.firstOrNull ?? '';
      if (parts.length > 1) {
        initialLastName = parts.sublist(1).join(' ');
      }
    }

    final firstNameController = TextEditingController(text: initialFirstName);
    final lastNameController = TextEditingController(text: initialLastName);
    final phoneController = TextEditingController(text: profile.phone ?? '');
    final addressController =
        TextEditingController(text: profile.address ?? '');
    final cityController =
        TextEditingController(text: profile.city ?? 'Dhaka');
    final dobController =
        TextEditingController(text: profile.dateOfBirth ?? '');
    String selectedGender = profile.gender ?? 'Male';
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    try {
      await showModalBottomSheet<void>(
        context: targetContext,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (bottomSheetContext) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              return SafeArea(
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.90,
                  ),
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 20,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'My Profile',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () =>
                                    Navigator.pop(bottomSheetContext),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Avatar Preview & Change Photo
                          Center(
                            child: Column(
                              children: [
                                UserAvatar(
                                  avatarUrl: profile.avatarUrl,
                                  name:
                                      '${firstNameController.text.trim()} ${lastNameController.text.trim()}'
                                              .trim()
                                              .isNotEmpty
                                          ? '${firstNameController.text.trim()} ${lastNameController.text.trim()}'
                                              .trim()
                                          : profile.fullName,
                                  radius: 40,
                                  showEditBadge: true,
                                  onTapEdit: () {
                                    Navigator.pop(bottomSheetContext);
                                    _showChangeAvatarModal(context, profile);
                                  },
                                ),
                                const SizedBox(height: 6),
                                TextButton.icon(
                                  onPressed: () {
                                    Navigator.pop(bottomSheetContext);
                                    _showChangeAvatarModal(context, profile);
                                  },
                                  icon: const Icon(
                                    Icons.photo_camera_outlined,
                                    size: 15,
                                    color: AppColors.primary,
                                  ),
                                  label: const Text(
                                    'Change Profile Picture',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Editable Profile Fields
                          TextFormField(
                            controller: firstNameController,
                            decoration: const InputDecoration(
                              labelText: 'First Name *',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'First name is required'
                                : null,
                          ),
                          const SizedBox(height: 14),

                          TextFormField(
                            controller: lastNameController,
                            decoration: const InputDecoration(
                              labelText: 'Last Name',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Email (Read-Only)
                          TextFormField(
                            initialValue: profile.email,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: Icon(Icons.email_outlined),
                              suffixIcon: Icon(Icons.lock_outline_rounded,
                                  size: 16, color: AppColors.textMuted),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Gender Dropdown
                          DropdownButtonFormField<String>(
                            initialValue: selectedGender,
                            decoration: const InputDecoration(
                              labelText: 'Gender',
                              prefixIcon: Icon(Icons.wc_outlined),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'Male', child: Text('Male')),
                              DropdownMenuItem(
                                  value: 'Female', child: Text('Female')),
                              DropdownMenuItem(
                                  value: 'Other', child: Text('Other')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setSheetState(() => selectedGender = val);
                              }
                            },
                          ),
                          const SizedBox(height: 14),

                          // Date of Birth Field
                          TextFormField(
                            controller: dobController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Date of Birth (YYYY-MM-DD)',
                              prefixIcon: Icon(Icons.cake_outlined),
                              suffixIcon:
                                  Icon(Icons.calendar_today_outlined, size: 18),
                            ),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime(2000, 1, 1),
                                firstDate: DateTime(1940),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                final formatted =
                                    '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                                setSheetState(() {
                                  dobController.text = formatted;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 14),

                          // Phone field
                          TextFormField(
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Address field
                          TextFormField(
                            controller: addressController,
                            decoration: const InputDecoration(
                              labelText: 'Address',
                              hintText: 'House / Road / Area',
                              prefixIcon: Icon(Icons.home_outlined),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // City field
                          TextFormField(
                            controller: cityController,
                            decoration: const InputDecoration(
                              labelText: 'City / District',
                              hintText: 'e.g. Dhaka',
                              prefixIcon: Icon(Icons.location_city_outlined),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Save Changes Button
                          PrimaryButton(
                            text: 'Save Changes',
                            isLoading: isSaving,
                            onPressed: isSaving
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) {
                                      return;
                                    }
                                    setSheetState(() => isSaving = true);

                                    final fName =
                                        firstNameController.text.trim();
                                    final lName =
                                        lastNameController.text.trim();
                                    final computedFullName =
                                        '$fName $lName'.trim();

                                    final success = await ref
                                        .read(authControllerProvider.notifier)
                                        .updateProfile(
                                          id: profile.id,
                                          firstName: fName,
                                          lastName: lName,
                                          fullName: computedFullName,
                                          gender: selectedGender,
                                          phone: phoneController.text
                                                  .trim()
                                                  .isEmpty
                                              ? null
                                              : phoneController.text.trim(),
                                          address: addressController.text
                                                  .trim()
                                                  .isEmpty
                                              ? null
                                              : addressController.text.trim(),
                                          city: cityController.text
                                                  .trim()
                                                  .isEmpty
                                              ? null
                                              : cityController.text.trim(),
                                          dateOfBirth: dobController.text
                                                  .trim()
                                                  .isEmpty
                                              ? null
                                              : dobController.text.trim(),
                                          avatarUrl: profile.avatarUrl,
                                        );

                                    if (context.mounted) {
                                      setSheetState(() => isSaving = false);
                                      if (success) {
                                        Navigator.pop(bottomSheetContext);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Profile updated successfully!',
                                            ),
                                            backgroundColor: AppColors.success,
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Failed to update profile.'),
                                            backgroundColor: AppColors.error,
                                          ),
                                        );
                                      }
                                    }
                                  },
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: TextButton.icon(
                              onPressed: () {
                                Navigator.pop(bottomSheetContext);
                                _confirmDeleteAccount(context);
                              },
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 16,
                                color: AppColors.error,
                              ),
                              label: const Text(
                                'Delete Account',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    } finally {
      ref.read(customerNavbarVisibleProvider.notifier).show();
    }
  }

  // ==========================================
  // SUPER SAVER MEMBERSHIP MODAL
  // ==========================================

  void _showSuperSaverModal(BuildContext context) {
    ref.read(customerNavbarVisibleProvider.notifier).hide();
    final targetContext = rootNavigatorKey.currentContext ?? context;
    showModalBottomSheet<void>(
      context: targetContext,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEDEC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: Color(0xFFE11D48),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Super Saver Club',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        'Unlock VIP Membership Perks',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildPerkRow(Icons.local_shipping_outlined,
                  'Free Delivery on Orders > ৳200', 'Valid across Dhaka city'),
              _buildPerkRow(
                  Icons.discount_outlined,
                  'Extra 10% Off Food Bags',
                  'Stackable with restaurant discounts'),
              _buildPerkRow(Icons.bolt_rounded, '15-Min Early Deal Drop Access',
                  'Grab limited hot meals before anyone else'),
              _buildPerkRow(Icons.verified_rounded, 'Exclusive Super Saver Badge',
                  'Recognized on your customer profile'),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF1F2), Color(0xFFFFE4E6)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFFCCD3)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '৳99 / month',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFE11D48),
                          ),
                        ),
                        Text(
                          'Cancel anytime, no commitment',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'SAVE 60%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFBE123C),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE11D48),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final userProfile =
                        ref.read(currentUserProfileProvider);
                    final customerName =
                        userProfile?.fullName?.trim().isNotEmpty == true
                            ? userProfile!.fullName!
                            : 'Valued Customer';

                    final result = await showPaymentPortalSheet(
                      context: context,
                      title: 'Super Saver VIP Membership',
                      subtitle: '1 Month (30 Days) • Auto-Renews',
                      amount: 99.0,
                      customerOrBusinessName: customerName,
                      perkHighlights: const [
                        'Free Delivery on Orders > ৳200',
                        'Extra 10% Off Food Bags',
                        '15-Min Early Deal Drop Access',
                        'Exclusive Super Saver VIP Badge',
                      ],
                      itemType: 'customer_membership',
                    );

                    if (result != null && result.isSuccess) {
                      await ref
                          .read(customerMembershipProvider.notifier)
                          .activateMembership(amount: 99.0);

                      ref
                          .read(adminFinancialProvider.notifier)
                          .recordSubscriptionPayment(
                            payerName: '$customerName (Consumer)',
                            payerType: 'customer',
                            planName: 'Super Saver VIP Club',
                            amount: 99.0,
                            paymentGateway: result.gateway ?? 'bKash',
                            transactionId:
                                result.transactionId ?? 'TXN-SS-891',
                          );

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '🎉 Payment Approved via ${result.gateway}! Welcome to Super Saver VIP! ✨',
                            ),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Payment was not completed. Super Saver perks remain locked.',
                            ),
                            backgroundColor: Color(0xFF64748B),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text(
                    'Join Super Saver Now (৳99/mo)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      ref.read(customerNavbarVisibleProvider.notifier).show();
    });
  }

  void _showActiveMembershipSheet(
      BuildContext context, CustomerMembershipState membership) {
    ref.read(customerNavbarVisibleProvider.notifier).hide();
    final targetContext = rootNavigatorKey.currentContext ?? context;
    showModalBottomSheet<void>(
      context: targetContext,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE11D48), Color(0xFFBE123C)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stars_rounded,
                        color: Colors.white, size: 36),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Super Saver VIP Member',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            membership.expiresAt != null
                                ? 'Renews on ${membership.expiresAt!.day}/${membership.expiresAt!.month}/${membership.expiresAt!.year}'
                                : '30-Day Auto-Renewing Membership',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'ACTIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'YOUR ACTIVE VIP PRIVILEGES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              _buildPerkRow(Icons.local_shipping_outlined,
                  'Free Delivery on Orders > ৳200', 'Active across Dhaka city'),
              _buildPerkRow(Icons.discount_outlined,
                  'Extra 10% Off Food Bags', 'Stacked automatically at checkout'),
              _buildPerkRow(Icons.bolt_rounded,
                  '15-Min Priority Early Deal Drops', 'Notifications enabled'),
              _buildPerkRow(Icons.verified_rounded,
                  'Exclusive Super Saver Badge', 'Displayed on your public profile'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE11D48),
                    side: const BorderSide(color: Color(0xFFFFCCD3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final confirm = await ConfirmDialog.show(
                      context,
                      title: 'Cancel Super Saver Membership?',
                      message:
                          'Are you sure you want to cancel your VIP membership? You will lose free delivery and 10% discounts at the end of the current billing period.',
                      confirmLabel: 'Cancel Membership',
                    );
                    if (confirm == true) {
                      await ref
                          .read(customerMembershipProvider.notifier)
                          .cancelMembership();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Super Saver membership canceled.'),
                            backgroundColor: Color(0xFF64748B),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text(
                    'Cancel Membership',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      ref.read(customerNavbarVisibleProvider.notifier).show();
    });
  }

  static Widget _buildPerkRow(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFFE11D48)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ACTION TILES MODAL HANDLERS
  // ==========================================

  void _showAddressesModal(BuildContext context) {
    CustomerLocationSheet.show(context);
  }


  void _showFavouritesModal(BuildContext context) {
    ref.read(customerNavbarVisibleProvider.notifier).hide();
    final targetContext = rootNavigatorKey.currentContext ?? context;
    showModalBottomSheet<void>(
      context: targetContext,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const _CustomerFavoritesModalSheet(),
    ).whenComplete(() {
      ref.read(customerNavbarVisibleProvider.notifier).show();
    });
  }

  void _showVouchersModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Available Vouchers',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              _buildVoucherTile(
                  context, 'SAVEBITE50', '৳50 OFF on orders above ৳200', 'Expires in 3 days'),
              _buildVoucherTile(
                  context, 'SAVE20', '20% OFF food bags', 'Expires in 7 days'),
              _buildVoucherTile(
                  context, 'SUPERSAVER', 'Free delivery anywhere in Dhaka', 'Super Saver Exclusive'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoucherTile(
      BuildContext context, String code, String discount, String expiry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCCD3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                code,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFE11D48),
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                discount,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                expiry,
                style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
              ),
            ],
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              foregroundColor: Colors.white,
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Voucher "$code" copied to clipboard!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  void _showRewardsModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'SaveBite Rewards',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE11D48), Color(0xFFBE123C)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '280 Reward Points',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Tier: Silver Member (7 orders placed)',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                    Icon(Icons.military_tech_rounded,
                        color: Colors.white, size: 36),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Tier Benefits:',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '✨ 5% bonus discount on orders above ৳500.\n🎟️ Earn 10 points for every completed order.',
                style: TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelpSupportModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Help & Support',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Instant assistance, hotlines & FAQs for your orders',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 16),

                // Support channels header
                const Text(
                  'CONTACT CHANNELS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEDEC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.phone_in_talk_rounded,
                        color: Color(0xFFE11D48), size: 20),
                  ),
                  title: const Text('Customer Hotline',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  subtitle: const Text('+880 1700-112233 (9 AM - 11:30 PM)'),
                  trailing: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF94A3B8)),
                  onTap: () {
                    Clipboard.setData(const ClipboardData(text: '+8801700112233'));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Hotline copied to clipboard.')),
                    );
                  },
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.chat_bubble_outline_rounded,
                        color: Color(0xFF10B981), size: 20),
                  ),
                  title: const Text('WhatsApp Chat Support',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  subtitle: const Text('Instant support for active orders'),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening WhatsApp Support...')),
                    );
                  },
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.email_outlined,
                        color: Color(0xFF3B82F6), size: 20),
                  ),
                  title: const Text('Email Support',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  subtitle: const Text('support@savebite.com'),
                  trailing: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF94A3B8)),
                  onTap: () {
                    Clipboard.setData(
                        const ClipboardData(text: 'support@savebite.com'));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Email copied to clipboard.')),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // FAQs header
                const Text(
                  'FREQUENTLY ASKED QUESTIONS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),
                _buildFaqItem('How do I collect my order?',
                    'Show your 4-digit pickup PIN in the app to the restaurant cashier during the scheduled pickup window.'),
                _buildFaqItem('What is a Mystery Bag?',
                    'A surprise assortment of fresh meals, pastries, or groceries packed by the restaurant at 50-70% off!'),
                _buildFaqItem('Can I cancel an order?',
                    'Cancellations are accepted up to 30 minutes before the pickup window begins.'),
                _buildFaqItem('Are the meals safe to eat?',
                    'Yes, SaveBite only partners with certified restaurants adhering strictly to hygiene and food safety guidelines.'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFFF1F5F9)),
        ),
        backgroundColor: const Color(0xFFF8FAFC),
        collapsedBackgroundColor: const Color(0xFFF8FAFC),
        title: Text(
          question,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Text(
              answer,
              style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Privacy Policy',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '• Data Protection: SaveBite encrypts all customer identifiers and transactions.\n\n'
                '• Location Privacy: Your GPS location is solely utilized to display nearby food offers within your delivery zone.\n\n'
                '• No Third-Party Selling: We never sell or transfer your personal contact data to marketing agencies.\n\n'
                '• Account Deletion: You can request complete profile and transaction data erasure at any time.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF475569),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE11D48),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Got It'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  void _confirmLogout(BuildContext context) {
    showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Log Out',
              style: TextStyle(fontWeight: FontWeight.w800)),
          content:
              const Text('Are you sure you want to log out of SaveBite?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel',
                  style: TextStyle(color: Color(0xFF64748B))),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                await ref.read(authControllerProvider.notifier).signOut();
                if (context.mounted) {
                  context.go(AppRoutes.login);
                }
              },
              child: const Text('Log Out',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: AppColors.error, size: 24),
              SizedBox(width: 8),
              Text(
                'Delete Account?',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to permanently delete your SaveBite account?',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              SizedBox(height: 10),
              Text(
                '• All your personal profile and address data will be erased.\n'
                '• Any active food reservations will be cancelled.\n'
                '• Saved vouchers, favourite spots, and Reward Points will be permanently lost.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  height: 1.45,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'An OTP verification code will be sent to your registered email to authorize permanent deletion.\nThis action cannot be undone.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel',
                  style: TextStyle(color: Color(0xFF64748B))),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);

                final profile = ref.read(currentUserProfileProvider);
                final email = profile?.email.trim() ?? '';
                if (email.isEmpty) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Unable to find account email address.'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                  return;
                }

                // 1. Send OTP to customer's email
                final otp = await ref
                    .read(authControllerProvider.notifier)
                    .sendDeletionOtp(email);

                if (!context.mounted) return;

                // 2. Open OTP verification bottom sheet for deletion
                final isVerified = await EmailOtpVerificationSheet.show(
                  context: context,
                  email: email,
                  initialOtp: otp,
                  purpose: OtpPurpose.deletion,
                );

                if (!context.mounted) return;
                if (!isVerified) return; // Verification was cancelled or failed

                // 3. Delete account after verified OTP
                final success = await ref
                    .read(authControllerProvider.notifier)
                    .deleteAccount();

                if (context.mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Your account has been deleted.'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    try {
                      context.go(AppRoutes.login);
                    } catch (_) {}
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Failed to delete account. Please try again.'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              child: const Text('Delete Account',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // ABOUT SAVEBITE MODAL (App Info & Version)
  // ==========================================

  void _showAboutModal(BuildContext context) {
    ref.read(customerNavbarVisibleProvider.notifier).hide();
    final targetContext = rootNavigatorKey.currentContext ?? context;
    showModalBottomSheet<void>(
      context: targetContext,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.88,
            ),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Drag Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Brand Hero Header
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.30),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.eco_rounded,
                              color: Colors.white,
                              size: 34,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'SaveBite',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Smart Food & Deals Platform',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),

                        // Version & Release Tag Chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified_rounded,
                                size: 14,
                                color: Color(0xFF15803D),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Version 1.1.0 (Build 110)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Mission & About Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline_rounded,
                              size: 18,
                              color: Color(0xFFE11D48),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'About SaveBite',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'SaveBite is a premier food and discount dining platform in Bangladesh. Every single day, freshly cooked meals and quality baked items remain unsold. SaveBite connects smart customers with trusted restaurants, cafes, and bakeries across Dhaka, making high-quality meals accessible at 50% to 70% discounts before closing time.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF475569),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Company Information & Credits
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SaveBite Ltd',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Dhaka, Bangladesh',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Email: contactshahria@gmail.com, Helpline: 16600',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '© 2026 SaveBite Ltd. All rights reserved',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Developed by B. M. Shahria Alam',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Close Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).whenComplete(() {
      ref.read(customerNavbarVisibleProvider.notifier).show();
    });
  }



  // ==========================================
  // MAIN BUILD METHOD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentUserProfileProvider);
    final membership = ref.watch(customerMembershipProvider);

    final displayName = profile?.fullName?.trim().isNotEmpty == true
        ? profile!.fullName!
        : 'Shahria Alam';
    final email = profile?.email ?? 'bmshahria02@gmail.com';

    return Scaffold(
      backgroundColor: AccountColors.background,
      body: DoublePullReload(
        onReload: () async {
          await ref.read(currentUserProfileProvider.notifier).refreshProfile();
        },
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 110),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // 1. WARM PEACH GRADIENT HEADER (As in screenshot)
            // ==========================================
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFECE5), // Warm soft peach
                    Color(0xFFFFF7F2),
                    Colors.white,
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Row(
                    children: [
                      // Circular Profile Avatar with Tap Action
                      GestureDetector(
                        onTap: () {
                          if (profile != null) {
                            _showChangeAvatarModal(context, profile);
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: UserAvatar(
                            avatarUrl: profile?.avatarUrl,
                            name: displayName,
                            radius: 36,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // User Info & "View Profile" link
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E293B),
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              email,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () {
                                if (profile != null) {
                                  _showViewProfileSheet(context, profile);
                                }
                              },
                              child: const Text(
                                'View Profile',
                                style: TextStyle(
                                  color: Color(0xFFE11D48),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ==========================================
            // 2. BECOME A SUPER SAVER CARD
            // ==========================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              child: InkWell(
                onTap: () {
                  if (membership.isSuperSaver) {
                    _showActiveMembershipSheet(context, membership);
                  } else {
                    _showSuperSaverModal(context);
                  }
                },
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0).withValues(alpha: 0.8),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.025),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (membership.isSuperSaver) ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE11D48),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.stars_rounded,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              membership.isSuperSaver
                                  ? 'Super Saver VIP Active ⭐'
                                  : 'Become a Super Saver',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: membership.isSuperSaver
                                    ? const Color(0xFF9F1239)
                                    : const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              membership.isSuperSaver
                                  ? 'Active Member • Free delivery & perks unlocked'
                                  : 'Unlock exclusive benefits',
                              style: TextStyle(
                                fontSize: 12,
                                color: membership.isSuperSaver
                                    ? const Color(0xFFBE123C)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildSuperSaverBadge(isActive: membership.isSuperSaver),
                  ],
                ),
              ),
            ),
          ),
          // ==========================================
          // 2.5 MY ORDERS & PICKUPS BANNER
          // ==========================================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => showCustomerOrdersSheet(context: context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.receipt_long_rounded,
                          color: Color(0xFF2563EB),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My Orders & Pickups',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Track scheduled takeaway & view receipts',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ==========================================
          // 3. QUICK ACTION TILES (4 balanced items)
          // ==========================================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionTile(
                    icon: Icons.menu_book_outlined,
                    iconColor: const Color(0xFF0284C7),
                    iconBgColor: const Color(0xFFF0F9FF),
                    label: 'Addresses',
                    onTap: () => _showAddressesModal(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionTile(
                    icon: Icons.favorite_border_rounded,
                    iconColor: const Color(0xFFE11D48),
                    iconBgColor: const Color(0xFFFFF1F2),
                    label: 'Favourites',
                    onTap: () => _showFavouritesModal(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionTile(
                    icon: Icons.confirmation_number_outlined,
                    iconColor: const Color(0xFFD97706),
                    iconBgColor: const Color(0xFFFFFBEB),
                    label: 'Vouchers',
                    onTap: () => _showVouchersModal(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionTile(
                    icon: Icons.card_giftcard_rounded,
                    iconColor: const Color(0xFF7C3AED),
                    iconBgColor: const Color(0xFFF5F3FF),
                    label: 'Rewards',
                    onTap: () => _showRewardsModal(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ==========================================
          // 4. MENU OPTIONS LIST (Sleek Modern Card Architecture)
          // ==========================================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section 1 Header: Benefits & Policies
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 3.5,
                        height: 13,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'BENEFITS & POLICIES',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),

                // Card 1: Benefits & Policies
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0).withValues(alpha: 0.8),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        icon: Icons.workspace_premium_rounded,
                        iconColor: const Color(0xFFE11D48),
                        iconBgColor: const Color(0xFFFFF1F2),
                        title: 'Become a Super Saver',
                        subtitle:
                            'Unlock exclusive member perks & extra discounts',
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20)),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFFECDD3),
                              width: 0.8,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 10,
                                color: Color(0xFFE11D48),
                              ),
                              SizedBox(width: 3.5),
                              Text(
                                'PERKS',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFE11D48),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        onTap: () => _showSuperSaverModal(context),
                      ),

                      const Divider(
                        height: 1,
                        thickness: 1,
                        indent: 70,
                        endIndent: 16,
                        color: Color(0xFFF1F5F9),
                      ),
                      _buildMenuItem(
                        icon: Icons.receipt_long_rounded,
                        iconColor: const Color(0xFF2563EB),
                        iconBgColor: const Color(0xFFEFF6FF),
                        title: 'My Orders & Pickups',
                        subtitle: 'Track scheduled takeaway collections & receipts',
                        onTap: () => showCustomerOrdersSheet(context: context),
                      ),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        indent: 70,
                        endIndent: 16,
                        color: Color(0xFFF1F5F9),
                      ),
                      _buildMenuItem(
                        icon: Icons.shield_outlined,
                        iconColor: const Color(0xFF0284C7),
                        iconBgColor: const Color(0xFFF0F9FF),
                        title: 'Privacy policy',
                        subtitle:
                            'Data protection & personal account safety',
                        borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(20)),
                        onTap: () => _showPrivacyPolicyModal(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Section 2 Header: Support & System
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 3.5,
                        height: 13,
                        decoration: BoxDecoration(
                          color: const Color(0xFF64748B),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'SUPPORT & SYSTEM',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),

                // Card 2: Support & System Settings
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0).withValues(alpha: 0.8),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        icon: Icons.headset_mic_outlined,
                        iconColor: const Color(0xFF0891B2),
                        iconBgColor: const Color(0xFFECFEFF),
                        title: 'Help & Support',
                        subtitle: 'Customer Care, 24/7 Hotline & FAQs',
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20)),
                        onTap: () => _showHelpSupportModal(context),
                      ),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        indent: 70,
                        endIndent: 16,
                        color: Color(0xFFF1F5F9),
                      ),
                      _buildMenuItem(
                        icon: Icons.info_outline_rounded,
                        iconColor: const Color(0xFF475569),
                        iconBgColor: const Color(0xFFF1F5F9),
                        title: 'About',
                        subtitle: 'Version 1.1.0 • App Information',
                        onTap: () => _showAboutModal(context),
                      ),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        indent: 70,
                        endIndent: 16,
                        color: Color(0xFFF1F5F9),
                      ),
                      _buildMenuItem(
                        icon: Icons.logout_rounded,
                        iconColor: const Color(0xFFE11D48),
                        iconBgColor: const Color(0xFFFFF1F2),
                        title: 'Log out',
                        subtitle: 'Sign out of your customer account',
                        borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(20)),
                        onTap: () => _confirmLogout(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Delete Account Dark Red Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF991B1B), // Dark Red
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => _confirmDeleteAccount(context),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          size: 19,
                          color: Colors.white,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Delete account',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  ),
);
}

  // ==========================================
  // WIDGET HELPER BUILDERS
  // ==========================================

  Widget _buildSuperSaverBadge({bool isActive = false}) {
    if (isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFE11D48),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE11D48).withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'VIP',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                color: Colors.white,
              ),
            ),
            Text(
              'MEMBER',
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFCCD3), width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'SUPER',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 0.5,
              color: const Color(0xFFE11D48),
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  offset: const Offset(0.5, 0.5),
                  blurRadius: 1,
                ),
              ],
            ),
          ),
          Text(
            'SAVER',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 0.5,
              color: const Color(0xFFBE123C),
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  offset: const Offset(0.5, 0.5),
                  blurRadius: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 84,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE2E8F0).withValues(alpha: 0.8),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required VoidCallback onTap,
    String? subtitle,
    Widget? trailing,
    BorderRadius? borderRadius,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2.5),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                trailing,
                const SizedBox(width: 8),
              ],
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF94A3B8),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerFavoritesModalSheet extends ConsumerStatefulWidget {
  const _CustomerFavoritesModalSheet();

  @override
  ConsumerState<_CustomerFavoritesModalSheet> createState() =>
      _CustomerFavoritesModalSheetState();
}

class _CustomerFavoritesModalSheetState
    extends ConsumerState<_CustomerFavoritesModalSheet> {
  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(customerFavoritesProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'My Favourites',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${favorites.length}',
                        style: const TextStyle(
                          color: Color(0xFFE11D48),
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                if (favorites.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _isEditing = !_isEditing;
                      });
                    },
                    icon: Icon(
                      _isEditing
                          ? Icons.check_circle_rounded
                          : Icons.edit_rounded,
                      size: 15,
                      color: _isEditing
                          ? const Color(0xFF059669)
                          : const Color(0xFFE11D48),
                    ),
                    label: Text(
                      _isEditing ? 'Done' : 'Edit',
                      style: TextStyle(
                        color: _isEditing
                            ? const Color(0xFF059669)
                            : const Color(0xFFE11D48),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: _isEditing
                          ? const Color(0xFFECFDF5)
                          : const Color(0xFFFFF1F2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
            if (_isEditing && favorites.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 4),
                child: Text(
                  'Tap the delete button to remove a restaurant from favourites',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: const Color(0xFFE11D48).withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            if (favorites.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFF1F2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite_border_rounded,
                          size: 32,
                          color: Color(0xFFE11D48),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No favourites yet',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Explore shops and tap the heart icon to save them here.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.60,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  itemCount: favorites.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final fav = favorites[index];
                    return Material(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          if (_isEditing) {
                            _removeFavorite(fav);
                          } else {
                            if (fav.id.startsWith('res-')) {
                              Navigator.pop(context);
                              context.push('/customer/restaurants/${fav.id}');
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFF1F5F9)),
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 20,
                                backgroundColor: Color(0xFFFFEDEC),
                                child: Icon(
                                  Icons.favorite_rounded,
                                  color: Color(0xFFE11D48),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      fav.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13.5,
                                        color: Color(0xFF1E293B),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      fav.subtitle,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: Color(0xFF64748B),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (_isEditing)
                                InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () => _removeFavorite(fav),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFEDEC),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFFFECDD3),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Color(0xFFE11D48),
                                      size: 18,
                                    ),
                                  ),
                                )
                              else
                                Text(
                                  fav.rating,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFD97706),
                                    fontSize: 12.5,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeFavorite(FavoriteRestaurant fav) async {
    await ref
        .read(customerFavoritesProvider.notifier)
        .removeFavorite(fav.id);
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${fav.name} removed from favourites'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

