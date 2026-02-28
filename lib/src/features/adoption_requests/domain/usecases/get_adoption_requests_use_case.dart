import '../entities/adoption_request.dart';
import '../repositories/adoption_requests_repository.dart';

class GetAdoptionRequestsUseCase {
  const GetAdoptionRequestsUseCase(this._repository);

  final AdoptionRequestsRepository _repository;

  Future<List<AdoptionRequest>> call({required String status}) {
    return _repository.getRequests(status: status);
  }
}
