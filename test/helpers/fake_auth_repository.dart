import 'package:save_bite/core/constants/app_constants.dart';
import 'package:save_bite/features/auth/data/auth_repository.dart';
import 'package:save_bite/features/auth/domain/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

/// Test fake for AuthRepository to avoid network and token refresh timers during tests.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.initialProfile});

  UserProfile? initialProfile;

  @override
  Stream<supa.AuthState> get authStateChanges => const Stream.empty();

  @override
  supa.User? get currentUser => null;

  @override
  Future<UserProfile?> getCurrentUserProfile() async => initialProfile;

  @override
  Future<UserProfile> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final role = email.trim().toLowerCase() == 'admin@savebite.com'
        ? AppConstants.roleHeadAdmin
        : AppConstants.roleCustomer;
    final profile = UserProfile(
      id: 'test-user-id',
      email: email,
      role: role,
      fullName: role == AppConstants.roleHeadAdmin
          ? 'Platform Head Administrator'
          : 'Test User',
      isActive: true,
    );
    initialProfile = profile;
    return profile;
  }

  @override
  Future<UserProfile> signInWithGoogle({bool forceDevDemo = false}) async {
    const profile = UserProfile(
      id: 'test-google-customer-id',
      email: 'customer.google@savebite.com',
      role: AppConstants.roleCustomer,
      fullName: 'Alex Google (Customer)',
      isActive: true,
    );
    initialProfile = profile;
    return profile;
  }

  @override
  Future<UserProfile> signUpCustomer({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? gender,
    String? fullName,
    String? phone,
  }) async {
    final effectiveFullName = (fullName != null && fullName.trim().isNotEmpty)
        ? fullName.trim()
        : [firstName, lastName]
            .where((s) => s != null && s.trim().isNotEmpty)
            .join(' ');
    final profile = UserProfile(
      id: 'test-customer-id',
      email: email,
      role: AppConstants.roleCustomer,
      firstName: firstName,
      lastName: lastName,
      gender: gender,
      fullName: effectiveFullName.isNotEmpty ? effectiveFullName : 'Test User',
      phone: phone,
      isActive: true,
    );
    initialProfile = profile;
    return profile;
  }

  @override
  Future<UserProfile> signUpRestaurant({
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
    final profile = UserProfile(
      id: 'test-restaurant-id',
      email: email,
      role: AppConstants.roleRestaurant,
      fullName: fullName,
      phone: phone,
      isActive: true,
    );
    initialProfile = profile;
    return profile;
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}

  @override
  Future<UserProfile> updateProfile({
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
    final resolvedFullName = (fullName != null && fullName.trim().isNotEmpty)
        ? fullName.trim()
        : [firstName, lastName]
            .where((s) => s != null && s.trim().isNotEmpty)
            .join(' ');

    final updated = (initialProfile ??
            UserProfile(
              id: id,
              email: 'test@savebite.com',
              role: AppConstants.roleCustomer,
              fullName: resolvedFullName,
              isActive: true,
            ))
        .copyWith(
      fullName: resolvedFullName.isNotEmpty ? resolvedFullName : null,
      firstName: firstName,
      lastName: lastName,
      gender: gender,
      phone: phone,
      avatarUrl: avatarUrl,
      address: address,
      city: city,
      dateOfBirth: dateOfBirth,
    );
    initialProfile = updated;
    return updated;
  }

  @override
  Future<String> sendRegistrationOtp(String email) async => '123456';

  @override
  Future<bool> verifyRegistrationOtp({
    required String email,
    required String otp,
  }) async =>
      otp.trim() == '123456';

  @override
  Future<void> signOut() async {
    initialProfile = null;
  }

  @override
  Future<void> deleteAccount() async {
    initialProfile = null;
  }
}
