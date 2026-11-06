import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../models/task_model.dart';

class TaskAvatarStack extends StatelessWidget {
  final List<TaskAssigneeModel> assignees;

  const TaskAvatarStack({super.key, required this.assignees});

  static Color avatarColor(String name) {
    final colors = [
      const Color(0xFF2563EB),
      const Color(0xFF0D9488),
      const Color(0xFFD97706),
      const Color(0xFF7C3AED),
      const Color(0xFFDC2626),
      const Color(0xFF0284C7),
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  static String getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (assignees.isEmpty) {
      return Text(
        'Unassigned',
        style: AppTheme.body(
          fontSize: 11,
          color: AppTheme.mutedSlate,
        ),
      );
    }

    const maxDisplay = 3;
    final displayed = assignees.take(maxDisplay).toList();
    final overflow = assignees.length - maxDisplay;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 22,
          width: 22.0 + (displayed.length - 1) * 14.0,
          child: Stack(
            children: List.generate(displayed.length, (i) {
              final a = displayed[i];
              final initials = getInitials(a.fullName);

              return Positioned(
                left: i * 14.0,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: avatarColor(a.fullName),
                    border: Border.all(
                      color: AppTheme.pureWhite,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        if (overflow > 0) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '+$overflow',
              style: AppTheme.mono(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppTheme.deepSlate,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

