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
      imageUrl: 'assets/images/biryani_logo.jpg',
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
      imageUrl: 'assets/images/burger_hub_logo.jpg',
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
      imageUrl: 'assets/images/woodfire_crust_logo.jpg',
    ),
    Restaurant(
      id: 'res-4',
      ownerId: 'owner-4',
      name: 'Sweet Treats Bakery',
      description: 'Fresh evening bakery items, croissants, rolls and desserts.',
      phone: '01611778899',
      address: 'Mirpur DOHS, Dhaka',
      division: 'Dhaka',
      area: 'Mirpur',
      cuisineType: 'Bakery',
      openingTime: '08:00 AM',
      closingTime: '10:00 PM',
      status: AppConstants.statusApproved,
      imageUrl: 'assets/images/bakery_logo.jpg',
    ),
    // Additional Dhanmondi restaurants
    Restaurant(
      id: 'res-5',
      ownerId: 'owner-5',
      name: 'Takeout Burgers Dhanmondi',
      description: 'Gourmet handcrafted burgers, crispy fries and fresh shakes.',
      phone: '01711334455',
      address: 'Satmasjid Road, Dhanmondi, Dhaka',
      division: 'Dhaka',
      area: 'Dhanmondi',
      cuisineType: 'Burger',
      openingTime: '12:00 PM',
      closingTime: '11:00 PM',
      status: AppConstants.statusApproved,
      imageUrl: 'assets/images/burger_hub_logo.jpg',
    ),
    Restaurant(
      id: 'res-6',
      ownerId: 'owner-6',
      name: 'Pizza Guy Dhanmondi',
      description: 'Wood-fired artisan pizzas with premium melted mozzarella.',
      phone: '01711889900',
      address: 'Road 27, Dhanmondi, Dhaka',
      division: 'Dhaka',
      area: 'Dhanmondi',
      cuisineType: 'Pizza',
      openingTime: '01:00 PM',
      closingTime: '11:00 PM',
      status: AppConstants.statusApproved,
      imageUrl: 'assets/images/woodfire_crust_logo.jpg',
    ),
    Restaurant(
      id: 'res-7',
      ownerId: 'owner-7',
      name: 'Dhanmondi Bakehouse',
      description: 'Artisanal cakes, cookies, and evening fresh pastries.',
      phone: '01711556677',
      address: 'Road 8/A, Dhanmondi, Dhaka',
      division: 'Dhaka',
      area: 'Dhanmondi',
      cuisineType: 'Bakery',
      openingTime: '09:00 AM',
      closingTime: '10:00 PM',
      status: AppConstants.statusApproved,
      imageUrl: 'assets/images/bakery_logo.jpg',
    ),
    // Banasree restaurants
    Restaurant(
      id: 'res-8',
      ownerId: 'owner-8',
      name: 'Banasree Biryani & Kabab',
      description: 'Traditional mutton kacchi, aromatic beef tehari and seekh kebabs.',
      phone: '01811223344',
      address: 'Main Road, Block B, Banasree, Dhaka',
      division: 'Dhaka',
      area: 'Banasree',
      cuisineType: 'Bengali',
      openingTime: '11:30 AM',
      closingTime: '11:00 PM',
      status: AppConstants.statusApproved,
      imageUrl: 'assets/images/biryani_logo.jpg',
    ),
    Restaurant(
      id: 'res-9',
      ownerId: 'owner-9',
      name: 'Banasree Burger Hub',
      description: 'Handcrafted gourmet beef burgers, crispy wings and shakes.',
      phone: '01811556677',
      address: 'Block C, Banasree, Dhaka',
      division: 'Dhaka',
      area: 'Banasree',
      cuisineType: 'Burger',
      openingTime: '12:00 PM',
      closingTime: '11:00 PM',
      status: AppConstants.statusApproved,
      imageUrl: 'assets/images/burger_hub_logo.jpg',
    ),
    Restaurant(
      id: 'res-10',
      ownerId: 'owner-10',
      name: 'Woodfire Crust Banasree',
      description: 'Hot oven baked classic Italian pizzas with rich cheese blend.',
      phone: '01811889900',
      address: 'Block E, Banasree, Dhaka',
      division: 'Dhaka',
      area: 'Banasree',
      cuisineType: 'Pizza',
      openingTime: '01:00 PM',
      closingTime: '11:30 PM',
      status: AppConstants.statusApproved,
      imageUrl: 'assets/images/woodfire_crust_logo.jpg',
    ),
    Restaurant(
      id: 'res-11',
      ownerId: 'owner-11',
      name: 'Hot & Crispy Banasree',
      description: 'Golden fried chicken buckets, chicken tenders and dips.',
      phone: '01811443322',
      address: 'Block D, Banasree, Dhaka',
      division: 'Dhaka',
      area: 'Banasree',
      cuisineType: 'Fast Food',
      openingTime: '12:00 PM',
      closingTime: '11:00 PM',
      status: AppConstants.statusApproved,
      imageUrl: 'assets/images/hot_crispy_logo.jpg',
    ),
    Restaurant(
      id: 'res-12',
      ownerId: 'owner-12',
      name: 'Crust & Crumb Bakery Banasree',
      description: 'Evening fresh pastries, red velvet cake slices and croissants.',
      phone: '01811776655',
      address: 'Block F, Banasree, Dhaka',
      division: 'Dhaka',
      area: 'Banasree',
      cuisineType: 'Bakery',
      openingTime: '08:00 AM',
      closingTime: '10:30 PM',
      status: AppConstants.statusApproved,
      imageUrl: 'assets/images/bakery_logo.jpg',
    ),
    Restaurant(
      id: 'res-blue-bell',
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
      imageUrl: 'assets/images/blue_bell_logo.jpg',
      isPremium: true,
      subscriptionPlan: 'gold',
      boostCredits: 5,
      hasActiveBanner: true,
      activeBannerId: 'banner_blue_bell',
    ),
  ];

  static final List<FoodOffer> _seedOffers = [
    FoodOffer(
      id: 'offer-bb-1',
      restaurantId: 'res-blue-bell',
      restaurantName: 'Blue Bell Café',
      restaurantAddress: 'House 14, Road 4, Block D, Banasree, Dhaka',
      division: 'Dhaka',
      area: 'Banasree',
      title: 'Tuscan Slow-Baked Lasagna',
      description:
          'Layers of fresh egg pasta, slow-simmered bolognese ragù, creamy béchamel, and melted parmesan. Packaged fresh for dinner discovery.',
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
      restaurantId: 'res-blue-bell',
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
      restaurantId: 'res-blue-bell',
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
      restaurantId: 'res-blue-bell',
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
      restaurantId: 'res-blue-bell',
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
    // Dhanmondi Offers
    FoodOffer(
      id: 'offer-7',
      restaurantId: 'res-5',
      restaurantName: 'Takeout Burgers Dhanmondi',
      restaurantAddress: 'Satmasjid Road, Dhanmondi, Dhaka',
      division: 'Dhaka',
      area: 'Dhanmondi',
      title: 'Smoked BBQ Beef Burger',
      description: 'Charbroiled beef patty, smoked bacon jam, aged cheddar, and house relish.',
      category: 'Burger',
      originalPrice: 260,
      discountedPrice: 130,
      quantity: 6,
      availableFrom: DateTime.now().subtract(const Duration(minutes: 30)),
      availableUntil: DateTime.now().add(const Duration(hours: 3)),
      imageUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600',
      isActive: true,
      adminBlocked: false,
    ),
    FoodOffer(
      id: 'offer-8',
      restaurantId: 'res-6',
      restaurantName: 'Pizza Guy Dhanmondi',
      restaurantAddress: 'Road 27, Dhanmondi, Dhaka',
      division: 'Dhaka',
      area: 'Dhanmondi',
      title: 'BBQ Chicken Pizza (12 inch)',
      description: 'Loaded with smoky BBQ chicken chunks, caramelized onions and mozzarella.',
      category: 'Pizza',
      originalPrice: 600,
      discountedPrice: 300,
      quantity: 4,
      availableFrom: DateTime.now().subtract(const Duration(minutes: 40)),
      availableUntil: DateTime.now().add(const Duration(hours: 3, minutes: 30)),
      imageUrl: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=600',
      isActive: true,
      adminBlocked: false,
    ),
    FoodOffer(
      id: 'offer-9',
      restaurantId: 'res-7',
      restaurantName: 'Dhanmondi Bakehouse',
      restaurantAddress: 'Road 8/A, Dhanmondi, Dhaka',
      division: 'Dhaka',
      area: 'Dhanmondi',
      title: 'Chocolate Fudge Brownie Box (4 pcs)',
      description: 'Rich dark Belgian chocolate brownies baked freshly this evening.',
      category: 'Bakery',
      originalPrice: 300,
      discountedPrice: 150,
      quantity: 5,
      availableFrom: DateTime.now().subtract(const Duration(minutes: 25)),
      availableUntil: DateTime.now().add(const Duration(hours: 2, minutes: 30)),
      imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=600',
      isActive: true,
      adminBlocked: false,
    ),
    // Banasree Offers
    FoodOffer(
      id: 'offer-10',
      restaurantId: 'res-8',
      restaurantName: 'Banasree Biryani & Kabab',
      restaurantAddress: 'Main Road, Block B, Banasree, Dhaka',
      division: 'Dhaka',
      area: 'Banasree',
      title: 'Special Mutton Kacchi Biryani',
      description: 'Fragrant basmati rice layered with succulent tender mutton and potatoes.',
      category: 'Rice',
      originalPrice: 340,
      discountedPrice: 170,
      quantity: 7,
      availableFrom: DateTime.now().subtract(const Duration(hours: 1)),
      availableUntil: DateTime.now().add(const Duration(hours: 3)),
      imageUrl: 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=600',
      isActive: true,
      adminBlocked: false,
    ),
    FoodOffer(
      id: 'offer-11',
      restaurantId: 'res-9',
      restaurantName: 'Banasree Burger Hub',
      restaurantAddress: 'Block C, Banasree, Dhaka',
      division: 'Dhaka',
      area: 'Banasree',
      title: 'Double Cheese Crunch Burger',
      description: 'Crispy fried chicken fillet topped with double melted cheddar and spicy mayo.',
      category: 'Burger',
      originalPrice: 240,
      discountedPrice: 120,
      quantity: 6,
      availableFrom: DateTime.now().subtract(const Duration(minutes: 35)),
      availableUntil: DateTime.now().add(const Duration(hours: 3)),
      imageUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600',
      isActive: true,
      adminBlocked: false,
    ),
    FoodOffer(
      id: 'offer-12',
      restaurantId: 'res-10',
      restaurantName: 'Woodfire Crust Banasree',
      restaurantAddress: 'Block E, Banasree, Dhaka',
      division: 'Dhaka',
      area: 'Banasree',
      title: 'Pepperoni Feast Pizza (12 inch)',
      description: 'Loaded with spicy beef pepperoni slices and gooey mozzarella cheese.',
      category: 'Pizza',
      originalPrice: 640,
      discountedPrice: 320,
      quantity: 5,
      availableFrom: DateTime.now().subtract(const Duration(minutes: 50)),
      availableUntil: DateTime.now().add(const Duration(hours: 4)),
      imageUrl: 'https://images.unsplash.com/photo-1604382355076-af4b0eb60143?w=600',
      isActive: true,
      adminBlocked: false,
    ),
    FoodOffer(
      id: 'offer-13',
      restaurantId: 'res-11',
      restaurantName: 'Hot & Crispy Banasree',
      restaurantAddress: 'Block D, Banasree, Dhaka',
      division: 'Dhaka',
      area: 'Banasree',
      title: 'Crispy Fried Chicken Bucket (6 pcs)',
      description: 'Hot, spicy, and extra-crispy chicken pieces with garlic mayo dips.',
      category: 'Fast Food',
      originalPrice: 380,
      discountedPrice: 190,
      quantity: 8,
      availableFrom: DateTime.now().subtract(const Duration(minutes: 15)),
      availableUntil: DateTime.now().add(const Duration(hours: 3)),
      imageUrl: 'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=600',
      isActive: true,
      adminBlocked: false,
    ),
    FoodOffer(
      id: 'offer-14',
      restaurantId: 'res-12',
      restaurantName: 'Crust & Crumb Bakery Banasree',
      restaurantAddress: 'Block F, Banasree, Dhaka',
      division: 'Dhaka',
      area: 'Banasree',
      title: 'Red Velvet Pastry Pack (4 pcs)',
      description: 'Soft and moist red velvet layers topped with velvety cream cheese frosting.',
      category: 'Bakery',
      originalPrice: 280,
      discountedPrice: 140,
      quantity: 6,
      availableFrom: DateTime.now().subtract(const Duration(minutes: 40)),
      availableUntil: DateTime.now().add(const Duration(hours: 2, minutes: 30)),
      imageUrl: 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=600',
      isActive: true,
      adminBlocked: false,
    ),
  ];

  /// Checks whether an offer matches the category filter,
  /// supporting direct category matching and visual category synonyms (e.g. Biryani -> Rice/Biryani).
  static bool matchesCategory(FoodOffer offer, String category) {
    final cat = category.toLowerCase().trim();
    if (cat.isEmpty || cat == 'all') return true;

    final offerCat = offer.category.toLowerCase().trim();
    final offerTitle = offer.title.toLowerCase().trim();

    // Direct match on category
    if (offerCat == cat) return true;

    // Cross-category semantic synonyms for visual filter buttons
    if (cat == 'biryani') {
      return offerCat == 'rice' ||
          offerTitle.contains('biryani') ||
          offerTitle.contains('tehari') ||
          offerTitle.contains('pulao');
    }

    if (cat == 'rice') {
      return offerCat == 'rice';
    }

    if (cat == 'burger') {
      return offerCat == 'burger' || offerTitle.contains('burger');
    }

    if (cat == 'pizza') {
      return offerCat == 'pizza' || offerTitle.contains('pizza');
    }

    if (cat == 'chicken') {
      return offerCat == 'chicken' ||
          offerCat == 'fast food' ||
          offerTitle.contains('chicken') ||
          offerTitle.contains('kebab') ||
          offerTitle.contains('broast') ||
          offerTitle.contains('wings');
    }

    if (cat == 'bakery') {
      return offerCat == 'bakery' ||
          offerCat == 'dessert' ||
          offerTitle.contains('croissant') ||
          offerTitle.contains('cake') ||
          offerTitle.contains('pastry') ||
          offerTitle.contains('bread') ||
          offerTitle.contains('bakery') ||
          offerTitle.contains('brownie');
    }

    if (cat == 'healthy' || cat == 'vegetarian') {
      return offerCat == 'vegetarian' ||
          offerTitle.contains('salad') ||
          offerTitle.contains('healthy') ||
          offerTitle.contains('veg');
    }

    if (cat == 'drinks' || cat == 'beverages') {
      return offerCat == 'beverages' ||
          offerCat == 'drinks' ||
          offerTitle.contains('juice') ||
          offerTitle.contains('shake') ||
          offerTitle.contains('coffee') ||
          offerTitle.contains('tea');
    }

    return offerCat.contains(cat) || offerTitle.contains(cat);
  }

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
            .where((offer) {
              if (!offer.isVisibleToCustomer()) return false;
              if (category != null && category.isNotEmpty && category != 'All') {
                if (!matchesCategory(offer, category)) return false;
              }
              return true;
            })
            .toList();

        if (offers.isNotEmpty) return offers;
      } catch (_) {
        // Fallback to seed offers for demonstration/development
      }
    }

    // Filter seed offers based on parameters
    final results = _seedOffers.where((offer) {
      if (!offer.isVisibleToCustomer()) return false;
      if (category != null && category.isNotEmpty && category != 'All') {
        if (!matchesCategory(offer, category)) return false;
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

    // Sort boosted offers to the top
    results.sort((a, b) {
      if (a.isBoosted && !b.isBoosted) return -1;
      if (!a.isBoosted && b.isBoosted) return 1;
      return 0;
    });

    return results;
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

  /// Retrieves active restaurants that have available food offers right now,
  /// filtered by category, division and area. Only restaurants with active offers matching
  /// the selected category (if provided) will be returned.
  Future<List<Restaurant>> getActiveRestaurants({
    String? category,
    String? division,
    String? area,
  }) async {
    final activeOffers = await getActiveOffers(
      category: category,
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
    String? fullName,
    String? firstName,
    String? lastName,
    String? gender,
    String? phone,
    String? address,
    String? city,
    String? dateOfBirth,
  }) async {
    try {
      final resolvedFullName = (fullName != null && fullName.trim().isNotEmpty)
          ? fullName.trim()
          : [firstName, lastName]
              .where((s) => s != null && s.trim().isNotEmpty)
              .join(' ');

      final data = <String, dynamic>{
        if (resolvedFullName.isNotEmpty) 'full_name': resolvedFullName,
        if (firstName != null) 'first_name': firstName.trim(),
        if (lastName != null) 'last_name': lastName.trim(),
        if (gender != null) 'gender': gender.trim(),
        if (phone != null) 'phone': phone.trim(),
        if (address != null) 'address': address.trim(),
        if (city != null) 'city': city.trim(),
        if (dateOfBirth != null) 'date_of_birth': dateOfBirth.trim(),
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

  /// Decreases the available quantity of an offer in the local cache when ordered.
  void decreaseOfferQuantityLocally(String offerId, int quantityToDecrease) {
    final index = _seedOffers.indexWhere((o) => o.id == offerId);
    if (index != -1) {
      final current = _seedOffers[index];
      final newQty = (current.quantity - quantityToDecrease).clamp(0, 9999);
      _seedOffers[index] = current.copyWith(
        quantity: newQty,
        isActive: newQty > 0,
      );
    }
  }
}

