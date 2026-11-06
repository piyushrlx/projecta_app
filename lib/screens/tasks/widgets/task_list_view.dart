import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../models/task_model.dart';
import 'task_card.dart';

class TaskListView extends StatelessWidget {
  final List<TaskModel> tasks;
  final String selectedFilter;
  final Future<void> Function() onRefresh;
  final ValueChanged<TaskModel> onTaskTap;

  const TaskListView({
    super.key,
    required this.tasks,
    required this.selectedFilter,
    required this.onRefresh,
    required this.onTaskTap,
  });

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 48,
              color: AppTheme.mutedSlate,
            ),
            const SizedBox(height: 12),
            Text('No Tasks Found', style: AppTheme.heading(fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              'No tasks matching filter "$selectedFilter"',
              style: AppTheme.body(fontSize: 13, color: AppTheme.mutedSlate),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppTheme.royalBlue,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: tasks.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (ctx, idx) {
          final task = tasks[idx];
          return TaskCard(
            task: task,
            isKanban: false,
            onTap: () => onTaskTap(task),
          );
        },
      ),
    );
  }
}

