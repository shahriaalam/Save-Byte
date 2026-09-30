import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:save_bite/core/theme/app_theme.dart';
import 'package:save_bite/features/auth/data/auth_repository.dart';
import 'package:save_bite/features/auth/presentation/customer_register_screen.dart';
import 'package:save_bite/features/auth/presentation/forgot_password_screen.dart';
import 'package:save_bite/features/auth/presentation/login_screen.dart';
import 'package:save_bite/features/auth/presentation/restaurant_register_screen.dart';

import '../helpers/fake_auth_repository.dart';

Widget createTestScope(Widget child) {
  return ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(FakeAuthRepository())],
    child: MaterialApp(theme: AppTheme.lightTheme, home: child),
  );
}

void main() {
  group('Authentication Screens', () {
    testWidgets('LoginScreen renders email and password fields and buttons', (
      tester,
    ) async {
      await tester.pumpWidget(createTestScope(const LoginScreen()));

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Log In'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('Sign Up as Customer'), findsOneWidget);
      expect(find.text('Register as Restaurant'), findsOneWidget);

      // Verify validation triggers on empty submit
      await tester.tap(find.text('Log In'));
      await tester.pump();

      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('CustomerRegisterScreen renders form fields and validation', (
      tester,
    ) async {
      await tester.pumpWidget(createTestScope(const CustomerRegisterScreen()));

      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Phone Number (Optional)'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);

      // Tap create without filling to trigger validation
      await tester.ensureVisible(find.text('Create Account'));
      await tester.tap(find.text('Create Account'));
      await tester.pump();

      expect(find.text('Please enter your name'), findsOneWidget);
      expect(find.text('Please enter your email'), findsOneWidget);
    });

    testWidgets(
      'RestaurantRegisterScreen renders owner and restaurant fields and notice',
      (tester) async {
        await tester.pumpWidget(
          createTestScope(const RestaurantRegisterScreen()),
        );

        expect(find.text('Owner Full Name'), findsOneWidget);
        expect(find.text('Contact Email'), findsOneWidget);
        expect(find.text('Phone Number'), findsOneWidget);
        expect(find.text('Restaurant Name'), findsOneWidget);
        expect(find.text('Description'), findsOneWidget);
        expect(find.text('Address'), findsOneWidget);
        expect(find.text('Cuisine Type'), findsOneWidget);
        expect(find.text('Create Restaurant Account'), findsOneWidget);

        // Verify pending review notice is visible (Section 30)
        expect(
          find.textContaining(
            'Restaurant accounts are registered with pending status',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('ForgotPasswordScreen renders email field and back link', (
      tester,
    ) async {
      await tester.pumpWidget(createTestScope(const ForgotPasswordScreen()));

      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('Send Reset Link'), findsOneWidget);
      expect(find.text('Back to Login'), findsOneWidget);

      await tester.tap(find.text('Send Reset Link'));
      await tester.pump();

      expect(find.text('Please enter your email'), findsOneWidget);
    });
  });
}
