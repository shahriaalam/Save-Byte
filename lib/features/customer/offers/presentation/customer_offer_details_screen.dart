import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/price_calculator.dart';
import '../../../../core/widgets/double_pull_reload.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_state.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../orders/presentation/order_checkout_sheet.dart';
import 'customer_offers_controller.dart';

class CustomerOfferDetailsScreen extends ConsumerWidget {
  const CustomerOfferDetailsScreen({
    required this.offerId,
    super.key,
  });

  final String offerId;

  String _formatTime(DateTime time) {
    final hour =
        time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offerAsync = ref.watch(offerDetailsProvider(offerId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Food Details'),
      ),
      body: offerAsync.when(
        data: (offer) {
          if (offer == null) {
            return const Center(
              child: Text('Offer not found or no longer available.'),
            );
          }

          return DoublePullReload(
            onReload: () async {
              ref.invalidate(offerDetailsProvider(offerId));
              await ref.read(offerDetailsProvider(offerId).future);
            },
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Food Image
                Container(
                  height: 240,
                  width: double.infinity,
                  color: AppColors.surfaceVariant,
                  child: offer.imageUrl != null
                      ? Image.network(
                          offer.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Center(
                            child: Icon(
                              Icons.restaurant_rounded,
                              size: 64,
                              color: AppColors.textMuted,
                            ),
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.restaurant_rounded,
                            size: 64,
                            color: AppColors.textMuted,
                          ),
                        ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category & Discount row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              offer.category,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (offer.discountPercentage > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${offer.discountPercentage}% OFF',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Food Title
                      Text(
                        offer.title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 6),

                      // Restaurant Name
                      if (offer.restaurantName != null)
                        Text(
                          offer.restaurantName!,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      const SizedBox(height: 16),

                      // Price & Savings Box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Special Price',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: AppColors.textMuted),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      PriceCalculator.format(offer.discountedPrice),
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      PriceCalculator.format(offer.originalPrice),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            decoration:
                                                TextDecoration.lineThrough,
                                            color: AppColors.textMuted,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Save ${PriceCalculator.format(offer.savings)}',
                                style: const TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Description
                      if (offer.description != null &&
                          offer.description!.isNotEmpty) ...[
                        Text(
                          'Description',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          offer.description!,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                    height: 1.5,
                                  ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Availability & Quantity Details Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              _buildDetailRow(
                                context,
                                icon: Icons.fastfood_outlined,
                                label: 'Available portions',
                                value: '${offer.quantity} portions',
                              ),
                              const Divider(height: 24),
                              _buildDetailRow(
                                context,
                                icon: Icons.access_time_rounded,
                                label: 'Pickup window',
                                value:
                                    '${_formatTime(offer.availableFrom)} – ${_formatTime(offer.availableUntil)}',
                              ),
                              if (offer.restaurantAddress != null) ...[
                                const Divider(height: 24),
                                _buildDetailRow(
                                  context,
                                  icon: Icons.location_on_outlined,
                                  label: 'Location',
                                  value: offer.restaurantAddress!,
                                ),
                              ],
                              const Divider(height: 24),
                              _buildDetailRow(
                                context,
                                icon: Icons.takeout_dining_rounded,
                                label: 'Fulfillment',
                                value: 'Takeaway / Self-Pickup Only (No Delivery)',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // [Order for Pickup] Button
                      PrimaryButton(
                        text: offer.quantity > 0
                            ? 'Order for Pickup (৳${offer.discountedPrice.toStringAsFixed(0)})'
                            : 'Sold Out',
                        icon: const Icon(Icons.shopping_bag_rounded, size: 20),
                        onPressed: offer.quantity > 0
                            ? () => showOrderCheckoutSheet(
                                  context: context,
                                  offer: offer,
                                )
                            : null,
                      ),
                      const SizedBox(height: 12),

                      // [View Restaurant Details] Secondary Action (Section 22)
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.storefront_rounded, size: 18, color: Color(0xFF1E293B)),
                          label: const Text(
                            'View Restaurant Details',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          onPressed: () {
                            context.push(
                              '/customer/restaurants/${offer.restaurantId}',
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // No home delivery notice
                      Center(
                        child: Text(
                          '🛍️ Takeaway / Self-Pickup Only • Pay online & pick up at the scheduled time.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                          textAlign: TextAlign.center,
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
        loading: () => const LoadingState(message: 'Loading offer details...'),
        error: (_, _) => ErrorState(
          message: 'Unable to load offer details.',
          onRetry: () => ref.refresh(offerDetailsProvider(offerId)),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}
