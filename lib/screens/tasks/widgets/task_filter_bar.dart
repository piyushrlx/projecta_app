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
      color: AppTheme.pureWhite,
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
                        ? (isAlert ? AppTheme.dangerBg : AppTheme.navyBlue)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? (isAlert
                              ? const Color(0xFFFECACA)
                              : AppTheme.navyBlue)
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
                          : AppTheme.mutedSlate,
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

  const TaskKanbanFilterBar({
    super.key,
    required this.selectedPriority,
    required this.onPriorityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final priorities = ['All', 'Critical', 'High', 'Medium', 'Low'];

    return Container(
      color: AppTheme.pureWhite,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.tune, size: 14, color: AppTheme.mutedSlate),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: priorities.map((p) {
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
                              ? AppTheme.navyBlue
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          p,
                          style: AppTheme.heading(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? AppTheme.pureWhite
                                : AppTheme.mutedSlate,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

