import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/location_constants.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../shared/widgets/offer_card.dart';
import '../offers/presentation/customer_offers_controller.dart';

/// Customer search screen supporting search by food title, restaurant name and category (Section 24).
class CustomerSearchScreen extends ConsumerStatefulWidget {
  const CustomerSearchScreen({super.key});

  @override
  ConsumerState<CustomerSearchScreen> createState() =>
      _CustomerSearchScreenState();
}

class _CustomerSearchScreenState extends ConsumerState<CustomerSearchScreen> {
  final _searchController = TextEditingController();

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

  @override
  Widget build(BuildContext context) {
    final searchResultsAsync = ref.watch(searchResultsProvider);
    final selectedCategory = ref.watch(searchCategoryProvider);
    final selectedDivision = ref.watch(searchDivisionProvider);
    final selectedArea = ref.watch(searchAreaProvider);

    final availableAreas = LocationConstants.getAreasForDivision(
      selectedDivision == 'All' ? 'Dhaka' : selectedDivision,
    );

    final hasLocationFilter =
        selectedDivision != 'All' || selectedArea != 'All';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Search Food & Restaurants'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: TextField(
                controller: _searchController,
                autofocus: false,
                onChanged: (value) {
                  ref.read(searchQueryProvider.notifier).setQuery(value);
                },
                decoration: InputDecoration(
                  hintText: 'Search biryani, burger, pizza, restaurant...',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.primary,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(searchQueryProvider.notifier)
                                .setQuery('');
                            setState(() {});
                          },
                        )
                      : null,
                ),
              ),
            ),

            // Location Filters: Division & Area (Dhaka focus)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
              child: Row(
                children: [
                  // Division Selector
                  Expanded(
                    flex: 11,
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selectedDivision != 'All'
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedDivision,
                          isDense: true,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.arrow_drop_down_rounded,
                            color: AppColors.primary,
                            size: 20,
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
                                    size: 14,
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
                                      size: 14,
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
                              // Reset area if not supported in the new division
                              ref
                                  .read(searchAreaProvider.notifier)
                                  .setArea('All');
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Area Selector (Dhaka Areas)
                  Expanded(
                    flex: 12,
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selectedArea != 'All'
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: availableAreas.contains(selectedArea)
                              ? selectedArea
                              : 'All',
                          isDense: true,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.arrow_drop_down_rounded,
                            color: AppColors.primary,
                            size: 20,
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
                                    size: 14,
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
                                      size: 14,
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
                    const SizedBox(width: 6),
                    IconButton(
                      visualDensity: VisualDensity.compact,
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
                  ],
                ],
              ),
            ),

            // Horizontal Category Filter Pills (Section 24 & 25)
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildSearchFilterChip(
                    label: 'All',
                    isSelected: selectedCategory == 'All',
                    onTap: () {
                      ref
                          .read(searchCategoryProvider.notifier)
                          .setCategory('All');
                    },
                  ),
                  for (final cat in AppConstants.categories)
                    _buildSearchFilterChip(
                      label: cat,
                      isSelected: selectedCategory == cat,
                      onTap: () {
                        ref
                            .read(searchCategoryProvider.notifier)
                            .setCategory(cat);
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Search results list
            Expanded(
              child: searchResultsAsync.when(
                data: (offers) {
                  if (offers.isEmpty) {
                    return const EmptyState(
                      title: 'No matching food found',
                      message:
                          'Try searching for another dish, restaurant name, or category.',
                      icon: Icons.search_off_rounded,
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
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
      ),
    );
  }

  Widget _buildSearchFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0, top: 4, bottom: 4),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.primary.withValues(alpha: 0.15),
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 12,
        ),
        onSelected: (_) => onTap(),
      ),
    );
  }
}
