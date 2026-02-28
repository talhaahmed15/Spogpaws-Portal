import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../theme.dart';
import '../../data/adoption_requests_remote_data_source.dart';
import '../../data/adoption_requests_repository_impl.dart';
import '../../domain/entities/adoption_request.dart';
import '../../domain/usecases/get_adoption_request_detail_use_case.dart';
import '../../domain/usecases/get_adoption_requests_use_case.dart';
import '../../domain/usecases/update_adoption_request_status_use_case.dart';
import '../controllers/adoption_requests_controller.dart';

class AdoptionRequestsPanel extends StatefulWidget {
  const AdoptionRequestsPanel({super.key});

  @override
  State<AdoptionRequestsPanel> createState() => _AdoptionRequestsPanelState();
}

class _AdoptionRequestsPanelState extends State<AdoptionRequestsPanel> {
  late final AdoptionRequestsController _controller;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final repository = AdoptionRequestsRepositoryImpl(
      AdoptionRequestsRemoteDataSource(),
    );
    _controller = AdoptionRequestsController(
      getAdoptionRequests: GetAdoptionRequestsUseCase(repository),
      getAdoptionRequestDetail: GetAdoptionRequestDetailUseCase(repository),
      updateAdoptionRequestStatus: UpdateAdoptionRequestStatusUseCase(
        repository,
      ),
    );

    _searchController.addListener(() {
      _controller.setQuery(_searchController.text);
      setState(() {});
    });

    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await _controller.load();
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _setFilter(String status) async {
    await _controller.setFilter(status);
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _openDetail(String requestId) async {
    setState(() {});
    await _controller.openDetail(requestId);
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _updateStatus(String nextStatus) async {
    try {
      await _controller.updateStatus(nextStatus);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Status updated to ${_prettyStatus(nextStatus)}.'),
        ),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Could not update status: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7FAFC),
      padding: const EdgeInsets.all(22),
      child: _controller.inDetailMode
          ? _AdoptionRequestDetailView(
              controller: _controller,
              onBack: () => setState(_controller.closeDetail),
              onUpdateStatus: _updateStatus,
              onReloadDetail: () async {
                final selected = _controller.selected;
                if (selected == null) {
                  return;
                }
                await _openDetail(selected.id);
              },
            )
          : _AdoptionRequestsListView(
              controller: _controller,
              searchController: _searchController,
              onReload: _load,
              onFilterSelected: _setFilter,
              onRowTap: _openDetail,
              onPageChanged: (nextPage) {
                _controller.goToPage(nextPage);
                setState(() {});
              },
            ),
    );
  }
}

class _AdoptionRequestsListView extends StatelessWidget {
  const _AdoptionRequestsListView({
    required this.controller,
    required this.searchController,
    required this.onReload,
    required this.onFilterSelected,
    required this.onRowTap,
    required this.onPageChanged,
  });

