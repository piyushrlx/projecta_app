import 'package:flutter/material.dart';
import '../../../core/app_date_utils.dart';
import '../../../core/theme.dart';
import '../../../models/project_model.dart';

class ProjectMilestonesSection extends StatelessWidget {
  final List<ProjectMilestoneModel> milestones;
  final bool canManage;
  final ValueChanged<ProjectMilestoneModel> onToggle;
  final VoidCallback onAdd;
  final ValueChanged<ProjectMilestoneModel> onEdit;
  final ValueChanged<ProjectMilestoneModel> onDelete;

  const ProjectMilestonesSection({
    super.key,
    required this.milestones,
    required this.canManage,
    required this.onToggle,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      'Milestones',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.heading(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.scaffoldBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: Text(
                      '${milestones.length}',
                      style: AppTheme.mono(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.deepSlate,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (canManage)
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(
                  Icons.add,
                  size: 16,
                  color: AppTheme.royalBlue,
                ),
                label: Text(
                  '+ Add Milestone',
                  style: AppTheme.heading(
                    fontSize: 12,
                    color: AppTheme.royalBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (milestones.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.pureWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'No milestones defined for this project.',
                    style: AppTheme.body(
                      color: AppTheme.mutedSlate,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (canManage)
                  ElevatedButton(
                    onPressed: onAdd,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.navyBlue,
                      foregroundColor: AppTheme.pureWhite,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    child: const Text('Add One'),
                  ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.pureWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderSubtle, width: 1.0),
              boxShadow: const [AppTheme.softShadow],
            ),
            child: Column(
              children: List.generate(milestones.length, (idx) {
                final m = milestones[idx];
                final isDone = m.isCompleted;
                final isLast = idx == milestones.length - 1;

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          InkWell(
                            onTap: () => onToggle(m),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: isDone
                                    ? AppTheme.successBg
                                    : AppTheme.scaffoldBg,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isDone
                                      ? AppTheme.successText
                                      : AppTheme.borderSubtle,
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: isDone
                                    ? const Icon(
                                        Icons.check,
                                        size: 16,
                                        color: AppTheme.successText,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          if (!isLast)
                            Expanded(
                              child: Container(
                                width: 1.5,
                                color: AppTheme.borderSubtle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: isLast ? 0 : 20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          m.title,
                                          style:
                                              AppTheme.heading(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: isDone
                                                    ? AppTheme.mutedSlate
                                                    : AppTheme.deepSlate,
                                              ).copyWith(
                                                decoration: isDone
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                              ),
                                        ),
                                        if (m.description != null &&
                                            m.description!.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            m.description!,
                                            style: AppTheme.body(
                                              fontSize: 12,
                                              color: AppTheme.mutedSlate,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDone
                                              ? AppTheme.successBg
                                              : const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          m.status.isEmpty
                                              ? 'Pending'
                                              : m.status[0].toUpperCase() +
                                                    m.status
                                                        .substring(1)
                                                        .toLowerCase(),
                                          style: AppTheme.heading(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: isDone
                                                ? AppTheme.successText
                                                : AppTheme.mutedSlate,
                                          ),
                                        ),
                                      ),
                                      if (canManage) ...[
                                        const SizedBox(width: 4),
                                        PopupMenuButton<String>(
                                          padding: EdgeInsets.zero,
                                          iconSize: 18,
                                          icon: const Icon(
                                            Icons.more_vert,
                                            size: 18,
                                            color: AppTheme.mutedSlate,
                                          ),
                                          onSelected: (val) {
                                            if (val == 'edit') {
                                              onEdit(m);
                                            }
                                            if (val == 'delete') {
                                              onDelete(m);
                                            }
                                          },
                                          itemBuilder: (_) => [
                                            const PopupMenuItem(
                                              value: 'edit',
                                              child: Text('Edit Milestone'),
                                            ),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Text(
                                                'Delete Milestone',
                                                style: TextStyle(
                                                  color: AppTheme.dangerText,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  if (m.dueDate != null) ...[
                                    Text(
                                      'Due: ${AppDateUtils.fmtDate(m.dueDate)}',
                                      style: AppTheme.mono(
                                        fontSize: 11,
                                        color: m.isOverdue
                                            ? AppTheme.dangerText
                                            : AppTheme.mutedSlate,
                                        fontWeight: m.isOverdue
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                    if (m.isOverdue)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.dangerBg,
                                          borderRadius: BorderRadius.circular(
                                            3,
                                          ),
                                        ),
                                        child: Text(
                                          'OVERDUE',
                                          style: AppTheme.mono(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.dangerText,
                                          ),
                                        ),
                                      ),
                                  ],
                                  if (m.taskCount > 0) ...[
                                    Text(
                                      '·',
                                      style: TextStyle(
                                        color: AppTheme.mutedSlate,
                                      ),
                                    ),
                                    Text(
                                      '${m.taskCount} task${m.taskCount == 1 ? '' : 's'}',
                                      style: AppTheme.body(
                                        fontSize: 11,
                                        color: AppTheme.mutedSlate,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (m.deliverables != null &&
                                  m.deliverables!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.scaffoldBg,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: AppTheme.borderSubtle,
                                    ),
                                  ),
                                  child: Text(
                                    'Deliverables: ${m.deliverables}',
                                    style: AppTheme.body(
                                      fontSize: 12,
                                      color: AppTheme.deepSlate,
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
              }),
            ),
          ),
      ],
    );
  }
}
