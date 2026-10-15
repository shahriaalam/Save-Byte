import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:save_bite/core/constants/app_constants.dart';
import 'package:save_bite/core/router/app_router.dart';
import 'package:save_bite/core/router/app_routes.dart';
import 'package:save_bite/core/widgets/app_logo.dart';
import 'package:save_bite/features/admin/dashboard/admin_dashboard_screen.dart';
import 'package:save_bite/features/auth/domain/user_profile.dart';
import 'package:save_bite/features/auth/presentation/auth_controller.dart';

class FakeCurrentUserNotifier extends CurrentUserNotifier {
  FakeCurrentUserNotifier(this._profile);
  final UserProfile? _profile;

  @override
  UserProfile? build() => _profile;
}

void main() {
  const adminProfile = UserProfile(
    id: 'admin-1',
    email: 'admin@savebite.com',
    role: AppConstants.roleAdmin,
    fullName: 'SaveBite Operations Director',
    phone: '01700000000',
    isActive: true,
  );

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [
        currentUserProfileProvider.overrideWith(
          () => FakeCurrentUserNotifier(adminProfile),
        ),
      ],
      child: const MaterialApp(
        home: AdminDashboardScreen(),
      ),
    );
  }

  testWidgets(
      'AdminDashboardScreen renders futuristic header, KPIs, and floating nav bar',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Verify SaveBite Admin Panel header, logo, and role badge
    expect(find.byType(AppLogoIcon), findsOneWidget);
    expect(find.text('SaveBite Admin Panel'), findsOneWidget);
    expect(find.text('ADMIN • ACTIVE'), findsOneWidget);

    // Verify KPI Telemetry Cards
    expect(find.text('TOTAL ORDERS'), findsOneWidget);
    expect(find.text('PARTNER KITCHENS'), findsOneWidget);
    expect(find.text('ACTIVE POSTS'), findsOneWidget);
    expect(find.text('PLATFORM VOLUME'), findsOneWidget);

    // Verify Quick Access Section & symbols
    expect(find.text('QUICK ACCESS COMMANDS'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Partners'), findsWidgets);
    expect(find.text('Posts'), findsWidgets);
    expect(find.text('Banners'), findsWidgets);
    expect(find.text('Verify ID'), findsOneWidget);
    expect(find.text('Vouchers'), findsOneWidget);
    expect(find.text('Ad Sales'), findsOneWidget);
    expect(find.text('Accounts'), findsOneWidget);
    expect(find.text('Broadcast'), findsOneWidget);
    expect(find.text('Reviews'), findsOneWidget);
    expect(find.text('Audit Log'), findsOneWidget);
    expect(find.text('Telemetry'), findsNothing);

    // Verify Floating Nav Bar items
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);

    // Verify Urgent Approvals Queue
    expect(find.text('URGENT ACTIONS REQUIRED'), findsOneWidget);
  });

  testWidgets('AdminDashboardScreen navigates via floating nav bar tabs',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Tap on Partners floating nav bar item (the last 'Partners' on screen is in the floating nav bar)
    final partnersNavItem = find.text('Partners').last;
    await tester.tap(partnersNavItem);
    await tester.pumpAndSettle();

    // Verify we are now on Partners tab
    expect(find.text('PARTNER DIRECTORY & ONBOARDING'), findsOneWidget);

    // Tap on Posts floating nav bar item
    final postsNavItem = find.text('Posts').last;
    await tester.tap(postsNavItem);
    await tester.pumpAndSettle();

    // Verify Posts tab and Remove button
    expect(find.text('COMMUNITY POSTS MONITOR'), findsOneWidget);
    expect(find.text('Remove'), findsWidgets);

    // Tap on System floating nav bar item
    final systemNavItem = find.text('System').last;
    await tester.tap(systemNavItem);
    await tester.pumpAndSettle();

    // Verify System Console tab & Redesigned Staff Management
    expect(find.text('DATABASE ARCHITECTURE'), findsNothing);
    expect(find.text('STAFF & ROLE ACCESS CONTROL'), findsOneWidget);
    expect(find.text('Head Admin'), findsWidgets);
    expect(find.text('Admin'), findsWidgets);
    expect(find.text('Moderator'), findsWidgets);

    // Initial selected role is Head Admin
    expect(find.text('Head Admin Control'), findsOneWidget);
    expect(find.text('Supreme Authority'), findsOneWidget);

    // Tap on Moderator role button to test interactive role switching
    final moderatorButton = find.text('Moderator').first;
    await tester.tap(moderatorButton);
    await tester.pumpAndSettle();

    // Verify Moderator console and permissions
    expect(find.text('Moderator Console'), findsOneWidget);
    expect(find.text('Review Kitchens'), findsOneWidget);
    expect(find.text('+ Add Moderator'), findsOneWidget);

    // Test switching to Vouchers Menu
    final vouchersMenuPill = find.text('Vouchers').first;
    await tester.tap(vouchersMenuPill);
    await tester.pumpAndSettle();
    expect(find.text('PLATFORM VOUCHERS'), findsOneWidget);
    expect(find.text('Zero Restaurant Deduction Guarantee'), findsOneWidget);
    expect(find.text('+ New Code'), findsOneWidget);

    // Test switching to Rewards Menu
    final rewardsMenuPill = find.text('Rewards').first;
    await tester.tap(rewardsMenuPill);
    await tester.pumpAndSettle();
    expect(find.text('CUSTOMER REWARDS'), findsOneWidget);
    expect(find.text('+ Post Reward'), findsOneWidget);

    // Test switching to Telemetry Menu
    final telemetryMenuPill = find.text('Telemetry').first;
    await tester.tap(telemetryMenuPill);
    await tester.pumpAndSettle();
    expect(find.text('SYSTEM HEALTH & TELEMETRY'), findsOneWidget);
    expect(find.text('SUPABASE BACKEND ARCHITECTURE'), findsOneWidget);
    expect(find.text('Realtime Sync'), findsOneWidget);

    // Test switching to Security Menu
    final securityMenuPill = find.text('Security').first;
    await tester.tap(securityMenuPill);
    await tester.pumpAndSettle();
    expect(find.text('SECURITY & GOVERNANCE'), findsOneWidget);
    expect(find.text('AUTHENTICATION INTEGRITY'), findsOneWidget);
    expect(find.text('System Security Audit Log'), findsOneWidget);

    // Test switching back to Staff Access Menu
    final staffMenuPill = find.text('Staff Access').first;
    await tester.tap(staffMenuPill);
    await tester.pumpAndSettle();
    expect(find.text('STAFF & ROLE ACCESS CONTROL'), findsOneWidget);
  });

  testWidgets('AdminDashboardScreen Banners tab renders Partner Banner Requests and Slots',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Tap on Banners quick command
    final bannersCmd = find.text('Banners').first;
    await tester.tap(bannersCmd);
    await tester.pumpAndSettle();

    // Verify Banners tab renders Homepage Carousel banners and Partner Banner Requests
    expect(find.text('ACTIVE CAROUSEL BANNERS'), findsOneWidget);
    expect(find.text('PARTNER BANNER REQUESTS'), findsOneWidget);
  });

  testWidgets('Quick Access Commands open Vouchers, Rewards, and Reviews modals properly',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // 1. Test Vouchers Quick Access Command navigates to SS 1 (Platform Vouchers screen)
    final vouchersCmd = find.text('Vouchers').first;
    await tester.tap(vouchersCmd);
    await tester.pumpAndSettle();

    expect(find.text('PLATFORM VOUCHERS'), findsOneWidget);
    expect(find.text('Zero Restaurant Deduction Guarantee'), findsOneWidget);
    expect(find.text('+ New Code'), findsOneWidget);

    // Test opening Advanced Voucher Studio modal from Platform Vouchers screen
    final advancedStudioBtn =
        find.text('Open Advanced Voucher Management Studio');
    await tester.ensureVisible(advancedStudioBtn);
    await tester.tap(advancedStudioBtn);
    await tester.pumpAndSettle();

    expect(find.text('Promo Codes & Vouchers'), findsOneWidget);
    expect(find.text('Setup Code'), findsOneWidget);

    // Verify Tab Switching between Vouchers and Rewards inside the popup
    final rewardsTabPill = find.text('🎁 Rewards & Perks').first;
    await tester.tap(rewardsTabPill);
    await tester.pumpAndSettle();

    expect(find.text('Customer Rewards Manager'), findsOneWidget);
    expect(find.text('Post Reward'), findsOneWidget);

    final vouchersTabPill = find.textContaining('🎟️ Promo Vouchers').first;
    await tester.tap(vouchersTabPill);
    await tester.pumpAndSettle();

    expect(find.text('Promo Codes & Vouchers'), findsOneWidget);
    expect(find.text('Setup Code'), findsOneWidget);

    // Dismiss Vouchers sheet
    Navigator.of(tester.element(find.text('Promo Codes & Vouchers'))).pop();
    await tester.pumpAndSettle();

    // Switch back to Dashboard Overview tab (Tab 0) to access Quick Access Commands
    final overviewNav = find.text('Overview').last;
    await tester.tap(overviewNav);
    await tester.pumpAndSettle();

    // 2. Test Rewards Quick Access Command navigates to Customer Rewards section
    final rewardsCmd = find.text('Rewards').first;
    await tester.tap(rewardsCmd);
    await tester.pumpAndSettle();

    expect(find.text('CUSTOMER REWARDS'), findsOneWidget);
    expect(find.text('+ Post Reward'), findsOneWidget);

    // Open Advanced Rewards Studio modal from Customer Rewards section
    final advancedRewardsBtn =
        find.text('Open Advanced Rewards Studio');
    await tester.ensureVisible(advancedRewardsBtn);
    await tester.tap(advancedRewardsBtn);
    await tester.pumpAndSettle();

    expect(find.text('Customer Rewards Manager'), findsOneWidget);
    expect(find.text('Post Reward'), findsOneWidget);

    // Dismiss Rewards sheet
    Navigator.of(tester.element(find.text('Customer Rewards Manager'))).pop();
    await tester.pumpAndSettle();

    // Switch back to Dashboard Overview tab (Tab 0) to access Quick Access Commands
    final overviewNav2 = find.text('Overview').last;
    await tester.tap(overviewNav2);
    await tester.pumpAndSettle();

    // 3. Test Reviews Quick Access Command
    final reviewsCmd = find.text('Reviews').first;
    await tester.tap(reviewsCmd);
    await tester.pumpAndSettle();

    expect(find.text('Customer Reviews & Ratings'), findsOneWidget);
    expect(find.text('All Reviews'), findsOneWidget);
    expect(find.text('5★ Top Rated'), findsOneWidget);
    expect(find.text('Verified Only'), findsOneWidget);

    // Dismiss Reviews sheet
    Navigator.of(tester.element(find.text('Customer Reviews & Ratings'))).pop();
    await tester.pumpAndSettle();
  });

  testWidgets('Quick Access Commands open properly with full GoRouter setup', (tester) async {
    const adminProfile = UserProfile(
      id: 'admin-1',
      email: 'admin@savebite.com',
      role: AppConstants.roleAdmin,
      fullName: 'SaveBite Operations Director',
      phone: '01700000000',
      isActive: true,
    );

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProfileProvider.overrideWith(
            () => FakeCurrentUserNotifier(adminProfile),
          ),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            final router = ref.watch(routerProvider);
            return MaterialApp.router(
              routerConfig: router,
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final router = ProviderScope.containerOf(tester.element(find.byType(MaterialApp))).read(routerProvider);
    router.go(AppRoutes.adminDashboard);
    await tester.pumpAndSettle();

    // Tap on Vouchers
    final vouchersCmd = find.text('Vouchers').first;
    await tester.tap(vouchersCmd);
    await tester.pumpAndSettle();

    expect(find.text('PLATFORM VOUCHERS'), findsOneWidget);
    expect(find.text('Zero Restaurant Deduction Guarantee'), findsOneWidget);
    expect(find.text('+ New Code'), findsOneWidget);
  });
}

