import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class TaskListFilterBar extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  const TaskListFilterBar({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filters = [
      'All',
      'My Priority',
      'Overdue',
      'In Progress',
      'Blocked',
      'Pending Review',
    ];

    return Container(
      color: AppTheme.scaffoldBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final isSelected = selectedFilter.toUpperCase() == f.toUpperCase();
            final isAlert =
                f.toUpperCase() == 'OVERDUE' || f.toUpperCase() == 'BLOCKED';

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => onFilterChanged(f),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isAlert ? AppTheme.dangerBg : AppTheme.electricIndigo)
                        : AppTheme.pureWhite,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? (isAlert
                              ? const Color(0xFFFECACA)
                              : AppTheme.electricIndigo)
                          : AppTheme.borderSubtle,
                    ),
                  ),
                  child: Text(
                    f,
                    style: AppTheme.heading(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? (isAlert ? AppTheme.dangerText : AppTheme.pureWhite)
                          : AppTheme.textSecondaryNavy,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class TaskKanbanFilterBar extends StatelessWidget {
  final String selectedPriority;
  final ValueChanged<String> onPriorityChanged;
  final String? selectedProjectName;
  final VoidCallback? onProjectFilterTap;
  final String? selectedAssigneeName;
  final VoidCallback? onAssigneeFilterTap;
  final VoidCallback? onClearFilters;

  const TaskKanbanFilterBar({
    super.key,
    required this.selectedPriority,
    required this.onPriorityChanged,
    this.selectedProjectName,
    this.onProjectFilterTap,
    this.selectedAssigneeName,
    this.onAssigneeFilterTap,
    this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final priorities = ['All', 'Critical', 'High', 'Medium', 'Low'];
    final hasActiveFilter = selectedPriority != 'All' ||
        selectedProjectName != null ||
        selectedAssigneeName != null;

    return Container(
      color: AppTheme.scaffoldBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.tune, size: 14, color: AppTheme.textSecondaryNavy),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Optional Project Filter Chip
                  if (onProjectFilterTap != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InkWell(
                        onTap: onProjectFilterTap,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: selectedProjectName != null
                                ? AppTheme.royalBlue
                                : AppTheme.pureWhite,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selectedProjectName != null
                                  ? AppTheme.royalBlue
                                  : AppTheme.borderSubtle,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.folder_outlined,
                                size: 12,
                                color: selectedProjectName != null
                                    ? AppTheme.pureWhite
                                    : AppTheme.mutedSlate,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                selectedProjectName ?? 'Project',
                                style: AppTheme.heading(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: selectedProjectName != null
                                      ? AppTheme.pureWhite
                                      : AppTheme.textSecondaryNavy,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Optional Assignee Filter Chip
                  if (onAssigneeFilterTap != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InkWell(
                        onTap: onAssigneeFilterTap,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: selectedAssigneeName != null
                                ? AppTheme.royalBlue
                                : AppTheme.pureWhite,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selectedAssigneeName != null
                                  ? AppTheme.royalBlue
                                  : AppTheme.borderSubtle,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 12,
                                color: selectedAssigneeName != null
                                    ? AppTheme.pureWhite
                                    : AppTheme.mutedSlate,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                selectedAssigneeName ?? 'Assignee',
                                style: AppTheme.heading(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: selectedAssigneeName != null
                                      ? AppTheme.pureWhite
                                      : AppTheme.textSecondaryNavy,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Priority Filter Pills
                  ...priorities.map((p) {
                    final isSelected = selectedPriority == p;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InkWell(
                        onTap: () {
                          if (selectedPriority != p) {
                            onPriorityChanged(p);
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.electricIndigo
                                : AppTheme.pureWhite,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.electricIndigo
                                  : AppTheme.borderSubtle,
                            ),
                          ),
                          child: Text(
                            p,
                            style: AppTheme.heading(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? AppTheme.pureWhite
                                  : AppTheme.textSecondaryNavy,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),

                  // Reset Pill
                  if (hasActiveFilter && onClearFilters != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InkWell(
                        onTap: onClearFilters,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.borderSubtle),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.close,
                                size: 11,
                                color: AppTheme.mutedSlate,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'Reset',
                                style: AppTheme.heading(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.mutedSlate,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

