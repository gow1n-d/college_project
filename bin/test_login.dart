import 'package:supabase/supabase.dart';

void main() async {
  const url = 'https://bunbenbtebciohrpcbyv.supabase.co';
  const anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ1bmJlbmJ0ZWJjaW9ocnBjYnl2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTMwNzk2MDUsImV4cCI6MjEwODY1NTYwNX0.OhKVd0c5oKDvHdMM0KO8C9G7kgciIKXbKjMJbxfdmnY';

  final client = SupabaseClient(url, anonKey);

  try {
    print('Testing signInWithPassword with admin@college-bus.local / superadmin...');
    final res = await client.auth.signInWithPassword(
      email: 'admin@college-bus.local',
      password: 'superadmin',
    );
    print('Auth success! User ID: ${res.user?.id}, email: ${res.user?.email}');
    print('User metadata: ${res.user?.userMetadata}');

    print('\nTesting profile query...');
    try {
      final profile = await client
          .from('profiles')
          .select()
          .eq('id', res.user!.id)
          .single();
      print('Profile query success: $profile');
    } catch (e) {
      print('Profile query error: $e');
    }
  } catch (e) {
    print('Auth error: $e');
  }
}
