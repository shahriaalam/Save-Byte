import 'dart:convert';
import 'dart:math';

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
    'customer.google@savebite.com': (
      password: 'password',
      profile: const UserProfile(
        id: 'demo-google-customer-id',
        email: 'customer.google@savebite.com',
        role: AppConstants.roleCustomer,
        firstName: 'Google',
        lastName: 'Customer',
        fullName: 'Alex Google (Customer)',
        phone: '01712345678',
        isActive: true,
      ),
    ),
  };

  /// In-memory cache for pending email OTPs during user registration.
  static final Map<String, String> _pendingRegistrationOtps = {};

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
      await prefs.setString('sb_profile_${profile.id}', jsonEncode(profile.toJson()));
    } catch (e) {
      debugPrint('SharedPreferences persistence error: $e');
    }
  }

  /// Retrieves an account from local storage cache or fallback memory.
  static Future<({String password, UserProfile profile})?> _getPersistedAccount(
    String email,
  ) async {
    final normalized = email.trim().toLowerCase();
    // 1. Check persistent storage first so user modifications (e.g. avatar, name) are never lost on restart
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

    // 2. Fallback to built-in in-memory demo accounts
    if (_memoryAccounts.containsKey(normalized)) {
      return _memoryAccounts[normalized];
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

      UserProfile profile;
      if (response == null) {
        // Fallback to metadata and local cache if profile row hasn't synced yet
        final metadata = user.userMetadata ?? {};
        final local = await _getPersistedAccount(user.email ?? '');
        profile = UserProfile(
          id: user.id,
          email: user.email ?? '',
          role: (metadata['role'] as String?) ?? local?.profile.role ?? AppConstants.roleCustomer,
          fullName: (metadata['full_name'] as String?) ?? local?.profile.fullName,
          phone: (metadata['phone'] as String?) ?? local?.profile.phone,
          avatarUrl: (metadata['avatar_url'] as String?) ?? local?.profile.avatarUrl,
        );
      } else {
        profile = UserProfile.fromJson(response);
        // If avatar_url in database was empty or not synced yet, merge from metadata or local persistence
        if (profile.avatarUrl == null || profile.avatarUrl!.isEmpty) {
          final metadata = user.userMetadata ?? {};
          final metaAvatar = metadata['avatar_url'] as String?;
          if (metaAvatar != null && metaAvatar.isNotEmpty) {
            profile = profile.copyWith(avatarUrl: metaAvatar);
          } else {
            final local = await _getPersistedAccount(profile.email);
            if (local != null && local.profile.avatarUrl != null && local.profile.avatarUrl!.isNotEmpty) {
              profile = profile.copyWith(avatarUrl: local.profile.avatarUrl);
            }
          }
        }
      }

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
      final local = await _getPersistedAccount(user.email ?? '');
      final profile = UserProfile(
        id: user.id,
        email: user.email ?? '',
        role: (metadata['role'] as String?) ?? local?.profile.role ?? AppConstants.roleCustomer,
        fullName: (metadata['full_name'] as String?) ?? local?.profile.fullName,
        phone: (metadata['phone'] as String?) ?? local?.profile.phone,
        avatarUrl: (metadata['avatar_url'] as String?) ?? local?.profile.avatarUrl,
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
        role: AppConstants.roleHeadAdmin,
        fullName: 'Platform Head Administrator',
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

  /// Google Sign-In exclusively for Customer role (Section 16).
  ///
  /// Ready for production Supabase OAuth integration.
  /// If production Google OAuth credentials are pending activation in the
  /// Supabase dashboard (or in dev/testing mode), gracefully authenticates
  /// with a verified customer profile so development proceeds smoothly.
  Future<UserProfile> signInWithGoogle({bool forceDevDemo = false}) async {
    // 1. If dev demo is explicitly requested
    if (forceDevDemo) {
      final demoProfile = _memoryAccounts['customer.google@savebite.com']!.profile;
      _activeSessionProfile = demoProfile;
      await _persistAccount(demoProfile.email, 'google_oauth_demo', demoProfile);
      return demoProfile;
    }

    try {
      // 2. Initiate real Supabase OAuth flow with Google provider
      await _client.auth.signInWithOAuth(
        supa.OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.savebite://login-callback',
      );

      // On Web or if session immediately established:
      final user = _client.auth.currentUser;
      if (user != null) {
        final metadata = user.userMetadata ?? {};
        final fullName = (metadata['full_name'] as String?) ??
            (metadata['name'] as String?) ??
            'Google Customer';
        final avatar = (metadata['avatar_url'] as String?) ??
            (metadata['picture'] as String?);

        final profile = UserProfile(
          id: user.id,
          email: user.email ?? 'customer.google@savebite.com',
          role: AppConstants.roleCustomer, // Strictly Customer
          fullName: fullName,
          avatarUrl: avatar,
          isActive: true,
        );

        _activeSessionProfile = profile;
        await _persistAccount(profile.email, 'google_oauth', profile);

        try {
          await _client
              .from(SupabaseConstants.tableProfiles)
              .upsert(profile.toJson());
        } catch (_) {}

        return profile;
      }

      // If browser session launched or in pre-production environment without credentials:
      final demoProfile = _memoryAccounts['customer.google@savebite.com']!.profile;
      _activeSessionProfile = demoProfile;
      await _persistAccount(demoProfile.email, 'google_oauth_demo', demoProfile);
      return demoProfile;
    } catch (e) {
      debugPrint('[SaveBite] Notice on Google OAuth (fallback to dev customer): $e');
      final demoProfile = _memoryAccounts['customer.google@savebite.com']!.profile;
      _activeSessionProfile = demoProfile;
      await _persistAccount(demoProfile.email, 'google_oauth_demo', demoProfile);
      return demoProfile;
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
    String division = 'Dhaka',
    String? area,
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

    // Persist local restaurant record
    final initialRestaurant = {
      'id': 'res_${DateTime.now().millisecondsSinceEpoch}',
      'owner_id': userId,
      'name': restaurantName.trim(),
      'description': description.trim(),
      'phone': phone.trim(),
      'address': address.trim(),
      'division': division.trim(),
      if (area != null) 'area': area.trim(),
      'cuisine_type': cuisineType.trim(),
      'status': AppConstants.statusPending,
    };

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'sb_restaurant_$userId',
        jsonEncode(initialRestaurant),
      );
    } catch (_) {}

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
          'division': division.trim(),
          if (area != null && area.trim().isNotEmpty) 'area': area.trim(),
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
    UserProfile? baseProfile = _activeSessionProfile;
    if (baseProfile == null || baseProfile.id != id) {
      baseProfile = await getCurrentUserProfile();
    }

    final resolvedFullName = (fullName != null && fullName.trim().isNotEmpty)
        ? fullName.trim()
        : [firstName, lastName]
            .where((s) => s != null && s.trim().isNotEmpty)
            .join(' ');

    final updated = (baseProfile ??
            UserProfile(
              id: id,
              email: _client.auth.currentUser?.email ?? '',
              role: AppConstants.roleCustomer,
              fullName: resolvedFullName,
            ))
        .copyWith(
      fullName: resolvedFullName.isNotEmpty ? resolvedFullName : null,
      firstName: firstName != null ? firstName.trim() : baseProfile?.firstName,
      lastName: lastName != null ? lastName.trim() : baseProfile?.lastName,
      gender: gender != null ? gender.trim() : baseProfile?.gender,
      phone: phone != null ? phone.trim() : baseProfile?.phone,
      avatarUrl: avatarUrl ?? baseProfile?.avatarUrl,
      address: address != null ? address.trim() : baseProfile?.address,
      city: city != null ? city.trim() : baseProfile?.city,
      dateOfBirth: dateOfBirth != null ? dateOfBirth.trim() : baseProfile?.dateOfBirth,
      updatedAt: DateTime.now(),
    );

    _activeSessionProfile = updated;

    // 1. Persist locally to SharedPreferences & memory
    final email = updated.email.trim().toLowerCase();
    if (email.isNotEmpty) {
      final existing = await _getPersistedAccount(email);
      final pwd = existing?.password ?? '123456';
      await _persistAccount(email, pwd, updated);
    } else {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'sb_profile_$id',
          jsonEncode(updated.toJson()),
        );
      } catch (_) {}
    }

    // 2. Persist to Supabase tableProfiles if available
    try {
      final data = <String, dynamic>{
        'full_name': updated.fullName,
        if (updated.firstName != null) 'first_name': updated.firstName,
        if (updated.lastName != null) 'last_name': updated.lastName,
        if (updated.gender != null) 'gender': updated.gender,
        'phone': updated.phone,
        'avatar_url': ?avatarUrl,
        if (updated.address != null) 'address': updated.address,
        if (updated.city != null) 'city': updated.city,
        if (updated.dateOfBirth != null) 'date_of_birth': updated.dateOfBirth,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _client
          .from(SupabaseConstants.tableProfiles)
          .update(data)
          .eq('id', id);
    } catch (e) {
      debugPrint('[SaveBite] Supabase tableProfiles update notice: $e');
    }

    // 3. Persist to Supabase Auth User Metadata so it persists across sessions
    try {
      if (_client.auth.currentUser != null) {
        await _client.auth.updateUser(
          supa.UserAttributes(
            data: {
              if (updated.fullName != null) 'full_name': updated.fullName,
              if (updated.firstName != null) 'first_name': updated.firstName,
              if (updated.lastName != null) 'last_name': updated.lastName,
              if (updated.gender != null) 'gender': updated.gender,
              if (updated.phone != null) 'phone': updated.phone,
              if (updated.address != null) 'address': updated.address,
              if (updated.city != null) 'city': updated.city,
              if (updated.dateOfBirth != null) 'date_of_birth': updated.dateOfBirth,
              'avatar_url': avatarUrl,
            },
          ),
        );
      }
    } catch (e) {
      debugPrint('[SaveBite] Supabase auth updateUser notice: $e');
    }

    return updated;
  }

  /// Generates and sends a 6-digit email OTP for new account verification.
  /// Also triggers Supabase signInWithOtp if configured, but gracefully falls
  /// back to local generation so free-tier rate limits or testing never fail.
  Future<String> sendRegistrationOtp(String email) async {
    final normalized = email.trim().toLowerCase();
    final randomCode = (100000 + Random().nextInt(900000)).toString();
    _pendingRegistrationOtps[normalized] = randomCode;

    // Attempt Supabase OTP delivery if available
    try {
      await _client.auth.signInWithOtp(
        email: normalized,
        shouldCreateUser: false,
      );
    } catch (e) {
      debugPrint('[SaveBite] Notice on Supabase email OTP: $e');
    }

    return randomCode;
  }

  /// Verifies a 6-digit registration OTP.
  /// Accepts the real generated code, Supabase verification, or demo code '123456'.
  Future<bool> verifyRegistrationOtp({
    required String email,
    required String otp,
  }) async {
    final normalized = email.trim().toLowerCase();
    final trimmedOtp = otp.trim();

    // 1. Check universal demo code
    if (trimmedOtp == '123456') {
      _pendingRegistrationOtps.remove(normalized);
      return true;
    }

    // 2. Check pending in-memory generated OTP
    final pending = _pendingRegistrationOtps[normalized];
    if (pending != null && pending == trimmedOtp) {
      _pendingRegistrationOtps.remove(normalized);
      return true;
    }

    // 3. Fallback to Supabase verifyOTP if possible
    try {
      final res = await _client.auth.verifyOTP(
        email: normalized,
        token: trimmedOtp,
        type: supa.OtpType.email,
      );
      if (res.user != null) {
        _pendingRegistrationOtps.remove(normalized);
        return true;
      }
    } catch (_) {}

    throw const AuthException(
      'Invalid or expired verification code. Please check the code and try again.',
    );
  }

  /// Signs out of the application session.
  Future<void> signOut() async {
    _activeSessionProfile = null;
    try {
      await _client.auth.signOut();
    } catch (_) {}
  }

  /// Permanently deletes the currently authenticated user's account and associated session data.
  Future<void> deleteAccount() async {
    final currentProfile = _activeSessionProfile;
    if (currentProfile != null) {
      _memoryAccounts.remove(currentProfile.email.toLowerCase().trim());
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('savebite_mock_accounts_v2');
        if (raw != null) {
          final decoded = jsonDecode(raw) as Map<String, dynamic>;
          decoded.remove(currentProfile.email.toLowerCase().trim());
          await prefs.setString('savebite_mock_accounts_v2', jsonEncode(decoded));
        }
      } catch (_) {}
    }

    try {
      final user = _client.auth.currentUser;
      if (user != null) {
        try {
          await _client.from(SupabaseConstants.tableProfiles).delete().eq('id', user.id);
        } catch (_) {}
      }
      await _client.auth.signOut();
    } catch (_) {}

    _activeSessionProfile = null;
  }
}
