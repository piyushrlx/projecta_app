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
      'shortLabel': 'Not Started',
      'bg': Color(0xFFF1F5F9),
      'fg': AppTheme.mutedSlate,
    },
    {
      'key': 'in_progress',
      'label': 'In Progress',
      'shortLabel': 'In Progress',
      'bg': AppTheme.infoBg,
      'fg': AppTheme.infoText,
    },
    {
      'key': 'blocked',
      'label': 'Blocked',
      'shortLabel': 'Blocked',
      'bg': AppTheme.dangerBg,
      'fg': AppTheme.dangerText,
    },
    {
      'key': 'pending_review',
      'label': 'Pending Review',
      'shortLabel': 'Review',
      'bg': AppTheme.warningBg,
      'fg': AppTheme.warningText,
    },
    {
      'key': 'completed',
      'label': 'Completed',
      'shortLabel': 'Done',
      'bg': AppTheme.successBg,
      'fg': AppTheme.successText,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Horizontal Column Indicators & Status Tabs (accepts drops too! 100% visible on 360-390dp)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          color: AppTheme.scaffoldBg,
          child: Row(
            children: List.generate(columnDefs.length, (idx) {
              final def = columnDefs[idx];
              final colKey = def['key'] as String;
              final list = kanbanColumns[colKey] ?? [];
              final isCurrent = activePage == idx;
              final label = (def['shortLabel'] ?? def['label']) as String;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: idx == columnDefs.length - 1 ? 0 : 4,
                  ),
                  child: DragTarget<TaskModel>(
                    onWillAcceptWithDetails: (details) =>
                        details.data.status != colKey &&
                        details.data.isStatusAllowed(colKey),
                    onAcceptWithDetails: (details) {
                      onTaskMove(details.data, colKey);
                    },
                    builder: (context, candidateData, rejectedData) {
                      final isHovered = candidateData.isNotEmpty;
                      final isRejected = rejectedData.isNotEmpty;

                      return InkWell(
                        onTap: () {
                          pageController.animateToPage(
                            idx,
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isHovered
                                ? AppTheme.electricIndigo.withValues(alpha: 0.15)
                                : isRejected
                                    ? AppTheme.dangerBg
                                    : isCurrent
                                        ? AppTheme.electricIndigo
                                        : AppTheme.pureWhite,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isHovered
                                  ? AppTheme.electricIndigo
                                  : isRejected
                                      ? AppTheme.dangerText
                                      : isCurrent
                                          ? AppTheme.electricIndigo
                                          : AppTheme.borderSubtle,
                              width: (isHovered || isRejected) ? 1.5 : 1.0,
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '$label (${list.length})',
                              maxLines: 1,
                              style: AppTheme.heading(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isCurrent
                                    ? AppTheme.pureWhite
                                    : isRejected
                                        ? AppTheme.dangerText
                                        : AppTheme.textSecondaryNavy,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            }),
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
                      details.data.status != colKey &&
                      details.data.isStatusAllowed(colKey),
                  onAcceptWithDetails: (details) {
                    onTaskMove(details.data, colKey);
                  },
                  builder: (context, candidateData, rejectedData) {
                    final isTargetHovered = candidateData.isNotEmpty;
                    final isTargetRejected = rejectedData.isNotEmpty;

                    return Container(
                      decoration: BoxDecoration(
                        color: isTargetHovered
                            ? const Color(0xFFEEF0FF)
                            : isTargetRejected
                                ? const Color(0xFFFEF2F2)
                                : const Color(0xFFEEF1F6),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isTargetHovered
                              ? AppTheme.electricIndigo
                              : isTargetRejected
                                  ? AppTheme.dangerText
                                  : AppTheme.borderSubtle,
                          width: (isTargetHovered || isTargetRejected) ? 1.5 : 1.0,
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
                              color: Color(0xFFEEF1F6),
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(18),
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

