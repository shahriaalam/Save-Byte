import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/review.dart';
import 'review_repository.dart';

/// Provider for list of reviews for a restaurant.
final restaurantReviewsProvider =
    FutureProvider.family<List<Review>, String>((ref, restaurantId) async {
  final repo = ref.watch(reviewRepositoryProvider);
  return repo.getReviewsForRestaurant(restaurantId);
});

/// Provider for aggregated rating stats for a restaurant.
final restaurantRatingSummaryProvider =
    FutureProvider.family<RestaurantRatingSummary, String>(
        (ref, restaurantId) async {
  final repo = ref.watch(reviewRepositoryProvider);
  return repo.getRatingSummary(restaurantId);
});

/// Provider for list of reviews written by a customer.
final customerReviewsProvider =
    FutureProvider.family<List<Review>, String>((ref, customerId) async {
  final repo = ref.watch(reviewRepositoryProvider);
  return repo.getReviewsForCustomer(customerId);
});

/// Provider checking whether an order has been reviewed.
final isOrderReviewedProvider =
    FutureProvider.family<bool, String>((ref, orderId) async {
  final repo = ref.watch(reviewRepositoryProvider);
  return repo.hasReviewedOrder(orderId);
});

/// Provider fetching a review for an order.
final orderReviewProvider =
    FutureProvider.family<Review?, String>((ref, orderId) async {
  final repo = ref.watch(reviewRepositoryProvider);
  return repo.getReviewForOrder(orderId);
});

/// Controller for creating and managing customer reviews.
class ReviewController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<Review?> submitReview({
    required String orderId,
    required String customerId,
    required String customerName,
    String? customerAvatarUrl,
    required String restaurantId,
    required String restaurantName,
    String? offerId,
    String? offerTitle,
    required double rating,
    required String comment,
    String? imageUrl,
  }) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(reviewRepositoryProvider);

      final review = Review(
        id: 'rev-${DateTime.now().millisecondsSinceEpoch}',
        orderId: orderId,
        customerId: customerId,
        customerName: customerName,
        customerAvatarUrl: customerAvatarUrl,
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        offerId: offerId,
        offerTitle: offerTitle,
        rating: rating,
        comment: comment.trim(),
        imageUrl: imageUrl,
        isVerified: true,
        createdAt: DateTime.now(),
      );

      final submitted = await repo.submitReview(review);

      // Invalidate relevant providers to update UI immediately
      ref.invalidate(restaurantReviewsProvider(restaurantId));
      ref.invalidate(restaurantReviewsProvider('res-blue-bell'));
      ref.invalidate(restaurantReviewsProvider('res-1'));
      ref.invalidate(restaurantReviewsProvider('demo-restaurant-id'));

      ref.invalidate(restaurantRatingSummaryProvider(restaurantId));
      ref.invalidate(restaurantRatingSummaryProvider('res-blue-bell'));
      ref.invalidate(restaurantRatingSummaryProvider('res-1'));
      ref.invalidate(restaurantRatingSummaryProvider('demo-restaurant-id'));

      ref.invalidate(customerReviewsProvider(customerId));
      ref.invalidate(customerReviewsProvider('demo-customer-id'));

      ref.invalidate(isOrderReviewedProvider(orderId));
      ref.invalidate(orderReviewProvider(orderId));

      state = const AsyncData(null);
      return submitted;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }
}

final reviewControllerProvider =
    AsyncNotifierProvider<ReviewController, void>(ReviewController.new);
