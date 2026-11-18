import 'package:flutter/material.dart';
import '../api_client.dart';
import '../async_server_discovery.dart';
import '../theme.dart';

/// Shows an interactive dialog allowing developers or testers to configure
/// the backend API base URL at runtime without needing to recompile the app.
Future<void> showServerConfigDialog({
  required BuildContext context,
  VoidCallback? onSaved,
}) async {
  final apiClient = ApiClient();
  final controller = TextEditingController(text: apiClient.baseUrl);

  String? testStatus;
  bool isTesting = false;
  bool isAutoDetecting = false;

  return showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) {
        Future<void> runTest(String url) async {
          setState(() {
            isTesting = true;
            testStatus = null;
          });
          final latency = await AsyncServerDiscovery.getEndpointLatency(url);
          if (context.mounted) {
            setState(() {
              isTesting = false;
              if (latency != null) {
                testStatus = 'Connected (${latency}ms) — 200 OK';
              } else {
                testStatus = 'Connection failed (Timeout / Unreachable)';
              }
            });
          }
        }

        Future<void> runAutoDetect() async {
          setState(() {
            isAutoDetecting = true;
            testStatus = null;
          });
          final fastest = await AsyncServerDiscovery.probeAndSelectFastest();
          if (context.mounted) {
            setState(() {
              isAutoDetecting = false;
              if (fastest != null && fastest.isNotEmpty) {
                controller.text = fastest;
                testStatus = 'Auto-detected live server: $fastest';
              } else {
                testStatus = 'No live server responded on standard endpoints';
              }
            });
          }
        }

        return AlertDialog(
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
              Expanded(
                child: Text(
                  'Server Configuration',
                  style: AppTheme.heading(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.deepSlate,
                  ),
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
                  'Backend API base endpoint URL:',
                  style: AppTheme.body(fontSize: 13, color: AppTheme.mutedSlate),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: controller,
                  style: AppTheme.mono(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'http://${ApiClient.defaultLanIp}/projecta/api/v1',
                    prefixIcon: const Icon(Icons.link, size: 18),
                    suffixIcon: IconButton(
                      icon: isTesting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.speed, size: 18),
                      tooltip: 'Test Connection',
                      onPressed: isTesting
                          ? null
                          : () => runTest(controller.text.trim()),
                    ),
                  ),
                ),
                if (testStatus != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: testStatus!.contains('Connected') ||
                              testStatus!.contains('Auto-detected')
                          ? const Color(0xFFDCFCE7) // Emerald 100
                          : const Color(0xFFFEE2E2), // Rose 100
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      testStatus!,
                      style: AppTheme.body(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: testStatus!.contains('Connected') ||
                                testStatus!.contains('Auto-detected')
                            ? const Color(0xFF166534) // Emerald 800
                            : const Color(0xFF991B1B), // Rose 800
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Quick Presets',
                      style: AppTheme.heading(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.deepSlate,
                      ),
                    ),
                    InkWell(
                      onTap: isAutoDetecting ? null : runAutoDetect,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isAutoDetecting)
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            else
                              const Icon(
                                Icons.auto_mode,
                                size: 14,
                                color: AppTheme.navyBlue,
                              ),
                            const SizedBox(width: 4),
                            Text(
                              'Auto-Detect',
                              style: AppTheme.heading(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.navyBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _presetChip(
                      'Live Production (projeqta.com)',
                      ApiClient.liveProductionUrl,
                      controller,
                      onTap: () => runTest(ApiClient.liveProductionUrl),
                    ),
                    _presetChip(
                      'USB ADB (localhost:8080)',
                      'http://localhost:8080/projecta/api/v1',
                      controller,
                      onTap: () => runTest('http://localhost:8080/projecta/api/v1'),
                    ),
                    _presetChip(
                      'Wi-Fi LAN (${ApiClient.defaultLanIp})',
                      'http://${ApiClient.defaultLanIp}/projecta/api/v1',
                      controller,
                      onTap: () => runTest(
                          'http://${ApiClient.defaultLanIp}/projecta/api/v1'),
                    ),
                    _presetChip(
                      'Wi-Fi IPv6 (Dual-Stack)',
                      AsyncServerDiscovery.ipv6Candidate,
                      controller,
                      onTap: () =>
                          runTest(AsyncServerDiscovery.ipv6Candidate),
                    ),
                    _presetChip(
                      'Android Emulator (10.0.2.2)',
                      'http://10.0.2.2/projecta/api/v1',
                      controller,
                      onTap: () =>
                          runTest('http://10.0.2.2/projecta/api/v1'),
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
                          'Tip: Over USB cable, ensure "adb reverse tcp:8080 tcp:80" is running. Over Wi-Fi, ensure your phone & PC share the same router.',
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
        );
      },
    ),
  );
}

Widget _presetChip(
  String label,
  String url,
  TextEditingController controller, {
  VoidCallback? onTap,
}) {
  return InkWell(
    onTap: () {
      controller.text = url;
      if (onTap != null) onTap();
    },
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
