import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:save_bite/features/customer/hot_deals/customer_hot_deals_screen.dart';
import 'package:save_bite/features/customer/location/user_location_controller.dart';
import 'package:save_bite/features/customer/location/widgets/location_permission_sheet.dart';
import 'package:save_bite/features/customer/offers/data/customer_offer_repository.dart';
import 'package:save_bite/features/customer/offers/presentation/customer_offers_controller.dart';
import 'package:save_bite/features/shared/widgets/offer_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

void main() {
  final testOfferRepo = CustomerOfferRepository(
    supa.SupabaseClient(
      'https://placeholder.supabase.co',
      'placeholder-anon-key',
      authOptions: const supa.AuthClientOptions(autoRefreshToken: false),
    ),
    useDemoDataOnly: true,
  );

  testWidgets('LocationPermissionSheet renders benefits and buttons correctly', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: LocationPermissionSheet(),
          ),
        ),
      ),
    );

    expect(find.text('Find 45%+ Hot Deals Near You'), findsOneWidget);
    expect(find.text('Allow Location & Find Deals'), findsOneWidget);
    expect(find.text('Choose Dhaka Area Manually'), findsNothing);
    expect(find.text('Exclusive 45% or more surplus food discounts'), findsOneWidget);
  });

  testWidgets('CustomerHotDealsScreen filters for 45%+ deals near detected location', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customerOfferRepositoryProvider.overrideWithValue(testOfferRepo),
        ],
        child: const MaterialApp(
          home: CustomerHotDealsScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify 45%+ OFF badge and header
    expect(find.text('45%+ OFF'), findsOneWidget);
    expect(find.textContaining('Hot Deals'), findsWidgets);
    expect(find.byType(OfferCard), findsWidgets);
  });

  testWidgets('Setting location to Dhanmondi updates Hot Deals to Dhanmondi 45%+ offers', (tester) async {
    final container = ProviderContainer(
      overrides: [
        customerOfferRepositoryProvider.overrideWithValue(testOfferRepo),
      ],
    );
    addTearDown(container.dispose);

    // Initial state
    container.read(userLocationControllerProvider.notifier).setManualArea('Dhanmondi');

    expect(container.read(homeAreaProvider), equals('Dhanmondi'));

    final deals = await container.read(hotDealsProvider.future);
    // Every deal in Hot Deals must have discountPercentage >= 45
    for (final deal in deals) {
      expect(deal.discountPercentage, greaterThanOrEqualTo(45));
      expect(deal.area, equals('Dhanmondi'));
    }
  });
}
