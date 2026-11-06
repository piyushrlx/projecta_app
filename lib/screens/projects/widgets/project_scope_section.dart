import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../models/project_model.dart';

class ProjectScopeSection extends StatelessWidget {
  final ProjectDetailModel detail;

  const ProjectScopeSection({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle, width: 1.0),
        boxShadow: const [AppTheme.softShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scope & Deliverables',
            style: AppTheme.heading(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.deepSlate,
            ),
          ),
          if (detail.scopeOfWork != null && detail.scopeOfWork!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              detail.scopeOfWork!,
              style: AppTheme.body(fontSize: 13, color: AppTheme.deepSlate),
            ),
          ],
          if (detail.deliverables != null &&
              detail.deliverables!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Deliverables',
              style: AppTheme.heading(
                fontSize: 12,
                color: AppTheme.royalBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              detail.deliverables!,
              style: AppTheme.body(fontSize: 13, color: AppTheme.deepSlate),
            ),
          ],
        ],
      ),
    );
  }
}

