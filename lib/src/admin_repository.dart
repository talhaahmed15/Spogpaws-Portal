import 'package:supabase_flutter/supabase_flutter.dart';

import 'models.dart';

class AdminRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<AdminProfile?> fetchCurrentProfile(String userId) async {
    final row = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (row == null) {
      return null;
    }
    return AdminProfile.fromMap(row);
  }

  Future<Map<String, String>> _profileNamesById(List<String> ids) async {
    final unique = ids.where((e) => e.trim().isNotEmpty).toSet().toList();
    if (unique.isEmpty) {
      return const {};
    }
    final rows = await _client
        .from('profiles')
        .select('id, full_name, username, email')
        .inFilter('id', unique);
    final map = <String, String>{};
    for (final raw in rows as List) {
      final row = raw as Map<String, dynamic>;
      final id = (row['id'] ?? '').toString();
      final fullName = (row['full_name'] ?? '').toString().trim();
      final username = (row['username'] ?? '').toString().trim();
      final email = (row['email'] ?? '').toString().trim();
      map[id] = fullName.isNotEmpty
          ? fullName
          : username.isNotEmpty
          ? username
          : email;
    }
    return map;
  }

  Future<List<AdminAdoption>> fetchAdoptions({
    String status = 'under_review',
  }) async {
    final rows = status == 'all'
        ? await _client
              .from('adoptions')
              .select()
              .order('created_at', ascending: false)
        : await _client
              .from('adoptions')
              .select()
              .eq('status', status)
              .order('created_at', ascending: false);
    final list = rows.map(AdminAdoption.fromMap).toList();
    if (list.isEmpty) {
      return list;
    }

    final ownerNames = await _profileNamesById(
      list.map((e) => e.userId).toList(),
    );
    final ids = list.map((e) => e.id).where((e) => e.isNotEmpty).toList();
    final reportCounts = <String, int>{};
    if (ids.isNotEmpty) {
      final reportRows = await _client
          .from('adoption_reports')
          .select('adoption_id')
          .inFilter('adoption_id', ids);
      for (final raw in reportRows as List) {
        final adoptionId = ((raw as Map<String, dynamic>)['adoption_id'] ?? '')
            .toString();
        if (adoptionId.isEmpty) {
          continue;
        }
        reportCounts[adoptionId] = (reportCounts[adoptionId] ?? 0) + 1;
      }
    }

    return list
        .map(
          (item) => item.copyWith(
            ownerName: ownerNames[item.userId] ?? 'User',
            reportCount: reportCounts[item.id] ?? 0,
          ),
        )
        .toList();
  }

  Future<void> updateAdoptionStatus(String postId, String status) async {
    await _client.from('adoptions').update({'status': status}).eq('id', postId);
  }

  Future<List<AdoptionReportItem>> fetchAdoptionReports() async {
    final rows = await _client
        .from('adoption_reports')
        .select('id, adoption_id, reporter_user_id, reason, created_at')
        .order('created_at', ascending: false);
    final base = (rows as List)
        .map((e) => AdoptionReportItem.fromMap(e as Map<String, dynamic>))
        .toList();
    if (base.isEmpty) {
      return base;
    }

    final postIds = base
        .map((e) => e.adoptionId)
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    final postRows = await _client
        .from('adoptions')
        .select('id, pet_name, status')
        .inFilter('id', postIds);
    final postById = <String, Map<String, dynamic>>{};
    for (final raw in postRows as List) {
      final row = raw as Map<String, dynamic>;
      postById[(row['id'] ?? '').toString()] = row;
    }
    final reporterNames = await _profileNamesById(
      base.map((e) => e.reporterUserId).toList(),
    );

    return base
        .map(
          (item) => item.copyWith(
            petName: (postById[item.adoptionId]?['pet_name'] ?? '').toString(),
            postStatus: (postById[item.adoptionId]?['status'] ?? '').toString(),
            reporterName: reporterNames[item.reporterUserId] ?? 'User',
          ),
        )
        .toList();
  }

  Future<void> deleteAdoptionReport(String reportId) async {
    await _client.from('adoption_reports').delete().eq('id', reportId);
  }

  Future<List<UserReportItem>> fetchUserReports() async {
    final rows = await _client
        .from('user_reports')
        .select(
          'id, reported_user_id, reporter_user_id, reason, details, created_at',
        )
        .order('created_at', ascending: false);
    final base = (rows as List)
        .map((e) => UserReportItem.fromMap(e as Map<String, dynamic>))
        .toList();
    if (base.isEmpty) {
      return base;
    }

    final ids = <String>{
      ...base.map((e) => e.reportedUserId),
      ...base.map((e) => e.reporterUserId),
    }.toList();
    final names = await _profileNamesById(ids);
    return base
        .map(
          (item) => item.copyWith(
            reportedUserName: names[item.reportedUserId] ?? 'User',
            reporterName: names[item.reporterUserId] ?? 'User',
          ),
        )
        .toList();
  }

  Future<void> deleteUserReport(String reportId) async {
    await _client.from('user_reports').delete().eq('id', reportId);
  }

  Future<List<FeedbackItem>> fetchFeedback({required String type}) async {
    final rows = type == 'all'
        ? await _client
              .from('app_feedback')
              .select('id, user_id, type, message, created_at')
              .order('created_at', ascending: false)
        : await _client
              .from('app_feedback')
              .select('id, user_id, type, message, created_at')
              .eq('type', type)
              .order('created_at', ascending: false);
    final base = (rows as List)
        .map((e) => FeedbackItem.fromMap(e as Map<String, dynamic>))
        .toList();
    if (base.isEmpty) {
      return base;
    }
    final userNames = await _profileNamesById(
      base.map((e) => e.userId).toList(),
    );
    return base
        .map((e) => e.copyWith(userName: userNames[e.userId] ?? 'User'))
        .toList();
  }

  Future<void> deleteFeedback(String id) async {
    await _client.from('app_feedback').delete().eq('id', id);
  }

  Future<List<AdminUser>> fetchUsers() async {
    final rows = await _client
        .from('profiles')
        .select(
          'id, email, full_name, username, role, account_status, created_at',
        )
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => AdminUser.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateUserStatus(String userId, String status) async {
    await _client
        .from('profiles')
        .update({'account_status': status})
        .eq('id', userId);
  }
}
