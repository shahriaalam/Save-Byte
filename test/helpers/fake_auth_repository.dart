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
        ? AppConstants.roleAdmin
        : AppConstants.roleCustomer;
    final profile = UserProfile(
      id: 'test-user-id',
      email: email,
      role: role,
      fullName: role == AppConstants.roleAdmin
          ? 'Platform Administrator'
          : 'Test User',
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
    required String fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    final updated = (initialProfile ??
            UserProfile(
              id: id,
              email: 'test@savebite.com',
              role: AppConstants.roleCustomer,
              fullName: fullName,
              isActive: true,
            ))
        .copyWith(
      fullName: fullName,
      phone: phone,
      avatarUrl: avatarUrl,
    );
    initialProfile = updated;
    return updated;
  }

  @override
  Future<void> signOut() async {
    initialProfile = null;
  }
}
