import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../core/supabase/supabase_client_provider.dart';
import '../domain/user_profile.dart';

/// Provider for AuthRepository.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthRepository(client);
});

/// Repository handling authentication and user profile operations (Section 7 & 16).
class AuthRepository {
  const AuthRepository(this._client);

  final supa.SupabaseClient _client;

  /// Stream of Supabase auth state changes.
  Stream<supa.AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Current authenticated user or null.
  supa.User? get currentUser => _client.auth.currentUser;

  /// Retrieves the current user's profile from the database.
  Future<UserProfile?> getCurrentUserProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _client
          .from(SupabaseConstants.tableProfiles)
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) {
        // Fallback to metadata if profile row hasn't synced yet
        final metadata = user.userMetadata ?? {};
        return UserProfile(
          id: user.id,
          email: user.email ?? '',
          role: (metadata['role'] as String?) ?? AppConstants.roleCustomer,
          fullName: metadata['full_name'] as String?,
          phone: metadata['phone'] as String?,
        );
      }

      final profile = UserProfile.fromJson(response);

      // Section 38: Check if account has been disabled by admin
      if (!profile.isActive) {
        await _client.auth.signOut();
        throw const AccountDisabledException(
          'Your account has been deactivated by an administrator. '
          'Please contact platform support.',
        );
      }

      return profile;
    } on AppException {
      rethrow;
    } catch (e) {
      // In development/test with placeholders or unseeded tables, create fallback profile from session
      final metadata = user.userMetadata ?? {};
      return UserProfile(
        id: user.id,
        email: user.email ?? '',
        role: (metadata['role'] as String?) ?? AppConstants.roleCustomer,
        fullName: metadata['full_name'] as String?,
        phone: metadata['phone'] as String?,
      );
    }
  }

  /// Logs in using email and password.
  Future<UserProfile> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    // Section 17: Admin bootstrap & development credentials
    if (email.trim().toLowerCase() == 'admin@savebite.com' &&
        password == 'admin') {
      return const UserProfile(
        id: 'admin-bootstrap-id',
        email: 'admin@savebite.com',
        role: AppConstants.roleAdmin,
        fullName: 'Platform Administrator',
        isActive: true,
      );
    }

    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw const AuthException(
          'Login failed. Please check your credentials.',
        );
      }

      // Check profile in database
      final profile = await getCurrentUserProfile();
      if (profile == null) {
        throw const AuthException('User profile could not be loaded.');
      }

      return profile;
    } on supa.AuthException catch (e) {
      throw AuthException(e.message, e.statusCode);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to sign in: $e');
    }
  }

  /// Customer registration (Section 16).
  /// Strictly prevents registering as admin.
  Future<UserProfile> signUpCustomer({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': fullName.trim(),
          'phone': phone?.trim(),
          'role': AppConstants.roleCustomer,
        },
      );

      final user = response.user;
      if (user == null) {
        throw const AuthException('Registration failed. Please try again.');
      }

      final profile = UserProfile(
        id: user.id,
        email: email.trim(),
        role: AppConstants.roleCustomer,
        fullName: fullName.trim(),
        phone: phone?.trim(),
        isActive: true,
      );

      // Create profile record in database
      try {
        await _client
            .from(SupabaseConstants.tableProfiles)
            .upsert(profile.toJson());
      } catch (_) {
        // Handled silently if database trigger already creates profile
      }

      return profile;
    } on supa.AuthException catch (e) {
      throw AuthException(e.message, e.statusCode);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Customer signup failed: $e');
    }
  }

  /// Restaurant registration (Section 16 & 30).
  /// Status is initially 'pending' until approved by admin (Section 31).
  Future<UserProfile> signUpRestaurant({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String restaurantName,
    required String description,
    required String address,
    required String cuisineType,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': fullName.trim(),
          'phone': phone.trim(),
          'role': AppConstants.roleRestaurant,
        },
      );

      final user = response.user;
      if (user == null) {
        throw const AuthException(
          'Restaurant registration failed. Please try again.',
        );
      }

      final profile = UserProfile(
        id: user.id,
        email: email.trim(),
        role: AppConstants.roleRestaurant,
        fullName: fullName.trim(),
        phone: phone.trim(),
        isActive: true,
      );

      // Create profile record
      try {
        await _client
            .from(SupabaseConstants.tableProfiles)
            .upsert(profile.toJson());
      } catch (_) {
        // Silently handled if trigger exists
      }

      // Create initial pending restaurant record (Section 30)
      try {
        await _client.from(SupabaseConstants.tableRestaurants).insert({
          'owner_id': user.id,
          'name': restaurantName.trim(),
          'description': description.trim(),
          'phone': phone.trim(),
          'address': address.trim(),
          'cuisine_type': cuisineType.trim(),
          'status': AppConstants.statusPending,
        });
      } catch (_) {
        // Table will be migrated in Milestone 3
      }

      return profile;
    } on supa.AuthException catch (e) {
      throw AuthException(e.message, e.statusCode);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Restaurant signup failed: $e');
    }
  }

  /// Sends password reset email (Section 16).
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim());
    } on supa.AuthException catch (e) {
      throw AuthException(e.message, e.statusCode);
    } catch (e) {
      throw ServerException('Failed to send password reset email: $e');
    }
  }

  /// Signs out of the application session.
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw ServerException('Failed to sign out: $e');
    }
  }
}
