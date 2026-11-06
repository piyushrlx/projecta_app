import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class TaskStatusPill extends StatelessWidget {
  final String status;
  final VoidCallback? onTap;
  final bool isInteractive;

  const TaskStatusPill({
    super.key,
    required this.status,
    this.onTap,
    this.isInteractive = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg = const Color(0xFFF1F5F9);
    Color fg = AppTheme.mutedSlate;

    if (status == 'completed') {
      bg = AppTheme.successBg;
      fg = AppTheme.successText;
    } else if (status == 'blocked') {
      bg = AppTheme.dangerBg;
      fg = AppTheme.dangerText;
    } else if (status == 'in_progress') {
      bg = AppTheme.infoBg;
      fg = AppTheme.infoText;
    } else if (status == 'pending_review') {
      bg = AppTheme.warningBg;
      fg = AppTheme.warningText;
    }

    final formatted = status.replaceAll('_', ' ');
    final label = formatted.isEmpty
        ? 'Pending'
        : formatted[0].toUpperCase() + formatted.substring(1).toLowerCase();

    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: isInteractive
            ? Border.all(color: fg.withValues(alpha: 0.3), width: 0.8)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTheme.heading(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
          if (isInteractive) ...[
            const SizedBox(width: 3),
            Icon(Icons.swap_vert, size: 12, color: fg),
          ],
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: pill,
      );
    }

    return pill;
  }
}

