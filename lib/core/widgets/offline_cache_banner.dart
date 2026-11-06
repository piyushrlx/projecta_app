import 'package:flutter/material.dart';
import '../theme.dart';

class OfflineCacheBanner extends StatelessWidget {
  final VoidCallback? onRetry;

  const OfflineCacheBanner({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFFEF3C7), // Amber 100
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFFDE68A), // Amber 200
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 16,
            color: Color(0xFF92400E), // Amber 800
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Viewing offline cached data. Actions are read-only.',
              style: AppTheme.heading(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF92400E),
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: onRetry,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text(
                  'Retry',
                  style: AppTheme.heading(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFB45309),
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

