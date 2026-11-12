import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/brutalist_pressable.dart';

class KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final bool isUrgent;
  final Color? valueColor;
  final VoidCallback? onTap;
  final IconData? icon;
  final String? badgeText;
  final Color? badgeColor;
  final Color? badgeBgColor;
  final double? progressValue;

  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.isUrgent = false,
    this.valueColor,
    this.onTap,
    this.icon,
    this.badgeText,
    this.badgeColor,
    this.badgeBgColor,
    this.progressValue,
  });

  @override
  Widget build(BuildContext context) {
    return BrutalistPressable(
      onTap: onTap,
      backgroundColor: isUrgent ? const Color(0xFFFEF2F2) : AppTheme.pureWhite,
      borderColor: isUrgent ? const Color(0xFFFECACA) : AppTheme.borderSubtle,
      borderWidth: 1.0,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.heading(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isUrgent ? AppTheme.dangerText : AppTheme.mutedSlate,
                  ),
                ),
              ),
              if (isUrgent)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Urgent',
                    style: AppTheme.heading(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.dangerText,
                    ),
                  ),
                )
              else if (icon != null)
                Icon(
                  icon,
                  size: 16,
                  color: AppTheme.lightSlate,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.heading(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color:
                        valueColor ??
                        (isUrgent ? AppTheme.dangerText : AppTheme.deepSlate),
                  ),
                ),
              ),
              if (badgeText != null && badgeText!.isNotEmpty) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBgColor ?? AppTheme.infoBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badgeText!,
                    style: AppTheme.mono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: badgeColor ?? AppTheme.infoText,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (progressValue != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progressValue!.clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(
                  valueColor ?? AppTheme.royalBlue,
                ),
              ),
            ),
          ],
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.body(
                fontSize: 11.5,
                color: isUrgent ? AppTheme.dangerText : AppTheme.mutedSlate,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
