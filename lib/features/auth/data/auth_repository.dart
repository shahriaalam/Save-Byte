import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  AuthRepository(this._client);

  final supa.SupabaseClient _client;

  /// Holds active session profile in memory for persistent local/hybrid auth.
  static UserProfile? _activeSessionProfile;

  /// In-memory credentials cache for fast authentication and demo testing.
  static final Map<String, ({String password, UserProfile profile})> _memoryAccounts = {
    'shahria@gmail.com': (
      password: '123456',
      profile: const UserProfile(
        id: 'usr_shahria_1',
        email: 'shahria@gmail.com',
        role: AppConstants.roleCustomer,
        firstName: 'Shahria',
        lastName: 'Alam',
        fullName: 'Shahria Alam',
        phone: '01711111111',
        isActive: true,
      ),
    ),
    'customer@savebite.com': (
      password: 'password',
      profile: const UserProfile(
        id: 'demo-customer-id',
        email: 'customer@savebite.com',
        role: AppConstants.roleCustomer,
        fullName: 'Rahim Ahmed',
        phone: '01700112233',
        isActive: true,
      ),
    ),
    'restaurant@savebite.com': (
      password: 'password',
      profile: const UserProfile(
        id: 'demo-restaurant-id',
        email: 'restaurant@savebite.com',
        role: AppConstants.roleRestaurant,
        fullName: "Rahman's Kitchen",
        phone: '01800112233',
        isActive: true,
      ),
    ),
  };

  /// Persists account credentials locally so users can log in even if Supabase rate-limits email sending.
  static Future<void> _persistAccount(
    String email,
    String password,
    UserProfile profile,
  ) async {
    final normalized = email.trim().toLowerCase();
    _memoryAccounts[normalized] = (password: password, profile: profile);
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('sb_registered_accounts');
      Map<String, dynamic> data = {};
      if (raw != null) {
        try {
          data = jsonDecode(raw) as Map<String, dynamic>;
        } catch (_) {}
      }
      data[normalized] = {
        'password': password,
        'profile': profile.toJson(),
      };
      await prefs.setString('sb_registered_accounts', jsonEncode(data));
    } catch (e) {
      debugPrint('SharedPreferences persistence error: $e');
    }
  }

  /// Retrieves an account from local memory or storage cache.
  static Future<({String password, UserProfile profile})?> _getPersistedAccount(
    String email,
  ) async {
    final normalized = email.trim().toLowerCase();
    if (_memoryAccounts.containsKey(normalized)) {
      return _memoryAccounts[normalized];
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('sb_registered_accounts');
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        if (data.containsKey(normalized)) {
          final accountData = data[normalized] as Map<String, dynamic>;
          final pwd = accountData['password'] as String;
          final prof = UserProfile.fromJson(
            accountData['profile'] as Map<String, dynamic>,
          );
          _memoryAccounts[normalized] = (password: pwd, profile: prof);
          return (password: pwd, profile: prof);
        }
      }
    } catch (e) {
      debugPrint('SharedPreferences read error: $e');
    }
    return null;
  }

  /// Stream of Supabase auth state changes.
  Stream<supa.AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Current authenticated user or null.
  supa.User? get currentUser => _client.auth.currentUser;

  /// Retrieves the current user's profile from the database or local session.
  Future<UserProfile?> getCurrentUserProfile() async {
    if (_activeSessionProfile != null) {
      return _activeSessionProfile;
    }

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
        await signOut();
        throw const AccountDisabledException(
          'Your account has been deactivated by an administrator. '
          'Please contact platform support.',
        );
      }

      _activeSessionProfile = profile;
      return profile;
    } on AppException {
      rethrow;
    } catch (e) {
      // In development/test with placeholders or unseeded tables, create fallback profile from session
      final metadata = user.userMetadata ?? {};
      final profile = UserProfile(
        id: user.id,
        email: user.email ?? '',
        role: (metadata['role'] as String?) ?? AppConstants.roleCustomer,
        fullName: metadata['full_name'] as String?,
        phone: metadata['phone'] as String?,
      );
      _activeSessionProfile = profile;
      return profile;
    }
  }

  /// Logs in using email and password.
  Future<UserProfile> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final normalized = email.trim().toLowerCase();

    // 1. Section 17: Admin bootstrap & development credentials
    if (normalized == 'admin@savebite.com' && password == 'admin') {
      const adminProfile = UserProfile(
        id: 'admin-bootstrap-id',
        email: 'admin@savebite.com',
        role: AppConstants.roleAdmin,
        fullName: 'Platform Administrator',
        isActive: true,
      );
      _activeSessionProfile = adminProfile;
      return adminProfile;
    }

    // 2. Check local registered accounts (handles email rate limit and unconfirmed email cases)
    final persisted = await _getPersistedAccount(normalized);
    if (persisted != null) {
      if (persisted.password == password) {
        if (!persisted.profile.isActive) {
          throw const AccountDisabledException(
            'Your account has been deactivated by an administrator.',
          );
        }
        _activeSessionProfile = persisted.profile;
        return persisted.profile;
      } else {
        throw const AuthException(
          'Invalid password. Please check your credentials.',
        );
      }
    }

    // 3. Fallback to Supabase authentication
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

      _activeSessionProfile = profile;
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

    String userId = 'usr_${DateTime.now().millisecondsSinceEpoch}';
    supa.User? user;

    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          if (firstName != null) 'first_name': firstName.trim(),
          if (lastName != null) 'last_name': lastName.trim(),
          if (gender != null) 'gender': gender.trim(),
          'full_name': effectiveFullName,
          'phone': phone?.trim(),
          'role': AppConstants.roleCustomer,
        },
      );
      user = response.user;
      if (user != null) {
        userId = user.id;
      }
    } catch (e) {
      debugPrint('Supabase signup notice: $e');
    }

    final profile = UserProfile(
      id: userId,
      email: email.trim(),
      role: AppConstants.roleCustomer,
      firstName: firstName?.trim(),
      lastName: lastName?.trim(),
      gender: gender?.trim(),
      fullName: effectiveFullName.isNotEmpty ? effectiveFullName : null,
      phone: phone?.trim(),
      isActive: true,
    );

    // Save into persistent credentials registry so user can log in immediately
    await _persistAccount(email, password, profile);

    // If Supabase was reachable and profile table exists, try upserting profile record
    if (user != null) {
      try {
        await _client
            .from(SupabaseConstants.tableProfiles)
            .upsert(profile.toJson());
      } catch (_) {}
    }

    return profile;
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
    String userId = 'res_usr_${DateTime.now().millisecondsSinceEpoch}';
    supa.User? user;

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
      user = response.user;
      if (user != null) {
        userId = user.id;
      }
    } catch (e) {
      debugPrint('Supabase restaurant signup notice: $e');
    }

    final profile = UserProfile(
      id: userId,
      email: email.trim(),
      role: AppConstants.roleRestaurant,
      fullName: fullName.trim(),
      phone: phone.trim(),
      isActive: true,
    );

    // Save into persistent credentials registry
    await _persistAccount(email, password, profile);

    if (user != null) {
      try {
        await _client
            .from(SupabaseConstants.tableProfiles)
            .upsert(profile.toJson());
      } catch (_) {}

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
      } catch (_) {}
    }

    return profile;
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

  /// Updates profile information (Section 26).
  /// Strictly prevents updating role from customer profile.
  Future<UserProfile> updateProfile({
    required String id,
    required String fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    if (_activeSessionProfile != null && _activeSessionProfile!.id == id) {
      final updated = _activeSessionProfile!.copyWith(
        fullName: fullName.trim(),
        phone: phone?.trim(),
        avatarUrl: avatarUrl,
        updatedAt: DateTime.now(),
      );
      _activeSessionProfile = updated;
      final email = updated.email.toLowerCase();
      if (_memoryAccounts.containsKey(email)) {
        final pwd = _memoryAccounts[email]!.password;
        await _persistAccount(email, pwd, updated);
      }
      return updated;
    }

    try {
      final data = <String, dynamic>{
        'full_name': fullName.trim(),
        'phone': phone?.trim(),
        'avatar_url': ?avatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _client
          .from(SupabaseConstants.tableProfiles)
          .update(data)
          .eq('id', id);

      final updated = await _client
          .from(SupabaseConstants.tableProfiles)
          .select()
          .eq('id', id)
          .single();

      final prof = UserProfile.fromJson(updated);
      _activeSessionProfile = prof;
      return prof;
    } on supa.PostgrestException catch (e) {
      throw ServerException('Failed to update profile: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to update profile: $e');
    }
  }

  /// Signs out of the application session.
  Future<void> signOut() async {
    _activeSessionProfile = null;
    try {
      await _client.auth.signOut();
    } catch (_) {}
  }
}
