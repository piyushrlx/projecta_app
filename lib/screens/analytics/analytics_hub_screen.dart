import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/widgets/module_app_bar.dart';
import '../../models/user_model.dart';
import '../../services/report_service.dart';

class AnalyticsHubScreen extends StatefulWidget {
  final UserModel? currentUser;
  final ReportService? reportService;

  const AnalyticsHubScreen({super.key, this.currentUser, this.reportService});

  @override
  State<AnalyticsHubScreen> createState() => _AnalyticsHubScreenState();
}

class _AnalyticsHubScreenState extends State<AnalyticsHubScreen> {
  late final ReportService _reportService =
      widget.reportService ?? ReportService();

  late String _activeType;
  int _rangeDays = 30;

  bool _isLoading = true;
  String? _errorMessage;

  Map<String, dynamic> _summary = {};
  List<dynamic> _rows = [];

  final List<Map<String, String>> _allReportTypes = [
    {'type': 'employee', 'label': 'Employee Performance', 'icon': 'person'},
    {'type': 'project', 'label': 'Project Progress', 'icon': 'work'},
    {'type': 'daily', 'label': 'Daily Work Log', 'icon': 'today'},
    {'type': 'pending', 'label': 'Pending Backlog', 'icon': 'pending_actions'},
    {'type': 'delay', 'label': 'Deadlines & Delay', 'icon': 'warning'},
    {'type': 'compliance', 'label': 'Compliance Trends', 'icon': 'verified'},
  ];

  @override
  void initState() {
    super.initState();
    _activeType = 'employee';
    _fetchReportData();
  }

  List<Map<String, String>> get _availableTypes {
    final isStaff = widget.currentUser?.isStaff ?? false;
    if (isStaff) {
      return _allReportTypes
          .where((t) => t['type'] == 'employee' || t['type'] == 'daily')
          .toList();
    }
    return _allReportTypes;
  }

  Future<void> _fetchReportData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final now = DateTime.now();
    final toDate =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final fromDt = now.subtract(Duration(days: _rangeDays - 1));
    final fromDate =
        '${fromDt.year.toString().padLeft(4, '0')}-${fromDt.month.toString().padLeft(2, '0')}-${fromDt.day.toString().padLeft(2, '0')}';

