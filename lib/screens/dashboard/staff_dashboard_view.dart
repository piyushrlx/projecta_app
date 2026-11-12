import 'package:flutter/material.dart';
import '../../core/app_date_utils.dart';
import '../../core/theme.dart';
import '../../core/widgets/brutalist_pressable.dart';
import '../../models/user_model.dart';
import '../projects/project_detail_screen.dart';
import '../projects/projects_list_screen.dart';
import '../reports/report_submission_screen.dart';
import '../reports/reports_list_screen.dart';
import '../tasks/task_detail_screen.dart';
import '../tasks/tasks_screen.dart';
import '../tasks/widgets/task_priority_badge.dart';
import '../tasks/widgets/task_status_pill.dart';
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
        (data['compliance'] ?? data['compliance_badge'])
            as Map<String, dynamic>?;
    final nextTasks = (data['what_to_work_on_next'] as List<dynamic>?) ?? [];
    final myTasks = (data['my_tasks'] as List<dynamic>?) ?? [];
    final deadlines = (data['deadlines'] as Map<String, dynamic>?) ?? {};
    final overdueDeadlines = (deadlines['overdue'] as List<dynamic>?) ?? [];
    final dueTodayDeadlines = (deadlines['due_today'] as List<dynamic>?) ?? [];
    final upcomingDeadlines = (deadlines['upcoming'] as List<dynamic>?) ?? [];
    final todayReports = (data['today_reports'] as List<dynamic>?) ?? [];
    final recentFeedback = (data['recent_feedback'] as List<dynamic>?) ?? [];
    final myProjects = (data['my_projects'] as List<dynamic>?) ?? [];

    final overdueCount = (kpis['overdue'] ?? 0) as int;
    final heroTask = nextTasks.isNotEmpty
        ? nextTasks.first as Map<String, dynamic>
        : null;
    final remainingTasks = nextTasks.length > 1
        ? nextTasks.sublist(1)
        : <dynamic>[];

    final firstName = user.fullName.trim().split(' ').first;
    final dateStr = AppDateUtils.fmtDate(data['date']?.toString());

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
      children: [
        // 1. Welcome Greeting Header (Matching Web: "Welcome back, Piyush 👋")
        _buildWelcomeHeader(context, firstName, dateStr),
        const SizedBox(height: 16),

        // 2. Section: Personal WorkDesk KPIs ("My Metrics")
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
              dateStr,
              style: AppTheme.mono(fontSize: 11, color: AppTheme.mutedSlate),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 6-Card KPI Grid (Matching Web KPI cards)
        _buildKpiGrid(context, kpis, overdueCount),
        const SizedBox(height: 16),

        // 3. Daily Report Status Callout / Reminder Banner (Matching Web Callout)
        _buildComplianceCallout(context, compliance),
        const SizedBox(height: 20),

        // 4. "What should I work on next?" Section
        _buildSectionHeader(
          'What should I work on next?',
          subtitle: 'Based on overdue, deadlines, priority & dependencies',
          icon: Icons.bolt_rounded,
        ),
        const SizedBox(height: 12),
        if (heroTask == null)
          _buildEmptyHeroCard()
        else ...[
          _buildHeroTaskCard(context, heroTask),
          if (remainingTasks.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Upcoming in Queue',
              style: AppTheme.heading(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.mutedSlate,
              ),
            ),
            const SizedBox(height: 8),
            ...remainingTasks.map((item) {
              final task = item as Map<String, dynamic>;
              return _buildQueueTaskCard(context, task);
            }),
          ],
        ],
        const SizedBox(height: 20),

        // 5. "Supervisor Feedback" Section
        if (recentFeedback.isNotEmpty) ...[
          _buildSupervisorFeedbackSection(context, recentFeedback),
          const SizedBox(height: 20),
        ],

        // 6. "My tasks" Section (Matching Web Table with "View all")
        _buildMyTasksSection(context, myTasks),
        const SizedBox(height: 20),

        // 7. "Deadlines" Breakdown (Overdue, Due today, Upcoming next 7 days)
        if (overdueDeadlines.isNotEmpty ||
            dueTodayDeadlines.isNotEmpty ||
            upcomingDeadlines.isNotEmpty) ...[
          _buildDeadlinesSection(
            context,
            overdueDeadlines,
            dueTodayDeadlines,
            upcomingDeadlines,
          ),
          const SizedBox(height: 20),
        ],

        // 8. "Today's submitted reports" Section
        _buildTodayReportsSection(context, todayReports),
        const SizedBox(height: 20),

        // 9. "My Projects" Overview Section
        if (myProjects.isNotEmpty) ...[
          _buildMyProjectsSection(context, myProjects),
          const SizedBox(height: 20),
        ],

        const SizedBox(height: 16),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // Header & Callouts
  // --------------------------------------------------------------------------

  Widget _buildWelcomeHeader(
    BuildContext context,
    String firstName,
    String dateStr,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, $firstName 👋',
                  style: AppTheme.heading(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.deepSlate,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$dateStr · Here is your work at a glance',
                  style: AppTheme.body(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.mutedSlate,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () async {
              final submitted = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => const ReportSubmissionScreen(),
                ),
              );
              if (submitted == true) {
                onRefresh();
              }
            },
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Daily Report'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.royalBlue,
              foregroundColor: AppTheme.pureWhite,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              textStyle: AppTheme.heading(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(
    BuildContext context,
    Map<String, dynamic> kpis,
    int overdueCount,
  ) {
    return Column(
      children: [
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
            const SizedBox(width: 10),
            Expanded(
              child: KpiCard(
                label: 'My Open Tasks',
                value: '${kpis['open_tasks'] ?? 0}',
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
                label: 'Due Today',
                value: '${kpis['due_today'] ?? 0}',
                valueColor: const Color(0xFFD97706),
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
                label: 'Overdue',
                value: '$overdueCount',
                isUrgent: overdueCount > 0,
                subtitle: overdueCount > 0 ? '$overdueCount late' : 'None',
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
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: KpiCard(
                label: 'Awaiting Review',
                value: '${kpis['pending_review'] ?? 0}',
                valueColor: const Color(0xFF7C3AED),
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
            const SizedBox(width: 10),
            Expanded(
              child: KpiCard(
                label: 'Completed',
                value: '${kpis['completed'] ?? 0}',
                valueColor: const Color(0xFF16A34A),
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
      ],
    );
  }

  Widget _buildComplianceCallout(
    BuildContext context,
    Map<String, dynamic>? compliance,
  ) {
    if (compliance == null) {
      return ComplianceCard(
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
      );
    }

    final reportsCount = (compliance['reports_count'] as num?)?.toInt() ?? 0;
    final isSubmitted = reportsCount > 0;
    final deadlineTime = compliance['deadline_time']?.toString() ?? '20:00';
    final statusKey = compliance['status_key']?.toString() ?? 'pending';

    final isOverdue = statusKey == 'pending' && !isSubmitted;

    final bgColor = isSubmitted
        ? const Color(0xFFF0FDF4)
        : (isOverdue ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB));
    final borderColor = isSubmitted
        ? const Color(0xFFBBF7D0)
        : (isOverdue ? const Color(0xFFFECACA) : const Color(0xFFFDE68A));
    final textColor = isSubmitted
        ? const Color(0xFF166534)
        : (isOverdue ? const Color(0xFF991B1B) : const Color(0xFF92400E));
    final iconColor = isSubmitted
        ? const Color(0xFF16A34A)
        : (isOverdue ? const Color(0xFFDC2626) : const Color(0xFFD97706));

    final String message;
    final String actionText;
    if (isSubmitted) {
      message = 'Today: Submitted — $reportsCount report(s) logged.';
      actionText = 'Add another entry →';
    } else if (isOverdue) {
      message = 'Your daily report for today is overdue.';
      actionText = 'Submit it now →';
    } else {
      message = "Today's report is due by $deadlineTime.";
      actionText = 'Submit it now →';
    }

    return BrutalistPressable(
      onTap: () async {
        final submitted = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => const ReportSubmissionScreen()),
        );
        if (submitted == true) {
          onRefresh();
        }
      },
      backgroundColor: bgColor,
      borderColor: borderColor,
      borderRadius: BorderRadius.circular(10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(
            isSubmitted
                ? Icons.check_circle_rounded
                : (isOverdue ? Icons.error_outline : Icons.schedule_rounded),
            color: iconColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: AppTheme.body(fontSize: 12, color: textColor),
                children: [
                  TextSpan(
                    text: '$message ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: actionText,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isSubmitted ? AppTheme.royalBlue : textColor,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // "What should I work on next?" Section
  // --------------------------------------------------------------------------

  Widget _buildSectionHeader(
    String title, {
    String? subtitle,
    IconData? icon,
    Widget? action,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: AppTheme.royalBlue, size: 18),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.heading(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.deepSlate,
                      ),
                    ),
                  ),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTheme.body(
                    fontSize: 11,
                    color: AppTheme.mutedSlate,
                  ),
                ),
              ],
            ],
          ),
        ),
        ?action,
      ],
    );
  }

  Widget _buildEmptyHeroCard() {
    return Container(
      padding: const EdgeInsets.all(22),
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
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Nothing Urgent',
            style: AppTheme.heading(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.deepSlate,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'No open tasks are ready to work on right now.',
            textAlign: TextAlign.center,
            style: AppTheme.body(fontSize: 12, color: AppTheme.mutedSlate),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroTaskCard(BuildContext context, Map<String, dynamic> task) {
    final progress = (task['progress'] ?? 0) as int;
    final isOverdue =
        task['is_overdue'] == true ||
        task['reason'].toString().toLowerCase().contains('overdue');
    final taskId = (task['id'] as num?)?.toInt();
    final priority = task['priority']?.toString() ?? 'medium';
    final status = task['status']?.toString() ?? 'not_started';

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
      padding: const EdgeInsets.all(16.0),
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
                        fontWeight: FontWeight.w700,
                        color: isOverdue
                            ? AppTheme.dangerText
                            : AppTheme.infoText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    TaskPriorityBadge(priority: priority),
                    TaskStatusPill(status: status),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.scaffoldBg,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: Text(
                        '$progress%',
                        style: AppTheme.mono(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.deepSlate,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            task['title']?.toString() ?? 'Untitled Task',
            style: AppTheme.heading(
              fontSize: 16,
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
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (task['reason'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isOverdue ? AppTheme.dangerBg : AppTheme.scaffoldBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    task['reason'].toString(),
                    style: AppTheme.heading(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isOverdue
                          ? AppTheme.dangerText
                          : AppTheme.mutedSlate,
                    ),
                  ),
                ),
              Text(
                '$progress% completed',
                style: AppTheme.mono(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.mutedSlate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Update Status button
          SizedBox(
            height: 44,
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
              icon: const Icon(Icons.edit_note_rounded, size: 18),
              label: const Text('Update Status'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.navyBlue,
                foregroundColor: AppTheme.pureWhite,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                alignment: Alignment.center,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: AppTheme.heading(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
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
    final priority = task['priority']?.toString() ?? 'medium';
    final status = task['status']?.toString() ?? 'not_started';

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
      borderRadius: BorderRadius.circular(10),
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task['title']?.toString() ?? 'Untitled Task',
                  style: AppTheme.heading(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.deepSlate,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              TaskPriorityBadge(priority: priority),
              const SizedBox(width: 4),
              TaskStatusPill(status: status),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                task['project_name']?.toString() ?? '',
                style: AppTheme.body(fontSize: 11, color: AppTheme.mutedSlate),
              ),
              Text(
                '$progress%',
                style: AppTheme.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isOverdue ? AppTheme.dangerText : AppTheme.mutedSlate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (progress / 100).clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                isOverdue ? AppTheme.dangerText : AppTheme.royalBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 5. "My Tasks" Section (Matching Web Tasks Table)
  // --------------------------------------------------------------------------

  Widget _buildMyTasksSection(BuildContext context, List<dynamic> myTasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'My tasks',
          action: TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TasksScreen()),
              );
            },
            child: const Text('View all →'),
          ),
        ),
        const SizedBox(height: 8),
        if (myTasks.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.pureWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Center(
              child: Text(
                'No open tasks assigned to you.',
                style: AppTheme.body(fontSize: 12, color: AppTheme.mutedSlate),
              ),
            ),
          )
        else
          ...myTasks.take(5).map((t) {
            final task = t as Map<String, dynamic>;
            final taskId = (task['id'] as num?)?.toInt();
            final isOverdue = task['is_overdue'] == true;
            final isShared = task['responsibility'] == 'contributor';
            final hasDeps = ((task['open_deps'] as num?)?.toInt() ?? 0) > 0;
            final progress = (task['progress'] as num?)?.toInt() ?? 0;
            final deadlineStr =
                task['deadline_formatted'] ?? task['deadline'] ?? 'No deadline';

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
                  : AppTheme.borderSubtle,
              borderRadius: BorderRadius.circular(10),
              margin: const EdgeInsets.only(bottom: 8.0),
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Text(
                              task['title']?.toString() ?? 'Untitled Task',
                              style: AppTheme.heading(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.deepSlate,
                              ),
                            ),
                            if (isShared)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'shared',
                                  style: AppTheme.heading(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFB45309),
                                  ),
                                ),
                              ),
                            if (hasDeps)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'deps',
                                  style: AppTheme.heading(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      TaskStatusPill(
                        status: task['status']?.toString() ?? 'not_started',
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        task['project_name']?.toString() ?? '',
                        style: AppTheme.body(
                          fontSize: 11,
                          color: AppTheme.mutedSlate,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 12,
                            color: isOverdue
                                ? AppTheme.dangerText
                                : AppTheme.mutedSlate,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            deadlineStr.toString(),
                            style: AppTheme.mono(
                              fontSize: 10,
                              fontWeight: isOverdue
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isOverdue
                                  ? AppTheme.dangerText
                                  : AppTheme.mutedSlate,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: (progress / 100).clamp(0.0, 1.0),
                            minHeight: 4,
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isOverdue
                                  ? AppTheme.dangerText
                                  : AppTheme.royalBlue,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$progress%',
                        style: AppTheme.mono(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.mutedSlate,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // 6. "Deadlines" Section (Overdue, Due today, Upcoming next 7 days)
  // --------------------------------------------------------------------------

  Widget _buildDeadlinesSection(
    BuildContext context,
    List<dynamic> overdue,
    List<dynamic> dueToday,
    List<dynamic> upcoming,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
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
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                size: 16,
                color: AppTheme.royalBlue,
              ),
              const SizedBox(width: 6),
              Text(
                'Deadlines',
                style: AppTheme.heading(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.deepSlate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Overdue group
          _buildDeadlineGroup(
            context,
            title: 'Overdue (${overdue.length})',
            titleColor: AppTheme.dangerText,
            tasks: overdue,
            badgeBuilder: (task) {
              final daysLate = task['days_late'] ?? 1;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.dangerBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${daysLate}d late',
                  style: AppTheme.heading(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.dangerText,
                  ),
                ),
              );
            },
          ),
          const Divider(height: 16, color: AppTheme.borderSubtle),

          // Due today group
          _buildDeadlineGroup(
            context,
            title: 'Due today (${dueToday.length})',
            titleColor: const Color(0xFFD97706),
            tasks: dueToday,
            badgeBuilder: (task) => TaskPriorityBadge(
              priority: task['priority']?.toString() ?? 'medium',
            ),
          ),
          const Divider(height: 16, color: AppTheme.borderSubtle),

          // Upcoming group
          _buildDeadlineGroup(
            context,
            title: 'Upcoming (next 7 days)',
            titleColor: AppTheme.deepSlate,
            tasks: upcoming,
            badgeBuilder: (task) {
              final deadline =
                  task['deadline_formatted'] ?? task['deadline'] ?? '';
              return Text(
                deadline.toString(),
                style: AppTheme.mono(fontSize: 10, color: AppTheme.mutedSlate),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlineGroup(
    BuildContext context, {
    required String title,
    required Color titleColor,
    required List<dynamic> tasks,
    required Widget Function(Map<String, dynamic> task) badgeBuilder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.heading(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 6),
        if (tasks.isEmpty)
          Text(
            'None',
            style: AppTheme.body(fontSize: 11, color: AppTheme.mutedSlate),
          )
        else
          ...tasks.take(4).map((item) {
            final task = item as Map<String, dynamic>;
            final taskId = (task['id'] as num?)?.toInt();
            return InkWell(
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
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task['title']?.toString() ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.body(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.deepSlate,
                            ),
                          ),
                          if (task['project_name'] != null)
                            Text(
                              task['project_name'].toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.body(
                                fontSize: 10,
                                color: AppTheme.mutedSlate,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    badgeBuilder(task),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // 7. "Today's Submitted Reports" Section
  // --------------------------------------------------------------------------

  Widget _buildTodayReportsSection(
    BuildContext context,
    List<dynamic> todayReports,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          "Today's submitted reports",
          action: TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReportsListScreen(user: user),
                ),
              );
            },
            child: const Text('History →'),
          ),
        ),
        const SizedBox(height: 8),
        if (todayReports.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.pureWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.note_alt_outlined,
                  color: AppTheme.mutedSlate,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No report entries logged for today yet.',
                    style: AppTheme.body(
                      fontSize: 12,
                      color: AppTheme.mutedSlate,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final submitted = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ReportSubmissionScreen(),
                      ),
                    );
                    if (submitted == true) {
                      onRefresh();
                    }
                  },
                  child: const Text('Submit Now'),
                ),
              ],
            ),
          )
        else
          ...todayReports.map((r) {
            final report = r as Map<String, dynamic>;
            final timeStr =
                report['time_spent_formatted'] ??
                '${report['minutes_spent'] ?? 0}m';
            final isLate = report['is_late'] == true;

            return Container(
              margin: const EdgeInsets.only(bottom: 8.0),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: AppTheme.pureWhite,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          report['project_name']?.toString() ?? 'General',
                          style: AppTheme.heading(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.deepSlate,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isLate)
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.dangerBg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Late',
                                style: AppTheme.heading(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.dangerText,
                                ),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.scaffoldBg,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppTheme.borderSubtle),
                            ),
                            child: Text(
                              timeStr.toString(),
                              style: AppTheme.mono(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.deepSlate,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (report['task_title'] != null &&
                      report['task_title'] != 'General') ...[
                    const SizedBox(height: 2),
                    Text(
                      report['task_title'].toString(),
                      style: AppTheme.body(
                        fontSize: 11,
                        color: AppTheme.royalBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    report['work_summary']?.toString() ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.body(
                      fontSize: 12,
                      color: AppTheme.deepSlate,
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // 8. "Recent Feedback" Section
  // --------------------------------------------------------------------------

  Widget _buildSupervisorFeedbackSection(
    BuildContext context,
    List<dynamic> recentFeedback,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Recent feedback',
          subtitle: 'Recent feedback on daily reports',
        ),
        const SizedBox(height: 8),
        ...recentFeedback.map((fb) {
          final f = fb as Map<String, dynamic>;
          final reviewer = f['reviewer_name']?.toString() ?? 'Supervisor';
          final comment = f['review_comment']?.toString() ?? '';
          final date = AppDateUtils.fmtDate(f['report_date']?.toString());
          final status = f['status']?.toString() ?? 'approved';

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.pureWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        reviewer,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.heading(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.deepSlate,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Report · $date',
                          style: AppTheme.mono(
                            fontSize: 11,
                            color: AppTheme.mutedSlate,
                          ),
                        ),
                        const SizedBox(width: 6),
                        TaskStatusPill(status: status),
                      ],
                    ),
                  ],
                ),
                if (comment.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    comment,
                    style: AppTheme.body(
                      fontSize: 13,
                      color: AppTheme.deepSlate,
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // 9. "My Projects" Section
  // --------------------------------------------------------------------------

  Widget _buildMyProjectsSection(
    BuildContext context,
    List<dynamic> myProjects,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('My projects'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.pureWhite,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Column(
            children: myProjects.map((p) {
              final proj = p as Map<String, dynamic>;
              final projId = (proj['id'] as num?)?.toInt();
              final percent =
                  (proj['completion_percent'] as num?)?.toInt() ?? 0;

              return InkWell(
                onTap: projId != null
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProjectDetailScreen(projectId: projId),
                          ),
                        );
                      }
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          proj['name']?.toString() ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.body(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.deepSlate,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        child: ClipRRect(
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
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$percent%',
                        style: AppTheme.mono(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.mutedSlate,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
