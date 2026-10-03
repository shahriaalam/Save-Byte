import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/location_constants.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../shared/widgets/offer_card.dart';
import '../offers/presentation/customer_offers_controller.dart';

/// Customer search screen supporting search by food title, restaurant name and category (Section 24).
/// Redesigned with dynamic branded gradient hero header, floating search bar, and visual category carousel.
class CustomerSearchScreen extends ConsumerStatefulWidget {
  const CustomerSearchScreen({super.key});

  @override
  ConsumerState<CustomerSearchScreen> createState() =>
      _CustomerSearchScreenState();
}

class _CustomerSearchScreenState extends ConsumerState<CustomerSearchScreen> {
  final _searchController = TextEditingController();

  // Visual category items with images and icons matching the Home screen aesthetic
  static final List<Map<String, dynamic>> _visualCategories = [
    {
      'name': 'All',
      'icon': '🍽️',
      'imageUrl':
          'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=200',
      'category': 'All',
    },
    {
      'name': 'Burger',
      'icon': '🍔',
      'imageUrl':
          'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=200',
      'category': 'Burger',
    },
    {
      'name': 'Biryani',
      'icon': '🍲',
      'imageUrl':
          'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=200',
      'category': 'Biryani',
    },
    {
      'name': 'Pizza',
      'icon': '🍕',
      'imageUrl':
          'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=200',
      'category': 'Pizza',
    },
    {
      'name': 'Chicken',
      'icon': '🍗',
      'imageUrl':
          'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=200',
      'category': 'Chicken',
    },
    {
      'name': 'Bakery',
      'icon': '🥐',
      'imageUrl':
          'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=200',
      'category': 'Bakery',
    },
    {
      'name': 'Rice',
      'icon': '🍛',
      'imageUrl':
          'https://images.unsplash.com/photo-1589302168068-964664d93dc0?w=200',
      'category': 'Rice',
    },
    {
      'name': 'Healthy',
      'icon': '🥗',
      'imageUrl':
          'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=200',
      'category': 'Healthy',
    },
    {
      'name': 'Drinks',
      'icon': '☕',
      'imageUrl':
          'https://images.unsplash.com/photo-1544787219-7f47ccb76574?w=200',
      'category': 'Drinks',
    },
    {
      'name': 'Snacks',
      'icon': '🍟',
      'imageUrl':
          'https://images.unsplash.com/photo-1576107232684-1279f3908594?w=200',
      'category': 'Snacks',
    },
    {
      'name': 'Dessert',
      'icon': '🍰',
      'imageUrl':
          'https://images.unsplash.com/photo-1587314168485-3236d6710814?w=200',
      'category': 'Dessert',
    },
  ];

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(searchQueryProvider);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetAllFilters() {
    _searchController.clear();
    ref.read(searchQueryProvider.notifier).setQuery('');
    ref.read(searchCategoryProvider.notifier).setCategory('All');
    ref.read(searchDivisionProvider.notifier).setDivision('All');
    ref.read(searchAreaProvider.notifier).setArea('All');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final searchResultsAsync = ref.watch(searchResultsProvider);
    final selectedCategory = ref.watch(searchCategoryProvider);
    final selectedDivision = ref.watch(searchDivisionProvider);
    final selectedArea = ref.watch(searchAreaProvider);
    final currentQuery = ref.watch(searchQueryProvider);

    final availableAreas = LocationConstants.getAreasForDivision(
      selectedDivision == 'All' ? 'Dhaka' : selectedDivision,
    );

    final hasLocationFilter =
        selectedDivision != 'All' || selectedArea != 'All';
    final hasActiveFilters = currentQuery.isNotEmpty ||
        selectedCategory != 'All' ||
        hasLocationFilter;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // 1. TOP BRANDED GRADIENT HERO HEADER WITH INTEGRATED SEARCH BAR
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFE23744),
                  Color(0xFFC62828),
                  Color(0xFF8B0000),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x33C62828),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Logo, Title & Reset action
                    Row(
                      children: [
                        const AppLogoIcon(
                          size: 38,
                          borderRadius: 12,
                          isInverted: true,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Search Food & Restaurants',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF4ADE80),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Discover surplus meals at 40-70% off',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (hasActiveFilters)
                          GestureDetector(
                            onTap: _resetAllFilters,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.35),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.refresh_rounded,
                                    color: Colors.white,
                                    size: 13,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Reset',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Elevated Pill Search Input
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: false,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        onChanged: (value) {
                          ref.read(searchQueryProvider.notifier).setQuery(value);
                          setState(() {});
                        },
                        decoration: InputDecoration(
                          hintText:
                              'Search biryani, burger, pizza, restaurant...',
                          hintStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF94A3B8),
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.search_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFE2E8F0),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      size: 14,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    ref
                                        .read(searchQueryProvider.notifier)
                                        .setQuery('');
                                    setState(() {});
                                  },
                                )
                              : const Padding(
                                  padding: EdgeInsets.only(right: 14),
                                  child: Icon(
                                    Icons.mic_none_rounded,
                                    color: Color(0xFF94A3B8),
                                    size: 20,
                                  ),
                                ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. LOCATION FILTERS (Division & Area Dropdowns)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              children: [
                // Division Selector
                Expanded(
                  flex: 11,
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selectedDivision != 'All'
                            ? AppColors.primary
                            : const Color(0xFFE2E8F0),
                        width: selectedDivision != 'All' ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: selectedDivision != 'All'
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedDivision,
                        isDense: true,
                        isExpanded: true,
                        icon: Icon(
                          Icons.arrow_drop_down_rounded,
                          color: selectedDivision != 'All'
                              ? AppColors.primary
                              : const Color(0xFF64748B),
                          size: 22,
                        ),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: selectedDivision != 'All'
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: selectedDivision != 'All'
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: 'All',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.map_outlined,
                                  size: 15,
                                  color: AppColors.textSecondary,
                                ),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'All Divisions',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          for (final div in LocationConstants.divisions)
                            DropdownMenuItem(
                              value: div,
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.location_city_rounded,
                                    size: 15,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      div,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            ref
                                .read(searchDivisionProvider.notifier)
                                .setDivision(value);
                            ref.read(searchAreaProvider.notifier).setArea('All');
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Area Selector
                Expanded(
                  flex: 12,
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selectedArea != 'All'
                            ? AppColors.primary
                            : const Color(0xFFE2E8F0),
                        width: selectedArea != 'All' ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: selectedArea != 'All'
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: availableAreas.contains(selectedArea)
                            ? selectedArea
                            : 'All',
                        isDense: true,
                        isExpanded: true,
                        icon: Icon(
                          Icons.arrow_drop_down_rounded,
                          color: selectedArea != 'All'
                              ? AppColors.primary
                              : const Color(0xFF64748B),
                          size: 22,
                        ),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: selectedArea != 'All'
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: selectedArea != 'All'
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: 'All',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.place_outlined,
                                  size: 15,
                                  color: AppColors.textSecondary,
                                ),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'All Areas',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          for (final area in availableAreas)
                            DropdownMenuItem(
                              value: area,
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.place_rounded,
                                    size: 15,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      area,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            ref
                                .read(searchAreaProvider.notifier)
                                .setArea(value);
                          }
                        },
                      ),
                    ),
                  ),
                ),

                // Clear Location Filter Button
                if (hasLocationFilter) ...[
                  const SizedBox(width: 8),
                  Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      tooltip: 'Clear location filter',
                      icon: const Icon(
                        Icons.filter_alt_off_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      onPressed: () {
                        ref
                            .read(searchDivisionProvider.notifier)
                            .setDivision('All');
                        ref
                            .read(searchAreaProvider.notifier)
                            .setArea('All');
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 3. VISUAL CATEGORY SELECTOR CAROUSEL (Like Customer Home Screen)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Food Categories',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                if (selectedCategory != 'All')
                  GestureDetector(
                    onTap: () {
                      ref
                          .read(searchCategoryProvider.notifier)
                          .setCategory('All');
                    },
                    child: const Text(
                      'Reset Category',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 94,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _visualCategories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
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
                    ref
                        .read(searchCategoryProvider.notifier)
                        .setCategory(selectedCategory == cat ? 'All' : cat);
                  },
                  label: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
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
                                  ? AppColors.primary.withValues(alpha: 0.28)
                                  : Colors.black.withValues(alpha: 0.05),
                              blurRadius: isSelected ? 10 : 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(2.5),
                        child: ClipOval(
                          child: Image.network(
                            item['imageUrl'] as String,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Center(
                              child: Text(
                                item['icon'] as String,
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item['name'] as String,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? AppColors.primary
                              : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // 4. RESULTS HEADER & SEARCH RESULTS LIST
          Expanded(
            child: searchResultsAsync.when(
              data: (offers) {
                if (offers.isEmpty) {
                  return EmptyState(
                    title: 'No matching food found',
                    message:
                        'Try searching for another dish, restaurant name, or category.',
                    icon: Icons.search_off_rounded,
                    actionText: hasActiveFilters ? 'Clear All Filters' : null,
                    onAction: hasActiveFilters ? _resetAllFilters : null,
                  );
                }

                return Column(
                  children: [
                    // Section Results Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Surplus Deals',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFBFDBFE),
                                  ),
                                ),
                                child: Text(
                                  '${offers.length} found',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1D4ED8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFFECACA),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.local_fire_department_rounded,
                                  size: 13,
                                  color: AppColors.primary,
                                ),
                                SizedBox(width: 3),
                                Text(
                                  'Best Deals First',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Active Filter Badges (if any active filters)
                    if (hasActiveFilters)
                      SizedBox(
                        height: 32,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            if (currentQuery.isNotEmpty)
                              _buildActiveFilterChip(
                                label: '"$currentQuery"',
                                icon: Icons.search_rounded,
                                onRemove: () {
                                  _searchController.clear();
                                  ref
                                      .read(searchQueryProvider.notifier)
                                      .setQuery('');
                                  setState(() {});
                                },
                              ),
                            if (selectedCategory != 'All')
                              _buildActiveFilterChip(
                                label: selectedCategory,
                                icon: Icons.restaurant_rounded,
                                onRemove: () {
                                  ref
                                      .read(searchCategoryProvider.notifier)
                                      .setCategory('All');
                                },
                              ),
                            if (selectedDivision != 'All')
                              _buildActiveFilterChip(
                                label: selectedDivision,
                                icon: Icons.map_outlined,
                                onRemove: () {
                                  ref
                                      .read(searchDivisionProvider.notifier)
                                      .setDivision('All');
                                },
                              ),
                            if (selectedArea != 'All')
                              _buildActiveFilterChip(
                                label: selectedArea,
                                icon: Icons.place_rounded,
                                onRemove: () {
                                  ref
                                      .read(searchAreaProvider.notifier)
                                      .setArea('All');
                                },
                              ),
                          ],
                        ),
                      ),

                    // Offers List
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 110),
                        itemCount: offers.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final offer = offers[index];
                          return OfferCard(
                            offer: offer,
                            onTap: () {
                              context.push('/customer/offers/${offer.id}');
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
              loading: () =>
                  const LoadingState(message: 'Searching offers...'),
              error: (_, _) => ErrorState(
                message: 'Failed to search offers.',
                onRetry: () => ref.refresh(searchResultsProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilterChip({
    required String label,
    required IconData icon,
    required VoidCallback onRemove,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onRemove,
              child: const Icon(
                Icons.close_rounded,
                size: 13,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
