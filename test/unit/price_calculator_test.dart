import 'package:flutter_test/flutter_test.dart';
import 'package:save_bite/core/constants/app_constants.dart';
import 'package:save_bite/core/utils/price_calculator.dart';

void main() {
  group('PriceCalculator', () {
    test('calculates savings correctly according to Section 14', () {
      // ৳500 original, ৳250 discounted -> ৳250 savings
      final savings = PriceCalculator.calculateSavings(
        originalPrice: 500,
        discountedPrice: 250,
      );
      expect(savings, 250.0);
    });

    test('returns 0 savings when discounted price equals original price', () {
      final savings = PriceCalculator.calculateSavings(
        originalPrice: 200,
        discountedPrice: 200,
      );
      expect(savings, 0.0);
    });

    test('calculates discount percentage correctly according to formula', () {
      // Formula: ((original_price - discounted_price) / original_price) * 100
      final discount = PriceCalculator.calculateDiscountPercentage(
        originalPrice: 500,
        discountedPrice: 250,
      );
      expect(discount, 50);

      final discount80 = PriceCalculator.calculateDiscountPercentage(
        originalPrice: 200,
        discountedPrice: 120,
      );
      expect(discount80, 40);
    });

    test('formats price with currency symbol', () {
      final formattedWhole = PriceCalculator.format(150);
      expect(formattedWhole, '${AppConstants.currencySymbol}150');

      final formattedDecimal = PriceCalculator.format(150.50);
      expect(formattedDecimal, '${AppConstants.currencySymbol}150.50');
    });
  });
}
