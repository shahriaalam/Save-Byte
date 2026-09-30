import '../constants/app_constants.dart';

/// Pure utility for price and discount calculations according to Section 14.
abstract final class PriceCalculator {
  /// Calculates the absolute savings (originalPrice - discountedPrice).
  static double calculateSavings({
    required double originalPrice,
    required double discountedPrice,
  }) {
    if (originalPrice < 0 || discountedPrice < 0) return 0;
    final savings = originalPrice - discountedPrice;
    return savings > 0 ? savings : 0;
  }

  /// Calculates discount percentage rounded to whole number.
  /// Formula: ((original_price - discounted_price) / original_price) * 100
  static int calculateDiscountPercentage({
    required double originalPrice,
    required double discountedPrice,
  }) {
    if (originalPrice <= 0 || discountedPrice <= 0) return 0;
    if (discountedPrice >= originalPrice) return 0;

    final percent = ((originalPrice - discountedPrice) / originalPrice) * 100;
    return percent.round().clamp(0, 100);
  }

  /// Formats amount with currency symbol (e.g. "৳150").
  static String format(double amount) {
    if (amount % 1 == 0) {
      return '${AppConstants.currencySymbol}${amount.toInt()}';
    }
    return '${AppConstants.currencySymbol}${amount.toStringAsFixed(2)}';
  }
}
