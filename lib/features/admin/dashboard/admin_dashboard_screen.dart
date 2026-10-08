import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/platform_file_picker.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../restaurant/notifications/restaurant_notification_controller.dart';
import '../../shared/data/promo_banner_controller.dart';
import '../../shared/models/promo_banner.dart';

/// Admin Command Center & Platform Management Portal
///
/// Clean, polished, and unified with Customer & Restaurant design systems:
/// - Signature SaveBite Light Theme (`AppColors.background`, white cards, clean borders)
/// - Floating SaveBite Navigation Bar (Overview, Partners, Posts, Banners, System)
/// - High-visibility Command Cockpit with Realtime Telemetry & KPI Cards
/// - 12-Item Quick Access Symbols Grid matching app action tiles
/// - Partner Restaurant Verification & Approvals Engine
/// - Posts Deal Moderation & 24h Boost Monitor
/// - Promotional Hero Carousel Banner Studio
/// - Voucher & Campaign Manager
/// - System Diagnostics & 14-Table Supabase Architecture Monitor
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  // Navigation: 0 = Overview, 1 = Partners, 2 = Posts, 3 = Banners, 4 = System
  int _currentTab = 0;
  bool _isNavVisible = true;

  // Filters & Search
  String _restaurantFilter = 'all'; // 'all', 'pending', 'verified', 'suspended'
  String _offerFilter = 'all'; // 'all', 'active', 'boosted', 'blocked'
  final TextEditingController _restaurantSearchCtrl = TextEditingController();
  final TextEditingController _offerSearchCtrl = TextEditingController();

  // Local mutable state for interactive admin operations
  late List<Map<String, dynamic>> _restaurantsData;
  late List<Map<String, dynamic>> _offersData;
  late List<Map<String, dynamic>> _vouchersData;
  late List<Map<String, dynamic>> _verificationRequests;
  late List<Map<String, dynamic>> _staffMembers;
  String _selectedStaffRole = AppConstants.roleHeadAdmin;

  @override
  void initState() {
    super.initState();
    _initMockData();
  }

  @override
  void dispose() {
    _restaurantSearchCtrl.dispose();
    _offerSearchCtrl.dispose();
    super.dispose();
  }

  void _initMockData() {
    _restaurantsData = [
      {
        'id': 'rest-1',
        'name': "Sultan's Dine",
        'cuisine': 'Biryani & Kebabs',
        'area': 'Dhanmondi',
        'division': 'Dhaka',
        'phone': '01711223344',
        'tradeLicense': 'TRAD/DSCC/019284/2024',
        'nid': 'NID-8291-0021-4912',
        'status': 'approved',
        'isVerified': true,
        'isPremium': true,
        'rating': 4.9,
        'offersCount': 4,
        'imageUrl':
            'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400',
      },
      {
        'id': 'rest-2',
        'name': 'Chillox Burgers',
        'cuisine': 'Gourmet Fast Food',
        'area': 'Banani',
        'division': 'Dhaka',
        'phone': '01822334455',
        'tradeLicense': 'TRAD/DNCC/088192/2023',
        'nid': 'NID-4421-9988-1029',
        'status': 'approved',
        'isVerified': true,
        'isPremium': false,
        'rating': 4.8,
        'offersCount': 3,
        'imageUrl':
            'https://images.unsplash.com/photo-1550547660-d9450f859349?w=400',
      },
      {
        'id': 'rest-3',
        'name': 'Bread & Beyond Bakery',
        'cuisine': 'Pastries & Breads',
        'area': 'Gulshan',
        'division': 'Dhaka',
        'phone': '01933445566',
        'tradeLicense': 'TRAD/DNCC/041120/2024',
        'nid': 'NID-1982-3344-9021',
        'status': 'approved',
        'isVerified': true,
        'isPremium': true,
        'rating': 4.7,
        'offersCount': 2,
        'imageUrl':
            'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400',
      },
      {
        'id': 'rest-4',
        'name': 'Kacchi Bhai Express',
        'cuisine': 'Traditional Kacchi',
        'area': 'Banasree',
        'division': 'Dhaka',
        'phone': '01644556677',
        'tradeLicense': 'TRAD/DSCC/092144/2024',
        'nid': 'NID-5512-8822-3100',
        'status': 'pending',
        'isVerified': false,
        'isPremium': false,
        'rating': 4.6,
        'offersCount': 1,
        'imageUrl':
            'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=400',
      },
      {
        'id': 'rest-5',
        'name': 'Green Garden Café',
        'cuisine': 'Healthy & Salads',
        'area': 'Uttara',
        'division': 'Dhaka',
        'phone': '01511223399',
        'tradeLicense': 'TRAD/DNCC/077221/2024',
        'nid': 'NID-9921-1122-4409',
        'status': 'pending',
        'isVerified': false,
        'isPremium': false,
        'rating': 4.5,
        'offersCount': 0,
        'imageUrl':
            'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=400',
      },
      {
        'id': 'rest-6',
        'name': 'Midnight Shawarma Hub',
        'cuisine': 'Middle Eastern',
        'area': 'Mirpur',
        'division': 'Dhaka',
        'phone': '01799887766',
        'tradeLicense': 'TRAD/DSCC/001923/2023',
        'nid': 'NID-3312-9988-2104',
        'status': 'suspended',
        'isVerified': true,
        'isPremium': false,
        'rating': 3.8,
        'offersCount': 0,
        'imageUrl':
            'https://images.unsplash.com/photo-1529193591184-b1d58069ecdd?w=400',
      },
    ];

    _offersData = [
      {
        'id': 'off-1',
        'restaurantId': 'rest-1',
        'restaurantName': "Sultan's Dine",
        'title': 'Mutton Kacchi Basmati Box (500g)',
        'category': 'Biryani',
        'originalPrice': 480.0,
        'discountedPrice': 240.0,
        'quantity': 5,
        'isBoosted': true,
        'isBlocked': false,
        'area': 'Dhanmondi',
        'expiresIn': '2h 15m',
      },
      {
        'id': 'off-2',
        'restaurantId': 'rest-2',
        'restaurantName': 'Chillox Burgers',
        'title': 'Smoked BBQ Beef Burger with Fries',
        'category': 'Fast Food',
        'originalPrice': 320.0,
        'discountedPrice': 160.0,
        'quantity': 3,
        'isBoosted': true,
        'isBlocked': false,
        'area': 'Banani',
        'expiresIn': '3h 45m',
      },
      {
        'id': 'off-3',
        'restaurantId': 'rest-3',
        'restaurantName': 'Bread & Beyond Bakery',
        'title': 'Artisanal Croissant & Danish Pastry Duo',
        'category': 'Bakery',
        'originalPrice': 240.0,
        'discountedPrice': 110.0,
        'quantity': 6,
        'isBoosted': false,
        'isBlocked': false,
        'area': 'Gulshan',
        'expiresIn': '1h 30m',
      },
      {
        'id': 'off-4',
        'restaurantId': 'rest-4',
        'restaurantName': 'Kacchi Bhai Express',
        'title': 'Chicken Roast & Polao Evening Rescue',
        'category': 'Rice',
        'originalPrice': 260.0,
        'discountedPrice': 130.0,
        'quantity': 4,
        'isBoosted': false,
        'isBlocked': false,
        'area': 'Banasree',
        'expiresIn': '4h 10m',
      },
      {
        'id': 'off-5',
        'restaurantId': 'rest-6',
        'restaurantName': 'Midnight Shawarma Hub',
        'title': 'Overnight Meat Wraps (Flagged)',
        'category': 'Fast Food',
        'originalPrice': 180.0,
        'discountedPrice': 70.0,
        'quantity': 0,
        'isBoosted': false,
        'isBlocked': true,
        'area': 'Mirpur',
        'expiresIn': 'Expired',
      },
    ];

    _vouchersData = [
      {
        'code': 'SAVEBITE50',
        'title': '৳50 OFF Discount',
        'discount': '৳50 OFF (Min ৳200)',
        'type': 'Flat',
        'status': 'Active',
        'usedCount': 342,
      },
      {
        'code': 'RESCUE20',
        'title': '20% Mystery Bag Discount',
        'discount': '20% OFF (Min ৳150)',
        'type': 'Percentage',
        'status': 'Active',
        'usedCount': 518,
      },
      {
        'code': 'SUPERSAVER',
        'title': 'Super Saver Free Delivery',
        'discount': 'Free Delivery ৳60',
        'type': 'Perk',
        'status': 'Active',
        'usedCount': 189,
      },
    ];

    _verificationRequests = [
      {
        'id': 'req-1',
        'restaurantName': 'Kacchi Bhai Express',
        'ownerName': 'Mohammad Tanvir',
        'tradeLicense': 'TRAD/DSCC/092144/2024',
        'nid': 'NID-5512-8822-3100',
        'requestedAt': 'Today, 08:30 AM',
        'status': 'pending',
      },
      {
        'id': 'req-2',
        'restaurantName': 'Green Garden Café',
        'ownerName': 'Nusrat Jahan',
        'tradeLicense': 'TRAD/DNCC/077221/2024',
        'nid': 'NID-9921-1122-4409',
        'requestedAt': 'Yesterday, 04:15 PM',
        'status': 'pending',
      },
    ];

    _staffMembers = [
      {
        'id': 'staff-1',
        'name': 'Platform Head Administrator',
        'email': 'admin@savebite.com',
        'role': AppConstants.roleHeadAdmin,
        'assignedAt': 'Jan 15, 2024',
        'status': 'active',
        'isPrimary': true,
      },
      {
        'id': 'staff-2',
        'name': 'Sabbir Ahmed (Operations Lead)',
        'email': 'sabbir.admin@savebite.com',
        'role': AppConstants.roleAdmin,
        'assignedAt': 'Mar 10, 2024',
        'status': 'active',
        'isPrimary': false,
      },
      {
        'id': 'staff-3',
        'name': 'Nusrat Jahan (Merchant Manager)',
        'email': 'nusrat.mod@savebite.com',
        'role': AppConstants.roleModerator,
        'assignedAt': 'Apr 22, 2024',
        'status': 'active',
        'isPrimary': false,
      },
      {
        'id': 'staff-4',
        'name': 'Tanvir Hossain (Content Reviewer)',
        'email': 'tanvir.mod@savebite.com',
        'role': AppConstants.roleModerator,
        'assignedAt': 'Jun 05, 2024',
        'status': 'active',
        'isPrimary': false,
      },
    ];
  }

  // ==========================================
  // MODAL RUNNER WITH FLOATING NAVBAR AUTO-HIDE
  // ==========================================
  Future<T?> _showSheet<T>({required WidgetBuilder builder}) async {
    setState(() => _isNavVisible = false);
    final targetContext = rootNavigatorKey.currentContext ?? context;
    try {
      return await showModalBottomSheet<T>(
        context: targetContext,
        useRootNavigator: true,
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

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentUserProfileProvider);
    final promoBannersAsync = ref.watch(promoBannersControllerProvider);
    final banners =
        promoBannersAsync.asData?.value ?? PromoBanner.defaultBanners;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, profile),
      body: Stack(
        children: [
          // Main Body Tabs
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: IndexedStack(
                index: _currentTab,
                children: [
                  _buildOverviewTab(context, banners),
                  _buildPartnersTab(context),
                  _buildSurplusPostsTab(context),
                  _buildBannersTab(context, banners),
                  _buildSystemConsoleTab(context, profile),
                ],
              ),
            ),
          ),

          // Floating SaveBite Navigation Bar
          if (_isNavVisible)
            Positioned(
              left: 20,
              right: 20,
              bottom: bottomInset + 16,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Container(
                    height: 66,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(33),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0).withValues(alpha: 0.8),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 20,
                          spreadRadius: 1,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.06),
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
                            label: 'Overview',
                            icon: Icons.space_dashboard_outlined,
                            selectedIcon: Icons.space_dashboard_rounded,
                          ),
                          _buildNavItem(
                            index: 1,
                            label: 'Partners',
                            icon: Icons.storefront_outlined,
                            selectedIcon: Icons.storefront_rounded,
                          ),
                          _buildNavItem(
                            index: 2,
                            label: 'Posts',
                            icon: Icons.dynamic_feed_outlined,
                            selectedIcon: Icons.dynamic_feed_rounded,
                          ),
                          _buildNavItem(
                            index: 3,
                            label: 'Banners',
                            icon: Icons.view_carousel_outlined,
                            selectedIcon: Icons.view_carousel_rounded,
                          ),
                          _buildNavItem(
                            index: 4,
                            label: 'System',
                            icon: Icons.admin_panel_settings_outlined,
                            selectedIcon: Icons.admin_panel_settings_rounded,
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
    );
  }

  // ==============================================================================
  // 1. APP BAR (Clean White Header matching Customer & Restaurant)
  // ==============================================================================
  PreferredSizeWidget _buildAppBar(BuildContext context, dynamic profile) {
    final String userRole =
        (profile?.role as String?) ?? AppConstants.roleHeadAdmin;
    final String roleBadgeText = switch (userRole) {
      AppConstants.roleHeadAdmin => 'HEAD ADMIN • ACTIVE',
      AppConstants.roleAdmin => 'ADMIN • ACTIVE',
      AppConstants.roleModerator => 'MODERATOR • ACTIVE',
      _ => 'HEAD ADMIN • ACTIVE',
    };

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      title: Row(
        children: [
          const AppLogoIcon(
            size: 32,
            borderRadius: 10,
            iconSize: 18,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SaveBite Admin Panel',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 1),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF16A34A),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    roleBadgeText,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded,
              color: Color(0xFF475569)),
          tooltip: 'System Alerts',
          onPressed: () => _showBroadcastNotificationModal(context),
        ),
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: AppColors.primary),
          tooltip: 'Exit Console',
          onPressed: () async {
            final confirmed = await ConfirmDialog.show(
              context,
              title: 'Terminate Admin Session',
              message:
                  'Are you sure you want to log out of the SaveBite Admin Panel?',
              confirmLabel: 'Log Out',
            );
            if (confirmed) {
              await ref.read(authControllerProvider.notifier).signOut();
            }
          },
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.2),
        child: Container(
          color: const Color(0xFFE2E8F0),
          height: 1.2,
        ),
      ),
    );
  }

  // ==============================================================================
  // 2. FLOATING NAV ITEM
  // ==============================================================================
  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData selectedIcon,
  }) {
    final isSelected = _currentTab == index;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => setState(() => _currentTab = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
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
                        : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.primary
                        : const Color(0xFF64748B),
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
    );
  }

  // Helper for Section Headers matching Restaurant and Customer profile
  Widget _buildSectionHeader(String title, {String? countBadge}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 3.5,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Color(0xFF475569),
                letterSpacing: 0.7,
              ),
            ),
          ],
        ),
        if (countBadge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              countBadge,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
              ),
            ),
          ),
      ],
    );
  }

  // ==============================================================================
  // 3. TAB 0: OVERVIEW
  // ==============================================================================
  Widget _buildOverviewTab(BuildContext context, List<PromoBanner> banners) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero System Status Banner (Signature SaveBite Gradient)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.28),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4ADE80),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'SYSTEM: 100% ONLINE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        'DHAKA CLUSTER',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Autonomous Surplus Food Rescue Network',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Real-time ingestion monitoring, restaurant verification approvals & dynamic promotion engine.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // KPI Telemetry Cards (2x2 Grid)
          Row(
            children: [
              Expanded(
                child: _buildTelemetryCard(
                  title: 'Food Rescued',
                  value: '1,428 kg',
                  subtext: '+22.4% this week',
                  trendColor: const Color(0xFF16A34A),
                  icon: Icons.eco_rounded,
                  accentColor: const Color(0xFF16A34A),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTelemetryCard(
                  title: 'Partner Kitchens',
                  value: '${_restaurantsData.length}',
                  subtext:
                      '${_restaurantsData.where((r) => r['status'] == 'pending').length} Pending Review',
                  trendColor: const Color(0xFFD97706),
                  icon: Icons.store_rounded,
                  accentColor: const Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTelemetryCard(
                  title: 'Active Posts',
                  value: '${_offersData.length}',
                  subtext:
                      '${_offersData.where((o) => o['isBoosted'] == true).length} Boosted 🚀',
                  trendColor: AppColors.primary,
                  icon: Icons.bolt_rounded,
                  accentColor: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTelemetryCard(
                  title: 'Platform Volume',
                  value: '৳204,500',
                  subtext: '৳18,200 Ad Sales',
                  trendColor: const Color(0xFF16A34A),
                  icon: Icons.account_balance_wallet_rounded,
                  accentColor: const Color(0xFF9333EA),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // ==========================================
          // QUICK ACCESS SYMBOLS (MANDATORY REQUIREMENT)
          // ==========================================
          _buildSectionHeader('QUICK ACCESS COMMANDS', countBadge: '12 Tools'),
          const SizedBox(height: 14),

          // 12 Squircle Quick Access Symbols Grid matching app action tiles
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 10,
            childAspectRatio: 0.82,
            children: [
              _buildQuickAccessSymbol(
                label: 'Partners',
                badge:
                    '${_restaurantsData.where((r) => r['status'] == 'pending').length} Wait',
                icon: Icons.storefront_rounded,
                gradient: const [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                onTap: () {
                  setState(() {
                    _currentTab = 1;
                    _restaurantFilter = 'pending';
                  });
                },
              ),
              _buildQuickAccessSymbol(
                label: 'Posts',
                badge: '${_offersData.length} Live',
                icon: Icons.dynamic_feed_rounded,
                gradient: const [Color(0xFFE11D48), Color(0xFFBE123C)],
                onTap: () => setState(() => _currentTab = 2),
              ),
              _buildQuickAccessSymbol(
                label: 'Banners',
                badge: '3 Slots',
                icon: Icons.view_carousel_rounded,
                gradient: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                onTap: () => setState(() => _currentTab = 3),
              ),
              _buildQuickAccessSymbol(
                label: 'Verify ID',
                badge: '${_verificationRequests.length} Req',
                icon: Icons.verified_user_rounded,
                gradient: const [Color(0xFF16A34A), Color(0xFF047857)],
                onTap: () => _showVerificationsModal(context),
              ),
              _buildQuickAccessSymbol(
                label: 'Vouchers',
                badge: '${_vouchersData.length} Active',
                icon: Icons.confirmation_number_rounded,
                gradient: const [Color(0xFFD97706), Color(0xFFB45309)],
                onTap: () => _showVouchersModal(context),
              ),
              _buildQuickAccessSymbol(
                label: 'Ad Sales',
                badge: '৳18.2k',
                icon: Icons.rocket_launch_rounded,
                gradient: const [Color(0xFFDB2777), Color(0xFFBE185D)],
                onTap: () => _showAdRevenueModal(context),
              ),
              _buildQuickAccessSymbol(
                label: 'Accounts',
                badge: '1.2k User',
                icon: Icons.people_alt_rounded,
                gradient: const [Color(0xFF0284C7), Color(0xFF0369A1)],
                onTap: () => _showUserDirectoryModal(context),
              ),
              _buildQuickAccessSymbol(
                label: 'Telemetry',
                badge: 'Eco Pulse',
                icon: Icons.query_stats_rounded,
                gradient: const [Color(0xFF0D9488), Color(0xFF0F766E)],
                onTap: () => _showTelemetryModal(context),
              ),
              _buildQuickAccessSymbol(
                label: 'Broadcast',
                badge: 'Push',
                icon: Icons.campaign_rounded,
                gradient: const [Color(0xFF6366F1), Color(0xFF4338CA)],
                onTap: () => _showBroadcastNotificationModal(context),
              ),
              _buildQuickAccessSymbol(
                label: 'Console',
                badge: 'DB v2.0',
                icon: Icons.terminal_rounded,
                gradient: const [Color(0xFF475569), Color(0xFF334155)],
                onTap: () => setState(() => _currentTab = 4),
              ),
              _buildQuickAccessSymbol(
                label: 'Reviews',
                badge: '4.8★ Avg',
                icon: Icons.rate_review_rounded,
                gradient: const [Color(0xFFEAB308), Color(0xFFCA8A04)],
                onTap: () => _showReviewsModerationModal(context),
              ),
              _buildQuickAccessSymbol(
                label: 'Audit Log',
                badge: 'Secured',
                icon: Icons.security_rounded,
                gradient: const [Color(0xFF64748B), Color(0xFF475569)],
                onTap: () => _showAuditLogsModal(context),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Urgent Action Queue (Pending approvals & verifications)
          _buildSectionHeader('URGENT ACTIONS REQUIRED'),
          const SizedBox(height: 12),
          _buildActionItemCard(
            title: 'Partner Registration: Kacchi Bhai Express',
            subtitle:
                'Submitted trade license TRAD/DSCC/092144/2024 for Banasree branch.',
            actionLabel: 'Approve Kitchen',
            icon: Icons.storefront_rounded,
            iconColor: const Color(0xFFD97706),
            onAction: () {
              setState(() {
                final idx = _restaurantsData
                    .indexWhere((r) => r['id'] == 'rest-4');
                if (idx != -1) {
                  _restaurantsData[idx]['status'] = 'approved';
                  _restaurantsData[idx]['isVerified'] = true;
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Kacchi Bhai Express approved and verified!'),
                  backgroundColor: Color(0xFF16A34A),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          _buildActionItemCard(
            title: 'Verification Request: Green Garden Café',
            subtitle: 'Uploaded National ID NID-9921-1122-4409 and trade deed.',
            actionLabel: 'Review Dossier',
            icon: Icons.shield_rounded,
            iconColor: const Color(0xFF0284C7),
            onAction: () => _showVerificationsModal(context),
          ),
          const SizedBox(height: 24),

          // Realtime Activity Feed
          _buildSectionHeader('LIVE NETWORK ACTIVITY'),
          const SizedBox(height: 12),
          _buildActivityTile(
            time: '2 mins ago',
            event: 'Surplus Mutton Kacchi Basmati Box (Order #SB-2041)',
            desc: "Pickup PIN verified at Sultan's Dine, Dhanmondi",
            icon: Icons.check_circle_rounded,
            iconColor: const Color(0xFF16A34A),
          ),
          _buildActivityTile(
            time: '14 mins ago',
            event: '24h Boost Package Activated',
            desc: 'Chillox Burgers boosted "Smoked BBQ Beef Burger"',
            icon: Icons.rocket_launch_rounded,
            iconColor: AppColors.primary,
          ),
          _buildActivityTile(
            time: '38 mins ago',
            event: 'New Customer Super Saver Subscription',
            desc: 'Shahria Alam upgraded to Super Saver perks tier',
            icon: Icons.military_tech_rounded,
            iconColor: const Color(0xFFD97706),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryCard({
    required String title,
    required String value,
    required String subtext,
    required Color trendColor,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtext,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: trendColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessSymbol({
    required String label,
    required String badge,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.first.withValues(alpha: 0.28),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
                Positioned(
                  top: -5,
                  right: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5.5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: gradient.first, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        color: gradient.first,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItemCard({
    required String title,
    required String subtitle,
    required String actionLabel,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: iconColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              actionLabel,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTile({
    required String time,
    required String event,
    required String desc,
    required IconData icon,
    required Color iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFE2E8F0).withValues(alpha: 0.8),
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
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    desc,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              time,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================================================
  // 4. TAB 1: PARTNERS (RESTAURANTS MANAGEMENT)
  // ==============================================================================
  Widget _buildPartnersTab(BuildContext context) {
    var filtered = _restaurantsData.where((r) {
      if (_restaurantFilter == 'pending' && r['status'] != 'pending') {
        return false;
      }
      if (_restaurantFilter == 'verified' && r['isVerified'] != true) {
        return false;
      }
      if (_restaurantFilter == 'suspended' && r['status'] != 'suspended') {
        return false;
      }
      final query = _restaurantSearchCtrl.text.trim().toLowerCase();
      if (query.isNotEmpty) {
        final name = (r['name'] as String).toLowerCase();
        final area = (r['area'] as String).toLowerCase();
        return name.contains(query) || area.contains(query);
      }
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('PARTNER DIRECTORY & ONBOARDING'),
          const SizedBox(height: 12),

          // Search & Filter header
          TextField(
            controller: _restaurantSearchCtrl,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search restaurants by name or area...',
              hintStyle:
                  const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              prefixIcon:
                  const Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All (${_restaurantsData.length})', 'all',
                    _restaurantFilter, (val) => setState(() => _restaurantFilter = val)),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Pending (${_restaurantsData.where((r) => r['status'] == 'pending').length})',
                  'pending',
                  _restaurantFilter,
                  (val) => setState(() => _restaurantFilter = val),
                  accentColor: const Color(0xFFD97706),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Verified (${_restaurantsData.where((r) => r['isVerified'] == true).length})',
                  'verified',
                  _restaurantFilter,
                  (val) => setState(() => _restaurantFilter = val),
                  accentColor: const Color(0xFF16A34A),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Suspended (${_restaurantsData.where((r) => r['status'] == 'suspended').length})',
                  'suspended',
                  _restaurantFilter,
                  (val) => setState(() => _restaurantFilter = val),
                  accentColor: const Color(0xFFDC2626),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Restaurant Cards List
          if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: const Text(
                'No partner restaurants found.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
            )
          else
            ...filtered.map((r) => _buildRestaurantAdminCard(context, r)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    String current,
    ValueChanged<String> onSelected, {
    Color? accentColor,
  }) {
    final isSelected = current == value;
    final color = accentColor ?? AppColors.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => onSelected(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : const Color(0xFF64748B),
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildRestaurantAdminCard(
      BuildContext context, Map<String, dynamic> r) {
    final bool isVerified = r['isVerified'] == true;
    final String status = r['status'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status == 'pending'
              ? const Color(0xFFD97706).withValues(alpha: 0.45)
              : const Color(0xFFE2E8F0),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  r['imageUrl'] as String,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 50,
                    height: 50,
                    color: const Color(0xFFF1F5F9),
                    child:
                        const Icon(Icons.storefront, color: Color(0xFF94A3B8)),
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
                        Flexible(
                          child: Text(
                            r['name'] as String,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(4),
                              border:
                                  Border.all(color: const Color(0xFF86EFAC)),
                            ),
                            child: const Text(
                              'VERIFIED',
                              style: TextStyle(
                                color: Color(0xFF16A34A),
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${r['cuisine']} • ${r['area']}, ${r['division']}',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11.5,
                      ),
                    ),
                    Text(
                      'Trade: ${r['tradeLicense']}',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Status: ${status.toUpperCase()}',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: status == 'approved'
                      ? const Color(0xFF16A34A)
                      : status == 'pending'
                          ? const Color(0xFFD97706)
                          : const Color(0xFFDC2626),
                ),
              ),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => _showRestaurantDossierModal(context, r),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF334155),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Dossier',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                  if (status == 'pending') ...[
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          r['status'] = 'approved';
                          r['isVerified'] = true;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${r['name']} approved!'),
                            backgroundColor: const Color(0xFF16A34A),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Approve',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w800)),
                    ),
                  ] else if (status == 'approved') ...[
                    ElevatedButton(
                      onPressed: () {
                        setState(() => r['status'] = 'suspended');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${r['name']} suspended.'),
                            backgroundColor: const Color(0xFFDC2626),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Suspend',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w800)),
                    ),
                  ] else ...[
                    ElevatedButton(
                      onPressed: () {
                        setState(() => r['status'] = 'approved');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${r['name']} reinstated.'),
                            backgroundColor: const Color(0xFF16A34A),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Reinstate',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==============================================================================
  // 5. TAB 2: SURPLUS POSTS MODERATION
  // ==============================================================================
  Widget _buildSurplusPostsTab(BuildContext context) {
    var filtered = _offersData.where((o) {
      if (_offerFilter == 'active' &&
          (o['isBlocked'] == true || o['quantity'] == 0)) {
        return false;
      }
      if (_offerFilter == 'boosted' && o['isBoosted'] != true) {
        return false;
      }
      if (_offerFilter == 'blocked' && o['isBlocked'] != true) {
        return false;
      }
      final query = _offerSearchCtrl.text.trim().toLowerCase();
      if (query.isNotEmpty) {
        final title = (o['title'] as String).toLowerCase();
        final rest = (o['restaurantName'] as String).toLowerCase();
        return title.contains(query) || rest.contains(query);
      }
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('COMMUNITY POSTS MONITOR'),
          const SizedBox(height: 12),

          TextField(
            controller: _offerSearchCtrl,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search posts by title or restaurant...',
              hintStyle:
                  const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              prefixIcon:
                  const Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  'All (${_offersData.length})',
                  'all',
                  _offerFilter,
                  (val) => setState(() => _offerFilter = val),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Active (${_offersData.where((o) => o['isBlocked'] != true && (o['quantity'] as int) > 0).length})',
                  'active',
                  _offerFilter,
                  (val) => setState(() => _offerFilter = val),
                  accentColor: const Color(0xFF16A34A),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Boosted 🚀 (${_offersData.where((o) => o['isBoosted'] == true).length})',
                  'boosted',
                  _offerFilter,
                  (val) => setState(() => _offerFilter = val),
                  accentColor: AppColors.primary,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Blocked (${_offersData.where((o) => o['isBlocked'] == true).length})',
                  'blocked',
                  _offerFilter,
                  (val) => setState(() => _offerFilter = val),
                  accentColor: const Color(0xFFDC2626),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: const Text(
                'No surplus offers match the filter.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
            )
          else
            ...filtered.map((o) => _buildOfferAdminCard(context, o)),
        ],
      ),
    );
  }

  Widget _buildOfferAdminCard(BuildContext context, Map<String, dynamic> o) {
    final bool isBoosted = o['isBoosted'] == true;
    final bool isBlocked = o['isBlocked'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isBlocked
              ? const Color(0xFFDC2626).withValues(alpha: 0.4)
              : isBoosted
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : const Color(0xFFE2E8F0),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isBoosted) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1F2),
                              borderRadius: BorderRadius.circular(4),
                              border:
                                  Border.all(color: const Color(0xFFFFCCD3)),
                            ),
                            child: const Text(
                              'BOOSTED 24H',
                              style: TextStyle(
                                color: Color(0xFFE11D48),
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            o['category'] as String,
                            style: const TextStyle(
                              color: Color(0xFF475569),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      o['title'] as String,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${o['restaurantName']} • ${o['area']} • Window: ${o['expiresIn']}',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '৳${(o['discountedPrice'] as double).toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Color(0xFF16A34A),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Orig: ৳${(o['originalPrice'] as double).toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isBlocked
                    ? '⛔ POLICY BLOCKED'
                    : 'Qty: ${o['quantity']} items left',
                style: TextStyle(
                  color: isBlocked
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () {
                      setState(() => o['isBoosted'] = !isBoosted);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isBoosted
                              ? 'Boost removed from "${o['title']}"'
                              : 'Boost active on "${o['title']}"'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      isBoosted ? 'Unboost' : '🚀 Boost',
                      style: const TextStyle(
                          fontSize: 10.5, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => o['isBlocked'] = !isBlocked);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isBlocked
                              ? 'Offer restored to feed.'
                              : 'Offer blocked from feed.'),
                          backgroundColor: isBlocked
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFDC2626),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isBlocked
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      isBlocked ? 'Restore' : 'Block',
                      style: const TextStyle(
                          fontSize: 10.5, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 6),
                  OutlinedButton(
                    onPressed: () async {
                      final confirmed = await ConfirmDialog.show(
                        context,
                        title: 'Remove Post Permanently',
                        message:
                            'Are you sure you want to permanently remove "${o['title']}" from the posts feed?',
                        confirmLabel: 'Remove Post',
                        isDestructive: true,
                      );
                      if (confirmed == true) {
                        setState(() {
                          _offersData
                              .removeWhere((item) => item['id'] == o['id']);
                        });
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Removed "${o['title']}" from posts.'),
                              backgroundColor: const Color(0xFFDC2626),
                            ),
                          );
                        }
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                      backgroundColor: const Color(0xFFFEF2F2),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text(
                      'Remove',
                      style: TextStyle(
                          fontSize: 10.5, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==============================================================================
  // 6. TAB 3: BANNERS & PROMOTIONAL ENGINE
  // ==============================================================================
  Widget _buildBannersTab(BuildContext context, List<PromoBanner> banners) {
    final pendingBanners = banners.where((b) => b.isPending).toList();
    final activeBanners = banners.where((b) => b.isApproved).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. PENDING RESTAURANT BANNER REQUESTS (Approval Flow)
          Row(
            children: [
              Container(
                width: 3.5,
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'PARTNER BANNER REQUESTS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: pendingBanners.isNotEmpty
                      ? const Color(0xFFFEF3C7)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${pendingBanners.length} PENDING',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: pendingBanners.isNotEmpty
                        ? const Color(0xFF92400E)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Restaurant submitted hero banners requiring admin moderation before displaying.',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),

          if (pendingBanners.isNotEmpty) ...[
            for (final p in pendingBanners) ...[
              _buildAdminPendingBannerCard(context, ref, p),
              const SizedBox(height: 12),
            ],
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      size: 18, color: Color(0xFF16A34A)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No pending banner requests. All restaurant submissions reviewed.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // 2. ACTIVE CAROUSEL BANNERS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 3.5,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ACTIVE CAROUSEL BANNERS',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'Live Slideshow on Customer Home Screen',
                            style:
                                TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () async {
                  final confirmed = await ConfirmDialog.show(
                    context,
                    title: 'Reset Promotional Banners',
                    message:
                        'Restore default 3 hero banners for Dhaka surplus campaigns?',
                    confirmLabel: 'Reset',
                  );
                  if (confirmed) {
                    await ref
                        .read(promoBannersControllerProvider.notifier)
                        .resetToDefaults();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Banners reset to defaults.'),
                          backgroundColor: Color(0xFF16A34A),
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.refresh_rounded, size: 14),
                label: const Text('Reset Defaults', style: TextStyle(fontSize: 11)),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Active Banner Cards
          for (int i = 0; i < activeBanners.length; i++) ...[
            _buildAdminBannerCard(context, ref, activeBanners[i], i + 1),
            if (i < activeBanners.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  /// Card displaying a pending restaurant hero banner request for Admin approval
  Widget _buildAdminPendingBannerCard(
    BuildContext context,
    WidgetRef ref,
    PromoBanner banner,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFDE68A),
          width: 1.5,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'PENDING APPROVAL ⏳',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.storefront_rounded,
                      size: 14, color: Color(0xFF92400E)),
                  const SizedBox(width: 4),
                  Text(
                    banner.restaurantName ?? 'Restaurant Partner',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            banner.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          if (banner.subtitle.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              banner.subtitle,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF475569),
              ),
            ),
          ],
          const SizedBox(height: 10),
          // Banner Image Design preview
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 110,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: banner.gradient,
              ),
              child: (banner.imageUrl != null && banner.imageUrl!.isNotEmpty)
                  ? _buildAdminImagePreview(
                      banner.imageUrl!,
                      fit: BoxFit.cover,
                    )
                  : const Center(
                      child: Text(
                        'No design image attached',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle_rounded, size: 16),
                  label: const Text('Approve & Go Live'),
                  onPressed: () async {
                    await ref
                        .read(promoBannersControllerProvider.notifier)
                        .approveBanner(banner.id);
                    if (banner.restaurantId != null) {
                      await ref
                          .read(restaurantNotificationsProvider.notifier)
                          .notifyBannerStarted(
                            restaurantId: banner.restaurantId!,
                            bannerHeadline: banner.title,
                            bannerId: banner.id,
                            restaurantName: banner.restaurantName,
                          );
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '🎉 Banner "${banner.title}" approved! Start notification sent to ${banner.restaurantName ?? 'partner'}.',
                          ),
                          backgroundColor: const Color(0xFF16A34A),
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('Reject'),
                onPressed: () async {
                  await ref
                      .read(promoBannersControllerProvider.notifier)
                      .rejectBanner(banner.id,
                          reason: 'Does not meet banner quality guidelines.');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Banner "${banner.title}" rejected.'),
                        backgroundColor: const Color(0xFFDC2626),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminBannerCard(
    BuildContext context,
    WidgetRef ref,
    PromoBanner banner,
    int slotNumber,
  ) {
    final bool isPartnerBanner = banner.restaurantId != null;

    return Container(
      padding: const EdgeInsets.all(14),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'SLOT #$slotNumber',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (isPartnerBanner)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: Text(
                          banner.restaurantName ?? 'PARTNER',
                          style: const TextStyle(
                            color: Color(0xFF166534),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Text(
                        banner.badge,
                        style: const TextStyle(
                          color: Color(0xFF92400E),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: banner.gradient,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        '${PromoBanner.availableThemes[banner.themeKey]?.emoji ?? '🎨'} ${PromoBanner.availableThemes[banner.themeKey]?.name ?? 'Theme'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isPartnerBanner)
                OutlinedButton.icon(
                  onPressed: () async {
                    final confirmed = await ConfirmDialog.show(
                      context,
                      title: 'End Banner Campaign',
                      message:
                          'End display of "${banner.title}" on the customer homepage carousel? The restaurant will receive an ending notification.',
                      confirmLabel: 'End Campaign',
                    );
                    if (confirmed) {
                      await ref
                          .read(promoBannersControllerProvider.notifier)
                          .endBanner(banner.id);
                      if (banner.restaurantId != null) {
                        await ref
                            .read(restaurantNotificationsProvider.notifier)
                            .notifyBannerEnded(
                              restaurantId: banner.restaurantId!,
                              bannerHeadline: banner.title,
                              bannerId: banner.id,
                              restaurantName: banner.restaurantName,
                            );
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Hero banner campaign ended. Notification dispatched to restaurant.',
                            ),
                            backgroundColor: Color(0xFF0F172A),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.timer_off_rounded, size: 13),
                  label: const Text('End',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 5),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              ElevatedButton.icon(
                onPressed: () => _openEditBannerSheet(context, ref, banner),
                icon: const Icon(Icons.edit_rounded, size: 14),
                label: const Text('Edit',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            banner.bannerName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          if (banner.subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              banner.subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (banner.code != null && banner.code!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.confirmation_number_outlined,
                    size: 13, color: Color(0xFF0284C7)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Code: ${banner.code}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0284C7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Container(
            height: 110,
            width: double.infinity,
            decoration: BoxDecoration(
              color: banner.startColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            clipBehavior: Clip.antiAlias,
            child: (banner.imageUrl != null && banner.imageUrl!.isNotEmpty)
                ? _buildAdminImagePreview(
                    banner.imageUrl!,
                    fit: BoxFit.cover,
                  )
                : const Center(
                    child: Text(
                      'No image uploaded yet.\nTap "Edit" to attach banner image.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _openEditBannerSheet(
    BuildContext context,
    WidgetRef ref,
    PromoBanner banner,
  ) {
    final headlineController =
        TextEditingController(text: banner.bannerName);
    final subtitleController =
        TextEditingController(text: banner.subtitle);
    final badgeController =
        TextEditingController(text: banner.badge);
    final codeController =
        TextEditingController(text: banner.code ?? '');
    final ctaController =
        TextEditingController(text: banner.ctaText);
    final imageUrlController =
        TextEditingController(text: banner.imageUrl ?? '');
    String selectedTheme = banner.themeKey;
    bool isSaving = false;

    _showSheet(
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final themeInfo = PromoBanner.availableThemes[selectedTheme] ??
                PromoBanner.availableThemes['coffee'] ??
                PromoBanner.availableThemes.values.first;
            final currentStartColor = Color(int.parse(themeInfo.start));
            final currentEndColor = Color(int.parse(themeInfo.end));

            return Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheetCtx).size.height * 0.92,
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
                top: 14,
                left: 18,
                right: 18,
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
                    const SizedBox(height: 14),

                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.auto_fix_high_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Edit Banner (${banner.id})',
                                style: const TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Text(
                                'Customize headline, image, subtitle & theme',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: Color(0xFF64748B)),
                          onPressed: () => Navigator.of(sheetCtx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Live Interactive Preview
                    const Text(
                      'LIVE PREVIEW',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [currentStartColor, currentEndColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: currentStartColor.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (imageUrlController.text.trim().isNotEmpty)
                            Container(
                              height: 120,
                              width: double.infinity,
                              color: Colors.black12,
                              child: _buildAdminImagePreview(
                                imageUrlController.text.trim(),
                                fit: BoxFit.cover,
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    if (badgeController.text.trim().isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.25),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          badgeController.text.trim(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    if (codeController.text.trim().isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Code: ${codeController.text.trim()}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  headlineController.text.trim().isEmpty
                                      ? 'Banner Headline'
                                      : headlineController.text.trim(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (subtitleController.text.trim().isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    subtitleController.text.trim(),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11.5,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 1. Banner Headline / Name
                    const Text('Banner Headline / Name *',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: headlineController,
                      style: const TextStyle(color: Color(0xFF0F172A)),
                      onChanged: (_) => setSheetState(() {}),
                      decoration: InputDecoration(
                        hintText: 'e.g. International Coffee Day 10% OFF',
                        hintStyle:
                            const TextStyle(color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 2. Banner Subtitle / Description
                    const Text('Description / Subtitle',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: subtitleController,
                      style: const TextStyle(color: Color(0xFF0F172A)),
                      maxLines: 2,
                      onChanged: (_) => setSheetState(() {}),
                      decoration: InputDecoration(
                        hintText: 'e.g. Valid across all North End branches on coffee day',
                        hintStyle:
                            const TextStyle(color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 3. Badge & Promo Code row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Badge Tag',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: badgeController,
                                style: const TextStyle(
                                    color: Color(0xFF0F172A)),
                                onChanged: (_) => setSheetState(() {}),
                                decoration: InputDecoration(
                                  hintText: '☕ COFFEE DAY',
                                  hintStyle: const TextStyle(
                                      color: Color(0xFF94A3B8)),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: Color(0xFFE2E8F0)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: Color(0xFFE2E8F0)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Coupon / Code',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: codeController,
                                style: const TextStyle(
                                    color: Color(0xFF0F172A)),
                                onChanged: (_) => setSheetState(() {}),
                                decoration: InputDecoration(
                                  hintText: 'e.g. BYTE100',
                                  hintStyle: const TextStyle(
                                      color: Color(0xFF94A3B8)),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: Color(0xFFE2E8F0)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: Color(0xFFE2E8F0)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 4. Banner Picture (URL / File Pick)
                    const Text('Banner Picture (URL / Device File)',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A))),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: imageUrlController,
                            style: const TextStyle(color: Color(0xFF0F172A)),
                            onChanged: (_) => setSheetState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Image URL or asset path',
                              hintStyle:
                                  const TextStyle(color: Color(0xFF94A3B8)),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final dataUrl =
                                await pickImageWithPermission(sheetCtx);
                            if (dataUrl != null) {
                              imageUrlController.text = dataUrl;
                              setSheetState(() {});
                            }
                          },
                          icon: const Icon(Icons.upload_file_rounded, size: 16),
                          label: const Text('Pick Image'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 12),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (imageUrlController.text.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            imageUrlController.clear();
                            setSheetState(() {});
                          },
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 15, color: Color(0xFFDC2626)),
                          label: const Text('Remove Image',
                              style: TextStyle(
                                  fontSize: 11.5, color: Color(0xFFDC2626))),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),

                    // 5. Theme selector
                    const Text('Background Color Theme',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A))),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: PromoBanner.availableThemes.entries.map((entry) {
                        final themeKey = entry.key;
                        final theme = entry.value;
                        final isSelected = selectedTheme == themeKey;
                        return InkWell(
                          onTap: () =>
                              setSheetState(() => selectedTheme = themeKey),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(int.parse(theme.start)),
                                  Color(int.parse(theme.end)),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.transparent,
                                width: 2.2,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.25),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(theme.emoji),
                                const SizedBox(width: 4),
                                Text(
                                  theme.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 22),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF64748B),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              minimumSize: const Size(0, 46),
                            ),
                            onPressed: isSaving
                                ? null
                                : () => Navigator.of(sheetCtx).pop(),
                            child: const Text('Cancel',
                                style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              minimumSize: const Size(0, 46),
                            ),
                            onPressed: isSaving
                                ? null
                                : () async {
                                    final finalHeadline = headlineController
                                        .text
                                        .trim()
                                        .isNotEmpty
                                        ? headlineController.text.trim()
                                        : banner.bannerName;
                                    setSheetState(() => isSaving = true);
                                    try {
                                      final chosenTheme =
                                          PromoBanner.availableThemes[
                                                  selectedTheme] ??
                                              PromoBanner.availableThemes[
                                                  'coffee'] ??
                                              PromoBanner.availableThemes.values
                                                  .first;
                                      final updated = banner.copyWith(
                                        name: finalHeadline,
                                        title: finalHeadline,
                                        subtitle:
                                            subtitleController.text.trim(),
                                        badge: badgeController.text.trim().isNotEmpty
                                            ? badgeController.text.trim()
                                            : banner.badge,
                                        code: codeController.text.trim(),
                                        clearCode: codeController.text.trim().isEmpty,
                                        ctaText: ctaController.text.trim().isNotEmpty
                                            ? ctaController.text.trim()
                                            : banner.ctaText,
                                        imageUrl: imageUrlController.text.trim(),
                                        clearImageUrl: imageUrlController.text.trim().isEmpty,
                                        themeKey: selectedTheme,
                                        bgStartColor: chosenTheme.start,
                                        bgEndColor: chosenTheme.end,
                                      );

                                      await ref
                                          .read(promoBannersControllerProvider
                                              .notifier)
                                          .updateBanner(updated);

                                      if (sheetCtx.mounted) {
                                        Navigator.of(sheetCtx).pop();
                                      }
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Banner "${updated.bannerName}" updated successfully! ✨',
                                            ),
                                            backgroundColor:
                                                const Color(0xFF16A34A),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (sheetCtx.mounted) {
                                        setSheetState(() => isSaving = false);
                                        ScaffoldMessenger.of(sheetCtx)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Failed to save banner: $e'),
                                            backgroundColor:
                                                const Color(0xFFDC2626),
                                          ),
                                        );
                                      }
                                    }
                                  },
                            child: isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Save Banner Changes',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
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

  // ==============================================================================
  // 7. TAB 4: SYSTEM CONSOLE & STAFF ROLE ACCESS HUB
  // ==============================================================================
  Widget _buildSystemConsoleTab(BuildContext context, dynamic profile) {
    final String currentRole =
        (profile?.role as String?) ?? AppConstants.roleHeadAdmin;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Executive Session Profile Card
          _buildCurrentSessionCard(profile, currentRole),
          const SizedBox(height: 18),

          // 2. Staff Roles & Access Control Center (3 Role Buttons + Data Management)
          _buildStaffManagementSection(context, profile, currentRole),
          const SizedBox(height: 18),

          // 3. Platform Vouchers & Campaigns Card
          _buildVouchersSummaryCard(context),
          const SizedBox(height: 18),

          // 4. System Health & Infrastructure Telemetry
          _buildSystemHealthSecurityCard(),
        ],
      ),
    );
  }

  // 1. Executive Session Profile Card
  Widget _buildCurrentSessionCard(dynamic profile, String currentRole) {
    final (badgeBg, badgeBorder, badgeText, roleLabel, roleIcon) =
        _getRoleVisuals(currentRole);

    final fullName = profile?.fullName ?? 'Platform Head Administrator';
    final email = profile?.email ?? 'admin@savebite.com';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
              // Avatar circle with online beacon
              Stack(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: badgeBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: badgeBorder, width: 1.5),
                    ),
                    child: Center(
                      child: Icon(roleIcon, color: badgeText, size: 24),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
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
                            fullName,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: badgeBorder),
                ),
                child: Text(
                  roleLabel,
                  style: TextStyle(
                    color: badgeText,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.lock_outline_rounded,
                          size: 13, color: Color(0xFF16A34A)),
                      SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'Session Authenticated • 2FA Enforced',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF334155),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'SSL Encrypted',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
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

  // 2. Staff Roles & Access Control Center (With 3 Interactive Buttons)
  Widget _buildStaffManagementSection(
      BuildContext context, dynamic profile, String currentRole) {
    final headCount = _staffMembers
        .where((s) => s['role'] == AppConstants.roleHeadAdmin)
        .length;
    final adminCount = _staffMembers
        .where((s) => s['role'] == AppConstants.roleAdmin)
        .length;
    final modCount = _staffMembers
        .where((s) => s['role'] == AppConstants.roleModerator)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('STAFF & ROLE ACCESS CONTROL',
            countBadge: '${_staffMembers.length} ACTIVE'),
        const SizedBox(height: 6),
        const Text(
          'Select a role button below to view assigned personnel, inspect privileges, or add new staff.',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 11.5,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),

        // 3 Interactive Role Buttons: Head Admin, Admin, Moderator
        Row(
          children: [
            Expanded(
              child: _buildRoleButton(
                role: AppConstants.roleHeadAdmin,
                title: 'Head Admin',
                level: 'LEVEL 1',
                emoji: '👑',
                count: headCount,
                themeColor: const Color(0xFF7E22CE),
                themeBg: const Color(0xFFFAF5FF),
                themeBorder: const Color(0xFFD8B4FE),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildRoleButton(
                role: AppConstants.roleAdmin,
                title: 'Admin',
                level: 'LEVEL 2',
                emoji: '🛡️',
                count: adminCount,
                themeColor: const Color(0xFF1D4ED8),
                themeBg: const Color(0xFFEFF6FF),
                themeBorder: const Color(0xFF93C5FD),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildRoleButton(
                role: AppConstants.roleModerator,
                title: 'Moderator',
                level: 'LEVEL 3',
                emoji: '🔍',
                count: modCount,
                themeColor: const Color(0xFF047857),
                themeBg: const Color(0xFFECFDF5),
                themeBorder: const Color(0xFF6EE7B7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Active Role Card (View & Insert data for the selected role button)
        _buildActiveRoleConsole(context, currentRole, profile?.email as String?),
      ],
    );
  }

  Widget _buildRoleButton({
    required String role,
    required String title,
    required String level,
    required String emoji,
    required int count,
    required Color themeColor,
    required Color themeBg,
    required Color themeBorder,
  }) {
    final isSelected = _selectedStaffRole == role;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedStaffRole = role),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? themeBg : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? themeColor : const Color(0xFFE2E8F0),
              width: isSelected ? 2.0 : 1.2,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: themeColor.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                )
              else
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? themeColor.withValues(alpha: 0.15)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      level,
                      style: TextStyle(
                        color: isSelected
                            ? themeColor
                            : const Color(0xFF64748B),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                title,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF0F172A)
                      : const Color(0xFF334155),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? themeColor
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count ${count == 1 ? "Staff" : "Staff"}',
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveRoleConsole(
    BuildContext context,
    String currentRole,
    String? currentEmail,
  ) {
    final isHeadAdmin = currentRole == AppConstants.roleHeadAdmin;
    final isAdmin = currentRole == AppConstants.roleAdmin;

    // Permissions to insert into this specific role
    bool canInsertIntoThisRole = false;
    String? insertLockReason;

    if (_selectedStaffRole == AppConstants.roleHeadAdmin) {
      if (isHeadAdmin) {
        canInsertIntoThisRole = true;
      } else {
        insertLockReason = 'Requires Head Admin';
      }
    } else if (_selectedStaffRole == AppConstants.roleAdmin) {
      if (isHeadAdmin) {
        canInsertIntoThisRole = true;
      } else {
        insertLockReason = 'Requires Head Admin';
      }
    } else if (_selectedStaffRole == AppConstants.roleModerator) {
      if (isHeadAdmin || isAdmin) {
        canInsertIntoThisRole = true;
      } else {
        insertLockReason = 'Read Only';
      }
    }

    final (themeBg, themeBorder, themeColor, roleTitle, roleIcon) =
        switch (_selectedStaffRole) {
      AppConstants.roleHeadAdmin => (
          const Color(0xFFFAF5FF),
          const Color(0xFFD8B4FE),
          const Color(0xFF7E22CE),
          'Head Admin Control',
          Icons.admin_panel_settings_rounded,
        ),
      AppConstants.roleAdmin => (
          const Color(0xFFEFF6FF),
          const Color(0xFF93C5FD),
          const Color(0xFF1D4ED8),
          'Admin Operations',
          Icons.security_rounded,
        ),
      _ => (
          const Color(0xFFECFDF5),
          const Color(0xFF6EE7B7),
          const Color(0xFF047857),
          'Moderator Console',
          Icons.verified_user_rounded,
        ),
    };

    final roleMembers = _staffMembers
        .where((s) => s['role'] == _selectedStaffRole)
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: themeBorder,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Role Info + Quick "+ Add [Role]" Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: themeBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: themeBorder),
                      ),
                      child: Icon(roleIcon, color: themeColor, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            roleTitle,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            _selectedStaffRole == AppConstants.roleHeadAdmin
                                ? 'Supreme Authority • System Governance'
                                : _selectedStaffRole == AppConstants.roleAdmin
                                    ? 'Operations Authority • Management'
                                    : 'Moderation Authority • Content Audit',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (canInsertIntoThisRole)
                ElevatedButton.icon(
                  onPressed: () => _showAddStaffModal(
                    context,
                    currentRole,
                    initialRole: _selectedStaffRole,
                  ),
                  icon: const Icon(Icons.person_add_rounded, size: 14),
                  label: Text(
                    '+ Add ${_selectedStaffRole == AppConstants.roleHeadAdmin ? "Head Admin" : _selectedStaffRole == AppConstants.roleAdmin ? "Admin" : "Moderator"}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                )
              else if (insertLockReason != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    insertLockReason,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Compact Capability Pills (NO text walls!)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _buildRoleCapabilityChips(_selectedStaffRole),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // Members Count Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ASSIGNED MEMBERS (${roleMembers.length})',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Members List
          if (roleMembers.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.group_off_rounded,
                      size: 28, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 8),
                  const Text(
                    'No staff assigned to this role yet.',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (canInsertIntoThisRole) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => _showAddStaffModal(
                        context,
                        currentRole,
                        initialRole: _selectedStaffRole,
                      ),
                      icon: const Icon(Icons.add, size: 14),
                      label: Text(
                        'Assign first ${_selectedStaffRole == AppConstants.roleAdmin ? "Admin" : "Moderator"}',
                        style: TextStyle(
                          color: themeColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            )
          else
            ...roleMembers.map((member) => _buildRoleMemberCard(
                  context,
                  member,
                  currentRole,
                  currentEmail,
                  themeColor,
                  themeBorder,
                  themeBg,
                )),
        ],
      ),
    );
  }

  List<Widget> _buildRoleCapabilityChips(String role) {
    final List<(String, IconData)> capabilities = switch (role) {
      AppConstants.roleHeadAdmin => [
          ('Supreme Authority', Icons.military_tech_rounded),
          ('Manage Admins', Icons.manage_accounts_rounded),
          ('Manage Moderators', Icons.group_add_rounded),
          ('Platform Vouchers', Icons.confirmation_number_rounded),
          ('System Security', Icons.lock_person_rounded),
        ],
      AppConstants.roleAdmin => [
          ('Partner Approvals', Icons.storefront_rounded),
          ('Post Moderation', Icons.dynamic_feed_rounded),
          ('Hero Banners', Icons.view_carousel_rounded),
          ('Voucher Studio', Icons.local_offer_rounded),
          ('Manage Moderators', Icons.person_add_alt_1_rounded),
        ],
      _ => [
          ('Review Kitchens', Icons.verified_user_rounded),
          ('Remove Posts', Icons.delete_sweep_rounded),
          ('Block Content', Icons.block_flipped),
          ('Resolve Reports', Icons.report_problem_rounded),
        ],
    };

    return capabilities.map((c) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(c.$2, size: 11, color: const Color(0xFF475569)),
            const SizedBox(width: 4),
            Text(
              c.$1,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildRoleMemberCard(
    BuildContext context,
    Map<String, dynamic> member,
    String currentRole,
    String? currentEmail,
    Color themeColor,
    Color themeBorder,
    Color themeBg,
  ) {
    final String role = member['role'] as String;
    final bool isPrimary = member['isPrimary'] == true;
    final bool isSelf = member['email'] == currentEmail;

    bool canRemove = false;
    String? statusNote;

    if (isPrimary || isSelf) {
      statusNote = isPrimary ? 'PRIMARY' : 'ACTIVE SESSION';
    } else if (currentRole == AppConstants.roleHeadAdmin) {
      if (role == AppConstants.roleAdmin ||
          role == AppConstants.roleModerator) {
        canRemove = true;
      }
    } else if (currentRole == AppConstants.roleAdmin) {
      if (role == AppConstants.roleModerator) {
        canRemove = true;
      } else {
        statusNote = 'HEAD ADMIN ONLY';
      }
    } else {
      statusNote = 'READ ONLY';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: themeBg,
            child: Text(
              (member['name'] as String).isNotEmpty
                  ? (member['name'] as String)[0].toUpperCase()
                  : 'S',
              style: TextStyle(
                color: themeColor,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member['name'] as String,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  member['email'] as String,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          if (canRemove)
            OutlinedButton.icon(
              onPressed: () async {
                final roleName =
                    role == AppConstants.roleAdmin ? 'Admin' : 'Moderator';
                final confirmed = await ConfirmDialog.show(
                  context,
                  title: 'Revoke Staff Role',
                  message:
                      'Are you sure you want to revoke $roleName privileges for ${member['name']} (${member['email']})?',
                  confirmLabel: 'Revoke Access',
                  isDestructive: true,
                );
                if (confirmed == true) {
                  setState(() {
                    _staffMembers
                        .removeWhere((s) => s['id'] == member['id']);
                  });
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Revoked $roleName privileges for ${member['name']}.'),
                        backgroundColor: const Color(0xFFDC2626),
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.person_remove_rounded, size: 11),
              label: const Text(
                'Remove',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
                side: const BorderSide(color: Color(0xFFFCA5A5)),
                backgroundColor: const Color(0xFFFEF2F2),
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            )
          else if (statusNote != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Text(
                statusNote,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 3. Platform Vouchers & Campaigns Card
  Widget _buildVouchersSummaryCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.confirmation_number_outlined,
                      size: 16, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'PLATFORM VOUCHERS',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () => _showCreateVoucherModal(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text('+ New Code',
                    style: TextStyle(
                        fontSize: 10.5, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._vouchersData.map(
            (v) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F2),
                            borderRadius: BorderRadius.circular(6),
                            border:
                                Border.all(color: const Color(0xFFFFCCD3)),
                          ),
                          child: Text(
                            v['code'] as String,
                            style: const TextStyle(
                              color: Color(0xFFE11D48),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            v['discount'] as String,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${v['usedCount']} claimed',
                    style: const TextStyle(
                        color: Color(0xFF64748B), fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 4. System Health & Security Telemetry
  Widget _buildSystemHealthSecurityCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.health_and_safety_outlined,
                  size: 16, color: Color(0xFF16A34A)),
              SizedBox(width: 8),
              Text(
                'SYSTEM HEALTH & TELEMETRY',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildHealthTile(
                  icon: Icons.sync_rounded,
                  label: 'Realtime Sync',
                  status: 'Connected',
                  color: const Color(0xFF16A34A),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildHealthTile(
                  icon: Icons.shield_rounded,
                  label: 'Security RLS',
                  status: 'Enforced',
                  color: const Color(0xFF0284C7),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildHealthTile(
                  icon: Icons.speed_rounded,
                  label: 'Uptime',
                  status: '99.98%',
                  color: const Color(0xFF7E22CE),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthTile({
    required IconData icon,
    required String label,
    required String status,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            status,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  (Color, Color, Color, String, IconData) _getRoleVisuals(String role) {
    return switch (role) {
      AppConstants.roleHeadAdmin => (
          const Color(0xFFFAF5FF),
          const Color(0xFFE9D5FF),
          const Color(0xFF7E22CE),
          'HEAD ADMIN 👑',
          Icons.admin_panel_settings_rounded,
        ),
      AppConstants.roleAdmin => (
          const Color(0xFFEFF6FF),
          const Color(0xFFBFDBFE),
          const Color(0xFF1D4ED8),
          'ADMIN 🛡️',
          Icons.security_rounded,
        ),
      _ => (
          const Color(0xFFECFDF5),
          const Color(0xFFA7F3D0),
          const Color(0xFF047857),
          'MODERATOR 🔍',
          Icons.verified_user_rounded,
        ),
    };
  }

  void _showAddStaffModal(
    BuildContext context,
    String currentRole, {
    String? initialRole,
  }) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();

    String selectedRole;
    if (initialRole != null &&
        (currentRole == AppConstants.roleHeadAdmin ||
            (currentRole == AppConstants.roleAdmin &&
                initialRole == AppConstants.roleModerator))) {
      selectedRole = initialRole;
    } else {
      selectedRole = (currentRole == AppConstants.roleHeadAdmin)
          ? AppConstants.roleAdmin
          : AppConstants.roleModerator;
    }

    _showSheet(
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                    const SizedBox(height: 16),
                    const Text(
                      'Assign New Staff Member',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Grant administrative or moderation privileges to team personnel.',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(
                          color: Color(0xFF0F172A), fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        hintText: 'e.g. Arifur Rahman',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        labelStyle: const TextStyle(color: Color(0xFF64748B)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(
                          color: Color(0xFF0F172A), fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'SaveBite Work Email',
                        hintText: 'e.g. arifur.staff@savebite.com',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        labelStyle: const TextStyle(color: Color(0xFF64748B)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    const Text(
                      'Select Staff Role:',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (currentRole == AppConstants.roleHeadAdmin) ...[
                      _buildRoleOptionCard(
                        roleKey: AppConstants.roleHeadAdmin,
                        roleTitle: 'Head Admin (Level 1)',
                        badgeText: '👑 Supreme Role',
                        description:
                            'Full system authority. Can add and remove Admins & Moderators.',
                        isSelected:
                            selectedRole == AppConstants.roleHeadAdmin,
                        onTap: () => setModalState(() =>
                            selectedRole = AppConstants.roleHeadAdmin),
                      ),
                      const SizedBox(height: 8),
                      _buildRoleOptionCard(
                        roleKey: AppConstants.roleAdmin,
                        roleTitle: 'Admin (Level 2)',
                        badgeText: '🛡️ Operations Role',
                        description:
                            'Can manage partners, posts, banners, and vouchers. Can add & remove Moderators.',
                        isSelected: selectedRole == AppConstants.roleAdmin,
                        onTap: () => setModalState(
                            () => selectedRole = AppConstants.roleAdmin),
                      ),
                      const SizedBox(height: 8),
                      _buildRoleOptionCard(
                        roleKey: AppConstants.roleModerator,
                        roleTitle: 'Moderator (Level 3)',
                        badgeText: '🔍 Moderation Role',
                        description:
                            'Can verify/block partner kitchens, moderate surplus deals, and manage community posts.',
                        isSelected:
                            selectedRole == AppConstants.roleModerator,
                        onTap: () => setModalState(() =>
                            selectedRole = AppConstants.roleModerator),
                      ),
                    ] else ...[
                      _buildRoleOptionCard(
                        roleKey: AppConstants.roleModerator,
                        roleTitle: 'Moderator (Level 3)',
                        badgeText: '🔍 Moderation Role',
                        description:
                            'Can verify/block partner kitchens, moderate surplus deals, and manage community posts.',
                        isSelected: true,
                        onTap: () {},
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline,
                                size: 14, color: Color(0xFF64748B)),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Admins can add and manage Moderators. Adding Admins requires Head Admin access.',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 10.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: FilledButton(
                        onPressed: () {
                          final name = nameCtrl.text.trim();
                          final email = emailCtrl.text.trim().toLowerCase();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Please enter staff member name.'),
                                backgroundColor: Color(0xFFDC2626),
                              ),
                            );
                            return;
                          }
                          if (email.isEmpty || !email.contains('@')) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Please enter a valid work email.'),
                                backgroundColor: Color(0xFFDC2626),
                              ),
                            );
                            return;
                          }

                          if (_staffMembers.any((s) =>
                              (s['email'] as String).toLowerCase() ==
                              email)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'A staff member with this email already exists.'),
                                backgroundColor: Color(0xFFDC2626),
                              ),
                            );
                            return;
                          }

                          setState(() {
                            _staffMembers.add({
                              'id':
                                  'staff-${DateTime.now().millisecondsSinceEpoch}',
                              'name': name,
                              'email': email,
                              'role': selectedRole,
                              'assignedAt': 'Today',
                              'status': 'active',
                              'isPrimary': false,
                            });
                            // Automatically switch to the assigned role tab so the new member is visible immediately
                            _selectedStaffRole = selectedRole;
                          });

                          Navigator.pop(ctx);

                          final roleName =
                              selectedRole == AppConstants.roleHeadAdmin
                                  ? 'Head Admin'
                                  : selectedRole == AppConstants.roleAdmin
                                      ? 'Admin'
                                      : 'Moderator';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Added $name as $roleName successfully!'),
                              backgroundColor: const Color(0xFF16A34A),
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Confirm & Assign Role',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
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
      ),
    );
  }

  Widget _buildRoleOptionCard({
    required String roleKey,
    required String roleTitle,
    required String badgeText,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF1F2) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              size: 18,
              color: isSelected ? AppColors.primary : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        roleTitle,
                        style: TextStyle(
                          color: const Color(0xFF0F172A),
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w700,
                        ),
                      ),
                      Text(
                        badgeText,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.primary
                              : const Color(0xFF64748B),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      height: 1.3,
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

  // ==============================================================================
  // 8. MODALS & TOOLS (VERIFICATION, VOUCHERS, TELEMETRY, BROADCAST)
  // ==============================================================================

  void _showRestaurantDossierModal(
      BuildContext context, Map<String, dynamic> r) {
    _showSheet(
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
            Text(
              '${r['name']} — Partner Dossier',
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            _buildDossierRow('Contact Phone', r['phone'] as String),
            _buildDossierRow('Trade License No.', r['tradeLicense'] as String),
            _buildDossierRow('National ID (NID)', r['nid'] as String),
            _buildDossierRow(
                'Area / Division', '${r['area']}, ${r['division']}'),
            _buildDossierRow('Verification Status',
                r['isVerified'] == true ? 'Verified' : 'Pending Audit'),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Close Dossier',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDossierRow(String key, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
          Text(value,
              style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  void _showVerificationsModal(BuildContext context) {
    _showSheet(
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
            const Text(
              'Trade License & NID Approvals Queue',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            ..._verificationRequests.map(
              (req) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.shield_outlined,
                          color: Color(0xFF0284C7), size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(req['restaurantName'] as String,
                              style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13)),
                          Text(
                              'Trade: ${req['tradeLicense']}\nOwner: ${req['ownerName']}',
                              style: const TextStyle(
                                  color: Color(0xFF64748B), fontSize: 11)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _verificationRequests.remove(req);
                          final rest = _restaurantsData.firstWhere(
                              (r) => r['name'] == req['restaurantName'],
                              orElse: () => {});
                          if (rest.isNotEmpty) {
                            rest['isVerified'] = true;
                            rest['status'] = 'approved';
                          }
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '${req['restaurantName']} trade license verified!'),
                            backgroundColor: const Color(0xFF16A34A),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Verify',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVouchersModal(BuildContext context) {
    _showSheet(
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
            const Text(
              'Campaign Vouchers & Perks',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            ..._vouchersData.map(
              (v) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.confirmation_number_rounded,
                      color: Color(0xFFD97706)),
                ),
                title: Text(v['code'] as String,
                    style: const TextStyle(
                        color: Color(0xFF0F172A), fontWeight: FontWeight.w800)),
                subtitle: Text(v['discount'] as String,
                    style: const TextStyle(color: Color(0xFF64748B))),
                trailing: Text('${v['usedCount']} uses',
                    style: const TextStyle(
                        color: Color(0xFF94A3B8), fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateVoucherModal(BuildContext context) {
    final codeCtrl = TextEditingController();
    final discountCtrl = TextEditingController();

    _showSheet(
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
            const Text('Generate New Voucher Code',
                style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 17,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            TextField(
              controller: codeCtrl,
              style: const TextStyle(color: Color(0xFF0F172A)),
              decoration: InputDecoration(
                hintText: 'e.g. MONSOON30',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                labelText: 'Coupon Code',
                labelStyle: const TextStyle(color: Color(0xFF64748B)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: discountCtrl,
              style: const TextStyle(color: Color(0xFF0F172A)),
              decoration: InputDecoration(
                hintText: 'e.g. ৳30 OFF on orders above ৳150',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                labelText: 'Discount Description',
                labelStyle: const TextStyle(color: Color(0xFF64748B)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton(
                onPressed: () {
                  final code = codeCtrl.text.trim();
                  if (code.isNotEmpty) {
                    setState(() {
                      _vouchersData.add({
                        'code': code.toUpperCase(),
                        'title': code.toUpperCase(),
                        'discount': discountCtrl.text.trim().isEmpty
                            ? '৳30 OFF'
                            : discountCtrl.text.trim(),
                        'type': 'Flat',
                        'status': 'Active',
                        'usedCount': 0,
                      });
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Voucher "$code" generated and live!'),
                        backgroundColor: const Color(0xFF16A34A),
                      ),
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Publish Voucher',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAdRevenueModal(BuildContext context) {
    _showSheet(
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
            const Text('Promotion & Boost Ad Revenue',
                style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 17,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            _buildDossierRow('24h Hero Banners (৳2,000)', '6 Active (৳12,000)'),
            _buildDossierRow('24h Meal Boosts (৳600)', '7 Active (৳4,200)'),
            _buildDossierRow('Gold Monthly Memberships', '2 Active (৳2,000)'),
            const Divider(color: Color(0xFFF1F5F9)),
            _buildDossierRow('Total Ad Monetization', '৳18,200 BDT'),
          ],
        ),
      ),
    );
  }

  void _showUserDirectoryModal(BuildContext context) {
    _showSheet(
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
            const Text('Platform User Directory',
                style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 17,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            _buildDossierRow('Registered Customers', '1,248 accounts'),
            _buildDossierRow('Super Saver Subscribers', '312 accounts'),
            _buildDossierRow('Registered Restaurant Owners', '52 accounts'),
            _buildDossierRow('Platform Administrators', '2 accounts'),
          ],
        ),
      ),
    );
  }

  void _showTelemetryModal(BuildContext context) {
    _showSheet(
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
            const Text('Environmental Telemetry & Impact',
                style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 17,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            _buildDossierRow('Total Surplus Food Saved', '1,428.5 kg'),
            _buildDossierRow('Atmospheric CO₂ Prevented', '3,571.2 kg'),
            _buildDossierRow('Equivalent Trees Planted', '178 Trees'),
            _buildDossierRow('Top Rescue Hub', 'Dhanmondi (38% volume)'),
          ],
        ),
      ),
    );
  }

  void _showBroadcastNotificationModal(BuildContext context) {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();

    _showSheet(
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
            const Text('Broadcast Platform Notification',
                style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 17,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            TextField(
              controller: titleCtrl,
              style: const TextStyle(color: Color(0xFF0F172A)),
              decoration: InputDecoration(
                hintText: 'e.g. 50% Evening Clearance Alert!',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                labelText: 'Alert Headline',
                labelStyle: const TextStyle(color: Color(0xFF64748B)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: bodyCtrl,
              style: const TextStyle(color: Color(0xFF0F172A)),
              decoration: InputDecoration(
                hintText: 'e.g. 12 fresh surplus boxes available in Dhanmondi.',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                labelText: 'Message Body',
                labelStyle: const TextStyle(color: Color(0xFF64748B)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Broadcast sent to all active customer devices!'),
                      backgroundColor: Color(0xFF16A34A),
                    ),
                  );
                },
                icon: const Icon(Icons.send_rounded, size: 16),
                label: const Text('Send Broadcast Alert',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReviewsModerationModal(BuildContext context) {
    _showSheet(
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Customer Reviews & Ratings',
                    style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 17,
                        fontWeight: FontWeight.w900)),
                Text('4.8★ Platform Rating',
                    style: TextStyle(
                        color: Color(0xFFD97706),
                        fontSize: 12,
                        fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 12),
            _buildActionItemCard(
              title: "Sultan's Dine • 5.0★ (Rahim Ahmed)",
              subtitle:
                  '"Hot biryani rescued at 50% discount! Amazing taste and fresh packaging."',
              actionLabel: 'Verified Review',
              icon: Icons.star_rounded,
              iconColor: const Color(0xFFD97706),
              onAction: () => Navigator.pop(ctx),
            ),
            const SizedBox(height: 8),
            _buildActionItemCard(
              title: 'Bread & Beyond • 4.8★ (Nusrat Jahan)',
              subtitle:
                  '"Super fresh artisanal sourdough bread. Thank you SaveBite!"',
              actionLabel: 'Verified Review',
              icon: Icons.star_rounded,
              iconColor: const Color(0xFFD97706),
              onAction: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _showAuditLogsModal(BuildContext context) {
    _showSheet(
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
            const Text('Security Audit & Access Trail',
                style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 17,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            _buildDossierRow('Admin Session', 'TLS 1.3 • AES-256 Encrypted'),
            _buildDossierRow(
                'RLS Policy Audit', '100% Passed (14 Tables Active)'),
            _buildDossierRow('Last Approvals',
                'Kacchi Bhai Express verified at 08:30 AM'),
            _buildDossierRow('System Node', 'Dhaka Cluster #01 (Online)'),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminImagePreview(
    String url, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    bool isCircle = false,
  }) {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isCircle ? null : BorderRadius.circular(6),
        ),
        child: Icon(
          Icons.image,
          size: width != null ? width * 0.6 : 28,
          color: const Color(0xFF94A3B8),
        ),
      );
    }

    Widget imageWidget;
    if (cleanUrl.startsWith('data:image')) {
      try {
        final commaIndex = cleanUrl.indexOf(',');
        final base64Str =
            commaIndex != -1 ? cleanUrl.substring(commaIndex + 1) : cleanUrl;
        final bytes = base64Decode(base64Str);
        imageWidget = Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.broken_image, color: Colors.grey),
        );
      } catch (_) {
        imageWidget = const Icon(Icons.broken_image, color: Colors.grey);
      }
    } else if (cleanUrl.startsWith('assets/')) {
      imageWidget = Image.asset(
        cleanUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image, color: Colors.grey),
      );
    } else {
      imageWidget = Image.network(
        cleanUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image, color: Colors.grey),
      );
    }

    if (isCircle) {
      return ClipOval(child: imageWidget);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: imageWidget,
    );
  }
}
