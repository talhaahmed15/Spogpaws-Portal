import 'dart:math' as math;

import '../../domain/entities/adoption_request.dart';
import '../../domain/usecases/get_adoption_request_detail_use_case.dart';
import '../../domain/usecases/get_adoption_requests_use_case.dart';
import '../../domain/usecases/update_adoption_request_status_use_case.dart';

class AdoptionRequestsController {
  AdoptionRequestsController({
    required GetAdoptionRequestsUseCase getAdoptionRequests,
    required GetAdoptionRequestDetailUseCase getAdoptionRequestDetail,
    required UpdateAdoptionRequestStatusUseCase updateAdoptionRequestStatus,
  }) : _getAdoptionRequests = getAdoptionRequests,
       _getAdoptionRequestDetail = getAdoptionRequestDetail,
       _updateAdoptionRequestStatus = updateAdoptionRequestStatus;

  final GetAdoptionRequestsUseCase _getAdoptionRequests;
  final GetAdoptionRequestDetailUseCase _getAdoptionRequestDetail;
  final UpdateAdoptionRequestStatusUseCase _updateAdoptionRequestStatus;

  static const int pageSize = 5;

  bool _isLoading = false;
  String? _error;
  List<AdoptionRequest> _items = const [];

  String _statusFilter = 'all';
  String _query = '';
  int _page = 1;

  bool _isDetailLoading = false;
  String? _detailError;
  AdoptionRequest? _selected;

  bool get isLoading => _isLoading;
  String? get error => _error;
  String get statusFilter => _statusFilter;
  String get query => _query;
  int get page => _page;
  bool get isDetailLoading => _isDetailLoading;
  String? get detailError => _detailError;
  AdoptionRequest? get selected => _selected;
  bool get inDetailMode => _selected != null || _isDetailLoading;

  List<AdoptionRequest> get filteredItems {
    final normalized = _query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return _items;
    }

    return _items.where((item) {
      final target = [
        item.id,
        item.applicantName,
        item.applicantEmail,
        item.petName,
        item.petType,
        item.breed,
        item.city,
      ].join(' ').toLowerCase();
      return target.contains(normalized);
    }).toList();
  }

  int get totalPages {
    if (filteredItems.isEmpty) {
      return 1;
    }
    return math.max(1, (filteredItems.length / pageSize).ceil());
  }

  List<AdoptionRequest> get pagedItems {
    final list = filteredItems;
    if (list.isEmpty) {
      return const [];
    }

    final safePage = _page.clamp(1, totalPages);
    final start = (safePage - 1) * pageSize;
    final end = math.min(start + pageSize, list.length);
    return list.sublist(start, end);
  }

  Future<void> load() async {
    _isLoading = true;
    _error = null;

    try {
      _items = await _getAdoptionRequests(status: _statusFilter);
      _page = 1;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
    }
  }

  Future<void> setFilter(String status) async {
    _statusFilter = status;
    await load();
  }

  void setQuery(String value) {
    _query = value;
    _page = 1;
  }

  void goToPage(int nextPage) {
    _page = nextPage.clamp(1, totalPages);
  }

  Future<void> openDetail(String requestId) async {
    _isDetailLoading = true;
    _detailError = null;
    _selected = null;

    try {
      _selected = await _getAdoptionRequestDetail(requestId);
      if (_selected == null) {
        _detailError = 'Request not found.';
      }
    } catch (e) {
      _detailError = e.toString();
    } finally {
      _isDetailLoading = false;
    }
  }

  void closeDetail() {
    _selected = null;
    _detailError = null;
    _isDetailLoading = false;
  }

  Future<void> updateStatus(String nextStatus) async {
    final selected = _selected;
    if (selected == null) {
      return;
    }

    await _updateAdoptionRequestStatus(
      requestId: selected.id,
      status: nextStatus,
    );
    await openDetail(selected.id);

    final index = _items.indexWhere((item) => item.id == selected.id);
    if (index != -1 && _selected != null) {
      _items[index] = _selected!;
    }
  }
}
