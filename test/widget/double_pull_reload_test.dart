import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:save_bite/core/widgets/double_pull_reload.dart';

void main() {
  testWidgets('DoublePullReload triggers onReload only after pulling down twice within 2 seconds', (tester) async {
    int reloadCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DoublePullReload(
            onReload: () async {
              reloadCount++;
            },
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Container(
                height: 1000,
                width: double.infinity,
                color: Colors.blue,
                child: const Text('Top Content'),
              ),
            ),
          ),
        ),
      ),
    );

    expect(reloadCount, 0);

    // 1. First pull down at top
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, 80));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify hint message appears and reload has NOT fired
    expect(find.text('Pull down once more to reload'), findsOneWidget);
    expect(reloadCount, 0);

    // 2. Second pull down within 2 seconds
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, 80));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify reload triggered
    expect(reloadCount, 1);
    expect(find.text('Reloading...'), findsOneWidget);

    // Let snackbar and timers finish
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('DoublePullReload ignores pull down when scrolled down away from top', (tester) async {
    int reloadCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DoublePullReload(
            onReload: () async {
              reloadCount++;
            },
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Container(
                height: 2000,
                width: double.infinity,
                color: Colors.blue,
                child: const Text('Top Content'),
              ),
            ),
          ),
        ),
      ),
    );

    // Scroll down by 300px
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();

    // Pull down while scrolled down
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, 80));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Should NOT show hint message or trigger reload
    expect(find.text('Pull down once more to reload'), findsNothing);
    expect(reloadCount, 0);
  });
}
