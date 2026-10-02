import 'package:flutter_test/flutter_test.dart';
import 'package:save_bite/core/constants/app_constants.dart';
import 'package:save_bite/core/errors/app_exceptions.dart';
import 'package:save_bite/features/restaurant/data/restaurant_repository.dart';
import 'package:save_bite/features/shared/models/food_offer.dart';
import 'package:save_bite/features/shared/models/restaurant.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('Restaurant Model - Profile Completeness', () {
    test('isProfileComplete returns true when all required fields and photo are present', () {
      const restaurant = Restaurant(
        id: 'res-1',
        ownerId: 'owner-1',
        name: "Rahman's Kitchen",
        phone: '01711223344',
        address: 'House 14, Road 7, Dhanmondi, Dhaka',
        division: 'Dhaka',
        area: 'Dhanmondi',
        imageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=600',
        cuisineType: 'Bengali',
        status: AppConstants.statusApproved,
      );

      expect(restaurant.isProfileComplete, isTrue);
      expect(restaurant.missingProfileFields, isEmpty);
    });

    test('isProfileComplete returns false when profile picture (imageUrl) is missing', () {
      const restaurant = Restaurant(
        id: 'res-1',
        ownerId: 'owner-1',
        name: "Rahman's Kitchen",
        phone: '01711223344',
        address: 'House 14, Road 7, Dhanmondi, Dhaka',
        division: 'Dhaka',
        area: 'Dhanmondi',
        imageUrl: null,
        cuisineType: 'Bengali',
      );

      expect(restaurant.isProfileComplete, isFalse);
      expect(restaurant.missingProfileFields, contains('Restaurant Profile Picture'));
    });

    test('isProfileComplete returns false when division or area is missing', () {
      const restaurant = Restaurant(
        id: 'res-1',
        ownerId: 'owner-1',
        name: "Rahman's Kitchen",
        phone: '01711223344',
        address: 'House 14, Road 7, Dhanmondi, Dhaka',
        division: null,
        area: null,
        imageUrl: 'https://example.com/logo.jpg',
        cuisineType: 'Bengali',
      );

      expect(restaurant.isProfileComplete, isFalse);
      expect(restaurant.missingProfileFields, contains('Division'));
      expect(restaurant.missingProfileFields, contains('Area'));
    });

    test('Restaurant serializes and deserializes division and area correctly', () {
      const original = Restaurant(
        id: 'res-test',
        ownerId: 'owner-test',
        name: 'Gulshan Diner',
        phone: '01912345678',
        address: 'Road 11, Gulshan 1, Dhaka',
        division: 'Dhaka',
        area: 'Gulshan',
        imageUrl: 'https://example.com/diner.jpg',
        cuisineType: 'Fast Food',
      );

      final json = original.toJson();
      expect(json['division'], 'Dhaka');
      expect(json['area'], 'Gulshan');

      final reconstructed = Restaurant.fromJson(json);
      expect(reconstructed.division, 'Dhaka');
      expect(reconstructed.area, 'Gulshan');
      expect(reconstructed.isProfileComplete, isTrue);
    });
  });

  group('RestaurantRepository - Post Creation Verification', () {
    test('createOffer throws ValidationException when restaurant profile is incomplete', () async {
      // Create repository with mock/local client
      final client = SupabaseClient('https://test.supabase.co', 'fake-key');
      final repo = RestaurantRepository(client, useDemoDataOnly: true);

      const incompleteRestaurant = Restaurant(
        id: 'res-incomplete',
        ownerId: 'owner-inc',
        name: 'Incomplete Cafe',
        phone: '01711223344',
        address: 'Dhanmondi, Dhaka',
        division: 'Dhaka',
        area: 'Dhanmondi',
        imageUrl: null, // Missing profile picture!
        cuisineType: 'Bakery',
      );

      final offer = FoodOffer(
        id: 'offer-new',
        restaurantId: incompleteRestaurant.id,
        title: 'Fresh Bread',
        category: 'Bakery',
        originalPrice: 100,
        discountedPrice: 50,
        quantity: 3,
        availableFrom: DateTime.now(),
        availableUntil: DateTime.now().add(const Duration(hours: 2)),
      );

      expect(
        () => repo.createOffer(offer: offer, restaurant: incompleteRestaurant),
        throwsA(isA<ValidationException>()),
      );
    });

    test('createOffer succeeds when restaurant profile is fully complete', () async {
      final client = SupabaseClient('https://test.supabase.co', 'fake-key');
      final repo = RestaurantRepository(client, useDemoDataOnly: true);

      const completeRestaurant = Restaurant(
        id: 'res-complete',
        ownerId: 'owner-comp',
        name: 'Complete Kitchen',
        phone: '01711223344',
        address: 'Road 5, Dhanmondi, Dhaka',
        division: 'Dhaka',
        area: 'Dhanmondi',
        imageUrl: 'https://example.com/logo.jpg',
        cuisineType: 'Bengali',
      );

      final offer = FoodOffer(
        id: 'offer-new',
        restaurantId: completeRestaurant.id,
        title: 'Special Tehari',
        category: 'Rice',
        originalPrice: 200,
        discountedPrice: 120,
        quantity: 4,
        availableFrom: DateTime.now(),
        availableUntil: DateTime.now().add(const Duration(hours: 3)),
      );

      final created = await repo.createOffer(offer: offer, restaurant: completeRestaurant);
      expect(created.title, 'Special Tehari');
      expect(created.division, 'Dhaka');
      expect(created.area, 'Dhanmondi');
      expect(created.restaurantName, 'Complete Kitchen');
    });
  });
}
