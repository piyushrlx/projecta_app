import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/widgets/brutalist_pressable.dart';
import '../../models/report_model.dart';
import '../../models/user_model.dart';
import '../../services/report_service.dart';

class ComplianceMatrixView extends StatefulWidget {
  final UserModel user;
  final String? initialDate;

  const ComplianceMatrixView({super.key, required this.user, this.initialDate});

  @override
  State<ComplianceMatrixView> createState() => _ComplianceMatrixViewState();
}

class _ComplianceMatrixViewState extends State<ComplianceMatrixView> {
  final ReportService _reportService = ReportService();

  late String _selectedDate;
  bool _isLoading = true;
  String? _errorMessage;
  ComplianceSummaryModel? _data;
  String _activeFilter =
      'All'; // 'All', 'Pending', 'Submitted', 'Late', 'Returned', 'Not Due'

  final Set<int> _remindingUserIds = {};
  final Set<int> _remindedUserIds = {};

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? _formatDate(DateTime.now());
    _loadComplianceData();
  }

  String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  DateTime _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
    } catch (_) {}
    return DateTime.now();
  }

  bool get _isToday {
    return _selectedDate == _formatDate(DateTime.now());
  }

  bool get _canGoNext {
    final cur = _parseDate(_selectedDate);
    final today = _parseDate(_formatDate(DateTime.now()));
    return cur.isBefore(today);
  }

  void _stepDate(int days) {
    final cur = _parseDate(_selectedDate);
    final next = cur.add(Duration(days: days));
    final today = _parseDate(_formatDate(DateTime.now()));
    if (next.isAfter(today)) return;

    setState(() {
      _selectedDate = _formatDate(next);
    });
    _loadComplianceData();
  }

  Future<void> _pickDate() async {
    final cur = _parseDate(_selectedDate);
    final today = _parseDate(_formatDate(DateTime.now()));
    final picked = await showDatePicker(
      context: context,
      initialDate: cur.isAfter(today) ? today : cur,
      firstDate: DateTime(2024, 1, 1),
      lastDate: today,
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.navyBlue,
              onPrimary: AppTheme.pureWhite,
              surface: AppTheme.pureWhite,
              onSurface: AppTheme.deepSlate,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted = _formatDate(picked);
      if (formatted != _selectedDate) {
        setState(() {
          _selectedDate = formatted;
        });
        _loadComplianceData();
      }
    }
  }

  Future<void> _loadComplianceData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _reportService.getComplianceSummary(_selectedDate);
      if (mounted) {
        setState(() {
          _data = result;
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

  Future<void> _onRemindEmployee(ComplianceEmployeeRow emp) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.pureWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Send Missing Report Reminder',
          style: AppTheme.heading(fontSize: 16, color: AppTheme.deepSlate),
        ),
        content: Text(
          'Send an immediate reminder notification to ${emp.fullName} for $_selectedDate?',
          style: AppTheme.body(fontSize: 13, color: AppTheme.mutedSlate),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: AppTheme.body(
                color: AppTheme.mutedSlate,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warningText,
              foregroundColor: AppTheme.pureWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Send Reminder'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _remindingUserIds.add(emp.id);
    });

    try {
      final res = await _reportService.remindDefaulter(
        userId: emp.id,
        date: _selectedDate,
      );

      if (!mounted) return;
      setState(() {
        _remindingUserIds.remove(emp.id);
        _remindedUserIds.add(emp.id);
      });

      final msg = res['message']?.toString() ?? 'Reminder sent successfully.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppTheme.successText,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _remindingUserIds.remove(emp.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('ApiException', '').trim()),
          backgroundColor: AppTheme.dangerText,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showExemptionBottomSheet(ComplianceEmployeeRow emp) async {
    String startDate = _selectedDate;
    String endDate = _selectedDate;
    String type = 'leave';
    final reasonController = TextEditingController();
    bool isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Record Leave / Exemption',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.heading(
                              fontSize: 16,
                              color: AppTheme.deepSlate,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Employee: ${emp.fullName} (${emp.departmentName ?? 'Staff'})',
                      style: AppTheme.body(
                        fontSize: 13,
                        color: AppTheme.mutedSlate,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Exemption Type Chips
                    Text(
                      'Type',
                      style: AppTheme.heading(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Leave'),
                          selected: type == 'leave',
                          onSelected: (val) {
                            if (val) setModalState(() => type = 'leave');
                          },
                          selectedColor: AppTheme.navyBlue,
                          labelStyle: TextStyle(
                            color: type == 'leave'
                                ? AppTheme.pureWhite
                                : AppTheme.deepSlate,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        ChoiceChip(
                          label: const Text('Reporting Exemption'),
                          selected: type == 'exemption',
                          onSelected: (val) {
                            if (val) setModalState(() => type = 'exemption');
                          },
                          selectedColor: AppTheme.navyBlue,
                          labelStyle: TextStyle(
                            color: type == 'exemption'
                                ? AppTheme.pureWhite
                                : AppTheme.deepSlate,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Dates
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Start Date',
                                style: AppTheme.heading(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () async {
                                  final cur = _parseDate(startDate);
                                  final picked = await showDatePicker(
                                    context: ctx,
                                    initialDate: cur,
                                    firstDate: DateTime(2024, 1, 1),
                                    lastDate: DateTime(2028, 12, 31),
                                  );
                                  if (picked != null) {
                                    setModalState(() {
                                      startDate = _formatDate(picked);
                                      if (_parseDate(
                                        endDate,
                                      ).isBefore(picked)) {
                                        endDate = startDate;
                                      }
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.scaffoldBg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppTheme.borderSubtle,
                                    ),
                                  ),
                                  child: Text(
                                    startDate,
                                    style: AppTheme.mono(
                                      fontSize: 12,
                                      color: AppTheme.deepSlate,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'End Date',
                                style: AppTheme.heading(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () async {
                                  final cur = _parseDate(endDate);
                                  final startDt = _parseDate(startDate);
                                  final picked = await showDatePicker(
                                    context: ctx,
                                    initialDate: cur.isBefore(startDt)
                                        ? startDt
                                        : cur,
                                    firstDate: startDt,
                                    lastDate: DateTime(2028, 12, 31),
                                  );
                                  if (picked != null) {
                                    setModalState(() {
                                      endDate = _formatDate(picked);
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.scaffoldBg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppTheme.borderSubtle,
                                    ),
                                  ),
                                  child: Text(
                                    endDate,
                                    style: AppTheme.mono(
                                      fontSize: 12,
                                      color: AppTheme.deepSlate,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Reason
                    Text(
                      'Reason (Optional)',
                      style: AppTheme.heading(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: reasonController,
                      maxLines: 2,
                      style: AppTheme.body(
                        fontSize: 13,
                        color: AppTheme.deepSlate,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'e.g., Sick leave, Conference, Client visit...',
                        hintStyle: AppTheme.body(
                          fontSize: 13,
                          color: AppTheme.lightSlate,
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                setModalState(() => isSubmitting = true);
                                final messenger = ScaffoldMessenger.of(context);
                                try {
                                  await _reportService.createExemption(
                                    userId: emp.id,
                                    startDate: startDate,
                                    endDate: endDate,
                                    type: type,
                                    reason: reasonController.text.trim(),
                                  );
                                  if (!ctx.mounted) return;
                                  Navigator.pop(ctx);
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Exemption saved for ${emp.fullName}.',
                                      ),
                                      backgroundColor: AppTheme.successText,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  if (mounted) {
                                    _loadComplianceData();
                                  }
                                } catch (e) {
                                  setModalState(() => isSubmitting = false);
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        e
                                            .toString()
                                            .replaceAll('ApiException', '')
                                            .trim(),
                                      ),
                                      backgroundColor: AppTheme.dangerText,
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.navyBlue,
                          foregroundColor: AppTheme.pureWhite,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.pureWhite,
                                ),
                              )
                            : const Text('Record Exemption'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadComplianceData,
      color: AppTheme.royalBlue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Date Navigator Bar
            _buildDateNavigator(),
            const SizedBox(height: 12),

            // 2. Cutoff / Deadline Status Banner
            _buildCutoffBanner(),
            const SizedBox(height: 16),

            // 3. Loading, Error, or Compliance Content
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: CircularProgressIndicator(
                    color: AppTheme.royalBlue,
                    strokeWidth: 2.5,
                  ),
                ),
              )
            else if (_errorMessage != null)
              _buildErrorCard()
            else if (_data != null) ...[
              // 4. 6-KPI Metric Grid
              _buildKpiGrid(_data!),
              const SizedBox(height: 16),

              // 5. 7-Working-Day Trend Bar Chart
              if (_data!.trend.isNotEmpty) ...[
                _buildTrendChart(_data!.trend),
                const SizedBox(height: 16),
              ],

              // 6. Filter Chips Strip for Defaulters & Statuses
              _buildFilterChips(_data!),
              const SizedBox(height: 12),

              // 7. Employee Compliance Roster
              _buildEmployeeRoster(_data!),
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // Section 1: Date Navigator Bar
  // -------------------------------------------------------------
  Widget _buildDateNavigator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Row(
        children: [
          // Prev Day Button
          InkWell(
            onTap: () => _stepDate(-1),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.scaffoldBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chevron_left, size: 16, color: AppTheme.deepSlate),
                  Text(
                    'Prev',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.deepSlate,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Date Picker Chip
          Expanded(
            child: InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 13,
                      color: AppTheme.royalBlue,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        _selectedDate,
                        style: AppTheme.mono(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.deepSlate,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_isToday) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.infoBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Today',
                          style: AppTheme.heading(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.infoText,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Next Day Button
          InkWell(
            onTap: _canGoNext ? () => _stepDate(1) : null,
            borderRadius: BorderRadius.circular(8),
            child: Opacity(
              opacity: _canGoNext ? 1.0 : 0.4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.scaffoldBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Next',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.deepSlate,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: AppTheme.deepSlate,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // Section 2: Cutoff Banner
  // -------------------------------------------------------------
  Widget _buildCutoffBanner() {
    final deadline = _data?.deadlineTime ?? '20:00';
    final passed = _data?.deadlinePassed ?? false;
    final isWorkingDay = _data?.isWorkingDay ?? true;
    final isHoliday = _data?.isHoliday ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: passed ? const Color(0xFFFFFBEB) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: passed ? const Color(0xFFFDE68A) : const Color(0xFFBBF7D0),
        ),
      ),
      child: Row(
        children: [
          Icon(
            passed ? Icons.timer_off_outlined : Icons.timer_outlined,
            size: 16,
            color: passed ? AppTheme.warningText : AppTheme.successText,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cutoff: $deadline (incl. grace)',
                  style: AppTheme.heading(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: passed ? AppTheme.warningText : AppTheme.successText,
                  ),
                ),
                Text(
                  passed
                      ? 'Reporting deadline has passed for this date.'
                      : 'Deadline has not passed yet. Submissions on-time.',
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
          if (!isWorkingDay || isHoliday) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isHoliday ? 'Holiday' : 'Non-working',
                style: AppTheme.heading(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.mutedSlate,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // Section 3: 6-Metric KPI Grid
  // -------------------------------------------------------------
  Widget _buildKpiGrid(ComplianceSummaryModel data) {
    Color pctBg = AppTheme.successBg;
    Color pctFg = AppTheme.successText;
    if (data.percent < 70) {
      pctBg = AppTheme.dangerBg;
      pctFg = AppTheme.dangerText;
    } else if (data.percent < 90) {
      pctBg = AppTheme.warningBg;
      pctFg = AppTheme.warningText;
    }

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final cardWidth = (constraints.maxWidth - 10) / 2;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
              width: cardWidth,
              child: _buildKpiCard(
                value: '${data.percent}%',
                label: 'Compliance Rate',
                subtitle: '${data.compliant} of ${data.required} required',
                valueColor: pctFg,
                bgColor: pctBg,
                isPrimary: true,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildKpiCard(
                value: '${data.required}',
                label: 'Required to Report',
                subtitle: 'Active staff on duty',
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildKpiCard(
                value: '${data.compliant}',
                label: 'Submitted Reports',
                subtitle:
                    '${data.submittedOnTime} on-time · ${data.submittedLate} late',
                valueColor: AppTheme.successText,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildKpiCard(
                value: '${data.pendingCount}',
                label: 'Pending (Missing)',
                subtitle: 'Defaulters who missed cutoff',
                valueColor: data.pendingCount > 0
                    ? AppTheme.dangerText
                    : AppTheme.deepSlate,
                bgColor: data.pendingCount > 0
                    ? const Color(0xFFFEF2F2)
                    : AppTheme.pureWhite,
                onTap: () {
                  setState(() => _activeFilter = 'Pending');
                },
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildKpiCard(
                value: '${data.returnedCount}',
                label: 'Returned / Clarify',
                subtitle: 'Requires staff revision',
                valueColor: data.returnedCount > 0
                    ? AppTheme.warningText
                    : AppTheme.deepSlate,
                onTap: () {
                  setState(() => _activeFilter = 'Returned');
                },
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildKpiCard(
                value: '${data.notDueCount}',
                label: 'Not Due',
                subtitle: 'Exempt / non-working',
                valueColor: AppTheme.mutedSlate,
                onTap: () {
                  setState(() => _activeFilter = 'Not Due');
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String value,
    required String label,
    required String subtitle,
    Color? valueColor,
    Color? bgColor,
    bool isPrimary = false,
    VoidCallback? onTap,
  }) {
    return BrutalistPressable(
      onTap: onTap,
      backgroundColor: bgColor ?? AppTheme.pureWhite,
      borderColor: AppTheme.borderSubtle,
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTheme.mono(
              fontSize: isPrimary ? 24 : 20,
              fontWeight: FontWeight.w800,
              color: valueColor ?? AppTheme.deepSlate,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: AppTheme.heading(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.deepSlate,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTheme.body(fontSize: 10, color: AppTheme.mutedSlate),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // Section 4: 7-Working-Day Trend Bar Chart Strip
  // -------------------------------------------------------------
  Widget _buildTrendChart(List<ComplianceDayTrend> trend) {
    return Container(
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
                  '7-Day Compliance Trend',
                  style: AppTheme.heading(
                    fontSize: 13,
                    color: AppTheme.deepSlate,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Tap day to jump',
                style: AppTheme.body(fontSize: 10, color: AppTheme.mutedSlate),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Bar Strip
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: trend.map((t) {
                final isCurrent = t.date == _selectedDate;
                final pct = t.percent.clamp(0, 100);
                final barHeight = ((pct / 100.0) * 55.0).clamp(4.0, 55.0);

                Color barColor = AppTheme.navyBlue;
                if (isCurrent) {
                  barColor = AppTheme.royalBlue;
                } else if (pct >= 90) {
                  barColor = AppTheme.successText;
                } else if (pct < 70 && t.required > 0) {
                  barColor = AppTheme.dangerText;
                }

                return Expanded(
                  child: InkWell(
                    onTap: () {
                      if (_selectedDate != t.date) {
                        setState(() => _selectedDate = t.date);
                        _loadComplianceData();
                      }
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${t.percent}%',
                            style: AppTheme.mono(
                              fontSize: 9,
                              fontWeight: isCurrent
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isCurrent
                                  ? AppTheme.royalBlue
                                  : AppTheme.deepSlate,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            height: barHeight,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: barColor,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(3),
                              ),
                              border: isCurrent
                                  ? Border.all(
                                      color: AppTheme.deepSlate,
                                      width: 1.2,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            t.dayLabel,
                            style: AppTheme.body(
                              fontSize: 9,
                              fontWeight: isCurrent
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isCurrent
                                  ? AppTheme.deepSlate
                                  : AppTheme.mutedSlate,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // Section 5: Filter Chips Strip
  // -------------------------------------------------------------
  Widget _buildFilterChips(ComplianceSummaryModel data) {
    final filters = [
      'All',
      'Pending',
      'Submitted',
      'Late',
      'Returned',
      'Not Due',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _activeFilter == f;
          int badgeCount = 0;
          if (f == 'All') badgeCount = data.rows.length;
          if (f == 'Pending') badgeCount = data.pendingCount;
          if (f == 'Submitted') badgeCount = data.submittedOnTime;
          if (f == 'Late') badgeCount = data.submittedLate;
          if (f == 'Returned') badgeCount = data.returnedCount;
          if (f == 'Not Due') badgeCount = data.notDueCount;

          final isAlert = f == 'Pending' && data.pendingCount > 0;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                setState(() => _activeFilter = f);
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
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
                child: Row(
                  children: [
                    Text(
                      f == 'Pending' ? 'Pending (Defaulters)' : f,
                      style: AppTheme.heading(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? (isAlert
                                  ? AppTheme.dangerText
                                  : AppTheme.pureWhite)
                            : AppTheme.mutedSlate,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isAlert
                                  ? AppTheme.dangerText
                                  : AppTheme.pureWhite)
                            : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$badgeCount',
                        style: AppTheme.mono(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? (isAlert
                                    ? AppTheme.pureWhite
                                    : AppTheme.navyBlue)
                              : AppTheme.deepSlate,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // -------------------------------------------------------------
  // Section 6: Employee Compliance Roster
  // -------------------------------------------------------------
  Widget _buildEmployeeRoster(ComplianceSummaryModel data) {
    var filtered = data.rows;
    if (_activeFilter == 'Pending') {
      filtered = filtered.where((r) => r.isPending).toList();
    } else if (_activeFilter == 'Submitted') {
      filtered = filtered.where((r) => r.isSubmitted).toList();
    } else if (_activeFilter == 'Late') {
      filtered = filtered.where((r) => r.isLate).toList();
    } else if (_activeFilter == 'Returned') {
      filtered = filtered.where((r) => r.isReturned).toList();
    } else if (_activeFilter == 'Not Due') {
      filtered = filtered.where((r) => r.isNotDue).toList();
    }

    if (filtered.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(28),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 36,
              color: AppTheme.mutedSlate,
            ),
            const SizedBox(height: 10),
            Text(
              'No Employees in $_activeFilter',
              style: AppTheme.heading(fontSize: 14, color: AppTheme.deepSlate),
            ),
            const SizedBox(height: 4),
            Text(
              'No employees match the selected filter for $_selectedDate.',
              style: AppTheme.body(fontSize: 12, color: AppTheme.mutedSlate),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: filtered.map((emp) => _buildEmployeeCard(emp)).toList(),
    );
  }

  Widget _buildEmployeeCard(ComplianceEmployeeRow emp) {
    final isReminding = _remindingUserIds.contains(emp.id);
    final wasReminded = _remindedUserIds.contains(emp.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: emp.isPending
              ? const Color(0xFFFECACA)
              : AppTheme.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Avatar + Name/Dept + Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(emp),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      emp.fullName,
                      style: AppTheme.heading(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.deepSlate,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${emp.departmentName ?? 'General'} · ${emp.employeeCode ?? 'Staff'}',
                      style: AppTheme.body(
                        fontSize: 11,
                        color: AppTheme.mutedSlate,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(emp.status),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: Metadata (Reports filed, active tasks, last submission)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.scaffoldBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Wrap(
              spacing: 10,
              runSpacing: 6,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.assignment_outlined,
                      size: 13,
                      color: AppTheme.mutedSlate,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${emp.reports} report${emp.reports == 1 ? '' : 's'}',
                      style: AppTheme.mono(
                        fontSize: 11,
                        color: AppTheme.deepSlate,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.task_alt_outlined,
                      size: 13,
                      color: AppTheme.mutedSlate,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${emp.pendingTasks} tasks',
                      style: AppTheme.mono(
                        fontSize: 11,
                        color: AppTheme.deepSlate,
                      ),
                    ),
                  ],
                ),
                Text(
                  emp.lastSubmittedAt != null
                      ? 'At ${_formatTime(emp.lastSubmittedAt!)}'
                      : 'No report',
                  style: AppTheme.body(
                    fontSize: 11,
                    color: emp.lastSubmittedAt != null
                        ? AppTheme.mutedSlate
                        : (emp.isPending
                              ? AppTheme.dangerText
                              : AppTheme.mutedSlate),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Row 3: Action Buttons (Remind Defaulter + Exempt)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Exempt Button
              if (emp.required)
                OutlinedButton.icon(
                  onPressed: () => _showExemptionBottomSheet(emp),
                  icon: const Icon(Icons.event_busy_outlined, size: 13),
                  label: const Text('Exempt'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.mutedSlate,
                    side: const BorderSide(color: AppTheme.borderSubtle),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    visualDensity: VisualDensity.compact,
                    textStyle: AppTheme.heading(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(width: 8),

              // Remind Button (for Pending Defaulters)
              if (emp.isPending)
                ElevatedButton.icon(
                  onPressed: isReminding || wasReminded
                      ? null
                      : () => _onRemindEmployee(emp),
                  icon: isReminding
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: AppTheme.pureWhite,
                          ),
                        )
                      : Icon(
                          wasReminded
                              ? Icons.check
                              : Icons.notifications_active_outlined,
                          size: 13,
                        ),
                  label: Text(wasReminded ? 'Reminded' : 'Remind'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: wasReminded
                        ? const Color(0xFF94A3B8)
                        : AppTheme.warningText,
                    foregroundColor: AppTheme.pureWhite,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    visualDensity: VisualDensity.compact,
                    textStyle: AppTheme.heading(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(ComplianceEmployeeRow emp) {
    final photoUrl = ApiClient().resolveMediaUrl(emp.profilePhotoUrl);

    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: AppTheme.scaffoldBg,
        backgroundImage: NetworkImage(photoUrl),
        onBackgroundImageError: (_, _) {},
        child: Text(
          _initials(emp.fullName),
          style: AppTheme.heading(fontSize: 11, color: AppTheme.navyBlue),
        ),
      );
    }

    return CircleAvatar(
      radius: 18,
      backgroundColor: const Color(0xFFE2E8F0),
      child: Text(
        _initials(emp.fullName),
        style: AppTheme.heading(fontSize: 11, color: AppTheme.navyBlue),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }

  String _formatTime(String raw) {
    try {
      final parts = raw.split(' ');
      if (parts.length >= 2) {
        final timeParts = parts[1].split(':');
        if (timeParts.length >= 2) {
          int h = int.parse(timeParts[0]);
          final m = timeParts[1];
          final ampm = h >= 12 ? 'PM' : 'AM';
          if (h > 12) h -= 12;
          if (h == 0) h = 12;
          return '$h:$m $ampm';
        }
      }
    } catch (_) {}
    return raw;
  }

  Widget _buildStatusBadge(String status) {
    Color bg = const Color(0xFFF1F5F9);
    Color fg = AppTheme.mutedSlate;

    if (status == 'submitted') {
      bg = AppTheme.successBg;
      fg = AppTheme.successText;
    } else if (status == 'submitted_late') {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFFD97706);
    } else if (status == 'pending') {
      bg = AppTheme.dangerBg;
      fg = AppTheme.dangerText;
    } else if (status == 'returned') {
      bg = AppTheme.warningBg;
      fg = AppTheme.warningText;
    } else if (status == 'exempt') {
      bg = const Color(0xFFF3E8FF);
      fg = const Color(0xFF7E22CE);
    }

    final formatted = status.replaceAll('_', ' ');
    final label = formatted.isEmpty
        ? 'Pending'
        : formatted[0].toUpperCase() + formatted.substring(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTheme.heading(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.dangerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dangerText.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            'Failed to load compliance data',
            style: AppTheme.heading(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.dangerText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'An unknown error occurred.',
            style: AppTheme.body(fontSize: 12, color: AppTheme.deepSlate),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _loadComplianceData,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.navyBlue,
              foregroundColor: AppTheme.pureWhite,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
