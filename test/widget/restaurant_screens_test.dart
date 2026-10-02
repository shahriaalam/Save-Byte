import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:save_bite/core/constants/app_constants.dart';
import 'package:save_bite/core/theme/app_theme.dart';
import 'package:save_bite/features/auth/domain/user_profile.dart';
import 'package:save_bite/features/auth/presentation/auth_controller.dart';
import 'package:save_bite/features/restaurant/dashboard/restaurant_dashboard_screen.dart';
import 'package:save_bite/features/restaurant/offers/presentation/create_offer_screen.dart';
import 'package:save_bite/features/restaurant/presentation/restaurant_controller.dart';
import 'package:save_bite/features/restaurant/profile/restaurant_profile_screen.dart';
import 'package:save_bite/features/shared/models/restaurant.dart';

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
  }) {
    return ProviderScope(
      overrides: [
        currentUserProfileProvider.overrideWith(
          () => FakeCurrentUserNotifier(restaurantUser),
        ),
        currentRestaurantProvider.overrideWith((ref) => restaurant),
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

    testWidgets('tapping Post Surplus Food with incomplete profile shows blocking alert dialog', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(
        const RestaurantDashboardScreen(),
        restaurant: incompleteRestaurant,
      ));
      await tester.pumpAndSettle();

      // Tap Post Surplus Food button
      final postButton = find.text('Post Surplus Food');
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
      expect(find.text('Surplus Price (৳) *'), findsNothing);
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
      expect(find.text('Post Surplus Food'), findsOneWidget);
      expect(find.text('Food Offer Title *'), findsOneWidget);
      expect(find.text('Surplus Price (৳) *'), findsOneWidget);
      expect(find.text('Publish Surplus Food Post'), findsOneWidget);
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
  });
}
