import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const url = 'https://bunbenbtebciohrpcbyv.supabase.co';
  const serviceKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ1bmJlbmJ0ZWJjaW9ocnBjYnl2Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc5MzA3OTYwNSwiZXhwIjoyMTA4NjU1NjA1fQ.9lT7OsAOCCm5vnbmmYsMnEAeqCrA1_oJG0lOSSmJOeo';

  final r = await http.get(
    Uri.parse('$url/rest/v1/'),
    headers: {
      'apikey': serviceKey,
      'Authorization': 'Bearer $serviceKey',
    },
  );

  print('Root OpenAPI status: ${r.statusCode}');
  if (r.statusCode == 200) {
    final spec = jsonDecode(r.body) as Map<String, dynamic>;
    final paths = (spec['paths'] as Map<String, dynamic>?)?.keys.toList() ?? [];
    print('Available REST paths: $paths');
  } else {
    print('Response: ${r.body}');
  }
}