  final AdoptionRequestsController controller;
  final TextEditingController searchController;
  final Future<void> Function() onReload;
  final Future<void> Function(String status) onFilterSelected;
  final Future<void> Function(String requestId) onRowTap;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 1200;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (compact)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Manage Requests',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w800,
                      fontSize: 21,
                      color: AdminColors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Review and process applications from potential pet owners.',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF70809B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SearchBox(controller: searchController),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _OutlineActionButton(
                      text: 'Refresh',
                      icon: Icons.refresh_rounded,
                      iconColor: const Color(0xFF2C63D6),
                      onTap: onReload,
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Manage Requests',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontWeight: FontWeight.w800,
                            fontSize: 21,
                            color: AdminColors.black,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Review and process applications from potential pet owners.',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Color(0xFF70809B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 380,
                    child: _SearchBox(controller: searchController),
                  ),
                  const SizedBox(width: 10),
                  _OutlineActionButton(
                    text: 'Refresh',
                    icon: Icons.refresh_rounded,
                    iconColor: const Color(0xFF2C63D6),
                    onTap: onReload,
                  ),
                ],
              ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final status in _filters)
                  _FilterChipButton(
                    label: status.label,
                    selected: controller.statusFilter == status.value,
                    onTap: () => onFilterSelected(status.value),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AdminColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AdminColors.divider),
                ),
                child: controller.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : controller.error != null
                    ? _ErrorState(message: controller.error!, onRetry: onReload)
                    : controller.filteredItems.isEmpty
                    ? const _EmptyState(label: 'No adoption requests found.')
                    : Column(
                        children: [
                          if (!compact) const _TableHeader(),
                          Expanded(
                            child: ListView.separated(
                              itemCount: controller.pagedItems.length,
                              separatorBuilder: (_, _) => const Divider(
                                height: 1,
                                color: AdminColors.divider,
                              ),
                              itemBuilder: (context, index) {
                                final request = controller.pagedItems[index];
                                if (compact) {
                                  return _RequestCard(
                                    request: request,
                                    onViewDetails: () => onRowTap(request.id),
                                  );
                                }
                                return _RequestRow(
                                  request: request,
                                  onViewDetails: () => onRowTap(request.id),
                                );
                              },
                            ),
                          ),
                          _PaginationBar(
                            itemCount: controller.filteredItems.length,
                            page: controller.page,
                            totalPages: controller.totalPages,
                            onPageChanged: onPageChanged,
                          ),
                        ],
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AdoptionRequestDetailView extends StatelessWidget {
  const _AdoptionRequestDetailView({
    required this.controller,
    required this.onBack,
    required this.onUpdateStatus,
    required this.onReloadDetail,
  });

  final AdoptionRequestsController controller;
  final VoidCallback onBack;
  final Future<void> Function(String nextStatus) onUpdateStatus;
  final Future<void> Function() onReloadDetail;

  @override
  Widget build(BuildContext context) {
    if (controller.isDetailLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.detailError != null) {
      return _ErrorState(
        message: controller.detailError!,
        onRetry: onReloadDetail,
      );
    }

    final request = controller.selected;
    if (request == null) {
      return const _EmptyState(label: 'Request not available.');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 1100;
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: onBack,
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Color(0xFF2C63D6),
                    ),
                    label: const Text('Back to requests'),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Application #${request.id}',
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AdminColors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AdminColors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AdminColors.divider),
                ),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _StatusActionButton(
                      text: 'Accept',
                      color: const Color(0xFF1ED5BA),
                      textColor: AdminColors.black,
                      icon: Icons.check_circle_rounded,
                      iconColor: const Color(0xFF0B9364),
                      onTap: () => onUpdateStatus('approved'),
                    ),
                    _StatusActionButton(
                      text: 'Under Review',
                      color: const Color(0xFFF1F5FA),
                      textColor: const Color(0xFF2E3E58),
                      icon: Icons.info_rounded,
                      iconColor: const Color(0xFF2C63D6),
                      borderColor: AdminColors.divider,
                      onTap: () => onUpdateStatus('under_review'),
                    ),
                    _StatusActionButton(
                      text: 'Reject',
                      color: const Color(0xFFFDEBEC),
                      textColor: const Color(0xFFD43E57),
                      icon: Icons.cancel_rounded,
                      iconColor: const Color(0xFFD43E57),
                      borderColor: const Color(0xFFF4BCC6),
                      onTap: () => onUpdateStatus('closed'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (compact)
                Column(
                  children: [
                    _DetailCard(
                      title: 'Applicant Information',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: const Color(0xFFE6FFF9),
                                child: Text(
                                  _initials(request.applicantName),
                                  style: const TextStyle(
                                    fontFamily: 'Manrope',
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F7A67),
                                  ),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    request.applicantName,
                                    style: const TextStyle(
                                      fontFamily: 'Manrope',
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                      color: AdminColors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    request.applicantEmail.isEmpty
                                        ? 'Email not available'
                                        : request.applicantEmail,
                                    style: const TextStyle(
                                      fontFamily: 'Manrope',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: Color(0xFF6B7A93),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F7FB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AdminColors.divider),
                            ),
                            child: const Text(
                              'Only backend-supported fields are shown for this request detail.',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Color(0xFF74839B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _DetailCard(
                      title: 'Pet Details',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _KeyValue(label: 'Pet Name', value: request.petName),
                          _KeyValue(
                            label: 'Type',
                            value: _prettyStatus(request.petType),
                          ),
                          _KeyValue(label: 'Breed', value: request.breed),
                          _KeyValue(label: 'City', value: request.city),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _DetailCard(
                      title: 'Request Metadata',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _KeyValue(label: 'Request ID', value: request.id),
                          _KeyValue(
                            label: 'Submitted',
                            value: _formatDate(request.createdAt),
                          ),
                          _KeyValue(
                            label: 'Current Status',
                            value: _prettyStatus(request.status),
                          ),
                          _KeyValue(
                            label: 'Reports',
                            value: '${request.reportCount}',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _DetailCard(
                      title: 'Attached Images',
                      child: _AttachedImagesSection(urls: request.photoUrls),
                    ),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          _DetailCard(
                            title: 'Pet Details',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _KeyValue(
                                  label: 'Pet Name',
                                  value: request.petName,
                                ),
                                _KeyValue(
                                  label: 'Type',
                                  value: _prettyStatus(request.petType),
                                ),
                                _KeyValue(label: 'Breed', value: request.breed),
                                _KeyValue(label: 'City', value: request.city),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          _DetailCard(
                            title: 'Request Metadata',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _KeyValue(
                                  label: 'Request ID',
                                  value: request.id,
                                ),
                                _KeyValue(
                                  label: 'Submitted',
                                  value: _formatDate(request.createdAt),
                                ),
                                _KeyValue(
                                  label: 'Current Status',
                                  value: _prettyStatus(request.status),
                                ),
                                _KeyValue(
                                  label: 'Reports',
                                  value: '${request.reportCount}',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          _DetailCard(
                            title: 'Attached Images',
                            child: _AttachedImagesSection(
                              urls: request.photoUrls,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 2,
                      child: _DetailCard(
                        title: 'Applicant Information',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: const Color(0xFFE6FFF9),
                                  child: Text(
                                    _initials(request.applicantName),
                                    style: const TextStyle(
                                      fontFamily: 'Manrope',
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F7A67),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        request.applicantName,
                                        style: const TextStyle(
                                          fontFamily: 'Manrope',
                                          fontWeight: FontWeight.w800,
                                          fontSize: 18,
                                          color: AdminColors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        request.applicantEmail.isEmpty
                                            ? 'Email not available'
                                            : request.applicantEmail,
                                        style: const TextStyle(
                                          fontFamily: 'Manrope',
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: Color(0xFF6B7A93),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4F7FB),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AdminColors.divider),
                              ),
                              child: const Text(
                                'Only backend-supported fields are shown for this request detail.',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Color(0xFF74839B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F5FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 20, color: Color(0xFF7D8AA0)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Search requests...',
                hintStyle: TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8B98AD),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlineActionButton extends StatelessWidget {
  const _OutlineActionButton({
    required this.text,
    required this.onTap,
    this.icon,
    this.iconColor,
  });

  final String text;
  final Future<void> Function() onTap;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AdminColors.divider),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: iconColor ?? const Color(0xFF607089)),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w800,
                color: AdminColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFCFFFF4) : const Color(0xFFF7FAFD),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFF8AE9D7) : const Color(0xFFD9E2EE),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: selected ? const Color(0xFF0D7A67) : const Color(0xFF4F5E77),
          ),
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFFF4F7FB),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: const Row(
        children: [
          Expanded(flex: 4, child: _HeaderText('APPLICANT NAME')),
          Expanded(flex: 3, child: _HeaderText('PET DETAILS')),
          Expanded(flex: 3, child: _HeaderText('DATE SUBMITTED')),
          Expanded(flex: 2, child: _HeaderText('STATUS')),
          Expanded(flex: 2, child: _HeaderText('ACTIONS')),
        ],
      ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  const _HeaderText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Manrope',
        fontWeight: FontWeight.w800,
        fontSize: 13,
        color: Color(0xFF5E6D84),
      ),
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({required this.request, required this.onViewDetails});

  final AdoptionRequest request;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 86,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFFECF2FB),
                    child: Text(
                      _initials(request.applicantName),
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: Color(0xFF56677F),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      request.applicantName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AdminColors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.petName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AdminColors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _PetTypeTag(type: request.petType),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                _formatDate(request.createdAt),
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Color(0xFF5B6B84),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _StatusBadge(status: request.status),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onViewDetails,
                  icon: const Icon(
                    Icons.visibility_rounded,
                    size: 18,
                    color: Color(0xFF07B89E),
                  ),
                  label: const Text(
                    'View Details',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Color(0xFF07B89E),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.onViewDetails});

  final AdoptionRequest request;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FBFE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AdminColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFECF2FB),
                  child: Text(
                    _initials(request.applicantName),
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: Color(0xFF56677F),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    request.applicantName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AdminColors.black,
                    ),
                  ),
                ),
                _StatusBadge(status: request.status),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${request.petName} (${_prettyStatus(request.petType)})',
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: AdminColors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(request.createdAt),
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFF5B6B84),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onViewDetails,
                icon: const Icon(
                  Icons.visibility_rounded,
                  size: 18,
                  color: Color(0xFF07B89E),
                ),
                label: const Text(
                  'View Details',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Color(0xFF07B89E),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PetTypeTag extends StatelessWidget {
  const _PetTypeTag({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final normalized = type.trim().toLowerCase();

    Color bgColor;
    Color fgColor;

    if (normalized == 'dog') {
      bgColor = const Color(0xFFF8EEB9);
      fgColor = const Color(0xFF975F00);
    } else if (normalized == 'cat') {
      bgColor = const Color(0xFFE1E7FF);
      fgColor = const Color(0xFF3F4FB0);
    } else {
      bgColor = const Color(0xFFD7F2F8);
      fgColor = const Color(0xFF076B84);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        normalized.isEmpty ? 'PET' : normalized.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Manrope',
          fontWeight: FontWeight.w800,
          fontSize: 12,
          color: fgColor,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final scheme = _statusScheme(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: scheme.$1,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _prettyStatus(status),
        style: TextStyle(
          fontFamily: 'Manrope',
          fontWeight: FontWeight.w800,
          fontSize: 15,
          color: scheme.$2,
        ),
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.itemCount,
    required this.page,
    required this.totalPages,
    required this.onPageChanged,
  });

  final int itemCount;
  final int page;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AdminColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              itemCount == 0
                  ? 'Showing 0 requests'
                  : 'Showing ${((page - 1) * AdoptionRequestsController.pageSize) + 1}-${((page * AdoptionRequestsController.pageSize) > itemCount) ? itemCount : (page * AdoptionRequestsController.pageSize)} of $itemCount requests',
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Color(0xFF607089),
              ),
            ),
          ),
          _PageButton(
            label: '<',
            enabled: page > 1,
            onTap: () => onPageChanged(page - 1),
          ),
          const SizedBox(width: 8),
          for (final pageNo in _pages(page, totalPages))
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _PageButton(
                label: '$pageNo',
                selected: pageNo == page,
                enabled: true,
                onTap: () => onPageChanged(pageNo),
              ),
            ),
          _PageButton(
            label: '>',
            enabled: page < totalPages,
            onTap: () => onPageChanged(page + 1),
          ),
        ],
      ),
    );
  }

  List<int> _pages(int current, int total) {
    if (total <= 3) {
      return List<int>.generate(total, (index) => index + 1);
    }
    if (current <= 2) {
      return [1, 2, 3];
    }
    if (current >= total - 1) {
      return [total - 2, total - 1, total];
    }
    return [current - 1, current, current + 1];
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({
    required this.label,
    required this.enabled,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AdminColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AdminColors.divider),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w800,
            color: enabled ? AdminColors.black : const Color(0xFFA8B4C6),
          ),
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AdminColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: AdminColors.black,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _KeyValue extends StatelessWidget {
  const _KeyValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: Color(0xFF8A98AD),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '-' : value,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AdminColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachedImagesSection extends StatelessWidget {
  const _AttachedImagesSection({required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F7FB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AdminColors.divider),
        ),
        child: const Text(
          'No images attached to this request.',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w600,
            color: Color(0xFF74839B),
          ),
        ),
      );
    }

    return SizedBox(
      height: 118,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final url = urls[index];
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 160,
              decoration: BoxDecoration(
                border: Border.all(color: AdminColors.divider),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.broken_image_rounded,
                      color: Color(0xFF91A0B5),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatusActionButton extends StatelessWidget {
  const _StatusActionButton({
    required this.text,
    required this.color,
    required this.textColor,
    required this.onTap,
    required this.icon,
    required this.iconColor,
    this.borderColor,
  });

  final String text;
  final Color color;
  final Color textColor;
  final IconData icon;
  final Color iconColor;
  final Color? borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor ?? color),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Could not load data',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: AdminColors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w600,
              color: AdminColors.muted,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Manrope',
          fontWeight: FontWeight.w800,
          fontSize: 16,
          color: AdminColors.muted,
        ),
      ),
    );
  }
}

class _FilterItem {
  const _FilterItem({required this.value, required this.label});

  final String value;
  final String label;
}

const List<_FilterItem> _filters = [
  _FilterItem(value: 'all', label: 'All Requests'),
  _FilterItem(value: 'under_review', label: 'Under Review'),
  _FilterItem(value: 'approved', label: 'Approved'),
  _FilterItem(value: 'adopted', label: 'Adopted'),
  _FilterItem(value: 'closed', label: 'Closed'),
];

(Color, Color) _statusScheme(String rawStatus) {
  switch (rawStatus.trim().toLowerCase()) {
    case 'approved':
      return (const Color(0xFFDDF9EA), const Color(0xFF0B9364));
    case 'under_review':
      return (const Color(0xFFDEE8FF), const Color(0xFF3450BC));
    case 'adopted':
      return (const Color(0xFFE2FAF5), const Color(0xFF118A76));
    case 'closed':
      return (const Color(0xFFFDE2E8), const Color(0xFFCA3E59));
    default:
      return (const Color(0xFFE7EDF6), const Color(0xFF50617C));
  }
}

String _prettyStatus(String status) {
  if (status.trim().isEmpty) {
    return '-';
  }

  return status
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _formatDate(DateTime? dt) {
  if (dt == null) {
    return '-';
  }

  return DateFormat('MMM dd, yyyy').format(dt.toLocal());
}

String _initials(String value) {
  final words = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();

  if (words.isEmpty) {
    return 'U';
  }
  if (words.length == 1) {
    return words.first.substring(0, 1).toUpperCase();
  }

  return '${words[0][0]}${words[1][0]}'.toUpperCase();
}
