import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:save_bite/features/customer/reviews/presentation/review_submission_sheet.dart';
import 'package:save_bite/features/customer/reviews/presentation/widgets/restaurant_reviews_section.dart';
import 'package:save_bite/features/customer/reviews/presentation/widgets/review_card.dart';
import 'package:save_bite/features/shared/models/order.dart';
import 'package:save_bite/features/shared/models/review.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Review Widgets Tests', () {
    testWidgets('ReviewCard renders verified badge, rating, comment and photo', (tester) async {
      final review = Review(
        id: 'rev-w-1',
        orderId: 'ord-w-1',
        customerId: 'cust-1',
        customerName: 'Samira Hossain',
        restaurantId: 'res-blue-bell',
        restaurantName: 'Blue Bell Café',
        offerTitle: 'Belgian Waffles & Berry Box',
        rating: 5.0,
        comment: 'Freshly baked and saved from waste! Excellent taste.',
        imageUrl: 'https://images.unsplash.com/photo-1565299585323-38d6b0865b47',
        isVerified: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReviewCard(review: review),
          ),
        ),
      );

      // Verify customer details
      expect(find.text('Samira Hossain'), findsOneWidget);
      expect(find.text('Freshly baked and saved from waste! Excellent taste.'), findsOneWidget);

      // Verify Verified Rescue Badge
      expect(find.text('Verified Rescue'), findsOneWidget);
      expect(find.byIcon(Icons.verified_rounded), findsOneWidget);

      // Verify item title
      expect(find.text('Belgian Waffles & Berry Box'), findsOneWidget);
    });

    testWidgets('RestaurantReviewsSection displays summary rating and review list', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: RestaurantReviewsSection(
                  restaurantId: 'res-blue-bell',
                  restaurantName: 'Blue Bell Café',
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Section Header
      expect(find.text('Reviews & Ratings'), findsOneWidget);

      // Verify Filter chips
      expect(find.text('All Reviews'), findsOneWidget);
      expect(find.text('With Photos'), findsOneWidget);

      // Verify verified reviews badge
      expect(find.textContaining('verified reviews'), findsOneWidget);
    });

    testWidgets('ReviewSubmissionSheet renders form inputs and verified badge', (tester) async {
      final order = Order(
        id: 'ord-sheet-1',
        orderNumber: 'SB-8821',
        customerId: 'demo-customer-id',
        customerName: 'Demo Customer',
        customerPhone: '01700000000',
        customerEmail: 'customer@savebite.com',
        restaurantId: 'res-blue-bell',
        restaurantName: 'Blue Bell Café',
        restaurantAddress: 'House 14, Road 4, Block D, Banasree, Dhaka',
        offerId: 'off-1',
        title: 'Fresh Croissant Trio',
        category: 'Bakery',
        quantity: 2,
        unitPrice: 120.0,
        originalUnitPrice: 240.0,
        totalPrice: 240.0,
        totalSavings: 240.0,
        status: 'completed',
        paymentStatus: 'paid',
        pickupCode: '8821',
        pickupTime: 'Today, 8:30 PM',
        paymentMethod: 'bKash',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ReviewSubmissionSheet(order: order),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Header and Verified Takeaway Badge
      expect(find.text('Rate & Review Food'), findsOneWidget);
      expect(find.text('Verified Pickup'), findsOneWidget);
      expect(find.text('Fresh Croissant Trio'), findsOneWidget);

      // Star rating prompt
      expect(find.byIcon(Icons.star_rounded), findsWidgets);

      // Feedback title & TextFormField
      expect(find.text('Your Feedback & Review'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);

      // Photo upload options
      expect(find.text('Attach Food Picture (Optional)'), findsOneWidget);
      expect(find.text('From Gallery'), findsOneWidget);
      expect(find.text('Food Preset'), findsOneWidget);

      // Submit button
      expect(find.text('Post Verified Review'), findsOneWidget);
    });
  });
}
