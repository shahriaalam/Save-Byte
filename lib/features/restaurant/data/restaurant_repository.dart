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
        name: 'Blue Bell Café',
        description:
            'Artisanal Coffee Roastery & Italian Bistro crafted with premium coffee beans, fresh pasta, and European pastries in Banasree.',
        phone: '01711234567',
        address: 'House 14, Road 4, Block D, Banasree, Dhaka 1219',
        division: 'Dhaka',
        area: 'Banasree',
        cuisineType: 'Specialty Coffee & Italian Bistro',
        openingTime: '07:30 AM',
        closingTime: '11:00 PM',
        status: AppConstants.statusApproved,
        imageUrl:
            'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=600',
        isPremium: false,
        subscriptionPlan: null,
        boostCredits: 0,
        bannerCredits: 0,
        hasActiveBanner: false,
        activeBannerId: null,
      );
      _memoryRestaurants[ownerId] = demoRes;
      await _persistRestaurant(demoRes);
      return demoRes;
    }

    // 5. Default new restaurant object for new signups
    final newRes = Restaurant(
      id: 'res_${DateTime.now().millisecondsSinceEpoch}',
      ownerId: ownerId,
      name: defaultName ?? 'Blue Bell Café',
      phone: defaultPhone ?? '01711234567',
      address: 'House 14, Road 4, Block D, Banasree, Dhaka 1219',
      division: 'Dhaka',
      area: 'Banasree',
      cuisineType: 'Specialty Coffee & Italian Bistro',
      openingTime: '07:30 AM',
      closingTime: '11:00 PM',
      status: AppConstants.statusApproved,
      imageUrl:
          'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=600',
      isPremium: true,
      subscriptionPlan: 'gold',
      boostCredits: 5,
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

  /// Upgrades or manages restaurant subscription (e.g. SaveBite Gold Merchant).
  /// Gold Merchant grants 1 hero banner ad quota per subscription.
  Future<Restaurant> updateSubscription(
    String ownerId, {
    required bool isPremium,
    String? plan,
    int? boostCredits,
    int? bannerCredits,
    bool? hasActiveBanner,
    String? activeBannerId,
  }) async {
    final current = await getRestaurantByOwnerId(ownerId);
    final updated = current.copyWith(
      isPremium: isPremium,
      subscriptionPlan: plan ?? (isPremium ? 'gold' : null),
      subscriptionExpiresAt: isPremium
          ? DateTime.now().add(const Duration(days: 30))
          : null,
      boostCredits: boostCredits ?? (isPremium ? 5 : 0),
      bannerCredits: bannerCredits ?? (isPremium ? 1 : 0),
      hasActiveBanner: hasActiveBanner ?? current.hasActiveBanner,
      activeBannerId: activeBannerId ?? current.activeBannerId,
    );
    return updateRestaurantProfile(updated);
  }

  /// Adds banner credits when a restaurant purchases a banner facility from Offers.
  Future<Restaurant> addBannerCredits(String ownerId, int count) async {
    final current = await getRestaurantByOwnerId(ownerId);
    final updated = current.copyWith(
      bannerCredits: current.bannerCredits + count,
      hasActiveBanner: true,
    );
    return updateRestaurantProfile(updated);
  }

  /// Uses 1 banner credit upon submitting a hero banner request.
  Future<Restaurant> useBannerCredit(String ownerId) async {
    final current = await getRestaurantByOwnerId(ownerId);
    final updated = current.copyWith(
      bannerCredits: (current.bannerCredits - 1).clamp(0, 999),
    );
    return updateRestaurantProfile(updated);
  }

  /// In-memory map for overrides on default seed offers (for toggling boost or active status).
  static final Map<String, FoodOffer> _seedOfferOverrides = {};

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

    // Fallback seed offers for Blue Bell Café (res-1 or demo)
    if (results.isEmpty &&
        (restaurantId == 'res-1' || restaurantId.contains('demo'))) {
      final defaultSeed = [
        FoodOffer(
          id: 'offer-bb-1',
          restaurantId: restaurantId,
          restaurantName: 'Blue Bell Café',
          restaurantAddress: 'House 14, Road 4, Block D, Banasree, Dhaka',
          division: 'Dhaka',
          area: 'Banasree',
          title: 'Tuscan Slow-Baked Lasagna',
          description:
              'Layers of fresh egg pasta, slow-simmered bolognese ragù, creamy béchamel, and melted parmesan. Packaged fresh for dinner surplus discovery.',
          category: 'Italian',
          originalPrice: 750,
          discountedPrice: 420,
          quantity: 6,
          availableFrom: DateTime.now().subtract(const Duration(hours: 1)),
          availableUntil: DateTime.now().add(const Duration(hours: 4)),
          imageUrl:
              'https://images.unsplash.com/photo-1574894709920-11b28e7367e3?w=600',
          isActive: true,
          adminBlocked: false,
          isBoosted: true,
          boostedUntil: DateTime.now().add(const Duration(hours: 24)),
        ),
        FoodOffer(
          id: 'offer-bb-2',
          restaurantId: restaurantId,
          restaurantName: 'Blue Bell Café',
          restaurantAddress: 'House 14, Road 4, Block D, Banasree, Dhaka',
          division: 'Dhaka',
          area: 'Banasree',
          title: 'Artisan Café Club Sandwich',
          description:
              'Triple-decker sourdough bread layered with smoked chicken, organic fried egg, crisp lettuce, cheddar, and Dijon mayo.',
          category: 'Snacks',
          originalPrice: 380,
          discountedPrice: 220,
          quantity: 8,
          availableFrom: DateTime.now().subtract(const Duration(hours: 1)),
          availableUntil: DateTime.now().add(const Duration(hours: 3)),
          imageUrl:
              'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=600',
          isActive: true,
          adminBlocked: false,
          isBoosted: true,
          boostedUntil: DateTime.now().add(const Duration(hours: 18)),
        ),
        FoodOffer(
          id: 'offer-bb-3',
          restaurantId: restaurantId,
          restaurantName: 'Blue Bell Café',
          restaurantAddress: 'House 14, Road 4, Block D, Banasree, Dhaka',
          division: 'Dhaka',
          area: 'Banasree',
          title: 'Pistachio Flaky Brioche',
          description:
              'Golden French brioche swirl infused with Bronte pistachio cream and white chocolate crumble, baked fresh this afternoon.',
          category: 'Bakery',
          originalPrice: 290,
          discountedPrice: 160,
          quantity: 10,
          availableFrom: DateTime.now().subtract(const Duration(hours: 2)),
          availableUntil: DateTime.now().add(const Duration(hours: 5)),
          imageUrl:
              'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=600',
          isActive: true,
          adminBlocked: false,
          isBoosted: false,
        ),
        FoodOffer(
          id: 'offer-bb-4',
          restaurantId: restaurantId,
          restaurantName: 'Blue Bell Café',
          restaurantAddress: 'House 14, Road 4, Block D, Banasree, Dhaka',
          division: 'Dhaka',
          area: 'Banasree',
          title: 'Truffle Fettuccine Alfredo',
          description:
              'Handcrafted bronze-cut fettuccine tossed in aromatic black truffle butter, heavy cream, garlic, and freshly cracked black pepper.',
          category: 'Italian',
          originalPrice: 850,
          discountedPrice: 480,
          quantity: 4,
          availableFrom: DateTime.now().subtract(const Duration(hours: 1)),
          availableUntil: DateTime.now().add(const Duration(hours: 3)),
          imageUrl:
              'https://images.unsplash.com/photo-1645112411341-6c4fd023714a?w=600',
          isActive: true,
          adminBlocked: false,
          isBoosted: false,
        ),
        FoodOffer(
          id: 'offer-bb-5',
          restaurantId: restaurantId,
          restaurantName: 'Blue Bell Café',
          restaurantAddress: 'House 14, Road 4, Block D, Banasree, Dhaka',
          division: 'Dhaka',
          area: 'Banasree',
          title: 'Venetian Espresso Tiramisu',
          description:
              'Traditional savoiardi ladyfingers soaked in single-origin Blue Bell espresso roast, whipped mascarpone, and Valrhona cocoa.',
          category: 'Dessert',
          originalPrice: 420,
          discountedPrice: 240,
          quantity: 7,
          availableFrom: DateTime.now().subtract(const Duration(hours: 1)),
          availableUntil: DateTime.now().add(const Duration(hours: 4)),
          imageUrl:
              'https://images.unsplash.com/photo-1571877227200-a0d98ea607e9?w=600',
          isActive: true,
          adminBlocked: false,
          isBoosted: false,
        ),
      ];

      for (final seed in defaultSeed) {
        if (_seedOfferOverrides.containsKey(seed.id)) {
          results.add(_seedOfferOverrides[seed.id]!);
        } else {
          results.add(seed);
        }
      }
    }

    return results;
  }

  /// Boosts a food offer for 24 hours (increases discovery ranking).
  Future<void> boostOffer(String offerId) async {
    final idx = _createdOffers.indexWhere((o) => o.id == offerId);
    if (idx != -1) {
      _createdOffers[idx] = _createdOffers[idx].copyWith(
        isBoosted: true,
        boostedUntil: DateTime.now().add(const Duration(hours: 24)),
      );
    } else {
      // Check in seeded offers
      final current = (await getRestaurantOffers('res-1'))
          .where((o) => o.id == offerId)
          .firstOrNull;
      if (current != null) {
        _seedOfferOverrides[offerId] = current.copyWith(
          isBoosted: true,
          boostedUntil: DateTime.now().add(const Duration(hours: 24)),
        );
      }
    }

    if (!_isLocalOnly) {
      try {
        await _client.from(SupabaseConstants.tableOffers).update({
          'is_boosted': true,
          'boosted_until':
              DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
        }).eq('id', offerId);
      } catch (_) {}
    }
  }

  /// Removes boost from an offer.
  Future<void> unboostOffer(String offerId) async {
    final idx = _createdOffers.indexWhere((o) => o.id == offerId);
    if (idx != -1) {
      _createdOffers[idx] = _createdOffers[idx].copyWith(
        isBoosted: false,
        boostedUntil: null,
      );
    } else {
      final current = (await getRestaurantOffers('res-1'))
          .where((o) => o.id == offerId)
          .firstOrNull;
      if (current != null) {
        _seedOfferOverrides[offerId] = current.copyWith(
          isBoosted: false,
          boostedUntil: null,
        );
      }
    }

    if (!_isLocalOnly) {
      try {
        await _client.from(SupabaseConstants.tableOffers).update({
          'is_boosted': false,
          'boosted_until': null,
        }).eq('id', offerId);
      } catch (_) {}
    }
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
      area: restaurant.area ?? 'Banasree',
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
    _seedOfferOverrides.remove(offerId);

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
    } else {
      final current = (await getRestaurantOffers('res-1'))
          .where((o) => o.id == offerId)
          .firstOrNull;
      if (current != null) {
        _seedOfferOverrides[offerId] = current.copyWith(isActive: isActive);
      }
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
