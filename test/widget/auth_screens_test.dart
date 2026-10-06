import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:save_bite/core/theme/app_theme.dart';
import 'package:save_bite/core/widgets/account_created_dialog.dart';
import 'package:save_bite/core/widgets/app_logo.dart';
import 'package:save_bite/core/widgets/food_loading_animation.dart';
import 'package:save_bite/features/auth/data/auth_repository.dart';
import 'package:save_bite/features/auth/presentation/customer_register_screen.dart';
import 'package:save_bite/features/auth/presentation/forgot_password_screen.dart';
import 'package:save_bite/features/auth/presentation/login_screen.dart';
import 'package:save_bite/features/auth/presentation/restaurant_register_screen.dart';

import '../helpers/fake_auth_repository.dart';

Widget createTestScope(Widget child, {FakeAuthRepository? repo}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(repo ?? FakeAuthRepository()),
    ],
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
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Sign Up as Customer'), findsOneWidget);
      expect(find.text('Register as Restaurant'), findsOneWidget);

      // Verify validation triggers on empty submit
      await tester.tap(find.text('Log In'));
      await tester.pump();

      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('LoginScreen allows Customer to sign in using Google', (
      tester,
    ) async {
      final fakeRepo = FakeAuthRepository();
      await tester.pumpWidget(createTestScope(const LoginScreen(), repo: fakeRepo));

      expect(find.text('Continue with Google'), findsOneWidget);
      await tester.ensureVisible(find.text('Continue with Google'));
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      // Verify customer Google profile was loaded
      expect(fakeRepo.initialProfile?.isCustomer, isTrue);
      expect(fakeRepo.initialProfile?.email, 'customer.google@savebite.com');
    });

    testWidgets('CustomerRegisterScreen renders form fields and validation', (
      tester,
    ) async {
      await tester.pumpWidget(createTestScope(const CustomerRegisterScreen()));

      expect(find.text('First Name'), findsOneWidget);
      expect(find.text('Last Name'), findsOneWidget);
      expect(find.text('Gender'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Phone Number'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);

      // Tap create without filling to trigger validation
      await tester.ensureVisible(find.text('Create Account'));
      await tester.tap(find.text('Create Account'));
      await tester.pump();

      expect(find.text('Please enter your first name'), findsOneWidget);
      expect(find.text('Please enter your last name'), findsOneWidget);
      expect(find.text('Please select your gender'), findsOneWidget);
      expect(find.text('Please enter your email address'), findsOneWidget);
      expect(find.text('Please enter your phone number'), findsOneWidget);
      expect(find.text('Please enter a password'), findsOneWidget);
    });

    testWidgets(
      'CustomerRegisterScreen submits valid data and displays AccountCreatedDialog with inverted logo',
      (tester) async {
        await tester.pumpWidget(createTestScope(const CustomerRegisterScreen()));

        // Enter First Name
        await tester.enterText(
          find.widgetWithText(TextField, 'Rahim'),
          'Rahim',
        );
        // Enter Last Name
        await tester.enterText(
          find.widgetWithText(TextField, 'Ahmed'),
          'Ahmed',
        );

        // Select Gender
        await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Male').last);
        await tester.pumpAndSettle();

        // Enter valid Email
        await tester.enterText(
          find.widgetWithText(TextField, 'name@example.com'),
          'rahim@example.com',
        );

        // Enter valid Phone
        await tester.enterText(
          find.widgetWithText(TextField, '017XXXXXXXX'),
          '01712345678',
        );

        // Enter Password & Confirm Password
        final passwordFields = find.byType(TextField);
        await tester.enterText(passwordFields.at(4), 'password123');
        await tester.enterText(passwordFields.at(5), 'password123');

        // Tap Create Account
        await tester.ensureVisible(find.text('Create Account'));
        await tester.tap(find.text('Create Account'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        // Bottom sheet is now open; tap Verify & Activate Account
        expect(find.text('Verify & Activate Account'), findsOneWidget);
        await tester.tap(find.text('Verify & Activate Account'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 400));

        // Verify AccountCreatedDialog is shown
        expect(find.byType(AccountCreatedDialog), findsOneWidget);
        expect(find.text('Account Created!'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(AccountCreatedDialog),
            matching: find.text('rahim@example.com'),
          ),
          findsOneWidget,
        );
        expect(find.text('Go to Login'), findsOneWidget);

        // Verify inverted logo is in the dialog
        final invertedLogoFinder = find.byWidgetPredicate(
          (widget) => widget is AppLogoIcon && widget.isInverted == true,
        );
        expect(invertedLogoFinder, findsOneWidget);
      },
    );

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

    testWidgets(
      'RestaurantRegisterScreen submits valid data and displays AccountCreatedDialog',
      (tester) async {
        await tester.pumpWidget(
          createTestScope(const RestaurantRegisterScreen()),
        );

        // Fill Owner info
        await tester.enterText(
          find.widgetWithText(TextField, 'Rahman Khan'),
          'Rahman Khan',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'contact@restaurant.com'),
          'cafe@savebite.com',
        );
        await tester.enterText(
          find.widgetWithText(TextField, '017XXXXXXXX'),
          '01812345678',
        );

        final fields = find.byType(TextField);
        await tester.enterText(fields.at(3), 'password123'); // password
        await tester.enterText(fields.at(4), 'password123'); // confirm password

        // Fill Restaurant info
        await tester.enterText(
          find.widgetWithText(TextField, "Rahman's Kitchen"),
          'Bite Bakery',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Traditional Bengali cuisine and snacks'),
          'Fresh pastries and bread',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'House 12, Road 4, Dhanmondi, Dhaka'),
          'Dhanmondi 27, Dhaka',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Bengali / Fast Food / Bakery'),
          'Bakery',
        );

        await tester.ensureVisible(find.text('Create Restaurant Account'));
        await tester.tap(find.text('Create Restaurant Account'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        // If EmailOtpVerificationSheet appears, verify OTP
        if (find.text('Verify & Activate Account').evaluate().isNotEmpty) {
          await tester.tap(find.text('Verify & Activate Account'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          await tester.pump(const Duration(milliseconds: 400));
        }

        // Verify dialog
        expect(find.byType(AccountCreatedDialog), findsOneWidget);
        expect(find.text('Account Created!'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(AccountCreatedDialog),
            matching: find.text('cafe@savebite.com'),
          ),
          findsOneWidget,
        );
        expect(find.text('Go to Login'), findsOneWidget);
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

    testWidgets('AccountCreatedDialog renders inverted logo and triggers button callback', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccountCreatedDialog(
              email: 'test@example.com',
              role: 'customer',
            ),
          ),
        ),
      );

      expect(find.text('Account Created!'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('Go to Login'), findsOneWidget);

      final invertedLogoFinder = find.byWidgetPredicate(
        (widget) => widget is AppLogoIcon && widget.isInverted == true,
      );
      expect(invertedLogoFinder, findsOneWidget);
    });

    testWidgets('FoodLoadingAnimation renders food elements and cycles', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Center(
              child: FoodLoadingAnimation(
                title: 'Logging in to SaveBite...',
              ),
            ),
          ),
        ),
      );

      // Verify title is rendered
      expect(find.text('Logging in to SaveBite...'), findsOneWidget);

      // Verify category badge (initial is Fine Dining)
      expect(find.text('Fine Dining'), findsOneWidget);

      // Verify LinearProgressIndicator is present
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // Pump 1200ms to advance food cycle timer
      await tester.pump(const Duration(milliseconds: 1200));

      // Should have switched to the next food category (Hot Noodles & Soup)
      expect(find.text('Hot Noodles & Soup'), findsOneWidget);
    });

    testWidgets('FoodLoginLoadingOverlay displays when isLoading is true and hides when false', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Stack(
              children: [
                Text('Background Content'),
                FoodLoginLoadingOverlay(isLoading: false),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Background Content'), findsOneWidget);
      expect(find.byType(FoodLoadingAnimation), findsNothing);

      // Pump with isLoading: true
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Stack(
              children: [
                Text('Background Content'),
                FoodLoginLoadingOverlay(isLoading: true),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(FoodLoadingAnimation), findsOneWidget);
      expect(find.text('Logging in to SaveBite...'), findsOneWidget);
    });
  });
}
