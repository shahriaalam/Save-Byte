import 'package:flutter_test/flutter_test.dart';
import 'package:save_bite/features/shared/models/order.dart';
import 'package:save_bite/features/shared/models/promo_code.dart';

void main() {
  group('PromoCode Model Tests', () {
    test('Flat discount computes accurately and caps at subtotal', () {
      const flatPromo = PromoCode(
        id: 'promo-1',
        code: 'SAVE50',
        title: '৳50 OFF',
        description: '৳50 discount on orders above ৳150',
        discountType: 'flat',
        discountValue: 50.0,
        minOrderAmount: 150.0,
        isPlatformSponsored: true,
      );

      // Order below minimum requirement
      expect(flatPromo.calculateDiscount(100.0), 0.0);

      // Order meeting minimum requirement
      expect(flatPromo.calculateDiscount(200.0), 50.0);

      // Order where subtotal is less than discount
      const smallOrderPromo = PromoCode(
        id: 'promo-2',
        code: 'FLAT100',
        title: '৳100 OFF',
        description: '৳100 discount with 0 min order',
        discountType: 'flat',
        discountValue: 100.0,
        minOrderAmount: 0.0,
      );
      expect(smallOrderPromo.calculateDiscount(70.0), 70.0); // Capped at subtotal
    });

    test('Percentage discount computes accurately with cap', () {
      const pctPromo = PromoCode(
        id: 'promo-3',
        code: 'SAVE20',
        title: '20% OFF',
        description: '20% discount (Max ৳80)',
        discountType: 'percentage',
        discountValue: 20.0,
        minOrderAmount: 100.0,
        maxDiscount: 80.0,
        isPlatformSponsored: true,
      );

      // Below minimum
      expect(pctPromo.calculateDiscount(80.0), 0.0);

      // 20% of 200 = 40
      expect(pctPromo.calculateDiscount(200.0), 40.0);

      // 20% of 600 = 120 -> capped at 80
      expect(pctPromo.calculateDiscount(600.0), 80.0);
    });

    test('PromoCode serialization and deserialization', () {
      const promo = PromoCode(
        id: 'promo-test',
        code: 'TESTCODE',
        title: 'Test Voucher',
        description: 'Test Description',
        discountType: 'flat',
        discountValue: 35.0,
        minOrderAmount: 120.0,
        maxDiscount: null,
        isActive: true,
        usedCount: 15,
        isPlatformSponsored: true,
      );

      final json = promo.toJson();
      final fromJson = PromoCode.fromJson(json);

      expect(fromJson.code, 'TESTCODE');
      expect(fromJson.discountValue, 35.0);
      expect(fromJson.minOrderAmount, 120.0);
      expect(fromJson.isPlatformSponsored, true);
    });
  });

  group('Order Revenue & Platform Authority Guarantee Tests', () {
    test('Restaurant receives full food payout without loss when promo code is applied', () {
      const unitPrice = 240.0;
      const quantity = 2;
      const subtotal = unitPrice * quantity; // 480.0
      const promoDiscount = 50.0;
      const customerPayable = subtotal - promoDiscount; // 430.0

      final order = Order(
        id: 'ord-123',
        orderNumber: 'SB-123456',
        customerId: 'cust-1',
        customerName: 'Rahim Ahmed',
        customerPhone: '01700112233',
        restaurantId: 'rest-blue-bell',
        restaurantName: 'Blue Bell Café',
        restaurantAddress: 'Banasree, Dhaka',
        title: 'Venetian Espresso Tiramisu',
        category: 'Dessert',
        quantity: quantity,
        unitPrice: unitPrice,
        originalUnitPrice: 420.0,
        totalPrice: customerPayable, // 430.0 (What customer pays)
        totalSavings: (420.0 - unitPrice) * quantity + promoDiscount, // (180 * 2) + 50 = 410.0
        pickupTime: 'Today at 9:59 AM',
        pickupCode: '4821',
        paymentMethod: 'BKASH',
        paymentStatus: 'paid',
        createdAt: DateTime.now(),
        promoCode: 'SAVEBITE50',
        discountAmount: promoDiscount,
        restaurantEarnings: subtotal, // 480.0 (Restaurant gets 100% full food earnings!)
        platformSubsidy: promoDiscount, // 50.0 (App authority absorbs this!)
      );

      // Verify the customer paid the discounted price
      expect(order.totalPrice, 430.0);

      // Verify the restaurant earns full 480.0 without any loss!
      expect(order.restaurantEarnings, 480.0);

      // Verify the platform absorbed the 50.0 subsidy
      expect(order.platformSubsidy, 50.0);
      expect(order.promoCode, 'SAVEBITE50');
    });
  });
}
