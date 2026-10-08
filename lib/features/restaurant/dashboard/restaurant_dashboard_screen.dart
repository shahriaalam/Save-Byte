import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/colors/account_colors.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/double_pull_reload.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../auth/domain/user_profile.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../shared/models/food_offer.dart';
import '../../shared/models/promo_banner.dart';
import '../../shared/models/restaurant.dart';
import '../../../core/utils/platform_file_picker.dart';
import '../../shared/data/promo_banner_controller.dart';
import '../../shared/data/admin_financial_controller.dart';
import '../../shared/presentation/payment_portal_sheet.dart';
import '../notifications/restaurant_notification_controller.dart';
import '../presentation/restaurant_controller.dart';

/// Restaurant Management Portal Screen.
/// Floating Bottom Navigation Bar order:
/// - 0: Posts (1st)
/// - 1: Offers (Admin promotional packages: 24h banner 2000 tk, 24h boost 600 tk, etc.)
/// - 2: Home (In the middle! Cockpit with all symbols, metrics, profile completeness)
/// - 3: Info (Top-selling posts leaderboard, telemetry, waste impact)
/// - 4: Account (Organized like User Account interface with Owner Profile & protected info updates)
class RestaurantDashboardScreen extends ConsumerStatefulWidget {
  const RestaurantDashboardScreen({super.key});

  @override
  ConsumerState<RestaurantDashboardScreen> createState() =>
      _RestaurantDashboardScreenState();
}

