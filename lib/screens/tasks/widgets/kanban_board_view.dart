import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../models/task_model.dart';
import 'task_card.dart';

class KanbanBoardView extends StatelessWidget {
  final Map<String, List<TaskModel>> kanbanColumns;
  final PageController pageController;
  final int activePage;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<TaskModel> onTaskTap;
  final ValueChanged<TaskModel> onStatusPillTap;
  final void Function(TaskModel task, String targetStatus) onTaskMove;
  final Future<void> Function() onRefresh;

  const KanbanBoardView({
    super.key,
    required this.kanbanColumns,
    required this.pageController,
    required this.activePage,
    required this.onPageChanged,
    required this.onTaskTap,
    required this.onStatusPillTap,
    required this.onTaskMove,
    required this.onRefresh,
  });

  static const List<Map<String, dynamic>> columnDefs = [
    {
      'key': 'not_started',
      'label': 'Not Started',
      'bg': Color(0xFFF1F5F9),
      'fg': AppTheme.mutedSlate,
    },
    {
      'key': 'in_progress',
      'label': 'In Progress',
      'bg': AppTheme.infoBg,
      'fg': AppTheme.infoText,
    },
    {
      'key': 'blocked',
      'label': 'Blocked',
      'bg': AppTheme.dangerBg,
      'fg': AppTheme.dangerText,
    },
    {
      'key': 'pending_review',
      'label': 'Pending Review',
      'bg': AppTheme.warningBg,
      'fg': AppTheme.warningText,
    },
    {
      'key': 'completed',
      'label': 'Completed',
      'bg': AppTheme.successBg,
      'fg': AppTheme.successText,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Horizontal Column Indicators & Status Tabs (accepts drops too!)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppTheme.pureWhite,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(columnDefs.length, (idx) {
                final def = columnDefs[idx];
                final colKey = def['key'] as String;
                final list = kanbanColumns[colKey] ?? [];
                final isCurrent = activePage == idx;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: DragTarget<TaskModel>(
                    onWillAcceptWithDetails: (details) =>
                        details.data.status != colKey,
                    onAcceptWithDetails: (details) {
                      onTaskMove(details.data, colKey);
                    },
                    builder: (context, candidateData, rejectedData) {
                      final isHovered = candidateData.isNotEmpty;

                      return InkWell(
                        onTap: () {
                          pageController.animateToPage(
                            idx,
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                          );
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isHovered
                                ? AppTheme.royalBlue.withValues(alpha: 0.2)
                                : isCurrent
                                    ? AppTheme.navyBlue
                                    : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                            border: isHovered
                                ? Border.all(
                                    color: AppTheme.royalBlue,
                                    width: 1.5,
                                  )
                                : null,
                          ),
                          child: Text(
                            '${def['label']} (${list.length})',
                            style: AppTheme.heading(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isCurrent
                                  ? AppTheme.pureWhite
                                  : AppTheme.mutedSlate,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
            ),
          ),
        ),

        // Snapping PageView with viewportFraction 0.88 + DragTarget columns
        Expanded(
          child: PageView.builder(
            controller: pageController,
            itemCount: columnDefs.length,
            onPageChanged: onPageChanged,
            itemBuilder: (context, colIndex) {
              final col = columnDefs[colIndex];
              final colKey = col['key'] as String;
              final list = kanbanColumns[colKey] ?? [];

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6.0,
                  vertical: 12.0,
                ),
                child: DragTarget<TaskModel>(
                  onWillAcceptWithDetails: (details) =>
                      details.data.status != colKey,
                  onAcceptWithDetails: (details) {
                    onTaskMove(details.data, colKey);
                  },
                  builder: (context, candidateData, rejectedData) {
                    final isTargetHovered = candidateData.isNotEmpty;

                    return Container(
                      decoration: BoxDecoration(
                        color: isTargetHovered
                            ? const Color(0xFFEFF6FF)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isTargetHovered
                              ? AppTheme.royalBlue
                              : AppTheme.borderSubtle,
                          width: isTargetHovered ? 2.0 : 1.0,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Column Header
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: const BoxDecoration(
                              color: AppTheme.pureWhite,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              border: Border(
                                bottom: BorderSide(
                                  color: AppTheme.borderSubtle,
                                  width: 1.0,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  col['label'] as String,
                                  style: AppTheme.heading(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.deepSlate,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: col['bg'] as Color,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${list.length}',
                                    style: AppTheme.mono(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: col['fg'] as Color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Column Tasks List
                          Expanded(
                            child: list.isEmpty
                                ? Center(
                                    child: Text(
                                      'No tasks in ${col['label']}',
                                      style: AppTheme.body(
                                        fontSize: 12,
                                        color: AppTheme.mutedSlate,
                                      ),
                                    ),
                                  )
                                : RefreshIndicator(
                                    onRefresh: onRefresh,
                                    color: AppTheme.royalBlue,
                                    child: ListView.separated(
                                      padding: const EdgeInsets.all(12),
                                      itemCount: list.length,
                                      separatorBuilder: (_, _) =>
                                          const SizedBox(height: 10),
                                      itemBuilder: (ctx, idx) {
                                        final task = list[idx];
                                        return TaskCard(
                                          task: task,
                                          isKanban: true,
                                          onTap: () => onTaskTap(task),
                                          onStatusPillTap: () =>
                                              onStatusPillTap(task),
                                        );
                                      },
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

