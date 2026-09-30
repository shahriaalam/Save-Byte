import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_state.dart';
import '../../../shared/widgets/offer_card.dart';
import '../../offers/presentation/customer_offers_controller.dart';

/// Restaurant details screen displaying restaurant info and active offers (Section 23).
class CustomerRestaurantDetailsScreen extends ConsumerWidget {
  const CustomerRestaurantDetailsScreen({
    required this.restaurantId,
    super.key,
  });

  final String restaurantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantAsync = ref.watch(restaurantDetailsProvider(restaurantId));
    final offersAsync =
        ref.watch(restaurantActiveOffersProvider(restaurantId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: restaurantAsync.when(
        data: (restaurant) {
          if (restaurant == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Restaurant Details')),
              body: const Center(child: Text('Restaurant not found.')),
            );
          }

          return CustomScrollView(
            slivers: [
              // Collapsible banner app bar
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    restaurant.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      restaurant.imageUrl != null
                          ? Image.network(
                              restaurant.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                color: AppColors.surfaceVariant,
                                child: const Icon(
                                  Icons.storefront_rounded,
                                  size: 64,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            )
                          : Container(
                              color: AppColors.surfaceVariant,
                              child: const Icon(
                                Icons.storefront_rounded,
                                size: 64,
                                color: AppColors.textMuted,
                              ),
                            ),
                      // Gradient overlay for title contrast
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black54,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Restaurant information details (Section 23)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cuisine chip & status
                      Row(
                        children: [
                          if (restaurant.cuisineType != null &&
                              restaurant.cuisineType!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                restaurant.cuisineType!,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 14,
                                  color: AppColors.success,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Verified Partner',
                                  style: TextStyle(
                                    color: AppColors.success,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Description
                      if (restaurant.description != null &&
                          restaurant.description!.isNotEmpty) ...[
                        Text(
                          restaurant.description!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Info card: Address & Opening Hours
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              if (restaurant.address != null &&
                                  restaurant.address!.isNotEmpty)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 20,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Address',
                                            style: TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            restaurant.address!,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              if (restaurant.openingTime != null ||
                                  restaurant.closingTime != null) ...[
                                const Divider(height: 24),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time_rounded,
                                      size: 20,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Opening Hours',
                                            style: TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${restaurant.openingTime ?? "Open"} – ${restaurant.closingTime ?? "Close"}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (restaurant.phone != null &&
                                  restaurant.phone!.isNotEmpty) ...[
                                const Divider(height: 24),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.phone_outlined,
                                      size: 20,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Contact Phone',
                                            style: TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            restaurant.phone!,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Section Header: Available Offers (Section 23)
                      Text(
                        'Available Offers',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              // Active offers list
              offersAsync.when(
                data: (offers) {
                  if (offers.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                        child: EmptyState(
                          title: 'No active offers right now',
                          message:
                              'This restaurant has not published any surplus food offers for pickup currently.',
                          icon: Icons.fastfood_outlined,
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final offer = offers[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: OfferCard(
                              offer: offer,
                              onTap: () {
                                context.push('/customer/offers/${offer.id}');
                              },
                            ),
                          );
                        },
                        childCount: offers.length,
                      ),
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: LoadingState(message: 'Loading offers...'),
                  ),
                ),
                error: (_, _) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ErrorState(
                      message: 'Failed to load restaurant offers.',
                      onRetry: () => ref.refresh(
                        restaurantActiveOffersProvider(restaurantId),
                      ),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 32),
              ),
            ],
          );
        },
        loading: () => const Scaffold(
          body: LoadingState(message: 'Loading restaurant...'),
        ),
        error: (_, _) => Scaffold(
          appBar: AppBar(title: const Text('Restaurant Details')),
          body: ErrorState(
            message: 'Unable to load restaurant details.',
            onRetry: () =>
                ref.refresh(restaurantDetailsProvider(restaurantId)),
          ),
        ),
      ),
    );
  }
}
