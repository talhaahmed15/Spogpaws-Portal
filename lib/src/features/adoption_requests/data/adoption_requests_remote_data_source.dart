import 'package:supabase_flutter/supabase_flutter.dart';

class AdoptionRequestsRemoteDataSource {
  AdoptionRequestsRemoteDataSource({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> fetchAdoptionRequests({
    required String status,
  }) async {
    final rows = status == 'all'
        ? await _client
              .from('adoptions')
              .select(
                'id, user_id, pet_name, pet_type, breed, city, status, created_at, photo_urls',
              )
              .order('created_at', ascending: false)
        : await _client
              .from('adoptions')
              .select(
                'id, user_id, pet_name, pet_type, breed, city, status, created_at, photo_urls',
              )
              .eq('status', status)
              .order('created_at', ascending: false);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>?> fetchAdoptionRequestById(
    String requestId,
  ) async {
    final row = await _client
        .from('adoptions')
        .select(
          'id, user_id, pet_name, pet_type, breed, city, status, created_at, photo_urls',
        )
        .eq('id', requestId)
        .maybeSingle();
    if (row == null) {
      return null;
    }
    return row;
  }

  Future<Map<String, Map<String, dynamic>>> fetchProfilesByIds(
    List<String> userIds,
  ) async {
    final uniqueIds = userIds
        .where((id) => id.trim().isNotEmpty)
        .toSet()
        .toList();
    if (uniqueIds.isEmpty) {
      return const {};
    }

    final rows = await _client
        .from('profiles')
        .select('id, full_name, username, email')
        .inFilter('id', uniqueIds);

    final map = <String, Map<String, dynamic>>{};
    for (final raw in rows as List) {
      final row = raw as Map<String, dynamic>;
      map[(row['id'] ?? '').toString()] = row;
    }
    return map;
  }

  Future<Map<String, int>> fetchReportCountsByAdoptionIds(
    List<String> adoptionIds,
  ) async {
    final uniqueIds = adoptionIds
        .where((id) => id.trim().isNotEmpty)
        .toSet()
        .toList();
    if (uniqueIds.isEmpty) {
      return const {};
    }

    final rows = await _client
        .from('adoption_reports')
        .select('adoption_id')
        .inFilter('adoption_id', uniqueIds);

    final counts = <String, int>{};
    for (final raw in rows as List) {
      final adoptionId = ((raw as Map<String, dynamic>)['adoption_id'] ?? '')
          .toString();
      if (adoptionId.isEmpty) {
        continue;
      }
      counts[adoptionId] = (counts[adoptionId] ?? 0) + 1;
    }
    return counts;
  }

  Future<void> updateAdoptionStatus({
    required String requestId,
    required String status,
  }) async {
    await _client
        .from('adoptions')
        .update({'status': status})
        .eq('id', requestId);
  }
}
