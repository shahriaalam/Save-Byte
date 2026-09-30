import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/food_offer.dart';
import '../../../shared/models/restaurant.dart';
import '../data/customer_offer_repository.dart';

/// Currently selected category filter on Customer Home ('All' by default).
class SelectedCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'All';

  void setCategory(String category) => state = category;
}

final selectedCategoryProvider =
    NotifierProvider<SelectedCategoryNotifier, String>(
  SelectedCategoryNotifier.new,
);

/// Search query on Customer Search tab.
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

/// Category filter on Customer Search tab ('All' by default).
class SearchCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'All';

  void setCategory(String category) => state = category;
}

final searchCategoryProvider =
    NotifierProvider<SearchCategoryNotifier, String>(
  SearchCategoryNotifier.new,
);

/// Stream/Future provider for active customer-visible food offers.
final activeOffersProvider = FutureProvider<List<FoodOffer>>((ref) async {
  final repository = ref.watch(customerOfferRepositoryProvider);
  final category = ref.watch(selectedCategoryProvider);
  return repository.getActiveOffers(
    category: category == 'All' ? null : category,
  );
});

/// Search results provider for Customer Search screen (Section 24).
final searchResultsProvider = FutureProvider<List<FoodOffer>>((ref) async {
  final repository = ref.watch(customerOfferRepositoryProvider);
  final query = ref.watch(searchQueryProvider);
  final category = ref.watch(searchCategoryProvider);
  return repository.getActiveOffers(
    searchQuery: query,
    category: category == 'All' ? null : category,
  );
});

/// Single offer details provider.
final offerDetailsProvider =
    FutureProvider.family<FoodOffer?, String>((ref, id) async {
  final repository = ref.watch(customerOfferRepositoryProvider);
  return repository.getOfferById(id);
});

/// Restaurant details provider.
final restaurantDetailsProvider =
    FutureProvider.family<Restaurant?, String>((ref, id) async {
  final repository = ref.watch(customerOfferRepositoryProvider);
  return repository.getRestaurantById(id);
});

/// Restaurant's active offers provider.
final restaurantActiveOffersProvider =
    FutureProvider.family<List<FoodOffer>, String>((ref, restaurantId) async {
  final repository = ref.watch(customerOfferRepositoryProvider);
  return repository.getRestaurantOffers(restaurantId);
});
