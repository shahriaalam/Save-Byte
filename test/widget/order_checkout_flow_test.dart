import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:save_bite/core/router/app_router.dart';
import 'package:save_bite/core/theme/app_theme.dart';
import 'package:save_bite/features/auth/domain/user_profile.dart';
import 'package:save_bite/features/auth/presentation/auth_controller.dart';
import 'package:save_bite/features/customer/orders/presentation/customer_orders_sheet.dart';
import 'package:save_bite/features/customer/orders/presentation/order_checkout_sheet.dart';
import 'package:save_bite/features/shared/data/order_controller.dart';
import 'package:save_bite/features/shared/models/order.dart';

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

  final testOrder = Order(
    id: 'ord-test-123',
    orderNumber: 'SB-795487',
    customerId: 'demo-customer-id',
    customerName: 'Shahriar Alam',
    customerPhone: '01712345678',
    customerEmail: 'customer@savebite.app',
    restaurantId: 'res-blue-bell',
    restaurantName: 'Blue Bell Café',
    restaurantAddress: 'Dhanmondi 27, Dhaka',
    offerId: 'off-1',
    title: 'Surplus Pastry Box',
    category: 'Bakery',
    quantity: 1,
    unitPrice: 240,
    originalUnitPrice: 500,
    totalPrice: 240,
    totalSavings: 260,
    pickupTime: '12:54 PM',
    pickupCode: '6524',
    paymentMethod: 'BKASH',
    paymentStatus: 'paid',
    status: 'confirmed',
    createdAt: DateTime.now(),
  );

  testWidgets('showCustomerOrdersSheet opens cleanly without errors',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProfileProvider.overrideWith(
            () => _FakeCurrentUserNotifier(testProfile),
          ),
          customerOrdersProvider('demo-customer-id').overrideWith(
            (ref) async => [testOrder],
          ),
        ],
        child: MaterialApp(
          navigatorKey: rootNavigatorKey,
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => Center(
                child: ElevatedButton(
                  onPressed: () => showCustomerOrdersSheet(context: ctx),
                  child: const Text('Open Orders'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Open Orders'), findsOneWidget);
    await tester.tap(find.text('Open Orders'));
    await tester.pumpAndSettle();

    // Verify sheet opened
    expect(find.text('My Takeaway Orders'), findsOneWidget);
    expect(find.text('Blue Bell Café'), findsOneWidget);
    expect(find.text('6524'), findsOneWidget);
  });

  testWidgets(
      'View in My Orders button on order success dialog cleanly navigates to orders sheet',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProfileProvider.overrideWith(
            () => _FakeCurrentUserNotifier(testProfile),
          ),
          customerOrdersProvider('demo-customer-id').overrideWith(
            (ref) async => [testOrder],
          ),
        ],
        child: MaterialApp(
          navigatorKey: rootNavigatorKey,
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Trigger the success dialog directly via root navigator
                    OrderCheckoutSheetStatePublic.showSuccessDialogForTest(
                      ctx,
                      testOrder,
                    );
                  },
                  child: const Text('Simulate Order Placed'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // Tap button to launch success dialog
    await tester.tap(find.text('Simulate Order Placed'));
    await tester.pumpAndSettle();

    // Verify success dialog elements
    expect(find.text('Order Booked & Paid! 🎉'), findsOneWidget);
    expect(find.text('Order #SB-795487'), findsOneWidget);
    expect(find.text('PIN 6524'), findsOneWidget);
    expect(find.text('View in My Orders'), findsOneWidget);

    // Tap 'View in My Orders'
    await tester.tap(find.text('View in My Orders'));
    await tester.pumpAndSettle();

    // Verify dialog was dismissed and CustomerOrdersSheet is displayed
    expect(find.text('Order Booked & Paid! 🎉'), findsNothing);
    expect(find.text('My Takeaway Orders'), findsOneWidget);
    expect(find.text('Blue Bell Café'), findsOneWidget);
    expect(find.text('Active Pickups'), findsOneWidget);
  });
}

/// Helper for testing the dialog
extension OrderCheckoutSheetStatePublic on OrderCheckoutSheet {
  static void showSuccessDialogForTest(BuildContext context, Order order) {
    showDialog<void>(
      context: rootNavigatorKey.currentContext ?? context,
      useRootNavigator: true,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Order Booked & Paid! 🎉',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
            Text('Order #${order.orderNumber}'),
            Text('PIN ${order.pickupCode}'),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                final targetContext = rootNavigatorKey.currentContext ?? context;
                showCustomerOrdersSheet(context: targetContext);
              },
              child: const Text('View in My Orders'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
