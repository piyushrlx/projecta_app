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

  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.isUrgent = false,
    this.valueColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BrutalistPressable(
      onTap: onTap,
      backgroundColor: isUrgent ? const Color(0xFFFEF2F2) : AppTheme.pureWhite,
      borderColor: isUrgent ? const Color(0xFFFECACA) : AppTheme.borderSubtle,
      borderWidth: 1.0,
      borderRadius: BorderRadius.circular(12),
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
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Urgent',
                    style: AppTheme.heading(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.dangerText,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTheme.heading(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color:
                  valueColor ??
                  (isUrgent ? AppTheme.dangerText : AppTheme.deepSlate),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.body(
                fontSize: 12,
                color: isUrgent ? AppTheme.dangerText : AppTheme.mutedSlate,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
