import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../shared/models/food_offer.dart';
import '../../shared/models/restaurant.dart';

/// Provider for RestaurantRepository.
final restaurantRepositoryProvider = Provider<RestaurantRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return RestaurantRepository(client);
});

class RestaurantRepository {
  RestaurantRepository(this._client, {this.useDemoDataOnly = false});

  final supa.SupabaseClient _client;
  final bool useDemoDataOnly;

  bool get _isLocalOnly =>
      useDemoDataOnly ||
      _client.rest.url.contains('placeholder') ||
      _client.rest.url.contains('test');

  /// In-memory cache of restaurants by ownerId
  static final Map<String, Restaurant> _memoryRestaurants = {};

  /// In-memory cache of created offers
  static final List<FoodOffer> _createdOffers = [];

  /// Retrieves the restaurant owned by [ownerId].
  Future<Restaurant> getRestaurantByOwnerId(String ownerId, {String? defaultName, String? defaultPhone}) async {
    // 1. Check local persistent storage
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('sb_restaurant_$ownerId');
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final res = Restaurant.fromJson(data);
        _memoryRestaurants[ownerId] = res;
        return res;
      }
    } catch (e) {
      debugPrint('SharedPreferences restaurant read notice: $e');
    }

    // 2. Check in-memory cache
    if (_memoryRestaurants.containsKey(ownerId)) {
      return _memoryRestaurants[ownerId]!;
    }

    // 3. Try fetching from Supabase if online
    if (!_isLocalOnly) {
      try {
        final response = await _client
            .from(SupabaseConstants.tableRestaurants)
            .select()
            .eq('owner_id', ownerId)
            .maybeSingle();

        if (response != null) {
          final res = Restaurant.fromJson(response);
          _memoryRestaurants[ownerId] = res;
          await _persistRestaurant(res);
          return res;
        }
      } catch (e) {
        debugPrint('Supabase getRestaurantByOwnerId notice: $e');
      }
    }

    // 4. Fallback for demo restaurant account
    if (ownerId == 'demo-restaurant-id' || ownerId == 'owner-1') {
      const demoRes = Restaurant(
        id: 'res-1',
        ownerId: 'demo-restaurant-id',
        name: "Rahman's Kitchen",
        description: 'Authentic Bengali biryani, tehari and homemade delicacies.',
        phone: '01711223344',
        address: 'House 14, Road 7, Dhanmondi, Dhaka',
        division: 'Dhaka',
        area: 'Dhanmondi',
        cuisineType: 'Bengali',
        openingTime: '11:00 AM',
        closingTime: '11:00 PM',
        status: AppConstants.statusApproved,
        imageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=600',
      );
      _memoryRestaurants[ownerId] = demoRes;
      await _persistRestaurant(demoRes);
      return demoRes;
    }

    // 5. Default new restaurant object for new signups
    final newRes = Restaurant(
      id: 'res_${DateTime.now().millisecondsSinceEpoch}',
      ownerId: ownerId,
      name: defaultName ?? 'My Restaurant',
      phone: defaultPhone,
      division: 'Dhaka',
      status: AppConstants.statusPending,
    );
    _memoryRestaurants[ownerId] = newRes;
    await _persistRestaurant(newRes);
    return newRes;
  }

  /// Persists restaurant locally
  static Future<void> _persistRestaurant(Restaurant restaurant) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'sb_restaurant_${restaurant.ownerId}',
        jsonEncode(restaurant.toJson()),
      );
    } catch (_) {}
  }

  /// Updates restaurant profile.
  Future<Restaurant> updateRestaurantProfile(Restaurant restaurant) async {
    _memoryRestaurants[restaurant.ownerId] = restaurant;
    await _persistRestaurant(restaurant);

    if (!_isLocalOnly) {
      try {
        await _client
            .from(SupabaseConstants.tableRestaurants)
            .upsert(restaurant.toJson());
      } catch (e) {
        debugPrint('Supabase updateRestaurantProfile notice: $e');
      }
    }

    return restaurant;
  }

  /// Retrieves all food offers posted by this restaurant.
  Future<List<FoodOffer>> getRestaurantOffers(String restaurantId) async {
    final List<FoodOffer> results = [];

    // Local in-memory created offers
    results.addAll(_createdOffers.where((o) => o.restaurantId == restaurantId));

    if (!_isLocalOnly) {
      try {
        final List<dynamic> response = await _client
            .from(SupabaseConstants.tableOffers)
            .select('*, restaurants(*)')
            .eq('restaurant_id', restaurantId)
            .order('created_at', ascending: false);

        for (final row in response) {
          final offer = FoodOffer.fromJson(row as Map<String, dynamic>);
          if (!results.any((r) => r.id == offer.id)) {
            results.add(offer);
          }
        }
      } catch (e) {
        debugPrint('Supabase getRestaurantOffers notice: $e');
      }
    }

    // Fallback seed offers if this is demo restaurant res-1
    if (results.isEmpty && (restaurantId == 'res-1' || restaurantId.contains('demo'))) {
      results.addAll([
        FoodOffer(
          id: 'offer-1',
          restaurantId: restaurantId,
          restaurantName: "Rahman's Kitchen",
          restaurantAddress: 'Dhanmondi, Dhaka',
          division: 'Dhaka',
          area: 'Dhanmondi',
          title: 'Chicken Biryani',
          description: 'Fresh chicken biryani prepared today, packaged safely before closing.',
          category: 'Rice',
          originalPrice: 250,
          discountedPrice: 150,
          quantity: 8,
          availableFrom: DateTime.now().subtract(const Duration(hours: 1)),
          availableUntil: DateTime.now().add(const Duration(hours: 3)),
          imageUrl: 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=600',
          isActive: true,
          adminBlocked: false,
        ),
        FoodOffer(
          id: 'offer-5',
          restaurantId: restaurantId,
          restaurantName: "Rahman's Kitchen",
          restaurantAddress: 'Dhanmondi, Dhaka',
          division: 'Dhaka',
          area: 'Dhanmondi',
          title: 'Special Beef Tehari',
          description: 'Aromatic mustard oil cooked beef tehari with fresh spices.',
          category: 'Rice',
          originalPrice: 280,
          discountedPrice: 180,
          quantity: 3,
          availableFrom: DateTime.now().subtract(const Duration(hours: 1)),
          availableUntil: DateTime.now().add(const Duration(hours: 3)),
          imageUrl: 'https://images.unsplash.com/photo-1589302168068-964664d93dc0?w=600',
          isActive: true,
          adminBlocked: false,
        ),
      ]);
    }

    return results;
  }

  /// Places a new food offer post.
  /// Strictly checks if restaurant profile is complete.
  Future<FoodOffer> createOffer({
    required FoodOffer offer,
    required Restaurant restaurant,
  }) async {
    // ENFORCE PROFILE COMPLETENESS
    if (!restaurant.isProfileComplete) {
      final missing = restaurant.missingProfileFields.join(', ');
      throw ValidationException(
        'Cannot post offer: Your restaurant profile is incomplete. '
        'Please complete the following required fields first: $missing.',
      );
    }

    final enrichedOffer = offer.copyWith(
      restaurantId: restaurant.id,
      restaurantName: restaurant.name,
      restaurantAddress: restaurant.address,
      division: restaurant.division ?? 'Dhaka',
      area: restaurant.area,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _createdOffers.insert(0, enrichedOffer);

    if (!_isLocalOnly) {
      try {
        await _client
            .from(SupabaseConstants.tableOffers)
            .insert(enrichedOffer.toJson());
      } catch (e) {
        debugPrint('Supabase createOffer notice: $e');
      }
    }

    return enrichedOffer;
  }

  /// Deletes an offer.
  Future<void> deleteOffer(String offerId) async {
    _createdOffers.removeWhere((o) => o.id == offerId);

    if (!_isLocalOnly) {
      try {
        await _client
            .from(SupabaseConstants.tableOffers)
            .delete()
            .eq('id', offerId);
      } catch (e) {
        debugPrint('Supabase deleteOffer notice: $e');
      }
    }
  }

  /// Toggles offer active state.
  Future<void> toggleOfferStatus(String offerId, bool isActive) async {
    final idx = _createdOffers.indexWhere((o) => o.id == offerId);
    if (idx != -1) {
      _createdOffers[idx] = _createdOffers[idx].copyWith(isActive: isActive);
    }

    if (!_isLocalOnly) {
      try {
        await _client
            .from(SupabaseConstants.tableOffers)
            .update({'is_active': isActive})
            .eq('id', offerId);
      } catch (_) {}
    }
  }
}
