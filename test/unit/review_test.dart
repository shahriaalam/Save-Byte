import 'package:flutter_test/flutter_test.dart';
import 'package:save_bite/features/shared/data/review_repository.dart';
import 'package:save_bite/features/shared/models/review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Review Model & Rating Summary Tests', () {
    test('Review serializes to and from JSON correctly', () {
      final now = DateTime(2026, 10, 10, 12, 0);
      final review = Review(
        id: 'rev-test-1',
        orderId: 'ord-test-1',
        customerId: 'cust-1',
        customerName: 'Arafat Rahman',
        customerAvatarUrl: null,
        restaurantId: 'res-blue-bell',
        restaurantName: 'Blue Bell Café',
        offerId: 'off-1',
        offerTitle: 'Delicious Croissant',
        rating: 5.0,
        comment: 'Fresh, flaky and saved from surplus! Highly recommended.',
        imageUrl: 'data:image/jpeg;base64,samplephoto',
        isVerified: true,
        createdAt: now,
      );

      final map = review.toJson();
      expect(map['id'], 'rev-test-1');
      expect(map['order_id'], 'ord-test-1');
      expect(map['rating'], 5.0);
      expect(map['is_verified'], true);
      expect(map['image_url'], isNotEmpty);

      final fromJson = Review.fromJson(map);
      expect(fromJson.id, review.id);
      expect(fromJson.comment, review.comment);
      expect(fromJson.customerName, review.customerName);
      expect(fromJson.isVerified, isTrue);
      expect(fromJson.starsDisplay, '★★★★★');
    });

    test('RestaurantRatingSummary computes ratios and formatted average accurately', () {
      const summary = RestaurantRatingSummary(
        restaurantId: 'res-blue-bell',
        averageRating: 4.8,
        totalReviews: 10,
        fiveStarCount: 8,
        fourStarCount: 2,
        threeStarCount: 0,
        twoStarCount: 0,
        oneStarCount: 0,
        verifiedRescueCount: 10,
      );

      expect(summary.formattedAverage, '4.8');
      expect(summary.fiveStarRatio, 0.8);
      expect(summary.fourStarRatio, 0.2);
      expect(summary.threeStarRatio, 0.0);
      expect(summary.verifiedRescueCount, 10);
    });
  });

  group('ReviewRepository Tests', () {
    late SupabaseClient client;
    late ReviewRepository repo;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      client = SupabaseClient('https://test.supabase.co', 'test-anon-key');
      repo = ReviewRepository(client);
    });

    test('Default seed reviews are loaded for demo restaurants', () async {
      final reviews = await repo.getReviewsForRestaurant('res-blue-bell');
      expect(reviews, isNotEmpty);
      expect(reviews.any((r) => r.isVerified), isTrue);

      final summary = await repo.getRatingSummary('res-blue-bell');
      expect(summary.totalReviews, greaterThanOrEqualTo(1));
      expect(summary.averageRating, greaterThan(4.0));
      expect(summary.verifiedRescueCount, greaterThanOrEqualTo(1));
    });

    test('Customer can submit a verified review with photo and sentence feedback', () async {
      const orderId = 'ord-unit-test-999';
      expect(await repo.hasReviewedOrder(orderId), isFalse);

      final newReview = Review(
        id: 'rev-unit-test-100',
        orderId: orderId,
        customerId: 'demo-customer-id',
        customerName: 'Test Foodie',
        restaurantId: 'res-blue-bell',
        restaurantName: 'Blue Bell Café',
        offerTitle: 'Dinner Special',
        rating: 5.0,
        comment: 'Absolutely delightful evening takeaway! Food was still warm.',
        imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c',
        isVerified: true,
        createdAt: DateTime.now(),
      );

      final submitted = await repo.submitReview(newReview);
      expect(submitted.id, newReview.id);

      // Verify order is now marked reviewed
      expect(await repo.hasReviewedOrder(orderId), isTrue);

      // Verify review appears in restaurant reviews
      final restaurantReviews = await repo.getReviewsForRestaurant('res-blue-bell');
      expect(restaurantReviews.any((r) => r.orderId == orderId), isTrue);

      // Verify review appears in customer reviews
      final customerReviews = await repo.getReviewsForCustomer('demo-customer-id');
      expect(customerReviews.any((r) => r.orderId == orderId), isTrue);

      // Verify rating summary updates
      final updatedSummary = await repo.getRatingSummary('res-blue-bell');
      expect(updatedSummary.totalReviews, greaterThanOrEqualTo(2));
      expect(updatedSummary.fiveStarCount, greaterThanOrEqualTo(1));
    });

    test('getReviewForOrder returns matching review', () async {
      const orderId = 'ord-unit-test-fetch';
      final review = Review(
        id: 'rev-fetch-1',
        orderId: orderId,
        customerId: 'demo-customer-id',
        customerName: 'Test Fetcher',
        restaurantId: 'res-blue-bell',
        restaurantName: 'Blue Bell Café',
        rating: 4.0,
        comment: 'Great value for money.',
        isVerified: true,
        createdAt: DateTime.now(),
      );

      await repo.submitReview(review);
      final fetched = await repo.getReviewForOrder(orderId);
      expect(fetched, isNotNull);
      expect(fetched!.comment, 'Great value for money.');
      expect(fetched.rating, 4.0);
    });
  });
}
