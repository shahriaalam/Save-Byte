import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:save_bite/core/constants/app_colors.dart';
import 'package:save_bite/features/customer/offers/data/customer_offer_repository.dart';
import 'package:save_bite/features/restaurant/data/restaurant_repository.dart';
import 'package:save_bite/features/shared/models/restaurant.dart';
import 'package:save_bite/features/shared/data/order_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Order & Ecosystem Interconnection Tests', () {
    late SupabaseClient client;
    late CustomerOfferRepository customerOfferRepo;
    late OrderRepository orderRepo;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      client = SupabaseClient('https://test.supabase.co', 'test-anon-key');
      customerOfferRepo = CustomerOfferRepository(client);
      orderRepo = OrderRepository(client, customerOfferRepo);
    });

    test('Customer ordering decrements item quantity across customer and restaurant feeds', () async {
      // 1. Fetch initial offer
      final initialOffer = await customerOfferRepo.getOfferById('offer-bb-1');
      expect(initialOffer, isNotNull);
      final initialQuantity = initialOffer!.quantity;
      expect(initialQuantity, greaterThanOrEqualTo(2));

      // 2. Place an order for 2 portions
      final order = await orderRepo.placeOrder(
        customerId: 'test-user-123',
        customerName: 'Test Customer',
        customerPhone: '01800000000',
        customerEmail: 'customer@test.com',
        restaurantId: 'res-blue-bell',
        restaurantName: 'Blue Bell Café',
        restaurantAddress: 'House 14, Road 4, Block D, Banasree, Dhaka',
        offerId: 'offer-bb-1',
        title: initialOffer.title,
        imageUrl: initialOffer.imageUrl,
        category: initialOffer.category,
        quantity: 2,
        unitPrice: initialOffer.discountedPrice,
        originalUnitPrice: initialOffer.originalPrice,
        pickupTime: 'Today at 7:30 PM',
        paymentMethod: 'bKash',
        transactionId: 'TXN-TEST-100',
      );

      expect(order.id, isNotEmpty);
      expect(order.quantity, 2);

      // 3. Verify offer quantity decreased in CustomerOfferRepository
      final updatedOffer = await customerOfferRepo.getOfferById('offer-bb-1');
      expect(updatedOffer, isNotNull);
      expect(updatedOffer!.quantity, initialQuantity - 2);

      // 4. Verify offer quantity also decreased in RestaurantRepository
      final restaurantRepo = RestaurantRepository(client);
      final restaurantOffers = await restaurantRepo.getRestaurantOffers('res-blue-bell');
      final matchingRestOffer = restaurantOffers.firstWhere((o) => o.id == 'offer-bb-1');
      expect(matchingRestOffer.quantity, initialQuantity - 2);
    });

    test('Placed order appears in restaurant active orders and updates owner profit/revenue stats', () async {
      // Get initial stats
      final initialStats = await orderRepo.getRestaurantSalesStats('res-blue-bell');
      final initialRevenue = (initialStats['totalRevenue'] as num).toDouble();
      final initialPortions = (initialStats['portionsSold'] as num).toInt();
      final initialActive = (initialStats['activePickups'] as num).toInt();

      // Place a new order
      final order = await orderRepo.placeOrder(
        customerId: 'test-user-456',
        customerName: 'Ayesha Rahman',
        customerPhone: '01700000000',
        restaurantId: 'res-blue-bell',
        restaurantName: 'Blue Bell Café',
        restaurantAddress: 'Banasree, Dhaka',
        offerId: 'offer-bb-2',
        title: 'Truffle Mushroom Risotto',
        category: 'Italian',
        quantity: 3,
        unitPrice: 500,
        originalUnitPrice: 800,
        pickupTime: 'Today at 8:00 PM',
        paymentMethod: 'Nagad',
        transactionId: 'TXN-NAGAD-200',
      );

      // 1. Restaurant orders list includes this order
      final restOrders = await orderRepo.getRestaurantOrders('res-blue-bell');
      expect(restOrders.any((o) => o.id == order.id), isTrue);

      // 2. Owner sales stats increment accurately
      final updatedStats = await orderRepo.getRestaurantSalesStats('res-blue-bell');
      expect((updatedStats['totalRevenue'] as num).toDouble(), initialRevenue + (3 * 500));
      expect((updatedStats['portionsSold'] as num).toInt(), initialPortions + 3);
      expect((updatedStats['activePickups'] as num).toInt(), initialActive + 1);
    });

    test('New restaurant registration connects with system and is visible to Admin', () async {
      const newCafeId = 'res-test-new-cafe';
      final newCafe = Restaurant(
        id: newCafeId,
        ownerId: 'owner-test-456',
        name: 'The Artisan Bakery & Bistro',
        phone: '01912345678',
        address: 'Sector 4, Uttara, Dhaka',
        status: 'pending',
        cuisineType: 'Bakery & Café',
        division: 'Dhaka',
        area: 'Uttara',
        createdAt: DateTime.now(),
      );

      // Register the restaurant
      RestaurantRepository.registerRestaurantStatic(newCafe);

      // Verify it appears in registered restaurants list (which Admin dashboard inspects)
      final allRestaurants = RestaurantRepository.allRegisteredRestaurants;
      expect(allRestaurants.any((r) => r.id == newCafeId), isTrue);

      final foundCafe = allRestaurants.firstWhere((r) => r.id == newCafeId);
      expect(foundCafe.name, 'The Artisan Bakery & Bistro');
      expect(foundCafe.status, 'pending');

      // Admin approves the restaurant
      RestaurantRepository.updateRestaurantStatus(newCafeId, 'approved');
      final approvedCafe = RestaurantRepository.allRegisteredRestaurants.firstWhere((r) => r.id == newCafeId);
      expect(approvedCafe.status, 'approved');
    });

    test('Order transitions from confirmed to ready_for_pickup (green) and then completed (picked up in history)', () async {
      // 1. Place a confirmed order
      final order = await orderRepo.placeOrder(
        customerId: 'test-user-789',
        customerName: 'Karim Uddin',
        customerPhone: '01811223344',
        restaurantId: 'res-blue-bell',
        restaurantName: 'Blue Bell Café',
        restaurantAddress: 'Banasree, Dhaka',
        offerId: 'offer-bb-3',
        title: 'Venetian Tiramisu',
        category: 'Dessert',
        quantity: 1,
        unitPrice: 240,
        originalUnitPrice: 420,
        pickupTime: 'Today at 6:30 PM',
        paymentMethod: 'bKash',
        transactionId: 'TXN-BK-999',
      );

      expect(order.isConfirmed, isTrue);
      expect(order.statusColor, AppColors.primary);

      // 2. Mark ready for pickup
      await orderRepo.updateOrderStatus(order.id, 'ready_for_pickup');
      final activeOrders = await orderRepo.getRestaurantOrders('res-blue-bell');
      final readyOrder = activeOrders.firstWhere((o) => o.id == order.id);

      expect(readyOrder.isReadyForPickup, isTrue);
      // Verifies it goes emerald green
      expect(readyOrder.statusColor, const Color(0xFF059669));
      expect(readyOrder.statusDisplayLabel, 'Ready for Pickup');

      // 3. Complete order (owner taps Done / Mark as Picked Up)
      await orderRepo.updateOrderStatus(order.id, 'completed');
      final allOrders = await orderRepo.getRestaurantOrders('res-blue-bell');
      final completedOrder = allOrders.firstWhere((o) => o.id == order.id);

      expect(completedOrder.isCompleted, isTrue);
      expect(completedOrder.isActivePickup, isFalse);
      expect(completedOrder.statusDisplayLabel, 'Picked Up');
      expect(completedOrder.statusColor, const Color(0xFF16A34A));
    });
  });
}
