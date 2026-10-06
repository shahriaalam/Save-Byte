import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/location_constants.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../shared/widgets/offer_card.dart';
import '../location/user_location_controller.dart';
import '../offers/presentation/customer_offers_controller.dart';

/// Screen displaying "Hot Deals" — food offers near the client with 45% or more discount.
class CustomerHotDealsScreen extends ConsumerStatefulWidget {
  const CustomerHotDealsScreen({super.key});

  @override
  ConsumerState<CustomerHotDealsScreen> createState() => _CustomerHotDealsScreenState();
}

class _CustomerHotDealsScreenState extends ConsumerState<CustomerHotDealsScreen> {
  static const List<String> _categories = [
    'All',
    'Rice',
    'Burger',
    'Pizza',
    'Fast Food',
    'Bakery',
    'Vegetarian',
    'Beverages',
  ];

  void _showAreaPickerSheet(BuildContext context, String currentArea) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
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
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.local_fire_department_rounded, color: Color(0xFFEA580C)),
                  SizedBox(width: 8),
                  Text(
                    'Select Hot Deals Location',
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
                'Show 45%+ surplus discounts near you in Dhaka',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),

              // Auto-detect GPS button inside sheet
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
                  'Pinpoint your closest Dhaka neighborhood',
                  style: TextStyle(fontSize: 11),
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final detected = await ref
                      .read(userLocationControllerProvider.notifier)
                      .requestPermissionAndDetect();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '📍 Location detected: $detected! Showing hot deals near you.',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: const Color(0xFF15803D),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
              const Divider(height: 16),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: currentArea == 'All'
                        ? const Color(0xFFFEF2F2)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.location_city_rounded,
                    color: currentArea == 'All' ? AppColors.primary : const Color(0xFF64748B),
                    size: 20,
                  ),
                ),
                title: const Text('All Dhaka (Everywhere)'),
                trailing: currentArea == 'All'
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                    : null,
                onTap: () {
                  ref.read(homeAreaProvider.notifier).setArea('All');
                  Navigator.pop(sheetContext);
                },
              ),
              const Divider(height: 16),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: LocationConstants.dhakaAreas.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final area = LocationConstants.dhakaAreas[idx];
                    final isSelected = currentArea == area;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFFEF2F2) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.near_me_rounded,
                          color: isSelected ? AppColors.primary : const Color(0xFF64748B),
                          size: 18,
                        ),
                      ),
                      title: Text(area),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                          : null,
                      onTap: () {
                        ref.read(homeAreaProvider.notifier).setArea(area);
                        Navigator.pop(sheetContext);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedArea = ref.watch(homeAreaProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final hotDealsAsync = ref.watch(hotDealsProvider);
    final allHotDealsAsync = ref.watch(allDhakaHotDealsProvider);
    final locationState = ref.watch(userLocationControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(hotDealsProvider);
          ref.invalidate(allDhakaHotDealsProvider);
          await ref.read(hotDealsProvider.future);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Top Fiery Hot Deals Header
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF7F1D1D),
                      Color(0xFFBA1A2E),
                      Color(0xFFEA580C),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(28),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: Location button & Auto GPS trigger & 45%+ Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Area Selector Pill
                            Flexible(
                              child: GestureDetector(
                                onTap: () => _showAreaPickerSheet(context, selectedArea),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.25),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.location_on_rounded,
                                        color: Color(0xFFFDE047),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          selectedArea == 'All'
                                              ? (!locationState.isInsideDhaka && locationState.detectedArea != null
                                                  ? '${locationState.detectedArea} (All Deals)'
                                                  : 'Dhaka (All)')
                                              : (locationState.isAutoDetected &&
                                                      locationState.detectedArea == selectedArea
                                                  ? '$selectedArea (GPS)'
                                                  : selectedArea),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: Colors.white70,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // GPS Auto-detect quick button
                            GestureDetector(
                              onTap: () async {
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
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.20),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 0.8,
                                  ),
                                ),
                                child: locationState.isDetecting
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            locationState.isAutoDetected
                                                ? Icons.my_location_rounded
                                                : Icons.near_me_rounded,
                                            color: const Color(0xFFFDE047),
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            locationState.isAutoDetected ? 'Located' : 'Detect GPS',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // 45%+ OFF Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDE047),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.local_fire_department_rounded,
                                    color: Color(0xFF78350F),
                                    size: 15,
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    '45%+ OFF',
                                    style: TextStyle(
                                      color: Color(0xFF78350F),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Title & Subtitle
                        Text(
                          selectedArea == 'All'
                              ? '🔥 Hot Deals Near You'
                              : '🔥 Hot Deals in $selectedArea',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          selectedArea == 'All'
                              ? 'Surplus listings with 45% or more discount across Dhaka'
                              : 'Exclusive 45%+ surplus discounts near your detected location',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Location banner if user has not yet detected location via GPS
            if (!locationState.isAutoDetected && selectedArea == 'All')
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.share_location_rounded,
                          color: Color(0xFFD97706),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Share your location to see 45%+ deals closest to your doorstep.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => ref
                              .read(userLocationControllerProvider.notifier)
                              .requestPermissionAndDetect(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Allow GPS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Category Filter Chips
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, idx) {
                      final cat = _categories[idx];
                      final isSelected = selectedCategory == cat;

                      return FilterChip(
                        label: Text(cat),
                        selected: isSelected,
                        showCheckmark: false,
                        selectedColor: AppColors.primary.withValues(alpha: 0.12),
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                            width: isSelected ? 1.4 : 1.0,
                          ),
                        ),
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                          fontSize: 12,
                        ),
                        onSelected: (_) {
                          ref.read(selectedCategoryProvider.notifier).setCategory(
                                selectedCategory == cat ? 'All' : cat,
                              );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),

            // Deals List Header / Counter
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: hotDealsAsync.when(
                  data: (deals) => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${deals.length} Hot Deals Found',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (selectedArea != 'All') ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'in $selectedArea',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: const Text(
                          'Ranked highest % first',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
            ),

            // Hot Deals Offers Content
            hotDealsAsync.when(
              data: (deals) {
                if (deals.isEmpty) {
                  // Fallback: If no deals in local neighborhood, show helpful message and suggest all Dhaka hot deals
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFFECACA)),
                            ),
                            child: const Icon(
                              Icons.local_fire_department_rounded,
                              size: 38,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            selectedArea == 'All'
                                ? 'No 45%+ deals right now'
                                : 'No 45%+ deals in $selectedArea right now',
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Hot deals require 45% or more discount. Restaurants post fresh surplus drops daily between lunch and dinner closing.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          if (selectedArea != 'All' || selectedCategory != 'All')
                            ElevatedButton.icon(
                              onPressed: () {
                                ref.read(homeAreaProvider.notifier).setArea('All');
                                ref.read(selectedCategoryProvider.notifier).setCategory('All');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                              ),
                              icon: const Icon(Icons.explore_rounded, size: 17),
                              label: const Text(
                                'Explore All Dhaka 45%+ Deals',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          const SizedBox(height: 24),

                          // Show other Dhaka hot deals as recommendations if local area is empty
                          if (selectedArea != 'All')
                            allHotDealsAsync.when(
                              data: (dhakaDeals) {
                                if (dhakaDeals.isEmpty) return const SizedBox.shrink();
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(
                                          Icons.stars_rounded,
                                          color: Color(0xFFEA580C),
                                          size: 18,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'Recommended 45%+ Hot Deals in Dhaka',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    for (final offer in dhakaDeals)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: OfferCard(
                                          offer: offer,
                                          onTap: () => context.push('/customer/offers/${offer.id}'),
                                        ),
                                      ),
                                  ],
                                );
                              },
                              loading: () => const SizedBox.shrink(),
                              error: (error, stackTrace) => const SizedBox.shrink(),
                            ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final offer = deals[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: OfferCard(
                            offer: offer,
                            onTap: () => context.push('/customer/offers/${offer.id}'),
                          ),
                        );
                      },
                      childCount: deals.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: LoadingState(message: 'Loading 45%+ hot deals near you...'),
              ),
              error: (error, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorState(
                  message: 'Unable to load hot deals. Please try again.',
                  onRetry: () => ref.refresh(hotDealsProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
