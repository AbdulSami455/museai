class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const backendBaseUrl = String.fromEnvironment('BACKEND_BASE_URL');

  static void validate() {
    final missing = <String>[];
    if (supabaseUrl.isEmpty) missing.add('SUPABASE_URL');
    if (supabaseAnonKey.isEmpty) missing.add('SUPABASE_ANON_KEY');
    if (backendBaseUrl.isEmpty) missing.add('BACKEND_BASE_URL');
    if (missing.isNotEmpty) {
      throw StateError(
        'Missing required dart-defines: ${missing.join(', ')}',
      );
    }
  }
}
