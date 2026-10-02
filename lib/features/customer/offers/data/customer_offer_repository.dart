import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../../auth/domain/user_profile.dart';
import '../../../shared/models/food_offer.dart';
import '../../../shared/models/restaurant.dart';

/// Provider for CustomerOfferRepository.
final customerOfferRepositoryProvider =
    Provider<CustomerOfferRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return CustomerOfferRepository(client);
});

class CustomerOfferRepository {
  CustomerOfferRepository(this._client, {this.useDemoDataOnly = false});

  final supa.SupabaseClient _client;
  final bool useDemoDataOnly;

  bool get _isLocalOnly =>
      useDemoDataOnly ||
      _client.rest.url.contains('placeholder') ||
      _client.rest.url.contains('test');

  // Curated demo dataset matching Section 20 of the specification
  static final List<Restaurant> _seedRestaurants = [
    Restaurant(
      id: 'res-1',
      ownerId: 'owner-1',
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
    ),
    Restaurant(
      id: 'res-2',
      ownerId: 'owner-2',
      name: 'Burger House',
      description: 'Gourmet handcrafted burgers, crispy fries and fresh shakes.',
      phone: '01811998877',
      address: 'Plot 25, Block B, Banani, Dhaka',
      division: 'Dhaka',
      area: 'Banani',
      cuisineType: 'Burger',
      openingTime: '12:00 PM',
      closingTime: '10:30 PM',
      status: AppConstants.statusApproved,
      imageUrl: 'https://images.unsplash.com/photo-1552566626-52f8b828add9?w=600',
    ),
    Restaurant(
      id: 'res-3',
      ownerId: 'owner-3',
      name: 'Bella Italia Pizza',
      description: 'Wood-fired sourdough pizza and artisanal Italian baking.',
      phone: '01911445566',
      address: 'Gulshan 2 Avenue, Dhaka',
      division: 'Dhaka',
      area: 'Gulshan',
      cuisineType: 'Pizza',
      openingTime: '01:00 PM',
      closingTime: '11:00 PM',
      status: AppConstants.statusApproved,
      imageUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=600',
    ),
    Restaurant(
      id: 'res-4',
      ownerId: 'owner-4',
      name: 'Sweet Treats Bakery',
      description: 'Fresh evening bakery surplus, croissants, rolls and desserts.',
      phone: '01611778899',
      address: 'Mirpur DOHS, Dhaka',
      division: 'Dhaka',
      area: 'Mirpur',
      cuisineType: 'Bakery',
      openingTime: '08:00 AM',
      closingTime: '10:00 PM',
      status: AppConstants.statusApproved,
      imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=600',
    ),
  ];

