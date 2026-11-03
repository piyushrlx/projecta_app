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
    final label = (badgeData?['label'] ?? 'Pending Report').toString();
    final deadline = (badgeData?['deadline_time'] ?? '07:00 PM').toString();
    final isSubmitted = statusKey == 'submitted' || statusKey == 'submitted_late';
    final isPending = statusKey == 'pending';

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: AppTheme.neoCardDecoration(
        backgroundColor: isSubmitted ? const Color(0xFFF0FDF4) : AppTheme.pureWhite,
        borderColor: isPending ? AppTheme.violentRed : AppTheme.pitchBlack,
        shadowOffset: 4.0,
        shadowColor: isPending ? AppTheme.violentRed : AppTheme.pureWhite,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                color: isSubmitted ? Colors.green.shade800 : AppTheme.violentRed,
                child: Icon(
                  isSubmitted ? Icons.check_circle_outline : Icons.assignment_late_outlined,
                  color: AppTheme.pureWhite,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "TODAY'S WORK REPORT",
                      style: AppTheme.mono(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF555555),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label.toUpperCase(),
                      style: AppTheme.heading(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: isPending ? AppTheme.violentRed : AppTheme.pitchBlack,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.pitchBlack,
                  border: Border.all(color: AppTheme.pitchBlack),
                ),
                child: Text(
                  'DUE $deadline',
                  style: AppTheme.mono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.pureWhite,
                  ),
                ),
              ),
            ],
          ),
          if (isPending) ...[
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: onSubmitReport,
              icon: const Icon(Icons.send_rounded, size: 16),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.violentRed,
                foregroundColor: AppTheme.pureWhite,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              label: Text(
                'SUBMIT DAILY REPORT',
                style: AppTheme.mono(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.pureWhite,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
