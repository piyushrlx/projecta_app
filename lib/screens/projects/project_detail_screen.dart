import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/project_model.dart';
import '../../services/project_service.dart';
import '../tasks/tasks_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  final int projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final ProjectService _projectService = ProjectService();

  bool _isLoading = true;
  String? _errorMessage;
  ProjectDetailModel? _detail;

  @override
  void initState() {
    super.initState();
    _loadProjectDetail();
  }

  Future<void> _loadProjectDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _projectService.getProjectDetails(widget.projectId);
      if (mounted) {
        setState(() {
          _detail = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('ApiException', '').trim();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: Text(
          _detail != null ? _detail!.project.projectCode : 'Project Details',
          style: AppTheme.mono(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadProjectDetail,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.royalBlue,
                strokeWidth: 2.5,
              ),
            )
          : _errorMessage != null
          ? _buildErrorView()
          : _detail == null
          ? const SizedBox.shrink()
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final detail = _detail!;
    final p = detail.project;

    return RefreshIndicator(
      onRefresh: _loadProjectDetail,
      color: AppTheme.royalBlue,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Header Summary Card
          _buildOverviewCard(p, detail),
          const SizedBox(height: 16),

          // 2. Task Breakdown Metrics
          _buildTaskCountsCard(detail.taskCounts),
          const SizedBox(height: 16),

          // 3. Button: View All Project Tasks
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        TasksScreen(projectId: p.id, projectName: p.name),
                  ),
                );
              },
              icon: const Icon(Icons.task_alt, size: 18),
              label: Text(
                'View All Project Tasks (${detail.taskCounts.total})',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.navyBlue,
                foregroundColor: AppTheme.pureWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 4. Milestones Section
          _buildMilestonesSection(detail.milestones),
          const SizedBox(height: 24),

          // 5. Team Members Strip
          _buildTeamSection(detail.members),
          const SizedBox(height: 24),

          // 6. Scope & Deliverables
          if ((detail.scopeOfWork != null && detail.scopeOfWork!.isNotEmpty) ||
              (detail.deliverables != null &&
                  detail.deliverables!.isNotEmpty)) ...[
            _buildScopeSection(detail),
            const SizedBox(height: 24),
          ],

          // 7. Recent Activity Section
          if (detail.recentActivity.isNotEmpty) ...[
            _buildActivitySection(detail.recentActivity),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildOverviewCard(ProjectModel p, ProjectDetailModel detail) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle, width: 1.0),
        boxShadow: const [AppTheme.softShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.scaffoldBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Text(
                  p.projectCode,
                  style: AppTheme.mono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.deepSlate,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: p.isActive
                      ? AppTheme.infoBg
                      : p.isCompleted
                      ? AppTheme.successBg
                      : AppTheme.warningBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  p.status.isEmpty
                      ? 'Active'
                      : p.status[0].toUpperCase() +
                            p.status.substring(1).toLowerCase(),
                  style: AppTheme.heading(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: p.isActive
                        ? AppTheme.infoText
                        : p.isCompleted
                        ? AppTheme.successText
                        : AppTheme.warningText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            p.name,
            style: AppTheme.heading(fontSize: 18, color: AppTheme.deepSlate),
          ),
          if (p.clientName != null && p.clientName!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Client: ${p.clientName}',
              style: AppTheme.body(fontSize: 13, color: AppTheme.mutedSlate),
            ),
          ],
          const SizedBox(height: 16),
          // Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Project Completion',
                style: AppTheme.heading(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.mutedSlate,
                ),
              ),
              Text(
                '${p.completionPercent.toStringAsFixed(1)}%',
                style: AppTheme.mono(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.deepSlate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (p.completionPercent / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.royalBlue,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.borderSubtle, thickness: 1.0),
          const SizedBox(height: 12),
          // Dates & Manager
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start Date',
                      style: AppTheme.body(
                        fontSize: 11,
                        color: AppTheme.mutedSlate,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.startDate ?? 'None',
                      style: AppTheme.mono(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.deepSlate,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Deadline',
                      style: AppTheme.body(
                        fontSize: 11,
                        color: AppTheme.mutedSlate,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.deadline ?? 'None',
                      style: AppTheme.mono(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: p.overdueTasks > 0
                            ? AppTheme.dangerText
                            : AppTheme.deepSlate,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Department',
                      style: AppTheme.body(
                        fontSize: 11,
                        color: AppTheme.mutedSlate,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.departmentName ?? 'General',
                      style: AppTheme.body(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.deepSlate,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manager',
                      style: AppTheme.body(
                        fontSize: 11,
                        color: AppTheme.mutedSlate,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.managerName ?? 'Unassigned',
                      style: AppTheme.body(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.deepSlate,
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

  Widget _buildTaskCountsCard(ProjectTaskCountsModel counts) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle, width: 1.0),
        boxShadow: const [AppTheme.softShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tasks Breakdown',
            style: AppTheme.heading(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.deepSlate,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricPill(
                'Total',
                counts.total.toString(),
                AppTheme.deepSlate,
              ),
              _buildMetricPill(
                'Active',
                counts.inProgress.toString(),
                AppTheme.royalBlue,
              ),
              _buildMetricPill(
                'Blocked',
                counts.blocked.toString(),
                AppTheme.dangerText,
              ),
              _buildMetricPill(
                'Done',
                counts.completed.toString(),
                AppTheme.successText,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppTheme.heading(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: AppTheme.body(
            fontSize: 11,
            color: AppTheme.mutedSlate,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMilestonesSection(List<ProjectMilestoneModel> milestones) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Milestones',
              style: AppTheme.heading(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.scaffoldBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Text(
                '${milestones.length}',
                style: AppTheme.mono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.deepSlate,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (milestones.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.pureWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Text(
              'No milestones defined for this project.',
              style: AppTheme.body(color: AppTheme.mutedSlate, fontSize: 13),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.pureWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderSubtle, width: 1.0),
              boxShadow: const [AppTheme.softShadow],
            ),
            child: Column(
              children: List.generate(milestones.length, (idx) {
                final m = milestones[idx];
                final isDone = m.isCompleted;
                final isLast = idx == milestones.length - 1;

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: isDone
                                  ? AppTheme.successBg
                                  : AppTheme.scaffoldBg,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isDone
                                    ? AppTheme.successText
                                    : AppTheme.borderSubtle,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: isDone
                                  ? const Icon(
                                      Icons.check,
                                      size: 14,
                                      color: AppTheme.successText,
                                    )
                                  : null,
                            ),
                          ),
                          if (!isLast)
                            Expanded(
                              child: Container(
                                width: 1.5,
                                color: AppTheme.borderSubtle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: isLast ? 0 : 20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      m.title,
                                      style: AppTheme.heading(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.deepSlate,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDone
                                          ? AppTheme.successBg
                                          : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      m.status.isEmpty
                                          ? 'Pending'
                                          : m.status[0].toUpperCase() +
                                                m.status
                                                    .substring(1)
                                                    .toLowerCase(),
                                      style: AppTheme.heading(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: isDone
                                            ? AppTheme.successText
                                            : AppTheme.mutedSlate,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (m.dueDate != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Due: ${m.dueDate}',
                                  style: AppTheme.mono(
                                    fontSize: 11,
                                    color: AppTheme.mutedSlate,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                              if (m.deliverables != null &&
                                  m.deliverables!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.scaffoldBg,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: AppTheme.borderSubtle,
                                    ),
                                  ),
                                  child: Text(
                                    'Deliverables: ${m.deliverables}',
                                    style: AppTheme.body(
                                      fontSize: 12,
                                      color: AppTheme.deepSlate,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildTeamSection(List<ProjectMemberModel> members) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Team Members',
              style: AppTheme.heading(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.scaffoldBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Text(
                '${members.length}',
                style: AppTheme.mono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.deepSlate,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (members.isEmpty)
          Text(
            'No team members assigned.',
            style: AppTheme.body(color: AppTheme.mutedSlate, fontSize: 13),
          )
        else
          SizedBox(
            height: 94,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: members.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (ctx, idx) {
                final mem = members[idx];
                final isViewer = mem.memberRole.toLowerCase().contains(
                  'viewer',
                );

                return Container(
                  width: 140,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.pureWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.borderSubtle,
                      width: 1.0,
                    ),
                    boxShadow: const [AppTheme.softShadow],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        mem.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.heading(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.deepSlate,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: isViewer
                              ? const Color(0xFFF1F5F9)
                              : AppTheme.infoBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isViewer ? 'Viewer' : 'Member',
                          style: AppTheme.heading(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: isViewer
                                ? AppTheme.mutedSlate
                                : AppTheme.infoText,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        mem.designation ?? 'Member',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.body(
                          fontSize: 11,
                          color: AppTheme.mutedSlate,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildScopeSection(ProjectDetailModel detail) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle, width: 1.0),
        boxShadow: const [AppTheme.softShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scope & Deliverables',
            style: AppTheme.heading(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.deepSlate,
            ),
          ),
          if (detail.scopeOfWork != null && detail.scopeOfWork!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              detail.scopeOfWork!,
              style: AppTheme.body(fontSize: 13, color: AppTheme.deepSlate),
            ),
          ],
          if (detail.deliverables != null &&
              detail.deliverables!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Deliverables',
              style: AppTheme.heading(
                fontSize: 12,
                color: AppTheme.royalBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              detail.deliverables!,
              style: AppTheme.body(fontSize: 13, color: AppTheme.deepSlate),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActivitySection(List<ProjectActivityModel> activities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: AppTheme.heading(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        ...activities.take(5).map((act) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.pureWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.bolt_rounded,
                  color: AppTheme.royalBlue,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        act.description,
                        style: AppTheme.body(
                          fontSize: 13,
                          color: AppTheme.deepSlate,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        act.createdAt,
                        style: AppTheme.mono(
                          fontSize: 11,
                          color: AppTheme.mutedSlate,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.dangerBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.dangerText.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Failed to load project',
                style: AppTheme.heading(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.dangerText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Unknown error occurred.',
                style: AppTheme.body(color: AppTheme.deepSlate, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _loadProjectDetail,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
