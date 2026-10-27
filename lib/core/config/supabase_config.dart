/// Supabase project configuration
/// Values injected via --dart-define at build time
/// Never hardcode real credentials here
class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://bunbenbtebciohrpcbyv.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ1bmJlbmJ0ZWJjaW9ocnBjYnl2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTMwNzk2MDUsImV4cCI6MjEwODY1NTYwNX0.OhKVd0c5oKDvHdMM0KO8C9G7kgciIKXbKjMJbxfdmnY',
  );

  static String get publishableKey => anonKey;

  /// Edge function base URL derived from project URL
  static String get functionsUrl => '$url/functions/v1';
}
