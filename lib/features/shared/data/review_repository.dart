import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client_provider.dart';
import '../models/review.dart';

/// Provider for ReviewRepository instance.
final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return ReviewRepository(supabase);
});

/// Repository handling customer reviews, ratings, and verified review badges.
class ReviewRepository {
  ReviewRepository(this._supabase);

  final SupabaseClient _supabase;

  static const String _storageKey = 'sb_customer_reviews_cache';

  /// In-memory cache for fast synchronous & resilient offline retrieval
  static final List<Review> _memoryReviews = [
    Review(
      id: 'rev-seed-1',
      orderId: 'ord-seed-1',
      customerId: 'cust-demo-1',
      customerName: 'Ayesha Rahman',
      customerAvatarUrl: null,
      restaurantId: 'res-blue-bell',
      restaurantName: 'Blue Bell Café',
      offerId: 'off-blue-bell-1',
      offerTitle: 'Croissant & Hazelnut Latte Box',
      rating: 5.0,
      comment:
          'Super fresh and warm! Rescued this box right before closing and the croissants were as soft as morning bake. 10/10 value for money!',
      imageUrl: 'assets/images/coffee_cup.jpg',
      isVerified: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    Review(
      id: 'rev-seed-2',
      orderId: 'ord-seed-2',
      customerId: 'cust-demo-2',
      customerName: 'Tanvir Hasan',
      customerAvatarUrl: null,
      restaurantId: 'res-blue-bell',
      restaurantName: 'Blue Bell Café',
      offerId: 'off-blue-bell-2',
      offerTitle: 'Dark Chocolate Pastry Duo',
      rating: 4.8,
      comment:
          'Amazing rich chocolate flavor and generous portions. Cashier scanned my PIN quickly and gave me a fresh takeaway bag. Great initiative!',
      imageUrl: 'assets/images/bakery_logo.jpg',
      isVerified: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    ),
    Review(
      id: 'rev-seed-3',
      orderId: 'ord-seed-3',
      customerId: 'cust-demo-3',
      customerName: 'Samira Chowdhury',
      customerAvatarUrl: null,
      restaurantId: 'res-blue-bell',
      restaurantName: 'Blue Bell Café',
      offerId: 'off-blue-bell-1',
      offerTitle: 'Croissant & Hazelnut Latte Box',
      rating: 5.0,
      comment:
          'SaveBite has saved me so much money on evening snacks in Dhanmondi. Coffee was rich and perfectly packed.',
      imageUrl: 'assets/images/coffee_day_banner.jpg',
      isVerified: true,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Review(
      id: 'rev-seed-4',
      orderId: 'ord-seed-4',
      customerId: 'cust-demo-4',
      customerName: 'Fahim Morshed',
      customerAvatarUrl: null,
      restaurantId: 'res-1',
      restaurantName: "Rahman's Kitchen",
      offerId: 'off-rahman-1',
      offerTitle: 'Kacchi Biryani Box (Mutton)',
      rating: 4.9,
      comment:
          'Authentic taste and perfectly tender meat! A whole portion at 50% discount was an absolute steal. Verified pickup was seamless.',
      imageUrl: 'assets/images/biryani_logo.jpg',
      isVerified: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Review(
      id: 'rev-seed-5',
      orderId: 'ord-seed-5',
      customerId: 'cust-demo-5',
      customerName: 'Zubair Al-Mamun',
      customerAvatarUrl: null,
      restaurantId: 'res-2',
      restaurantName: 'Burger Hub & Grill',
      offerId: 'off-burger-1',
      offerTitle: 'Smoky Beef Burger & Fries Drop',
      rating: 4.7,
      comment:
          'Juicy patty, warm buns, and crisp seasoned fries. Picked up in Banani with my code without waiting in line.',
      imageUrl: 'assets/images/burger_hub_logo.jpg',
      isVerified: true,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    Review(
      id: 'rev-seed-6',
      orderId: 'ord-seed-6',
      customerId: 'cust-demo-6',
      customerName: 'Nadia Karim',
      customerAvatarUrl: null,
      restaurantId: 'res-3',
      restaurantName: 'Woodfire Crust Pizza',
      offerId: 'off-pizza-1',
      offerTitle: '12" Pepperoni Delight (Surplus)',
      rating: 5.0,
      comment:
          'Crust was still crispy and toppings were plentiful. Unbelievable discount for a 12-inch pizza. Highly recommended!',
      imageUrl: 'assets/images/woodfire_crust_logo.jpg',
      isVerified: true,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
  ];

  static bool _hasLoadedFromPrefs = false;

  /// Loads reviews from SharedPreferences into memory cache
  Future<void> _ensureCacheLoaded() async {
    if (_hasLoadedFromPrefs) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        for (final item in decoded) {
          final review = Review.fromJson(item as Map<String, dynamic>);
          if (!_memoryReviews.any((r) => r.id == review.id)) {
            _memoryReviews.insert(0, review);
          }
        }
      }
      _hasLoadedFromPrefs = true;
    } catch (e) {
      debugPrint('[ReviewRepository] Cache load error: $e');
    }
  }

  /// Saves user-submitted reviews to SharedPreferences
  Future<void> _saveCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_memoryReviews.map((r) => r.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      debugPrint('[ReviewRepository] Cache save error: $e');
    }
  }

  /// Fetches all reviews for a specific restaurant
  Future<List<Review>> getReviewsForRestaurant(String restaurantId) async {
    await _ensureCacheLoaded();
    try {
      final response = await _supabase
          .from('reviews')
          .select()
          .eq('restaurant_id', restaurantId)
          .order('created_at', ascending: false);

      if (response.isNotEmpty) {
        final liveReviews = (response as List<dynamic>)
            .map((json) => Review.fromJson(json as Map<String, dynamic>))
            .toList();

        // Merge live with any newly posted local memory reviews not yet synced
        for (final mem in _memoryReviews) {
          if (mem.restaurantId == restaurantId &&
              !liveReviews.any((r) => r.id == mem.id || r.orderId == mem.orderId)) {
            liveReviews.insert(0, mem);
          }
        }
        return liveReviews;
      }
    } catch (e) {
      debugPrint('[ReviewRepository] Live fetch error (using fallback): $e');
    }

    // Fallback: match by ID or normalize alias ('res-1' vs 'demo-restaurant-id' vs 'res-blue-bell')
    return _memoryReviews.where((r) {
      if (r.restaurantId == restaurantId) return true;
      if ((restaurantId == 'res-1' || restaurantId == 'demo-restaurant-id') &&
          (r.restaurantId == 'res-1' || r.restaurantId == 'res-blue-bell')) {
        return true;
      }
      return false;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Fetches all reviews submitted by a specific customer
  Future<List<Review>> getReviewsForCustomer(String customerId) async {
    await _ensureCacheLoaded();
    try {
      final response = await _supabase
          .from('reviews')
          .select()
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);

      if (response.isNotEmpty) {
        final liveReviews = (response as List<dynamic>)
            .map((json) => Review.fromJson(json as Map<String, dynamic>))
            .toList();

        for (final mem in _memoryReviews) {
          if (mem.customerId == customerId &&
              !liveReviews.any((r) => r.id == mem.id)) {
            liveReviews.insert(0, mem);
          }
        }
        return liveReviews;
      }
    } catch (e) {
      debugPrint('[ReviewRepository] Customer reviews live fetch error: $e');
    }

    return _memoryReviews
        .where((r) => r.customerId == customerId || customerId == 'demo-customer-id')
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Checks whether an order has already been reviewed
  Future<bool> hasReviewedOrder(String orderId) async {
    await _ensureCacheLoaded();
    if (_memoryReviews.any((r) => r.orderId == orderId)) {
      return true;
    }

    try {
      final response = await _supabase
          .from('reviews')
          .select('id')
          .eq('order_id', orderId)
          .maybeSingle();
      return response != null;
    } catch (_) {
      return false;
    }
  }

  /// Retrieves the review submitted for a specific order
  Future<Review?> getReviewForOrder(String orderId) async {
    await _ensureCacheLoaded();
    final cached = _memoryReviews.where((r) => r.orderId == orderId).firstOrNull;
    if (cached != null) return cached;

    try {
      final response = await _supabase
          .from('reviews')
          .select()
          .eq('order_id', orderId)
          .maybeSingle();

      if (response != null) {
        return Review.fromJson(response);
      }
    } catch (_) {}

    return null;
  }

  /// Submits a new customer review with rating, comments, and optional photo
  Future<Review> submitReview(Review review) async {
    await _ensureCacheLoaded();

    // 1. Try to persist to live Supabase backend
    try {
      final data = review.toJson();
      await _supabase.from('reviews').upsert(data);
    } catch (e) {
      debugPrint('[ReviewRepository] Live submit warning: $e');
    }

    // 2. Add or update in memory cache
    final existingIndex = _memoryReviews.indexWhere((r) => r.orderId == review.orderId);
    if (existingIndex >= 0) {
      _memoryReviews[existingIndex] = review;
    } else {
      _memoryReviews.insert(0, review);
    }

    // 3. Persist locally to SharedPreferences
    await _saveCache();

    return review;
  }

  /// Calculates aggregated rating summary for a restaurant
  Future<RestaurantRatingSummary> getRatingSummary(String restaurantId) async {
    final reviews = await getReviewsForRestaurant(restaurantId);

    if (reviews.isEmpty) {
      return RestaurantRatingSummary(
        restaurantId: restaurantId,
        averageRating: 4.8, // Healthy default for demo partners
        totalReviews: 0,
        fiveStarCount: 0,
        fourStarCount: 0,
        threeStarCount: 0,
        twoStarCount: 0,
        oneStarCount: 0,
      );
    }

    int five = 0;
    int four = 0;
    int three = 0;
    int two = 0;
    int one = 0;
    double sum = 0;

    for (final r in reviews) {
      sum += r.rating;
      final rounded = r.rating.round();
      if (rounded >= 5) {
        five++;
      } else if (rounded == 4) {
        four++;
      } else if (rounded == 3) {
        three++;
      } else if (rounded == 2) {
        two++;
      } else {
        one++;
      }
    }

    final avg = sum / reviews.length;
    final verifiedCount = reviews.where((r) => r.isVerified).length;

    return RestaurantRatingSummary(
      restaurantId: restaurantId,
      averageRating: double.parse(avg.toStringAsFixed(1)),
      totalReviews: reviews.length,
      fiveStarCount: five,
      fourStarCount: four,
      threeStarCount: three,
      twoStarCount: two,
      oneStarCount: one,
      verifiedRescueCount: verifiedCount,
    );
  }
}
