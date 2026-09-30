/// Route paths for GoRouter navigation across SaveBite V1.
abstract final class AppRoutes {
  static const String splash = '/';

  // Auth routes (Milestone 2)
  static const String login = '/login';
  static const String register = '/register';

  // Customer routes (Milestone 5)
  static const String customerHome = '/customer';
  static const String customerSearch = '/customer/search';
  static const String customerOfferDetails = '/customer/offers/:id';
  static const String customerRestaurantDetails = '/customer/restaurants/:id';
  static const String customerProfile = '/customer/profile';

  // Restaurant routes (Milestone 4)
  static const String restaurantDashboard = '/restaurant';
  static const String restaurantOffers = '/restaurant/offers';
  static const String restaurantCreateOffer = '/restaurant/offers/create';
  static const String restaurantEditOffer = '/restaurant/offers/:id/edit';
  static const String restaurantProfile = '/restaurant/profile';

  // Admin routes (Milestone 6)
  static const String adminDashboard = '/admin';
  static const String adminUsers = '/admin/users';
  static const String adminRestaurants = '/admin/restaurants';
  static const String adminOffers = '/admin/offers';
}
