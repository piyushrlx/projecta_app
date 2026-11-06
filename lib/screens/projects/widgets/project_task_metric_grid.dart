import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../models/project_model.dart';

class ProjectTaskMetricGrid extends StatelessWidget {
  final ProjectTaskCountsModel counts;

  const ProjectTaskMetricGrid({super.key, required this.counts});

  @override
  Widget build(BuildContext context) {
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
            style: AppTheme.heading(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
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
}

