import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  static const String _storageKey = 'sb_takeaway_orders';
  static bool _hasLoadedFromPrefs = false;

  // In-memory persistent order state for offline/demo/testing and instant UI sync
  static final List<Order> _seedOrders = [];

  bool _isValidUuid(String? str) {
    if (str == null || str.isEmpty) return false;
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(str);
  }

  /// Loads cached orders from SharedPreferences into _seedOrders.
  Future<void> _ensureLoaded() async {
    if (_hasLoadedFromPrefs) return;
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(milliseconds: 300),
      );
      final jsonList = prefs.getStringList(_storageKey);
      if (jsonList != null && jsonList.isNotEmpty) {
        final List<Order> loaded = [];
        for (final item in jsonList) {
          try {
            final map = jsonDecode(item) as Map<String, dynamic>;
            loaded.add(Order.fromJson(map));
          } catch (e) {
            debugPrint('Failed to parse cached order: $e');
          }
        }
        for (final order in loaded) {
          final idx = _seedOrders.indexWhere(
            (o) => o.id == order.id || o.orderNumber == order.orderNumber,
          );
          if (idx == -1) {
            _seedOrders.add(order);
          } else {
            if (order.status == 'completed' && _seedOrders[idx].status != 'completed') {
              _seedOrders[idx] = order;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('SharedPreferences order loading error: $e');
    } finally {
      _hasLoadedFromPrefs = true;
    }
  }

  /// Persists current _seedOrders to SharedPreferences so order history is never lost.
  Future<void> _persistToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(milliseconds: 300),
      );
      final list = _seedOrders.map((o) => jsonEncode(o.toJson())).toList();
      await prefs.setStringList(_storageKey, list);
    } catch (e) {
      debugPrint('SharedPreferences order saving error: $e');
    }
  }

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
    String? promoCode,
    double discountAmount = 0.0,
  }) async {
    final subtotal = unitPrice * quantity;
    final totalPrice = (subtotal - discountAmount) < 0.0 ? 0.0 : (subtotal - discountAmount);
    final totalSavings = ((originalUnitPrice - unitPrice) * quantity) + discountAmount;
    final restaurantEarnings = subtotal; // 100% full payout to restaurant (no loss)
    final platformSubsidy = discountAmount; // 100% absorbed by app authority
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
      promoCode: promoCode,
      discountAmount: discountAmount,
      restaurantEarnings: restaurantEarnings,
      platformSubsidy: platformSubsidy,
    );

    // Ensure existing cache is loaded before inserting
    await _ensureLoaded();

    // 1. Decrease food offer portion inventory locally
    if (offerId != null) {
      _offerRepo.decreaseOfferQuantityLocally(offerId, quantity);
    }

    // 2. Add to in-memory order cache (top of list)
    _seedOrders.insert(0, order);

    // Save to SharedPreferences so it is immediately persisted across restarts
    await _persistToPrefs();

    // 3. Persist to Supabase if remote backend is accessible
    if (!_isLocalOnly) {
      try {
        final Map<String, dynamic> insertPayload = {
          'order_number': orderNumber,
          'customer_name': customerName,
          'customer_phone': customerPhone,
          'customer_email': customerEmail,
          'restaurant_name': restaurantName,
          'restaurant_address': restaurantAddress,
          'restaurant_phone': restaurantPhone,
          'restaurant_email': restaurantEmail,
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
          'promo_code': promoCode,
          'discount_amount': discountAmount,
          'restaurant_earnings': restaurantEarnings,
          'platform_subsidy': platformSubsidy,
        };

        if (_isValidUuid(customerId)) {
          insertPayload['customer_id'] = customerId;
        } else if (_client.auth.currentUser != null && _isValidUuid(_client.auth.currentUser!.id)) {
          insertPayload['customer_id'] = _client.auth.currentUser!.id;
        }

        if (_isValidUuid(restaurantId)) {
          insertPayload['restaurant_id'] = restaurantId;
        }

        if (offerId != null && _isValidUuid(offerId)) {
          insertPayload['offer_id'] = offerId;
        }

        // Only insert if both customer_id and restaurant_id can be satisfied with valid UUIDs
        if (insertPayload.containsKey('customer_id') && insertPayload.containsKey('restaurant_id')) {
          final res = await _client
              .from(SupabaseConstants.tableOrders)
              .insert(insertPayload)
              .select()
              .maybeSingle();

          if (res != null && res['id'] != null) {
            final remoteId = res['id'].toString();
            final updatedIdx = _seedOrders.indexWhere((o) => o.orderNumber == orderNumber);
            if (updatedIdx != -1) {
              _seedOrders[updatedIdx] = _seedOrders[updatedIdx].copyWith(id: remoteId);
              await _persistToPrefs();
            }
          }
        }

        // Also update Supabase offers table quantity
        if (offerId != null && _isValidUuid(offerId)) {
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
    await _ensureLoaded();

    if (!_isLocalOnly) {
      try {
        final queryId = _isValidUuid(customerId)
            ? customerId
            : (_client.auth.currentUser != null && _isValidUuid(_client.auth.currentUser!.id)
                ? _client.auth.currentUser!.id
                : null);

        if (queryId != null) {
          final List<dynamic> response = await _client
              .from(SupabaseConstants.tableOrders)
              .select()
              .eq('customer_id', queryId)
              .order('created_at', ascending: false);

          if (response.isNotEmpty) {
            for (final row in response) {
              try {
                final remoteOrder = Order.fromJson(row as Map<String, dynamic>);
                final idx = _seedOrders.indexWhere(
                  (o) => o.id == remoteOrder.id || o.orderNumber == remoteOrder.orderNumber,
                );
                if (idx == -1) {
                  _seedOrders.add(remoteOrder);
                } else {
                  if (remoteOrder.status == 'completed' && _seedOrders[idx].status != 'completed') {
                    _seedOrders[idx] = _seedOrders[idx].copyWith(status: 'completed');
                  }
                }
              } catch (_) {}
            }
            await _persistToPrefs();
          }
        }
      } catch (e) {
        debugPrint('Supabase getCustomerOrders notice: $e');
      }
    }

    final results = _seedOrders.where((o) {
      if (customerId == 'demo-customer-id') return true;
      if (o.customerId == customerId) return true;
      if (o.customerId == 'demo-customer-id' || o.customerId.isEmpty) return true;
      return false;
    }).toList();

    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return results;
  }

  /// Retrieves orders received by a specific restaurant.
  Future<List<Order>> getRestaurantOrders(String restaurantId) async {
    await _ensureLoaded();

    if (!_isLocalOnly) {
      try {
        if (_isValidUuid(restaurantId)) {
          final List<dynamic> response = await _client
              .from(SupabaseConstants.tableOrders)
              .select()
              .eq('restaurant_id', restaurantId)
              .order('created_at', ascending: false);

          if (response.isNotEmpty) {
            for (final row in response) {
              try {
                final remoteOrder = Order.fromJson(row as Map<String, dynamic>);
                final idx = _seedOrders.indexWhere(
                  (o) => o.id == remoteOrder.id || o.orderNumber == remoteOrder.orderNumber,
                );
                if (idx == -1) {
                  _seedOrders.add(remoteOrder);
                } else {
                  if (remoteOrder.status == 'completed' && _seedOrders[idx].status != 'completed') {
                    _seedOrders[idx] = _seedOrders[idx].copyWith(status: 'completed');
                  }
                }
              } catch (_) {}
            }
            await _persistToPrefs();
          }
        }
      } catch (e) {
        debugPrint('Supabase getRestaurantOrders notice: $e');
      }
    }

    final isBlueBellQuery = restaurantId == 'res-blue-bell' ||
        restaurantId == 'res-1' ||
        restaurantId == 'demo-restaurant-id';

    final results = _seedOrders.where((o) {
      if (o.restaurantId == restaurantId) return true;
      final isBlueBellOrder = o.restaurantId == 'res-blue-bell' ||
          o.restaurantId == 'res-1' ||
          o.restaurantId == 'demo-restaurant-id';
      if (isBlueBellQuery && isBlueBellOrder) return true;
      return false;
    }).toList();

    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return results;
  }

  /// Updates an order status (e.g. from 'confirmed' to 'ready_for_pickup' or 'completed').
  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    await _ensureLoaded();

    // 1. Update in-memory cache
    Order? matchedOrder;
    final index = _seedOrders.indexWhere((o) => o.id == orderId || o.orderNumber == orderId);
    if (index != -1) {
      _seedOrders[index] = _seedOrders[index].copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );
      matchedOrder = _seedOrders[index];
    }

    // Persist to SharedPreferences so it is stored permanently
    await _persistToPrefs();

    // 2. Update Supabase if available
    if (!_isLocalOnly) {
      try {
        final isUuid = _isValidUuid(orderId);
        final orderNumber = matchedOrder?.orderNumber;

        if (isUuid) {
          await _client
              .from(SupabaseConstants.tableOrders)
              .update({'status': newStatus, 'updated_at': DateTime.now().toIso8601String()})
              .eq('id', orderId);
        } else if (orderNumber != null) {
          await _client
              .from(SupabaseConstants.tableOrders)
              .update({'status': newStatus, 'updated_at': DateTime.now().toIso8601String()})
              .eq('order_number', orderNumber);
        } else {
          await _client
              .from(SupabaseConstants.tableOrders)
              .update({'status': newStatus, 'updated_at': DateTime.now().toIso8601String()})
              .eq('order_number', orderId);
        }
        return true;
      } catch (e) {
        debugPrint('Notice: Supabase order status update notice: $e');
      }
    }

    return true;
  }

  /// Completes all active orders associated with a given food offer (e.g. when restaurant marks post as done).
  Future<void> completeOrdersForOffer(String offerId) async {
    await _ensureLoaded();
    bool updatedAny = false;
    for (int i = 0; i < _seedOrders.length; i++) {
      if (_seedOrders[i].offerId == offerId && _seedOrders[i].isActivePickup) {
        _seedOrders[i] = _seedOrders[i].copyWith(
          status: 'completed',
          updatedAt: DateTime.now(),
        );
        updatedAny = true;
      }
    }
    if (updatedAny) {
      await _persistToPrefs();
    }

    if (!_isLocalOnly) {
      try {
        if (_isValidUuid(offerId)) {
          await _client
              .from(SupabaseConstants.tableOrders)
              .update({
                'status': 'completed',
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('offer_id', offerId)
              .inFilter('status', ['confirmed', 'ready_for_pickup']);
        }
      } catch (e) {
        debugPrint('Supabase completeOrdersForOffer notice: $e');
      }
    }
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
