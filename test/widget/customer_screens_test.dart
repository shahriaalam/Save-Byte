import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:save_bite/core/constants/app_constants.dart';
import 'package:save_bite/core/theme/app_theme.dart';
import 'package:save_bite/core/widgets/user_avatar.dart';
import 'package:save_bite/features/auth/data/auth_repository.dart';
import 'package:save_bite/features/auth/domain/user_profile.dart';
import 'package:save_bite/features/auth/presentation/auth_controller.dart';
import 'package:save_bite/features/customer/home/customer_home_screen.dart';
import 'package:save_bite/features/customer/offers/data/customer_offer_repository.dart';
import 'package:save_bite/features/customer/offers/presentation/customer_offer_details_screen.dart';
import 'package:save_bite/features/customer/profile/customer_profile_screen.dart';
import 'package:save_bite/features/customer/profile/widgets/change_avatar_sheet.dart';
import 'package:save_bite/features/customer/restaurants/presentation/customer_restaurant_details_screen.dart';
import 'package:save_bite/features/customer/search/customer_search_screen.dart';
import 'package:save_bite/features/shared/widgets/offer_card.dart';
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
    Widget child, {
    UserProfile? profile = customerProfile,
  }) {
    final fakeAuth = FakeAuthRepository(initialProfile: profile);

    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuth),
        currentUserProfileProvider.overrideWith(
          () => FakeCurrentUserNotifier(profile),
        ),
        customerOfferRepositoryProvider.overrideWithValue(testOfferRepo),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: child,
      ),
    );
  }

  group('Customer HomeScreen (Section 20 & 25)', () {
    testWidgets('renders greeting, search shortcut, and category chips',
        (tester) async {
      await tester.pumpWidget(createTestWidget(const CustomerHomeScreen()));
      await tester.pumpAndSettle();

      // Verify personalized greeting or time greeting
      expect(find.textContaining('👋'), findsOneWidget);
      expect(find.text('Find affordable food near you'), findsOneWidget);

      // Verify search shortcut bar
      expect(find.text('Search food or restaurant...'), findsOneWidget);

      // Verify category filter chips specifically
      expect(find.widgetWithText(FilterChip, 'All'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Rice'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Burger'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Pizza'), findsOneWidget);

      // Verify offers are rendered with OfferCard
      expect(find.byType(OfferCard), findsWidgets);

      // Verify strict V1 requirement: NO ORDER BUTTON (Section 5 & 21)
      expect(find.text('Order'), findsNothing);
      expect(find.text('Buy Now'), findsNothing);
      expect(find.text('Add to Cart'), findsNothing);
    });
  });

  group('Customer Offer Details Screen (Section 22)', () {
    testWidgets('renders offer details, pricing, and View Restaurant button',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const CustomerOfferDetailsScreen(offerId: 'offer-1'),
        ),
      );
      await tester.pumpAndSettle();

      // Verify offer title and pricing
      expect(find.text('Chicken Biryani'), findsOneWidget);
      expect(find.text('৳150'), findsOneWidget);
      expect(find.text('৳250'), findsOneWidget);
      expect(find.text('Save ৳100'), findsOneWidget);

      // Verify View Restaurant Details button
      expect(find.text('View Restaurant Details'), findsOneWidget);

      // Verify strictly NO order button (Section 22 & Section 5)
      expect(find.text('Order Now'), findsNothing);
      expect(find.text('Add to Cart'), findsNothing);
    });
  });

  group('Customer Restaurant Details Screen (Section 23)', () {
    testWidgets('renders restaurant details and active offers list',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const CustomerRestaurantDetailsScreen(restaurantId: 'res-1'),
        ),
      );
      await tester.pumpAndSettle();

      // Verify restaurant title & address
      expect(find.text("Rahman's Kitchen"), findsWidgets);
      expect(find.text('Available Offers'), findsOneWidget);
      expect(find.text('Address'), findsOneWidget);

      // Verify restaurant's active offers
      expect(find.byType(OfferCard), findsWidgets);
    });
  });

  group('Customer Search Screen (Section 24)', () {
    testWidgets('renders search text field and filters results',
        (tester) async {
      await tester.pumpWidget(createTestWidget(const CustomerSearchScreen()));
      await tester.pumpAndSettle();

      // Search input bar exists
      expect(
        find.widgetWithText(
          TextField,
          'Search biryani, burger, pizza, restaurant...',
        ),
        findsOneWidget,
      );

      // Categories exist on search screen
      expect(find.widgetWithText(FilterChip, 'All'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Rice'), findsOneWidget);

      // Type search query
      await tester.enterText(find.byType(TextField), 'biryani');
      await tester.pumpAndSettle();

      // Offers list renders
      expect(find.byType(OfferCard), findsWidgets);
    });
  });

  group('Customer Profile Screen (Section 26)', () {
    testWidgets('renders user info, edit profile action, and logout',
        (tester) async {
      await tester.pumpWidget(createTestWidget(const CustomerProfileScreen()));
      await tester.pumpAndSettle();

      // Verify customer info
      expect(find.text('Rahim Ahmed'), findsWidgets);
      expect(find.text('customer@savebite.com'), findsOneWidget);
      expect(find.text('01700112233'), findsOneWidget);
      expect(find.text('Customer Account'), findsOneWidget);

      // Verify Edit Profile and Logout buttons
      expect(find.text('Edit Profile'), findsWidgets);
      expect(find.text('Log Out'), findsOneWidget);

      // Tap Edit Profile button in AppBar
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      // Verify bottom sheet appears with editable fields
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('Full Name *'), findsOneWidget);
      expect(find.text('Phone Number'), findsWidgets);
    });

    testWidgets(
      'renders UserAvatar and tapping Change Profile Picture opens ChangeAvatarSheet',
      (tester) async {
        await tester.pumpWidget(createTestWidget(const CustomerProfileScreen()));
        await tester.pumpAndSettle();

        // Verify UserAvatar and change picture button
        expect(find.byType(UserAvatar), findsWidgets);
        expect(find.text('Change Profile Picture'), findsOneWidget);

        // Tap Change Profile Picture button
        await tester.tap(find.text('Change Profile Picture'));
        await tester.pumpAndSettle();

        // Verify ChangeAvatarSheet modal appears
        expect(find.byType(ChangeAvatarSheet), findsOneWidget);
        expect(find.text('Choose a Foodie Avatar'), findsOneWidget);
        expect(find.text('Upload Photo from Device'), findsOneWidget);
        expect(find.text('Save Profile Picture'), findsOneWidget);

        // Verify foodie preset avatars are rendered
        expect(find.text('Pizza Lover'), findsOneWidget);
        expect(find.text('Gourmet Burger'), findsOneWidget);
        expect(find.text('Hot Ramen'), findsOneWidget);

        // Tap a preset avatar
        await tester.tap(find.text('Pizza Lover'));
        await tester.pumpAndSettle();

        // Verify checkmark appears for the selected preset
        expect(find.byIcon(Icons.check_rounded), findsOneWidget);

        // Tap Save Profile Picture with ensureVisible
        await tester.ensureVisible(find.text('Save Profile Picture'));
        await tester.tap(find.text('Save Profile Picture'));
        await tester.pumpAndSettle();

        // Verify sheet closes and success snackbar appears
        expect(find.byType(ChangeAvatarSheet), findsNothing);
        expect(
          find.text('Profile picture updated successfully!'),
          findsOneWidget,
        );
      },
    );

    testWidgets('UserAvatar renders monogram initials properly', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Center(
              child: UserAvatar(
                name: 'Kazi Nazrul',
                radius: 40,
                showEditBadge: true,
              ),
            ),
          ),
        ),
      );

      // Verify initials "KN"
      expect(find.text('KN'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);
    });
  });
}
