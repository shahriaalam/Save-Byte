import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:save_bite/core/constants/app_constants.dart';
import 'package:save_bite/core/theme/app_theme.dart';
import 'package:save_bite/features/auth/data/auth_repository.dart';
import 'package:save_bite/features/auth/domain/user_profile.dart';
import 'package:save_bite/features/auth/presentation/auth_controller.dart';
import 'package:save_bite/features/customer/offers/data/customer_offer_repository.dart';
import 'package:save_bite/features/customer/profile/customer_profile_screen.dart';
import 'package:save_bite/features/customer/restaurants/presentation/customer_restaurant_details_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../helpers/fake_auth_repository.dart';

class FakeCurrentUserNotifier extends CurrentUserNotifier {
  FakeCurrentUserNotifier(this._profile);
  final UserProfile? _profile;

  @override
  UserProfile? build() => _profile;
}

void main() {
  const customerProfile = UserProfile(
    id: 'cust-1',
    email: 'customer@savebite.com',
    role: AppConstants.roleCustomer,
    fullName: 'Rahim Ahmed',
    phone: '01700112233',
    isActive: true,
  );

  final testOfferRepo = CustomerOfferRepository(
    SupabaseClient(
      'https://placeholder.supabase.co',
      'placeholder-anon-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    ),
    useDemoDataOnly: true,
  );

  Widget createTestWidget(
    Widget child,
  ) {
    final fakeAuth = FakeAuthRepository(initialProfile: customerProfile);

    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuth),
        currentUserProfileProvider.overrideWith(
          () => FakeCurrentUserNotifier(customerProfile),
        ),
        customerOfferRepositoryProvider.overrideWithValue(testOfferRepo),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: child,
      ),
    );
  }

  group('Customer Favorites & Restaurant Details Back Button', () {
    testWidgets('CustomerRestaurantDetailsScreen renders prominent back button and favourite button',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const CustomerRestaurantDetailsScreen(restaurantId: 'res-1'),
        ),
      );
      await tester.pumpAndSettle();

      // Back button in SliverAppBar
      final backButtonFinder = find.byTooltip('Back');
      expect(backButtonFinder, findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsWidgets);

      // Add to Favourite button in app bar actions and inline badge
      expect(find.byTooltip('Add to favourites'), findsOneWidget);
      expect(find.text('Add to Favourite'), findsOneWidget);

      // Tap Add to Favourite
      await tester.tap(find.byTooltip('Add to favourites'));
      await tester.pumpAndSettle();

      // Should now reflect Favourited
      expect(find.byTooltip('Remove from favourites'), findsOneWidget);
      expect(find.text('Favourited'), findsOneWidget);
    });

    testWidgets('My Favourites modal renders list, allows Edit to remove items',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const CustomerProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Find and tap Favourites quick action tile
      final favouritesTile = find.text('Favourites');
      expect(favouritesTile, findsOneWidget);
      await tester.tap(favouritesTile);
      await tester.pumpAndSettle();

      // Verify My Favourites modal is open
      expect(find.text('My Favourites'), findsOneWidget);
      expect(find.text("Sultan's Dine"), findsOneWidget);
      expect(find.text('Chillox Burgers'), findsOneWidget);
      expect(find.text('Secret Recipe'), findsOneWidget);

      // Verify Edit button exists and tap it
      final editButton = find.text('Edit');
      expect(editButton, findsOneWidget);
      await tester.tap(editButton);
      await tester.pumpAndSettle();

      // Now in Edit mode -> Done button is shown, delete icons visible inside modal list
      expect(find.text('Done'), findsOneWidget);
      final deleteIcons = find.descendant(
        of: find.byType(ListView),
        matching: find.byIcon(Icons.delete_outline_rounded),
      );
      expect(deleteIcons, findsNWidgets(3));

      // Tap the first delete icon to remove Sultan's Dine
      await tester.tap(deleteIcons.first);
      await tester.pumpAndSettle();

      // Verify Sultan's Dine is removed
      expect(find.text("Sultan's Dine"), findsNothing);
      expect(find.text('Chillox Burgers'), findsOneWidget);
      expect(find.text('Secret Recipe'), findsOneWidget);

      // Tap Done
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Verify back in normal mode (Edit button restored, ratings visible)
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('4.8 ★'), findsOneWidget);
      expect(find.text('4.7 ★'), findsOneWidget);
    });
  });
}
