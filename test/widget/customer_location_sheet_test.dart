import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:save_bite/core/theme/app_theme.dart';
import 'package:save_bite/features/customer/location/widgets/customer_location_sheet.dart';
import 'package:save_bite/features/customer/location/widgets/google_map_preview.dart';

void main() {
  testWidgets('CustomerLocationSheet renders country, current location, map card and add address',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: CustomerLocationSheet(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify country row
    expect(find.text('Bangladesh'), findsOneWidget);
    expect(find.text('Change'), findsOneWidget);

    // 2. Verify current location option
    expect(find.text('Use my current location'), findsOneWidget);

    // 3. Verify Home card and GoogleMapPreview
    expect(find.byType(GoogleMapPreview), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('2B, House 32, Road 3, Block C Road 3'), findsOneWidget);
    expect(find.text('Dhaka'), findsOneWidget);

    // 4. Verify Google branding & landmark inside map
    expect(find.text('আইডিয়াল স্কুল অ্যান্ড কলেজ'), findsOneWidget);

    // 5. Verify Add New Address action
    expect(find.text('Add New Address'), findsOneWidget);
  });

  testWidgets('CustomerLocationSheet tapping Add New Address opens new address form',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: CustomerLocationSheet(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Add New Address
    await tester.tap(find.text('Add New Address'));
    await tester.pumpAndSettle();

    // Verify form fields
    expect(find.text('Address Label'), findsOneWidget);
    expect(find.text('Save & Select Address'), findsOneWidget);
  });
}
