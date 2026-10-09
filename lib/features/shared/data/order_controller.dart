import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../customer/offers/presentation/customer_offers_controller.dart';
import '../../restaurant/presentation/restaurant_controller.dart';
import '../models/order.dart';
import 'order_repository.dart';

/// Provider for customer orders list.
final customerOrdersProvider =
    FutureProvider.family<List<Order>, String>((ref, customerId) async {
  final repo = ref.watch(orderRepositoryProvider);
  return repo.getCustomerOrders(customerId);
});

/// Provider for restaurant orders list.
final restaurantOrdersProvider =
    FutureProvider.family<List<Order>, String>((ref, restaurantId) async {
  final repo = ref.watch(orderRepositoryProvider);
  return repo.getRestaurantOrders(restaurantId);
});

/// Provider for restaurant live sales stats (synchronous computation derived from orders).
final restaurantSalesStatsProvider =
    Provider.family<RestaurantSalesStats, String>((ref, restaurantId) {
  final orders = ref.watch(restaurantOrdersProvider(restaurantId)).value ?? [];
  final totalOrders = orders.length;
  final activeCount = orders.where((o) => o.isActivePickup).length;
  final portionsSold = orders.fold<int>(0, (sum, o) => sum + o.quantity);
  final revenue = orders.fold<double>(0.0, (sum, o) => sum + o.totalPrice);
  final savings = orders.fold<double>(0.0, (sum, o) => sum + o.totalSavings);

  return RestaurantSalesStats(
    totalOrders: totalOrders,
    activeOrdersCount: activeCount,
    totalPortionsSold: portionsSold,
    totalRevenue: revenue,
    totalSavings: savings,
  );
});

/// Controller for placing food rescue pickup orders and updating status.
class OrderController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<Order?> placeOrder({
    required String customerId,
    required String customerName,
    required String customerPhone,
    String? customerEmail,
    required String restaurantId,
    required String restaurantName,
    required String restaurantAddress,
    String? restaurantPhone,
    String? restaurantEmail,
    String? offerId,
    required String title,
    String? imageUrl,
    required String category,
    required int quantity,
    required double unitPrice,
    required double originalUnitPrice,
    required String pickupTime,
    required String paymentMethod,
    String? transactionId,
    String? notes,
  }) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(orderRepositoryProvider);
      final order = await repo.placeOrder(
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        customerEmail: customerEmail,
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        restaurantAddress: restaurantAddress,
        restaurantPhone: restaurantPhone,
        restaurantEmail: restaurantEmail,
        offerId: offerId,
        title: title,
        imageUrl: imageUrl,
        category: category,
        quantity: quantity,
        unitPrice: unitPrice,
        originalUnitPrice: originalUnitPrice,
        pickupTime: pickupTime,
        paymentMethod: paymentMethod,
        transactionId: transactionId,
        notes: notes,
      );

      // Invalidate customer and restaurant orders & profit stats
      ref.invalidate(customerOrdersProvider(customerId));
      ref.invalidate(restaurantOrdersProvider(restaurantId));
      ref.invalidate(restaurantOrdersProvider('res-blue-bell'));
      ref.invalidate(restaurantOrdersProvider('res-1'));
      ref.invalidate(restaurantOrdersProvider('demo-restaurant-id'));
      ref.invalidate(restaurantSalesStatsProvider(restaurantId));
      ref.invalidate(restaurantSalesStatsProvider('res-blue-bell'));
      ref.invalidate(restaurantSalesStatsProvider('res-1'));
      ref.invalidate(restaurantSalesStatsProvider('demo-restaurant-id'));

      // Invalidate customer offer inventory providers so counts decrease instantly
      ref.invalidate(activeOffersProvider);
      ref.invalidate(nearbyOffersProvider);
      ref.invalidate(allHomeOffersProvider);
      ref.invalidate(hotDealsProvider);
      ref.invalidate(allDhakaHotDealsProvider);
      ref.invalidate(searchResultsProvider);
      ref.invalidate(activeRestaurantsProvider);
      if (offerId != null) {
        ref.invalidate(offerDetailsProvider(offerId));
      }

      // Invalidate restaurant side offer providers
      ref.invalidate(currentRestaurantOffersProvider);
      ref.invalidate(restaurantActiveOffersProvider(restaurantId));
      ref.invalidate(restaurantActiveOffersProvider('res-blue-bell'));
      ref.invalidate(restaurantActiveOffersProvider('res-1'));

      state = const AsyncData(null);
      return order;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<bool> updateStatus(
    String orderId,
    String newStatus, {
    String? restaurantId,
    String? customerId,
  }) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(orderRepositoryProvider);
      final success = await repo.updateOrderStatus(orderId, newStatus);

      if (restaurantId != null) {
        ref.invalidate(restaurantOrdersProvider(restaurantId));
        ref.invalidate(restaurantSalesStatsProvider(restaurantId));
      }
      ref.invalidate(restaurantOrdersProvider('res-blue-bell'));
      ref.invalidate(restaurantOrdersProvider('res-1'));
      ref.invalidate(restaurantOrdersProvider('demo-restaurant-id'));
      ref.invalidate(restaurantSalesStatsProvider('res-blue-bell'));
      ref.invalidate(restaurantSalesStatsProvider('res-1'));
      ref.invalidate(restaurantSalesStatsProvider('demo-restaurant-id'));

      if (customerId != null) {
        ref.invalidate(customerOrdersProvider(customerId));
      }

      state = const AsyncData(null);
      return success;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final orderControllerProvider =
    AsyncNotifierProvider<OrderController, void>(OrderController.new);
