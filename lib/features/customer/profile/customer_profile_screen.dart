import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../auth/domain/user_profile.dart';
import '../../auth/presentation/auth_controller.dart';
import '../shell/customer_shell_screen.dart';
import 'widgets/change_avatar_sheet.dart';

/// Customer profile management screen (Section 26).
class CustomerProfileScreen extends ConsumerStatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  ConsumerState<CustomerProfileScreen> createState() =>
      _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends ConsumerState<CustomerProfileScreen> {
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

  Future<void> _showEditProfileSheet(
      BuildContext context, UserProfile profile) async {
    // Derive initial first and last name
    String initialFirstName = profile.firstName ?? '';
    String initialLastName = profile.lastName ?? '';
    if (initialFirstName.isEmpty && initialLastName.isEmpty && profile.fullName != null) {
      final parts = profile.fullName!.trim().split(' ');
      initialFirstName = parts.firstOrNull ?? '';
      if (parts.length > 1) {
        initialLastName = parts.sublist(1).join(' ');
      }
    }

    final firstNameController = TextEditingController(text: initialFirstName);
    final lastNameController = TextEditingController(text: initialLastName);
    final phoneController = TextEditingController(text: profile.phone ?? '');
    final addressController = TextEditingController(text: profile.address ?? '');
    final cityController = TextEditingController(text: profile.city ?? 'Dhaka');
    final dobController = TextEditingController(text: profile.dateOfBirth ?? '');
    String selectedGender = profile.gender ?? 'Male';
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    ref.read(customerNavbarVisibleProvider.notifier).hide();
    final targetContext = rootNavigatorKey.currentContext ?? context;
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
                    maxHeight: MediaQuery.of(context).size.height * 0.88,
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
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Edit Profile',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () => Navigator.pop(bottomSheetContext),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Quick Avatar Preview & Change Photo
                          Center(
                            child: Column(
                              children: [
                                UserAvatar(
                                  avatarUrl: profile.avatarUrl,
                                  name: '${firstNameController.text.trim()} ${lastNameController.text.trim()}'.trim().isNotEmpty
                                      ? '${firstNameController.text.trim()} ${lastNameController.text.trim()}'.trim()
                                      : profile.fullName,
                                  radius: 36,
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
                                  icon: const Icon(Icons.photo_camera_outlined,
                                      size: 15),
                                  label: const Text('Change Photo'),
                                  style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // First Name and Last Name Row
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: firstNameController,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: const InputDecoration(
                                    labelText: 'First Name *',
                                    prefixIcon: Icon(Icons.person_outline_rounded),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: lastNameController,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: const InputDecoration(
                                    labelText: 'Last Name',
                                    prefixIcon: Icon(Icons.person_outline_rounded),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Gender Selection
                          const Text(
                            'Gender',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: ['Male', 'Female', 'Other'].map((gender) {
                              final isSelected = selectedGender == gender;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  label: Text(gender),
                                  selected: isSelected,
                                  onSelected: (_) {
                                    setSheetState(() => selectedGender = gender);
                                  },
                                  selectedColor: AppColors.primary.withValues(alpha: 0.12),
                                  labelStyle: TextStyle(
                                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                  side: BorderSide(
                                    color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),

                          // Date of Birth (DOB)
                          TextFormField(
                            controller: dobController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Date of Birth (DOB)',
                              hintText: 'Select date of birth',
                              prefixIcon: Icon(Icons.cake_outlined),
                              suffixIcon: Icon(Icons.calendar_month_rounded, color: AppColors.primary),
                            ),
                            onTap: () async {
                              final now = DateTime.now();
                              DateTime initialDate = DateTime(2000, 1, 1);
                              if (dobController.text.isNotEmpty) {
                                final parsed = DateTime.tryParse(dobController.text);
                                if (parsed != null) initialDate = parsed;
                              }

                              final picked = await showDatePicker(
                                context: context,
                                initialDate: initialDate,
                                firstDate: DateTime(1920),
                                lastDate: now,
                                helpText: 'Select Date of Birth',
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
                          const SizedBox(height: 16),

                          // Phone field
                          TextFormField(
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Address field
                          TextFormField(
                            controller: addressController,
                            decoration: const InputDecoration(
                              labelText: 'Address',
                              hintText: 'House / Road / Area',
                              prefixIcon: Icon(Icons.home_outlined),
                            ),
                          ),
                          const SizedBox(height: 16),

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

                          // Save button
                          PrimaryButton(
                            text: 'Save Changes',
                            isLoading: isSaving,
                            onPressed: isSaving
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) return;
                                    setSheetState(() => isSaving = true);

                                    final fName = firstNameController.text.trim();
                                    final lName = lastNameController.text.trim();
                                    final computedFullName = '$fName $lName'.trim();

                                    final success = await ref
                                        .read(authControllerProvider.notifier)
                                        .updateProfile(
                                          id: profile.id,
                                          firstName: fName,
                                          lastName: lName,
                                          fullName: computedFullName,
                                          gender: selectedGender,
                                          phone: phoneController.text.trim().isEmpty
                                              ? null
                                              : phoneController.text.trim(),
                                          address: addressController.text.trim().isEmpty
                                              ? null
                                              : addressController.text.trim(),
                                          city: cityController.text.trim().isEmpty
                                              ? null
                                              : cityController.text.trim(),
                                          dateOfBirth: dobController.text.trim().isEmpty
                                              ? null
                                              : dobController.text.trim(),
                                          avatarUrl: profile.avatarUrl,
                                        );

                                    if (context.mounted) {
                                      setSheetState(() => isSaving = false);
                                      if (success) {
                                        Navigator.pop(bottomSheetContext);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Profile updated successfully!',
                                            ),
                                            backgroundColor: AppColors.success,
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Failed to update profile.'),
                                            backgroundColor: AppColors.error,
                                          ),
                                        );
                                      }
                                    }
                                  },
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

  void _confirmLogout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text('Are you sure you want to log out of SaveBite?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                await ref.read(authControllerProvider.notifier).signOut();
                if (context.mounted) {
                  context.go(AppRoutes.login);
                }
              },
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentUserProfileProvider);

    if (profile == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Not logged in.')),
      );
    }

    final displayName = profile.fullName?.trim() ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Profile',
            onPressed: () => _showEditProfileSheet(context, profile),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
        child: Column(
          children: [
            // Profile Avatar with Camera badge & Direct Access
            Center(
              child: GestureDetector(
                onTap: () => _showChangeAvatarModal(context, profile),
                child: UserAvatar(
                  avatarUrl: profile.avatarUrl,
                  name: profile.fullName,
                  radius: 50,
                  showEditBadge: true,
                  onTapEdit: () => _showChangeAvatarModal(context, profile),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _showChangeAvatarModal(context, profile),
              icon: const Icon(Icons.photo_camera_outlined, size: 16),
              label: const Text('Change Profile Picture'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: AppColors.primary,
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Full Name & Role badge
            Text(
              displayName.isNotEmpty ? displayName : 'Customer',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Customer Account',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Profile Information Card (Section 26)
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.person_outline_rounded,
                        color: AppColors.primary,
                      ),
                      title: const Text(
                        'Full Name',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      subtitle: Text(
                        displayName.isNotEmpty ? displayName : 'Not provided',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.email_outlined,
                        color: AppColors.primary,
                      ),
                      title: const Text(
                        'Email Address',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      subtitle: Text(
                        profile.email,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.lock_outline_rounded,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.phone_outlined,
                        color: AppColors.primary,
                      ),
                      title: const Text(
                        'Phone Number',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      subtitle: Text(
                        (profile.phone != null && profile.phone!.isNotEmpty)
                            ? profile.phone!
                            : 'Not provided',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: (profile.phone != null &&
                                  profile.phone!.isNotEmpty)
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                    if (profile.gender != null && profile.gender!.isNotEmpty) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.wc_outlined,
                          color: AppColors.primary,
                        ),
                        title: const Text(
                          'Gender',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        subtitle: Text(
                          profile.gender!,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                    if (profile.dateOfBirth != null && profile.dateOfBirth!.isNotEmpty) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.cake_outlined,
                          color: AppColors.primary,
                        ),
                        title: const Text(
                          'Date of Birth',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        subtitle: Text(
                          profile.dateOfBirth!,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                    if ((profile.address != null && profile.address!.isNotEmpty) ||
                        (profile.city != null && profile.city!.isNotEmpty)) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.primary,
                        ),
                        title: const Text(
                          'Address & City',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        subtitle: Text(
                          [profile.address, profile.city]
                              .where((s) => s != null && s.trim().isNotEmpty)
                              .join(', '),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Edit Profile Button
            PrimaryButton(
              text: 'Edit Profile',
              icon: const Icon(Icons.edit_rounded, size: 18),
              onPressed: () => _showEditProfileSheet(context, profile),
            ),
            const SizedBox(height: 12),

            // Logout Button
            OutlinedButton.icon(
              onPressed: () => _confirmLogout(context),
              icon: const Icon(
                Icons.logout_rounded,
                color: AppColors.error,
                size: 18,
              ),
              label: const Text(
                'Log Out',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // App version & mission note
            Text(
              '${AppConstants.appName} v1.0.0\nSafe surplus food discovery',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