  static final List<FoodOffer> _seedOffers = [
    FoodOffer(
      id: 'offer-1',
      restaurantId: 'res-1',
      restaurantName: "Rahman's Kitchen",
      restaurantAddress: 'Dhanmondi, Dhaka',
      division: 'Dhaka',
      area: 'Dhanmondi',
      title: 'Chicken Biryani',
      description:
          'Fresh chicken biryani prepared today, packaged safely at discounted price before closing.',
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
      id: 'offer-2',
      restaurantId: 'res-2',
      restaurantName: 'Burger House',
      restaurantAddress: 'Banani, Dhaka',
      division: 'Dhaka',
      area: 'Banani',
      title: 'Beef Burger',
      description:
          'Signature beef burger with cheddar, caramelized onions and special sauce.',
      category: 'Burger',
      originalPrice: 240,
      discountedPrice: 120,
      quantity: 5,
      availableFrom: DateTime.now().subtract(const Duration(minutes: 30)),
      availableUntil: DateTime.now().add(const Duration(hours: 2, minutes: 30)),
      imageUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600',
      isActive: true,
      adminBlocked: false,
    ),
    FoodOffer(
      id: 'offer-3',
      restaurantId: 'res-3',
      restaurantName: 'Bella Italia Pizza',
      restaurantAddress: 'Gulshan 2, Dhaka',
      division: 'Dhaka',
      area: 'Gulshan',
      title: 'Margherita Pizza (12 inch)',
      description:
          'Classic wood-fired sourdough pizza with mozzarella, tomato sauce and fresh basil.',
      category: 'Pizza',
      originalPrice: 650,
      discountedPrice: 380,
      quantity: 4,
      availableFrom: DateTime.now().subtract(const Duration(hours: 1)),
      availableUntil: DateTime.now().add(const Duration(hours: 4)),
      imageUrl: 'https://images.unsplash.com/photo-1604382355076-af4b0eb60143?w=600',
      isActive: true,
      adminBlocked: false,
    ),
    FoodOffer(
      id: 'offer-4',
      restaurantId: 'res-4',
      restaurantName: 'Sweet Treats Bakery',
      restaurantAddress: 'Mirpur DOHS, Dhaka',
      division: 'Dhaka',
      area: 'Mirpur',
      title: 'Assorted Butter Croissants Box (4 pcs)',
      description:
          'Freshly baked flaky butter croissants prepared this afternoon.',
      category: 'Bakery',
      originalPrice: 360,
      discountedPrice: 180,
      quantity: 6,
      availableFrom: DateTime.now().subtract(const Duration(minutes: 45)),
      availableUntil: DateTime.now().add(const Duration(hours: 2)),
      imageUrl: 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=600',
      isActive: true,
      adminBlocked: false,
    ),
    FoodOffer(
      id: 'offer-5',
      restaurantId: 'res-1',
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
    FoodOffer(
      id: 'offer-6',
      restaurantId: 'res-1',
      restaurantName: "Rahman's Kitchen",
      restaurantAddress: 'Dhanmondi, Dhaka',
      division: 'Dhaka',
      area: 'Dhanmondi',
      title: 'Kebab & Naan Platter',
      description: 'Charcoal grilled seekh kebabs with hot butter naans.',
      category: 'Fast Food',
      originalPrice: 400,
      discountedPrice: 200,
      quantity: 5,
      availableFrom: DateTime.now().subtract(const Duration(minutes: 20)),
      availableUntil: DateTime.now().add(const Duration(hours: 3)),
      imageUrl: 'https://images.unsplash.com/photo-1544025162-d76694265947?w=600',
      isActive: true,
      adminBlocked: false,
    ),
  ];

  /// Retrieves customer-visible active food offers (Section 13, 44, 61) with category, search, division and area filters.
  Future<List<FoodOffer>> getActiveOffers({
    String? category,
    String? searchQuery,
    String? division,
    String? area,
  }) async {
    if (!_isLocalOnly) {
      try {
        final now = DateTime.now().toIso8601String();
        var queryBuilder = _client
            .from(SupabaseConstants.tableOffers)
            .select('*, restaurants!inner(*)')
            .eq('is_active', true)
            .eq('admin_blocked', false)
            .gt('available_until', now)
            .eq('restaurants.status', AppConstants.statusApproved);

        if (category != null && category.isNotEmpty && category != 'All') {
          queryBuilder = queryBuilder.eq('category', category);
        }

        if (searchQuery != null && searchQuery.trim().isNotEmpty) {
          queryBuilder = queryBuilder.ilike('title', '%${searchQuery.trim()}%');
        }

        if (division != null && division.isNotEmpty && division != 'All') {
          queryBuilder = queryBuilder.ilike('restaurants.address', '%$division%');
        }

        if (area != null && area.isNotEmpty && area != 'All') {
          queryBuilder = queryBuilder.ilike('restaurants.address', '%$area%');
        }

        final List<dynamic> response = await queryBuilder;
        final offers = response
            .map((row) => FoodOffer.fromJson(row as Map<String, dynamic>))
            .where((offer) => offer.isVisibleToCustomer())
            .toList();

        if (offers.isNotEmpty) return offers;
      } catch (_) {
        // Fallback to seed offers for demonstration/development
      }
    }

    // Filter seed offers based on parameters
    return _seedOffers.where((offer) {
      if (!offer.isVisibleToCustomer()) return false;
      if (category != null && category.isNotEmpty && category != 'All') {
        if (offer.category.toLowerCase() != category.toLowerCase()) return false;
      }
      if (division != null && division.isNotEmpty && division != 'All') {
        final d = division.toLowerCase();
        final matchesDiv = (offer.division?.toLowerCase() == d) ||
            (offer.restaurantAddress?.toLowerCase().contains(d) ?? false);
        if (!matchesDiv) return false;
      }
      if (area != null && area.isNotEmpty && area != 'All') {
        final a = area.toLowerCase();
        final matchesArea = (offer.area?.toLowerCase() == a) ||
            (offer.restaurantAddress?.toLowerCase().contains(a) ?? false);
        if (!matchesArea) return false;
      }
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        final matchesTitle = offer.title.toLowerCase().contains(q);
        final matchesRestaurant =
            offer.restaurantName?.toLowerCase().contains(q) ?? false;
        final matchesCategory = offer.category.toLowerCase().contains(q);
        final matchesArea = offer.area?.toLowerCase().contains(q) ?? false;
        if (!matchesTitle && !matchesRestaurant && !matchesCategory && !matchesArea) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  /// Retrieves single food offer by ID.
  Future<FoodOffer?> getOfferById(String id) async {
    if (!_isLocalOnly) {
      try {
        final response = await _client
            .from(SupabaseConstants.tableOffers)
            .select('*, restaurants(*)')
            .eq('id', id)
            .maybeSingle();

        if (response != null) {
          return FoodOffer.fromJson(response);
        }
      } catch (_) {}
    }

    return _seedOffers.where((o) => o.id == id).firstOrNull;
  }

  /// Retrieves restaurant details by ID (Section 23).
  Future<Restaurant?> getRestaurantById(String id) async {
    if (!_isLocalOnly) {
      try {
        final response = await _client
            .from(SupabaseConstants.tableRestaurants)
            .select()
            .eq('id', id)
            .maybeSingle();

        if (response != null) {
          return Restaurant.fromJson(response);
        }
      } catch (_) {}
    }

    return _seedRestaurants.where((r) => r.id == id).firstOrNull;
  }

  /// Retrieves active offers for a specific restaurant (Section 23).
  Future<List<FoodOffer>> getRestaurantOffers(String restaurantId) async {
    if (!_isLocalOnly) {
      try {
        final now = DateTime.now().toIso8601String();
        final List<dynamic> response = await _client
            .from(SupabaseConstants.tableOffers)
            .select('*, restaurants(*)')
            .eq('restaurant_id', restaurantId)
            .eq('is_active', true)
            .eq('admin_blocked', false)
            .gt('available_until', now);

        final offers = response
            .map((row) => FoodOffer.fromJson(row as Map<String, dynamic>))
            .where((o) => o.isVisibleToCustomer())
            .toList();

        if (offers.isNotEmpty) return offers;
      } catch (_) {}
    }

    return _seedOffers
        .where((o) => o.restaurantId == restaurantId && o.isVisibleToCustomer())
        .toList();
  }

  /// Retrieves active restaurants that have available surplus food offers right now.
  Future<List<Restaurant>> getActiveRestaurants({
    String? division,
    String? area,
  }) async {
    final activeOffers = await getActiveOffers(
      division: division,
      area: area,
    );
    final activeRestaurantIds = activeOffers.map((o) => o.restaurantId).toSet();

    if (!_isLocalOnly) {
      try {
        final List<dynamic> response = await _client
            .from(SupabaseConstants.tableRestaurants)
            .select()
            .eq('status', AppConstants.statusApproved);

        final restaurants = response
            .map((row) => Restaurant.fromJson(row as Map<String, dynamic>))
            .where((r) => activeRestaurantIds.contains(r.id))
            .toList();

        if (restaurants.isNotEmpty) return restaurants;
      } catch (_) {}
    }

    return _seedRestaurants
        .where((r) =>
            activeRestaurantIds.contains(r.id) &&
            (division == null || r.division == division) &&
            (area == null || r.area == area))
        .toList();
  }

  /// Updates customer profile (Section 26).
  Future<UserProfile> updateCustomerProfile({
    required String id,
    required String fullName,
    String? phone,
  }) async {
    try {
      final data = {
        'full_name': fullName.trim(),
        'phone': phone?.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _client
          .from(SupabaseConstants.tableProfiles)
          .update(data)
          .eq('id', id);

      final updated = await _client
          .from(SupabaseConstants.tableProfiles)
          .select()
          .eq('id', id)
          .single();

      return UserProfile.fromJson(updated);
    } catch (e) {
      throw ServerException('Failed to update profile: $e');
    }
  }
}
