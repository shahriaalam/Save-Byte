import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:save_bite/core/constants/app_constants.dart';
import 'package:save_bite/core/theme/app_theme.dart';
import 'package:save_bite/features/admin/dashboard/admin_dashboard_screen.dart';
import 'package:save_bite/features/admin/dashboard/widgets/admin_analytics_dashboard_sheet.dart';
import 'package:save_bite/features/auth/data/auth_repository.dart';
import 'package:save_bite/features/auth/domain/user_profile.dart';
import 'package:save_bite/features/auth/presentation/auth_controller.dart';
import 'package:save_bite/features/shared/presentation/payment_portal_sheet.dart';

import '../helpers/fake_auth_repository.dart';

void main() {
  testWidgets('PaymentPortalSheet renders amount, gateway choices and security badges',
      (WidgetTester tester) async {
    PaymentResult? capturedResult;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  capturedResult = await showPaymentPortalSheet(
                    context: context,
                    amount: 999.0,
                    title: 'Upgrade to Gold Merchant',
                    subtitle: 'Pay via bKash / Nagad / Rocket / Card',
                    customerOrBusinessName: "Sultan's Dine Banasree",
                  );
                },
                child: const Text('Open Payment Portal'),
              ),
            ),
          ),
        ),
      ),
    );

    // Tap to open sheet
    await tester.tap(find.text('Open Payment Portal'));
    await tester.pumpAndSettle();

    // Verify Title, Amount, Gateways
    expect(find.text('Upgrade to Gold Merchant'), findsOneWidget);
    expect(find.text('৳999'), findsWidgets);
    expect(find.text('bKash'), findsOneWidget);
    expect(find.text('Nagad'), findsOneWidget);
    expect(find.text('Rocket'), findsOneWidget);
    expect(find.text('Card'), findsOneWidget);
    expect(find.text('256-Bit SSL Encrypted Payment Portal'), findsOneWidget);

    // Verify Pay Button
    expect(find.text('Pay ৳999 via bKash'), findsOneWidget);

    // Cancel modal
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(capturedResult, isNotNull);
    expect(capturedResult!.isSuccess, isFalse);
  });

  testWidgets('AdminAnalyticsDashboardSheet renders KPI metrics, graph, pie chart and banner runs',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showAdminAnalyticsDashboardSheet(context),
                child: const Text('Open Analytics Dashboard'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Analytics Dashboard'));
    await tester.pumpAndSettle();

    // Check KPI metrics & header
    expect(find.text('Platform Financial Dashboard'), findsOneWidget);
    expect(find.text('Monthly Subscription Earning'), findsOneWidget);
    expect(find.text('Total Platform Earning'), findsOneWidget);
    expect(find.text('Total Partners'), findsOneWidget);
    expect(find.text('Hero Banner Runs'), findsOneWidget);

    // Check chart and section titles
    expect(find.text('Monthly Earnings Growth'), findsOneWidget);
    expect(find.text('Revenue Streams Breakdown (Pie Chart)'), findsOneWidget);
    expect(find.text('Hero Banners Run for That Month'), findsOneWidget);
    expect(find.text('Real-Time Subscription Feed'), findsOneWidget);

    // Close sheet
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
  });

  testWidgets('AdminDashboardScreen has Dashboard as 1st Quick Access option and tapping opens analytics',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const adminProfile = UserProfile(
      id: 'admin-1',
      email: 'admin@savebite.com',
      fullName: 'Head Administrator',
      role: AppConstants.roleHeadAdmin,
      isActive: true,
    );
    final fakeAuth = FakeAuthRepository(initialProfile: adminProfile);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuth),
          currentUserProfileProvider
              .overrideWith(() => _FakeAdminCurrentUserNotifier(adminProfile)),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AdminDashboardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify 13 Tools count and 1st symbol 'Dashboard' with 'Live KPI' badge
    expect(find.text('13 Tools'), findsOneWidget);
    expect(find.text('Live KPI'), findsOneWidget);

    // Tap Dashboard quick access button via its unique Live KPI badge or tile
    await tester.tap(find.text('Live KPI'));
    await tester.pumpAndSettle();

    // Verify Analytics Dashboard sheet opened
    expect(find.text('Platform Financial Dashboard'), findsOneWidget);
    expect(find.text('Monthly Subscription Earning'), findsOneWidget);
    expect(find.text('Total Platform Earning'), findsOneWidget);

    // Close sheet
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
  });
}

class _FakeAdminCurrentUserNotifier extends CurrentUserNotifier {
  _FakeAdminCurrentUserNotifier(this.profile);
  final UserProfile? profile;

  @override
  UserProfile? build() => profile;
}
