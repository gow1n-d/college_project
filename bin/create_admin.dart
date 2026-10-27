import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const supabaseUrl = 'https://bunbenbtebciohrpcbyv.supabase.co';
  const serviceKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ1bmJlbmJ0ZWJjaW9ocnBjYnl2Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc5MzA3OTYwNSwiZXhwIjoyMTA4NjU1NjA1fQ.9lT7OsAOCCm5vnbmmYsMnEAeqCrA1_oJG0lOSSmJOeo';

  final headers = {
    'apikey': serviceKey,
    'Authorization': 'Bearer $serviceKey',
    'Content-Type': 'application/json',
  };

  print('1. Checking or creating admin user...');
  final adminEmail = 'admin@college-bus.local';
  final adminPassword = 'superadmin';

  // Check if admin user already exists
  final listUsersRes = await http.get(
    Uri.parse('$supabaseUrl/auth/v1/admin/users'),
    headers: headers,
  );

  String? adminUserId;
  if (listUsersRes.statusCode == 200) {
    final data = jsonDecode(listUsersRes.body) as Map<String, dynamic>;
    final users = data['users'] as List? ?? [];
    for (final u in users) {
      if (u['email'] == adminEmail) {
        adminUserId = u['id'] as String;
        print('Found existing admin user: $adminUserId');
        break;
      }
    }
  }

  if (adminUserId == null) {
    print('Creating new admin user: $adminEmail with password: $adminPassword');
    final createRes = await http.post(
      Uri.parse('$supabaseUrl/auth/v1/admin/users'),
      headers: headers,
      body: jsonEncode({
        'email': adminEmail,
        'password': adminPassword,
        'email_confirm': true,
        'user_metadata': {'display_name': 'Administrator', 'role': 'admin'},
      }),
    );

    print('Create user status: ${createRes.statusCode}');
    print('Response: ${createRes.body}');

    if (createRes.statusCode == 200 || createRes.statusCode == 201) {
      final userObj = jsonDecode(createRes.body);
      adminUserId = userObj['id'] as String;
    } else {
      print('Failed to create admin auth user');
      return;
    }
  } else {
    // Update password to ensure it is definitely 'superadmin'
    print('Updating password for existing admin to: $adminPassword');
    final updateRes = await http.put(
      Uri.parse('$supabaseUrl/auth/v1/admin/users/$adminUserId'),
      headers: headers,
      body: jsonEncode({
        'password': adminPassword,
        'email_confirm': true,
      }),
    );
    print('Update password status: ${updateRes.statusCode}');
  }

  print('\n2. Upserting public.profiles for admin...');
  // Note: headers with Prefer: resolution=merge-duplicates for upsert
  final profileRes = await http.post(
    Uri.parse('$supabaseUrl/rest/v1/profiles'),
    headers: {
      ...headers,
      'Prefer': 'resolution=merge-duplicates',
    },
    body: jsonEncode({
      'id': adminUserId,
      'username': 'admin',
      'display_name': 'Administrator',
      'role': 'admin',
      'is_active': true,
    }),
  );

  print('Profile status: ${profileRes.statusCode}');
  print('Profile response: ${profileRes.body}');

  print('\nSUCCESS: Admin account is ready!');
  print('Email: $adminEmail');
  print('Password: $adminPassword');
}
