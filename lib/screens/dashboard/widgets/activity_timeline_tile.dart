import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../projects/project_detail_screen.dart';
import '../../tasks/task_detail_screen.dart';

class ActivityTimelineTile extends StatelessWidget {
  final Map<String, dynamic> activity;
  final bool isLast;

  const ActivityTimelineTile({
    super.key,
    required this.activity,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final description = activity['description']?.toString() ?? '';
    final timeAgo = activity['time_ago']?.toString() ?? '';
    final taskId = (activity['task_id'] as num?)?.toInt();
    final projectId = (activity['project_id'] as num?)?.toInt();

    return InkWell(
      onTap: () {
        if (taskId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TaskDetailScreen(taskId: taskId),
            ),
          );
        } else if (projectId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProjectDetailScreen(projectId: projectId),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Dot Indicator
            Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: const BoxDecoration(
                    color: AppTheme.royalBlue,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 38,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: const Color(0xFFE2E8F0),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: AppTheme.body(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.deepSlate,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    timeAgo,
                    style: AppTheme.mono(
                      fontSize: 11,
                      color: AppTheme.lightSlate,
                    ),
                  ),
                ],
              ),
            ),
            if (taskId != null || projectId != null)
              const Icon(
                Icons.chevron_right,
                size: 16,
                color: AppTheme.lightSlate,
              ),
          ],
        ),
      ),
    );
  }
}
