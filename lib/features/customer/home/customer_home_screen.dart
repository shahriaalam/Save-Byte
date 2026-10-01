import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../auth/domain/user_profile.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../shared/widgets/offer_card.dart';
import '../offers/presentation/customer_offers_controller.dart';

class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final offersAsync = ref.watch(activeOffersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            const AppLogoIcon(size: 32),
            const SizedBox(width: 10),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
                children: [
                  TextSpan(
                    text: 'Save',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  TextSpan(
                    text: 'Bite',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: GestureDetector(
              onTap: () => context.go(AppRoutes.customerProfile),
              child: UserAvatar(
                avatarUrl: profile?.avatarUrl,
                name: profile?.fullName,
                radius: 17,
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(activeOffersProvider.future),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Greeting (Section 20)
              Text(
                _getGreeting(profile),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Find affordable food near you',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 16),

              // Search shortcut bar (Section 20)
              GestureDetector(
                onTap: () {
                  context.go(AppRoutes.customerSearch);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Search food or restaurant...',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Category Selector (Section 25)
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildCategoryChip(ref, 'All', selectedCategory == 'All'),
                    for (final category in AppConstants.categories)
                      _buildCategoryChip(
                        ref,
                        category,
                        selectedCategory == category,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Available Food section header (Section 20)
              Text(
                'Available Food',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 12),

              // Offers list / Async states
              offersAsync.when(
                data: (offers) {
                  if (offers.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 32.0),
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
                        if (i > 0) const SizedBox(height: 12),
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
      ),
    );
  }

  Widget _buildCategoryChip(WidgetRef ref, String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.primary.withValues(alpha: 0.15),
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 13,
        ),
        onSelected: (_) {
          ref.read(selectedCategoryProvider.notifier).setCategory(label);
        },
      ),
    );
  }
}
