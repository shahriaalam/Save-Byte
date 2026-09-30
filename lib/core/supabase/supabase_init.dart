import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/supabase_constants.dart';

/// Initializes Supabase with application credentials.
///
/// Security: Only the anonymous/public key is used here (Section 50).
/// Never expose the service-role key.
Future<void> initializeSupabase() async {
  try {
    if (SupabaseConstants.supabaseUrl.contains('placeholder') ||
        SupabaseConstants.supabaseAnonKey.contains('placeholder')) {
      debugPrint(
        '[SaveBite] Supabase initialized with placeholder credentials. '
        'Provide SUPABASE_URL and SUPABASE_ANON_KEY to connect to live backend.',
      );
    }

    // ignore: deprecated_member_use
    await Supabase.initialize(
      url: SupabaseConstants.supabaseUrl,
      // ignore: deprecated_member_use
      anonKey: SupabaseConstants.supabaseAnonKey,
    );
  } catch (e) {
    debugPrint('[SaveBite] Warning: Supabase.initialize encountered error: $e');
  }
}
