import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  const supabaseUrl = 'https://bunbenbtebciohrpcbyv.supabase.co';
  const serviceKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ1bmJlbmJ0ZWJjaW9ocnBjYnl2Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc5MzA3OTYwNSwiZXhwIjoyMTA4NjU1NjA1fQ.9lT7OsAOCCm5vnbmmYsMnEAeqCrA1_oJG0lOSSmJOeo';

  final endpoints = [
    '$supabaseUrl/pg/query',
    '$supabaseUrl/rest/v1/rpc/exec',
    'https://api.supabase.com/v1/projects/bunbenbtebciohrpcbyv/database/query',
  ];

  for (final ep in endpoints) {
    try {
      final res = await http.post(
        Uri.parse(ep),
        headers: {
          'apikey': serviceKey,
          'Authorization': 'Bearer $serviceKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'query': 'SELECT 1 as val;'}),
      );
      print('Endpoint $ep -> Status: ${res.statusCode}, Body: ${res.body}');
    } catch (e) {
      print('Endpoint $ep error: $e');
    }
  }
}
