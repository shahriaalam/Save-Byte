import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:save_bite/features/customer/profile/data/customer_membership_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CustomerMembershipController Tests', () {
    test('initial state has isSuperSaver as false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(customerMembershipProvider);
      expect(state.isSuperSaver, isFalse);
      expect(state.expiresAt, isNull);
    });

    test('activateMembership turns isSuperSaver to true and sets expiry date', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(customerMembershipProvider.notifier).activateMembership(
            amount: 99.0,
            plan: 'Super Saver Monthly',
          );

      final state = container.read(customerMembershipProvider);
      expect(state.isSuperSaver, isTrue);
      expect(state.planName, 'Super Saver Monthly');
      expect(state.lastPaidAmount, 99.0);
      expect(state.expiresAt, isNotNull);
      expect(state.expiresAt!.isAfter(DateTime.now()), isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('customer_is_super_saver'), isTrue);
    });

    test('cancelMembership reverts isSuperSaver to false', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(customerMembershipProvider.notifier);
      await notifier.activateMembership();
      expect(container.read(customerMembershipProvider).isSuperSaver, isTrue);

      await notifier.cancelMembership();
      final state = container.read(customerMembershipProvider);
      expect(state.isSuperSaver, isFalse);
      expect(state.expiresAt, isNull);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('customer_is_super_saver'), isFalse);
    });
  });
}
