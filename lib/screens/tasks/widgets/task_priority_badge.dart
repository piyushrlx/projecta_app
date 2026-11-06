import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class TaskPriorityBadge extends StatelessWidget {
  final String priority;

  const TaskPriorityBadge({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    Color bg = const Color(0xFFF1F5F9);
    Color fg = AppTheme.mutedSlate;

    final p = priority.toLowerCase();
    if (p == 'critical' || p == 'urgent') {
      bg = AppTheme.dangerBg;
      fg = AppTheme.dangerText;
    } else if (p == 'high') {
      bg = AppTheme.warningBg;
      fg = AppTheme.warningText;
    } else if (p == 'medium') {
      bg = AppTheme.infoBg;
      fg = AppTheme.infoText;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        priority.isNotEmpty
            ? priority[0].toUpperCase() + priority.substring(1).toLowerCase()
            : 'Medium',
        style: AppTheme.heading(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

