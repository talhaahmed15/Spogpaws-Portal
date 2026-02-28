import '../repositories/adoption_requests_repository.dart';

class UpdateAdoptionRequestStatusUseCase {
  const UpdateAdoptionRequestStatusUseCase(this._repository);

  final AdoptionRequestsRepository _repository;

  Future<void> call({required String requestId, required String status}) {
    return _repository.updateRequestStatus(
      requestId: requestId,
      status: status,
    );
  }
}
