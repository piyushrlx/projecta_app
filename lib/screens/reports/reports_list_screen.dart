import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/report_model.dart';
import '../../models/user_model.dart';
import '../../services/report_service.dart';
import 'report_submission_screen.dart';

class ReportsListScreen extends StatefulWidget {
  final UserModel user;

  const ReportsListScreen({super.key, required this.user});

  @override
  State<ReportsListScreen> createState() => _ReportsListScreenState();
}

class _ReportsListScreenState extends State<ReportsListScreen> {
  final ReportService _reportService = ReportService();

  bool _isLoading = true;
  String? _errorMessage;
  List<ReportModel> _reports = [];
  String _selectedFilter = 'ALL'; // ALL, PENDING, APPROVED, REJECTED, CLARIFICATION

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? statusQuery;
      if (_selectedFilter == 'PENDING') statusQuery = 'submitted';
      if (_selectedFilter == 'APPROVED') statusQuery = 'approved';
      if (_selectedFilter == 'REJECTED') statusQuery = 'rejected';
      if (_selectedFilter == 'CLARIFICATION') statusQuery = 'clarification_requested';

      final res = await _reportService.getReports(
        status: statusQuery,
        limit: 50,
      );

      if (mounted) {
        setState(() {
          _reports = (res['reports'] as List<ReportModel>?) ?? [];
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
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: AppTheme.pitchBlack, width: 2),
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
                  'REVIEW DAILY REPORT',
                  style: AppTheme.heading(fontSize: 16, color: AppTheme.pitchBlack),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  color: AppTheme.pitchBlack,
                  child: Text(
                    report.hoursFormatted,
                    style: AppTheme.mono(fontSize: 11, color: AppTheme.pureWhite, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${report.employeeName ?? 'Worker'} · ${report.reportDate}',
              style: AppTheme.mono(fontSize: 12, color: const Color(0xFF666666)),
            ),
            const SizedBox(height: 4),
            Text(
              '${report.projectName ?? 'Project'} ${report.taskTitle != null ? '· ${report.taskTitle}' : ''}',
              style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              color: const Color(0xFFF5F5F5),
              child: Text(
                report.workSummary,
                style: AppTheme.body(fontSize: 13),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'REVIEWER FEEDBACK / NOTE (REQUIRED FOR REJECT OR CLARIFY)',
              style: AppTheme.mono(fontSize: 10, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: commentController,
              maxLines: 2,
              style: AppTheme.body(color: AppTheme.pitchBlack),
              decoration: const InputDecoration(
                hintText: 'Enter feedback for employee...',
                border: OutlineInputBorder(borderRadius: BorderRadius.zero),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx, 'approve');
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                    child: const Text('APPROVE'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (commentController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Comment required to request clarification.')),
                        );
                        return;
                      }
                      Navigator.pop(ctx, 'clarify');
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE65100)),
                    child: const Text('CLARIFY'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (commentController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Comment required to reject report.')),
                        );
                        return;
                      }
                      Navigator.pop(ctx, 'reject');
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.violentRed),
                    child: const Text('REJECT'),
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
          SnackBar(
            content: Text('Report review marked as ${result.toUpperCase()}.'),
            backgroundColor: AppTheme.pitchBlack,
          ),
        );
        _loadReports();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('ApiException', '').trim()),
            backgroundColor: AppTheme.violentRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.user.isAdmin;
    final title = isAdmin ? 'DAILY REPORTS INBOX' : 'MY DAILY REPORTS';

    return Scaffold(
      backgroundColor: AppTheme.pitchBlack,
      appBar: AppBar(
        title: Text(title, style: AppTheme.heading(fontSize: 16)),
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
          // Filter Chips
          _buildFilterBar(),

          // Reports List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.violentRed, strokeWidth: 3),
                  )
                : _errorMessage != null
                    ? _buildErrorView()
                    : _reports.isEmpty
                        ? _buildEmptyView()
                        : RefreshIndicator(
                            onRefresh: _loadReports,
                            color: AppTheme.violentRed,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _reports.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 12),
                              itemBuilder: (ctx, idx) => _buildReportCard(_reports[idx]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final filters = ['ALL', 'PENDING', 'APPROVED', 'REJECTED', 'CLARIFICATION'];
    return Container(
      color: AppTheme.pitchBlack,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final isSelected = _selectedFilter == f;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => _onFilterTap(f),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.violentRed : AppTheme.pitchBlack,
                    border: Border.all(
                      color: isSelected ? AppTheme.violentRed : AppTheme.pureWhite,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    f,
                    style: AppTheme.mono(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.pureWhite,
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
    final isAdmin = widget.user.isAdmin;

    return GestureDetector(
      onTap: () async {
        if (isAdmin && report.canReview) {
          _showReviewBottomSheet(report);
        } else if (!isAdmin && (report.isDraft || report.isReturned)) {
          final updated = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => ReportSubmissionScreen(existingReport: report),
            ),
          );
          if (updated == true) _loadReports();
        }
      },
      child: Container(
        decoration: AppTheme.neoCardDecoration(
          backgroundColor: AppTheme.pureWhite,
          borderColor: AppTheme.pitchBlack,
          shadowOffset: 4,
          shadowColor: AppTheme.pureWhite,
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Date, Late badge, Status pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      color: AppTheme.pitchBlack,
                      child: Text(
                        report.reportDate,
                        style: AppTheme.mono(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.pureWhite),
                      ),
                    ),
                    if (report.isLate) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        color: AppTheme.violentRed,
                        child: Text(
                          'LATE',
                          style: AppTheme.mono(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.pureWhite),
                        ),
                      ),
                    ],
                  ],
                ),
                _buildStatusPill(report.status),
              ],
            ),
            const SizedBox(height: 8),

