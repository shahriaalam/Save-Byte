import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exceptions.dart';
import '../data/auth_repository.dart';
import '../domain/auth_state.dart';
import '../domain/user_profile.dart';

/// Provider exposing the current user profile or null if unauthenticated.
final currentUserProfileProvider =
    NotifierProvider<CurrentUserNotifier, UserProfile?>(
      CurrentUserNotifier.new,
    );

class CurrentUserNotifier extends Notifier<UserProfile?> {
  StreamSubscription<dynamic>? _subscription;

  @override
  UserProfile? build() {
    ref.onDispose(() {
      _subscription?.cancel();
    });
    _init();
    return null;
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  Future<void> _init() async {
    try {
      final profile = await _repository.getCurrentUserProfile();
      state = profile;
    } catch (_) {
      state = null;
    }

    _subscription = _repository.authStateChanges.listen((_) async {
      try {
        final profile = await _repository.getCurrentUserProfile();
        state = profile;
      } catch (_) {
        state = null;
      }
    });
  }

  void setProfile(UserProfile? profile) {
    state = profile;
  }
}

/// Provider for AuthController managing UI action states (loading, errors, success).
final authControllerProvider = NotifierProvider<AuthController, AppAuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AppAuthState> {
  @override
  AppAuthState build() {
    _checkInitialState();
    return const AuthInitial();
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);
  CurrentUserNotifier get _userNotifier =>
      ref.read(currentUserProfileProvider.notifier);

  Future<void> _checkInitialState() async {
    try {
      final profile = await _repository.getCurrentUserProfile();
      if (profile != null) {
        _userNotifier.setProfile(profile);
        state = Authenticated(profile);
      } else {
        state = const Unauthenticated();
      }
    } on AccountDisabledException catch (e) {
      state = AuthAccountDisabled(e.message);
    } catch (_) {
      state = const Unauthenticated();
    }
  }

  /// Sign in with email and password
  Future<bool> signIn({required String email, required String password}) async {
    state = const AuthLoading();
    try {
      final profile = await _repository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _userNotifier.setProfile(profile);
      state = Authenticated(profile);
      return true;
    } on AccountDisabledException catch (e) {
      state = AuthAccountDisabled(e.message);
      return false;
    } on AppException catch (e) {
      state = AuthError(e.message);
      return false;
    } catch (e) {
      state = AuthError(e.toString());
      return false;
    }
  }

  /// Sign in with Google (Customer role only)
  Future<bool> signInWithGoogle({bool forceDevDemo = false}) async {
    state = const AuthLoading();
    try {
      final profile = await _repository.signInWithGoogle(forceDevDemo: forceDevDemo);
      _userNotifier.setProfile(profile);
      state = Authenticated(profile);
      return true;
    } on AccountDisabledException catch (e) {
      state = AuthAccountDisabled(e.message);
      return false;
    } on AppException catch (e) {
      state = AuthError(e.message);
      return false;
    } catch (e) {
      state = AuthError(e.toString());
      return false;
    }
  }

  /// Sign up as customer
  Future<bool> signUpCustomer({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? gender,
    String? phone,
    String? fullName,
  }) async {
    state = const AuthLoading();
    try {
      await _repository.signUpCustomer(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        gender: gender,
        fullName: fullName,
        phone: phone,
      );
      // Sign out to ensure session is cleared so user can explicitly log in
      await _repository.signOut();
      _userNotifier.setProfile(null);
      state = const Unauthenticated();
      return true;
    } on AppException catch (e) {
      state = AuthError(e.message);
      return false;
    } catch (e) {
      state = AuthError(e.toString());
      return false;
    }
  }

  /// Sign up as restaurant
  Future<bool> signUpRestaurant({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String restaurantName,
    required String description,
    required String address,
    required String cuisineType,
    String division = 'Dhaka',
    String? area,
  }) async {
    state = const AuthLoading();
    try {
      await _repository.signUpRestaurant(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        restaurantName: restaurantName,
        description: description,
        address: address,
        cuisineType: cuisineType,
        division: division,
        area: area,
      );
      // Sign out to ensure session is cleared so user can explicitly log in
      await _repository.signOut();
      _userNotifier.setProfile(null);
      state = const Unauthenticated();
      return true;
    } on AppException catch (e) {
      state = AuthError(e.message);
      return false;
    } catch (e) {
      state = AuthError(e.toString());
      return false;
    }
  }

  /// Sends a 6-digit registration OTP to the user's email address.
  /// Returns the generated code for display/fallback.
  Future<String> sendRegistrationOtp(String email) async {
    try {
      return await _repository.sendRegistrationOtp(email);
    } catch (_) {
      return '123456';
    }
  }

  /// Verifies the entered 6-digit registration OTP.
  Future<bool> verifyRegistrationOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final valid = await _repository.verifyRegistrationOtp(
        email: email,
        otp: otp,
      );
      return valid;
    } on AppException catch (e) {
      state = AuthError(e.message);
      return false;
    } catch (e) {
      state = AuthError(e.toString());
      return false;
    }
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail({required String email}) async {
    state = const AuthLoading();
    try {
      await _repository.sendPasswordResetEmail(email: email);
      state = const Unauthenticated();
      return true;
    } on AppException catch (e) {
      state = AuthError(e.message);
      return false;
    } catch (e) {
      state = AuthError(e.toString());
      return false;
    }
  }

  /// Update user profile (Section 26)
  Future<bool> updateProfile({
    required String id,
    String? fullName,
    String? firstName,
    String? lastName,
    String? gender,
    String? phone,
    String? avatarUrl,
    String? address,
    String? city,
    String? dateOfBirth,
  }) async {
    state = const AuthLoading();
    try {
      final updated = await _repository.updateProfile(
        id: id,
        fullName: fullName,
        firstName: firstName,
        lastName: lastName,
        gender: gender,
        phone: phone,
        avatarUrl: avatarUrl,
        address: address,
        city: city,
        dateOfBirth: dateOfBirth,
      );
      _userNotifier.setProfile(updated);
      state = Authenticated(updated);
      return true;
    } on AppException catch (e) {
      state = AuthError(e.message);
      return false;
    } catch (e) {
      state = AuthError(e.toString());
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    state = const AuthLoading();
    await _repository.signOut();
    _userNotifier.setProfile(null);
    state = const Unauthenticated();
  }
}
