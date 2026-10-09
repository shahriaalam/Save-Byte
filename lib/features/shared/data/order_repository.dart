import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../../core/constants/supabase_constants.dart';
import '../../../core/supabase/supabase_client_provider.dart';
import '../../customer/offers/data/customer_offer_repository.dart';
import '../models/order.dart';
import '../services/email_notification_service.dart';

/// Provider for OrderRepository.
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final offerRepo = ref.watch(customerOfferRepositoryProvider);
  return OrderRepository(client, offerRepo);
});

class OrderRepository {
  OrderRepository(this._client, this._offerRepo)
      : _emailService = EmailNotificationService(client: _client);

  final supa.SupabaseClient _client;
  final CustomerOfferRepository _offerRepo;
  final EmailNotificationService _emailService;

  bool get _isLocalOnly =>
      _client.rest.url.contains('placeholder') ||
      _client.rest.url.contains('test');

  // In-memory persistent order state for offline/demo/testing and instant UI sync
  static final List<Order> _seedOrders = [
    Order(
      id: 'ord-bb-101',
      orderNumber: 'SB-849201',
      customerId: 'demo-customer-id',
      customerName: 'Shahriar Alam',
      customerPhone: '01712345678',
      customerEmail: 'shahriar@savebite.app',
      restaurantId: 'res-blue-bell',
      restaurantName: 'Blue Bell Café',
      restaurantAddress: 'House 14, Road 4, Block D, Banasree, Dhaka',
      restaurantPhone: '01711234567',
      restaurantEmail: 'bluebell@savebite.app',
      offerId: 'offer-bb-1',
      title: 'Tuscan Slow-Baked Lasagna',
      imageUrl: 'https://images.unsplash.com/photo-1574894709920-11b28e7367e3?w=600',
      category: 'Italian',
      quantity: 2,
      unitPrice: 420,
      originalUnitPrice: 750,
      totalPrice: 840,
      totalSavings: 660,
      pickupTime: 'Today at 7:30 PM',
      pickupCode: '4821',
      paymentMethod: 'bKash',
      paymentStatus: 'paid',
      transactionId: 'TXN-BK-7391024',
      status: 'ready_for_pickup',
      notes: 'Please pack with extra napkins.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
    ),
  ];