class _RestaurantDashboardScreenState
    extends ConsumerState<RestaurantDashboardScreen> {
  // Nav bar order: Posts (0), Offers (1), Home (2 - middle), Info (3), Account (4)
  int _navIndex = 2; // Home in the middle as initial landing view
  bool _isNavVisible = true;
  String _selectedPostsFilter = 'all'; // 'all', 'active', 'boosted'

  // Protected Restaurant & Owner Change Request State (Requires Admin Approval)
  Map<String, dynamic>? _pendingChangeRequest;
  String? _approvedOwnerName;
  String? _approvedTradeLicense;
  String? _approvedNid;
  String? _approvedEmail;

  // Active Promo Purchases from Admin
  bool _hasActive24hBanner = false;
  bool _hasActive24hBoost = false;

  // ==========================================
  // MODAL RUNNER WITH FLOATING NAVBAR AUTO-HIDE
  // ==========================================
  Future<T?> _showSheet<T>({required WidgetBuilder builder}) async {
    setState(() => _isNavVisible = false);
    try {
      return await showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: builder,
      );
    } finally {
      if (mounted) {
        setState(() => _isNavVisible = true);
      }
    }
  }

  // ==========================================
  // INCOMPLETE PROFILE ALERT DIALOG (Preserved for tests)
  // ==========================================
  void _showIncompleteProfileDialog(
      BuildContext context, Restaurant restaurant) {
    setState(() => _isNavVisible = false);
    final missing = restaurant.missingProfileFields;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 26),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Complete Profile First',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your restaurant cannot place any food posts until your profile is complete with all required information and a profile picture.',
              style: TextStyle(
                  fontSize: 13, height: 1.35, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Missing Requirements:',
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.error),
                  ),
                  const SizedBox(height: 4),
                  for (final item in missing)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Icon(Icons.circle,
                                size: 6, color: AppColors.error),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item,
                              style: const TextStyle(
                                  fontSize: 11.5, color: AppColors.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context.push(AppRoutes.restaurantProfile);
            },
            child: const Text('Complete Profile'),
          ),
        ],
      ),
    ).then((_) {
      if (mounted) setState(() => _isNavVisible = true);
    });
  }

  void _onPostSurplusTapped(BuildContext context, Restaurant restaurant) {
    if (!restaurant.isProfileComplete) {
      _showIncompleteProfileDialog(context, restaurant);
    } else {
      context.push(AppRoutes.restaurantCreateOffer);
    }
  }

  // ==========================================
  // OWNER PROFILE MODAL (Verified & Protected)
  // ==========================================
  void _showOwnerProfileModal(
      BuildContext context, Restaurant restaurant, UserProfile? user) {
    final ownerName = _approvedOwnerName ??
        (user?.fullName?.trim().isNotEmpty == true
            ? user!.fullName!
            : (restaurant.name.contains('Kitchen')
                ? 'Rahman Chowdhury'
                : 'Shahria Alam'));
    final ownerEmail = _approvedEmail ?? (user?.email ?? 'restaurant@savebite.com');
    final ownerPhone = restaurant.phone ?? user?.phone ?? '01711234567';
    final tradeLicense = _approvedTradeLicense ?? 'TRAD/DSCC/019284/2024 (Banasree Zone)';
    final nid = _approvedNid ?? 'NID-8291-XXXX-4912 (Verified)';
    final restaurantName = restaurant.name;
    final address = restaurant.address ?? 'House 14, Road 4, Block D, Banasree, Dhaka';

    _showSheet<void>(
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.90,
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Title with Verified Seal
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: Color(0xFF16A34A),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Owner Profile',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          'Official business ownership & license records',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            size: 13, color: Color(0xFF16A34A)),
                        SizedBox(width: 4),
                        Text(
                          'VERIFIED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Protected Notice Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_outline_rounded,
                        color: Color(0xFF0F766E), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This owner profile is verified by SaveBite HQ. For safety and fraud prevention, verified owner and restaurant records cannot be edited directly.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF475569),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Owner Credentials List (All 7-8 official properties)
              _buildOwnerFieldTile('Owner Full Name', ownerName, Icons.badge_outlined),
              _buildOwnerFieldTile('Account Role', 'Verified Restaurant Owner', Icons.verified_user_outlined),
              _buildOwnerFieldTile('Email Address', ownerEmail, Icons.email_outlined),
              _buildOwnerFieldTile('Official Phone', ownerPhone, Icons.phone_outlined),
              _buildOwnerFieldTile('Trade License No.', tradeLicense, Icons.receipt_long_outlined),
              _buildOwnerFieldTile('National ID (NID)', nid, Icons.credit_card_outlined),
              _buildOwnerFieldTile('Assigned Restaurant', restaurantName, Icons.storefront_outlined),
              _buildOwnerFieldTile('Restaurant Address', address, Icons.place_outlined),
              const SizedBox(height: 18),

              // Action button to request updates
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.edit_note_rounded, size: 20),
                  label: const Text(
                    'Request Information Update',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _showRequestInfoUpdateModal(context, restaurant, user);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOwnerFieldTile(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF64748B)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.lock_rounded, size: 14, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // REQUEST INFO UPDATE MODAL (With Admin Notification & Approval Flow)
  // Allows proposing edits to ALL owner & restaurant info
  // ==========================================
  void _showRequestInfoUpdateModal(
      BuildContext context, Restaurant restaurant, [UserProfile? user]) {
    final currentOwner = _approvedOwnerName ??
        (user?.fullName?.trim().isNotEmpty == true
            ? user!.fullName!
            : (restaurant.name.contains('Kitchen')
                ? 'Rahman Chowdhury'
                : 'Shahria Alam'));
    final currentEmail = _approvedEmail ?? (user?.email ?? 'restaurant@savebite.com');
    final currentPhone = restaurant.phone ?? user?.phone ?? '01711234567';
    final currentTradeLicense = _approvedTradeLicense ?? 'TRAD/DSCC/019284/2024 (Banasree Zone)';
    final currentNid = _approvedNid ?? 'NID-8291-XXXX-4912 (Verified)';
    final currentAddress = restaurant.address ?? 'House 14, Road 4, Block D, Banasree, Dhaka';

    final ownerNameController = TextEditingController(text: currentOwner);
    final nidController = TextEditingController(text: currentNid);
    final tradeLicenseController = TextEditingController(text: currentTradeLicense);
    final nameController = TextEditingController(text: restaurant.name);
    final phoneController = TextEditingController(text: currentPhone);
    final emailController = TextEditingController(text: currentEmail);
    final addressController = TextEditingController(text: currentAddress);
    final reasonController = TextEditingController(
        text: 'Annual DSCC trade license renewal & contact update');

    _showSheet<void>(
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(modalCtx).size.height * 0.90,
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(modalCtx).viewInsets.bottom + 28,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Header
                    const Row(
                      children: [
                        Icon(Icons.edit_note_rounded,
                            color: Color(0xFF2563EB), size: 26),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Request Info Change',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Changes to Owner Name, License, NID, Restaurant Name, Address, or Phone require Admin review.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 14),

                    // Admin Review Notice
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.shield_outlined,
                              color: Color(0xFFB45309), size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Security Rule: Verified restaurants cannot change core data directly. When you submit, the Admin gets an instant notification. Your current approved details remain live until the Admin accepts the changes.',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF92400E),
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // SECTION 1: OWNER LEGAL IDENTITY
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDBEAFE),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.person_rounded,
                              size: 14, color: Color(0xFF2563EB)),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Owner Legal Identity',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: ownerNameController,
                      decoration: const InputDecoration(
                        labelText: 'Owner Full Name',
                        hintText: 'e.g. Mahmudur Rahman Chowdhury',
                        border: OutlineInputBorder(),
                        isDense: true,
                        prefixIcon: Icon(Icons.badge_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nidController,
                      decoration: const InputDecoration(
                        labelText: 'National ID (NID)',
                        hintText: 'e.g. NID-8291-XXXX-4912',
                        border: OutlineInputBorder(),
                        isDense: true,
                        prefixIcon: Icon(Icons.credit_card_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: tradeLicenseController,
                      decoration: const InputDecoration(
                        labelText: 'Trade License No. (DSCC)',
                        hintText: 'e.g. TRAD/DSCC/019284/2024',
                        border: OutlineInputBorder(),
                        isDense: true,
                        prefixIcon: Icon(Icons.receipt_long_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // SECTION 2: RESTAURANT & CONTACT INFORMATION
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.storefront_rounded,
                              size: 14, color: Color(0xFFD97706)),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Restaurant & Contact Details',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Proposed Restaurant Name',
                        hintText: 'e.g. Blue Bell Café',
                        border: OutlineInputBorder(),
                        isDense: true,
                        prefixIcon: Icon(Icons.storefront_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Proposed Official Phone',
                        hintText: 'e.g. 01711234567',
                        border: OutlineInputBorder(),
                        isDense: true,
                        prefixIcon: Icon(Icons.phone_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Proposed Official Email',
                        hintText: 'e.g. bluebell@savebite.com',
                        border: OutlineInputBorder(),
                        isDense: true,
                        prefixIcon: Icon(Icons.email_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addressController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Proposed Address (Banasree, Dhaka)',
                        hintText: 'House 14, Road 4, Block D, Banasree, Dhaka',
                        border: OutlineInputBorder(),
                        isDense: true,
                        prefixIcon: Icon(Icons.place_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // SECTION 3: REASON FOR MODIFICATION
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.info_rounded,
                              size: 14, color: Color(0xFF475569)),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Reason for Modification',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: reasonController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Reason for Modification',
                        hintText: 'e.g. Annual trade license renewal, owner update, branch relocation',
                        border: OutlineInputBorder(),
                        isDense: true,
                        prefixIcon: Icon(Icons.info_outline_rounded, size: 20),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: const Text(
                          'Submit Change Request to Admin',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          setState(() {
                            _pendingChangeRequest = {
                              'ownerName': ownerNameController.text.trim(),
                              'name': nameController.text.trim(),
                              'phone': phoneController.text.trim(),
                              'email': emailController.text.trim(),
                              'tradeLicense': tradeLicenseController.text.trim(),
                              'nid': nidController.text.trim(),
                              'address': addressController.text.trim(),
                              'reason': reasonController.text.trim(),
                              'submittedAt': DateTime.now(),
                              'status': 'pending',
                            };
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                '📨 Change request submitted! Admin has received your notification for review.',
                              ),
                              backgroundColor: Color(0xFF2563EB),
                              duration: Duration(seconds: 4),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  // ==========================================
  // ADMIN PACKAGE PURCHASE CONFIRMATION MODAL
  // ==========================================
  void _showPackagePurchaseModal({
    required BuildContext context,
    required String packageTitle,
    required String price,
    required String duration,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onConfirm,
  }) {
    _showSheet<void>(
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        packageTitle,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        'Admin Promotion Package • $duration',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Package Cost',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        price,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 18, color: Color(0xFFE2E8F0)),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF334155),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 15, color: Color(0xFF16A34A)),
                      SizedBox(width: 6),
                      Text(
                        'Billed to linked restaurant balance / weekly settlement',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  final cleanStr = price.replaceAll(RegExp(r'[^0-9]'), '');
                  final parsedAmount = double.tryParse(cleanStr) ?? 600.0;
                  final payResult = await showPaymentPortalSheet(
                    context: context,
                    title: packageTitle,
                    subtitle: 'Admin Promotional Package • $duration',
                    amount: parsedAmount,
                    customerOrBusinessName: 'Partner Kitchen',
                    perkHighlights: [
                      description,
                      'Instant Feature Clearance',
                    ],
                    itemType: 'ad_package',
                  );

                  if (payResult != null && payResult.isSuccess) {
                    ref
                        .read(adminFinancialProvider.notifier)
                        .recordSubscriptionPayment(
                          payerName: 'Partner Merchant',
                          payerType: 'restaurant',
                          planName: packageTitle,
                          amount: parsedAmount,
                          paymentGateway: payResult.gateway ?? 'bKash',
                          transactionId:
                              payResult.transactionId ?? 'TXN-PKG-771',
                        );
                    onConfirm();
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Payment was not completed. Package was not activated.'),
                          backgroundColor: Color(0xFF64748B),
                        ),
                      );
                    }
                  }
                },
                child: Text(
                  'Confirm & Activate ($price)',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // DELETE ACCOUNT & LOGOUT ACTIONS
  // ==========================================
  Future<void> _confirmDeleteAccount(BuildContext context) async {
    setState(() => _isNavVisible = false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFF8B0000), size: 26),
            SizedBox(width: 8),
            Text(
              'Delete Account',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF8B0000),
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to permanently delete your restaurant account? All listed food offers, active boosts, banners, and analytics history will be erased immediately.',
          style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF8B0000), // Dark red button
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Permanently Delete'),
          ),
        ],
      ),
    );

    if (mounted) setState(() => _isNavVisible = true);

    if (confirmed == true && mounted) {
      await ref.read(authControllerProvider.notifier).signOut();
      if (context.mounted) {
        context.go(AppRoutes.login);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your restaurant account has been removed.'),
            backgroundColor: Color(0xFF8B0000),
          ),
        );
      }
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    setState(() => _isNavVisible = false);
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Log Out',
      message: 'Are you sure you want to log out of your restaurant dashboard?',
      confirmLabel: 'Log Out',
    );
    if (mounted) setState(() => _isNavVisible = true);

    if (confirmed) {
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }

  // ==========================================
  // MAIN BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    final restaurantAsync = ref.watch(currentRestaurantProvider);
    final offersAsync = ref.watch(currentRestaurantOffersProvider);
    final userProfile = ref.watch(currentUserProfileProvider);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: restaurantAsync.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        data: (restaurant) {
          if (restaurant == null) {
            return const Center(child: Text('Restaurant account not found.'));
          }

          final offers = offersAsync.asData?.value ?? [];

          return Stack(
            children: [
              // Screen Body with IndexedStack:
              // Index 0: Posts (1st)
              // Index 1: Offers (Admin offers: banner 24h 2000 tk, boost 24h 600 tk)
              // Index 2: Home (In the middle! Cockpit with all symbols)
              // Index 3: Info (Top selling posts leaderboard & impact)
              // Index 4: Account (Organized like user account + owner profile)
              Positioned.fill(
                child: DoublePullReload(
                  onReload: () async {
                    await Future.wait<dynamic>([
                      ref.refresh(currentRestaurantProvider.future),
                      ref.refresh(currentRestaurantOffersProvider.future),
                    ]);
                  },
                  child: IndexedStack(
                    index: _navIndex,
                    children: [
                      _buildPostsTab(context, restaurant, offers),
                      _buildOffersTab(context, restaurant, offers),
                      _buildHomeTab(context, restaurant, offers),
                      _buildInfoTab(context, restaurant, offers),
                      _buildAccountTab(context, restaurant, userProfile),
                    ],
                  ),
                ),
              ),

              // Floating Pill Bottom Navigation Bar (Matching Customer Shell)
              // Home in the middle: Posts (0), Offers (1), Home (2), Info (3), Account (4)
              if (_isNavVisible)
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: bottomInset + 16,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Container(
                        height: 66,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(33),
                          border: Border.all(
                            color: AppColors.border.withValues(alpha: 0.8),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.10),
                              blurRadius: 20,
                              spreadRadius: 1,
                              offset: const Offset(0, 6),
                            ),
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              blurRadius: 14,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(33),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildNavItem(
                                index: 0,
                                label: 'Posts',
                                icon: Icons.fastfood_outlined,
                                selectedIcon: Icons.fastfood_rounded,
                              ),
                              _buildNavItem(
                                index: 1,
                                label: 'Offers',
                                icon: Icons.local_offer_outlined,
                                selectedIcon: Icons.local_offer_rounded,
                              ),
                              _buildNavItem(
                                index: 2,
                                label: 'Home',
                                icon: Icons.home_outlined,
                                selectedIcon: Icons.home_rounded,
                              ),
                              _buildNavItem(
                                index: 3,
                                label: 'Info',
                                icon: Icons.insights_rounded,
                                selectedIcon: Icons.insights_rounded,
                              ),
                              _buildNavItem(
                                index: 4,
                                label: 'Account',
                                icon: Icons.storefront_outlined,
                                selectedIcon: Icons.storefront_rounded,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading dashboard: $err')),
      ),
    );
  }

  // ==========================================
  // FLOATING NAV BAR ITEM WIDGET
  // ==========================================
  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData selectedIcon,
  }) {
    final isSelected = _navIndex == index;

    return Expanded(
      child: Semantics(
        selected: isSelected,
        label: label,
        button: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: ValueKey('restaurant_nav_$label'),
            borderRadius: BorderRadius.circular(24),
            onTap: () => setState(() => _navIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      isSelected ? selectedIcon : icon,
                      size: 21,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TAB 0: POSTS (1st option on bottom bar)
  // ==========================================
  Widget _buildPostsTab(
      BuildContext context, Restaurant restaurant, List<FoodOffer> offers) {
    List<FoodOffer> filtered = offers;
    if (_selectedPostsFilter == 'active') {
      filtered = offers.where((o) => o.isActive).toList();
    } else if (_selectedPostsFilter == 'boosted') {
      filtered = offers.where((o) => o.isBoosted).toList();
    }

    final isComplete = restaurant.isProfileComplete;

    return SafeArea(
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row with title and Add button
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All Food Posts',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Manage surplus listings in Banasree',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text(
                      '+ New Surplus Post',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed: () =>
                        _onPostSurplusTapped(context, restaurant),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Filter Chips Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                child: Row(
                  children: [
                    _buildFilterChip(
                      'All (${offers.length})',
                      _selectedPostsFilter == 'all',
                      () => setState(() => _selectedPostsFilter = 'all'),
                    ),
                    const SizedBox(width: 6),
                    _buildFilterChip(
                      'Active (${offers.where((o) => o.isActive).length})',
                      _selectedPostsFilter == 'active',
                      () => setState(() => _selectedPostsFilter = 'active'),
                    ),
                    const SizedBox(width: 6),
                    _buildFilterChip(
                      'Boosted 🔥 (${offers.where((o) => o.isBoosted).length})',
                      _selectedPostsFilter == 'boosted',
                      () => setState(() => _selectedPostsFilter = 'boosted'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Posts List
              if (filtered.isEmpty)
                EmptyState(
                  title: _selectedPostsFilter == 'boosted'
                      ? 'No boosted posts'
                      : 'No food offers posted yet',
                  message: isComplete
                      ? 'Tap "+ New Surplus Post" to list fresh discounted food for hungry neighbors in Banasree!'
                      : 'Complete your restaurant profile to start posting surplus food offers.',
                  icon: Icons.fastfood_outlined,
                  actionText:
                      isComplete ? 'Post Food Offer' : 'Complete Profile',
                  onAction: () {
                    if (isComplete) {
                      context.push(AppRoutes.restaurantCreateOffer);
                    } else {
                      context.push(AppRoutes.restaurantProfile);
                    }
                  },
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final offer = filtered[index];
                    return _buildOfferCard(context, offer, restaurant);
                  },
                ),
            ],
          ),
        ),
      );
  }

  // ==========================================
  // TAB 1: OFFERS (Admin Provided Offers: Banner 24h 2000 tk, Boost 24h 600 tk, etc.)
  // ==========================================
  Widget _buildOffersTab(
      BuildContext context, Restaurant restaurant, List<FoodOffer> offers) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.campaign_rounded,
                    color: Color(0xFF7C3AED),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin Promotional Offers',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        'Growth, banner & boost packages provided by SaveBite HQ',
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Active Promotions Status Banner
            if (_hasActive24hBanner || _hasActive24hBoost)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF10B981), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Active Campaign: ${_hasActive24hBanner ? "1 Homepage Hero Banner (24h)" : ""}${_hasActive24hBanner && _hasActive24hBoost ? " • " : ""}${_hasActive24hBoost ? "1 Dish Boost (24h)" : ""}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF065F46),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ADMIN OFFER 1: 1 Banner for 24hrs 2000 tk (Explicitly requested!)
            _buildAdminPackageCard(
              badge: 'POPULAR • HOMEPAGE HERO',
              badgeColor: const Color(0xFF2563EB),
              title: '1 Homepage Hero Banner (24 Hours)',
              priceTag: '${AppConstants.currencySymbol}2,000',
              duration: '24 Hours',
              description:
                  'Promote Blue Bell Café on the customer home slideshow banner carousel for 24 hours. Includes custom headline, image & direct booking link.',
              reachMetric: '12,500+ Customer Views',
              icon: Icons.view_carousel_rounded,
              iconColor: const Color(0xFF2563EB),
              iconBgColor: const Color(0xFFDBEAFE),
              isPurchased: _hasActive24hBanner,
              actionLabel: _hasActive24hBanner
                  ? 'Banner Active (Design / Edit)'
                  : 'Buy Banner for 24h (${AppConstants.currencySymbol}2,000)',
              onAction: () {
                if (_hasActive24hBanner) {
                  _showHeroBannerModal(context, restaurant);
                } else {
                  _showPackagePurchaseModal(
                    context: context,
                    packageTitle: '1 Homepage Hero Banner (24h)',
                    price: '${AppConstants.currencySymbol}2,000',
                    duration: '24 Hours',
                    description:
                        'Feature your restaurant banner prominently on the top carousel of the Customer Home Screen across Banasree and Dhaka for 24 hours.',
                    icon: Icons.view_carousel_rounded,
                    color: const Color(0xFF2563EB),
                    onConfirm: () async {
                      setState(() => _hasActive24hBanner = true);
                      await ref
                          .read(restaurantActionNotifierProvider.notifier)
                          .addBannerCredits(1);
                      if (context.mounted) {
                        _showHeroBannerModal(context, restaurant);
                      }
                    },
                  );
                }
              },
            ),
            const SizedBox(height: 14),

            // ADMIN OFFER 2: Boost for 24hrs 600 tk (Explicitly requested!)
            _buildAdminPackageCard(
              badge: 'HIGH CONVERSION • TOP FEEDS',
              badgeColor: const Color(0xFFFF5722),
              title: 'Post Boost for 24 Hours',
              priceTag: '${AppConstants.currencySymbol}600',
              duration: '24 Hours',
              description:
                  'Boost a surplus food post to #1 priority placement in Customer Search & Hot Deals feeds in Banasree for 24 hours.',
              reachMetric: '3.4x Faster Orders',
              icon: Icons.local_fire_department_rounded,
              iconColor: const Color(0xFFFF5722),
              iconBgColor: const Color(0xFFFFEDE6),
              isPurchased: _hasActive24hBoost,
              actionLabel: _hasActive24hBoost
                  ? 'Boost Active (Manage Posts)'
                  : 'Buy Boost for 24h (${AppConstants.currencySymbol}600)',
              onAction: () {
                _showPackagePurchaseModal(
                  context: context,
                  packageTitle: 'Post Boost for 24 Hours',
                  price: '${AppConstants.currencySymbol}600',
                  duration: '24 Hours',
                  description:
                      'Pin your surplus dish at the top of customer search and hot deals in Banasree for 24 hours to clear all stock before closing.',
                  icon: Icons.local_fire_department_rounded,
                  color: const Color(0xFFFF5722),
                  onConfirm: () {
                    setState(() => _hasActive24hBoost = true);
                    _showBoostOffersModal(context, offers, restaurant);
                  },
                );
              },
            ),
            const SizedBox(height: 14),

            // ADMIN OFFER 3: 48h Weekend Surge Boost 1000 tk
            _buildAdminPackageCard(
              badge: 'WEEKEND SPECIAL • 48H',
              badgeColor: const Color(0xFFD97706),
              title: 'Weekend 48h Surge Boost Pack',
              priceTag: '${AppConstants.currencySymbol}1,000',
              duration: 'Friday & Saturday (48h)',
              description:
                  'Covers the entire weekend surplus rush. Boost up to 2 surplus dishes for 48 hours during Dhaka weekend dining hours.',
              reachMetric: 'Save ${AppConstants.currencySymbol}200 on bundle',
              icon: Icons.bolt_rounded,
              iconColor: const Color(0xFFD97706),
              iconBgColor: const Color(0xFFFEF3C7),
              actionLabel: 'Buy Weekend Pack (${AppConstants.currencySymbol}1,000)',
              onAction: () {
                _showPackagePurchaseModal(
                  context: context,
                  packageTitle: 'Weekend 48h Surge Boost Pack',
                  price: '${AppConstants.currencySymbol}1,000',
                  duration: '48 Hours',
                  description:
                      'Keep up to 2 surplus dishes boosted throughout Friday and Saturday night closing hours.',
                  icon: Icons.bolt_rounded,
                  color: const Color(0xFFD97706),
                  onConfirm: () {
                    setState(() => _hasActive24hBoost = true);
                    _showBoostOffersModal(context, offers, restaurant);
                  },
                );
              },
            ),
            const SizedBox(height: 14),

            // ADMIN OFFER 4: Weekly Hero Banner 10,000 tk
            _buildAdminPackageCard(
              badge: 'MAXIMUM VISIBILITY • 7 DAYS',
              badgeColor: const Color(0xFF7C3AED),
              title: 'Weekly Hero Banner (7 Days Spotlight)',
              priceTag: '${AppConstants.currencySymbol}10,000',
              duration: 'Full Week (7 Days)',
              description:
                  'Maintain #1 featured carousel spot on Customer Home for an entire week. Includes detailed analytics on clicks & conversions.',
              reachMetric: '85,000+ Total Impressions',
              icon: Icons.star_rounded,
              iconColor: const Color(0xFF7C3AED),
              iconBgColor: const Color(0xFFEDE9FE),
              actionLabel: 'Buy 7-Day Banner (${AppConstants.currencySymbol}10,000)',
              onAction: () {
                _showPackagePurchaseModal(
                  context: context,
                  packageTitle: 'Weekly Hero Banner (7 Days)',
                  price: '${AppConstants.currencySymbol}10,000',
                  duration: '7 Days',
                  description:
                      'Maintain top featured placement on the customer home slideshow for 7 full days across Banasree and Dhaka.',
                  icon: Icons.star_rounded,
                  color: const Color(0xFF7C3AED),
                  onConfirm: () async {
                    setState(() => _hasActive24hBanner = true);
                    await ref
                        .read(restaurantActionNotifierProvider.notifier)
                        .addBannerCredits(1);
                    if (context.mounted) {
                      _showHeroBannerModal(context, restaurant);
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 14),

            // ADMIN OFFER 5: Push Notification Blast 3,500 tk
            _buildAdminPackageCard(
              badge: 'INSTANT SELLOUT • NEIGHBORHOOD',
              badgeColor: const Color(0xFF059669),
              title: 'Banasree Push Notification Broadcast',
              priceTag: '${AppConstants.currencySymbol}3,500',
              duration: '1 Broadcast Blast',
              description:
                  'Admin sends an instant high-priority push notification to all 3,420+ registered food lovers in Banasree when you post surplus food.',
              reachMetric: 'Avg 25-Min Sellout',
              icon: Icons.notifications_active_rounded,
              iconColor: const Color(0xFF059669),
              iconBgColor: const Color(0xFFD1FAE5),
              actionLabel: 'Schedule Broadcast (${AppConstants.currencySymbol}3,500)',
              onAction: () {
                _showPackagePurchaseModal(
                  context: context,
                  packageTitle: 'Banasree Push Notification Broadcast',
                  price: '${AppConstants.currencySymbol}3,500',
                  duration: 'Instant Broadcast',
                  description:
                      'Send a targeted push alert to all nearby customers in Banasree announcing tonight\'s fresh surplus drop.',
                  icon: Icons.notifications_active_rounded,
                  color: const Color(0xFF059669),
                  onConfirm: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('📣 Push notification broadcast scheduled for 08:30 PM closing window!'),
                        backgroundColor: Color(0xFF059669),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 18),

            // Admin Billing Terms Notice
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.receipt_long_outlined,
                      color: Color(0xFF64748B), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'All promotional packages purchased from Admin are automatically logged in your statement and settled weekly with your restaurant payouts.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminPackageCard({
    required String badge,
    required Color badgeColor,
    required String title,
    required String priceTag,
    required String duration,
    required String description,
    required String reachMetric,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String actionLabel,
    required VoidCallback onAction,
    bool isPurchased = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPurchased
              ? const Color(0xFF10B981)
              : const Color(0xFFE2E8F0),
          width: isPurchased ? 1.5 : 1,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: badgeColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF475569),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),

          // Price & Metric Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Wrap(
                  spacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      priceTag,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: badgeColor,
                      ),
                    ),
                    Text(
                      '• $duration',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    reachMetric,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 42,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: isPurchased
                    ? const Color(0xFF0F766E)
                    : const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: onAction,
              child: Text(
                actionLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: HOME (In the middle! "in home there will be all the symbols")
  // ==========================================
  Widget _buildHomeTab(
      BuildContext context, Restaurant restaurant, List<FoodOffer> offers) {
    final isComplete = restaurant.isProfileComplete;
    final restaurantName = restaurant.name.trim().isNotEmpty
        ? restaurant.name
        : 'Blue Bell Café';
    final area = restaurant.area?.trim().isNotEmpty == true
        ? restaurant.area!
        : 'Banasree';

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ambient Warm Header
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFECE5), // Warm peach
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
                      GestureDetector(
                        onTap: () =>
                            _showRestaurantPreviewSheet(context, restaurant),
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
                          child: restaurant.imageUrl != null &&
                                  restaurant.imageUrl!.isNotEmpty
                              ? ClipOval(
                                  child: Image.network(
                                    restaurant.imageUrl!,
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => UserAvatar(
                                      name: restaurantName,
                                      radius: 35,
                                    ),
                                  ),
                                )
                              : UserAvatar(name: restaurantName, radius: 35),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    restaurantName,
                                    style: const TextStyle(
                                      fontSize: 18.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1E293B),
                                      letterSpacing: -0.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.verified_rounded,
                                  size: 18,
                                  color: Color(0xFFD97706),
                                ),
                                const Spacer(),
                                _buildNotificationBell(context),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$area, Dhaka • ${restaurant.openingTime ?? '07:30 AM'} – ${restaurant.closingTime ?? '11:00 PM'}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () => _showRestaurantPreviewSheet(
                                      context, restaurant),
                                  child: const Text(
                                    'View Café Page',
                                    style: TextStyle(
                                      color: Color(0xFFE11D48),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                StatusBadge.fromStatus(restaurant.status),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Profile Completeness Banner (Required for unit & widget tests)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isComplete
                      ? const Color(0xFFF0FDF4)
                      : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isComplete
                        ? const Color(0xFFBBF7D0)
                        : const Color(0xFFFDE68A),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isComplete
                          ? Icons.check_circle_rounded
                          : Icons.warning_amber_rounded,
                      color: isComplete
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFD97706),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isComplete
                            ? 'Profile Complete (Dhaka Verified)'
                            : 'Profile Incomplete - Cannot Post Offers',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: isComplete
                              ? const Color(0xFF15803D)
                              : const Color(0xFFB45309),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          context.push(AppRoutes.restaurantProfile),
                      child: Text(
                        isComplete ? 'Edit' : 'Fix Now',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: isComplete
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFD97706),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // SaveBite Gold Subscription Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: InkWell(
                onTap: () =>
                    _showGoldSubscriptionModal(context, restaurant),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFFDE68A),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD97706)
                            .withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              restaurant.hasGoldSubscription
                                  ? 'SaveBite Gold Merchant ⭐'
                                  : 'SaveBite Gold Merchant',
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF92400E),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              restaurant.hasGoldSubscription
                                  ? 'Active • 5 monthly boosts & hero banner access'
                                  : 'Boost posts, add hero banner & get 3x reach',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFFB45309),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFB45309), Color(0xFFD97706)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          restaurant.hasGoldSubscription
                              ? 'ACTIVE'
                              : 'UPGRADE',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // QUICK SYMBOLS SECTION TITLE ("in home there will be all the symbols")
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: Text(
                'Quick Access Symbols',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // ALL THE SYMBOLS GRID (Row 1: 4 primary symbols)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionTile(
                          icon: Icons.add_circle_outline_rounded,
                          iconColor: const Color(0xFFE11D48),
                          iconBgColor: const Color(0xFFFFEDEC),
                          label: 'Post Surplus',
                          onTap: () =>
                              _onPostSurplusTapped(context, restaurant),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionTile(
                          icon: Icons.fastfood_outlined,
                          iconColor: const Color(0xFF2563EB),
                          iconBgColor: const Color(0xFFDBEAFE),
                          label: 'My Posts',
                          onTap: () => setState(() => _navIndex = 0),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionTile(
                          icon: Icons.local_offer_outlined,
                          iconColor: const Color(0xFF7C3AED),
                          iconBgColor: const Color(0xFFEDE9FE),
                          badgeText: 'HOT',
                          label: 'Ad Packages',
                          onTap: () => setState(() => _navIndex = 1),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionTile(
                          icon: Icons.insights_rounded,
                          iconColor: const Color(0xFF059669),
                          iconBgColor: const Color(0xFFD1FAE5),
                          label: 'Café Info',
                          onTap: () => setState(() => _navIndex = 3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Row 2: 4 operational symbols
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionTile(
                          icon: Icons.local_fire_department_rounded,
                          iconColor: const Color(0xFFFF5722),
                          iconBgColor: const Color(0xFFFFEDE6),
                          badgeText: 'PRO',
                          label: 'Boost Dishes',
                          onTap: () => _showBoostOffersModal(
                              context, offers, restaurant),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Builder(
                        builder: (context) {
                          final isHeroBannerEnabled =
                              restaurant.canAccessHeroBanner || _hasActive24hBanner;
                          return Expanded(
                            child: _buildActionTile(
                              icon: isHeroBannerEnabled
                                  ? Icons.view_carousel_rounded
                                  : Icons.lock_outline_rounded,
                              iconColor: isHeroBannerEnabled
                                  ? const Color(0xFF4F46E5)
                                  : const Color(0xFF94A3B8),
                              iconBgColor: isHeroBannerEnabled
                                  ? const Color(0xFFEEF2FF)
                                  : const Color(0xFFF1F5F9),
                              badgeText: isHeroBannerEnabled
                                  ? (restaurant.bannerCredits > 0
                                      ? '${restaurant.bannerCredits} READY'
                                      : (restaurant.hasActiveBanner ? 'LIVE' : null))
                                  : 'LOCKED',
                              badgeColor: isHeroBannerEnabled
                                  ? (restaurant.hasActiveBanner
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFF4F46E5))
                                  : const Color(0xFF64748B),
                              label: 'Hero Banner',
                              isDisabled: !isHeroBannerEnabled,
                              onTap: () {
                                if (isHeroBannerEnabled) {
                                  _showHeroBannerModal(context, restaurant);
                                } else {
                                  _showHeroBannerLockedModal(context, restaurant);
                                }
                              },
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionTile(
                          icon: Icons.access_time_rounded,
                          iconColor: const Color(0xFFD97706),
                          iconBgColor: const Color(0xFFFEF3C7),
                          label: 'Hours',
                          onTap: () =>
                              _showHoursModal(context, restaurant),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionTile(
                          icon: Icons.storefront_outlined,
                          iconColor: const Color(0xFF0284C7),
                          iconBgColor: const Color(0xFFE0F2FE),
                          label: 'Account',
                          onTap: () => setState(() => _navIndex = 4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Live Banasree Quick Metrics Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildMetricCol(
                        '${offers.where((o) => o.isActive).length}',
                        'Active Posts',
                        const Color(0xFF1E293B),
                      ),
                    ),
                    _buildMetricDivider(),
                    Expanded(
                      child: _buildMetricCol(
                        '${offers.where((o) => o.isBoosted).length} 🔥',
                        'Boosted',
                        const Color(0xFFFF5722),
                      ),
                    ),
                    _buildMetricDivider(),
                    Expanded(
                      child: _buildMetricCol(
                        '1.8k',
                        'Discovery',
                        const Color(0xFF2563EB),
                      ),
                    ),
                    _buildMetricDivider(),
                    Expanded(
                      child: _buildMetricCol(
                        '4.9 ★',
                        'Rating',
                        const Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Prominent "Post Surplus Food" Button (tested by widget test!)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 19),
                  label: const Text(
                    'Post Surplus Food',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  onPressed: () => _onPostSurplusTapped(context, restaurant),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Recent Active Offers Preview
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      const Text(
                        'Active Surplus Listings',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _navIndex = 0),
                        child: const Text(
                          'View all posts →',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (offers.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Center(
                        child: Text(
                          isComplete
                              ? 'No food offers posted yet. Tap "Post Surplus Food" above!'
                              : 'Complete your restaurant profile to start posting surplus dishes.',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF64748B),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    for (final offer in offers.take(2))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildOfferCard(context, offer, restaurant),
                      ),
                ],
              ),
            ),
          ],
        ),
      );
  }

  // ==========================================
  // TAB 3: INFO ("including top selling post and other data")
  // ==========================================
  Widget _buildInfoTab(
      BuildContext context, Restaurant restaurant, List<FoodOffer> offers) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.insights_rounded,
                    color: Color(0xFF059669),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Café Intelligence & Info',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        'Top-selling dishes, impact metrics & Banasree reach',
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // SECTION 1: TOP SELLING POSTS LEADERBOARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text('🏆', style: TextStyle(fontSize: 20)),
                      SizedBox(width: 8),
                      Text(
                        'Top Selling Surplus Posts',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Ranked by lifetime portions rescued & customer ratings',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 14),

                  _buildTopSellingRow(
                    rank: 1,
                    title: 'Belgium Dark Chocolate Pastry',
                    soldCount: 142,
                    revenue: '${AppConstants.currencySymbol}28,400',
                    rating: '4.9 ★',
                    badge: '#1 BEST SELLER',
                    badgeColor: const Color(0xFFD97706),
                  ),
                  const Divider(height: 18, color: Color(0xFFF1F5F9)),
                  _buildTopSellingRow(
                    rank: 2,
                    title: 'Hazelnut Cappuccino & Croissant',
                    soldCount: 98,
                    revenue: '${AppConstants.currencySymbol}19,600',
                    rating: '4.9 ★',
                    badge: '#2 COFFEE PAIRING',
                    badgeColor: const Color(0xFF2563EB),
                  ),
                  const Divider(height: 18, color: Color(0xFFF1F5F9)),
                  _buildTopSellingRow(
                    rank: 3,
                    title: 'Blue Bell Club Chicken Sandwich',
                    soldCount: 84,
                    revenue: '${AppConstants.currencySymbol}16,800',
                    rating: '4.8 ★',
                    badge: '#3 LUNCH RUSH',
                    badgeColor: const Color(0xFF059669),
                  ),
                  const Divider(height: 18, color: Color(0xFFF1F5F9)),
                  _buildTopSellingRow(
                    rank: 4,
                    title: 'Truffle Beef Lasagna (Surplus Box)',
                    soldCount: 76,
                    revenue: '${AppConstants.currencySymbol}22,800',
                    rating: '5.0 ★',
                    badge: '#4 DINNER HIT',
                    badgeColor: const Color(0xFF7C3AED),
                  ),
                  const Divider(height: 18, color: Color(0xFFF1F5F9)),
                  _buildTopSellingRow(
                    rank: 5,
                    title: 'Artisan Garlic Sourdough Loaf',
                    soldCount: 59,
                    revenue: '${AppConstants.currencySymbol}8,850',
                    rating: '4.7 ★',
                    badge: '#5 BAKERY PICK',
                    badgeColor: const Color(0xFFE11D48),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // SECTION 2: SUSTAINABILITY & IMPACT DATA
            const Text(
              'Environmental Impact Rescued',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildImpactCard(
                    icon: Icons.scale_rounded,
                    color: const Color(0xFF16A34A),
                    value: '214 kg',
                    label: 'Food Rescued',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildImpactCard(
                    icon: Icons.fastfood_rounded,
                    color: const Color(0xFF2563EB),
                    value: '428',
                    label: 'Meals Saved',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildImpactCard(
                    icon: Icons.cloud_done_rounded,
                    color: const Color(0xFF0F766E),
                    value: '535 kg',
                    label: 'CO₂e Abated',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildImpactCard(
                    icon: Icons.water_drop_rounded,
                    color: const Color(0xFF0284C7),
                    value: '85,600 L',
                    label: 'Water Preserved',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // SECTION 3: BANASREE DISCOVERY TELEMETRY
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Banasree Neighborhood Reach',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Live customer discovery stats around House 14, Road 4',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetricCol('3,420', 'Local Views', const Color(0xFF1E293B)),
                        const SizedBox(width: 8),
                        _buildMetricDivider(),
                        const SizedBox(width: 8),
                        _buildMetricCol('312', 'Favorited', const Color(0xFFE11D48)),
                        const SizedBox(width: 8),
                        _buildMetricDivider(),
                        const SizedBox(width: 8),
                        _buildMetricCol('46.8%', 'Repeat Rate', const Color(0xFF16A34A)),
                        const SizedBox(width: 8),
                        _buildMetricDivider(),
                        const SizedBox(width: 8),
                        _buildMetricCol('42 min', 'Avg Sellout', const Color(0xFF2563EB)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // SECTION 4: PEAK ORDERING SURGE WINDOW
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.timer_rounded,
                      color: Color(0xFFB45309),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Peak Ordering Window: 08:30 – 10:30 PM',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF92400E),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '68% of surplus orders occur during late evening café closing hours. Listing deals by 08:00 PM maximizes sell-through.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFFB45309),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 4: ACCOUNT (Organized exactly like User Account Interface + Owner Profile)
  // ==========================================
  Widget _buildAccountTab(
      BuildContext context, Restaurant restaurant, UserProfile? user) {
    final restaurantName = restaurant.name.trim().isNotEmpty
        ? restaurant.name
        : 'Blue Bell Cafe';
    final ownerName = _approvedOwnerName ??
        (user?.fullName?.trim().isNotEmpty == true
            ? user!.fullName!
            : 'Rahman Chowdhury');
    final rawAddress = restaurant.address?.trim();
    final userEmail = user?.email.trim();
    final displaySubtitle = (rawAddress != null &&
            rawAddress.isNotEmpty &&
            !rawAddress.contains('Banasree'))
        ? rawAddress
        : ((userEmail != null && userEmail.isNotEmpty)
            ? userEmail
            : 'partner@savebite.com');

    return Container(
      color: AccountColors.background,
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // 1. WARM PEACH GRADIENT HEADER (Restaurant Profile Header)
            // ==========================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFF8F6),
                    Color(0xFFFFEFEA),
                  ],
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () =>
                        _showRestaurantPreviewSheet(context, restaurant),
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
                      child: restaurant.imageUrl != null &&
                              restaurant.imageUrl!.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                restaurant.imageUrl!,
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => UserAvatar(
                                  name: restaurantName,
                                  radius: 36,
                                ),
                              ),
                            )
                          : UserAvatar(name: restaurantName, radius: 36),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Restaurant Identity & Crimson "View Profile" link
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                restaurantName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E293B),
                                  letterSpacing: -0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified_rounded,
                              size: 16,
                              color: Color(0xFFD97706),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          displaySubtitle,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        GestureDetector(
                          onTap: () =>
                              _showRestaurantPreviewSheet(context, restaurant),
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

            // ==========================================
            // 2. SAVEBITE GOLD MERCHANT CARD (Styled like Super Saver Card)
            // ==========================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              child: InkWell(
                onTap: () => _showGoldSubscriptionModal(context, restaurant),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFF1F5F9),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              restaurant.hasGoldSubscription
                                  ? 'SaveBite Gold Merchant ⭐'
                                  : 'SaveBite Gold Merchant',
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              restaurant.hasGoldSubscription
                                  ? 'Active: 5 monthly boosts & hero banner access'
                                  : 'Unlock exclusive benefits & 3x reach',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildGoldMerchantBadge(restaurant.hasGoldSubscription),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ==========================================
            // PENDING CHANGE REQUEST BANNER (If Change Requested)
            // ==========================================
            if (_pendingChangeRequest != null)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: const Color(0xFFF59E0B), width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.pending_actions_rounded,
                              color: Color(0xFFB45309), size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Change Request Pending Admin Review',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF92400E),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() => _pendingChangeRequest = null);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Change request cancelled.')),
                              );
                            },
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Proposed changes to "${_pendingChangeRequest!['name']}" • Owner: "${_pendingChangeRequest!['ownerName'] ?? 'Owner'}" • Phone: "${_pendingChangeRequest!['phone']}". Will update once approved.',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF78350F),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Demo Simulator Button to preview Admin Approval
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact),
                          onPressed: () {
                            final req = _pendingChangeRequest!;
                            setState(() {
                              if ((req['ownerName'] as String?)?.isNotEmpty ==
                                  true) {
                                _approvedOwnerName = req['ownerName'] as String;
                              }
                              if ((req['tradeLicense'] as String?)?.isNotEmpty ==
                                  true) {
                                _approvedTradeLicense =
                                    req['tradeLicense'] as String;
                              }
                              if ((req['nid'] as String?)?.isNotEmpty == true) {
                                _approvedNid = req['nid'] as String;
                              }
                              if ((req['email'] as String?)?.isNotEmpty == true) {
                                _approvedEmail = req['email'] as String;
                              }
                              _pendingChangeRequest = null;
                            });
                            final current = ref
                                .read(currentRestaurantProvider)
                                .asData
                                ?.value;
                            if (current != null) {
                              final updated = current.copyWith(
                                name: (req['name'] as String?)?.isNotEmpty ==
                                        true
                                    ? req['name'] as String
                                    : current.name,
                                phone: (req['phone'] as String?)?.isNotEmpty ==
                                        true
                                    ? req['phone'] as String
                                    : current.phone,
                                address:
                                    (req['address'] as String?)?.isNotEmpty ==
                                            true
                                        ? req['address'] as String
                                        : current.address,
                                updatedAt: DateTime.now(),
                              );
                              ref
                                  .read(
                                      restaurantActionNotifierProvider.notifier)
                                  .updateProfile(updated);
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    '✓ Admin Approved! Your restaurant and owner information has been updated.'),
                                backgroundColor: Color(0xFF16A34A),
                              ),
                            );
                          },
                          icon: const Icon(Icons.check_circle_outline,
                              size: 14, color: Color(0xFF15803D)),
                          label: const Text(
                            'Demo: Simulate Admin Approval',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF15803D)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ==========================================
            // 3. QUICK ACTION TILES (4 items in balanced row)
            // ==========================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  Expanded(
                    child: _buildActionTile(
                      icon: Icons.person_outline_rounded,
                      iconColor: const Color(0xFF059669),
                      iconBgColor: const Color(0xFFECFDF5),
                      label: 'Owner Profile',
                      onTap: () =>
                          _showOwnerProfileModal(context, restaurant, user),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildActionTile(
                      icon: Icons.edit_note_rounded,
                      iconColor: const Color(0xFF0284C7),
                      iconBgColor: const Color(0xFFF0F9FF),
                      label: 'Update Info',
                      badgeText:
                          _pendingChangeRequest != null ? 'PENDING' : null,
                      onTap: () => _showRequestInfoUpdateModal(
                          context, restaurant, user),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildActionTile(
                      icon: Icons.campaign_outlined,
                      iconColor: const Color(0xFFD97706),
                      iconBgColor: const Color(0xFFFFFBEB),
                      badgeText: 'OFFERS',
                      label: 'Ad Packages',
                      onTap: () => setState(() => _navIndex = 1),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildActionTile(
                      icon: Icons.headset_mic_outlined,
                      iconColor: const Color(0xFF7C3AED),
                      iconBgColor: const Color(0xFFF5F3FF),
                      label: 'Support',
                      onTap: () => _showMerchantHelpModal(context),
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
                  // Section 1 Header: Business & Credentials
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
                          'BUSINESS & CREDENTIALS',
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

                  // Card 1: Credentials & Business Settings
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
                          icon: Icons.badge_outlined,
                          iconColor: const Color(0xFF059669),
                          iconBgColor: const Color(0xFFECFDF5),
                          title: 'Owner Profile',
                          subtitle: '$ownerName • Legal Representative',
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20)),
                          trailing: restaurant.isApproved
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFF86EFAC)
                                          .withValues(alpha: 0.7),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle_rounded,
                                        size: 11,
                                        color: Color(0xFF15803D),
                                      ),
                                      SizedBox(width: 3.5),
                                      Text(
                                        'VERIFIED',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF15803D),
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : null,
                          onTap: () =>
                              _showOwnerProfileModal(context, restaurant, user),
                        ),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          indent: 70,
                          endIndent: 16,
                          color: Color(0xFFF1F5F9),
                        ),
                        _buildMenuItem(
                          icon: Icons.edit_note_rounded,
                          iconColor: const Color(0xFF2563EB),
                          iconBgColor: const Color(0xFFEFF6FF),
                          title: 'Request Info Update (Admin Review)',
                          subtitle: _pendingChangeRequest != null
                              ? '1 update request pending admin approval'
                              : 'Changes to Name, Address & Phone require verification',
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: _pendingChangeRequest != null
                                  ? const Color(0xFFFEF3C7)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _pendingChangeRequest != null
                                    ? const Color(0xFFFCD34D)
                                    : const Color(0xFFE2E8F0),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _pendingChangeRequest != null
                                      ? Icons.schedule_rounded
                                      : Icons.lock_outline_rounded,
                                  size: 10,
                                  color: _pendingChangeRequest != null
                                      ? const Color(0xFFB45309)
                                      : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 3.5),
                                Text(
                                  _pendingChangeRequest != null
                                      ? 'PENDING'
                                      : 'PROTECTED',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: _pendingChangeRequest != null
                                        ? const Color(0xFFB45309)
                                        : const Color(0xFF64748B),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          onTap: () =>
                              _showRequestInfoUpdateModal(context, restaurant, user),
                        ),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          indent: 70,
                          endIndent: 16,
                          color: Color(0xFFF1F5F9),
                        ),
                        _buildMenuItem(
                          icon: Icons.stars_rounded,
                          iconColor: const Color(0xFFD97706),
                          iconBgColor: const Color(0xFFFFFBEB),
                          title: 'SaveBite Gold Subscription',
                          subtitle: restaurant.hasGoldSubscription
                              ? 'Active • 5 monthly boosts & banner access'
                              : 'Upgrade to boost dishes & get 3x reach',
                          borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(20)),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: restaurant.hasGoldSubscription
                                  ? const Color(0xFFFEF3C7)
                                  : const Color(0xFFFFF1F2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: restaurant.hasGoldSubscription
                                    ? const Color(0xFFFCD34D)
                                    : const Color(0xFFFECDD3),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  restaurant.hasGoldSubscription
                                      ? Icons.star_rounded
                                      : Icons.arrow_upward_rounded,
                                  size: 10,
                                  color: restaurant.hasGoldSubscription
                                      ? const Color(0xFFB45309)
                                      : const Color(0xFFE11D48),
                                ),
                                const SizedBox(width: 3.5),
                                Text(
                                  restaurant.hasGoldSubscription
                                      ? 'ACTIVE'
                                      : 'UPGRADE',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: restaurant.hasGoldSubscription
                                        ? const Color(0xFFB45309)
                                        : const Color(0xFFE11D48),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          onTap: () =>
                              _showGoldSubscriptionModal(context, restaurant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Section 2 Header: App & System
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
                          'APP & SYSTEM',
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

                  // Card 2: App & System Settings
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
                          icon: Icons.info_outline_rounded,
                          iconColor: const Color(0xFF475569),
                          iconBgColor: const Color(0xFFF1F5F9),
                          title: 'About',
                          subtitle: 'Version 1.1.0 • App Info & Impact',
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20)),
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
                          subtitle: 'Sign out of restaurant management session',
                          borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(20)),
                          onTap: () => _confirmLogout(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Delete Account Button (Premium Destructive Action Card)
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
                            'Delete Account',
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
          ],
        ),
      ),
    ),
  );
}

  // ==========================================
  // ABOUT SAVEBITE MODAL (Directly Following Customer Account About)
  // ==========================================
  void _showAboutModal(BuildContext context) {
    _showSheet<void>(
      builder: (ctx) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.88,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                          'Smart Surplus Food Rescue Platform',
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
                          child: const Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
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
                            Expanded(
                              child: Text(
                                'About SaveBite',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'SaveBite is a mission-driven surplus food rescue platform founded to combat urban food waste in Bangladesh. Every single day, freshly cooked meals and quality baked items remain unsold. SaveBite connects conscious customers with trusted restaurants, cafes, and bakeries across Dhaka, making high-quality surplus meals accessible at 50% to 70% discounts before closing time.',
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

                  // Key Impact Metrics Grid
                  const Text(
                    'Our Community Impact',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildAboutStatCard(
                          icon: Icons.restaurant_rounded,
                          title: '10,000+',
                          subtitle: 'Meals Rescued',
                          color: const Color(0xFFE11D48),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildAboutStatCard(
                          icon: Icons.eco_rounded,
                          title: '15+ Tons',
                          subtitle: 'CO₂ Prevented',
                          color: const Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildAboutStatCard(
                          icon: Icons.savings_outlined,
                          title: '৳2.5M+',
                          subtitle: 'Saved by Users',
                          color: const Color(0xFF0284C7),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildAboutStatCard(
                          icon: Icons.storefront_outlined,
                          title: '150+',
                          subtitle: 'Partner Outlets',
                          color: const Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // App Features & Details
                  const Text(
                    'Key Features',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildAboutFeatureTile(
                    icon: Icons.local_fire_department_rounded,
                    color: const Color(0xFFEA580C),
                    title: 'Hot Deals & Mystery Bags',
                    description:
                        'Rescue daily surplus bags with freshly prepared dishes at unbeatable prices.',
                  ),
                  _buildAboutFeatureTile(
                    icon: Icons.near_me_rounded,
                    color: const Color(0xFF0284C7),
                    title: 'Dhaka Neighborhood Coverage',
                    description:
                        'Discover nearby partner restaurants in Mirpur, Dhanmondi, Gulshan, Banani, and Uttara.',
                  ),
                  _buildAboutFeatureTile(
                    icon: Icons.workspace_premium_rounded,
                    color: const Color(0xFFE11D48),
                    title: 'Super Saver Membership',
                    description:
                        'Enjoy free deliveries, extra 10% discounts, and 15-minute priority deal drops.',
                  ),
                  _buildAboutFeatureTile(
                    icon: Icons.qr_code_2_rounded,
                    color: const Color(0xFF15803D),
                    title: 'Seamless Contactless Pickup',
                    description:
                        'Pick up meals quickly with secure digital verification and order tracking.',
                  ),
                  const SizedBox(height: 20),

                  // Technical Specs & Organization
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SaveBite Technologies Ltd.',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Dhaka, Bangladesh • Made with ❤️ for sustainable living',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Email: support@savebite.com • Helpline: +880 1700-112233',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '© 2026 SaveBite Technologies Ltd. All rights reserved.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
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
                      onPressed: () => Navigator.of(ctx).pop(),
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
    );
  }

  // ==========================================
  // SHARED BUILDERS & HELPERS (Matching Customer Profile Screen)
  // ==========================================

  Widget _buildAboutStatCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutFeatureTile({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
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
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoldMerchantBadge(bool hasGold) {
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
            hasGold ? 'GOLD' : 'BECOME',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 0.5,
              color: Color(0xFFE11D48),
            ),
          ),
          Text(
            hasGold ? 'ACTIVE' : 'GOLD',
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 0.5,
              color: Color(0xFFBE123C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color iconColor = const Color(0xFFE11D48),
    Color iconBgColor = const Color(0xFFFFEDEC),
    String? badgeText,
    Color? badgeColor,
    Color? badgeTextColor,
    Color? tileBgColor,
    Color? textColor,
    bool isDisabled = false,
  }) {
    final effectiveTileBg =
        isDisabled ? const Color(0xFFF8FAFC) : (tileBgColor ?? Colors.white);
    final effectiveBorderColor = isDisabled
        ? const Color(0xFFCBD5E1)
        : const Color(0xFFE2E8F0).withValues(alpha: 0.8);
    final effectiveIconColor =
        isDisabled ? const Color(0xFF94A3B8) : iconColor;
    final effectiveIconBgColor =
        isDisabled ? const Color(0xFFF1F5F9) : iconBgColor;
    final effectiveTextColor = isDisabled
        ? const Color(0xFF64748B)
        : (textColor ?? const Color(0xFF1E293B));
    final effectiveBadgeColor = badgeColor ??
        (isDisabled ? const Color(0xFF64748B) : const Color(0xFFFF5722));
    final effectiveBadgeTextColor = badgeTextColor ?? Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 84,
          decoration: BoxDecoration(
            color: effectiveTileBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: effectiveBorderColor,
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
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: effectiveIconBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(icon, size: 20, color: effectiveIconColor),
                    ),
                  ),
                  if (badgeText != null)
                    Positioned(
                      top: -4,
                      right: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: effectiveBadgeColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            color: effectiveBadgeTextColor,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: effectiveTextColor,
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

  Widget _buildTopSellingRow({
    required int rank,
    required String title,
    required int soldCount,
    required String revenue,
    required String rating,
    required String badge,
    required Color badgeColor,
  }) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: badgeColor,
              ),
            ),
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
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '$soldCount sold • $revenue rescued • $rating',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            badge,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: badgeColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImpactCard({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCol(String value, String label, Color valueColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: valueColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildMetricDivider() {
    return Container(
      width: 1,
      height: 24,
      color: const Color(0xFFE2E8F0),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildOfferCard(
      BuildContext context, FoodOffer offer, Restaurant restaurant) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: offer.isBoosted
              ? const Color(0xFFFF5722).withValues(alpha: 0.4)
              : const Color(0xFFE2E8F0),
          width: offer.isBoosted ? 1.5 : 1,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  offer.imageUrl ?? '',
                  width: 76,
                  height: 76,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 76,
                    height: 76,
                    color: const Color(0xFFF1F5F9),
                    child: const Icon(Icons.fastfood_rounded,
                        color: AppColors.textSecondary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            offer.title,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (offer.isBoosted)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF5722), Color(0xFFFF9800)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '🔥 BOOSTED',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Category: ${offer.category} • ${offer.quantity} available',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '${AppConstants.currencySymbol}${offer.discountedPrice.toInt()}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${AppConstants.currencySymbol}${offer.originalPrice.toInt()}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF94A3B8),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Save ${AppConstants.currencySymbol}${offer.savings.toInt()}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Actions row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Boost button
              InkWell(
                onTap: () async {
                  if (offer.isBoosted) {
                    await ref
                        .read(restaurantActionNotifierProvider.notifier)
                        .unboostOffer(offer.id);
                  } else {
                    await ref
                        .read(restaurantActionNotifierProvider.notifier)
                        .boostOffer(offer.id);
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          offer.isBoosted
                              ? 'Boost paused.'
                              : '🚀 "${offer.title}" boosted!',
                        ),
                        backgroundColor: offer.isBoosted
                            ? const Color(0xFF475569)
                            : const Color(0xFFFF5722),
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: offer.isBoosted
                        ? const Color(0xFFFFEDE6)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: offer.isBoosted
                          ? const Color(0xFFFF5722).withValues(alpha: 0.3)
                          : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_fire_department_rounded,
                        size: 14,
                        color: offer.isBoosted
                            ? const Color(0xFFFF5722)
                            : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        offer.isBoosted ? 'Boosted' : 'Boost',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: offer.isBoosted
                              ? const Color(0xFFFF5722)
                              : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Active / Inactive toggle
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  offer.isActive
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 19,
                  color: offer.isActive
                      ? const Color(0xFF16A34A)
                      : const Color(0xFF94A3B8),
                ),
                tooltip: offer.isActive ? 'Deactivate' : 'Activate',
                onPressed: () async {
                  await ref
                      .read(restaurantActionNotifierProvider.notifier)
                      .toggleOfferStatus(offer.id, !offer.isActive);
                },
              ),

              // Delete button (tested by widget test!)
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 19, color: AppColors.error),
                tooltip: 'Delete Post',
                onPressed: () async {
                  final confirmed = await ConfirmDialog.show(
                    context,
                    title: 'Delete Food Post',
                    message: 'Are you sure you want to remove "${offer.title}"?',
                    confirmLabel: 'Delete',
                  );
                  if (confirmed) {
                    await ref
                        .read(restaurantActionNotifierProvider.notifier)
                        .deleteOffer(offer.id);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MODAL SHEETS FOR GOLD, HERO, HOURS, GUIDELINES, HELP, PREVIEW
  // ==========================================
  void _showGoldSubscriptionModal(BuildContext context, Restaurant restaurant) {
    _showSheet<void>(
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final isSubscribed = restaurant.hasGoldSubscription;

            return Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFB45309), Color(0xFFD97706), Color(0xFFF59E0B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.workspace_premium_rounded,
                              color: Colors.white, size: 36),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  restaurant.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const Text(
                                  'SaveBite Gold Merchant',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildBenefitItem(
                      icon: Icons.local_fire_department_rounded,
                      color: const Color(0xFFFF5722),
                      title: 'Boost Surplus Posts (🔥)',
                      description: 'Top placement in search and hot deals feeds.',
                    ),
                    _buildBenefitItem(
                      icon: Icons.view_carousel_rounded,
                      color: const Color(0xFF2563EB),
                      title: 'Homepage Hero Banner',
                      description: 'Feature your café on the customer home slideshow.',
                    ),
                    _buildBenefitItem(
                      icon: Icons.verified_rounded,
                      color: const Color(0xFFD97706),
                      title: 'Verified Gold Merchant Badge',
                      description: 'Instant customer trust in Banasree.',
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: isSubscribed
                              ? const Color(0xFF475569)
                              : const Color(0xFFD97706),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          Navigator.of(ctx).pop();
                          if (isSubscribed) {
                            final confirm = await ConfirmDialog.show(
                              context,
                              title: 'Cancel Gold Subscription?',
                              message:
                                  'Are you sure you want to cancel your SaveBite Gold Merchant subscription? Hero banner placement and boost quotas will be discontinued.',
                              confirmLabel: 'Cancel Plan',
                            );
                            if (confirm == true) {
                              setState(() => _hasActive24hBanner = false);
                              await ref
                                  .read(restaurantActionNotifierProvider.notifier)
                                  .updateSubscription(
                                    isPremium: false,
                                    plan: null,
                                    boostCredits: 0,
                                    bannerCredits: 0,
                                    hasActiveBanner: false,
                                  );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Gold subscription canceled.'),
                                    backgroundColor: Color(0xFF64748B),
                                  ),
                                );
                              }
                            }
                            return;
                          }

                          // Not subscribed: TAKE THEM TO SECURE PAYMENT PORTAL!
                          final payResult = await showPaymentPortalSheet(
                            context: context,
                            title: 'SaveBite Gold Merchant Subscription',
                            subtitle: '1 Month (30 Days) • Auto-Renews',
                            amount: 999.0,
                            customerOrBusinessName: restaurant.name,
                            perkHighlights: const [
                              '1 Homepage Hero Banner Placement',
                              '5 Priority Meal Boosts (🔥)',
                              'Verified Gold Merchant Badge',
                              'Top Placement in Banasree Feeds',
                            ],
                            itemType: 'restaurant_subscription',
                          );

                          if (payResult != null && payResult.isSuccess) {
                            // ONLY UNLOCK UPON VERIFIED PAYMENT!
                            setState(() => _hasActive24hBanner = true);
                            await ref
                                .read(restaurantActionNotifierProvider.notifier)
                                .updateSubscription(
                                  isPremium: true,
                                  plan: 'gold',
                                  boostCredits: 5,
                                  bannerCredits: 1,
                                  hasActiveBanner: true,
                                );

                            ref
                                .read(adminFinancialProvider.notifier)
                                .recordSubscriptionPayment(
                                  payerName: '${restaurant.name} (Partner)',
                                  payerType: 'restaurant',
                                  planName: 'Gold Merchant Monthly',
                                  amount: 999.0,
                                  paymentGateway: payResult.gateway ?? 'bKash',
                                  transactionId:
                                      payResult.transactionId ?? 'TXN-GM-991',
                                );

                            await ref
                                .read(restaurantNotificationsProvider.notifier)
                                .notifyGoldMerchant(
                                  restaurantId: restaurant.id,
                                  restaurantName: restaurant.name,
                                );

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '🎉 Payment Approved via ${payResult.gateway}! SaveBite Gold Merchant unlocked! ✨',
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
                                    'Payment was not completed. Gold features remain locked.',
                                  ),
                                  backgroundColor: Color(0xFF64748B),
                                ),
                              );
                            }
                          }
                        },
                        child: Text(
                          isSubscribed
                              ? 'Manage Subscription'
                              : 'Upgrade (${AppConstants.currencySymbol}999/mo)',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showBoostOffersModal(
      BuildContext context, List<FoodOffer> offers, Restaurant restaurant) {
    _showSheet<void>(
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.local_fire_department_rounded,
                    color: Color(0xFFFF5722), size: 24),
                SizedBox(width: 10),
                Text(
                  'Select Dish to Boost',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (offers.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No food offers posted yet. Post a surplus dish first!',
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: offers.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (itemCtx, idx) {
                    final offer = offers[idx];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                      tileColor: const Color(0xFFF8FAFC),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: offer.isBoosted
                              ? const Color(0xFFFF5722)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      leading: const Icon(Icons.fastfood_rounded,
                          color: Color(0xFF475569)),
                      title: Text(offer.title,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                      subtitle: Text(
                          '${AppConstants.currencySymbol}${offer.discountedPrice.toInt()} • ${offer.isBoosted ? "Boosted 🔥" : "Standard"}'),
                      trailing: FilledButton(
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          backgroundColor: offer.isBoosted
                              ? const Color(0xFFFF5722)
                              : const Color(0xFF0F172A),
                        ),
                        onPressed: () async {
                          Navigator.of(ctx).pop();
                          if (offer.isBoosted) {
                            await ref
                                .read(restaurantActionNotifierProvider.notifier)
                                .unboostOffer(offer.id);
                          } else {
                            await ref
                                .read(restaurantActionNotifierProvider.notifier)
                                .boostOffer(offer.id);
                          }
                        },
                        child: Text(offer.isBoosted ? 'Boosted' : 'Boost'),
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

  // ==========================================
  // NOTIFICATION BELL & PARTNER NOTIFICATIONS SHEET
  // ==========================================
  Widget _buildNotificationBell(BuildContext context) {
    final notifsAsync = ref.watch(restaurantNotificationsProvider);
    final notifs = notifsAsync.asData?.value ?? [];
    final unreadCount = notifs.where((n) => !n.isRead).length;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showRestaurantNotificationsSheet(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_outlined,
                size: 20,
                color: Color(0xFF334155),
              ),
              if (unreadCount > 0)
                Positioned(
                  top: -5,
                  right: -5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE11D48),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Center(
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRestaurantNotificationsSheet(BuildContext context) {
    _showSheet<void>(
      builder: (ctx) => Consumer(
        builder: (sheetCtx, sheetRef, _) {
          final notifsAsync = sheetRef.watch(restaurantNotificationsProvider);
          final notifs = notifsAsync.asData?.value ?? [];
          final unreadCount = notifs.where((n) => !n.isRead).length;

          return Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: Color(0xFF4F46E5),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Partner Notifications',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            unreadCount > 0
                                ? '$unreadCount unread updates'
                                : 'All notifications read',
                            style: TextStyle(
                              fontSize: 12,
                              color: unreadCount > 0
                                  ? const Color(0xFFE11D48)
                                  : const Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (unreadCount > 0)
                      TextButton(
                        onPressed: () {
                          sheetRef
                              .read(restaurantNotificationsProvider.notifier)
                              .markAllRead();
                        },
                        child: const Text('Mark all read'),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (notifs.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.notifications_none_rounded,
                            size: 36, color: Color(0xFF94A3B8)),
                        SizedBox(height: 8),
                        Text(
                          'No notifications yet',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xFF475569),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'You will receive notifications when your hero banner starts or ends.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(sheetCtx).size.height * 0.55,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: notifs.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (itemCtx, idx) {
                        final notif = notifs[idx];
                        Color iconBg;
                        Color iconColor;
                        IconData icon;

                        switch (notif.type) {
                          case 'banner_started':
                            iconBg = const Color(0xFFDCFCE7);
                            iconColor = const Color(0xFF16A34A);
                            icon = Icons.campaign_rounded;
                            break;
                          case 'banner_ended':
                            iconBg = const Color(0xFFDBEAFE);
                            iconColor = const Color(0xFF2563EB);
                            icon = Icons.flag_rounded;
                            break;
                          case 'gold_merchant':
                            iconBg = const Color(0xFFFEF3C7);
                            iconColor = const Color(0xFFD97706);
                            icon = Icons.workspace_premium_rounded;
                            break;
                          default:
                            iconBg = const Color(0xFFF1F5F9);
                            iconColor = const Color(0xFF64748B);
                            icon = Icons.info_outline_rounded;
                        }

                        return InkWell(
                          onTap: () {
                            sheetRef
                                .read(restaurantNotificationsProvider.notifier)
                                .markAsRead(notif.id);
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: notif.isRead
                                  ? const Color(0xFFF8FAFC)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: notif.isRead
                                    ? const Color(0xFFE2E8F0)
                                    : const Color(0xFFBFDBFE),
                                width: notif.isRead ? 1.0 : 1.5,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: iconBg,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(icon, color: iconColor, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              notif.title,
                                              style: TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: notif.isRead
                                                    ? FontWeight.w600
                                                    : FontWeight.w800,
                                                color: const Color(0xFF1E293B),
                                              ),
                                            ),
                                          ),
                                          if (!notif.isRead)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFE11D48),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        notif.message,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF475569),
                                          height: 1.35,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _formatRelativeTime(notif.createdAt),
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          color: Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatRelativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  // ==========================================
  // HERO BANNER LOCKED MODAL (FOR NORMAL RESTAURANTS)
  // ==========================================
  void _showHeroBannerLockedModal(BuildContext context, Restaurant restaurant) {
    _showSheet<void>(
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      color: Color(0xFFE11D48),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hero Banner Locked',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          'Exclusive feature for Gold Merchants & Promo Ad buyers',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Text(
                  'The Homepage Hero Banner carousel showcases premium restaurants to thousands of food savers daily in Dhaka. Normal accounts cannot post hero banners. You can unlock this feature through either of the following 2 options:',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF334155),
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Option 1: Gold Merchant Subscription
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.workspace_premium_rounded,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Option 1: Gold Merchant Upgrade',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                              Text(
                                '৳999 / month • Includes 1 Hero Banner Ad + 5 Post Boosts',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFD97706),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _showGoldSubscriptionModal(context, restaurant);
                        },
                        child: const Text(
                          'Upgrade to Gold Merchant (৳999/mo)',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Option 2: Buy from Offers tab
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.view_carousel_rounded,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Option 2: Buy Banner Package from Offers',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E40AF),
                                ),
                              ),
                              Text(
                                '৳2,000 / 24 Hours • 12,500+ customer views on Dhaka homepage',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          setState(() => _navIndex = 1); // Switch to Offers tab
                        },
                        child: const Text(
                          'View Ad Packages in Offers Tab',
                          style: TextStyle(fontWeight: FontWeight.w700),
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
    );
  }

  // ==========================================
  // HERO BANNER MODAL (DESIGN, IMAGE, & ADMIN APPROVAL)
  // ==========================================
  void _showHeroBannerModal(BuildContext context, Restaurant restaurant) {
    final titleController = TextEditingController(
      text: '20% OFF SURPLUS FEAST AT ${restaurant.name.toUpperCase()}',
    );
    final subtitleController = TextEditingController(
      text: 'Freshly prepared specialty dishes rescued daily in ${restaurant.area ?? "Dhaka"}.',
    );
    final badgeController = TextEditingController(text: '🔥 SPECIAL OFFER');
    String selectedTheme = 'yellow';
    String currentImageUrl = restaurant.imageUrl ??
        'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=900&auto=format&fit=crop&q=80';
    bool isSubmitting = false;

    final presetImages = [
      {
        'label': 'Bakery & Pastry',
        'url':
            'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=900&auto=format&fit=crop&q=80',
      },
      {
        'label': 'Coffee & Café',
        'url':
            'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=900&auto=format&fit=crop&q=80',
      },
      {
        'label': 'Gourmet Feast',
        'url':
            'https://images.unsplash.com/photo-1551183053-bf91a1d81141?w=900&auto=format&fit=crop&q=80',
      },
      {
        'label': 'Surplus Dishes',
        'url':
            'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=900&auto=format&fit=crop&q=80',
      },
    ];

    _showSheet<void>(
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          final themeInfo = PromoBanner.availableThemes[selectedTheme] ??
              PromoBanner.availableThemes['coffee'] ??
              PromoBanner.availableThemes.values.first;

          final allBanners =
              ref.watch(promoBannersControllerProvider).asData?.value ?? [];
          final partnerBanners = allBanners
              .where((b) =>
                  b.restaurantId == restaurant.id ||
                  (b.restaurantName != null &&
                      b.restaurantName == restaurant.name))
              .toList();
          final pendingBanner =
              partnerBanners.where((b) => b.isPending).firstOrNull;
          final activeBanner =
              partnerBanners.where((b) => b.isApproved).firstOrNull;

          return Container(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(modalCtx).viewInsets.bottom + 28,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Header with Quota & Verification
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.view_carousel_rounded,
                          color: Color(0xFF4F46E5),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Homepage Hero Banner',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              restaurant.hasGoldSubscription
                                  ? 'Gold Merchant Access • Requires Admin Approval'
                                  : 'Ad Package Active • Requires Admin Approval',
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
                  const SizedBox(height: 14),

                  // Status indicator if pending or active
                  if (pendingBanner != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.hourglass_top_rounded,
                              color: Color(0xFFD97706), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '⏳ Banner Pending Admin Review',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12.5,
                                    color: Color(0xFF92400E),
                                  ),
                                ),
                                Text(
                                  'Headline: "${pendingBanner.title}". You will receive a notification the moment admin approves it.',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFFB45309),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (activeBanner != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: Color(0xFF16A34A), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '🟢 Banner is Live on Customer Home',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12.5,
                                    color: Color(0xFF15803D),
                                  ),
                                ),
                                Text(
                                  'Currently seen by customers in Dhaka. You will receive a notification when the campaign ends.',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF166534),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // LIVE CAROUSEL PREVIEW CARD
                  const Text(
                    'LIVE CUSTOMER HOMEPAGE PREVIEW',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          // Background Image
                          Positioned.fill(
                            child: Image.network(
                              currentImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: const Color(0xFF1E293B),
                                child: const Icon(
                                  Icons.image_outlined,
                                  color: Colors.white54,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                          // Dark gradient overlay for readability
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withValues(alpha: 0.85),
                                    Colors.black.withValues(alpha: 0.45),
                                    Colors.black.withValues(alpha: 0.2),
                                  ],
                                  begin: Alignment.bottomLeft,
                                  end: Alignment.topRight,
                                ),
                              ),
                            ),
                          ),
                          // Content Overlay
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (badgeController.text.trim().isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE11D48),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      badgeController.text.trim(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 5),
                                Text(
                                  titleController.text.trim().isEmpty
                                      ? 'Banner Headline'
                                      : titleController.text.trim(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  subtitleController.text.trim().isEmpty
                                      ? 'Description of your featured offer'
                                      : subtitleController.text.trim(),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 1. HEADLINE
                  const Text(
                    '1. Headline',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: 'e.g. 20% Off Weekend Buffet Feast',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                    ),
                    onChanged: (_) => setModalState(() {}),
                  ),
                  const SizedBox(height: 12),

                  // 2. DESCRIPTION
                  const Text(
                    '2. Description',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: subtitleController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText:
                          'e.g. Freshly handcrafted lasagna and pastries in Banasree',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                    ),
                    onChanged: (_) => setModalState(() {}),
                  ),
                  const SizedBox(height: 12),

                  // 3. BADGE / OFFER TAG
                  const Text(
                    '3. Badge Tag (Optional)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: badgeController,
                    decoration: InputDecoration(
                      hintText: 'e.g. 🔥 20% OFF SURPLUS',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                    ),
                    onChanged: (_) => setModalState(() {}),
                  ),
                  const SizedBox(height: 14),

                  // 4. BANNER DESIGN (IMAGE)
                  const Text(
                    '4. Banner Design (Image)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Image Upload Button & Presets
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: const BorderSide(color: Color(0xFF4F46E5)),
                          ),
                          icon: const Icon(Icons.add_photo_alternate_rounded,
                              size: 18, color: Color(0xFF4F46E5)),
                          label: const Text(
                            'Pick From Gallery',
                            style: TextStyle(
                              color: Color(0xFF4F46E5),
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                          onPressed: () async {
                            final picked =
                                await pickImageWithPermission(modalCtx);
                            if (picked != null) {
                              setModalState(() {
                                currentImageUrl = picked;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Quick presets
                  const Text(
                    'Or select a professionally curated banner design:',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: presetImages.map((preset) {
                        final isSelected = currentImageUrl == preset['url'];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(preset['label']!),
                            selected: isSelected,
                            selectedColor: const Color(0xFFEEF2FF),
                            labelStyle: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? const Color(0xFF4F46E5)
                                  : const Color(0xFF475569),
                            ),
                            onSelected: (val) {
                              if (val) {
                                setModalState(() {
                                  currentImageUrl = preset['url']!;
                                });
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ADMIN APPROVAL INFO NOTICE
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 18, color: Color(0xFF64748B)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Note: Banners are submitted to Admin for quality check. You will receive an in-app notification when the banner starts and ends.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF475569),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // SUBMIT BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, size: 18),
                      label: Text(
                        isSubmitting
                            ? 'Submitting...'
                            : 'Submit Banner for Admin Approval',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final headline = titleController.text.trim();
                              final subtitle = subtitleController.text.trim();
                              if (headline.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter a headline.'),
                                  ),
                                );
                                return;
                              }

                              setModalState(() => isSubmitting = true);

                              final banner = PromoBanner(
                                id: 'banner_${restaurant.id}_${DateTime.now().millisecondsSinceEpoch}',
                                name: headline,
                                title: headline,
                                subtitle: subtitle,
                                badge: badgeController.text.trim().isNotEmpty
                                    ? badgeController.text.trim()
                                    : 'PARTNER SPECIAL',
                                themeKey: selectedTheme,
                                bgStartColor: themeInfo.start,
                                bgEndColor: themeInfo.end,
                                ctaText: 'Visit ${restaurant.name}',
                                targetRoute:
                                    '/customer/restaurant/${restaurant.id}',
                                imageUrl: currentImageUrl,
                                restaurantId: restaurant.id,
                                restaurantName: restaurant.name,
                                status: 'pending',
                                createdAt: DateTime.now(),
                              );

                              final ok = await ref
                                  .read(
                                      restaurantActionNotifierProvider.notifier)
                                  .submitHeroBanner(banner);

                              if (context.mounted) {
                                Navigator.of(ctx).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      ok
                                          ? '🎉 Banner submitted for Admin Approval! You will receive a notification when it goes live.'
                                          : 'Failed to submit banner. Please try again.',
                                    ),
                                    backgroundColor: ok
                                        ? const Color(0xFF0F172A)
                                        : const Color(0xFFDC2626),
                                  ),
                                );
                              }
                            },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  void _showHoursModal(BuildContext context, Restaurant restaurant) {
    _showSheet<void>(
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Café Operating Hours & Status',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 14),
            ListTile(
              leading: const Icon(Icons.wb_sunny_outlined, color: Color(0xFFD97706)),
              title: const Text('Opening Time'),
              trailing: Text(restaurant.openingTime ?? '07:30 AM',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
            ListTile(
              leading: const Icon(Icons.nightlight_outlined, color: Color(0xFF4F46E5)),
              title: const Text('Closing Time'),
              trailing: Text(restaurant.closingTime ?? '11:00 PM',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  void _showMerchantHelpModal(BuildContext context) {
    _showSheet<void>(
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Merchant Support Hub',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 14),
            _buildMenuItem(
              icon: Icons.phone_outlined,
              iconColor: const Color(0xFF16A34A),
              iconBgColor: const Color(0xFFDCFCE7),
              title: 'Hotline: +880 1711234567',
              subtitle: 'Daily 08:00 AM – 11:00 PM for Banasree',
              onTap: () {},
            ),
            _buildMenuItem(
              icon: Icons.email_outlined,
              iconColor: const Color(0xFF2563EB),
              iconBgColor: const Color(0xFFDBEAFE),
              title: 'Email: merchants@savebite.com',
              subtitle: 'Responses within 2 hours',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  void _showRestaurantPreviewSheet(BuildContext context, Restaurant restaurant) {
    _showSheet<void>(
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.85,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                restaurant.imageUrl ?? '',
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  height: 150,
                  color: const Color(0xFFF1F5F9),
                  child: const Icon(Icons.storefront, size: 48, color: Color(0xFF94A3B8)),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              restaurant.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              restaurant.address ?? 'House 14, Road 4, Block D, Banasree, Dhaka',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.push(AppRoutes.restaurantProfile);
                },
                child: const Text('Edit Full Restaurant Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                Text(description,
                    style: const TextStyle(
                        fontSize: 11.5, color: Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
