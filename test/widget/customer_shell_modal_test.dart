import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:save_bite/core/constants/app_constants.dart';
import 'package:save_bite/core/router/app_router.dart';
import 'package:save_bite/core/router/app_routes.dart';
import 'package:save_bite/core/theme/app_theme.dart';
import 'package:save_bite/core/widgets/user_avatar.dart';
import 'package:save_bite/features/auth/data/auth_repository.dart';
import 'package:save_bite/features/auth/domain/user_profile.dart';
import 'package:save_bite/features/auth/presentation/auth_controller.dart';
import 'package:save_bite/features/customer/offers/data/customer_offer_repository.dart';
import 'package:save_bite/features/customer/profile/widgets/change_avatar_sheet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../helpers/fake_auth_repository.dart';

class FakeCurrentUserNotifier extends CurrentUserNotifier {
  FakeCurrentUserNotifier(this._profile);
  final UserProfile? _profile;

  @override
  UserProfile? build() => _profile;
}

void main() {
  testWidgets('verify modal sheet renders above customer shell navbar with full GoRouter setup', (tester) async {
    const customerProfile = UserProfile(
      id: 'cust-1',
      email: 'customer@savebite.com',
      role: AppConstants.roleCustomer,
      fullName: 'Shahria Alam',
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

    final fakeAuth = FakeAuthRepository(initialProfile: customerProfile);

    tester.view.physicalSize = const Size(412 * 2.625, 915 * 2.625);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuth),
          currentUserProfileProvider.overrideWith(
            () => FakeCurrentUserNotifier(customerProfile),
          ),
          customerOfferRepositoryProvider.overrideWithValue(testOfferRepo),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            final router = ref.watch(routerProvider);
            return MaterialApp.router(
              theme: AppTheme.lightTheme,
              routerConfig: router,
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Navigate to profile / account
    final router = ProviderScope.containerOf(tester.element(find.byType(MaterialApp))).read(routerProvider);
    router.go(AppRoutes.customerProfile);
    await tester.pumpAndSettle();

    // Verify on account screen
    expect(find.byType(UserAvatar), findsWidgets);

    // Tap UserAvatar to open ChangeAvatarSheet
    await tester.tap(find.byType(UserAvatar).first);
    await tester.pumpAndSettle();

    // Verify modal sheet is displayed
    expect(find.byType(ChangeAvatarSheet), findsOneWidget);

    // Now check: Is the floating navbar's pill visible on top of ChangeAvatarSheet, or is ChangeAvatarSheet on top?
    // Let's check the render tree and layer order!
    final sheetRect = tester.getRect(find.byType(ChangeAvatarSheet));
    expect(sheetRect.bottom, equals(915.0));

    final saveButton = find.text('Save Profile Picture');
    expect(saveButton, findsOneWidget);
    final saveButtonRect = tester.getRect(saveButton);
    expect(saveButtonRect.top, greaterThan(800.0));

    // Check if navbar pill is hidden while modal sheet is open
    final pillFinder = find.byWidgetPredicate((widget) {
      if (widget is Container && widget.decoration is BoxDecoration) {
        final box = widget.decoration as BoxDecoration;
        return box.borderRadius == BorderRadius.circular(33);
      }
      return false;
    });

    // Pill MUST be hidden while modal is open
    expect(pillFinder, findsNothing);

    // Save button must be fully accessible and visible
    expect(saveButton, findsOneWidget);

    // Close the modal sheet
    final closeButton = find.byIcon(Icons.close_rounded);
    expect(closeButton, findsOneWidget);
    await tester.tap(closeButton);
    await tester.pumpAndSettle();

    // Verify modal sheet is closed
    expect(find.byType(ChangeAvatarSheet), findsNothing);

    // Verify pill has reappeared on the screen!
    expect(pillFinder, findsOneWidget);

    // Now test View / Edit Profile modal sheet
    final viewProfileButton = find.text('View Profile');
    expect(viewProfileButton, findsOneWidget);
    await tester.tap(viewProfileButton);
    await tester.pumpAndSettle();

    // Verify Edit Profile sheet is open
    expect(find.text('Save Changes'), findsOneWidget);

    // Verify pill is hidden while Edit Profile sheet is open
    expect(pillFinder, findsNothing);

    // Close Edit Profile sheet
    final editCloseButton = find.byIcon(Icons.close_rounded);
    expect(editCloseButton, findsOneWidget);
    await tester.tap(editCloseButton);
    await tester.pumpAndSettle();

    // Verify pill is visible again
    expect(pillFinder, findsOneWidget);

    // Test Favourites modal sheet in Account section
    final favouritesButton = find.text('Favourites');
    expect(favouritesButton, findsOneWidget);
    await tester.tap(favouritesButton);
    await tester.pumpAndSettle();

    // Verify Favourites sheet is open and pill is hidden
    expect(find.text('My Favourites'), findsOneWidget);
    expect(pillFinder, findsNothing);

    // Close Favourites sheet
    final favouritesCloseButton = find.byIcon(Icons.close_rounded);
    if (favouritesCloseButton.evaluate().isNotEmpty) {
      await tester.tap(favouritesCloseButton.first);
      await tester.pumpAndSettle();
    } else {
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();
    }
    expect(pillFinder, findsOneWidget);

    // Navigate to Home screen
    router.go(AppRoutes.customerHome);
    await tester.pumpAndSettle();
    expect(pillFinder, findsOneWidget);

    // Tap on the Deliver to location header on Home screen
    final deliverToFinder = find.text('Current location');
    expect(deliverToFinder, findsOneWidget);
    await tester.tap(deliverToFinder);
    await tester.pumpAndSettle();

    // Verify CustomerLocationSheet opened and pill is hidden
    expect(find.text('Use my current location'), findsOneWidget);
    expect(pillFinder, findsNothing);

    // Close CustomerLocationSheet by tapping outside/barrier
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    // Verify CustomerLocationSheet closed and pill is visible
    expect(find.text('Use my current location'), findsNothing);
    expect(pillFinder, findsOneWidget);
  });
}