  /// Creates a new takeaway pickup order after online payment is approved.
  /// - Deducts ordered portions from available food inventory
  /// - Persists order to Supabase orders table
  /// - Dispatches confirmation email to customer & alert email to restaurant
  Future<Order> placeOrder({
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
    final totalPrice = unitPrice * quantity;
    final totalSavings = (originalUnitPrice - unitPrice) * quantity;
    final randomSuffix = (Random().nextInt(900000) + 100000).toString();
    final orderNumber = 'SB-$randomSuffix';
    final pickupCode = (Random().nextInt(9000) + 1000).toString();
    final orderId = 'ord-${DateTime.now().millisecondsSinceEpoch}';

    final order = Order(
      id: orderId,
      orderNumber: orderNumber,
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
      totalPrice: totalPrice,
      totalSavings: totalSavings,
      pickupTime: pickupTime,
      pickupCode: pickupCode,
      paymentMethod: paymentMethod,
      paymentStatus: 'paid',
      transactionId: transactionId,
      status: 'confirmed',
      notes: notes,
      createdAt: DateTime.now(),
      emailSentCustomer: true,
      emailSentRestaurant: true,
    );

    // 1. Decrease food offer portion inventory locally
    if (offerId != null) {
      _offerRepo.decreaseOfferQuantityLocally(offerId, quantity);
    }

    // 2. Add to in-memory order cache (top of list)
    _seedOrders.insert(0, order);

    // 3. Persist to Supabase if remote backend is accessible
    if (!_isLocalOnly) {
      try {
        await _client.from(SupabaseConstants.tableOrders).insert({
          'order_number': orderNumber,
          'customer_id': customerId,
          'customer_name': customerName,
          'customer_phone': customerPhone,
          'customer_email': customerEmail,
          'restaurant_id': restaurantId,
          'restaurant_name': restaurantName,
          'restaurant_address': restaurantAddress,
          'restaurant_phone': restaurantPhone,
          'restaurant_email': restaurantEmail,
          'offer_id': offerId,
          'title': title,
          'image_url': imageUrl,
          'category': category,
          'quantity': quantity,
          'unit_price': unitPrice,
          'original_price': originalUnitPrice,
          'total_price': totalPrice,
          'total_savings': totalSavings,
          'pickup_time': pickupTime,
          'pickup_code': pickupCode,
          'payment_method': paymentMethod,
          'payment_status': 'paid',
          'transaction_id': transactionId,
          'status': 'confirmed',
          'notes': notes,
        });

        // Also update Supabase offers table quantity
        if (offerId != null) {
          try {
            final offerRes = await _client
                .from(SupabaseConstants.tableOffers)
                .select('quantity')
                .eq('id', offerId)
                .maybeSingle();

            if (offerRes != null) {
              final currentQty = (offerRes['quantity'] as num?)?.toInt() ?? quantity;
              final newQty = (currentQty - quantity).clamp(0, 9999);
              await _client.from(SupabaseConstants.tableOffers).update({
                'quantity': newQty,
                if (newQty <= 0) 'is_active': false,
              }).eq('id', offerId);
            }
          } catch (e) {
            debugPrint('Note: Supabase offer quantity update handled: $e');
          }
        }
      } catch (e) {
        debugPrint('Notice: Local storage used for order: $e');
      }
    }

    // 4. Dispatch transactional confirmation emails
    await _emailService.sendCustomerOrderEmail(order);
    await _emailService.sendRestaurantOrderEmail(order);

    return order;
  }

  /// Retrieves orders placed by a specific customer.
  Future<List<Order>> getCustomerOrders(String customerId) async {
    if (!_isLocalOnly) {
      try {
        final List<dynamic> response = await _client
            .from(SupabaseConstants.tableOrders)
            .select()
            .eq('customer_id', customerId)
            .order('created_at', ascending: false);

        if (response.isNotEmpty) {
          return response
              .map((row) => Order.fromJson(row as Map<String, dynamic>))
              .toList();
        }
      } catch (_) {}
    }

    return _seedOrders.where((o) => o.customerId == customerId || customerId == 'demo-customer-id').toList();
  }

  /// Retrieves orders received by a specific restaurant.
  Future<List<Order>> getRestaurantOrders(String restaurantId) async {
    if (!_isLocalOnly) {
      try {
        final List<dynamic> response = await _client
            .from(SupabaseConstants.tableOrders)
            .select()
            .eq('restaurant_id', restaurantId)
            .order('created_at', ascending: false);

        if (response.isNotEmpty) {
          return response
              .map((row) => Order.fromJson(row as Map<String, dynamic>))
              .toList();
        }
      } catch (_) {}
    }

    return _seedOrders
        .where((o) => o.restaurantId == restaurantId || restaurantId == 'res-blue-bell' || restaurantId == 'demo-restaurant-id')
        .toList();
  }

  /// Updates an order status (e.g. from 'confirmed' to 'ready_for_pickup' or 'completed').
  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    // 1. Update in-memory cache
    final index = _seedOrders.indexWhere((o) => o.id == orderId || o.orderNumber == orderId);
    if (index != -1) {
      _seedOrders[index] = _seedOrders[index].copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );
    }

    // 2. Update Supabase if available
    if (!_isLocalOnly) {
      try {
        await _client
            .from(SupabaseConstants.tableOrders)
            .update({'status': newStatus, 'updated_at': DateTime.now().toIso8601String()})
            .or('id.eq.$orderId,order_number.eq.$orderId');
        return true;
      } catch (_) {}
    }

    return true;
  }

  /// Calculates restaurant sales analytics based on placed orders.
  Future<Map<String, dynamic>> getRestaurantSalesStats(String restaurantId) async {
    final orders = await getRestaurantOrders(restaurantId);
    double totalRevenue = 0;
    int portionsSold = 0;
    int completedPickups = 0;
    int activePickups = 0;

    for (final order in orders) {
      if (order.status != 'cancelled') {
        totalRevenue += order.totalPrice;
        portionsSold += order.quantity;
      }
      if (order.status == 'completed') {
        completedPickups++;
      } else if (order.isActivePickup) {
        activePickups++;
      }
    }

    return {
      'totalRevenue': totalRevenue,
      'portionsSold': portionsSold,
      'totalOrders': orders.length,
      'completedPickups': completedPickups,
      'activePickups': activePickups,
    };
  }
}
