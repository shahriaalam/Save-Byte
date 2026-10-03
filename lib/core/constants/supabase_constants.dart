/// Supabase configuration constants for SaveBite.
///
/// Security Notice (Section 50):
/// NEVER store or expose the service-role key in the Flutter application.
/// Only use the public/anonymous key here.
abstract final class SupabaseConstants {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://fbzftgpgwdqcdlxnvlfc.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZiemZ0Z3Bnd2RxY2RseG52bGZjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA3NDI1MDMsImV4cCI6MjEwNjMxODUwM30.nZoe660G22yHVDKSCz5FNtzsbmvCeJTMMpi-J-LAZr4',
  );

  // Database tables (Section 9)
  static const String tableProfiles = 'profiles';
  static const String tableRestaurants = 'restaurants';
  static const String tableOffers = 'offers';
  static const String tablePromoBanners = 'promo_banners';

  // Storage buckets (Section 51)
  static const String bucketAvatars = 'avatars';
  static const String bucketRestaurantImages = 'restaurant-images';
  static const String bucketOfferImages = 'offer-images';
  static const String bucketPromoBanners = 'promo-banners';
}
