import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../models/project_model.dart';

class ProjectTeamSection extends StatelessWidget {
  final List<ProjectMemberModel> members;
  final bool canManage;
  final VoidCallback onAdd;
  final ValueChanged<ProjectMemberModel> onRemove;

  const ProjectTeamSection({
    super.key,
    required this.members,
    required this.canManage,
    required this.onAdd,
    required this.onRemove,
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
                      'Team Members',
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
                      '${members.length}',
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
                  Icons.person_add_alt,
                  size: 16,
                  color: AppTheme.royalBlue,
                ),
                label: Text(
                  '+ Add Member',
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
        if (members.isEmpty)
          Text(
            'No team members assigned.',
            style: AppTheme.body(color: AppTheme.mutedSlate, fontSize: 13),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: List.generate(members.length, (idx) {
                  final mem = members[idx];
                  final isViewer = mem.memberRole.toLowerCase().contains(
                    'viewer',
                  );

                  return Padding(
                    padding: EdgeInsets.only(
                      right: idx < members.length - 1 ? 10 : 0,
                    ),
                    child: InkWell(
                      onTap: canManage ? () => onRemove(mem) : null,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 170,
                        constraints: const BoxConstraints(minHeight: 110),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.pureWhite,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.borderSubtle,
                            width: 1.0,
                          ),
                          boxShadow: const [AppTheme.softShadow],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    mem.fullName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTheme.heading(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.deepSlate,
                                    ),
                                  ),
                                ),
                                if (canManage)
                                  const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: AppTheme.mutedSlate,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isViewer
                                        ? const Color(0xFFF1F5F9)
                                        : AppTheme.infoBg,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    isViewer ? 'Viewer' : 'Member',
                                    style: AppTheme.heading(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: isViewer
                                          ? AppTheme.mutedSlate
                                          : AppTheme.infoText,
                                    ),
                                  ),
                                ),
                                if (mem.openTasks > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${mem.openTasks} open',
                                      style: AppTheme.mono(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFFB45309),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              mem.designation ?? 'Team Member',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.body(
                                fontSize: 11,
                                color: AppTheme.mutedSlate,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
      ],
    );
  }
}
