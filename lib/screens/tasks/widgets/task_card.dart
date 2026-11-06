import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/brutalist_pressable.dart';
import '../../../models/task_model.dart';
import 'task_avatar_stack.dart';
import 'task_priority_badge.dart';
import 'task_status_pill.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final bool isKanban;
  final VoidCallback? onTap;
  final VoidCallback? onStatusPillTap;

  const TaskCard({
    super.key,
    required this.task,
    this.isKanban = false,
    this.onTap,
    this.onStatusPillTap,
  });

  Widget _buildCardContent(BuildContext context) {
    return BrutalistPressable(
      onTap: onTap,
      backgroundColor: AppTheme.pureWhite,
      borderColor: task.isLocked
          ? const Color(0xFFFECACA)
          : AppTheme.borderSubtle,
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Code + Project + Priority Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.scaffoldBg,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Text(
                  task.taskCode,
                  style: AppTheme.mono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.deepSlate,
                  ),
                ),
              ),
              if (task.projectName != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    task.projectName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.body(
                      fontSize: 11,
                      color: AppTheme.mutedSlate,
                    ),
                  ),
                ),
              ] else
                const Spacer(),
              TaskPriorityBadge(priority: task.priority),
            ],
          ),
          const SizedBox(height: 8),

          // Title
          Text(
            task.title,
            style: AppTheme.heading(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.deepSlate,
            ),
          ),
          const SizedBox(height: 8),

          // Dependency Lock Banner if locked
          if (task.isLocked) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.dangerBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 14,
                    color: AppTheme.dangerText,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Blocked by ${task.openDependenciesCount} dependenc${task.openDependenciesCount == 1 ? 'y' : 'ies'}',
                      style: AppTheme.heading(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.dangerText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Progress Bar if in progress
          if (task.status == 'in_progress' || task.progress > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress',
                  style: AppTheme.body(
                    fontSize: 10,
                    color: AppTheme.mutedSlate,
                  ),
                ),
                Text(
                  '${task.progress}%',
                  style: AppTheme.mono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.deepSlate,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (task.progress / 100).clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(
                  task.isLocked ? AppTheme.dangerText : AppTheme.royalBlue,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Bottom Meta Row: Status tag, Avatar Stack, Deadline
          Row(
            children: [
              TaskStatusPill(
                key: ValueKey('task_status_pill_${task.id}'),
                status: task.status,
                isInteractive: isKanban,
                onTap: onStatusPillTap,
              ),
              const SizedBox(width: 8),
              TaskAvatarStack(assignees: task.assignees),
              const Spacer(),
              Icon(
                Icons.calendar_today_outlined,
                size: 12,
                color: task.isOverdue
                    ? AppTheme.dangerText
                    : AppTheme.lightSlate,
              ),
              const SizedBox(width: 4),
              Text(
                task.isOverdue && task.overdueDays > 0
                    ? '${task.formattedDeadline} (${task.overdueDays}d overdue)'
                    : task.isOverdue
                        ? '${task.formattedDeadline} (overdue)'
                        : task.formattedDeadline,
                style: AppTheme.mono(
                  fontSize: 10,
                  color: task.isOverdue
                      ? AppTheme.dangerText
                      : AppTheme.mutedSlate,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildCardContent(context);

    if (!isKanban) {
      return content;
    }

    return LongPressDraggable<TaskModel>(
      data: task,
      delay: const Duration(milliseconds: 250),
      hapticFeedbackOnStart: true,
      onDragStarted: () => HapticFeedback.mediumImpact(),
      feedback: Material(
        color: Colors.transparent,
        elevation: 8,
        shadowColor: Colors.black26,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Opacity(
            opacity: 0.95,
            child: content,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: content,
      ),
      child: content,
    );
  }
}

