import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:save_bite/core/constants/app_constants.dart';
import 'package:save_bite/core/theme/app_theme.dart';
import 'package:save_bite/core/widgets/user_avatar.dart';
import 'package:save_bite/features/auth/data/auth_repository.dart';
import 'package:save_bite/features/auth/domain/user_profile.dart';
import 'package:save_bite/features/auth/presentation/auth_controller.dart';
import 'package:save_bite/core/widgets/app_logo.dart';
import 'package:save_bite/features/customer/home/customer_home_screen.dart';
import 'package:save_bite/features/customer/hot_deals/customer_hot_deals_screen.dart';
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

    testWidgets(
        'does not have huge gap below last listed item when scrolled to bottom',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(const CustomerHomeScreen()));
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView);
      await tester.drag(scrollable, const Offset(0, -8000));
      await tester.pumpAndSettle();

      final offerCards = find.byType(OfferCard);
      expect(offerCards, findsWidgets);
      final lastCard = offerCards.last;
      final lastCardRect = tester.getRect(lastCard);

      // Verify last card is visible near the bottom, not scrolled far off-screen
      expect(lastCardRect.bottom, isPositive);
      expect(lastCardRect.bottom, greaterThan(600));
      expect(lastCardRect.bottom, lessThanOrEqualTo(800));
    });

    testWidgets(
        'renders redesigned header with location symbol logo, Banasree location, and no right GPS button',
        (tester) async {
      await tester.pumpWidget(createTestWidget(const CustomerHomeScreen()));
      await tester.pumpAndSettle();

      // Verify app logo is rendered with location symbol
      expect(find.byType(AppLogoIcon), findsWidgets);
      expect(find.byIcon(Icons.location_on_rounded), findsWidgets);

      // Verify current location is set to Banasree, Dhaka
      expect(find.text('Current location'), findsOneWidget);
      expect(find.text('Banasree, Dhaka'), findsWidgets);

      // Verify right-side GPS location buttons are removed
      expect(find.byIcon(Icons.my_location_rounded), findsNothing);
      expect(find.byIcon(Icons.near_me_outlined), findsNothing);
      expect(find.byIcon(Icons.menu_rounded), findsNothing);
      expect(find.byType(Drawer), findsNothing);
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

    testWidgets('renders division and area filter dropdowns and filters offers',
        (tester) async {
      await tester.pumpWidget(createTestWidget(const CustomerSearchScreen()));
      await tester.pumpAndSettle();

      // Division and area filters are present
      expect(find.text('All Divisions'), findsOneWidget);
      expect(find.text('All Areas'), findsOneWidget);

      // Tap division dropdown and select Dhaka
      await tester.tap(find.text('All Divisions'));
      await tester.pumpAndSettle();

      // Select 'Dhaka' from dropdown
      final dhakaOption = find.text('Dhaka').last;
      await tester.tap(dhakaOption);
      await tester.pumpAndSettle();

      // Verify Dhaka is selected
      expect(find.text('Dhaka'), findsWidgets);

      // Now tap Area dropdown and select Dhanmondi
      await tester.tap(find.text('All Areas'));
      await tester.pumpAndSettle();

      final dhanmondiOption = find.text('Dhanmondi').last;
      await tester.tap(dhanmondiOption);
      await tester.pumpAndSettle();

      // Verify offers still display
      expect(find.byType(OfferCard), findsWidgets);
    });
  });

  group('Customer Profile Screen (Section 26)', () {
    testWidgets('renders user info, edit profile action, and logout',
        (tester) async {
      await tester.pumpWidget(createTestWidget(const CustomerProfileScreen()));
      await tester.pumpAndSettle();

      // Verify customer info & header
      expect(find.text('Rahim Ahmed'), findsWidgets);
      expect(find.text('customer@savebite.com'), findsOneWidget);
      expect(find.text('View Profile'), findsOneWidget);

      // Verify Super Saver card & action tiles
      expect(find.text('Become a Super Saver'), findsWidgets);
      expect(find.text('Orders'), findsOneWidget);
      expect(find.text('Addresses'), findsOneWidget);
      expect(find.text('Favourites'), findsOneWidget);
      expect(find.text('Vouchers'), findsOneWidget);
      expect(find.text('Rewards'), findsOneWidget);
      expect(find.text('Help center'), findsOneWidget);
      expect(find.text('Contact us'), findsOneWidget);

      // Verify menu options list
      expect(find.text('Refund policy'), findsOneWidget);
      expect(find.text('Privacy policy'), findsOneWidget);
      expect(find.text('Join group order'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
      expect(find.text('Log out'), findsOneWidget);

      // Scroll to About and tap it to verify About modal sheet opens and contains Version 1.1.0
      await tester.ensureVisible(find.text('About'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('About'));
      await tester.pumpAndSettle();
      expect(find.text('About SaveBite'), findsOneWidget);
      expect(find.text('Version 1.1.0 (Build 110)'), findsOneWidget);

      // Close About modal by tapping outside
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      // Tap View Profile
      await tester.ensureVisible(find.text('View Profile'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('View Profile'));
      await tester.pumpAndSettle();

      // Verify bottom sheet appears with editable fields
      expect(find.text('My Profile'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('First Name *'), findsOneWidget);
      expect(find.text('Last Name'), findsOneWidget);
      expect(find.text('Gender'), findsOneWidget);
      expect(find.text('Phone Number'), findsWidgets);
    });

    testWidgets(
      'renders UserAvatar and tapping Change Profile Picture opens ChangeAvatarSheet',
      (tester) async {
        await tester.pumpWidget(createTestWidget(const CustomerProfileScreen()));
        await tester.pumpAndSettle();

        // Verify UserAvatar
        expect(find.byType(UserAvatar), findsWidgets);

        // Tap UserAvatar directly on account screen
        await tester.tap(find.byType(UserAvatar).first);
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

    testWidgets(
      'tapping Delete account displays confirmation dialog and triggers deletion',
      (tester) async {
        await tester.pumpWidget(createTestWidget(const CustomerProfileScreen()));
        await tester.pumpAndSettle();

        // Find and tap Delete account option
        final deleteOption = find.text('Delete account');
        expect(deleteOption, findsOneWidget);
        await tester.ensureVisible(deleteOption);
        await tester.tap(deleteOption);
        await tester.pumpAndSettle();

        // Verify confirmation dialog appears with warning
        expect(find.text('Delete Account?'), findsOneWidget);
        expect(
          find.text('Are you sure you want to permanently delete your SaveBite account?'),
          findsOneWidget,
        );
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Delete Account'), findsOneWidget);

        // Tap Delete Account in dialog to confirm
        await tester.tap(find.widgetWithText(FilledButton, 'Delete Account'));
        await tester.pumpAndSettle();

        // Verify success snackbar appears
        expect(find.text('Your account has been deleted.'), findsOneWidget);
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

    testWidgets(
      'double pull on CustomerProfileScreen reloads in place and stays on Profile screen without navigating away',
      (tester) async {
        await tester.pumpWidget(createTestWidget(const CustomerProfileScreen()));
        await tester.pumpAndSettle();

        expect(find.text('Rahim Ahmed'), findsOneWidget);

        // 1. First pull down at top
        await tester.drag(find.byType(SingleChildScrollView), const Offset(0, 80));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Pull down once more to reload'), findsOneWidget);
        expect(find.text('Rahim Ahmed'), findsOneWidget);

        // 2. Second pull down within 2 seconds
        await tester.drag(find.byType(SingleChildScrollView), const Offset(0, 80));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Reloading...'), findsOneWidget);
        // Verify we are STILL firmly on the Profile screen, not navigated away to Home
        expect(find.text('Rahim Ahmed'), findsOneWidget);
        expect(find.text('Become a Super Saver'), findsWidgets);

        // Let snackbars and timers finish
        await tester.pump(const Duration(seconds: 3));
        expect(find.text('Rahim Ahmed'), findsOneWidget);
      },
    );
  });

  group('Customer Hot Deals Screen', () {
    testWidgets('renders hot deals header, 45%+ OFF badge, and hot deal offers', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget(const CustomerHotDealsScreen()));
      await tester.pumpAndSettle();

      // Verify header and badge
      expect(find.text('🔥 Hot Deals Near You'), findsOneWidget);
      expect(find.text('45%+ OFF'), findsOneWidget);

      // Verify category filter chips
      expect(find.widgetWithText(FilterChip, 'All'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Burger'), findsOneWidget);

      // Verify offers are rendered with OfferCard
      expect(find.byType(OfferCard), findsWidgets);

      // Verify strict V1 requirement: NO ORDER BUTTON
      expect(find.text('Order'), findsNothing);
      expect(find.text('Buy Now'), findsNothing);
      expect(find.text('Add to Cart'), findsNothing);
    });
  });
}
