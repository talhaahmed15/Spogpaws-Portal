import '../entities/adoption_request.dart';
import '../repositories/adoption_requests_repository.dart';

class GetAdoptionRequestDetailUseCase {
  const GetAdoptionRequestDetailUseCase(this._repository);

  final AdoptionRequestsRepository _repository;

  Future<AdoptionRequest?> call(String requestId) {
    return _repository.getRequestDetail(requestId);
  }
}
