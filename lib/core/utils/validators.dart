/// Common form input validators for email, phone numbers, and names.
class AppValidators {
  AppValidators._();

  /// RFC-compliant email regular expression.
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
  );

  /// Bangladeshi phone regex: 013-019 (11 digits) or with +88 / 88 country code.
  static final RegExp _bdPhoneRegex = RegExp(
    r'^(?:\+?8801|01)[3-9]\d{8}$',
  );

  /// General international phone regex (E.164 compliant: + followed by 10 to 15 digits).
  static final RegExp _intlPhoneRegex = RegExp(
    r'^\+[1-9]\d{9,14}$',
  );

  /// Validates standard email format.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email address';
    }
    final trimmed = value.trim();
    if (!_emailRegex.hasMatch(trimmed)) {
      return 'Please enter a valid email address (e.g., name@example.com)';
    }
    return null;
  }

  /// Validates phone number format.
  /// Accepts Bangladeshi 11-digit numbers (e.g. 017XXXXXXXX) or standard international format.
  static String? validatePhone(String? value, {bool isRequired = true}) {
    if (value == null || value.trim().isEmpty) {
      if (isRequired) {
        return 'Please enter your phone number';
      }
      return null;
    }

    final clean = value.trim().replaceAll(RegExp(r'[\s\-]'), '');
    if (!_bdPhoneRegex.hasMatch(clean) && !_intlPhoneRegex.hasMatch(clean)) {
      return 'Please enter a valid phone number (e.g., 017XXXXXXXX or +88017XXXXXXXX)';
    }
    return null;
  }

  /// Validates non-empty required text field.
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your $fieldName';
    }
    return null;
  }

  /// Validates password strength (minimum 6 characters as per Section 16).
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }
}
