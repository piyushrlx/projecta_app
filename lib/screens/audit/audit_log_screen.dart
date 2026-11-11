import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/user_model.dart';
import '../../services/dashboard_service.dart';

class AuditLogScreen extends StatefulWidget {
  final UserModel? currentUser;
  final DashboardService? dashboardService;

  const AuditLogScreen({
    super.key,
    this.currentUser,
    this.dashboardService,
  });

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  late final DashboardService _service = widget.dashboardService ?? DashboardService();

  bool _isLoading = true;
  String? _errorMessage;

  List<dynamic> _logs = [];
  String _filterAction = '';

  @override
  void initState() {
    super.initState();
    _fetchAuditLogs();
  }

  Future<void> _fetchAuditLogs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final logs = await _service.getAuditLogs(
        action: _filterAction.isNotEmpty ? _filterAction : null,
      );

      if (mounted) {
        setState(() {
          _logs = logs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('ApiException:', '').trim();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: const BoxDecoration(
            color: AppTheme.pureWhite,
            border: Border(
              bottom: BorderSide(color: AppTheme.borderSubtle, width: 1.0),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppTheme.deepSlate),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Audit Log Viewer',
                      style: AppTheme.heading(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.deepSlate,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: AppTheme.royalBlue),
                    onPressed: _fetchAuditLogs,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            color: AppTheme.pureWhite,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Filter by action (e.g. user, task)...',
                      prefixIcon: const Icon(Icons.filter_list, size: 20),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (val) {
                      _filterAction = val.trim();
                    },
                    onSubmitted: (_) => _fetchAuditLogs(),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _fetchAuditLogs,
                  style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                  child: const Text('Apply'),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderSubtle),

          // Main Log Stream
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.royalBlue))
                : _errorMessage != null
                    ? Center(
                        child: Text(
                          _errorMessage!,
                          style: AppTheme.body(fontSize: 14, color: AppTheme.dangerText),
                        ),
                      )
                    : _logs.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.history_toggle_off, size: 48, color: AppTheme.mutedSlate),
                                const SizedBox(height: 12),
                                Text(
                                  'No audit records found.',
                                  style: AppTheme.body(fontSize: 14, color: AppTheme.mutedSlate),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            color: AppTheme.royalBlue,
                            onRefresh: _fetchAuditLogs,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16.0),
                              itemCount: _logs.length,
                              itemBuilder: (context, idx) => _AuditLogCard(log: _logs[idx] as Map<String, dynamic>),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _AuditLogCard extends StatefulWidget {
  final Map<String, dynamic> log;

  const _AuditLogCard({required this.log});

  @override
  State<_AuditLogCard> createState() => _AuditLogCardState();
}

class _AuditLogCardState extends State<_AuditLogCard> {
  bool _isExpanded = false;

  String _formatDiffJson(dynamic raw) {
    if (raw == null) return 'None';
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        return const JsonEncoder.withIndent('  ').convert(decoded);
      } catch (_) {
        return raw;
      }
    }
    try {
      return const JsonEncoder.withIndent('  ').convert(raw);
    } catch (_) {
      return raw.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final log = widget.log;
    final actor = log['actor_name']?.toString() ?? 'System';
    final action = log['action']?.toString() ?? 'action';
    final entityType = log['entity_type']?.toString() ?? 'entity';
    final entityId = log['entity_id']?.toString() ?? '0';
    final createdAt = log['created_at']?.toString() ?? '';
    final ip = log['ip_address']?.toString() ?? '127.0.0.1';

    final hasOld = log['old_values'] != null && log['old_values'].toString().trim().isNotEmpty;
    final hasNew = log['new_values'] != null && log['new_values'].toString().trim().isNotEmpty;
    final hasDiff = hasOld || hasNew;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle),
        boxShadow: const [AppTheme.softShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: AppTheme.royalBlue,
                            child: Text(
                              actor.isNotEmpty ? actor[0].toUpperCase() : 'U',
                              style: const TextStyle(fontSize: 10, color: AppTheme.pureWhite, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              actor,
                              style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.deepSlate),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      createdAt,
                      style: AppTheme.mono(fontSize: 10, color: AppTheme.mutedSlate),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        action,
                        style: AppTheme.mono(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.royalBlue),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$entityType #$entityId',
                        style: AppTheme.body(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.deepSlate),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      child: Text(
                        'IP: $ip',
                        style: AppTheme.mono(fontSize: 10, color: AppTheme.mutedSlate),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (hasDiff) ...[
            const Divider(height: 1, color: AppTheme.borderSubtle),
            InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Inspect State Diff',
                      style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.royalBlue),
                    ),
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: AppTheme.royalBlue,
                    ),
                  ],
                ),
              ),
            ),
            if (_isExpanded)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: const Color(0xFFF8FAFC),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasOld) ...[
                      Text('Before:', style: AppTheme.mono(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.dangerText)),
                      const SizedBox(height: 2),
                      SelectableText(
                        _formatDiffJson(log['old_values']),
                        style: AppTheme.mono(fontSize: 10, color: AppTheme.deepSlate),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (hasNew) ...[
                      Text('After:', style: AppTheme.mono(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.successText)),
                      const SizedBox(height: 2),
                      SelectableText(
                        _formatDiffJson(log['new_values']),
                        style: AppTheme.mono(fontSize: 10, color: AppTheme.deepSlate),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
