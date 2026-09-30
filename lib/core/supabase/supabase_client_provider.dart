import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider for the SupabaseClient.
/// Can be overridden in tests to provide a mock client.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  try {
    return Supabase.instance.client;
  } catch (_) {
    // Return an uninitialized fallback client if accessed before Supabase.initialize in tests
    return SupabaseClient(
      'https://placeholder.supabase.co',
      'placeholder-anon-key',
    );
  }
});
