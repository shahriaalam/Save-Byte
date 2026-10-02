import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/location_constants.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../auth/domain/user_profile.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../shared/models/food_offer.dart';
import '../../shared/models/restaurant.dart';
import '../../shared/widgets/offer_card.dart';
import '../location/user_location_controller.dart';
import '../offers/presentation/customer_offers_controller.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;

  // Curated hero slideshow banners matching 1st screenshot
  final List<Map<String, String>> _heroBanners = [
    {
      'title': 'SUPER SAVER DEALS',
      'discount': 'Up to 70% OFF',
      'code': 'Code: SAVE70 • Min order Tk 199',
      'badge': 'Dhaka Surplus Rescue',
      'tagline': 'Save delicious food from top restaurants',
    },
    {
      'title': 'FRESH EVENING DROP',
      'discount': '40% - 60% OFF',
      'code': 'Code: SURPLUS50 • Instant Pickup',
      'badge': 'Verified Quality',
      'tagline': 'Authentic biryani, burgers & bakery surplus',
    },
    {
      'title': 'ZERO FOOD WASTE',
      'discount': 'Save Wallet & Planet',
      'code': 'Daily 8 PM - 11 PM Drops',
      'badge': 'SaveBite Dhaka',
      'tagline': 'Join 10,000+ happy food savers in Dhaka',
    },
  ];

  // Visual category items with images and icons matching screenshots 1, 2, 3
  final List<Map<String, dynamic>> _visualCategories = [
    {
      'name': 'All',
      'icon': '🍽️',
      'imageUrl': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=200',
      'category': 'All',
    },
    {
      'name': 'Burger',
      'icon': '🍔',
      'imageUrl': 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=200',
      'category': 'Burger',
    },
    {
      'name': 'Biryani',
      'icon': '🍲',
      'imageUrl': 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=200',
      'category': 'Rice',
    },
    {
      'name': 'Pizza',
      'icon': '🍕',
      'imageUrl': 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=200',
      'category': 'Pizza',
    },
    {
      'name': 'Chicken',
      'icon': '🍗',
      'imageUrl': 'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=200',
      'category': 'Fast Food',
    },
    {
      'name': 'Bakery',
      'icon': '🥐',
      'imageUrl': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=200',
      'category': 'Bakery',
    },
    {
      'name': 'Healthy',
      'icon': '🥗',
      'imageUrl': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=200',
      'category': 'Vegetarian',
    },
    {
      'name': 'Drinks',
      'icon': '☕',
      'imageUrl': 'https://images.unsplash.com/photo-1544787219-7f47ccb76574?w=200',
      'category': 'Beverages',
    },
    {
      'name': 'Rice',
      'icon': '🍛',
      'imageUrl': 'https://images.unsplash.com/photo-1589302168068-964664d93dc0?w=200',
      'category': 'Rice',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Auto-advance banner slideshow
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_bannerController.hasClients) {
        final nextPage = (_currentBannerIndex + 1) % _heroBanners.length;
        _bannerController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  String _getGreeting(UserProfile? profile) {
    final hour = DateTime.now().hour;
    final timeGreeting = hour < 12
        ? 'Good morning'
        : (hour < 17 ? 'Good afternoon' : 'Good evening');
    final firstName = profile?.fullName?.trim().split(' ').firstOrNull;
    if (firstName != null && firstName.isNotEmpty) {
      return '$timeGreeting, $firstName 👋';
    }
    return '$timeGreeting 👋';
  }

  void _showAreaPickerSheet(BuildContext context, String currentArea) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
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
                    Icon(Icons.location_city_rounded, color: AppColors.primary, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Select Dhaka Area',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Browse surplus food deals close to your neighborhood',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.my_location_rounded,
                      color: Color(0xFF2563EB),
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Auto-detect My Location (GPS)',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E40AF),
                    ),
                  ),
                  subtitle: const Text(
                    'Automatically pinpoint nearest Dhaka area',
                    style: TextStyle(fontSize: 11),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final area = await ref
                        .read(userLocationControllerProvider.notifier)
                        .requestPermissionAndDetect();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '📍 Location detected: $area! Showing deals near you.',
                          ),
                          backgroundColor: const Color(0xFF15803D),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
                const Divider(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('All Dhaka Areas'),
                          selected: currentArea == 'All',
                          onSelected: (_) {
                            ref.read(homeAreaProvider.notifier).setArea('All');
                            Navigator.pop(ctx);
                          },
                        ),
                        for (final area in LocationConstants.dhakaAreas)
                          ChoiceChip(
                            label: Text(area),
                            selected: currentArea == area,
                            onSelected: (_) {
                              ref.read(homeAreaProvider.notifier).setArea(area);
                              Navigator.pop(ctx);
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentUserProfileProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final selectedArea = ref.watch(homeAreaProvider);
    final locationState = ref.watch(userLocationControllerProvider);
    final offersAsync = ref.watch(activeOffersProvider);
    final nearbyOffersAsync = ref.watch(nearbyOffersProvider);
    final nearbyRestaurantsAsync = ref.watch(activeRestaurantsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.refresh(activeOffersProvider.future),
            ref.refresh(nearbyOffersProvider.future),
            ref.refresh(activeRestaurantsProvider.future),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==========================================
              // 1. TOP MAROON HEADER & SLIDESHOW SECTION
              // (Matches 1st Screenshot - Rich Crimson Theme)
              // ==========================================
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF880015),
                      Color(0xFFA80D22),
                      Color(0xFFBA1A2E),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(32),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      // Top Row: Location / Deliver to & Notification
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                        child: Row(
                          children: [
                            // Location Icon in frosted circle
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.location_on_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Deliver to + Address
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _showAreaPickerSheet(context, selectedArea),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          'Deliver to',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 1.5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'SaveBite',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 1),
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            !locationState.isInsideDhaka && locationState.detectedArea != null
                                                ? '${locationState.detectedArea} (Dhaka Deals)'
                                                : (selectedArea == 'All'
                                                    ? 'Ave 3, Dhaka, Bangladesh'
                                                    : '$selectedArea, Dhaka, Bangladesh'),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w800,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // GPS Locate Quick Action
                            GestureDetector(
                              onTap: () async {
                                final area = await ref
                                    .read(userLocationControllerProvider.notifier)
                                    .requestPermissionAndDetect();
                                if (context.mounted) {
                                  final loc = ref.read(userLocationControllerProvider);
                                  final msg = !loc.isInsideDhaka
                                      ? '📍 Detected: $area (Outside Dhaka). Showing top Dhaka hot deals!'
                                      : '📍 Location detected: $area! Showing deals near you.';
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(msg),
                                      backgroundColor: loc.isInsideDhaka
                                          ? const Color(0xFF15803D)
                                          : const Color(0xFF1E293B),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: locationState.isDetecting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Icon(
                                        locationState.isAutoDetected
                                            ? Icons.my_location_rounded
                                            : Icons.near_me_outlined,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                              ),
                            ),

                            // Notification Bell
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Stack(
                                children: [
                                  const Icon(
                                    Icons.notifications_none_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFDE047),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Personalized Greeting Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _getGreeting(profile),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Find affordable food near you',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Super Saver Promo Slideshow Carousel (1st screenshot)
                      SizedBox(
                        height: 125,
                        child: PageView.builder(
                          controller: _bannerController,
                          onPageChanged: (idx) {
                            setState(() => _currentBannerIndex = idx);
                          },
                          itemCount: _heroBanners.length,
                          itemBuilder: (context, index) {
                            final b = _heroBanners[index];
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFDE047),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            b['title']!,
                                            style: const TextStyle(
                                              color: Color(0xFF78350F),
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          b['discount']!,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 17,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          b['code']!,
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.85),
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Visual rider / badge graphics
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.electric_moped_rounded,
                                        color: Colors.white,
                                        size: 42,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Slideshow Indicator Dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _heroBanners.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: _currentBannerIndex == i ? 18 : 6,
                            height: 5,
                            decoration: BoxDecoration(
                              color: _currentBannerIndex == i
                                  ? Colors.white
                                  : Colors.white38,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ),

              // ==========================================
              // 2. FLOATING SEARCH BAR (1st & 2nd Screenshot)
              // ==========================================
              Transform.translate(
                offset: const Offset(0, -18),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GestureDetector(
                    onTap: () => context.go(AppRoutes.customerSearch),
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: AppColors.primary,
                            size: 22,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Search food or restaurant...',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            Icons.mic_none_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ==========================================
              // 3. FOOD CATEGORY TILES (WITH PICTURE & TEXT)
              // (Matches 1st, 2nd & 3rd Screenshot)
              // ==========================================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Food Categories',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        if (selectedCategory != 'All')
                          GestureDetector(
                            onTap: () {
                              ref.read(selectedCategoryProvider.notifier).setCategory('All');
                            },
                            child: const Text(
                              'Reset Filter',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Picture Category Filters (Word boxes removed, 'All' included as picture filter)
                    SizedBox(
                      height: 96,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _visualCategories.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                        itemBuilder: (context, idx) {
                          final item = _visualCategories[idx];
                          final cat = item['category'] as String;
                          final isSelected = selectedCategory == cat;

                          return FilterChip(
                            selected: isSelected,
                            showCheckmark: false,
                            padding: EdgeInsets.zero,
                            labelPadding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            backgroundColor: Colors.transparent,
                            selectedColor: Colors.transparent,
                            disabledColor: Colors.transparent,
                            surfaceTintColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            selectedShadowColor: Colors.transparent,
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            onSelected: (_) {
                              ref.read(selectedCategoryProvider.notifier).setCategory(
                                    selectedCategory == cat ? 'All' : cat,
                                  );
                            },
                            label: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 62,
                                  height: 62,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : const Color(0xFFE2E8F0),
                                      width: isSelected ? 2.5 : 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isSelected
                                            ? AppColors.primary.withValues(alpha: 0.25)
                                            : Colors.black.withValues(alpha: 0.04),
                                        blurRadius: isSelected ? 8 : 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Image.network(
                                      item['imageUrl'] as String,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Center(
                                        child: Text(
                                          item['icon'] as String,
                                          style: const TextStyle(fontSize: 26),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item['name'] as String,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // ==========================================
              // 4. "OFFERS NEAR YOU" - POSTS OF NEARBY RESTAURANTS
              // ==========================================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Flexible(
                                child: Text(
                                  'Offers Near You',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  selectedArea == 'All' ? 'Dhaka' : selectedArea,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => context.go(AppRoutes.customerSearch),
                          child: const Text(
                            'See All',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Horizontal Scrolling Nearby Offer Cards
                    nearbyOffersAsync.when(
                      data: (offers) {
                        if (offers.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Text(
                              'No surplus offer posts in $selectedArea right now. Check back soon!',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        }

                        return SizedBox(
                          height: 220,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: offers.length,
                            separatorBuilder: (context, index) => const SizedBox(width: 12),
                            itemBuilder: (context, idx) {
                              final offer = offers[idx];
                              return _buildNearbyOfferCard(offer);
                            },
                          ),
                        );
                      },
                      loading: () => const SizedBox(
                        height: 220,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (error, stackTrace) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // ==========================================
              // 5. "SHOPS NEAR YOU" / SURPLUS NEAR ME
              // (Matches 4th Screenshot - Dhaka Location Active Restaurants)
              // ==========================================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Flexible(
                                child: Text(
                                  'Shops Near You',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  selectedArea == 'All' ? 'Dhaka' : selectedArea,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF15803D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => context.go(AppRoutes.customerSearch),
                          child: const Text(
                            'See All',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Horizontal Scrolling Nearby Restaurant Cards
                    nearbyRestaurantsAsync.when(
                      data: (restaurants) {
                        if (restaurants.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Text(
                              'No restaurants listed surplus in $selectedArea yet. Try exploring All Dhaka!',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        }

                        return SizedBox(
                          height: 156,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: restaurants.length,
                            separatorBuilder: (context, index) => const SizedBox(width: 12),
                            itemBuilder: (context, idx) {
                              final res = restaurants[idx];
                              return _buildNearbyShopCard(res);
                            },
                          ),
                        );
                      },
                      loading: () => const SizedBox(
                        height: 156,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (error, stackTrace) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // ==========================================
              // 5. "ALL RESTAURANTS" - RANKED BY DISCOUNT %
              // (Matches 5th Screenshot - Most % discount is #1)
              // ==========================================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'All Restaurants',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Ranked by highest discount % 🔥',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Highest % First',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Offers / Restaurants List Sorted by Discount %
                    offersAsync.when(
                      data: (offers) {
                        if (offers.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 24.0),
                            child: EmptyState(
                              title: 'No offers available right now',
                              message:
                                  'Check back shortly! Restaurants list surplus food in the evening before closing.',
                              icon: Icons.fastfood_outlined,
                            ),
                          );
                        }

                        return Column(
                          children: [
                            for (int i = 0; i < offers.length; i++) ...[
                              if (i > 0) const SizedBox(height: 14),
                              OfferCard(
                                offer: offers[i],
                                onTap: () {
                                  context.push('/customer/offers/${offers[i].id}');
                                },
                              ),
                            ],
                          ],
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.only(top: 48.0),
                        child: LoadingState(message: 'Loading available food...'),
                      ),
                      error: (error, _) => Padding(
                        padding: const EdgeInsets.only(top: 32.0),
                        child: ErrorState(
                          message: 'Unable to load food offers. Please try again.',
                          onRetry: () => ref.refresh(activeOffersProvider),
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


  // Nearby Offer Post Card matching user request for "Offers Near You"
  Widget _buildNearbyOfferCard(FoodOffer offer) {
    final savings = (offer.originalPrice - offer.discountedPrice).clamp(0, double.infinity);

    return GestureDetector(
      onTap: () => context.push('/customer/offers/${offer.id}'),
      child: Container(
        width: 205,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with Discount Tag & Remaining Quantity Badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  child: Container(
                    height: 108,
                    width: double.infinity,
                    color: const Color(0xFFF1F5F9),
                    child: offer.imageUrl != null
                        ? Image.network(
                            offer.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Center(
                              child: Icon(Icons.fastfood_rounded, color: AppColors.primary, size: 28),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.fastfood_rounded, color: AppColors.primary, size: 28),
                          ),
                  ),
                ),
                // Discount Badge on top left
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      '${offer.discountPercentage}% OFF',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                // Remaining Quantity on top right
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${offer.quantity} left',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Offer Information Content
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    offer.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),

                  // Restaurant Name
                  Row(
                    children: [
                      const Icon(
                        Icons.storefront_rounded,
                        size: 13,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          offer.restaurantName ?? 'Restaurant',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Pricing Row
                  Row(
                    children: [
                      Text(
                        '৳${offer.discountedPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '৳${offer.originalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 10.5,
                          decoration: TextDecoration.lineThrough,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      if (savings > 0)
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '-৳${savings.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF15803D),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
      ),
    );
  }

  // Nearby Restaurant Card matching 4th screenshot
  Widget _buildNearbyShopCard(Restaurant res) {
    return GestureDetector(
      onTap: () => context.push('/customer/restaurants/${res.id}'),
      child: Container(
        width: 170,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
            // Restaurant Logo / Banner
            Container(
              height: 58,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: res.imageUrl != null
                    ? Image.network(
                        res.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Icon(Icons.storefront_rounded, color: AppColors.primary),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.storefront_rounded, color: AppColors.primary),
                      ),
              ),
            ),
            const SizedBox(height: 6),

            // Restaurant Name
            Text(
              res.name,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),

            // Area & Distance
            Text(
              '${res.area ?? 'Dhaka'} • 15-30 mins',
              style: const TextStyle(
                fontSize: 10.5,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),

            // Discount Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFECACA), width: 0.8),
              ),
              child: const Text(
                'Up to 50% OFF',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
