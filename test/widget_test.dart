import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:save_bite/core/constants/app_constants.dart';
import 'package:save_bite/features/auth/data/auth_repository.dart';
import 'package:save_bite/main.dart';

import 'helpers/fake_auth_repository.dart';

void main() {
  testWidgets('SaveBiteApp smoke test - renders splash screen on startup', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: const SaveBiteApp(),
      ),
    );

    // Pump a frame to build the router and initial splash screen
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Router resolves unauthenticated state to login screen
    expect(find.textContaining(AppConstants.appName), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
  });
}
