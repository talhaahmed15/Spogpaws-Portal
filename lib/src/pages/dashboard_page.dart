import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../admin_repository.dart';
import '../features/adoption_requests/presentation/widgets/adoption_requests_panel.dart';
import '../features/feedback/presentation/widgets/feedback_panel.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/spog_widgets.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key, required this.profile});

  final AdminProfile profile;

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _index = 0;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const DashboardOverviewPanel(),
      const UsersManagementPanel(),
      const AdoptionModerationPanel(),
      const ReportsPanel(),
      const SuggestionsPanel(),
    ];

    final titles = [
      'Overview',
      'User Management',
      'Adoption Requests',
      'Reports',
      'Feedback',
    ];

    final subtitles = [
      'Welcome back, here\'s what\'s happening today.',
      'Review, search, and manage all registered users.',
      'Review and moderate adoption listings.',
      'Handle adoption and user reports.',
      'Review user suggestions and feedback.',
    ];

    return Scaffold(
      body: Row(
        children: [
          _AdminSidebar(
            profile: widget.profile,
            selectedIndex: _index,
            onSelected: (index) => setState(() => _index = index),
          ),
          Expanded(
            child: Column(
              children: [
                _TopHeader(
                  title: titles[_index],
                  subtitle: subtitles[_index],
                  controller: _searchController,
                ),
                Expanded(child: pages[_index]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({
    required this.profile,
    required this.selectedIndex,
    required this.onSelected,
  });

  final AdminProfile profile;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = [
      _SidebarItemData(label: 'Dashboard', iconAsset: AdminIcons.home),
      _SidebarItemData(label: 'Users', iconAsset: AdminIcons.user),
      _SidebarItemData(label: 'Adoption Requests', iconAsset: AdminIcons.heart),
      _SidebarItemData(label: 'Reports', iconAsset: AdminIcons.flag),
      _SidebarItemData(label: 'Feedback', iconAsset: AdminIcons.lightbulb),
    ];

    return Container(
      width: 275,
      decoration: const BoxDecoration(
        color: AdminColors.white,
        border: Border(right: BorderSide(color: AdminColors.divider)),
      ),
      child: Column(
        children: [
          Container(
            height: 94,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AdminColors.divider)),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AdminColors.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/icons/spogpaws-logo.png',
                        width: 30,
                        height: 30,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'spogpaws',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: AdminColors.black,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      _prettyRole(profile.role),
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AdminColors.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < items.length; i++)
            _SidebarItem(
              data: items[i],
              selected: selectedIndex == i,
              onTap: () => onSelected(i),
            ),
          const Spacer(),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F6FB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AdminColors.divider),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AdminColors.accent.withValues(alpha: 0.14),
                  child: Text(
                    _initials(profile.displayName),
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: AdminColors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AdminColors.black,
                        ),
                      ),
                      Text(
                        profile.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AdminColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async => Supabase.instance.client.auth.signOut(),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF3FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AdminColors.divider),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      AdminIcons.exit,
                      width: 18,
                      height: 18,
                      colorFilter: const ColorFilter.mode(
                        AdminColors.black,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Logout',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AdminColors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItemData {
  const _SidebarItemData({required this.label, required this.iconAsset});

  final String label;
  final String iconAsset;
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _SidebarItemData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isReports = data.label.toLowerCase() == 'reports';
    final iconColor = isReports ? AdminColors.error : AdminColors.secondary;

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 5, 16, 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AdminColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              data.iconAsset,
              width: 18,
              height: 18,
              colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
            ),
            const SizedBox(width: 12),
            Text(
              data.label,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: selected ? AdminColors.black : const Color(0xFF3C4A62),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({
    required this.title,
    required this.subtitle,
    required this.controller,
  });

  final String title;
  final String subtitle;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 94,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: AdminColors.white,
        border: Border(bottom: BorderSide(color: AdminColors.divider)),
      ),
      child: Row(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: AdminColors.black,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AdminColors.muted,
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: 360,
            child: SpogSearchField(
              controller: controller,
              hintText: 'Search data, users...',
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F6FB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AdminColors.divider),
            ),
            child: IconButton(
              onPressed: () {},
              icon: SvgPicture.asset(
                AdminIcons.bell,
                width: 18,
                height: 18,
                colorFilter: const ColorFilter.mode(
                  AdminColors.muted,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 150,
            child: SpogButton(
              text: '+  New Listing',
              uppercase: false,
              height: 48,
              fontSize: 15,
              backgroundColor: AdminColors.accent,
              textColor: AdminColors.black,
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}

class SpogSearchField extends StatefulWidget {
  const SpogSearchField({
    super.key,
    required this.controller,
    required this.hintText,
  });

  final TextEditingController controller;
  final String hintText;

  @override
  State<SpogSearchField> createState() => _SpogSearchFieldState();
}

class _SpogSearchFieldState extends State<SpogSearchField> {
  final _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (mounted) {
      setState(() => _isFocused = _focusNode.hasFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isFocused ? AdminColors.accent : AdminColors.divider,
        ),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            AdminIcons.search,
            width: 18,
            height: 18,
            colorFilter: const ColorFilter.mode(
              AdminColors.muted,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: AdminColors.black,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: widget.hintText,
                hintStyle: const TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Color(0xFF9AA9BF),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardOverviewPanel extends StatefulWidget {
  const DashboardOverviewPanel({super.key});

  @override
  State<DashboardOverviewPanel> createState() => _DashboardOverviewPanelState();
}

class _DashboardOverviewPanelState extends State<DashboardOverviewPanel> {
  final _repo = AdminRepository();
  late Future<_DashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DashboardData> _load() async {
    final results = await Future.wait([
      _repo.fetchUsers(),
      _repo.fetchAdoptions(status: 'all'),
      _repo.fetchAdoptionReports(),
      _repo.fetchUserReports(),
    ]);

    final users = results[0] as List<AdminUser>;
    final adoptions = results[1] as List<AdminAdoption>;
    final adoptionReports = results[2] as List<AdoptionReportItem>;
    final userReports = results[3] as List<UserReportItem>;

    final pending = adoptions.where((e) => e.status == 'under_review').length;
    final activeAdoptions = adoptions
        .where((e) => e.status == 'approved' || e.status == 'adopted')
        .length;
    final now = DateTime.now();
    final newReports =
        adoptionReports
            .where(
              (e) =>
                  e.createdAt != null &&
                  now.difference(e.createdAt!).inDays <= 7,
            )
            .length +
        userReports
            .where(
              (e) =>
                  e.createdAt != null &&
                  now.difference(e.createdAt!).inDays <= 7,
            )
            .length;

    final activity = <_RecentActivityItem>[];
    for (final user in users.take(3)) {
      activity.add(
        _RecentActivityItem(
          title: 'New User Registration',
          detail: '${_displayUser(user)} joined the platform',
          createdAt: user.createdAt,
          color: const Color(0xFF0BC39B),
          iconAsset: AdminIcons.user,
        ),
      );
    }
    for (final post in adoptions.take(3)) {
      activity.add(
        _RecentActivityItem(
          title: 'New Pet Post',
          detail: '${post.petName} (${post.breed}) listed for adoption',
          createdAt: post.createdAt,
          color: const Color(0xFF25C2A0),
          iconAsset: AdminIcons.heart,
        ),
      );
    }
    for (final report in adoptionReports.take(2)) {
      activity.add(
        _RecentActivityItem(
          title: 'New Report Filed',
          detail: '${report.reason} flagged on listing #${report.adoptionId}',
          createdAt: report.createdAt,
          color: const Color(0xFFEF476F),
          iconAsset: AdminIcons.flag,
        ),
      );
    }

    activity.sort(
      (a, b) => (b.createdAt ?? DateTime(1970)).compareTo(
        a.createdAt ?? DateTime(1970),
      ),
    );

    final weekBuckets = [0, 0, 0, 0];
    for (final post in adoptions) {
      final date = post.createdAt;
      if (date == null) continue;
      final days = now.difference(date).inDays;
      if (days < 0 || days > 27) continue;
      final weekIndex = 3 - (days ~/ 7);
      if (weekIndex >= 0 && weekIndex <= 3)
        weekBuckets[weekIndex] = weekBuckets[weekIndex] + 1;
    }

    return _DashboardData(
      totalUsers: users.length,
      activeAdoptions: activeAdoptions,
      pendingRequests: pending,
      newReports: newReports,
      weeklyTrends: weekBuckets,
      recentRequests: adoptions.take(6).toList(),
      activity: activity.take(6).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DashboardData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return Center(child: Text('Error: ${snapshot.error}'));
        final data = snapshot.data;
        if (data == null)
          return const Center(child: Text('No dashboard data found.'));

        return Container(
          color: const Color(0xFFF7FAFC),
          padding: const EdgeInsets.all(22),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    _MetricCard(
                      label: 'Total Users',
                      value: _fmtInt(data.totalUsers),
                      delta: '+12.5%',
                      deltaPositive: true,
                      icon: AdminIcons.user,
                    ),
                    _MetricCard(
                      label: 'Active Adoptions',
                      value: _fmtInt(data.activeAdoptions),
                      delta: '+5.2%',
                      deltaPositive: true,
                      icon: AdminIcons.heart,
                    ),
                    _MetricCard(
                      label: 'Pending Requests',
                      value: _fmtInt(data.pendingRequests),
                      delta: '-2.4%',
                      deltaPositive: false,
                      icon: AdminIcons.library,
                    ),
                    _MetricCard(
                      label: 'New Reports',
                      value: _fmtInt(data.newReports),
                      delta: '+8%',
                      deltaPositive: true,
                      icon: AdminIcons.flag,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 430,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _TrendsCard(weeklyCounts: data.weeklyTrends),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _RecentActivityCard(items: data.activity),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _RecentRequestsCard(items: data.recentRequests),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DashboardData {
  const _DashboardData({
    required this.totalUsers,
    required this.activeAdoptions,
    required this.pendingRequests,
    required this.newReports,
    required this.weeklyTrends,
    required this.recentRequests,
    required this.activity,
  });

  final int totalUsers;
  final int activeAdoptions;
  final int pendingRequests;
  final int newReports;
  final List<int> weeklyTrends;
  final List<AdminAdoption> recentRequests;
  final List<_RecentActivityItem> activity;
}

class _RecentActivityItem {
  const _RecentActivityItem({
    required this.title,
    required this.detail,
    required this.createdAt,
    required this.color,
    required this.iconAsset,
  });

  final String title;
  final String detail;
  final DateTime? createdAt;
  final Color color;
  final String iconAsset;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.delta,
    required this.deltaPositive,
    required this.icon,
  });

  final String label;
  final String value;
  final String delta;
  final bool deltaPositive;
  final String icon;

  @override
  Widget build(BuildContext context) {
    final iconColor = icon == AdminIcons.flag
        ? AdminColors.error
        : AdminColors.secondary;

    return Container(
      width: 300,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AdminColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AdminColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F6FB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    icon,
                    width: 23,
                    height: 23,
                    colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: deltaPositive
                      ? const Color(0xFFDDF9EA)
                      : const Color(0xFFFDE2E8),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  delta,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: deltaPositive
                        ? const Color(0xFF0C9D63)
                        : const Color(0xFFDE2A5A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: Color(0xFF61708A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w800,
              fontSize: 26,
              color: AdminColors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendsCard extends StatelessWidget {
  const _TrendsCard({required this.weeklyCounts});

  final List<int> weeklyCounts;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AdminColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AdminColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Adoption Trends',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: AdminColors.black,
                    ),
                  ),
                  Text(
                    'Success rate over the last 30 days',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: AdminColors.muted,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F6FB),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Last 30 Days',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AdminColors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: CustomPaint(
              painter: _TrendPainter(weeklyCounts),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _WeekLabel('WEEK 1'),
              _WeekLabel('WEEK 2'),
              _WeekLabel('WEEK 3'),
              _WeekLabel('WEEK 4'),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekLabel extends StatelessWidget {
  const _WeekLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Manrope',
        fontWeight: FontWeight.w800,
        fontSize: 13,
        color: Color(0xFF8CA0BD),
        letterSpacing: 1,
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.counts);

  final List<int> counts;

  @override
  void paint(Canvas canvas, Size size) {
    final safeCounts = counts.length == 4 ? counts : [1, 2, 1, 3];
    final maxVal = math.max(1, safeCounts.reduce(math.max));
    final points = <Offset>[];
    for (var i = 0; i < safeCounts.length; i++) {
      final x = (size.width / 3) * i;
      final normalized = safeCounts[i] / maxVal;
      final y = size.height - ((size.height - 20) * normalized) - 10;
      points.add(Offset(x, y));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final current = points[i];
      final cp1 = Offset((prev.dx + current.dx) / 2, prev.dy);
      final cp2 = Offset((prev.dx + current.dx) / 2, current.dy);
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, current.dx, current.dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..style = PaintingStyle.fill
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x8025D8BE), Color(0x1A25D8BE)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = const Color(0xFF12D5BE)
        ..strokeCap = StrokeCap.round,
    );
    for (final point in points) {
      canvas.drawCircle(point, 5, Paint()..color = const Color(0xFF12D5BE));
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.counts != counts;
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({required this.items});

  final List<_RecentActivityItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AdminColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: AdminColors.black,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'View all',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w800,
                    color: AdminColors.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Builder(
                      builder: (_) {
                        final iconColor = item.iconAsset == AdminIcons.flag
                            ? AdminColors.error
                            : AdminColors.secondary;
                        return Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF3F6FB),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: SvgPicture.asset(
                              item.iconAsset,
                              width: 16,
                              height: 16,
                              colorFilter: ColorFilter.mode(
                                iconColor,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: AdminColors.black,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.detail,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AdminColors.muted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _timeAgo(item.createdAt),
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: Color(0xFF8DA1BB),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentRequestsCard extends StatelessWidget {
  const _RecentRequestsCard({required this.items});

  final List<AdminAdoption> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AdminColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AdminColors.divider),
      ),
      child: Column(
        children: [
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AdminColors.divider)),
            ),
            child: Row(
              children: [
                const Text(
                  'Recent Adoption Requests',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: AdminColors.black,
                  ),
                ),
                const Spacer(),
                _OutlineButton(label: 'Filter', onTap: () {}),
                const SizedBox(width: 10),
                _OutlineButton(label: 'Export CSV', onTap: () {}),
              ],
            ),
          ),
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            color: const Color(0xFFF4F7FB),
            child: const Row(
              children: [
                Expanded(flex: 4, child: _HeaderText('APPLICANT')),
                Expanded(flex: 3, child: _HeaderText('PET')),
                Expanded(flex: 3, child: _HeaderText('DATE SUBMITTED')),
                Expanded(flex: 2, child: _HeaderText('STATUS')),
                Expanded(flex: 2, child: _HeaderText('ACTION')),
              ],
            ),
          ),
          for (final post in items)
            Container(
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AdminColors.divider)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      post.ownerName,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      '${post.petName} (${post.petType})',
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      _fmtDate(post.createdAt),
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: AdminColors.muted,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _StatusPill(status: post.status),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text(
                        'VIEW DETAILS',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.w800,
                          color: AdminColors.accent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(18),
              child: Text('No recent adoption requests.'),
            ),
        ],
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AdminColors.divider),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: AdminColors.black,
          ),
        ),
      ),
    );
  }
}

class UsersManagementPanel extends StatefulWidget {
  const UsersManagementPanel({super.key});

  @override
  State<UsersManagementPanel> createState() => _UsersManagementPanelState();
}

class _UsersManagementPanelState extends State<UsersManagementPanel> {
  final _repo = AdminRepository();
  final _searchController = TextEditingController();
  late Future<List<AdminUser>> _future;
  String _statusFilter = 'all';
  String _sort = 'newest';
  int _page = 1;
  static const int _pageSize = 8;

  @override
  void initState() {
    super.initState();
    _future = _repo.fetchUsers();
    _searchController.addListener(() => setState(() => _page = 1));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _future = _repo.fetchUsers();
      _page = 1;
    });
  }

  Future<void> _toggleUserStatus(AdminUser user) async {
    final current = user.accountStatus.toLowerCase();
    final next = current == 'active' ? 'blocked' : 'active';
    await _repo.updateUserStatus(user.id, next);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Updated ${_displayUser(user)} to ${_prettyStatus(next)}.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7FAFC),
      padding: const EdgeInsets.all(22),
      child: FutureBuilder<List<AdminUser>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(child: Text('Error: ${snapshot.error}'));

          final allUsers = snapshot.data ?? const [];
          var filtered = allUsers.where((user) {
            final query = _searchController.text.trim().toLowerCase();
            final target =
                '${user.fullName} ${user.username} ${user.email} ${user.id}'
                    .toLowerCase();
            final status = user.accountStatus.toLowerCase();
            return (query.isEmpty || target.contains(query)) &&
                (_statusFilter == 'all' || status == _statusFilter);
          }).toList();

          filtered.sort((a, b) {
            final aa = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bb = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return _sort == 'newest' ? bb.compareTo(aa) : aa.compareTo(bb);
          });

          final totalPages = math.max(1, (filtered.length / _pageSize).ceil());
          _page = _page.clamp(1, totalPages);
          final start = (_page - 1) * _pageSize;
          final end = math.min(start + _pageSize, filtered.length);
          final pageUsers = start < filtered.length
              ? filtered.sublist(start, end)
              : <AdminUser>[];

          final activeCount = allUsers
              .where((e) => e.accountStatus == 'active')
              .length;
          final blockedCount = allUsers
              .where((e) => e.accountStatus == 'blocked')
              .length;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Manage Users',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.w800,
                              fontSize: 24,
                              color: AdminColors.black,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Review, search, and manage all registered platform participants.',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: AdminColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      child: SpogButton(
                        text: 'Invite New User',
                        uppercase: false,
                        height: 48,
                        fontSize: 16,
                        backgroundColor: AdminColors.accent,
                        textColor: AdminColors.black,
                        onTap: () {},
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AdminColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AdminColors.divider),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SpogSearchField(
                          controller: _searchController,
                          hintText: 'Search by name, email or ID...',
                        ),
                      ),
                      const SizedBox(width: 12),
                      _DropdownChip<String>(
                        value: _statusFilter,
                        width: 145,
                        items: const [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text('All Status'),
                          ),
                          DropdownMenuItem(
                            value: 'active',
                            child: Text('Active'),
                          ),
                          DropdownMenuItem(
                            value: 'blocked',
                            child: Text('Blocked'),
                          ),
                          DropdownMenuItem(
                            value: 'suspended',
                            child: Text('Suspended'),
                          ),
                          DropdownMenuItem(
                            value: 'banned',
                            child: Text('Banned'),
                          ),
                        ],
                        onChanged: (value) => setState(() {
                          _statusFilter = value ?? 'all';
                          _page = 1;
                        }),
                      ),
                      const SizedBox(width: 12),
                      _DropdownChip<String>(
                        value: _sort,
                        width: 168,
                        items: const [
                          DropdownMenuItem(
                            value: 'newest',
                            child: Text('Joined (Newest)'),
                          ),
                          DropdownMenuItem(
                            value: 'oldest',
                            child: Text('Joined (Oldest)'),
                          ),
                        ],
                        onChanged: (value) => setState(() {
                          _sort = value ?? 'newest';
                          _page = 1;
                        }),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 118,
                        child: SpogButton(
                          text: 'Filters',
                          uppercase: false,
                          height: 46,
                          fontSize: 15,
                          backgroundColor: const Color(0xFFEFF3FA),
                          textColor: AdminColors.black,
                          onTap: _reload,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: AdminColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AdminColors.divider),
                  ),
                  child: Column(
                    children: [
                      const _UsersHeaderRow(),
                      for (final user in pageUsers)
                        _UserRow(
                          user: user,
                          onToggleStatus: () => _toggleUserStatus(user),
                        ),
                      Container(
                        height: 68,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: AdminColors.divider),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Showing ${pageUsers.length} of ${filtered.length} users',
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AdminColors.muted,
                              ),
                            ),
                            const Spacer(),
                            _PaginationButton(
                              label: 'Previous',
                              enabled: _page > 1,
                              onTap: () => setState(() => _page--),
                            ),
                            const SizedBox(width: 8),
                            for (final pageNo in _buildPages(_page, totalPages))
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _PaginationButton(
                                  label: '$pageNo',
                                  compact: true,
                                  enabled: true,
                                  selected: pageNo == _page,
                                  onTap: () => setState(() => _page = pageNo),
                                ),
                              ),
                            _PaginationButton(
                              label: 'Next',
                              enabled: _page < totalPages,
                              onTap: () => setState(() => _page++),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        icon: AdminIcons.user,
                        title: 'Total Users',
                        value: _fmtInt(allUsers.length),
                        tint: const Color(0xFFD6F5EE),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _SummaryCard(
                        icon: AdminIcons.user,
                        title: 'Active Now',
                        value: _fmtInt(activeCount),
                        tint: const Color(0xFFD7F7E6),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _SummaryCard(
                        icon: AdminIcons.blockUser,
                        title: 'Blocked',
                        value: _fmtInt(blockedCount),
                        tint: const Color(0xFFFDE2E8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<int> _buildPages(int current, int total) {
    if (total <= 3) return List<int>.generate(total, (index) => index + 1);
    if (current <= 2) return [1, 2, 3];
    if (current >= total - 1) return [total - 2, total - 1, total];
    return [current - 1, current, current + 1];
  }
}

class _UsersHeaderRow extends StatelessWidget {
  const _UsersHeaderRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        color: Color(0xFFF4F7FB),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
        ),
      ),
      child: const Row(
        children: [
          Expanded(flex: 5, child: _HeaderText('USER')),
          Expanded(flex: 5, child: _HeaderText('EMAIL ADDRESS')),
          Expanded(flex: 3, child: _HeaderText('STATUS')),
          Expanded(flex: 3, child: _HeaderText('JOINED DATE')),
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
        fontSize: 14,
        color: Color(0xFF607089),
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({required this.user, required this.onToggleStatus});

  final AdminUser user;
  final VoidCallback onToggleStatus;

  @override
  Widget build(BuildContext context) {
    final status = user.accountStatus.toLowerCase();
    final active = status == 'active';

    return Container(
      height: 84,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AdminColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 21,
                  backgroundColor: const Color(0xFFE9EEF7),
                  child: Text(
                    _initials(_displayUser(user)),
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w800,
                      color: AdminColors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _displayUser(user),
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
            flex: 5,
            child: Text(
              user.email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Color(0xFF4A5A75),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _StatusPill(status: status),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              _fmtDate(user.createdAt),
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Color(0xFF4A5A75),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                _ActionCircle(
                  icon: AdminIcons.user,
                  tint: const Color(0xFF96A5BF),
                  onTap: () {},
                ),
                const SizedBox(width: 10),
                _ActionCircle(
                  icon: active ? AdminIcons.blockUser : AdminIcons.user,
                  tint: active ? const Color(0xFF96A5BF) : AdminColors.success,
                  onTap: onToggleStatus,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toLowerCase();
    late final Color bg;
    late final Color fg;

    switch (normalized) {
      case 'active':
      case 'approved':
        bg = const Color(0xFFDDF9EA);
        fg = const Color(0xFF0C9D63);
      case 'under_review':
      case 'pending':
        bg = const Color(0xFFDEE8FF);
        fg = const Color(0xFF3450BC);
      case 'adopted':
        bg = const Color(0xFFE2FAF5);
        fg = const Color(0xFF118A76);
      case 'rejected':
      case 'closed':
      case 'inactive':
      case 'blocked':
      case 'suspended':
        bg = const Color(0xFFFDE2E8);
        fg = const Color(0xFFDE2A5A);
      default:
        bg = const Color(0xFFE7EDF6);
        fg = const Color(0xFF50617C);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _prettyStatus(status),
        style: TextStyle(
          fontFamily: 'Manrope',
          fontWeight: FontWeight.w800,
          fontSize: 15,
          color: fg,
        ),
      ),
    );
  }
}

class _ActionCircle extends StatelessWidget {
  const _ActionCircle({
    required this.icon,
    required this.tint,
    required this.onTap,
  });

  final String icon;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4FB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AdminColors.divider),
        ),
        child: Center(
          child: SvgPicture.asset(
            icon,
            width: 16,
            height: 16,
            colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}

class _DropdownChip<T> extends StatelessWidget {
  const _DropdownChip({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.width,
  });

  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          borderRadius: BorderRadius.circular(12),
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: AdminColors.black,
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _PaginationButton extends StatelessWidget {
  const _PaginationButton({
    required this.label,
    required this.enabled,
    required this.onTap,
    this.compact = false,
    this.selected = false,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;
  final bool compact;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 40,
        width: compact ? 40 : null,
        padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 16),
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
            fontSize: 14,
            color: enabled ? AdminColors.black : AdminColors.muted,
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.tint,
  });

  final String icon;
  final String title;
  final String value;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 122,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AdminColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: SvgPicture.asset(
                icon,
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  AdminColors.accent,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Color(0xFF61708A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                  color: AdminColors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AdoptionModerationPanel extends StatelessWidget {
  const AdoptionModerationPanel({super.key});

  @override
  Widget build(BuildContext context) => const AdoptionRequestsPanel();
}

class ReportsPanel extends StatefulWidget {
  const ReportsPanel({super.key});

  @override
  State<ReportsPanel> createState() => _ReportsPanelState();
}

class _ReportsPanelState extends State<ReportsPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _reload() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Reports Review',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              IconButton(
                onPressed: _reload,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Adoption Reports'),
              Tab(text: 'User Reports'),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                Center(child: Text('Reports list unchanged')),
                Center(child: Text('Reports list unchanged')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SuggestionsPanel extends StatelessWidget {
  const SuggestionsPanel({super.key});

  @override
  Widget build(BuildContext context) => const FeedbackPanel();
}

String _displayUser(AdminUser user) {
  final full = user.fullName.trim();
  final username = user.username.trim();
  if (full.isNotEmpty) return full;
  if (username.isNotEmpty) return username;
  return user.email;
}

String _fmtInt(int value) => NumberFormat.decimalPattern().format(value);

String _fmtDate(DateTime? dt) {
  if (dt == null) return '-';
  return DateFormat('MMM dd, yyyy').format(dt.toLocal());
}

String _prettyStatus(String status) {
  if (status.trim().isEmpty) return '-';
  return status
      .replaceAll('_', ' ')
      .split(' ')
      .where((e) => e.isNotEmpty)
      .map((e) => '${e[0].toUpperCase()}${e.substring(1)}')
      .join(' ');
}

String _prettyRole(String role) {
  if (role.trim().isEmpty) return 'User';
  return role
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _initials(String value) {
  final words = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  if (words.isEmpty) return 'U';
  if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
  return '${words[0][0]}${words[1][0]}'.toUpperCase();
}

String _timeAgo(DateTime? dt) {
  if (dt == null) return 'DATE UNKNOWN';
  final diff = DateTime.now().difference(dt.toLocal());
  if (diff.inMinutes < 60) return '${math.max(1, diff.inMinutes)} MINS AGO';
  if (diff.inHours < 24) return '${diff.inHours} HOURS AGO';
  return '${diff.inDays} DAYS AGO';
}
