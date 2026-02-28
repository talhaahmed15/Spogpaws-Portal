import '../entities/adoption_request.dart';

abstract class AdoptionRequestsRepository {
  Future<List<AdoptionRequest>> getRequests({required String status});
  Future<AdoptionRequest?> getRequestDetail(String requestId);
  Future<void> updateRequestStatus({
    required String requestId,
    required String status,
  });
}
