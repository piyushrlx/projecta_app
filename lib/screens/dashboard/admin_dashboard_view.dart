import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/widgets/brutalist_pressable.dart';
import '../../models/user_model.dart';
import '../projects/project_detail_screen.dart';
import '../projects/projects_list_screen.dart';
import '../reports/reports_list_screen.dart';
import '../tasks/create_task_screen.dart';
import '../tasks/task_detail_screen.dart';
import '../tasks/tasks_screen.dart';
import 'widgets/activity_timeline_tile.dart';
import 'widgets/dashboard_filter_sheet.dart';
import 'widgets/employee_workload_card.dart';
import 'widgets/kpi_card.dart';

class AdminDashboardView extends StatefulWidget {
  final UserModel user;
  final Map<String, dynamic> data;
  final VoidCallback onRefresh;
  final Function(int? projectId, int? departmentId, int? userId)? onFilterChanged;
  final int? selectedProjectId;
  final int? selectedDepartmentId;
  final int? selectedUserId;
  final int initialSubTab;

  const AdminDashboardView({
    super.key,
    required this.user,
    required this.data,
    required this.onRefresh,
    this.onFilterChanged,
    this.selectedProjectId,
    this.selectedDepartmentId,
    this.selectedUserId,
    this.initialSubTab = 0,
  });

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  late int _selectedSubTabIndex;
  String _projectSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedSubTabIndex = widget.initialSubTab;
  }

  @override
  Widget build(BuildContext context) {
    final kpis = (widget.data['kpis'] as Map<String, dynamic>?) ?? {};
    final alerts = (widget.data['alerts'] as Map<String, dynamic>?) ?? {};
    final activeProjects = (widget.data['active_projects'] as List<dynamic>?) ?? [];
    final employees = (widget.data['employee_overview'] as List<dynamic>?) ?? [];
    final activity = (widget.data['recent_activity'] as List<dynamic>?) ?? [];
    final filterOptions = (widget.data['filter_options'] as Map<String, dynamic>?) ?? {};

    final overdueTasksCount = (kpis['overdue_tasks'] ?? 0) as int;
    final reportsPendingCount = (kpis['reports_pending_today'] ?? 0) as int;
    final awaitingReviewCount = (alerts['reports_awaiting_review'] ?? 0) as int;
    final compliancePercent = (kpis['compliance_percent'] ?? 0) as int;

    final overdueList = (alerts['overdue_tasks'] as List<dynamic>?) ?? [];
    final blockedList = (alerts['blocked_tasks'] as List<dynamic>?) ?? [];
    final approachingList =
        (alerts['approaching_projects'] as List<dynamic>?) ?? [];
    final staleList = (alerts['stale_tasks'] as List<dynamic>?) ?? [];
    final missingReportsList =
        (alerts['missing_reports'] as List<dynamic>?) ?? [];

    final hasActiveFilters = (widget.selectedProjectId != null && widget.selectedProjectId! > 0) ||
        (widget.selectedDepartmentId != null && widget.selectedDepartmentId! > 0) ||
        (widget.selectedUserId != null && widget.selectedUserId! > 0);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      children: [
        // PART A: COMPACT TOP SUMMARY
        // 1. Top Urgent Action Strip with Filter Trigger
        _buildUrgentActionStrip(
          context,
          overdueTasksCount,
          reportsPendingCount,
          awaitingReviewCount,
          filterOptions,
          hasActiveFilters,
        ),
        const SizedBox(height: 12),

        // 2. Quick Actions Bar (Immediately below top banner for instant 1-tap access)
        _buildQuickActions(context),
        const SizedBox(height: 16),

        // PART B: SEGMENTED PILL TAB BAR
        _buildSegmentedPills(),
        const SizedBox(height: 16),

        // SUB-TAB CONTENT
        if (_selectedSubTabIndex == 0)
          _buildOverviewTab(
            context,
            kpis,
            alerts,
            overdueTasksCount,
            reportsPendingCount,
            compliancePercent,
            overdueList,
            blockedList,
            activeProjects,
          )
        else if (_selectedSubTabIndex == 1)
          _buildProjectsTab(context, activeProjects)
        else if (_selectedSubTabIndex == 2)
          _buildTeamTab(context, employees, compliancePercent)
        else
          _buildRisksAndActivityTab(
            context,
            overdueList,
            blockedList,
            approachingList,
            staleList,
            missingReportsList,
            activity,
          ),
      ],
    );
  }

  // Segmented Pill TabBar
  Widget _buildSegmentedPills() {
    final tabs = [
      {'label': 'Overview', 'icon': Icons.dashboard_outlined},
      {'label': 'Projects', 'icon': Icons.folder_outlined},
      {'label': 'Team', 'icon': Icons.people_outline},
      {'label': 'Risks & Logs', 'icon': Icons.warning_amber_rounded},
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedSubTabIndex == index;
          return Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedSubTabIndex = index;
                });
              },
              borderRadius: BorderRadius.circular(7),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.royalBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  boxShadow: isSelected ? const [AppTheme.softShadow] : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      tabs[index]['icon'] as IconData,
                      size: 13,
                      color: isSelected ? AppTheme.pureWhite : AppTheme.mutedSlate,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        tabs[index]['label'] as String,
                        style: AppTheme.heading(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected ? AppTheme.pureWhite : AppTheme.deepSlate,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // SUB-TAB 1: OVERVIEW (Compact KPIs + Previews of Risks and Projects)
  Widget _buildOverviewTab(
    BuildContext context,
    Map<String, dynamic> kpis,
    Map<String, dynamic> alerts,
    int overdueTasksCount,
    int reportsPendingCount,
    int compliancePercent,
    List<dynamic> overdueList,
    List<dynamic> blockedList,
    List<dynamic> activeProjects,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 10 Core Metrics Header
        Text(
          '10 Core Metrics',
          style: AppTheme.heading(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.deepSlate,
          ),
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: KpiCard(
                label: 'Active Projects',
                value: '${kpis['active_projects'] ?? 0}',
                onTap: () => setState(() => _selectedSubTabIndex = 1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: KpiCard(
                label: 'Completed Projects',
                value: '${kpis['completed_projects'] ?? 0}',
                onTap: () => setState(() => _selectedSubTabIndex = 1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Row 2: Open Tasks Assigned & Tasks In Progress
        Row(
          children: [
            Expanded(
              child: KpiCard(
                label: 'Open Tasks Assigned',
                value: '${kpis['open_tasks'] ?? 0}',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TasksScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: KpiCard(
                label: 'Tasks In Progress',
                value: '${kpis['tasks_in_progress'] ?? 0}',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TasksScreen()),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: KpiCard(
                label: 'Completed Tasks',
                value: '${kpis['completed_tasks'] ?? 0}',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TasksScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: KpiCard(
                label: 'Pending Tasks',
                value: '${kpis['pending_tasks'] ?? 0}',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TasksScreen()),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: KpiCard(
                label: 'Overdue Tasks',
                value: '$overdueTasksCount',
                isUrgent: overdueTasksCount > 0,
                subtitle: overdueTasksCount > 0 ? 'Requires attention' : 'Clear',
                onTap: () => setState(() => _selectedSubTabIndex = 3),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: KpiCard(
                label: 'Active Staff',
                value: '${kpis['active_employees'] ?? 0}',
                onTap: () => setState(() => _selectedSubTabIndex = 2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Row 5: Reports Submitted Today & Reports Pending Today
        Row(
          children: [
            Expanded(
              child: KpiCard(
                label: 'Reports Submitted Today',
                value: '${kpis['reports_submitted_today'] ?? 0}',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReportsListScreen(user: widget.user),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: KpiCard(
                label: 'Reports Pending Today',
                value: '$reportsPendingCount',
                isUrgent: reportsPendingCount > 0,
                subtitle: '$compliancePercent% compliance',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReportsListScreen(user: widget.user),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Risk & Alert Center Preview
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppTheme.dangerText,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Risk & Alert Center',
                      style: AppTheme.heading(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.deepSlate,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () => setState(() => _selectedSubTabIndex = 3),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Text(
                  'See All ->',
                  style: AppTheme.heading(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.royalBlue,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        if (overdueList.isEmpty && blockedList.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.pureWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Text(
              'No active risks or bottlenecks detected.',
              style: AppTheme.body(fontSize: 12, color: AppTheme.mutedSlate),
            ),
          )
        else ...[
          ...overdueList.take(2).map((t) => _buildOverdueItem(context, t as Map<String, dynamic>)),
          ...blockedList.take(2).map((t) => _buildBlockedItem(context, t as Map<String, dynamic>)),
        ],
        const SizedBox(height: 18),

        // Active Projects Overview Preview
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Active Projects Overview',
                style: AppTheme.heading(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.deepSlate,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            InkWell(
              onTap: () => setState(() => _selectedSubTabIndex = 1),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Text(
                  'See All ->',
                  style: AppTheme.heading(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.royalBlue,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        if (activeProjects.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.pureWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Center(
              child: Text(
                'No active projects found.',
                style: AppTheme.body(fontSize: 12, color: AppTheme.mutedSlate),
              ),
            ),
          )
        else
          ...activeProjects.take(3).map((p) => _buildProjectCard(context, p as Map<String, dynamic>)),
      ],
    );
  }

  // SUB-TAB 2: PROJECTS (Full Projects List with Search)
  Widget _buildProjectsTab(BuildContext context, List<dynamic> activeProjects) {
    final filtered = activeProjects.where((p) {
      if (_projectSearchQuery.isEmpty) return true;
      final name = (p['name'] ?? '').toString().toLowerCase();
      final code = (p['project_code'] ?? '').toString().toLowerCase();
      return name.contains(_projectSearchQuery.toLowerCase()) ||
          code.contains(_projectSearchQuery.toLowerCase());
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search & Count Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.pureWhite,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, size: 18, color: AppTheme.mutedSlate),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search projects by name or code...',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  style: AppTheme.body(fontSize: 13, color: AppTheme.deepSlate),
                  onChanged: (val) => setState(() => _projectSearchQuery = val),
                ),
              ),
              if (_projectSearchQuery.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: () => setState(() => _projectSearchQuery = ''),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'All Active Projects (${filtered.length})',
                style: AppTheme.heading(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.deepSlate,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProjectsListScreen()),
                );
              },
              child: Text(
                'Directory ->',
                style: AppTheme.heading(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.royalBlue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.pureWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Center(
              child: Text(
                'No projects match "$_projectSearchQuery"',
                style: AppTheme.body(fontSize: 13, color: AppTheme.mutedSlate),
              ),
            ),
          )
        else
          ...filtered.map((p) => _buildProjectCard(context, p as Map<String, dynamic>)),
      ],
    );
  }

  // SUB-TAB 3: TEAM (Employee Work Overview & Compliance Header)
  Widget _buildTeamTab(
    BuildContext context,
    List<dynamic> employees,
    int compliancePercent,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Employee Work Overview',
                style: AppTheme.heading(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.deepSlate,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: compliancePercent > 70
                    ? AppTheme.successBg
                    : (compliancePercent > 30 ? AppTheme.warningBg : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Compliance ($compliancePercent% today)',
                style: AppTheme.heading(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: compliancePercent > 70
                      ? AppTheme.successText
                      : (compliancePercent > 30 ? AppTheme.warningText : AppTheme.mutedSlate),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (employees.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.pureWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Center(
              child: Text(
                'No employee workload data available.',
                style: AppTheme.body(fontSize: 13, color: AppTheme.mutedSlate),
              ),
            ),
          )
        else
          ...employees.map(
            (em) => EmployeeWorkloadCard(
              employee: em as Map<String, dynamic>,
            ),
          ),
      ],
    );
  }

  // SUB-TAB 4: RISKS & RECENT ACTIVITY
  Widget _buildRisksAndActivityTab(
    BuildContext context,
    List<dynamic> overdueList,
    List<dynamic> blockedList,
    List<dynamic> approachingList,
    List<dynamic> staleList,
    List<dynamic> missingReportsList,
    List<dynamic> activity,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Comprehensive Risk Center
        _buildRiskAlertCenter(
          context,
          overdueList,
          blockedList,
          approachingList,
          staleList,
          missingReportsList,
        ),
        const SizedBox(height: 20),

        // Recent Activity Live Stream
        Text(
          'Recent Activity',
          style: AppTheme.heading(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.deepSlate,
          ),
        ),
        const SizedBox(height: 10),

        if (activity.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.pureWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Center(
              child: Text(
                'No recent activity recorded.',
                style: AppTheme.body(fontSize: 12, color: AppTheme.mutedSlate),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.pureWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderSubtle),
              boxShadow: const [AppTheme.softShadow],
            ),
            child: Column(
              children: List.generate(
                activity.length,
                (index) => ActivityTimelineTile(
                  activity: activity[index] as Map<String, dynamic>,
                  isLast: index == activity.length - 1,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Top Urgent Action Strip (Header with Overflow-Proof Flex)
  Widget _buildUrgentActionStrip(
    BuildContext context,
    int overdueTasksCount,
    int reportsPendingCount,
    int awaitingReviewCount,
    Map<String, dynamic> filterOptions,
    bool hasActiveFilters,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle, width: 1.0),
        boxShadow: const [AppTheme.softShadow],
      ),
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Zero-Overflow Wrapping
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.infoBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Admin Executive Control',
                    style: AppTheme.heading(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.infoText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        widget.data['date']?.toString() ?? '',
                        style: AppTheme.mono(
                          fontSize: 11,
                          color: AppTheme.mutedSlate,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.onFilterChanged != null) ...[
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => DashboardFilterSheet(
                              filterOptions: filterOptions,
                              selectedProjectId: widget.selectedProjectId,
                              selectedDepartmentId: widget.selectedDepartmentId,
                              selectedUserId: widget.selectedUserId,
                              onApply: (p, d, u) {
                                widget.onFilterChanged?.call(p, d, u);
                              },
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: hasActiveFilters ? AppTheme.royalBlue : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.filter_list,
                                size: 12,
                                color: hasActiveFilters ? AppTheme.pureWhite : AppTheme.mutedSlate,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                hasActiveFilters ? 'Active' : 'Filter',
                                style: AppTheme.heading(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: hasActiveFilters ? AppTheme.pureWhite : AppTheme.mutedSlate,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Overdue & Reports Pending Counters
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TasksScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: overdueTasksCount > 0
                          ? const Color(0xFFFEF2F2)
                          : AppTheme.scaffoldBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: overdueTasksCount > 0
                            ? const Color(0xFFFECACA)
                            : AppTheme.borderSubtle,
                        width: 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Overdue Tasks',
                          style: AppTheme.heading(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: overdueTasksCount > 0
                                ? AppTheme.dangerText
                                : AppTheme.deepSlate,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$overdueTasksCount',
                          style: AppTheme.heading(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: overdueTasksCount > 0
                                ? AppTheme.dangerText
                                : AppTheme.deepSlate,
                          ),
                        ),
                        Text(
                          overdueTasksCount > 0 ? 'Tap to resolve' : 'All on schedule',
                          style: AppTheme.body(
                            fontSize: 10,
                            color: AppTheme.mutedSlate,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReportsListScreen(user: widget.user),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: awaitingReviewCount > 0 || reportsPendingCount > 0
                          ? const Color(0xFFFEF3C7).withValues(alpha: 0.5)
                          : AppTheme.scaffoldBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: awaitingReviewCount > 0 || reportsPendingCount > 0
                            ? const Color(0xFFFDE68A)
                            : AppTheme.borderSubtle,
                        width: 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pending Reports Today',
                          style: AppTheme.heading(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: reportsPendingCount > 0
                                ? AppTheme.warningText
                                : AppTheme.deepSlate,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$reportsPendingCount',
                          style: AppTheme.heading(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: reportsPendingCount > 0
                                ? AppTheme.warningText
                                : AppTheme.deepSlate,
                          ),
                        ),
                        Text(
                          reportsPendingCount > 0
                              ? (awaitingReviewCount > 0 ? '$awaitingReviewCount awaiting approval' : 'Awaiting submission')
                              : 'Team up to date',
                          style: AppTheme.body(
                            fontSize: 10,
                            color: AppTheme.mutedSlate,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (awaitingReviewCount > 0) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReportsListScreen(user: widget.user),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.warningBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.assignment_late_outlined,
                      color: AppTheme.warningText,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Reports Awaiting Review',
                        style: AppTheme.heading(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.warningText,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppTheme.warningText,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$awaitingReviewCount',
                        style: AppTheme.mono(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.pureWhite,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppTheme.warningText,
                      size: 10,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Quick Actions Bar (Positioned directly below top banner for instant 1-tap access)
  Widget _buildQuickActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle),
        boxShadow: const [AppTheme.softShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Quick Actions',
                  style: AppTheme.heading(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.deepSlate,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.bolt, size: 16, color: AppTheme.royalBlue),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildActionChip(
                context,
                icon: Icons.add_task,
                label: '+ Assign Task',
                isPrimary: true,
                onTap: () async {
                  final res = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateTaskScreen(),
                    ),
                  );
                  if (res == true) widget.onRefresh();
                },
              ),
              _buildActionChip(
                context,
                icon: Icons.folder_open,
                label: 'Projects',
                isPrimary: false,
                onTap: () => setState(() => _selectedSubTabIndex = 1),
              ),
              _buildActionChip(
                context,
                icon: Icons.assignment_turned_in_outlined,
                label: 'Review Reports',
                isPrimary: false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReportsListScreen(user: widget.user),
                    ),
                  );
                },
              ),
              _buildActionChip(
                context,
                icon: Icons.timer_off_outlined,
                label: 'Overdue Backlog',
                isPrimary: false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TasksScreen(initialFilter: 'Overdue'),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return BrutalistPressable(
      onTap: onTap,
      backgroundColor: isPrimary ? AppTheme.royalBlue : AppTheme.scaffoldBg,
      borderColor: isPrimary ? AppTheme.royalBlue : AppTheme.borderSubtle,
      borderRadius: BorderRadius.circular(8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isPrimary ? AppTheme.pureWhite : AppTheme.deepSlate,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTheme.heading(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isPrimary ? AppTheme.pureWhite : AppTheme.deepSlate,
            ),
          ),
        ],
      ),
    );
  }

  // Full Risk & Alert Center
  Widget _buildRiskAlertCenter(
    BuildContext context,
    List<dynamic> overdueList,
    List<dynamic> blockedList,
    List<dynamic> approachingList,
    List<dynamic> staleList,
    List<dynamic> missingReportsList,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppTheme.dangerText,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              'Risk & Alert Center',
              style: AppTheme.heading(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.deepSlate,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Overdue Tasks
        if (overdueList.isNotEmpty) ...[
          Text(
            'Overdue Tasks (${overdueList.length})',
            style: AppTheme.heading(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.dangerText,
            ),
          ),
          const SizedBox(height: 6),
          ...overdueList.map((t) => _buildOverdueItem(context, t as Map<String, dynamic>)),
          const SizedBox(height: 12),
        ],

        // Approaching Project Deadlines (< 7 days)
        if (approachingList.isNotEmpty) ...[
          Text(
            'Projects due within 7 days (${approachingList.length})',
            style: AppTheme.heading(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.warningText,
            ),
          ),
          const SizedBox(height: 6),
          ...approachingList.map((p) {
            final proj = p as Map<String, dynamic>;
            final id = (proj['id'] as num?)?.toInt();
            return BrutalistPressable(
              onTap: id != null
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProjectDetailScreen(projectId: id),
                        ),
                      );
                    }
                  : null,
              backgroundColor: AppTheme.pureWhite,
              borderColor: const Color(0xFFFDE68A),
              borderRadius: BorderRadius.circular(10),
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      proj['name']?.toString() ?? '',
                      style: AppTheme.heading(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.deepSlate,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.warningBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Due ${proj['deadline'] ?? ''}',
                      style: AppTheme.mono(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.warningText,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
        ],

        // Missing Daily Reports List
        if (missingReportsList.isNotEmpty) ...[
          Text(
            "Missing Today's Report (${missingReportsList.length})",
            style: AppTheme.heading(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFEA580C),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.pureWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: Column(
              children: missingReportsList.take(6).map((m) {
                final staff = m as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          staff['full_name']?.toString() ?? '',
                          style: AppTheme.heading(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.deepSlate,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        staff['department_name']?.toString() ?? '',
                        style: AppTheme.body(
                          fontSize: 11,
                          color: AppTheme.mutedSlate,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Blocked Tasks
        if (blockedList.isNotEmpty) ...[
          Text(
            'Blocked Tasks (${blockedList.length})',
            style: AppTheme.heading(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.warningText,
            ),
          ),
          const SizedBox(height: 6),
          ...blockedList.map((t) => _buildBlockedItem(context, t as Map<String, dynamic>)),
          const SizedBox(height: 12),
        ],

        // Stale Tasks (no update for 3+ days)
        if (staleList.isNotEmpty) ...[
          Text(
            'No update for 3+ days (${staleList.length})',
            style: AppTheme.heading(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.mutedSlate,
            ),
          ),
          const SizedBox(height: 6),
          ...staleList.map((st) {
            final task = st as Map<String, dynamic>;
            final id = (task['id'] as num?)?.toInt();
            return BrutalistPressable(
              onTap: id != null
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TaskDetailScreen(taskId: id),
                        ),
                      );
                    }
                  : null,
              backgroundColor: AppTheme.pureWhite,
              borderColor: AppTheme.borderSubtle,
              borderRadius: BorderRadius.circular(10),
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task['title']?.toString() ?? '',
                          style: AppTheme.heading(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.deepSlate,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          task['project_name']?.toString() ?? '',
                          style: AppTheme.body(
                            fontSize: 11,
                            color: AppTheme.mutedSlate,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    task['time_ago']?.toString() ?? '',
                    style: AppTheme.mono(
                      fontSize: 10,
                      color: AppTheme.lightSlate,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildOverdueItem(BuildContext context, Map<String, dynamic> task) {
    final id = (task['id'] as num?)?.toInt();
    final daysLate = task['days_overdue'] ?? '';
    return BrutalistPressable(
      onTap: id != null
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TaskDetailScreen(taskId: id),
                ),
              );
            }
          : null,
      backgroundColor: AppTheme.pureWhite,
      borderColor: const Color(0xFFFECACA),
      borderRadius: BorderRadius.circular(10),
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task['title']?.toString() ?? '',
                  style: AppTheme.heading(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.deepSlate,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  task['project_name']?.toString() ?? '',
                  style: AppTheme.body(
                    fontSize: 11,
                    color: AppTheme.mutedSlate,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.dangerBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              daysLate.toString().isNotEmpty
                  ? '${daysLate}d late'
                  : 'Due: ${task['deadline'] ?? ''}',
              style: AppTheme.mono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppTheme.dangerText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedItem(BuildContext context, Map<String, dynamic> task) {
    final id = (task['id'] as num?)?.toInt();
    return BrutalistPressable(
      onTap: id != null
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TaskDetailScreen(taskId: id),
                ),
              );
            }
          : null,
      backgroundColor: AppTheme.pureWhite,
      borderColor: const Color(0xFFFDE68A),
      borderRadius: BorderRadius.circular(10),
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(
            Icons.block,
            color: AppTheme.warningText,
            size: 16,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              task['title']?.toString() ?? '',
              style: AppTheme.heading(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.deepSlate,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            task['project_name']?.toString() ?? '',
            style: AppTheme.body(
              fontSize: 11,
              color: AppTheme.mutedSlate,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Compact Project Health Overview Card with Clean 1-Row Header & Wrap Bottom
  Widget _buildProjectCard(BuildContext context, Map<String, dynamic> proj) {
    final percent = (proj['completion_percent'] ?? 0) as int;
    final overdue = (proj['overdue_tasks'] ?? 0) as int;
    final done = (proj['done_tasks'] ?? 0) as int;
    final pending = (proj['pending_tasks'] ?? 0) as int;
    final id = (proj['id'] as num?)?.toInt();
    final members = (proj['members'] as List<dynamic>?) ?? [];
    final memberCount = (proj['member_count'] as num?)?.toInt() ?? members.length;
    final code = proj['project_code']?.toString() ?? '';
    final priority = proj['priority']?.toString() ?? 'Medium';

    return BrutalistPressable(
      onTap: id != null
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProjectDetailScreen(projectId: id),
                ),
              );
            }
          : null,
      backgroundColor: AppTheme.pureWhite,
      borderColor: AppTheme.borderSubtle,
      borderRadius: BorderRadius.circular(12),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Single Header Row: [P-0001] [Priority] Title ... [X%]
          Row(
            children: [
              if (code.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    code,
                    style: AppTheme.mono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.deepSlate,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: priority.toLowerCase() == 'urgent'
                      ? AppTheme.dangerBg
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Text(
                  priority,
                  style: AppTheme.heading(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: priority.toLowerCase() == 'urgent'
                        ? AppTheme.dangerText
                        : AppTheme.mutedSlate,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  proj['name']?.toString() ?? '',
                  style: AppTheme.heading(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.deepSlate,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.infoBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$percent%',
                  style: AppTheme.mono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.infoText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Subtitle: Manager & Due Date
          Text(
            'Manager: ${proj['manager_name'] ?? 'Unassigned'} · Due: ${proj['deadline'] ?? 'No date'}',
            style: AppTheme.body(
              fontSize: 11,
              color: AppTheme.mutedSlate,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // Compact Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (percent / 100).clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.royalBlue,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Bottom Row with Wrap to Guarantee Zero Overflow
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              // Team Avatars
              _buildTeamAvatars(members, memberCount),

              // Task counts: Done, Pending, Overdue (Wrap to prevent any overflow on narrow screens)
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 4,
                children: [
                  Text(
                    'Done: $done · Pending: $pending',
                    style: AppTheme.body(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.mutedSlate,
                    ),
                  ),
                  if (overdue > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppTheme.dangerBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Overdue: $overdue',
                        style: AppTheme.mono(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.dangerText,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamAvatars(List<dynamic> members, int memberCount) {
    if (members.isEmpty) {
      return Text(
        '$memberCount members',
        style: AppTheme.body(fontSize: 10, color: AppTheme.lightSlate),
      );
    }
    final display = members.take(4).toList();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...display.map((m) {
          final member = m as Map<String, dynamic>;
          final name = member['full_name']?.toString() ?? '';
          final photo = member['profile_photo']?.toString();
          return Container(
            margin: const EdgeInsets.only(right: 3),
            child: photo != null && photo.isNotEmpty && photo.startsWith('http')
                ? CircleAvatar(radius: 10, backgroundImage: NetworkImage(photo))
                : CircleAvatar(
                    radius: 10,
                    backgroundColor: const Color(0xFFE2E8F0),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.mutedSlate,
                      ),
                    ),
                  ),
          );
        }),
        if (memberCount > 4)
          Text(
            '+${memberCount - 4}',
            style: AppTheme.mono(fontSize: 10, color: AppTheme.lightSlate),
          ),
      ],
    );
  }
}
