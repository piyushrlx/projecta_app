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
      backgroundColor: AppTheme.pitchBlack,
      appBar: AppBar(
        title: Text(
          _detail != null ? _detail!.project.projectCode : 'PROJECT DETAILS',
          style: AppTheme.mono(fontSize: 16, fontWeight: FontWeight.w800),
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
                color: AppTheme.violentRed,
                strokeWidth: 3,
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
      color: AppTheme.violentRed,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Header Card (Overview)
          _buildOverviewCard(p),
          const SizedBox(height: 16),

          // 2. Task Breakdown Metrics
          _buildTaskCountsCard(detail.taskCounts),
          const SizedBox(height: 16),

          // 3. Jump to Tasks Button
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      TasksScreen(projectId: p.id, projectName: p.name),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.violentRed,
                border: Border.all(color: AppTheme.pureWhite, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: AppTheme.pureWhite,
                    offset: Offset(4, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.task_alt,
                    color: AppTheme.pureWhite,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'VIEW ALL PROJECT TASKS (${detail.taskCounts.total})',
                    style: AppTheme.mono(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.pureWhite,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 4. Milestones Section (Read-Only Checkpoints)
          _buildMilestonesSection(detail.milestones),
          const SizedBox(height: 20),

          // 5. Team Members Section
          _buildTeamSection(detail.members),
          const SizedBox(height: 20),

          // 6. Scope & Deliverables (if any)
          if ((detail.scopeOfWork != null && detail.scopeOfWork!.isNotEmpty) ||
              (detail.deliverables != null &&
                  detail.deliverables!.isNotEmpty)) ...[
            _buildScopeSection(detail),
            const SizedBox(height: 20),
          ],

          // 7. Recent Activity Section
          if (detail.recentActivity.isNotEmpty) ...[
            _buildActivitySection(detail.recentActivity),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  Widget _buildOverviewCard(ProjectModel p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.neoCardDecoration(
        backgroundColor: AppTheme.pureWhite,
        borderColor: AppTheme.pitchBlack,
        shadowOffset: 4,
        shadowColor: AppTheme.pureWhite,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                color: AppTheme.pitchBlack,
                child: Text(
                  p.projectCode,
                  style: AppTheme.mono(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.pureWhite,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.pitchBlack, width: 1.5),
                  color: p.isActive
                      ? const Color(0xFFE8F5E9)
                      : p.isCompleted
                      ? const Color(0xFFE3F2FD)
                      : const Color(0xFFFFF3E0),
                ),
                child: Text(
                  p.status.toUpperCase(),
                  style: AppTheme.mono(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            p.name,
            style: AppTheme.heading(fontSize: 20, color: AppTheme.pitchBlack),
          ),
          if (p.clientName != null && p.clientName!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'CLIENT: ${p.clientName!.toUpperCase()}',
              style: AppTheme.mono(
                fontSize: 12,
                color: const Color(0xFF666666),
              ),
            ),
          ],
          const SizedBox(height: 14),
          // Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PROJECT COMPLETION',
                style: AppTheme.mono(fontSize: 11, fontWeight: FontWeight.w700),
              ),
              Text(
                '${p.completionPercent.toStringAsFixed(1)}%',
                style: AppTheme.mono(fontSize: 12, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.zero,
            child: LinearProgressIndicator(
              value: (p.completionPercent / 100).clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: const Color(0xFFE0E0E0),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.pitchBlack,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Divider(color: AppTheme.pitchBlack, thickness: 1.5),
          const SizedBox(height: 10),
          // Dates & Manager
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'START DATE',
                      style: AppTheme.mono(
                        fontSize: 10,
                        color: const Color(0xFF777777),
                      ),
                    ),
                    Text(
                      p.startDate ?? 'None',
                      style: AppTheme.mono(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
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
                      'DEADLINE',
                      style: AppTheme.mono(
                        fontSize: 10,
                        color: const Color(0xFF777777),
                      ),
                    ),
                    Text(
                      p.deadline ?? 'None',
                      style: AppTheme.mono(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: p.overdueTasks > 0
                            ? AppTheme.violentRed
                            : AppTheme.pitchBlack,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DEPARTMENT',
                      style: AppTheme.mono(
                        fontSize: 10,
                        color: const Color(0xFF777777),
                      ),
                    ),
                    Text(
                      p.departmentName ?? 'General',
                      style: AppTheme.body(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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
                      'MANAGER',
                      style: AppTheme.mono(
                        fontSize: 10,
                        color: const Color(0xFF777777),
                      ),
                    ),
                    Text(
                      p.managerName ?? 'Unassigned',
                      style: AppTheme.body(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        border: Border.all(color: AppTheme.pureWhite, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TASKS BREAKDOWN',
            style: AppTheme.mono(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppTheme.pureWhite,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricPill(
                'TOTAL',
                counts.total.toString(),
                AppTheme.pureWhite,
              ),
              _buildMetricPill(
                'ACTIVE',
                counts.inProgress.toString(),
                const Color(0xFF4FC3F7),
              ),
              _buildMetricPill(
                'BLOCKED',
                counts.blocked.toString(),
                AppTheme.violentRed,
              ),
              _buildMetricPill(
                'DONE',
                counts.completed.toString(),
                const Color(0xFF81C784),
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
          style: AppTheme.mono(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTheme.mono(fontSize: 10, color: const Color(0xFFAAAAAA)),
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
              'MILESTONES & DELIVERABLES',
              style: AppTheme.heading(fontSize: 15),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              color: AppTheme.pureWhite,
              child: Text(
                '${milestones.length}',
                style: AppTheme.mono(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.pitchBlack,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (milestones.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF333333)),
            ),
            child: Text(
              'No milestones defined for this project.',
              style: AppTheme.body(
                color: const Color(0xFF888888),
                fontSize: 13,
              ),
            ),
          )
        else
          ...milestones.map((m) {
            final isDone = m.isCompleted;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDone
                    ? const Color(0xFF0F1E12)
                    : const Color(0xFF141414),
                border: Border.all(
                  color: isDone ? const Color(0xFF4CAF50) : AppTheme.pureWhite,
                  width: 1.5,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isDone ? Icons.check_box : Icons.check_box_outline_blank,
                    color: isDone
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFF888888),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                m.title,
                                style: AppTheme.mono(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDone
                                      ? const Color(0xFF4CAF50)
                                      : AppTheme.pureWhite,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              color: isDone
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFF333333),
                              child: Text(
                                m.status.toUpperCase(),
                                style: AppTheme.mono(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: isDone
                                      ? AppTheme.pitchBlack
                                      : AppTheme.pureWhite,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (m.deliverables != null &&
                            m.deliverables!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Deliverables: ${m.deliverables}',
                            style: AppTheme.body(
                              fontSize: 12,
                              color: const Color(0xFFAAAAAA),
                            ),
                          ),
                        ],
                        if (m.dueDate != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Target Due: ${m.dueDate}',
                            style: AppTheme.mono(
                              fontSize: 10,
                              color: const Color(0xFF777777),
                            ),
                          ),
                        ],
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

  Widget _buildTeamSection(List<ProjectMemberModel> members) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('TEAM MEMBERS', style: AppTheme.heading(fontSize: 15)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              color: AppTheme.pureWhite,
              child: Text(
                '${members.length}',
                style: AppTheme.mono(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.pitchBlack,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (members.isEmpty)
          Text(
            'No team members assigned.',
            style: AppTheme.body(color: const Color(0xFF888888), fontSize: 13),
          )
        else
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: members.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (ctx, idx) {
                final mem = members[idx];
                return Container(
                  width: 130,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.pureWhite,
                    border: Border.all(color: AppTheme.pitchBlack, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: AppTheme.pureWhite,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        mem.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.mono(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.pitchBlack,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        mem.memberRole.toUpperCase(),
                        style: AppTheme.mono(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.violentRed,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        mem.designation ?? 'Member',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.body(
                          fontSize: 10,
                          color: const Color(0xFF666666),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        border: Border.all(color: AppTheme.pureWhite, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SCOPE & DELIVERABLES',
            style: AppTheme.mono(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppTheme.pureWhite,
            ),
          ),
          if (detail.scopeOfWork != null && detail.scopeOfWork!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              detail.scopeOfWork!,
              style: AppTheme.body(
                fontSize: 13,
                color: const Color(0xFFCCCCCC),
              ),
            ),
          ],
          if (detail.deliverables != null &&
              detail.deliverables!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'DELIVERABLES',
              style: AppTheme.mono(fontSize: 11, color: AppTheme.violentRed),
            ),
            const SizedBox(height: 4),
            Text(
              detail.deliverables!,
              style: AppTheme.body(
                fontSize: 13,
                color: const Color(0xFFCCCCCC),
              ),
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
        Text('RECENT ACTIVITY', style: AppTheme.heading(fontSize: 15)),
        const SizedBox(height: 10),
        ...activities.take(5).map((act) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF2E2E2E)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.bolt, color: AppTheme.pureWhite, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        act.description,
                        style: AppTheme.body(
                          fontSize: 12,
                          color: AppTheme.pureWhite,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        act.createdAt,
                        style: AppTheme.mono(
                          fontSize: 10,
                          color: const Color(0xFF777777),
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
            color: const Color(0xFF1E1414),
            border: Border.all(color: AppTheme.violentRed, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'FAILED TO LOAD PROJECT',
                style: AppTheme.mono(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.violentRed,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Unknown error occurred.',
                style: AppTheme.body(color: AppTheme.pureWhite, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _loadProjectDetail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.violentRed,
                ),
                child: const Text('RETRY'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