    try {
      final res = await _reportService.getAnalyticsData(
        type: _activeType,
        from: fromDate,
        to: toDate,
      );

      if (mounted) {
        setState(() {
          _summary = (res['summary'] as Map<String, dynamic>?) ?? {};
          _rows = (res['rows'] as List<dynamic>?) ?? [];
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

  void _handleExportCsv() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Exporting ${_rows.length} records for ${_activeType.toUpperCase()} report to CSV...',
        ),
        backgroundColor: AppTheme.successText,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String get _activeTypeLabel {
    for (final item in _allReportTypes) {
      if (item['type'] == _activeType) {
        return item['label'] ?? 'Analytics';
      }
    }
    return 'Analytics';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: ModuleAppBar(
        title: 'Reports & Analytics Hub',
        subtitle: '$_activeTypeLabel · Last $_rangeDays days',
        actions: [
          IconButton(
            icon: const Icon(
              Icons.file_download_outlined,
              color: AppTheme.royalBlue,
            ),
            tooltip: 'Export CSV',
            onPressed: _handleExportCsv,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.deepSlate),
            tooltip: 'Refresh',
            onPressed: _fetchReportData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Dimension Selector Tabs
          _buildDimensionTabs(),

          // Date Range Chips
          _buildRangeSelector(),

          // Main Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.royalBlue),
                  )
                : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: AppTheme.dangerText,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: AppTheme.body(
                              fontSize: 14,
                              color: AppTheme.deepSlate,
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: _fetchReportData,
                            child: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    color: AppTheme.royalBlue,
                    onRefresh: _fetchReportData,
                    child: ListView(
                      padding: const EdgeInsets.all(16.0),
                      children: [
                        // Summary Metrics
                        _buildSummaryCard(),
                        const SizedBox(height: 16),

                        // Data Table / Cards
                        _buildRowsSection(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDimensionTabs() {
    return Container(
      color: AppTheme.pureWhite,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: _availableTypes.map((dim) {
            final isSelected = dim['type'] == _activeType;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(dim['label']!),
                selected: isSelected,
                selectedColor: AppTheme.royalBlue,
                backgroundColor: const Color(0xFFF1F5F9),
                labelStyle: AppTheme.body(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? AppTheme.pureWhite : AppTheme.deepSlate,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isSelected
                        ? AppTheme.royalBlue
                        : AppTheme.borderSubtle,
                  ),
                ),
                onSelected: (val) {
                  if (val && _activeType != dim['type']) {
                    setState(() => _activeType = dim['type']!);
                    _fetchReportData();
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRangeSelector() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.pureWhite,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderSubtle, width: 1.0),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Text(
              'Period:',
              style: AppTheme.body(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.mutedSlate,
              ),
            ),
            const SizedBox(width: 8),
            _buildRangeChip(7, 'Last 7 Days'),
            const SizedBox(width: 6),
            _buildRangeChip(30, 'Last 30 Days'),
            const SizedBox(width: 6),
            _buildRangeChip(90, 'Last 90 Days'),
          ],
        ),
      ),
    );
  }

  Widget _buildRangeChip(int days, String label) {
    final isSelected = _rangeDays == days;
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          setState(() => _rangeDays = days);
          _fetchReportData();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppTheme.royalBlue : AppTheme.borderSubtle,
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: AppTheme.body(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppTheme.royalBlue : AppTheme.deepSlate,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    if (_summary.isEmpty) return const SizedBox.shrink();

    final entries = _summary.entries
        .where((e) => e.key != 'from' && e.key != 'to')
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle),
        boxShadow: const [AppTheme.softShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Summary Overview',
            style: AppTheme.heading(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.deepSlate,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 8.0;
              final cols = constraints.maxWidth < 400
                  ? (entries.length < 2 ? entries.length : 2)
                  : entries.length.clamp(1, 4);
              final itemWidth =
                  (constraints.maxWidth - spacing * (cols - 1)) / cols;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: entries.map((entry) {
                  final label = entry.key.replaceAll('_', ' ').toUpperCase();
                  final val = entry.value.toString();
                  return SizedBox(
                    width: itemWidth,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: Column(
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              val,
                              maxLines: 1,
                              style: AppTheme.heading(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.royalBlue,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            label,
                            textAlign: TextAlign.center,
                            style: AppTheme.mono(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.mutedSlate,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRowsSection() {
    if (_rows.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.inbox_outlined,
                size: 40,
                color: AppTheme.mutedSlate,
              ),
              const SizedBox(height: 8),
              Text(
                'No records found for this period.',
                style: AppTheme.body(fontSize: 13, color: AppTheme.mutedSlate),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
          child: Text(
            'Records (${_rows.length})',
            style: AppTheme.heading(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.deepSlate,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ..._rows.map((row) => _buildRowCard(row)),
      ],
    );
  }

  Widget _buildRowCard(dynamic row) {
    if (row is! Map<String, dynamic>) return const SizedBox.shrink();

    if (_activeType == 'employee') {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.royalBlue,
              child: Text(
                (row['full_name']?.toString().isNotEmpty ?? false)
                    ? row['full_name'].toString()[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  color: AppTheme.pureWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row['full_name']?.toString() ?? '',
                    style: AppTheme.body(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.deepSlate,
                    ),
                  ),
                  Text(
                    '${row['employee_code'] ?? '—'} · ${row['designation'] ?? '—'}',
                    style: AppTheme.body(
                      fontSize: 11,
                      color: AppTheme.mutedSlate,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${row['completed_tasks'] ?? 0} Done',
                  style: AppTheme.mono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.successText,
                  ),
                ),
                Text(
                  '${row['open_tasks'] ?? 0} Open',
                  style: AppTheme.mono(
                    fontSize: 10,
                    color: AppTheme.mutedSlate,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else if (_activeType == 'project') {
      final pct = (row['progress_percent'] as num?)?.toInt() ?? 0;
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    row['name']?.toString() ?? '',
                    style: AppTheme.body(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.deepSlate,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    row['code']?.toString() ?? '',
                    style: AppTheme.mono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.royalBlue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${row['completed_tasks']} / ${row['total_tasks']} tasks',
                  style: AppTheme.body(
                    fontSize: 11,
                    color: AppTheme.mutedSlate,
                  ),
                ),
                Text(
                  '$pct%',
                  style: AppTheme.mono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.deepSlate,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (pct / 100.0).clamp(0.0, 1.0),
                backgroundColor: const Color(0xFFF1F5F9),
                valueColor: AlwaysStoppedAnimation<Color>(
                  pct == 100 ? AppTheme.successText : AppTheme.royalBlue,
                ),
                minHeight: 6,
              ),
            ),
          ],
        ),
      );
    } else if (_activeType == 'delay') {
      final days = row['days_delayed'] ?? 0;
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppTheme.dangerText,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row['title']?.toString() ?? '',
                    style: AppTheme.body(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.deepSlate,
                    ),
                  ),
                  Text(
                    '${row['code']} · ${row['project_name']}',
                    style: AppTheme.body(
                      fontSize: 11,
                      color: AppTheme.mutedSlate,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$days d late',
                style: AppTheme.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.dangerText,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // General fall-through for daily, pending, compliance
      final title =
          row['title'] ?? row['full_name'] ?? row['employee_name'] ?? 'Record';
      final subtitle =
          row['project_name'] ?? row['summary'] ?? row['department'] ?? '';
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toString(),
                    style: AppTheme.body(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.deepSlate,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle.toString().isNotEmpty)
                    Text(
                      subtitle.toString(),
                      style: AppTheme.body(
                        fontSize: 11,
                        color: AppTheme.mutedSlate,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (row['deadline'] != null || row['report_date'] != null)
              Text(
                (row['deadline'] ?? row['report_date']).toString(),
                style: AppTheme.mono(fontSize: 10, color: AppTheme.mutedSlate),
              ),
          ],
        ),
      );
    }
  }
}
