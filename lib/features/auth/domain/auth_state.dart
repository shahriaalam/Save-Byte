import 'user_profile.dart';

/// Sealed hierarchy representing the authentication status.
sealed class AppAuthState {
  const AppAuthState();
}

/// Initial state when determining current session.
class AuthInitial extends AppAuthState {
  const AuthInitial();
}

/// Authenticating or processing request.
class AuthLoading extends AppAuthState {
  const AuthLoading();
}

/// User is authenticated and account is active.
class Authenticated extends AppAuthState {
  const Authenticated(this.profile);
  final UserProfile profile;
}

/// User is not logged in.
class Unauthenticated extends AppAuthState {
  const Unauthenticated();
}

/// User account has been deactivated by administrator (Section 38).
class AuthAccountDisabled extends AppAuthState {
  const AuthAccountDisabled(this.email);
  final String email;
}

/// Authentication encountered an error.
class AuthError extends AppAuthState {
  const AuthError(this.message);
  final String message;
}
