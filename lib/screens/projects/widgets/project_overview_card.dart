import 'package:flutter/material.dart';
import '../../../core/app_date_utils.dart';
import '../../../core/theme.dart';
import '../../../models/project_model.dart';

class ProjectOverviewCard extends StatelessWidget {
  final ProjectModel project;
  final ProjectDetailModel detail;

  const ProjectOverviewCard({
    super.key,
    required this.project,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final p = project;

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
                    fontSize: 12,
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
                      AppDateUtils.fmtDate(p.startDate),
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
                      p.deadline != null
                          ? '${AppDateUtils.fmtDate(p.deadline)}${p.deadlineDaysLabel != null ? ' (${p.deadlineDaysLabel})' : ''}'
                          : 'None',
                      style: AppTheme.mono(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: p.isOverdue
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
}

