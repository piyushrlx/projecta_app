import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class ComplianceCard extends StatelessWidget {
  final Map<String, dynamic>? badgeData;
  final VoidCallback? onSubmitReport;

  const ComplianceCard({
    super.key,
    required this.badgeData,
    this.onSubmitReport,
  });

  @override
  Widget build(BuildContext context) {
    final statusKey = (badgeData?['status_key'] ?? 'pending').toString();
    final label = (badgeData?['label'] ?? 'Pending').toString();
    final deadline = (badgeData?['deadline_time'] ?? '07:00 PM').toString();
    final isSubmitted =
        statusKey == 'submitted' || statusKey == 'submitted_late';
    final isPending = statusKey == 'pending';

    final badgeBg = isSubmitted ? AppTheme.successBg : AppTheme.warningBg;
    final badgeText = isSubmitted ? AppTheme.successText : AppTheme.warningText;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPending ? const Color(0xFFFDE68A) : AppTheme.borderSubtle,
          width: 1.0,
        ),
        boxShadow: const [AppTheme.softShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isSubmitted ? AppTheme.successBg : AppTheme.warningBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(
                    isSubmitted
                        ? Icons.check_circle_outline
                        : Icons.assignment_outlined,
                    color: isSubmitted
                        ? AppTheme.successText
                        : AppTheme.warningText,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Work Report",
                      style: AppTheme.heading(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.mutedSlate,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isSubmitted ? 'Submitted — On Time' : label,
                            style: AppTheme.heading(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: badgeText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.scaffoldBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Text(
                  'Due $deadline',
                  style: AppTheme.mono(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.mutedSlate,
                  ),
                ),
              ),
            ],
          ),
          if (isPending) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 42,
              child: ElevatedButton.icon(
                onPressed: onSubmitReport,
                icon: const Icon(Icons.send_rounded, size: 16),
                label: const Text('Submit Daily Report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.navyBlue,
                  foregroundColor: AppTheme.pureWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
