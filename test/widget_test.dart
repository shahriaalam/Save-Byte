import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:save_bite/core/constants/app_constants.dart';
import 'package:save_bite/main.dart';

void main() {
  testWidgets('SaveBiteApp smoke test - renders splash screen on startup', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: SaveBiteApp()));

    // Pump a frame to build the router and initial splash screen
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(find.text(AppConstants.appTagline), findsOneWidget);
  });
}
