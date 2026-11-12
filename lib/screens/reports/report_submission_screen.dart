import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../models/report_model.dart';
import '../../services/report_service.dart';

class ReportSubmissionScreen extends StatefulWidget {
  final ReportModel? existingReport;

  const ReportSubmissionScreen({super.key, this.existingReport});

  @override
  State<ReportSubmissionScreen> createState() => _ReportSubmissionScreenState();
}

class _ReportSubmissionScreenState extends State<ReportSubmissionScreen> {
  final ReportService _reportService = ReportService();

  final _formKey = GlobalKey<FormState>();
  final _summaryController = TextEditingController();
  final _completedController = TextEditingController();
  final _pendingController = TextEditingController();
  final _blockersController = TextEditingController();
  final _nextPlanController = TextEditingController();
  final _minutesController = TextEditingController(text: '60');

  bool _isLoadingContext = true;
  bool _isSubmitting = false;
  String? _contextError;
  TodayReportContextModel? _todayContext;

  int? _selectedProjectId;
  int? _selectedTaskId;
  int _totalMinutes = 60;
  double _progressAfter = 50;

  @override
  void initState() {
    super.initState();
    if (widget.existingReport != null) {
      final r = widget.existingReport!;
      _selectedProjectId = r.projectId;
      _selectedTaskId = r.taskId;
      _summaryController.text = r.workSummary;
      _totalMinutes = r.minutesSpent > 0 ? r.minutesSpent : 60;
      _minutesController.text = _totalMinutes.toString();
      _progressAfter = (r.progressAfter ?? 50).toDouble();
    }
    _loadTodayContext();
  }

  Future<void> _loadTodayContext() async {
    setState(() {
      _isLoadingContext = true;
      _contextError = null;
    });

    try {
      final ctx = await _reportService.getTodayContext();
      if (mounted) {
        setState(() {
          _todayContext = ctx;
          if (_selectedProjectId == null && ctx.projects.isNotEmpty) {
            _selectedProjectId = (ctx.projects.first['id'] as num?)?.toInt();
          }
          if (_selectedTaskId == null && ctx.tasks.isNotEmpty) {
            final matching = ctx.tasks
                .where(
                  (t) =>
                      (t['project_id'] as num?)?.toInt() == _selectedProjectId,
                )
                .toList();
            if (matching.isNotEmpty) {
              _selectedTaskId = (matching.first['id'] as num?)?.toInt();
              _progressAfter =
                  ((matching.first['progress'] as num?)?.toDouble() ?? 50)
                      .clamp(0.0, 100.0);
            }
          }
          _isLoadingContext = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _contextError = e.toString().replaceAll('ApiException', '').trim();
          _isLoadingContext = false;
        });
      }
    }
  }

  void _setTimeChip(int minutes) {
    HapticFeedback.lightImpact();
    setState(() {
      _totalMinutes = minutes;
      _minutesController.text = minutes.toString();
    });
  }

