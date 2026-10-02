import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../../shared/models/food_offer.dart';
import '../../shared/models/restaurant.dart';
import '../data/restaurant_repository.dart';

/// Fetches the current restaurant for the logged-in restaurant owner.
final currentRestaurantProvider = FutureProvider<Restaurant?>((ref) async {
  final user = ref.watch(currentUserProfileProvider);
  if (user == null || !user.isRestaurant) return null;

  final repo = ref.watch(restaurantRepositoryProvider);
  return repo.getRestaurantByOwnerId(
    user.id,
    defaultName: user.fullName,
    defaultPhone: user.phone,
  );
});

/// Fetches the offers posted by the current restaurant.
final currentRestaurantOffersProvider =
    FutureProvider<List<FoodOffer>>((ref) async {
  final restaurant = await ref.watch(currentRestaurantProvider.future);
  if (restaurant == null) return [];

  final repo = ref.watch(restaurantRepositoryProvider);
  return repo.getRestaurantOffers(restaurant.id);
});

/// Notifier to handle restaurant actions (update profile, post offer, delete offer).
class RestaurantActionNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> updateProfile(Restaurant updated) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(restaurantRepositoryProvider);
      await repo.updateRestaurantProfile(updated);
      ref.invalidate(currentRestaurantProvider);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> createOffer(FoodOffer offer) async {
    state = const AsyncLoading();
    try {
      final restaurant = await ref.read(currentRestaurantProvider.future);
      if (restaurant == null) {
        throw Exception('Restaurant profile not found');
      }

      final repo = ref.read(restaurantRepositoryProvider);
      await repo.createOffer(offer: offer, restaurant: restaurant);
      ref.invalidate(currentRestaurantOffersProvider);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> deleteOffer(String offerId) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(restaurantRepositoryProvider);
      await repo.deleteOffer(offerId);
      ref.invalidate(currentRestaurantOffersProvider);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final restaurantActionNotifierProvider =
    AsyncNotifierProvider<RestaurantActionNotifier, void>(
  RestaurantActionNotifier.new,
);
