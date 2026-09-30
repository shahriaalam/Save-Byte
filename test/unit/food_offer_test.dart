import 'package:flutter_test/flutter_test.dart';
import 'package:save_bite/features/shared/models/food_offer.dart';

void main() {
  group('FoodOffer Model & Logic (Sections 12, 13, 21, 44)', () {
    final now = DateTime.now();

    final testOffer = FoodOffer(
      id: 'test-1',
      restaurantId: 'res-1',
      restaurantName: "Rahman's Kitchen",
      restaurantAddress: 'Dhanmondi, Dhaka',
      title: 'Chicken Biryani',
      category: 'Rice',
      originalPrice: 250,
      discountedPrice: 150,
      quantity: 8,
      availableFrom: now.subtract(const Duration(hours: 1)),
      availableUntil: now.add(const Duration(hours: 2)),
      isActive: true,
      adminBlocked: false,
    );

    test('calculates savings and discount percentage correctly', () {
      expect(testOffer.savings, 100);
      expect(testOffer.discountPercentage, 40);
    });

    test('checks customer visibility correctly (Section 13 & 44)', () {
      // Active and unblocked and valid time
      expect(testOffer.isVisibleToCustomer(now), isTrue);

      // Inactive offer
      final inactiveOffer = testOffer.copyWith(isActive: false);
      expect(inactiveOffer.isVisibleToCustomer(now), isFalse);

      // Admin blocked offer
      final blockedOffer = testOffer.copyWith(adminBlocked: true);
      expect(blockedOffer.isVisibleToCustomer(now), isFalse);

      // Expired offer
      final expiredOffer = testOffer.copyWith(
        availableUntil: now.subtract(const Duration(minutes: 5)),
      );
      expect(expiredOffer.isVisibleToCustomer(now), isFalse);
    });

    test('serializes and deserializes to and from JSON', () {
      final json = testOffer.toJson();
      expect(json['id'], 'test-1');
      expect(json['title'], 'Chicken Biryani');
      expect(json['original_price'], 250);
      expect(json['discounted_price'], 150);
      expect(json['quantity'], 8);
      expect(json['category'], 'Rice');

      final fromJson = FoodOffer.fromJson(json);
      expect(fromJson.id, 'test-1');
      expect(fromJson.title, 'Chicken Biryani');
      expect(fromJson.discountedPrice, 150);
      expect(fromJson.savings, 100);
    });
  });
}
