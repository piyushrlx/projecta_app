import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/user_model.dart';
import '../projects/project_detail_screen.dart';
import '../reports/reports_list_screen.dart';
import '../tasks/task_detail_screen.dart';
import 'widgets/kpi_card.dart';

class AdminDashboardView extends StatelessWidget {
  final UserModel user;
  final Map<String, dynamic> data;
  final VoidCallback onRefresh;

  const AdminDashboardView({
    super.key,
    required this.user,
    required this.data,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final kpis = (data['kpis'] as Map<String, dynamic>?) ?? {};
    final alerts = (data['alerts'] as Map<String, dynamic>?) ?? {};
    final activeProjects = (data['active_projects'] as List<dynamic>?) ?? [];

    final overdueTasksCount = (kpis['overdue_tasks'] ?? 0) as int;
    final reportsPendingCount = (kpis['reports_pending_today'] ?? 0) as int;
    final awaitingReviewCount = (alerts['reports_awaiting_review'] ?? 0) as int;

    final overdueList = (alerts['overdue_tasks'] as List<dynamic>?) ?? [];
    final blockedList = (alerts['blocked_tasks'] as List<dynamic>?) ?? [];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      children: [
        // Header Date & Admin Notice
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: AppTheme.violentRed,
              child: Text(
                'ADMIN EXECUTIVE CONTROL',
                style: AppTheme.mono(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.pureWhite,
                ),
              ),
            ),
            Text(
              data['date']?.toString() ?? '',
              style: AppTheme.mono(
                fontSize: 12,
                color: const Color(0xFF888888),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Urgent Action Banner (Reports Awaiting Review)
        if (awaitingReviewCount > 0) ...[
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReportsListScreen(user: user),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F0),
                border: Border.all(color: AppTheme.violentRed, width: 2.0),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.assignment_late,
                    color: AppTheme.violentRed,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'REPORTS AWAITING REVIEW',
                          style: AppTheme.mono(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.violentRed,
                          ),
                        ),
                        Text(
                          '$awaitingReviewCount daily reports submitted require manager approval.',
                          style: AppTheme.body(
                            fontSize: 12,
                            color: AppTheme.pitchBlack,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 10 Core Administrative KPIs Grid
        Text(
          '10 CORE METRICS',
          style: AppTheme.mono(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppTheme.pureWhite,
          ),
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: KpiCard(
                label: 'Active Projects',
                value: '${kpis['active_projects'] ?? 0}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: KpiCard(
                label: 'Completed Proj',
                value: '${kpis['completed_projects'] ?? 0}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: KpiCard(
                label: 'Open Tasks',
                value: '${kpis['open_tasks'] ?? 0}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: KpiCard(
                label: 'In Progress',
                value: '${kpis['tasks_in_progress'] ?? 0}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: KpiCard(
                label: 'Completed Tasks',
                value: '${kpis['completed_tasks'] ?? 0}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: KpiCard(
                label: 'Pending Tasks',
                value: '${kpis['pending_tasks'] ?? 0}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: KpiCard(
                label: 'Overdue Tasks',
                value: '$overdueTasksCount',
                isUrgent: overdueTasksCount > 0,
                subtitle: overdueTasksCount > 0
                    ? 'Urgent action required'
                    : 'Clear',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: KpiCard(
                label: 'Active Staff',
                value: '${kpis['active_employees'] ?? 0}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: KpiCard(
                label: 'Submitted Today',
                value: '${kpis['reports_submitted_today'] ?? 0}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: KpiCard(
                label: 'Reports Missing',
                value: '$reportsPendingCount',
                isUrgent: reportsPendingCount > 0,
                subtitle: '${kpis['compliance_percent'] ?? 0}% team compliance',
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Risk Alert Center
        if (overdueList.isNotEmpty || blockedList.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: AppTheme.violentRed,
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppTheme.pureWhite,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'PROJECT RISK & ALERT CENTER',
                  style: AppTheme.mono(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.pureWhite,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          if (overdueList.isNotEmpty) ...[
            Text(
              'OVERDUE TASKS (${overdueList.length})',
              style: AppTheme.mono(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.violentRed,
              ),
            ),
            const SizedBox(height: 6),
            ...overdueList.map((t) {
              final task = t as Map<String, dynamic>;
              return GestureDetector(
                onTap: () {
                  final id = (task['id'] as num?)?.toInt();
                  if (id != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskDetailScreen(taskId: id),
                      ),
                    );
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: AppTheme.neoCardDecoration(
                    backgroundColor: AppTheme.pureWhite,
                    borderColor: AppTheme.violentRed,
                    shadowOffset: 3.0,
                    shadowColor: AppTheme.violentRed,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task['title']?.toString() ?? '',
                              style: AppTheme.heading(
                                fontSize: 14,
                                color: AppTheme.pitchBlack,
                              ),
                            ),
                            Text(
                              task['project_name']?.toString() ?? '',
                              style: AppTheme.body(
                                fontSize: 12,
                                color: const Color(0xFF666666),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        color: AppTheme.violentRed,
                        child: Text(
                          'DUE: ${task['deadline'] ?? ''}',
                          style: AppTheme.mono(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.pureWhite,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
          ],

          if (blockedList.isNotEmpty) ...[
            Text(
              'BLOCKED TASKS (${blockedList.length})',
              style: AppTheme.mono(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(height: 6),
            ...blockedList.map((t) {
              final task = t as Map<String, dynamic>;
              return GestureDetector(
                onTap: () {
                  final id = (task['id'] as num?)?.toInt();
                  if (id != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskDetailScreen(taskId: id),
                      ),
                    );
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: AppTheme.neoCardDecoration(
                    backgroundColor: AppTheme.pureWhite,
                    borderColor: AppTheme.pitchBlack,
                    shadowOffset: 3.0,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.block,
                        color: Color(0xFFD97706),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          task['title']?.toString() ?? '',
                          style: AppTheme.heading(
                            fontSize: 14,
                            color: AppTheme.pitchBlack,
                          ),
                        ),
                      ),
                      Text(
                        task['project_name']?.toString() ?? '',
                        style: AppTheme.mono(
                          fontSize: 11,
                          color: const Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 12),
        ],

        // Active Projects Overview Snapshot
        Text(
          'ACTIVE PROJECTS OVERVIEW',
          style: AppTheme.mono(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppTheme.pureWhite,
          ),
        ),
        const SizedBox(height: 10),

        if (activeProjects.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.neoCardDecoration(),
            child: Text(
              'No active projects found.',
              style: AppTheme.body(fontSize: 13),
            ),
          )
        else
          ...activeProjects.map((p) {
            final proj = p as Map<String, dynamic>;
            final percent = (proj['completion_percent'] ?? 0) as int;
            final overdue = (proj['overdue_tasks'] ?? 0) as int;

            return GestureDetector(
              onTap: () {
                final id = (proj['id'] as num?)?.toInt();
                if (id != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProjectDetailScreen(projectId: id),
                    ),
                  );
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.neoCardDecoration(
                  backgroundColor: AppTheme.pureWhite,
                  borderColor: AppTheme.pitchBlack,
                  shadowOffset: 4.0,
                  shadowColor: AppTheme.pureWhite,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            proj['name']?.toString() ?? '',
                            style: AppTheme.heading(
                              fontSize: 16,
                              color: AppTheme.pitchBlack,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          color: AppTheme.pitchBlack,
                          child: Text(
                            '$percent%',
                            style: AppTheme.mono(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.pureWhite,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manager: ${proj['manager_name'] ?? 'Unassigned'} · Deadline: ${proj['deadline'] ?? 'No date'}',
                      style: AppTheme.body(
                        fontSize: 12,
                        color: const Color(0xFF666666),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.zero,
                      child: LinearProgressIndicator(
                        value: (percent / 100).clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: const Color(0xFFE5E5E5),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.pitchBlack,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          'DONE: ${proj['done_tasks'] ?? 0}  |  PENDING: ${proj['pending_tasks'] ?? 0}',
                          style: AppTheme.mono(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF444444),
                          ),
                        ),
                        if (overdue > 0) ...[
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            color: const Color(0xFFFFEAEA),
                            child: Text(
                              'OVERDUE: $overdue',
                              style: AppTheme.mono(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.violentRed,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
