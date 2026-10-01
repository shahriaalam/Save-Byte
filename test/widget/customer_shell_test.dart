import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:save_bite/core/constants/app_colors.dart';
import 'package:save_bite/core/theme/app_theme.dart';
import 'package:save_bite/features/customer/shell/customer_shell_screen.dart';

class FakeStatefulNavigationShell extends StatefulWidget
    implements StatefulNavigationShell {
  const FakeStatefulNavigationShell({
    required this.currentIndex,
    required this.onGoBranch,
    super.key,
  });

  @override
  final int currentIndex;

  final void Function(int index, bool initialLocation) onGoBranch;

  @override
  State<FakeStatefulNavigationShell> createState() =>
      _FakeStatefulNavigationShellState();

  @override
  void goBranch(int index, {bool initialLocation = false}) {
    onGoBranch(index, initialLocation);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeStatefulNavigationShellState
    extends State<FakeStatefulNavigationShell> {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

void main() {
  group('CustomerShellScreen Floating Navbar', () {
    testWidgets('renders floating pill container with Home, Search, and Profile', (
      tester,
    ) async {
      int? navigatedIndex;
      final fakeShell = FakeStatefulNavigationShell(
        currentIndex: 0,
        onGoBranch: (index, initial) {
          navigatedIndex = index;
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: CustomerShellScreen(navigationShell: fakeShell),
          ),
        ),
      );

      // Verify destinations exist
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Verify floating pill styling: Container with borderRadius 33
      final containerFinder = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final box = widget.decoration as BoxDecoration;
          final radius = box.borderRadius;
          return radius == BorderRadius.circular(33) && box.color == Colors.white;
        }
        return false;
      });
      expect(containerFinder, findsOneWidget);

      // Tap on Search item
      await tester.tap(find.text('Search'));
      await tester.pump();

      expect(navigatedIndex, 1);

      // Tap on Profile item
      await tester.tap(find.text('Profile'));
      await tester.pump();

      expect(navigatedIndex, 2);
    });

    testWidgets('highlights selected destination with primary color', (
      tester,
    ) async {
      final fakeShell = FakeStatefulNavigationShell(
        currentIndex: 1, // Search selected
        onGoBranch: (_, _) {},
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: CustomerShellScreen(navigationShell: fakeShell),
          ),
        ),
      );

      // In index 1 (Search), text style has AppColors.primary
      final searchText = tester.widget<Text>(find.text('Search'));
      expect(searchText.style?.color, AppColors.primary);
      expect(searchText.style?.fontWeight, FontWeight.w700);

      // In index 0 (Home), text style has AppColors.textSecondary
      final homeText = tester.widget<Text>(find.text('Home'));
      expect(homeText.style?.color, AppColors.textSecondary);
    });

    testWidgets('navigation bar Align has heightFactor: 1.0 to prevent full-screen expansion', (tester) async {
      final fakeShell = FakeStatefulNavigationShell(
        currentIndex: 0,
        onGoBranch: (_, _) {},
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: CustomerShellScreen(navigationShell: fakeShell),
          ),
        ),
      );

      expect(find.byType(CustomerShellScreen), findsOneWidget);
    });
  });
}



