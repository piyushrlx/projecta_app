import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/widgets/brutalist_pressable.dart';
import '../../models/user_model.dart';
import '../projects/projects_list_screen.dart';
import '../reports/report_submission_screen.dart';
import '../tasks/task_detail_screen.dart';
import '../tasks/tasks_screen.dart';
import 'widgets/compliance_card.dart';
import 'widgets/kpi_card.dart';

class StaffDashboardView extends StatelessWidget {
  final UserModel user;
  final Map<String, dynamic> data;
  final VoidCallback onRefresh;

  const StaffDashboardView({
    super.key,
    required this.user,
    required this.data,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final kpis = (data['kpis'] as Map<String, dynamic>?) ?? {};
    final compliance =
        (data['compliance'] ?? data['compliance_badge']) as Map<String, dynamic>?;
    final nextTasks = (data['what_to_work_on_next'] as List<dynamic>?) ?? [];
    final recentFeedback = (data['recent_feedback'] as List<dynamic>?) ?? [];

    final overdueCount = (kpis['overdue'] ?? 0) as int;
    final heroTask = nextTasks.isNotEmpty
        ? nextTasks.first as Map<String, dynamic>
        : null;
    final remainingTasks = nextTasks.length > 1
        ? nextTasks.sublist(1)
        : <dynamic>[];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      children: [
        // 1. Daily Report Compliance Card
        ComplianceCard(
          badgeData: compliance,
          onSubmitReport: () async {
            final submitted = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => const ReportSubmissionScreen()),
            );
            if (submitted == true) {
              onRefresh();
            }
          },
        ),
        const SizedBox(height: 24),

        // 2. Section: Personal WorkDesk KPIs
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Metrics',
              style: AppTheme.heading(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.deepSlate,
              ),
            ),
            Text(
              data['date']?.toString() ?? '',
              style: AppTheme.mono(fontSize: 11, color: AppTheme.mutedSlate),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 2-Column KPI Grid
        Row(
          children: [
            Expanded(
              child: KpiCard(
                label: 'Active Projects',
                value: '${kpis['active_projects'] ?? 0}',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProjectsListScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: KpiCard(
                label: 'Open Tasks',
                value: '${kpis['open_tasks'] ?? 0}',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TasksScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: KpiCard(
                label: 'Due Today',
                value: '${kpis['due_today'] ?? 0}',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TasksScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: KpiCard(
                label: 'Overdue Tasks',
                value: '$overdueCount',
                isUrgent: overdueCount > 0,
                subtitle: overdueCount > 0 ? 'Requires attention' : 'All clear',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const TasksScreen(initialFilter: 'OVERDUE'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: KpiCard(
                label: 'Awaiting Review',
                value: '${kpis['pending_review'] ?? 0}',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const TasksScreen(initialFilter: 'PENDING REVIEW'),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: KpiCard(
                label: 'Completed',
                value: '${kpis['completed'] ?? 0}',
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
        const SizedBox(height: 24),

        // 3. Section: "What should I work on next?" Hero & Queue
        Row(
          children: [
            const Icon(Icons.bolt_rounded, color: AppTheme.royalBlue, size: 20),
            const SizedBox(width: 8),
            Text(
              'What should I work on next?',
              style: AppTheme.heading(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.deepSlate,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (heroTask == null)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.pureWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderSubtle),
              boxShadow: const [AppTheme.softShadow],
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: AppTheme.successText,
                  size: 36,
                ),
                const SizedBox(height: 10),
                Text(
                  'All Caught Up!',
                  style: AppTheme.heading(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.deepSlate,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You have no pending high-priority tasks assigned.',
                  textAlign: TextAlign.center,
                  style: AppTheme.body(
                    fontSize: 13,
                    color: AppTheme.mutedSlate,
                  ),
                ),
              ],
            ),
          )
        else ...[
          // #1 HERO TASK CARD
          _buildHeroTaskCard(context, heroTask),
          const SizedBox(height: 20),

          // Remaining Tasks in Priority Queue
          if (remainingTasks.isNotEmpty) ...[
            Text(
              'Upcoming in Queue',
              style: AppTheme.heading(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.mutedSlate,
              ),
            ),
            const SizedBox(height: 10),
            ...remainingTasks.map((item) {
              final task = item as Map<String, dynamic>;
              return _buildQueueTaskCard(context, task);
            }),
          ],
        ],

        // 4. Section: Recent Supervisor Feedback
        if (recentFeedback.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Supervisor Feedback',
            style: AppTheme.heading(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.deepSlate,
            ),
          ),
          const SizedBox(height: 12),
          ...recentFeedback.map((fb) {
            final f = fb as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
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
                      Text(
                        f['reviewer_name']?.toString() ?? 'Supervisor',
                        style: AppTheme.heading(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.deepSlate,
                        ),
                      ),
                      Text(
                        f['report_date']?.toString() ?? '',
                        style: AppTheme.mono(
                          fontSize: 11,
                          color: AppTheme.mutedSlate,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    f['review_comment']?.toString() ??
                        'No review notes provided.',
                    style: AppTheme.body(
                      fontSize: 13,
                      color: AppTheme.deepSlate,
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

  Widget _buildHeroTaskCard(BuildContext context, Map<String, dynamic> task) {
    final progress = (task['progress'] ?? 0) as int;
    final isOverdue =
        task['is_overdue'] == true ||
        task['reason'].toString().toLowerCase().contains('overdue');
    final taskId = (task['id'] as num?)?.toInt();

    return BrutalistPressable(
      onTap: taskId != null
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TaskDetailScreen(taskId: taskId),
                ),
              );
            }
          : null,
      backgroundColor: AppTheme.pureWhite,
      borderColor: isOverdue
          ? const Color(0xFFFECACA)
          : const Color(0xFFBFDBFE),
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isOverdue ? AppTheme.dangerBg : AppTheme.infoBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: isOverdue
                          ? AppTheme.dangerText
                          : AppTheme.infoText,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Next Up (#1 Hero)',
                      style: AppTheme.heading(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isOverdue
                            ? AppTheme.dangerText
                            : AppTheme.infoText,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.scaffoldBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Text(
                  '$progress%',
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
          Text(
            task['title']?.toString() ?? 'Untitled Task',
            style: AppTheme.heading(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.deepSlate,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            task['project_name']?.toString() ?? '',
            style: AppTheme.body(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.mutedSlate,
            ),
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (progress / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                isOverdue ? AppTheme.dangerText : AppTheme.royalBlue,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (task['reason'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isOverdue ? AppTheme.dangerBg : AppTheme.scaffoldBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    task['reason'].toString(),
                    style: AppTheme.heading(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isOverdue
                          ? AppTheme.dangerText
                          : AppTheme.mutedSlate,
                    ),
                  ),
                ),
              if (task['deadline'] != null)
                Text(
                  'Deadline: ${task['deadline']}',
                  style: AppTheme.mono(
                    fontSize: 11,
                    color: isOverdue
                        ? AppTheme.dangerText
                        : AppTheme.mutedSlate,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Update Status button
          SizedBox(
            height: 42,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: taskId != null
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TaskDetailScreen(taskId: taskId),
                        ),
                      );
                    }
                  : null,
              icon: const Icon(Icons.edit_note, size: 18),
              label: const Text('Update Status'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.navyBlue,
                foregroundColor: AppTheme.pureWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueTaskCard(BuildContext context, Map<String, dynamic> task) {
    final progress = (task['progress'] ?? 0) as int;
    final isOverdue =
        task['is_overdue'] == true ||
        task['reason'].toString().toLowerCase().contains('overdue');
    final taskId = (task['id'] as num?)?.toInt();

    return BrutalistPressable(
      onTap: taskId != null
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TaskDetailScreen(taskId: taskId),
                ),
              );
            }
          : null,
      backgroundColor: AppTheme.pureWhite,
      borderColor: isOverdue ? const Color(0xFFFECACA) : AppTheme.borderSubtle,
      borderRadius: BorderRadius.circular(12),
      margin: const EdgeInsets.only(bottom: 10.0),
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  task['title']?.toString() ?? 'Untitled Task',
                  style: AppTheme.heading(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.deepSlate,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isOverdue ? AppTheme.dangerBg : AppTheme.scaffoldBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$progress%',
                  style: AppTheme.mono(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isOverdue ? AppTheme.dangerText : AppTheme.deepSlate,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            task['project_name']?.toString() ?? '',
            style: AppTheme.body(fontSize: 12, color: AppTheme.mutedSlate),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (progress / 100).clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                isOverdue ? AppTheme.dangerText : AppTheme.royalBlue,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (task['reason'] != null)
                Text(
                  task['reason'].toString(),
                  style: AppTheme.body(
                    fontSize: 11,
                    color: isOverdue
                        ? AppTheme.dangerText
                        : AppTheme.mutedSlate,
                  ),
                ),
              if (task['deadline'] != null)
                Text(
                  'Due: ${task['deadline']}',
                  style: AppTheme.mono(
                    fontSize: 11,
                    color: isOverdue
                        ? AppTheme.dangerText
                        : AppTheme.mutedSlate,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
