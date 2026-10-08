import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:save_bite/core/theme/app_theme.dart';
import 'package:save_bite/core/widgets/app_text_field.dart';
import 'package:save_bite/core/widgets/empty_state.dart';
import 'package:save_bite/core/widgets/error_state.dart';
import 'package:save_bite/core/widgets/loading_state.dart';
import 'package:save_bite/core/widgets/primary_button.dart';
import 'package:save_bite/core/widgets/secondary_button.dart';
import 'package:save_bite/core/widgets/status_badge.dart';

Widget createTestApp(Widget child) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: Scaffold(body: child),
  );
}

void main() {
  group('Core Reusable Widgets', () {
    testWidgets('PrimaryButton renders and triggers callback', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        createTestApp(
          PrimaryButton(text: 'Click Me', onPressed: () => pressed = true),
        ),
      );

      expect(find.text('Click Me'), findsOneWidget);
      await tester.tap(find.text('Click Me'));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets(
      'PrimaryButton displays loading indicator when isLoading is true',
      (tester) async {
        var pressed = false;
        await tester.pumpWidget(
          createTestApp(
            PrimaryButton(
              text: 'Submit',
              isLoading: true,
              onPressed: () => pressed = true,
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Submit'), findsNothing);

        // Tapping while loading should not trigger onPressed
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();
        expect(pressed, isFalse);
      },
    );

    testWidgets('SecondaryButton renders text and triggers callback', (
      tester,
    ) async {
      var pressed = false;
      await tester.pumpWidget(
        createTestApp(
          SecondaryButton(text: 'Cancel', onPressed: () => pressed = true),
        ),
      );

      expect(find.text('Cancel'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      expect(pressed, isTrue);
    });

    testWidgets('AppTextField displays label and hint', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AppTextField(label: 'Email', hint: 'Enter your email'),
        ),
      );

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Enter your email'), findsOneWidget);
    });

    testWidgets('LoadingState renders message and indicator', (tester) async {
      await tester.pumpWidget(
        createTestApp(const LoadingState(message: 'Fetching offers...')),
      );

      expect(find.text('Fetching offers...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('EmptyState renders message and action button', (tester) async {
      var refreshed = false;
      await tester.pumpWidget(
        createTestApp(
          EmptyState(
            title: 'No Offers Available',
            message: 'Check back later for fresh food offers.',
            actionText: 'Refresh',
            onAction: () => refreshed = true,
          ),
        ),
      );

      expect(find.text('No Offers Available'), findsOneWidget);
      expect(
        find.text('Check back later for fresh food offers.'),
        findsOneWidget,
      );
      expect(find.text('Refresh'), findsOneWidget);

      await tester.tap(find.text('Refresh'));
      await tester.pump();
      expect(refreshed, isTrue);
    });

    testWidgets('ErrorState renders error message and retry button', (
      tester,
    ) async {
      var retried = false;
      await tester.pumpWidget(
        createTestApp(
          ErrorState(
            message: 'Could not connect to server.',
            onRetry: () => retried = true,
          ),
        ),
      );

      expect(find.text('Could not connect to server.'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      await tester.tap(find.text('Try Again'));
      await tester.pump();
      expect(retried, isTrue);
    });

    testWidgets('StatusBadge renders appropriate text for status', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          Column(
            children: [
              StatusBadge.fromStatus('approved'),
              StatusBadge.fromStatus('pending'),
              StatusBadge.fromStatus('suspended'),
            ],
          ),
        ),
      );

      expect(find.text('APPROVED'), findsOneWidget);
      expect(find.text('PENDING'), findsOneWidget);
      expect(find.text('SUSPENDED'), findsOneWidget);
    });
  });
}