            // Project & Task Info
            Text(
              '${report.projectCode != null ? '${report.projectCode} · ' : ''}${report.projectName ?? 'Project'}',
              style: AppTheme.mono(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF666666)),
            ),
            if (report.taskTitle != null) ...[
              const SizedBox(height: 2),
              Text(
                'TASK: ${report.taskTitle}',
                style: AppTheme.mono(fontSize: 11, color: AppTheme.pitchBlack),
              ),
            ],
            const SizedBox(height: 6),

            // Summary
            Text(
              report.workSummary,
              style: AppTheme.heading(fontSize: 14, color: AppTheme.pitchBlack),
            ),
            const SizedBox(height: 10),

            // Review Comment Banner if rejected / clarified
            if (report.reviewComment != null && report.reviewComment!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(8),
                color: const Color(0xFFFFF3E0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.comment, size: 14, color: Color(0xFFE65100)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Manager feedback: ${report.reviewComment}',
                        style: AppTheme.body(fontSize: 11, color: const Color(0xFFE65100), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Bottom Meta Row: Employee (if admin), Hours, Action hint
            Row(
              children: [
                if (isAdmin && report.employeeName != null) ...[
                  const Icon(Icons.person_outline, size: 14, color: AppTheme.neutralGrey),
                  const SizedBox(width: 4),
                  Text(report.employeeName!, style: AppTheme.mono(fontSize: 11, fontWeight: FontWeight.w700)),
                  const Spacer(),
                ] else
                  const Spacer(),
                const Icon(Icons.access_time, size: 13, color: AppTheme.neutralGrey),
                const SizedBox(width: 4),
                Text(
                  report.hoursFormatted,
                  style: AppTheme.mono(fontSize: 12, fontWeight: FontWeight.w800),
                ),
                if (isAdmin && report.canReview) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    color: AppTheme.violentRed,
                    child: Text(
                      'TAP TO REVIEW',
                      style: AppTheme.mono(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.pureWhite),
                    ),
                  ),
                ] else if (!isAdmin && (report.isDraft || report.isReturned)) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    color: AppTheme.pitchBlack,
                    child: Text(
                      'TAP TO REVISE',
                      style: AppTheme.mono(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.pureWhite),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    Color bg = const Color(0xFFEEEEEE);
    Color fg = AppTheme.pitchBlack;

    if (status == 'approved') {
      bg = const Color(0xFFE8F5E9);
      fg = const Color(0xFF2E7D32);
    } else if (status == 'rejected') {
      bg = const Color(0xFFFFEBEE);
      fg = AppTheme.violentRed;
    } else if (status == 'clarification_requested') {
      bg = const Color(0xFFFFF3E0);
      fg = const Color(0xFFE65100);
    } else if (status == 'submitted') {
      bg = const Color(0xFFE3F2FD);
      fg = const Color(0xFF1565C0);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: AppTheme.pitchBlack, width: 1),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: AppTheme.mono(fontSize: 9, fontWeight: FontWeight.w800, color: fg),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.assignment_outlined, size: 48, color: AppTheme.pureWhite),
          const SizedBox(height: 12),
          Text('NO REPORTS FOUND', style: AppTheme.heading(fontSize: 16)),
          const SizedBox(height: 6),
          Text(
            'No reports matching filter "$_selectedFilter"',
            style: AppTheme.body(fontSize: 13, color: const Color(0xFFAAAAAA)),
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
            color: const Color(0xFF1E1414),
            border: Border.all(color: AppTheme.violentRed, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('FAILED TO LOAD REPORTS', style: AppTheme.mono(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.violentRed)),
              const SizedBox(height: 8),
              Text(_errorMessage ?? 'Unknown error occurred.', style: AppTheme.body(color: AppTheme.pureWhite, fontSize: 13), textAlign: TextAlign.center),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _loadReports,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.violentRed),
                child: const Text('RETRY'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

