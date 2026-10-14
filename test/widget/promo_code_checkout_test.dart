import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:save_bite/core/theme/app_theme.dart';
import 'package:save_bite/features/auth/domain/user_profile.dart';
import 'package:save_bite/features/auth/presentation/auth_controller.dart';
import 'package:save_bite/features/customer/orders/presentation/order_checkout_sheet.dart';
import 'package:save_bite/features/shared/models/food_offer.dart';

class _FakeCurrentUserNotifier extends CurrentUserNotifier {
  _FakeCurrentUserNotifier(this._profile);
  final UserProfile? _profile;

  @override
  UserProfile? build() => _profile;
}

void main() {
  const testProfile = UserProfile(
    id: 'demo-customer-id',
    email: 'customer@savebite.app',
    role: 'customer',
    fullName: 'Shahriar Alam',
    phone: '01712345678',
    isActive: true,
  );

  final testOffer = FoodOffer(
    id: 'off-test-1',
    restaurantId: 'res-blue-bell',
    restaurantName: 'Blue Bell Café',
    restaurantAddress: 'Dhanmondi 27, Dhaka',
    title: 'Surplus Pastry Box',
    category: 'Bakery',
    originalPrice: 500,
    discountedPrice: 240,
    quantity: 5,
    availableFrom: DateTime.now().subtract(const Duration(hours: 1)),
    availableUntil: DateTime.now().add(const Duration(hours: 3)),
  );

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        currentUserProfileProvider.overrideWith(
          () => _FakeCurrentUserNotifier(testProfile),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Builder(
            builder: (ctx) => Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: Size.zero),
                onPressed: () => showOrderCheckoutSheet(
                  context: ctx,
                  offer: testOffer,
                ),
                child: const Text('Open Checkout'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('OrderCheckoutSheet renders clean promo code input and hides suggested chips/offers',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Checkout'));
    await tester.pumpAndSettle();

    // Verify promo code section header and input exist
    expect(find.text('Have a Promo Code?'), findsOneWidget);
    expect(find.text('Apply'), findsOneWidget);

    // Verify suggested chips and view offers are NOT displayed
    expect(find.text('SAVEBITE50'), findsNothing);
    expect(find.text('SAVE20'), findsNothing);
    expect(find.text('RESCUE30'), findsNothing);
    expect(find.text('View Offers'), findsNothing);
  });

  testWidgets('Manually typing SAVEBITE50 and tapping Apply applies discount and platform sponsorship guarantee',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Checkout'));
    await tester.pumpAndSettle();

    // Enter promo code manually in TextField
    final promoTextField = find.widgetWithText(TextField, 'Enter code (e.g. SAVEBITE50)');
    expect(promoTextField, findsOneWidget);
    await tester.enterText(promoTextField, 'SAVEBITE50');
    await tester.pumpAndSettle();

    // Tap Apply button
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    // Verify applied state is shown
    expect(find.text('SAVEBITE50'), findsOneWidget);
    expect(find.text('-৳50 OFF'), findsOneWidget);
    expect(
      find.text('🛡️ 100% Platform Sponsored • Blue Bell Café receives full payout'),
      findsOneWidget,
    );
    expect(find.text('Promo Discount (SAVEBITE50)'), findsOneWidget);
    expect(find.text('-৳50'), findsOneWidget);

    // Initial item total is 240, after 50 discount, total payable is 190
    expect(find.text('৳190'), findsWidgets);
    expect(find.text('Proceed to Pay ৳190'), findsOneWidget);
  });

  testWidgets('Manually typing SAVE20 and tapping Apply calculates 20% discount',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Checkout'));
    await tester.pumpAndSettle();

    // Enter promo code manually in TextField
    final promoTextField = find.widgetWithText(TextField, 'Enter code (e.g. SAVEBITE50)');
    expect(promoTextField, findsOneWidget);
    await tester.enterText(promoTextField, 'SAVE20');
    await tester.pumpAndSettle();

    // Tap Apply button
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    // 20% of 240 = 48 discount -> total payable 192
    expect(find.text('SAVE20'), findsOneWidget);
    expect(find.text('-৳48 OFF'), findsOneWidget);
    expect(find.text('Promo Discount (SAVE20)'), findsOneWidget);
    expect(find.text('-৳48'), findsOneWidget);
    expect(find.text('৳192'), findsWidgets);
    expect(find.text('Proceed to Pay ৳192'), findsOneWidget);
  });

  testWidgets('Entering invalid promo code displays error message',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Checkout'));
    await tester.pumpAndSettle();

    final promoTextField = find.widgetWithText(TextField, 'Enter code (e.g. SAVEBITE50)');
    await tester.enterText(promoTextField, 'INVALIDCODE');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(
      find.text('Invalid promo code "INVALIDCODE". Please check and try again.'),
      findsOneWidget,
    );
  });
}
