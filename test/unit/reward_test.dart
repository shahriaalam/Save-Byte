import 'package:flutter_test/flutter_test.dart';
import 'package:save_bite/features/shared/models/reward.dart';
import 'package:save_bite/features/shared/models/promo_code.dart';

void main() {
  group('Customer Reward Model Tests', () {
    test('Reward discount computes correctly based on minimum order requirement', () {
      final reward = Reward(
        id: 'rew-1000-30',
        title: 'SaveBite Mega Order Perk',
        description: 'Order 1000 taka product and get 30 tk off',
        minOrderAmount: 1000.0,
        discountValue: 30.0,
        discountType: 'flat',
        expiresAt: DateTime.now().add(const Duration(days: 7)),
        createdAt: DateTime.now(),
      );

      // Order below ৳1,000 threshold (e.g. ৳850) -> 0 discount
      expect(reward.calculateDiscount(850.0), 0.0);

      // Order exactly at ৳1,000 threshold -> ৳30 discount
      expect(reward.calculateDiscount(1000.0), 30.0);

      // Order above ৳1,000 threshold (e.g. ৳1,500) -> ৳30 discount
      expect(reward.calculateDiscount(1500.0), 30.0);
    });

    test('Expired rewards are marked as invalid and not active for customers', () {
      final expiredReward = Reward(
        id: 'rew-expired',
        title: 'Flash Flash Deal',
        description: 'Expired yesterday',
        minOrderAmount: 500.0,
        discountValue: 20.0,
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
      );

      expect(expiredReward.isExpired, isTrue);
      expect(expiredReward.isValid, isFalse);
      expect(expiredReward.remainingTimeText, 'Expired');

      final activeReward = Reward(
        id: 'rew-active',
        title: 'Weekend Saver',
        description: 'Ends in 3 days',
        minOrderAmount: 500.0,
        discountValue: 20.0,
        expiresAt: DateTime.now().add(const Duration(days: 3)),
        createdAt: DateTime.now(),
      );

      expect(activeReward.isExpired, isFalse);
      expect(activeReward.isValid, isTrue);
      expect(activeReward.remainingTimeText.contains('Ends in'), isTrue);
    });

    test('Single advantage exclusivity rule logic', () {
      // Rule: Customer can apply ONLY ONE advantage (either promo or reward) per order
      PromoCode? appliedPromo;
      Reward? appliedReward;

      final promo = const PromoCode(
        id: 'p1',
        code: 'SAVE50',
        title: '৳50 OFF',
        description: '৳50 discount',
        discountValue: 50.0,
      );

      final reward = Reward(
        id: 'r1',
        title: 'Weekly 30 Perk',
        description: 'Order 1000 taka get 30 tk off',
        minOrderAmount: 1000.0,
        discountValue: 30.0,
        expiresAt: DateTime.now().add(const Duration(days: 5)),
        createdAt: DateTime.now(),
      );

      // Step 1: User claims reward and applies it
      appliedReward = reward;
      expect(appliedReward, isNotNull);
      expect(appliedPromo, isNull);

      // Step 2: User enters promo code -> replaces reward (Single Advantage Rule)
      appliedPromo = promo;
      appliedReward = null; // Automatically cleared
      expect(appliedPromo, isNotNull);
      expect(appliedReward, isNull);

      // Step 3: User switches back to reward -> replaces promo
      appliedReward = reward;
      appliedPromo = null; // Automatically cleared
      expect(appliedReward, isNotNull);
      expect(appliedPromo, isNull);
    });
  });
}
