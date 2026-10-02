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

/// Division filter on Customer Search tab ('All' by default).
class SearchDivisionNotifier extends Notifier<String> {
  @override
  String build() => 'All';

  void setDivision(String division) => state = division;
}

final searchDivisionProvider =
    NotifierProvider<SearchDivisionNotifier, String>(
  SearchDivisionNotifier.new,
);

/// Area filter on Customer Search tab ('All' by default).
class SearchAreaNotifier extends Notifier<String> {
  @override
  String build() => 'All';

  void setArea(String area) => state = area;
}

final searchAreaProvider =
    NotifierProvider<SearchAreaNotifier, String>(
  SearchAreaNotifier.new,
);

/// Area filter on Customer Home tab ('All' by default for Dhaka).
class HomeAreaNotifier extends Notifier<String> {
  @override
  String build() => 'All';

  void setArea(String area) => state = area;
}

final homeAreaProvider = NotifierProvider<HomeAreaNotifier, String>(
  HomeAreaNotifier.new,
);

/// Stream/Future provider for active customer-visible food offers.
/// Sorted by discount percentage in descending order (highest discount first).
final activeOffersProvider = FutureProvider<List<FoodOffer>>((ref) async {
  final repository = ref.watch(customerOfferRepositoryProvider);
  final category = ref.watch(selectedCategoryProvider);
  final area = ref.watch(homeAreaProvider);
  final offers = await repository.getActiveOffers(
    category: category == 'All' ? null : category,
    division: 'Dhaka',
    area: area == 'All' ? null : area,
  );
  // Sort in descending order of discount % (most % discount is number one)
  offers.sort((a, b) => b.discountPercentage.compareTo(a.discountPercentage));
  return offers;
});

/// Nearby offers provider for customer home ("Offers Near You") from restaurants in the area.
/// Filters by both selectedCategory and homeArea.
final nearbyOffersProvider = FutureProvider<List<FoodOffer>>((ref) async {
  final repository = ref.watch(customerOfferRepositoryProvider);
  final category = ref.watch(selectedCategoryProvider);
  final area = ref.watch(homeAreaProvider);
  final offers = await repository.getActiveOffers(
    category: category == 'All' ? null : category,
    division: 'Dhaka',
    area: area == 'All' ? null : area,
  );
  // Ranked by highest discount percentage first
  offers.sort((a, b) => b.discountPercentage.compareTo(a.discountPercentage));
  return offers;
});

/// Hot deals provider for customer role: offers with 45% or higher discount
/// located in the client's area (or all Dhaka when 'All').
final hotDealsProvider = FutureProvider<List<FoodOffer>>((ref) async {
  final repository = ref.watch(customerOfferRepositoryProvider);
  final area = ref.watch(homeAreaProvider);
  final category = ref.watch(selectedCategoryProvider);
  final offers = await repository.getActiveOffers(
    category: category == 'All' ? null : category,
    division: 'Dhaka',
    area: area == 'All' ? null : area,
  );
  // Filter for deals that are 45% or more discounted
  final hotDeals = offers.where((offer) => offer.discountPercentage >= 45).toList();
  // Rank highest discount % first
  hotDeals.sort((a, b) => b.discountPercentage.compareTo(a.discountPercentage));
  return hotDeals;
});

/// Hot deals provider across all Dhaka areas for recommendations/fallback.
final allDhakaHotDealsProvider = FutureProvider<List<FoodOffer>>((ref) async {
  final repository = ref.watch(customerOfferRepositoryProvider);
  final category = ref.watch(selectedCategoryProvider);
  final offers = await repository.getActiveOffers(
    category: category == 'All' ? null : category,
    division: 'Dhaka',
  );
  final hotDeals = offers.where((offer) => offer.discountPercentage >= 45).toList();
  hotDeals.sort((a, b) => b.discountPercentage.compareTo(a.discountPercentage));
  return hotDeals;
});

/// Nearby restaurants provider for customer home ("Shops Near You") that have active surplus listings right now.
/// Filters by both selectedCategory and homeArea to only display shops offering the selected category.
final activeRestaurantsProvider = FutureProvider<List<Restaurant>>((ref) async {
  final repository = ref.watch(customerOfferRepositoryProvider);
  final category = ref.watch(selectedCategoryProvider);
  final area = ref.watch(homeAreaProvider);
  return repository.getActiveRestaurants(
    category: category == 'All' ? null : category,
    division: 'Dhaka',
    area: area == 'All' ? null : area,
  );
});

/// Provider for the bottom "All Restaurants" section on Customer Home.
/// Does NOT filter by category ("and dont filter all restaurants portion. bcz the portion is set to see all the offers"),
/// only filters by the selected/detected home area, sorted by highest discount % first.
final allHomeOffersProvider = FutureProvider<List<FoodOffer>>((ref) async {
  final repository = ref.watch(customerOfferRepositoryProvider);
  final area = ref.watch(homeAreaProvider);
  final offers = await repository.getActiveOffers(
    division: 'Dhaka',
    area: area == 'All' ? null : area,
  );
  // Ranked by highest discount percentage first
  offers.sort((a, b) => b.discountPercentage.compareTo(a.discountPercentage));
  return offers;
});

/// Search results provider for Customer Search screen with division and area filters (Section 24).
final searchResultsProvider = FutureProvider<List<FoodOffer>>((ref) async {
  final repository = ref.watch(customerOfferRepositoryProvider);
  final query = ref.watch(searchQueryProvider);
  final category = ref.watch(searchCategoryProvider);
  final division = ref.watch(searchDivisionProvider);
  final area = ref.watch(searchAreaProvider);

  return repository.getActiveOffers(
    searchQuery: query,
    category: category == 'All' ? null : category,
    division: division == 'All' ? null : division,
    area: area == 'All' ? null : area,
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