  Future<void> _handleSubmit(String action) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProjectId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a project.')));
      return;
    }

    final hours = _totalMinutes ~/ 60;
    final mins = _totalMinutes % 60;

    if (action == 'submit' && _totalMinutes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log the time spent on this work.'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final payload = <String, dynamic>{
        'action': action,
        if (widget.existingReport != null) 'id': widget.existingReport!.id,
        'report_date':
            _todayContext?.today ?? DateTime.now().toString().substring(0, 10),
        'project_id': _selectedProjectId,
        if (_selectedTaskId != null) 'task_id': _selectedTaskId,
        'work_summary': _summaryController.text.trim(),
        'work_completed': _completedController.text.trim().isNotEmpty
            ? _completedController.text.trim()
            : _summaryController.text.trim(),
        'hours': hours,
        'minutes': mins,
        'progress_after': _progressAfter.round(),
        if (_pendingController.text.trim().isNotEmpty)
          'work_pending': _pendingController.text.trim(),
        if (_blockersController.text.trim().isNotEmpty)
          'blockers': _blockersController.text.trim(),
        if (_nextPlanController.text.trim().isNotEmpty)
          'next_plan': _nextPlanController.text.trim(),
      };

      await _reportService.submitReport(payload);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            action == 'draft'
                ? 'Report draft saved.'
                : 'Daily report submitted successfully!',
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('ApiException', '').trim()),
          backgroundColor: AppTheme.dangerText,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: Text(
          widget.existingReport != null
              ? 'Edit Daily Report'
              : 'Submit Daily Report',
          style: AppTheme.heading(fontSize: 18),
        ),
      ),
      body: _isLoadingContext
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.royalBlue,
                strokeWidth: 2.5,
              ),
            )
          : _contextError != null
          ? _buildErrorView()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.pureWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.borderSubtle,
                      width: 1.0,
                    ),
                    boxShadow: const [AppTheme.softShadow],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Notice if currently late
                      if (_todayContext?.isCurrentlyLate == true) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.dangerBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.dangerText.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.timer_off_outlined,
                                color: AppTheme.dangerText,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Reporting deadline passed (${_todayContext?.reportDeadlineTime ?? '7:00 PM'}). Submission will be flagged late.',
                                  style: AppTheme.body(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.dangerText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // 1. Project Selector
                      Text(
                        'Project *',
                        style: AppTheme.heading(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.deepSlate,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        initialValue: _selectedProjectId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                        items: (_todayContext?.projects ?? []).map((p) {
                          final id = (p['id'] as num).toInt();
                          final name = p['name']?.toString() ?? '';
                          final code = p['project_code']?.toString() ?? '';
                          return DropdownMenuItem<int>(
                            value: id,
                            child: Text(
                              '$code · $name',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.body(
                                fontSize: 13,
                                color: AppTheme.deepSlate,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedProjectId = val;
                            _selectedTaskId = null;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // 2. Task Selector
                      Text(
                        'Assigned Task (Optional)',
                        style: AppTheme.heading(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.deepSlate,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int?>(
                        initialValue: _selectedTaskId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text(
                              'General Project Work (No specific task)',
                            ),
                          ),
                          ...((_todayContext?.tasks ?? [])
                              .where(
                                (t) =>
                                    _selectedProjectId == null ||
                                    (t['project_id'] as num?)?.toInt() ==
                                        _selectedProjectId,
                              )
                              .map((t) {
                                final id = (t['id'] as num).toInt();
                                final code = t['task_code']?.toString() ?? '';
                                final title = t['title']?.toString() ?? '';
                                return DropdownMenuItem<int?>(
                                  value: id,
                                  child: Text(
                                    '$code · $title',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTheme.body(
                                      fontSize: 13,
                                      color: AppTheme.deepSlate,
                                    ),
                                  ),
                                );
                              })),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedTaskId = val;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // 3. Time Spent
                      Text(
                        'Time Spent (Minutes) *',
                        style: AppTheme.heading(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.deepSlate,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildTimeChip('15m', 15),
                          const SizedBox(width: 6),
                          _buildTimeChip('30m', 30),
                          const SizedBox(width: 6),
                          _buildTimeChip('1h', 60),
                          const SizedBox(width: 6),
                          _buildTimeChip('2h', 120),
                          const SizedBox(width: 6),
                          _buildTimeChip('4h', 240),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _minutesController,
                              keyboardType: TextInputType.number,
                              style: AppTheme.mono(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Total Minutes',
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                              ),
                              onChanged: (v) {
                                final val = int.tryParse(v);
                                if (val != null) {
                                  setState(() {
                                    _totalMinutes = val;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.scaffoldBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.borderSubtle),
                            ),
                            child: Text(
                              '${_totalMinutes ~/ 60}h ${_totalMinutes % 60}m',
                              style: AppTheme.mono(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.deepSlate,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 4. Progress Slider
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Task Progress After Today',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.heading(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.deepSlate,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_progressAfter.round()}%',
                            style: AppTheme.mono(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.deepSlate,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _progressAfter,
                        min: 0,
                        max: 100,
                        divisions: 20,
                        activeColor: AppTheme.royalBlue,
                        inactiveColor: const Color(0xFFE2E8F0),
                        onChanged: (val) {
                          setState(() {
                            _progressAfter = val;
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      // 5. Work Summary
                      Text(
                        'Work Summary *',
                        style: AppTheme.heading(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.deepSlate,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _summaryController,
                        style: AppTheme.body(color: AppTheme.deepSlate),
                        decoration: const InputDecoration(
                          hintText:
                              'High-level headline of today’s accomplishments...',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Summary is required.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 6. Work Completed Description
                      Text(
                        'Detailed Work Completed *',
                        style: AppTheme.heading(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.deepSlate,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _completedController,
                        maxLines: 3,
                        style: AppTheme.body(color: AppTheme.deepSlate),
                        decoration: const InputDecoration(
                          hintText:
                              'Specific deliverables, commits, tests or tasks finished...',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Completed work description is required.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 7. Work Pending / Next Plan
                      Text(
                        'Work Pending & Next Plan',
                        style: AppTheme.heading(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.deepSlate,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nextPlanController,
                        maxLines: 2,
                        style: AppTheme.body(color: AppTheme.deepSlate),
                        decoration: const InputDecoration(
                          hintText: 'What is scheduled for tomorrow...',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 8. Blockers (Optional)
                      Text(
                        'Blockers & Obstacles (Optional)',
                        style: AppTheme.heading(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.warningText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _blockersController,
                        maxLines: 2,
                        style: AppTheme.body(color: AppTheme.deepSlate),
                        decoration: const InputDecoration(
                          hintText:
                              'Any impediments requiring manager intervention...',
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: OutlinedButton(
                                onPressed: _isSubmitting
                                    ? null
                                    : () => _handleSubmit('draft'),
                                child: const Text('Save Draft'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _isSubmitting
                                    ? null
                                    : () => _handleSubmit('submit'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.navyBlue,
                                  foregroundColor: AppTheme.pureWhite,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: AppTheme.pureWhite,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Submit Report'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildTimeChip(String label, int minutes) {
    final isSelected = _totalMinutes == minutes;
    return Expanded(
      child: InkWell(
        onTap: () => _setTimeChip(minutes),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.navyBlue : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppTheme.navyBlue : AppTheme.borderSubtle,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTheme.heading(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppTheme.pureWhite : AppTheme.mutedSlate,
              ),
            ),
          ),
        ),
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
                'Failed to load reporting context',
                style: AppTheme.heading(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.dangerText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _contextError ?? 'Unknown error occurred.',
                style: AppTheme.body(color: AppTheme.deepSlate, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _loadTodayContext,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
