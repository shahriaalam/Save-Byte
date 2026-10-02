import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../shared/models/restaurant.dart';
import '../presentation/restaurant_controller.dart';

class RestaurantDashboardScreen extends ConsumerWidget {
  const RestaurantDashboardScreen({super.key});

  void _showIncompleteProfileDialog(BuildContext context, Restaurant restaurant) {
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
              style: TextStyle(fontSize: 13, height: 1.35, color: AppColors.textPrimary),
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
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.error),
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
                            child: Icon(Icons.circle, size: 6, color: AppColors.error),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item,
                              style: const TextStyle(fontSize: 11.5, color: AppColors.textPrimary),
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
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider);
    final restaurantAsync = ref.watch(currentRestaurantProvider);
    final offersAsync = ref.watch(currentRestaurantOffersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Restaurant Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: 'Restaurant Profile',
            onPressed: () {
              context.push(AppRoutes.restaurantProfile);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Log Out',
            onPressed: () async {
              final confirmed = await ConfirmDialog.show(
                context,
                title: 'Log Out',
                message: 'Are you sure you want to log out?',
                confirmLabel: 'Log Out',
              );
              if (confirmed) {
                await ref.read(authControllerProvider.notifier).signOut();
              }
            },
          ),
        ],
      ),
      body: restaurantAsync.when(
        data: (restaurant) {
          if (restaurant == null) {
            return const Center(child: Text('Restaurant account not found.'));
          }

          final isComplete = restaurant.isProfileComplete;

          return SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(currentRestaurantProvider);
                ref.invalidate(currentRestaurantOffersProvider);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Restaurant Header Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Restaurant Profile Picture
                          GestureDetector(
                            onTap: () => context.push(AppRoutes.restaurantProfile),
                            child: CircleAvatar(
                              radius: 30,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              backgroundImage: restaurant.imageUrl != null
                                  ? NetworkImage(restaurant.imageUrl!)
                                  : null,
                              child: restaurant.imageUrl == null
                                  ? const Icon(
                                      Icons.storefront_rounded,
                                      size: 30,
                                      color: AppColors.primary,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  restaurant.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.place_rounded,
                                      size: 13,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        '${restaurant.area ?? 'Area not set'}, ${restaurant.division ?? 'Dhaka'}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  profile?.email ?? '',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          StatusBadge.fromStatus(restaurant.status),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Profile Completeness Status Card (Enforces Post Placement Rule)
                    Container(
                      padding: const EdgeInsets.all(14),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isComplete
                                    ? Icons.check_circle_rounded
                                    : Icons.warning_amber_rounded,
                                color: isComplete
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFD97706),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isComplete
                                      ? 'Profile Complete (Dhaka Verified)'
                                      : 'Profile Incomplete - Cannot Post Offers',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isComplete
                                        ? const Color(0xFF15803D)
                                        : const Color(0xFFB45309),
                                  ),
                                ),
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                ),
                                onPressed: () {
                                  context.push(AppRoutes.restaurantProfile);
                                },
                                child: Text(
                                  isComplete ? 'Edit' : 'Fix Now',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: isComplete
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFFD97706),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (!isComplete) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Missing: ${restaurant.missingProfileFields.join(', ')}. '
                              'You must complete all details and upload your restaurant profile picture before you can place food posts.',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF78350F),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Action Buttons (Post Surplus Food & Edit Profile)
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: PrimaryButton(
                            text: 'Post Surplus Food',
                            icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                            onPressed: () {
                              if (!isComplete) {
                                _showIncompleteProfileDialog(context, restaurant);
                              } else {
                                context.push(AppRoutes.restaurantCreateOffer);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              side: const BorderSide(color: AppColors.border),
                            ),
                            icon: const Icon(Icons.store_rounded, size: 17, color: AppColors.textPrimary),
                            label: const Text(
                              'Profile',
                              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                            ),
                            onPressed: () {
                              context.push(AppRoutes.restaurantProfile);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Section Heading: My Food Offers / Posts
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'My Food Offers',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        offersAsync.maybeWhen(
                          data: (offers) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${offers.length} Active',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          orElse: () => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Offers List
                    offersAsync.when(
                      data: (offers) {
                        if (offers.isEmpty) {
                          return EmptyState(
                            title: 'No food offers posted yet',
                            message: isComplete
                                ? 'Tap "Post Surplus Food" to list discounted food for discovery in Dhaka!'
                                : 'Complete your restaurant profile to start posting surplus food offers.',
                            icon: Icons.fastfood_outlined,
                            actionText: isComplete
                                ? 'Post Food Offer'
                                : 'Complete Profile',
                            onAction: () {
                              if (isComplete) {
                                context.push(AppRoutes.restaurantCreateOffer);
                              } else {
                                context.push(AppRoutes.restaurantProfile);
                              }
                            },
                          );
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: offers.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final offer = offers[index];
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Offer Image
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      offer.imageUrl ?? '',
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        width: 70,
                                        height: 70,
                                        color: const Color(0xFFF1F5F9),
                                        child: const Icon(Icons.fastfood_rounded, color: AppColors.textSecondary),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          offer.title,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Category: ${offer.category} • ${offer.quantity} available',
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Text(
                                              '${AppConstants.currencySymbol}${offer.discountedPrice.toInt()}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${AppConstants.currencySymbol}${offer.originalPrice.toInt()}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textMuted,
                                                decoration: TextDecoration.lineThrough,
                                              ),
                                            ),
                                            const Spacer(),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
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
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const LoadingState(message: 'Loading your food offers...'),
                      error: (err, _) => Text('Error loading offers: $err'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading dashboard: $err')),
      ),
    );
  }
}
