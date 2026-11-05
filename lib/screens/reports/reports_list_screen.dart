import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/widgets/brutalist_pressable.dart';
import '../../models/report_model.dart';
import '../../models/user_model.dart';
import '../../services/report_service.dart';
import 'report_submission_screen.dart';

class ReportsListScreen extends StatefulWidget {
  final UserModel user;
  final String? initialFilter;

  const ReportsListScreen({
    super.key,
    required this.user,
    this.initialFilter,
  });

  @override
  State<ReportsListScreen> createState() => _ReportsListScreenState();
}

class _ReportsListScreenState extends State<ReportsListScreen> {
  final ReportService _reportService = ReportService();

  bool _isLoading = true;
  String? _errorMessage;
  List<ReportModel> _reports = [];
  late String _selectedFilter;

  @override
  void initState() {
    super.initState();
    if (widget.initialFilter != null) {
      final f = widget.initialFilter!.trim().toLowerCase();
      if (f == 'pending_review' || f == 'pending review' || f == 'pending') {
        _selectedFilter = 'Pending Review';
      } else if (f == 'approved') {
        _selectedFilter = 'Approved';
      } else if (f == 'late') {
        _selectedFilter = 'Late';
      } else if (f == 'returned' || f == 'rejected') {
        _selectedFilter = 'Returned / Rejected';
      } else {
        _selectedFilter = widget.initialFilter!;
      }
    } else {
      _selectedFilter = 'All';
    }
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? statusQuery;
      bool? isLate;

      final upper = _selectedFilter.toUpperCase();
      if (upper == 'PENDING REVIEW') statusQuery = 'submitted';
      if (upper == 'APPROVED') statusQuery = 'approved';
      if (upper == 'RETURNED / REJECTED') statusQuery = 'rejected';
      if (upper == 'LATE') isLate = true;

      final res = await _reportService.getReports(
        status: statusQuery,
        limit: 50,
      );

      var list = (res['reports'] as List<ReportModel>?) ?? [];
      if (upper == 'LATE' && isLate == true) {
        list = list.where((r) => r.isLate).toList();
      }

      if (mounted) {
        setState(() {
          _reports = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('ApiException', '').trim();
          _isLoading = false;
        });
      }
    }
  }

  void _onFilterTap(String f) {
    if (_selectedFilter == f) return;
    setState(() {
      _selectedFilter = f;
    });
    _loadReports();
  }

  Future<void> _showReviewBottomSheet(ReportModel report) async {
    final commentController = TextEditingController();

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Review Daily Report',
                  style: AppTheme.heading(
                    fontSize: 17,
                    color: AppTheme.deepSlate,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.scaffoldBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Text(
                    report.hoursFormatted,
                    style: AppTheme.mono(
                      fontSize: 11,
                      color: AppTheme.deepSlate,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${report.employeeName ?? 'Worker'} Â· ${report.reportDate}',
              style: AppTheme.body(fontSize: 12, color: AppTheme.mutedSlate),
            ),
            const SizedBox(height: 4),
            Text(
              '${report.projectName ?? 'Project'} ${report.taskTitle != null ? 'Â· ${report.taskTitle}' : ''}',
              style: AppTheme.heading(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.deepSlate,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.scaffoldBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Text(
                report.workSummary,
                style: AppTheme.body(fontSize: 13, color: AppTheme.deepSlate),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Reviewer Feedback (required for Reject / Clarify)',
              style: AppTheme.heading(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.deepSlate,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: commentController,
              maxLines: 2,
              style: AppTheme.body(color: AppTheme.deepSlate),
              decoration: const InputDecoration(
                hintText: 'Enter feedback for employee...',
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, 'approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successText,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Approve'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (commentController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Comment required to request clarification.',
                            ),
                          ),
                        );
                        return;
                      }
                      Navigator.pop(ctx, 'clarify');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.warningText,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Clarify'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      if (commentController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Comment required to reject report.'),
                          ),
                        );
                        return;
                      }
                      Navigator.pop(ctx, 'reject');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.dangerText,
                      side: const BorderSide(color: AppTheme.dangerText),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      try {
        await _reportService.reviewReport(
          report.id,
          decision: result,
          comment: commentController.text.trim(),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report marked as ${result.toUpperCase()}.')),
        );
        _loadReports();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('ApiException', '').trim()),
            backgroundColor: AppTheme.dangerText,
          ),
        );
      }
    }
  }

  void _onReportTapped(ReportModel report) async {
    if (widget.user.isAdmin) {
      if (report.status == 'submitted' || report.status == 'submitted_late') {
        _showReviewBottomSheet(report);
      }
    } else {
      if (report.isRejected || report.isClarificationRequested) {
        final res = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => ReportSubmissionScreen(existingReport: report),
          ),
        );
        if (res == true) _loadReports();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.user.isAdmin;
    final title = isAdmin ? 'Daily Reports Inbox' : 'My Daily Reports';

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: Text(title, style: AppTheme.heading(fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadReports,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips Bar
          _buildFilterChips(),

          // Reports List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.royalBlue,
                      strokeWidth: 2.5,
                    ),
                  )
                : _errorMessage != null
                ? _buildErrorView()
                : _reports.isEmpty
                ? _buildEmptyView()
                : RefreshIndicator(
                    onRefresh: _loadReports,
                    color: AppTheme.royalBlue,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _reports.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (ctx, idx) =>
                          _buildReportCard(_reports[idx]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      'All',
      'Pending Review',
      'Approved',
      'Returned / Rejected',
      'Late',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppTheme.pureWhite,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderSubtle, width: 1.0),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final isSelected = _selectedFilter.toUpperCase() == f.toUpperCase();
            final isAlert =
                f.toUpperCase() == 'LATE' ||
                f.toUpperCase().contains('REJECTED');

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => _onFilterTap(f),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isAlert ? AppTheme.dangerBg : AppTheme.navyBlue)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? (isAlert
                                ? const Color(0xFFFECACA)
                                : AppTheme.navyBlue)
                          : AppTheme.borderSubtle,
                    ),
                  ),
                  child: Text(
                    f,
                    style: AppTheme.heading(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? (isAlert ? AppTheme.dangerText : AppTheme.pureWhite)
                          : AppTheme.mutedSlate,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildReportCard(ReportModel report) {
    return BrutalistPressable(
      onTap: () => _onReportTapped(report),
      backgroundColor: AppTheme.pureWhite,
      borderColor: report.isLate
          ? const Color(0xFFFECACA)
          : AppTheme.borderSubtle,
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Date + Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.scaffoldBg,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: Text(
                      report.reportDate,
                      style: AppTheme.mono(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.deepSlate,
                      ),
                    ),
                  ),
                  if (report.isLate) ...[
                    const SizedBox(width: 6),
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
                        'Late',
                        style: AppTheme.heading(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.dangerText,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              _buildStatusPill(report.status),
            ],
          ),
          const SizedBox(height: 10),

          // Employee name & project
          if (widget.user.isAdmin && report.employeeName != null) ...[
            Text(
              report.employeeName!,
              style: AppTheme.heading(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.deepSlate,
              ),
            ),
            const SizedBox(height: 2),
          ],
          Text(
            report.projectName ?? 'General Project',
            style: AppTheme.body(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.mutedSlate,
            ),
          ),
          const SizedBox(height: 8),

          // Summary text
          Text(
            report.workSummary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.body(fontSize: 13, color: AppTheme.deepSlate),
          ),
          const SizedBox(height: 12),

          // Footer meta: Hours + Progress After + Review button
          Row(
            children: [
              const Icon(
                Icons.access_time_outlined,
                size: 14,
                color: AppTheme.mutedSlate,
              ),
              const SizedBox(width: 4),
              Text(
                report.hoursFormatted,
                style: AppTheme.mono(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.mutedSlate,
                ),
              ),
              if (report.progressAfter != null) ...[
                const SizedBox(width: 10),
                Text('Â·', style: TextStyle(color: AppTheme.mutedSlate)),
                const SizedBox(width: 10),
                Text(
                  'Progress: ${report.progressAfter}%',
                  style: AppTheme.body(
                    fontSize: 11,
                    color: AppTheme.mutedSlate,
                  ),
                ),
              ],
              const Spacer(),
              if (widget.user.isAdmin &&
                  (report.status == 'submitted' ||
                      report.status == 'submitted_late'))
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.infoBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Review',
                    style: AppTheme.heading(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.infoText,
                    ),
                  ),
                )
              else if (!widget.user.isAdmin &&
                  (report.isRejected || report.isClarificationRequested))
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.warningBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Revise',
                    style: AppTheme.heading(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.warningText,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    Color bg = const Color(0xFFF1F5F9);
    Color fg = AppTheme.mutedSlate;

    if (status == 'approved') {
      bg = AppTheme.successBg;
      fg = AppTheme.successText;
    } else if (status == 'rejected') {
      bg = AppTheme.dangerBg;
      fg = AppTheme.dangerText;
    } else if (status.contains('clarification')) {
      bg = AppTheme.warningBg;
      fg = AppTheme.warningText;
    } else if (status.contains('submitted')) {
      bg = AppTheme.infoBg;
      fg = AppTheme.infoText;
    }

    final formatted = status.replaceAll('_', ' ');
    final label = formatted.isEmpty
        ? 'Pending'
        : formatted[0].toUpperCase() + formatted.substring(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: AppTheme.heading(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.assignment_outlined,
            size: 48,
            color: AppTheme.mutedSlate,
          ),
          const SizedBox(height: 12),
          Text('No Reports Found', style: AppTheme.heading(fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            'No reports matching filter "$_selectedFilter"',
            style: AppTheme.body(fontSize: 13, color: AppTheme.mutedSlate),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.dangerBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.dangerText.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Failed to load reports',
                style: AppTheme.heading(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.dangerText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Unknown error occurred.',
                style: AppTheme.body(color: AppTheme.deepSlate, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _loadReports,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
