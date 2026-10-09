import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:save_bite/core/constants/app_constants.dart';
import 'package:save_bite/core/theme/app_theme.dart';
import 'package:save_bite/features/auth/data/auth_repository.dart';
import 'package:save_bite/features/auth/domain/user_profile.dart';
import 'package:save_bite/features/auth/presentation/auth_controller.dart';
import 'package:save_bite/features/restaurant/dashboard/restaurant_dashboard_screen.dart';
import 'package:save_bite/features/restaurant/offers/presentation/create_offer_screen.dart';
import 'package:save_bite/features/restaurant/orders/presentation/restaurant_orders_sheet.dart';
import 'package:save_bite/features/restaurant/presentation/restaurant_controller.dart';
import 'package:save_bite/features/restaurant/profile/restaurant_profile_screen.dart';
import 'package:save_bite/features/shared/data/order_controller.dart';
import 'package:save_bite/features/shared/models/order.dart';
import 'package:save_bite/features/shared/models/restaurant.dart';

import '../helpers/fake_auth_repository.dart';

class FakeCurrentUserNotifier extends CurrentUserNotifier {
  FakeCurrentUserNotifier(this._profile);
  final UserProfile? _profile;

  @override
  UserProfile? build() => _profile;
}

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _MockHttpClient();
}

class _MockHttpClient implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockHttpClientResponse implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => _transparentImage.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_transparentImage).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

