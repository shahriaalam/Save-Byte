/// Global application constants based on SaveBite V1 specification.
abstract final class AppConstants {
  static const String appName = 'SaveBite';
  static const String appTagline = 'Smart Food & Deals Platform';
  static const String currencySymbol = '৳';

  // Role values (Section 10)
  static const String roleCustomer = 'customer';
  static const String roleRestaurant = 'restaurant';
  static const String roleAdmin = 'admin';
  static const String roleHeadAdmin = 'head_admin';
  static const String roleModerator = 'moderator';

  // Restaurant statuses (Section 11)
  static const String statusPending = 'pending';
  static const String statusApproved = 'approved';
  static const String statusRejected = 'rejected';
  static const String statusSuspended = 'suspended';

  // V1 Food Categories (Section 25)
  static const List<String> categories = [
    'Rice',
    'Burger',
    'Pizza',
    'Bakery',
    'Snacks',
    'Drinks',
    'Dessert',
    'Other',
  ];
}
