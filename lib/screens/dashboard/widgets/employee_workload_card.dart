import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/brutalist_pressable.dart';

class EmployeeWorkloadCard extends StatelessWidget {
  final Map<String, dynamic> employee;
  final VoidCallback? onTap;

  const EmployeeWorkloadCard({
    super.key,
    required this.employee,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = employee['full_name']?.toString() ?? 'Staff Member';
    final dept = employee['department_name']?.toString() ?? 'General';
    final photo = employee['profile_photo']?.toString();
    final activeProjects = (employee['active_projects'] as num?)?.toInt() ?? 0;
    final assigned = (employee['assigned'] as num?)?.toInt() ?? 0;
    final done = (employee['completed'] as num?)?.toInt() ?? 0;
    final pending = (employee['pending'] as num?)?.toInt() ?? 0;
    final overdue = (employee['overdue'] as num?)?.toInt() ?? 0;
    final lastReport = employee['last_report_relative']?.toString() ?? 'Never';
    final todayStatus = employee['today_status']?.toString() ?? 'not_due';

    return BrutalistPressable(
      onTap: onTap,
      backgroundColor: AppTheme.pureWhite,
      borderColor: AppTheme.borderSubtle,
      borderRadius: BorderRadius.circular(12),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, Name, Department & Today's Status Pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildAvatar(name, photo),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTheme.heading(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.deepSlate,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dept,
                      style: AppTheme.body(
                        fontSize: 11,
                        color: AppTheme.mutedSlate,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildComplianceBadge(todayStatus),
            ],
          ),
          const SizedBox(height: 10),

          // Workload Metrics Strip (Projects, Assigned, Done, Pending, Overdue)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: BoxDecoration(
              color: AppTheme.scaffoldBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Row(
              children: [
                Expanded(child: _buildMetricCol('Projects', '$activeProjects', AppTheme.deepSlate)),
                _buildDivider(),
                Expanded(child: _buildMetricCol('Assigned', '$assigned', AppTheme.deepSlate)),
                _buildDivider(),
                Expanded(child: _buildMetricCol('Done', '$done', AppTheme.successText)),
                _buildDivider(),
                Expanded(child: _buildMetricCol('Pending', '$pending', AppTheme.mutedSlate)),
                _buildDivider(),
                Expanded(
                  child: _buildMetricCol(
                    'Overdue',
                    '$overdue',
                    overdue > 0 ? AppTheme.dangerText : AppTheme.mutedSlate,
                    isBold: overdue > 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Footer: Last report time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.history,
                      size: 13,
                      color: AppTheme.lightSlate,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Last report: $lastReport',
                        style: AppTheme.mono(
                          fontSize: 11,
                          color: AppTheme.mutedSlate,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (overdue > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$overdue overdue',
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
    );
  }

  Widget _buildAvatar(String name, String? photo) {
    if (photo != null && photo.isNotEmpty && photo.startsWith('http')) {
      return CircleAvatar(
        radius: 18,
        backgroundImage: NetworkImage(photo),
      );
    }
    final initials = name.isNotEmpty
        ? name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join()
        : '?';
    return CircleAvatar(
      radius: 18,
      backgroundColor: const Color(0xFFE2E8F0),
      child: Text(
        initials.toUpperCase(),
        style: AppTheme.heading(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.mutedSlate,
        ),
      ),
    );
  }

  Widget _buildMetricCol(
    String label,
    String value,
    Color color, {
    bool isBold = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTheme.mono(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTheme.body(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: AppTheme.lightSlate,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 20,
      color: AppTheme.borderSubtle,
    );
  }

  Widget _buildComplianceBadge(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'submitted':
        bg = AppTheme.successBg;
        fg = AppTheme.successText;
        label = 'Submitted';
        break;
      case 'submitted_late':
        bg = AppTheme.warningBg;
        fg = AppTheme.warningText;
        label = 'Late';
        break;
      case 'pending':
        bg = AppTheme.dangerBg;
        fg = AppTheme.dangerText;
        label = 'Pending';
        break;
      case 'exempt':
      case 'on_leave':
        bg = AppTheme.infoBg;
        fg = AppTheme.infoText;
        label = 'Exempt';
        break;
      case 'not_due':
      default:
        bg = const Color(0xFFF1F5F9);
        fg = AppTheme.mutedSlate;
        label = 'Not Due';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTheme.heading(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
