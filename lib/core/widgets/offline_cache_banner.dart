import 'package:flutter/material.dart';
import '../theme.dart';

class OfflineCacheBanner extends StatelessWidget {
  final VoidCallback? onRetry;
  final VoidCallback? onServerConfig;

  const OfflineCacheBanner({
    super.key,
    this.onRetry,
    this.onServerConfig,
  });

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
            child: InkWell(
              onTap: onServerConfig,
              borderRadius: BorderRadius.circular(4),
              child: Text(
                'Viewing offline cached data. Actions are read-only.',
                style: AppTheme.heading(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF92400E),
                ),
              ),
            ),
          ),
          if (onServerConfig != null) ...[
            const SizedBox(width: 6),
            InkWell(
              onTap: onServerConfig,
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE68A), // Amber 200
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.settings_ethernet,
                      size: 11,
                      color: Color(0xFF92400E),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'Server',
                      style: AppTheme.heading(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
