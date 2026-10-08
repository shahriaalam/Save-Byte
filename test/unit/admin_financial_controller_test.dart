import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:save_bite/features/shared/data/admin_financial_controller.dart';

void main() {
  group('AdminFinancialController Tests', () {
    test('initial state contains baseline stats and historical data', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(adminFinancialProvider);
      expect(state.monthlySubscriptionEarnings, greaterThan(0));
      expect(state.totalPlatformEarnings, greaterThan(0));
      expect(state.totalPartners, greaterThan(0));
      expect(state.bannerRuns.isNotEmpty, isTrue);
      expect(state.monthlyHistory.isNotEmpty, isTrue);
      expect(state.revenueSlices.isNotEmpty, isTrue);
    });

    test('recording a subscription payment updates earnings and transaction history', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initialMonthly =
          container.read(adminFinancialProvider).monthlySubscriptionEarnings;
      final initialTotal =
          container.read(adminFinancialProvider).totalPlatformEarnings;
      final initialTxCount =
          container.read(adminFinancialProvider).recentTransactions.length;

      container.read(adminFinancialProvider.notifier).recordSubscriptionPayment(
            payerName: 'Kacchi Express',
            payerType: 'restaurant',
            planName: 'Gold Merchant Monthly',
            amount: 999.0,
            paymentGateway: 'bKash',
            transactionId: 'BK-TEST-1234',
          );

      final updatedState = container.read(adminFinancialProvider);
      expect(updatedState.monthlySubscriptionEarnings, initialMonthly + 999.0);
      expect(updatedState.totalPlatformEarnings, initialTotal + 999.0);
      expect(updatedState.recentTransactions.length, initialTxCount + 1);

      final newestTx = updatedState.recentTransactions.first;
      expect(newestTx.payerName, 'Kacchi Express');
      expect(newestTx.amount, 999.0);
      expect(newestTx.paymentGateway, 'bKash');
      expect(newestTx.transactionId, 'BK-TEST-1234');
      expect(newestTx.isSuccessful, isTrue);
    });

    test('recording customer VIP payment updates super saver count', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initialVipCount =
          container.read(adminFinancialProvider).activeSuperSaverMembers;

      container.read(adminFinancialProvider.notifier).recordSubscriptionPayment(
            payerName: 'Rahim Khan',
            payerType: 'customer',
            planName: 'Super Saver VIP Club',
            amount: 99.0,
            paymentGateway: 'Nagad',
            transactionId: 'NG-TEST-9988',
          );

      final updatedState = container.read(adminFinancialProvider);
      expect(updatedState.activeSuperSaverMembers, initialVipCount + 1);
    });

    test('updatePartnerCounts updates partner status breakdown correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(adminFinancialProvider.notifier).updatePartnerCounts(
            total: 25,
            gold: 15,
            verified: 20,
            pending: 5,
          );

      final state = container.read(adminFinancialProvider);
      expect(state.totalPartners, 25);
      expect(state.activeGoldMerchants, 15);
      expect(state.verifiedPartners, 20);
      expect(state.pendingPartners, 5);
    });
  });
}
