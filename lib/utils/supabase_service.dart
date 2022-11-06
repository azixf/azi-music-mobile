import 'dart:developer';

import 'package:supabase/supabase.dart';

class SupaBase {
  final SupabaseClient client = SupabaseClient(
      'https://gfjftgeebwcrldothslz.supabase.co',
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdmamZ0Z2VlYndjcmxkb3Roc2x6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE2Njc2MjY0NjYsImV4cCI6MTk4MzIwMjQ2Nn0.E4fTnZzDUrDpX7RYllCLiei-hMhi6L7uO5eI6iG2XXU');

  Future<Map> getUpdate() async {
    final response =
        await client.from('Update').select().order('LatestVersion');

    log('response: $response');
    final List result = response as List;
    return result.isEmpty
        ? {}
        : {
            'LatestVersion': result[0]['LatestVersion'] ?? '0.0.1',
            'LatestUrl': result[0]['LatestUrl'] ?? '',
            'arm64-v8a': result[0]['arm64-v8a'] ?? '',
            'armeabi-v7a': result[0]['armeabi-v7a'] ?? '',
            'universal': result[0]['universal'] ?? '',
          };
  }
}
