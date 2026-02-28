import '../domain/entities/adoption_request.dart';
import '../domain/repositories/adoption_requests_repository.dart';
import 'adoption_requests_remote_data_source.dart';

class AdoptionRequestsRepositoryImpl implements AdoptionRequestsRepository {
  const AdoptionRequestsRepositoryImpl(this._remoteDataSource);

  final AdoptionRequestsRemoteDataSource _remoteDataSource;

  @override
  Future<List<AdoptionRequest>> getRequests({required String status}) async {
    final rows = await _remoteDataSource.fetchAdoptionRequests(status: status);
    if (rows.isEmpty) {
      return const [];
    }

    final userIds = rows
        .map((row) => (row['user_id'] ?? '').toString())
        .toList();
    final adoptionIds = rows
        .map((row) => (row['id'] ?? '').toString())
        .toList();

    final profilesById = await _remoteDataSource.fetchProfilesByIds(userIds);
    final reportCountsById = await _remoteDataSource
        .fetchReportCountsByAdoptionIds(adoptionIds);

    return rows
        .map((row) => _mapAdoptionRequest(row, profilesById, reportCountsById))
        .toList();
  }

  @override
  Future<AdoptionRequest?> getRequestDetail(String requestId) async {
    final row = await _remoteDataSource.fetchAdoptionRequestById(requestId);
    if (row == null) {
      return null;
    }

    final userId = (row['user_id'] ?? '').toString();
    final profiles = await _remoteDataSource.fetchProfilesByIds([userId]);
    final reportCounts = await _remoteDataSource.fetchReportCountsByAdoptionIds(
      [requestId],
    );

    return _mapAdoptionRequest(row, profiles, reportCounts);
  }

  @override
  Future<void> updateRequestStatus({
    required String requestId,
    required String status,
  }) {
    return _remoteDataSource.updateAdoptionStatus(
      requestId: requestId,
      status: status,
    );
  }

  AdoptionRequest _mapAdoptionRequest(
    Map<String, dynamic> row,
    Map<String, Map<String, dynamic>> profilesById,
    Map<String, int> reportCountsById,
  ) {
    final userId = (row['user_id'] ?? '').toString();
    final requestId = (row['id'] ?? '').toString();
    final profile = profilesById[userId];

    final fullName = (profile?['full_name'] ?? '').toString().trim();
    final username = (profile?['username'] ?? '').toString().trim();
    final email = (profile?['email'] ?? '').toString().trim();

    final applicantName = fullName.isNotEmpty
        ? fullName
        : username.isNotEmpty
        ? username
        : email.isNotEmpty
        ? email
        : 'User';

    return AdoptionRequest(
      id: requestId,
      userId: userId,
      petName: (row['pet_name'] ?? '').toString(),
      petType: (row['pet_type'] ?? '').toString(),
      breed: (row['breed'] ?? '').toString(),
      city: (row['city'] ?? '').toString(),
      status: (row['status'] ?? '').toString(),
      createdAt: DateTime.tryParse((row['created_at'] ?? '').toString()),
      photoUrls:
          (row['photo_urls'] as List?)
              ?.map((item) => item.toString())
              .where((item) => item.trim().isNotEmpty)
              .toList() ??
          const [],
      applicantName: applicantName,
      applicantEmail: email,
      reportCount: reportCountsById[requestId] ?? 0,
    );
  }
}
