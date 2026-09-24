import 'package:flutter/foundation.dart';

/// Supabase connection details, supplied with --dart-define.
///
/// The default host differs per platform because a local Supabase bound to
/// 127.0.0.1 is not reachable at that address from an Android emulator.
class Env {
  const Env._();

  static const _url = String.fromEnvironment('SUPABASE_URL');
  static const _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get supabaseUrl {
    if (_url.isNotEmpty) return _url;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:54321';
    }
    return 'http://127.0.0.1:54321';
  }

  static const _defaultLocalAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0';

  static String get supabaseAnonKey {
    if (_anonKey.isNotEmpty) return _anonKey;
    return _defaultLocalAnonKey;
  }
}
