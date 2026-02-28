import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../admin_repository.dart';
import '../../../../models.dart';
import '../../../../theme.dart';

class FeedbackPanel extends StatefulWidget {
  const FeedbackPanel({super.key});

  @override
  State<FeedbackPanel> createState() => _FeedbackPanelState();
}

class _FeedbackPanelState extends State<FeedbackPanel> {
  final _repo = AdminRepository();
  final _searchController = TextEditingController();

  String _type = 'all';
  bool _loading = true;
  String? _error;
  List<FeedbackItem> _items = const [];
  FeedbackItem? _selected;
  int _page = 1;

  static const _pageSize = 5;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() => _page = 1));
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await _repo.fetchFeedback(type: _type);
      if (!mounted) {
        return;
      }
      setState(() {
        _items = items;
        _loading = false;
        _page = 1;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<FeedbackItem> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _items;
    }

    return _items.where((item) {
      final target = [
        item.id,
        item.userName,
        item.type,
        item.message,
      ].join(' ').toLowerCase();
      return target.contains(query);
    }).toList();
  }

  int get _totalPages {
    final total = _filtered.length;
    if (total == 0) {
      return 1;
    }
    return (total / _pageSize).ceil();
  }

  List<FeedbackItem> get _paged {
    final list = _filtered;
    if (list.isEmpty) {
      return const [];
    }

    final safePage = _page.clamp(1, _totalPages);
    final start = (safePage - 1) * _pageSize;
    final end = (start + _pageSize).clamp(0, list.length);
    return list.sublist(start, end);
  }

  Future<void> _exportCsv() async {
    final rows = _filtered;
    final buffer = StringBuffer('id,user,type,message,created_at\n');
    for (final item in rows) {
      final message = item.message.replaceAll('"', '""').replaceAll('\n', ' ');
      buffer.writeln(
        '"${item.id}","${item.userName}","${item.type}","$message","${item.createdAt?.toIso8601String() ?? ''}"',
      );
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('CSV copied to clipboard.'),
      ),
    );
  }

  Future<void> _deleteSelected() async {
    final selected = _selected;
    if (selected == null) {
      return;
    }

    await _repo.deleteFeedback(selected.id);
    if (!mounted) {
      return;
    }
    setState(() {
      _selected = null;
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7FAFC),
      padding: const EdgeInsets.all(22),
      child: _selected == null ? _buildList() : _buildDetail(_selected!),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Feedback Overview',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w800,
                      fontSize: 21,
                      color: AdminColors.black,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Review and manage user experiences and reports.',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF6D7A90),
                    ),
                  ),
                ],
              ),
            ),
            _OutlineButton(
              text: 'Export CSV',
              icon: Icons.download_rounded,
              onTap: _exportCsv,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text(
              'TYPE:',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w800,
                color: Color(0xFF74839B),
              ),
            ),
            for (final option in _typeFilters)
              _FilterChipButton(
                label: option.label,
                selected: _type == option.value,
                onTap: () async {
                  setState(() => _type = option.value);
                  await _load();
                },
              ),
            SizedBox(
              width: 280,
              child: _SearchBox(controller: _searchController),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AdminColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AdminColors.divider),
            ),
            child: _filtered.isEmpty
                ? const Center(
                    child: Text(
                      'No feedback found.',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w700,
                        color: AdminColors.muted,
                      ),
                    ),
                  )
                : Column(
                    children: [
                      const _FeedbackHeader(),
                      Expanded(
                        child: ListView.separated(
                          itemCount: _paged.length,
                          separatorBuilder: (_, _) => const Divider(
                            height: 1,
                            color: AdminColors.divider,
                          ),
                          itemBuilder: (context, index) {
                            final item = _paged[index];
                            return _FeedbackRow(
                              item: item,
                              onView: () => setState(() => _selected = item),
                            );
                          },
                        ),
                      ),
                      _PaginationBar(
                        count: _filtered.length,
                        page: _page,
                        totalPages: _totalPages,
                        onPage: (next) => setState(() => _page = next),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetail(FeedbackItem item) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TextButton.icon(
                onPressed: () => setState(() => _selected = null),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Back to feedback'),
              ),
              const SizedBox(width: 12),
              Text(
                'Feedback Detail  ID: #${item.id}',
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _Card(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: const Color(0xFFE6FFF9),
                            child: Text(
                              _initials(item.userName),
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F7A67),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.userName,
                                  style: const TextStyle(
                                    fontFamily: 'Manrope',
                                    fontWeight: FontWeight.w800,
                                    fontSize: 20,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.type.toUpperCase(),
                                  style: const TextStyle(
                                    fontFamily: 'Manrope',
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF6382A8),
                                  ),
                                ),
                                Text(
                                  _dateTime(item.createdAt),
                                  style: const TextStyle(
                                    fontFamily: 'Manrope',
                                    fontWeight: FontWeight.w600,
                                    color: AdminColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Feedback Message',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            item.message,
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Color(0xFF263854),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  children: [
                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Admin Response',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F7FB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AdminColors.divider),
                            ),
                            child: const Text(
                              'Reply/resolve workflow is not available in current backend yet.',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF74839B),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.tonalIcon(
                              onPressed: _deleteSelected,
                              icon: const Icon(Icons.delete_outline_rounded),
                              label: const Text('Delete Feedback'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Metadata',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _meta('Feedback ID', item.id),
                          _meta('User ID', item.userId),
                          _meta('Type', item.type),
                          _meta('Submitted', _date(item.createdAt)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _meta(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w700,
                color: Color(0xFF74839B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '-' : value,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeFilter {
  const _TypeFilter({required this.value, required this.label});

  final String value;
  final String label;
}

const _typeFilters = [
  _TypeFilter(value: 'all', label: 'All Types'),
  _TypeFilter(value: 'bug', label: 'Bug'),
  _TypeFilter(value: 'suggestion', label: 'Suggestion'),
  _TypeFilter(value: 'praise', label: 'Praise'),
];

class _FeedbackHeader extends StatelessWidget {
  const _FeedbackHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF4F7FB),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
        ),
      ),
      child: const Row(
        children: [
          Expanded(flex: 3, child: _HeaderText('User')),
          Expanded(flex: 2, child: _HeaderText('Type')),
          Expanded(flex: 6, child: _HeaderText('Message')),
          Expanded(flex: 2, child: _HeaderText('Date')),
          Expanded(flex: 2, child: _HeaderText('Actions')),
        ],
      ),
    );
  }
}

class _FeedbackRow extends StatelessWidget {
  const _FeedbackRow({required this.item, required this.onView});

  final FeedbackItem item;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 74,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFE6FFF9),
                    child: Text(
                      _initials(item.userName),
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F7A67),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(flex: 2, child: _TypeBadge(type: item.type)),
            Expanded(
              flex: 6,
              child: Text(
                item.message,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5B6B84),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                _date(item.createdAt),
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5B6B84),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: TextButton.icon(
                onPressed: onView,
                icon: const Icon(Icons.visibility_rounded, size: 18),
                label: const Text('View'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final t = type.trim().toLowerCase();
    final bg = t == 'bug'
        ? const Color(0xFFFDE2E8)
        : t == 'suggestion'
        ? const Color(0xFFDFF0FF)
        : const Color(0xFFDDF9EA);
    final fg = t == 'bug'
        ? const Color(0xFFCC3057)
        : t == 'suggestion'
        ? const Color(0xFF226AB4)
        : const Color(0xFF0C9D63);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          t.isEmpty ? '-' : t.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w800,
            fontSize: 12,
            color: fg,
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.divider),
      ),
      child: child,
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
        color: Color(0xFF5E6D84),
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
            fontWeight: FontWeight.w700,
            color: selected ? const Color(0xFF0D7A67) : const Color(0xFF4F5E77),
          ),
        ),
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F5FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 18, color: Color(0xFF7D8AA0)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Search feedback...',
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

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({
    required this.text,
    required this.icon,
    required this.onTap,
  });

  final String text;
  final IconData icon;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Manrope',
          fontWeight: FontWeight.w700,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AdminColors.divider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.count,
    required this.page,
    required this.totalPages,
    required this.onPage,
  });

  final int count;
  final int page;
  final int totalPages;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AdminColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              count == 0
                  ? 'Showing 0 feedback submissions'
                  : 'Showing $count feedback submissions',
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w600,
                color: Color(0xFF607089),
              ),
            ),
          ),
          IconButton(
            onPressed: page > 1 ? () => onPage(page - 1) : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F5FA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AdminColors.divider),
            ),
            child: Text(
              '$page / $totalPages',
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: page < totalPages ? () => onPage(page + 1) : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

String _initials(String value) {
  final words = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  if (words.isEmpty) {
    return 'U';
  }
  if (words.length == 1) {
    return words.first.substring(0, 1).toUpperCase();
  }
  return '${words[0][0]}${words[1][0]}'.toUpperCase();
}

String _date(DateTime? dt) {
  if (dt == null) {
    return '-';
  }
  return DateFormat('MMM dd, yyyy').format(dt.toLocal());
}

String _dateTime(DateTime? dt) {
  if (dt == null) {
    return '-';
  }
  return DateFormat('MMM dd, yyyy - h:mm a').format(dt.toLocal());
}
