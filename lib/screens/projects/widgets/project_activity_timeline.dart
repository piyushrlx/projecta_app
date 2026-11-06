import 'package:flutter/material.dart';
import '../../../core/app_date_utils.dart';
import '../../../core/theme.dart';
import '../../../models/project_model.dart';

class ProjectActivityTimeline extends StatelessWidget {
  final List<ProjectActivityModel> activities;

  const ProjectActivityTimeline({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppTheme.infoBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.history_rounded,
              color: AppTheme.royalBlue,
              size: 18,
            ),
          ),
          title: Row(
            children: [
              Text(
                'Recent Activity',
                style: AppTheme.heading(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.deepSlate,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${activities.length}',
                  style: AppTheme.mono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.mutedSlate,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Text(
            'Tap to view audit trail & changes',
            style: AppTheme.body(fontSize: 11, color: AppTheme.mutedSlate),
          ),
          iconColor: AppTheme.deepSlate,
          collapsedIconColor: AppTheme.mutedSlate,
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          children: [
            const Divider(height: 1, color: AppTheme.borderSubtle),
            const SizedBox(height: 12),
            ...activities.take(10).map((act) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.bolt_rounded,
                      color: AppTheme.royalBlue,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            act.description,
                            style: AppTheme.body(
                              fontSize: 12,
                              color: AppTheme.deepSlate,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${AppDateUtils.fmtDateTime(act.createdAt)} (${AppDateUtils.timeAgo(act.createdAt)})',
                            style: AppTheme.mono(
                              fontSize: 10,
                              color: AppTheme.mutedSlate,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    ),
    );
  }
}
