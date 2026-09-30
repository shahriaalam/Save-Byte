import 'package:flutter_test/flutter_test.dart';
import 'package:save_bite/core/utils/validators.dart';

void main() {
  group('AppValidators', () {
    test('validateEmail validates valid and invalid emails', () {
      expect(AppValidators.validateEmail('user@savebite.com'), isNull);
      expect(AppValidators.validateEmail('customer.name@domain.co'), isNull);
      expect(AppValidators.validateEmail(''), isNotNull);
      expect(AppValidators.validateEmail('   '), isNotNull);
      expect(AppValidators.validateEmail('plainaddress'), isNotNull);
      expect(AppValidators.validateEmail('@missingusername.com'), isNotNull);
      expect(AppValidators.validateEmail('user@.com'), isNotNull);
    });

    test('validatePhone validates Bangladeshi and international formats', () {
      // Valid Bangladeshi numbers
      expect(AppValidators.validatePhone('01712345678'), isNull);
      expect(AppValidators.validatePhone('+8801812345678'), isNull);
      expect(AppValidators.validatePhone('8801912345678'), isNull);
      expect(AppValidators.validatePhone('01300000000'), isNull);

      // Valid International numbers
      expect(AppValidators.validatePhone('+14155552671'), isNull);
      expect(AppValidators.validatePhone('+447911123456'), isNull);

      // Invalid formats
      expect(AppValidators.validatePhone('12345'), isNotNull);
      expect(AppValidators.validatePhone('01212345678'), isNotNull); // 012 is invalid in BD
      expect(AppValidators.validatePhone('abcdefghijk'), isNotNull);
      expect(AppValidators.validatePhone('', isRequired: true), isNotNull);
      expect(AppValidators.validatePhone('', isRequired: false), isNull);
    });

    test('validatePassword validates length constraint', () {
      expect(AppValidators.validatePassword('123456'), isNull);
      expect(AppValidators.validatePassword('supersecret'), isNull);
      expect(AppValidators.validatePassword('12345'), isNotNull);
      expect(AppValidators.validatePassword(''), isNotNull);
    });

    test('validateRequired validates non-empty constraint', () {
      expect(AppValidators.validateRequired('Rahim', 'first name'), isNull);
      expect(AppValidators.validateRequired('', 'first name'), isNotNull);
      expect(AppValidators.validateRequired('   ', 'first name'), isNotNull);
    });
  });
}
