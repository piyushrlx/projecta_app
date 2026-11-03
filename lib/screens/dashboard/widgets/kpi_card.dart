import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final bool isUrgent;
  final VoidCallback? onTap;

  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.isUrgent = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14.0),
        decoration: AppTheme.neoCardDecoration(
          backgroundColor: isUrgent ? const Color(0xFFFFF0F0) : AppTheme.pureWhite,
          borderColor: isUrgent ? AppTheme.violentRed : AppTheme.pitchBlack,
          shadowOffset: 4.0,
          shadowColor: isUrgent ? AppTheme.violentRed : AppTheme.pureWhite,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.mono(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isUrgent ? AppTheme.violentRed : const Color(0xFF555555),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTheme.mono(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: isUrgent ? AppTheme.violentRed : AppTheme.pitchBlack,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.body(
                  fontSize: 11,
                  color: const Color(0xFF777777),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
