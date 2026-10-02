import 'package:flutter_test/flutter_test.dart';
import 'package:save_bite/features/customer/offers/data/customer_offer_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('CustomerOfferRepository (Sections 20, 23, 24, 25)', () {
    late CustomerOfferRepository repository;

    setUp(() {
      final client = SupabaseClient(
        'https://test.supabase.co',
        'test-anon-key',
      );
      repository = CustomerOfferRepository(client);
    });

    test('retrieves active offers with fallback demo data', () async {
      final offers = await repository.getActiveOffers();
      expect(offers, isNotEmpty);
      expect(offers.any((o) => o.title.contains('Biryani')), isTrue);
    });

    test('filters active offers by category', () async {
      final riceOffers = await repository.getActiveOffers(category: 'Rice');
      expect(riceOffers, isNotEmpty);
      for (final offer in riceOffers) {
        expect(offer.category, 'Rice');
      }

      final burgerOffers = await repository.getActiveOffers(category: 'Burger');
      expect(burgerOffers, isNotEmpty);
      for (final offer in burgerOffers) {
        expect(offer.category, 'Burger');
      }
    });

    test('filters active offers by search query (Section 24)', () async {
      final results = await repository.getActiveOffers(searchQuery: 'biryani');
      expect(results, isNotEmpty);
      for (final offer in results) {
        final matches = offer.title.toLowerCase().contains('biryani') ||
            (offer.restaurantName?.toLowerCase().contains('biryani') ?? false);
        expect(matches, isTrue);
      }
    });

    test('retrieves single offer by ID', () async {
      final offer = await repository.getOfferById('offer-1');
      expect(offer, isNotNull);
      expect(offer!.id, 'offer-1');
      expect(offer.title, 'Chicken Biryani');
    });

    test('retrieves restaurant details by ID (Section 23)', () async {
      final restaurant = await repository.getRestaurantById('res-1');
      expect(restaurant, isNotNull);
      expect(restaurant!.id, 'res-1');
      expect(restaurant.name, "Rahman's Kitchen");
      expect(restaurant.address, contains('Dhanmondi'));
    });

    test("retrieves restaurant's active offers (Section 23)", () async {
      final offers = await repository.getRestaurantOffers('res-1');
      expect(offers, isNotEmpty);
      for (final offer in offers) {
        expect(offer.restaurantId, 'res-1');
      }
    });

    test('filters active offers by division and area', () async {
      final dhakaOffers = await repository.getActiveOffers(division: 'Dhaka');
      expect(dhakaOffers, isNotEmpty);
      expect(dhakaOffers.every((o) => o.division == 'Dhaka'), isTrue);

      final dhanmondiOffers = await repository.getActiveOffers(
        division: 'Dhaka',
        area: 'Dhanmondi',
      );
      expect(dhanmondiOffers, isNotEmpty);
      expect(dhanmondiOffers.every((o) => o.area == 'Dhanmondi'), isTrue);

      final nonExistentAreaOffers = await repository.getActiveOffers(
        division: 'Dhaka',
        area: 'NonExistentArea',
      );
      expect(nonExistentAreaOffers, isEmpty);

      final otherDivisionOffers = await repository.getActiveOffers(
        division: 'Sylhet',
      );
      expect(otherDivisionOffers, isEmpty);
    });
  });
}
