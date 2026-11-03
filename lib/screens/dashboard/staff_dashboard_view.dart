import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/user_model.dart';
import '../reports/report_submission_screen.dart';
import '../tasks/task_detail_screen.dart';
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
    final compliance = data['compliance_badge'] as Map<String, dynamic>?;
    final nextTasks = (data['what_to_work_on_next'] as List<dynamic>?) ?? [];
    final recentFeedback = (data['recent_feedback'] as List<dynamic>?) ?? [];

    final overdueCount = (kpis['overdue'] ?? 0) as int;

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
              'MY METRICS',
              style: AppTheme.mono(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppTheme.pureWhite,
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
        const SizedBox(height: 10),

        // 2-Column KPI Grid
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
                label: 'Open Tasks',
                value: '${kpis['open_tasks'] ?? 0}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: KpiCard(
                label: 'In Progress',
                value: '${kpis['in_progress_tasks'] ?? 0}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: KpiCard(
                label: 'Overdue Tasks',
                value: '$overdueCount',
                isUrgent: overdueCount > 0,
                subtitle: overdueCount > 0 ? 'Requires attention' : 'All clear',
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // 3. Section: "What should I work on next?"
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: AppTheme.violentRed,
          child: Row(
            children: [
              const Icon(Icons.flash_on, color: AppTheme.pureWhite, size: 18),
              const SizedBox(width: 8),
              Text(
                'WHAT SHOULD I WORK ON NEXT?',
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

        if (nextTasks.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.neoCardDecoration(
              backgroundColor: AppTheme.pureWhite,
              borderColor: AppTheme.pitchBlack,
              shadowOffset: 4.0,
            ),
            child: Column(
              children: [
                const Icon(Icons.task_alt, color: Colors.green, size: 36),
                const SizedBox(height: 8),
                Text(
                  'ALL CAUGHT UP!',
                  style: AppTheme.heading(
                    fontSize: 16,
                    color: AppTheme.pitchBlack,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You have no pending high-priority tasks assigned.',
                  textAlign: TextAlign.center,
                  style: AppTheme.body(fontSize: 12),
                ),
              ],
            ),
          )
        else
          ...nextTasks.map((item) {
            final task = item as Map<String, dynamic>;
            final progress = (task['progress'] ?? 0) as int;
            final isOverdue =
                task['is_overdue'] == true ||
                task['reason'].toString().toLowerCase().contains('overdue');

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
                margin: const EdgeInsets.only(bottom: 12.0),
                padding: const EdgeInsets.all(16.0),
                decoration: AppTheme.neoCardDecoration(
                  backgroundColor: AppTheme.pureWhite,
                  borderColor: isOverdue
                      ? AppTheme.violentRed
                      : AppTheme.pitchBlack,
                  shadowOffset: 4.0,
                  shadowColor: isOverdue
                      ? AppTheme.violentRed
                      : AppTheme.pureWhite,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            task['title']?.toString() ?? 'Untitled Task',
                            style: AppTheme.heading(
                              fontSize: 16,
                              color: AppTheme.pitchBlack,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          color: isOverdue
                              ? AppTheme.violentRed
                              : AppTheme.pitchBlack,
                          child: Text(
                            '$progress%',
                            style: AppTheme.mono(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.pureWhite,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      task['project_name']?.toString() ?? '',
                      style: AppTheme.body(
                        fontSize: 13,
                        color: const Color(0xFF555555),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.zero,
                      child: LinearProgressIndicator(
                        value: (progress / 100).clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: const Color(0xFFE5E5E5),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isOverdue ? AppTheme.violentRed : AppTheme.pitchBlack,
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
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isOverdue
                                  ? const Color(0xFFFFEEEE)
                                  : const Color(0xFFF0F0F0),
                              border: Border.all(
                                color: isOverdue
                                    ? AppTheme.violentRed
                                    : const Color(0xFFCCCCCC),
                              ),
                            ),
                            child: Text(
                              task['reason'].toString().toUpperCase(),
                              style: AppTheme.mono(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isOverdue
                                    ? AppTheme.violentRed
                                    : AppTheme.pitchBlack,
                              ),
                            ),
                          ),
                        if (task['deadline'] != null)
                          Text(
                            'DEADLINE: ${task['deadline']}',
                            style: AppTheme.mono(
                              fontSize: 11,
                              color: isOverdue
                                  ? AppTheme.violentRed
                                  : const Color(0xFF666666),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),

        // 4. Section: Recent Supervisor Feedback
        if (recentFeedback.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'SUPERVISOR FEEDBACK',
            style: AppTheme.mono(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppTheme.pureWhite,
            ),
          ),
          const SizedBox(height: 10),
          ...recentFeedback.map((fb) {
            final f = fb as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: AppTheme.neoCardDecoration(
                backgroundColor: AppTheme.pureWhite,
                borderColor: AppTheme.pitchBlack,
                shadowOffset: 3.0,
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
                          color: AppTheme.pitchBlack,
                        ),
                      ),
                      Text(
                        f['report_date']?.toString() ?? '',
                        style: AppTheme.mono(
                          fontSize: 11,
                          color: const Color(0xFF777777),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    f['review_comment']?.toString() ??
                        'No review notes provided.',
                    style: AppTheme.body(fontSize: 13),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}