final _transparentImage = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
];

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  const restaurantUser = UserProfile(
    id: 'owner-1',
    email: 'restaurant@savebite.com',
    role: AppConstants.roleRestaurant,
    fullName: "Rahman's Kitchen",
    phone: '01711223344',
    isActive: true,
  );

  const incompleteRestaurant = Restaurant(
    id: 'res-1',
    ownerId: 'owner-1',
    name: "Rahman's Kitchen",
    phone: '01711223344',
  );

  const completeRestaurant = Restaurant(
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

  Widget createTestWidget(
    Widget child, {
    Restaurant? restaurant = incompleteRestaurant,
    FakeAuthRepository? authRepo,
    bool overrideOffers = true,
  }) {
    return ProviderScope(
      overrides: [
        if (authRepo != null)
          authRepositoryProvider.overrideWithValue(authRepo),
        currentUserProfileProvider.overrideWith(
          () => FakeCurrentUserNotifier(restaurantUser),
        ),
        currentRestaurantProvider.overrideWith((ref) => restaurant),
        if (overrideOffers)
          currentRestaurantOffersProvider.overrideWith((ref) => []),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: child,
      ),
    );
  }

  group('Restaurant Dashboard Screen - Profile Completeness & Posting Protection', () {
    testWidgets('displays incomplete profile banner when restaurant has missing fields', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(
        const RestaurantDashboardScreen(),
        restaurant: incompleteRestaurant,
      ));
      await tester.pumpAndSettle();

      // Profile completeness banner should be visible
      expect(find.textContaining('Profile Incomplete'), findsOneWidget);
      expect(find.text('Fix Now'), findsOneWidget);
    });

    testWidgets('tapping New Post with incomplete profile shows blocking alert dialog', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(
        const RestaurantDashboardScreen(),
        restaurant: incompleteRestaurant,
      ));
      await tester.pumpAndSettle();

      // Tap New Post Quick Access button
      final postButton = find.text('New Post');
      expect(postButton, findsOneWidget);
      await tester.tap(postButton);
      await tester.pumpAndSettle();

      // Verify blocking dialog is shown
      expect(find.text('Complete Profile First'), findsOneWidget);
      expect(
        find.textContaining('Your restaurant cannot place any food posts'),
        findsOneWidget,
      );
      expect(find.widgetWithText(FilledButton, 'Complete Profile'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('shows Profile Complete badge when all fields and photo are provided', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(
        const RestaurantDashboardScreen(),
        restaurant: completeRestaurant,
      ));
      await tester.pumpAndSettle();

      // Profile Complete status badge should be displayed
      expect(find.textContaining('Profile Complete'), findsOneWidget);
      expect(find.textContaining('Profile Incomplete'), findsNothing);
    });
  });

  group('Create Offer Screen - Strict Blocker for Incomplete Profile', () {
    testWidgets('renders blocking screen when restaurant profile is incomplete', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(
        const CreateOfferScreen(),
        restaurant: incompleteRestaurant,
      ));
      await tester.pumpAndSettle();

      // Blocked state should be displayed
      expect(find.text('Complete Your Profile First'), findsOneWidget);
      expect(
        find.textContaining('restaurants cannot place food posts until their profile is completely filled out'),
        findsOneWidget,
      );
      expect(find.text('Complete Restaurant Profile'), findsOneWidget);

      // Offer form fields should NOT be shown
      expect(find.text('Food Offer Title *'), findsNothing);
      expect(find.text('Discount Price (৳) *'), findsNothing);
    });

    testWidgets('renders offer creation form when restaurant profile is complete', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(
        const CreateOfferScreen(),
        restaurant: completeRestaurant,
      ));
      await tester.pumpAndSettle();

      // Form should be rendered
      expect(find.text('New Post'), findsOneWidget);
      expect(find.text('Food Offer Title *'), findsOneWidget);
      expect(find.text('Discount Price (৳) *'), findsOneWidget);
      expect(find.text('Publish Post'), findsOneWidget);
    });

    testWidgets('Quick Fill Sample Offer populates offer form fields', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(
        const CreateOfferScreen(),
        restaurant: completeRestaurant,
      ));
      await tester.pumpAndSettle();

      final quickFillBtn = find.text('Quick Fill Sample Offer');
      expect(quickFillBtn, findsOneWidget);
      await tester.tap(quickFillBtn);
      await tester.pump();

      expect(find.text('Truffle Beef Lasagna (Special Box)'), findsOneWidget);
      expect(find.text('420'), findsOneWidget);
    });
  });

  group('Restaurant Profile Screen', () {
    testWidgets('renders division and area selectors and restaurant fields', (tester) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(
        const RestaurantProfileScreen(),
        restaurant: completeRestaurant,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Restaurant Profile'), findsOneWidget);
      expect(find.text("Rahman's Kitchen"), findsWidgets);
      expect(find.text('Dhaka'), findsWidgets);
      expect(find.text('Dhanmondi'), findsWidgets);
      expect(find.text('Save Restaurant Profile'), findsOneWidget);
    });

    testWidgets('Quick Fill (Blue Bell Café) populates profile fields', (tester) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(
        const RestaurantProfileScreen(),
        restaurant: incompleteRestaurant,
      ));
      await tester.pumpAndSettle();

      final quickFillBtn = find.text('Quick Fill (Blue Bell Café)');
      expect(quickFillBtn, findsOneWidget);
      await tester.tap(quickFillBtn);
      await tester.pump();

      expect(find.text('Blue Bell Café'), findsWidgets);
      expect(find.text('01711234567'), findsOneWidget);
    });
  });

  group('Restaurant Dashboard - Navigation, Admin Offers, Account & Owner Profile', () {
    testWidgets('floating nav bar has Home in the middle: Posts, Offers, Home, Info, Account', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(
        const RestaurantDashboardScreen(),
        restaurant: completeRestaurant,
      ));
      await tester.pumpAndSettle();

      // Check all 5 nav tabs exist by their precise ValueKeys
      expect(find.byKey(const ValueKey('restaurant_nav_Posts')), findsOneWidget);
      expect(find.byKey(const ValueKey('restaurant_nav_Offers')), findsOneWidget);
      expect(find.byKey(const ValueKey('restaurant_nav_Home')), findsOneWidget);
      expect(find.byKey(const ValueKey('restaurant_nav_Info')), findsOneWidget);
      expect(find.byKey(const ValueKey('restaurant_nav_Account')), findsOneWidget);

      // Verify Home is currently selected (rendered on Home view)
      expect(find.text('New Post'), findsOneWidget);
    });

    testWidgets('Offers tab displays Admin Promotional Packages (Banner 2000 tk, Boost 600 tk)', (tester) async {
      tester.view.physicalSize = const Size(400, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(
        const RestaurantDashboardScreen(),
        restaurant: completeRestaurant,
      ));
      await tester.pumpAndSettle();

      // Tap Offers nav tab using key
      await tester.tap(find.byKey(const ValueKey('restaurant_nav_Offers')));
      await tester.pumpAndSettle();

      // Check offers header and packages
      expect(find.text('Offers for you'), findsOneWidget);
      expect(find.text('1 Homepage Hero Banner (24 Hours)'), findsOneWidget);
      expect(find.text('৳2,000'), findsWidgets);
      expect(find.text('Post Boost for 24 Hours'), findsOneWidget);
      expect(find.text('৳600'), findsWidgets);
      expect(find.text('Weekend 48h Surge Boost Pack'), findsOneWidget);
      expect(find.textContaining('Weekly Hero Banner'), findsOneWidget);
    });

    testWidgets('Account tab is organized with Owner Profile, Gold card, and dark red Delete Account button', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(
        const RestaurantDashboardScreen(),
        restaurant: completeRestaurant,
      ));
      await tester.pumpAndSettle();

      // Tap Account nav tab using key
      await tester.tap(find.byKey(const ValueKey('restaurant_nav_Account')));
      await tester.pumpAndSettle();

      // Verify user-style account screen elements
      expect(find.text('Owner Profile'), findsWidgets);
      expect(find.textContaining('SaveBite Gold Merchant'), findsOneWidget);
      expect(find.text('Request Info Update (Admin Review)'), findsOneWidget);
      expect(find.text('Operating Hours & Status'), findsNothing);
      expect(find.text('Surplus Food Safety Rules'), findsNothing);
      expect(find.text('About'), findsOneWidget);
      expect(find.text('Delete Account'), findsOneWidget);
    });

    testWidgets('Owner Profile dialog opens and displays verified owner credentials', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(
        const RestaurantDashboardScreen(),
        restaurant: completeRestaurant,
      ));
      await tester.pumpAndSettle();

      // Navigate to Account tab using key
      await tester.tap(find.byKey(const ValueKey('restaurant_nav_Account')));
      await tester.pumpAndSettle();

      // Tap Owner Profile option
      await tester.tap(find.text('Owner Profile').first);
      await tester.pumpAndSettle();

      // Check owner dialog contents
      expect(find.text("Rahman's Kitchen"), findsWidgets);
      expect(find.textContaining('TRAD/DSCC/019284/2024'), findsOneWidget);
      expect(find.textContaining('cannot be edited directly'), findsOneWidget);
    });

    testWidgets('Request Info Update submits change request and requires Admin Approval', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(
        const RestaurantDashboardScreen(),
        restaurant: completeRestaurant,
      ));
      await tester.pumpAndSettle();

      // Navigate to Account tab using key
      await tester.tap(find.byKey(const ValueKey('restaurant_nav_Account')));
      await tester.pumpAndSettle();

      // Tap Request Info Update
      await tester.tap(find.text('Request Info Update (Admin Review)'));
      await tester.pumpAndSettle();

      // Check dialog
      expect(find.text('Request Info Change'), findsOneWidget);
      expect(find.textContaining('require Admin review'), findsOneWidget);

      // Scroll to ensure Submit button is visible and tap it
      final submitBtn = find.text('Submit Change Request to Admin');
      await tester.ensureVisible(submitBtn);
      await tester.pumpAndSettle();
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Verify pending review banner is shown on Account screen
      expect(find.text('Change Request Pending Admin Review'), findsOneWidget);
      expect(find.text('Demo: Simulate Admin Approval'), findsOneWidget);
    });

    testWidgets('tapping About opens aesthetic SaveBite Partner Portal about sheet', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(
        const RestaurantDashboardScreen(),
        restaurant: completeRestaurant,
      ));
      await tester.pumpAndSettle();

      // Navigate to Account tab using key
      await tester.tap(find.byKey(const ValueKey('restaurant_nav_Account')));
      await tester.pumpAndSettle();

      // Tap About option
      final aboutTile = find.text('About');
      await tester.ensureVisible(aboutTile);
      await tester.pumpAndSettle();
      await tester.tap(aboutTile);
      await tester.pumpAndSettle();

      // Verify rich About sheet contents matching user app
      expect(find.text('SaveBite'), findsWidgets);
      expect(find.text('Smart Food & Deals Platform'), findsOneWidget);
      expect(find.text('Version 1.1.0 (Build 110)'), findsOneWidget);
      expect(find.text('About SaveBite'), findsOneWidget);
      expect(find.text('Our Community Impact'), findsNothing);
      expect(find.text('Key Features'), findsNothing);
      expect(find.text('SaveBite Ltd'), findsOneWidget);
      expect(find.text('Developed by B. M. Shahria Alam'), findsOneWidget);
    });

    testWidgets('Hero Banner button is locked (gray) for normal restaurant and opens locked modal', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final normalRestaurant = completeRestaurant.copyWith(
        isPremium: false,
        subscriptionPlan: null,
        bannerCredits: 0,
        hasActiveBanner: false,
      );

      await tester.pumpWidget(createTestWidget(
        const RestaurantDashboardScreen(),
        restaurant: normalRestaurant,
      ));
      await tester.pumpAndSettle();

      // Verify the LOCKED badge is present on the Hero Banner tile
      expect(find.text('LOCKED'), findsOneWidget);
      expect(find.text('Hero Banner'), findsOneWidget);

      // Tap Hero Banner tile
      await tester.tap(find.text('Hero Banner'));
      await tester.pumpAndSettle();

      // Verify locked modal details
      expect(find.text('Hero Banner Locked'), findsOneWidget);
      expect(find.text('Option 1: Gold Merchant Upgrade'), findsOneWidget);
      expect(find.text('Option 2: Buy Banner Package from Offers'), findsOneWidget);
    });

    testWidgets('Hero Banner is enabled for Gold Merchant and opens Designer with approval workflow', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final goldRestaurant = completeRestaurant.copyWith(
        isPremium: true,
        subscriptionPlan: 'gold',
        bannerCredits: 1,
      );

      await tester.pumpWidget(createTestWidget(
        const RestaurantDashboardScreen(),
        restaurant: goldRestaurant,
      ));
      await tester.pumpAndSettle();

      // Normal LOCKED badge should not be on the Hero Banner button
      expect(find.text('LOCKED'), findsNothing);
      expect(find.text('Hero Banner'), findsOneWidget);

      // Tap Hero Banner
      await tester.tap(find.text('Hero Banner'));
      await tester.pumpAndSettle();

      // Verify Designer elements
      expect(find.text('Homepage Hero Banner'), findsOneWidget);
      expect(find.text('LIVE CUSTOMER HOMEPAGE PREVIEW'), findsOneWidget);
      expect(find.text('1. Headline'), findsOneWidget);
      expect(find.text('2. Description'), findsOneWidget);
      expect(find.text('4. Banner Design (Image)'), findsOneWidget);
      expect(find.text('Submit Banner for Admin Approval'), findsOneWidget);
    });

    testWidgets('Tapping notification bell opens Partner Notifications sheet', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(
        const RestaurantDashboardScreen(),
        restaurant: completeRestaurant,
      ));
      await tester.pumpAndSettle();

      // Tap notification bell in header
      final bellFinder = find.byIcon(Icons.notifications_outlined);
      expect(bellFinder, findsOneWidget);
      await tester.tap(bellFinder);
      await tester.pumpAndSettle();

      // Verify Partner Notifications sheet opens
      expect(find.text('Partner Notifications'), findsOneWidget);
    });

    testWidgets(
      'Restaurant Account Deletion requires warning confirmation and email OTP verification',
      (tester) async {
        tester.view.physicalSize = const Size(400, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final fakeRepo = FakeAuthRepository(initialProfile: restaurantUser);

        await tester.pumpWidget(createTestWidget(
          const RestaurantDashboardScreen(),
          restaurant: completeRestaurant,
          authRepo: fakeRepo,
        ));
        await tester.pumpAndSettle();

        // 1. Switch to Account Tab
        final accountTabFinder =
            find.byKey(const ValueKey('restaurant_nav_Account'));
        expect(accountTabFinder, findsOneWidget);
        await tester.tap(accountTabFinder);
        await tester.pumpAndSettle();

        // 2. Scroll to Delete Account button and tap it
        final deleteButton = find.widgetWithText(ElevatedButton, 'Delete Account');
        expect(deleteButton, findsOneWidget);
        await tester.ensureVisible(deleteButton);
        await tester.tap(deleteButton);
        await tester.pumpAndSettle();

        // 3. Confirm Delete Account dialog is displayed
        expect(find.text('Permanently Delete'), findsOneWidget);
        expect(
          find.textContaining('An OTP verification code will be sent to your registered email'),
          findsOneWidget,
        );

        // 4. Tap Permanently Delete in confirmation dialog
        await tester.tap(find.widgetWithText(FilledButton, 'Permanently Delete'));
        await tester.pumpAndSettle();

        // 5. EmailOtpVerificationSheet appears for deletion
        expect(find.text('Confirm Account Deletion'), findsOneWidget);
        final otpField = find.byKey(const Key('otp_input_field'));
        if (otpField.evaluate().isNotEmpty) {
          await tester.enterText(otpField, '123456');
          await tester.pumpAndSettle();
        } else if (find.text('Verify & Delete Account').evaluate().isNotEmpty) {
          await tester.tap(find.text('Verify & Delete Account'));
          await tester.pumpAndSettle();
        }

        // 6. Verify account deletion was executed
        expect(fakeRepo.deleteAccountCalled, isTrue);
        expect(
          find.text('Your restaurant account has been permanently deleted.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Café Intelligence tab renders modern KPI dashboard and opens Top Sellers Bottom Sheet',
      (tester) async {
        tester.view.physicalSize = const Size(400, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createTestWidget(
          const RestaurantDashboardScreen(),
          restaurant: completeRestaurant,
        ));
        await tester.pumpAndSettle();

        // 1. Navigate to Info tab using key
        final infoTabFinder = find.byKey(const ValueKey('restaurant_nav_Info'));
        expect(infoTabFinder, findsOneWidget);
        await tester.tap(infoTabFinder);
        await tester.pumpAndSettle();

        // 2. Verify modern ambient header and title
        expect(find.text('Café Intelligence & Info'), findsOneWidget);
        expect(find.text('Live'), findsOneWidget);
        expect(find.text('This Week'), findsOneWidget);

        // 3. Verify core metrics dashboard
        expect(find.text('৳96,450'), findsOneWidget);
        expect(find.text('459'), findsOneWidget);
        expect(find.text('Running on Boost'), findsOneWidget);
        expect(find.text('Total Active Posts'), findsOneWidget);
        expect(find.text('Favorited Café'), findsOneWidget);
        expect(find.text('Active Subscriptions'), findsOneWidget);
        expect(find.text('312 Foodies'), findsOneWidget);

        // 4. Verify Top Selling Product preview card on page
        expect(find.text('Top Selling Dishes'), findsOneWidget);
        expect(find.text('Belgium Dark Chocolate Pastry'), findsOneWidget);
        expect(find.text('Open Full Top Sellers Leaderboard'), findsOneWidget);

        // 5. Tap Open Full Top Sellers Leaderboard to trigger Bottom Sheet
        final openLeaderboardBtn = find.text('Open Full Top Sellers Leaderboard');
        await tester.ensureVisible(openLeaderboardBtn);
        await tester.tap(openLeaderboardBtn);
        await tester.pumpAndSettle();

        // 6. Verify Top Sellers Bottom Sheet opened with ranked dishes and filters
        expect(find.text('Ranked by lifetime orders & 5-star customer ratings'), findsOneWidget);
        expect(find.text('Bakery & Dessert'), findsWidgets);
        expect(find.text('Hazelnut Cappuccino & Croissant'), findsOneWidget);
        expect(find.text('Blue Bell Club Chicken Sandwich'), findsOneWidget);
        expect(find.text('Truffle Beef Lasagna (Special Box)'), findsOneWidget);
        expect(find.text('Artisan Garlic Sourdough Loaf'), findsOneWidget);
        expect(find.text('Post for Top Items'), findsOneWidget);

        // 7. Close bottom sheet
        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();

        // 8. Verify Neighborhood Reach and Peak Ordering window are present on page
        expect(find.textContaining('Neighborhood Reach'), findsOneWidget);
        expect(find.textContaining('Peak Ordering'), findsOneWidget);
      },
    );

    testWidgets(
      'Posts tab allows editing post details, adjusting available quantity, and marking post as Done with confirmation popup updating dashboard',
      (tester) async {
        tester.view.physicalSize = const Size(400, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createTestWidget(
          const RestaurantDashboardScreen(),
          restaurant: completeRestaurant,
          overrideOffers: false,
        ));
        await tester.pumpAndSettle();

        // 1. Navigate to Posts tab
        final postsTabFinder =
            find.byKey(const ValueKey('restaurant_nav_Posts'));
        expect(postsTabFinder, findsOneWidget);
        await tester.tap(postsTabFinder);
        await tester.pumpAndSettle();

        // 2. Verify filter chips include All, Active, Done, Boosted
        expect(find.textContaining('All ('), findsOneWidget);
        expect(find.textContaining('Active ('), findsOneWidget);
        expect(find.textContaining('Done ('), findsOneWidget);
        expect(find.textContaining('Boosted 🔥 ('), findsOneWidget);

        // 3. Verify stock counter controls are rendered
        expect(find.byIcon(Icons.remove), findsWidgets);
        expect(find.byIcon(Icons.add), findsWidgets);
        expect(find.text('6 available'), findsOneWidget);

        // 4. Tap '-' to sell 1 portion
        await tester.tap(find.byIcon(Icons.remove).first);
        await tester.pumpAndSettle();

        // 5. Verify quantity decreased to 5 available
        expect(find.text('5 available'), findsOneWidget);

        // 6. Test Edit Post sheet
        final editBtn = find.byTooltip('Edit Post').first;
        await tester.tap(editBtn);
        await tester.pumpAndSettle();

        expect(find.text('Edit Food Post'), findsOneWidget);
        expect(find.text('Save Changes'), findsOneWidget);

        // Close edit sheet
        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();

        // 7. Test Mark as Done button
        final doneBtn = find.widgetWithText(InkWell, 'Done').first;
        await tester.tap(doneBtn);
        await tester.pumpAndSettle();

        // 8. Verify confirmation popup appears with exact value details
        expect(find.text('Mark Post as Done?'), findsOneWidget);
        expect(find.text('Completed Portions'), findsOneWidget);
        expect(find.text('Value Added to Dashboard'), findsOneWidget);
        expect(find.text('Confirm & Mark Done'), findsOneWidget);

        // 9. Confirm Done
        await tester.tap(find.text('Confirm & Mark Done'));
        await tester.pumpAndSettle();

        // 10. Verify post status changed to Completed
        expect(find.text('Completed'), findsWidgets);

        // 11. Switch to Info tab and verify dashboard numbers increased
        ScaffoldMessenger.of(tester.element(find.byType(Scaffold).first))
            .clearSnackBars();
        await tester.pumpAndSettle();

        final infoTabFinder = find.byKey(const ValueKey('restaurant_nav_Info'));
        await tester.tap(infoTabFinder);
        await tester.pumpAndSettle();

        // Verify the value was added to the dashboard (greater than base ৳96,450)
        expect(find.text('৳96,450'), findsNothing);
        expect(find.text('Portions Sold'), findsOneWidget);
      },
    );
  });

  group('Restaurant Orders Sheet - Pickup Flow, Green State and Done Button', () {
    final confirmedOrder = Order(
      id: 'ord-101',
      orderNumber: 'SB-100101',
      customerId: 'cust-1',
      customerName: 'Rahim Ahmed',
      customerPhone: '01700112233',
      restaurantId: 'res-1',
      restaurantName: "Rahman's Kitchen",
      restaurantAddress: 'Dhanmondi, Dhaka',
      title: 'Venetian Espresso Tiramisu',
      category: 'Dessert',
      quantity: 1,
      unitPrice: 240,
      originalUnitPrice: 400,
      totalPrice: 240,
      totalSavings: 160,
      pickupTime: 'Today at 10:43 AM',
      pickupCode: '4115',
      paymentMethod: 'bKash',
      paymentStatus: 'paid',
      status: 'confirmed',
      createdAt: DateTime.now(),
    );

    final readyOrder = confirmedOrder.copyWith(
      status: 'ready_for_pickup',
    );

    testWidgets('renders active pickups and "Mark Ready for Pickup" button for confirmed order', (tester) async {
      tester.view.physicalSize = const Size(420, 950);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            restaurantOrdersProvider('res-1').overrideWith(
              (ref) => [confirmedOrder],
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: RestaurantOrdersSheet(restaurantId: 'res-1'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Takeaway Pickups & Orders'), findsOneWidget);
      expect(find.text('Active Pickups (1)'), findsOneWidget);
      expect(find.text('Venetian Espresso Tiramisu'), findsOneWidget);
      expect(find.text('Rahim Ahmed'), findsOneWidget);
      expect(find.text('Mark Ready for Pickup'), findsOneWidget);
    });

    testWidgets('ready_for_pickup order renders green card, "Mark as Picked Up" and "Done" button', (tester) async {
      tester.view.physicalSize = const Size(420, 950);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            restaurantOrdersProvider('res-1').overrideWith(
              (ref) => [readyOrder],
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: RestaurantOrdersSheet(restaurantId: 'res-1'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Card is in ready state:
      expect(find.text('READY FOR PICKUP'), findsOneWidget);
      expect(find.text('Mark as Picked Up'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);

      // Ensure visible in scrollable list
      await tester.ensureVisible(find.text('Done'));
      await tester.pumpAndSettle();

      // Tap Done button
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Should show SnackBar
      expect(find.textContaining('Moved to Order History'), findsOneWidget);
    });
  });
}
