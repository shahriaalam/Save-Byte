import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:save_bite/core/constants/app_constants.dart';
import 'package:save_bite/core/theme/app_theme.dart';
import 'package:save_bite/features/admin/dashboard/admin_dashboard_screen.dart';
import 'package:save_bite/features/auth/data/auth_repository.dart';
import 'package:save_bite/features/auth/domain/user_profile.dart';
import 'package:save_bite/features/auth/presentation/auth_controller.dart';
import 'package:save_bite/features/shared/models/promo_banner.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_auth_repository.dart';

class _FakeCurrentUserNotifier extends CurrentUserNotifier {
  _FakeCurrentUserNotifier(this.profile);
  final UserProfile? profile;

  @override
  UserProfile? build() => profile;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Admin banner edit sheet opens, edits fields and saves cleanly',
      (tester) async {
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
              .overrideWith(() => _FakeCurrentUserNotifier(adminProfile)),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AdminDashboardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Switch to Banners tab (index 3)
    final bannersTab = find.text('Banners').last;
    await tester.tap(bannersTab);
    await tester.pumpAndSettle();

    // 2. Tap Edit on Slot #1
    final editButton = find.text('Edit').first;
    expect(editButton, findsWidgets);
    await tester.tap(editButton);
    await tester.pumpAndSettle();

    // 3. Verify Edit Sheet UI and all fields are present
    expect(find.text('LIVE PREVIEW'), findsOneWidget);
    expect(find.text('Banner Headline / Name *'), findsOneWidget);
    expect(find.text('Description / Subtitle'), findsOneWidget);
    expect(find.text('Badge Tag'), findsOneWidget);
    expect(find.text('Coupon / Code'), findsOneWidget);
    expect(find.text('Background Color Theme'), findsOneWidget);
    expect(find.text('Save Banner Changes'), findsOneWidget);

    // 4. Edit headline
    final headlineInput = find.widgetWithText(
      TextField,
      PromoBanner.defaultBanners.first.bannerName,
    );
    await tester.enterText(
      headlineInput,
      'North End Special Blend - 20% OFF',
    );
    await tester.pumpAndSettle();

    // 5. Select Teal Mart theme (emoji: 🥬)
    final tealTheme = find.text('Teal Mart (SS 3)');
    expect(tealTheme, findsOneWidget);
    await tester.ensureVisible(tealTheme);
    await tester.pumpAndSettle();
    await tester.tap(tealTheme);
    await tester.pumpAndSettle();

    // 6. Tap "Save Banner Changes"
    final saveButton = find.text('Save Banner Changes');
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // 7. Verify sheet is dismissed and new banner title is displayed on dashboard
    expect(find.text('Save Banner Changes'), findsNothing);
    expect(find.text('North End Special Blend - 20% OFF'), findsOneWidget);
  });
}
