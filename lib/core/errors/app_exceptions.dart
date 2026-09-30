/// Base class for all app-level exceptions.
sealed class AppException implements Exception {
  const AppException(this.message, [this.code]);

  final String message;
  final String? code;

  @override
  String toString() =>
      '$runtimeType: $message${code != null ? ' ($code)' : ''}';
}

/// Authentication specific exceptions.
class AuthException extends AppException {
  const AuthException(super.message, [super.code]);
}

/// Network connectivity issues.
class NetworkException extends AppException {
  const NetworkException([
    super.message = 'Network connection error. Please check your internet.',
    super.code,
  ]);
}

/// Server or Supabase database errors (sanitized from raw DB details).
class ServerException extends AppException {
  const ServerException([
    super.message = 'A server error occurred. Please try again later.',
    super.code,
  ]);
}

/// Permission or authorization denial.
class PermissionDeniedException extends AppException {
  const PermissionDeniedException([
    super.message = 'You do not have permission to perform this action.',
    super.code,
  ]);
}

/// Account suspended or disabled exception.
class AccountDisabledException extends AppException {
  const AccountDisabledException([
    super.message =
        'Your account has been deactivated. Please contact support.',
    super.code,
  ]);
}

/// Restaurant status restriction (e.g. pending, rejected, suspended).
class RestaurantNotApprovedException extends AppException {
  const RestaurantNotApprovedException([
    super.message =
        'Your restaurant is pending approval or currently suspended.',
    super.code,
  ]);
}

/// Form or data validation errors.
class ValidationException extends AppException {
  const ValidationException(super.message, [super.code]);
}

/// Storage/Image upload errors.
class StorageException extends AppException {
  const StorageException([
    super.message = 'Failed to upload or retrieve file. Please try again.',
    super.code,
  ]);
}
