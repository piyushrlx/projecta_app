import 'package:flutter/material.dart';
import '../api_client.dart';
import '../theme.dart';

/// Shows an interactive dialog allowing developers or testers to configure
/// the backend API base URL at runtime without needing to recompile the app.
Future<void> showServerConfigDialog({
  required BuildContext context,
  VoidCallback? onSaved,
}) async {
  final apiClient = ApiClient();
  final controller = TextEditingController(text: apiClient.baseUrl);

  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.pureWhite,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.borderSubtle, width: 1.0),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.infoBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.dns_outlined,
              color: AppTheme.navyBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Server Configuration',
            style: AppTheme.heading(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.deepSlate,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the backend API base endpoint URL (e.g. when your PC IP changes):',
              style: AppTheme.body(fontSize: 13, color: AppTheme.mutedSlate),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: AppTheme.mono(fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'http://192.168.1.4/projecta/api/v1',
                prefixIcon: Icon(Icons.link, size: 18),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Quick Presets',
              style: AppTheme.heading(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.deepSlate,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _presetChip(
                  'USB ADB (localhost:8080)',
                  'http://localhost:8080/projecta/api/v1',
                  controller,
                ),
                _presetChip(
                  'Wi-Fi (192.168.1.4)',
                  'http://192.168.1.4/projecta/api/v1',
                  controller,
                ),
                _presetChip(
                  'Android Emulator (10.0.2.2)',
                  'http://10.0.2.2/projecta/api/v1',
                  controller,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppTheme.mutedSlate,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Ensure your phone & PC are on the same Wi-Fi, or run "adb reverse tcp:8080 tcp:80" over USB.',
                      style: AppTheme.body(
                        fontSize: 11,
                        color: AppTheme.mutedSlate,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(
            'Cancel',
            style: AppTheme.heading(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.mutedSlate,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            final newUrl = controller.text.trim();
            if (newUrl.isNotEmpty) {
              await apiClient.setBaseUrl(newUrl);
            }
            if (!ctx.mounted) return;
            Navigator.pop(ctx);
            if (onSaved != null) {
              onSaved();
            }
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Server URL set to: ${apiClient.baseUrl}'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          child: const Text('Save & Apply'),
        ),
      ],
    ),
  );
}

Widget _presetChip(String label, String url, TextEditingController controller) {
  return InkWell(
    onTap: () => controller.text = url,
    borderRadius: BorderRadius.circular(6),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.scaffoldBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Text(
        label,
        style: AppTheme.body(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppTheme.deepSlate,
        ),
      ),
    ),
  );
}
