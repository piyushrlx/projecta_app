class ReportModel {
  final int id;
  final int userId;
  final String reportDate;
  final int projectId;
  final int? taskId;
  final String workSummary;
  final int minutesSpent;
  final int? progressBefore;
  final int? progressAfter;
  final String status; // draft, submitted, approved, rejected, clarification_requested
  final bool isLate;
  final String? submittedAt;
  final int? reviewedBy;
  final String? reviewedAt;
  final String? reviewComment;
  final int revisionNo;
  final String? employeeName;
  final String? profilePhotoUrl;
  final String? projectName;
  final String? projectCode;
  final String? taskTitle;
  final String? taskCode;
  final String? reviewerName;
  final String hoursFormatted;
  final bool canEdit;
  final bool canReview;

  const ReportModel({
    required this.id,
    required this.userId,
    required this.reportDate,
    required this.projectId,
    this.taskId,
    required this.workSummary,
    this.minutesSpent = 0,
    this.progressBefore,
    this.progressAfter,
    required this.status,
    this.isLate = false,
    this.submittedAt,
    this.reviewedBy,
    this.reviewedAt,
    this.reviewComment,
    this.revisionNo = 1,
    this.employeeName,
    this.profilePhotoUrl,
    this.projectName,
    this.projectCode,
    this.taskTitle,
    this.taskCode,
    this.reviewerName,
    this.hoursFormatted = '0m',
    this.canEdit = false,
    this.canReview = false,
  });

  bool get isDraft => status == 'draft';
  bool get isSubmitted => status == 'submitted';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isClarificationRequested => status == 'clarification_requested';
  bool get isReturned => isRejected || isClarificationRequested;

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      reportDate: json['report_date']?.toString() ?? '',
      projectId: (json['project_id'] as num?)?.toInt() ?? 0,
      taskId: (json['task_id'] as num?)?.toInt(),
      workSummary: json['work_summary']?.toString() ?? '',
      minutesSpent: (json['minutes_spent'] as num?)?.toInt() ?? 0,
      progressBefore: (json['progress_before'] as num?)?.toInt(),
      progressAfter: (json['progress_after'] as num?)?.toInt(),
      status: json['status']?.toString() ?? 'submitted',
      isLate: json['is_late'] == true || json['is_late'] == 1,
      submittedAt: json['submitted_at']?.toString(),
      reviewedBy: (json['reviewed_by'] as num?)?.toInt(),
      reviewedAt: json['reviewed_at']?.toString(),
      reviewComment: json['review_comment']?.toString(),
      revisionNo: (json['revision_no'] as num?)?.toInt() ?? 1,
      employeeName: json['employee_name']?.toString(),
      profilePhotoUrl: json['profile_photo_url']?.toString(),
      projectName: json['project_name']?.toString(),
      projectCode: json['project_code']?.toString(),
      taskTitle: json['task_title']?.toString(),
      taskCode: json['task_code']?.toString(),
      reviewerName: json['reviewer_name']?.toString(),
      hoursFormatted: json['hours_formatted']?.toString() ??
          '${((json['minutes_spent'] as num?)?.toInt() ?? 0) ~/ 60}h ${((json['minutes_spent'] as num?)?.toInt() ?? 0) % 60}m',
      canEdit: json['can_edit'] == true || json['can_edit'] == 1,
      canReview: json['can_review'] == true || json['can_review'] == 1,
    );
  }
}

class TodayReportContextModel {
  final String today;
  final String complianceStatus;
  final String complianceLabel;
  final String? reportDeadlineTime;
  final int graceMinutes;
  final String? minReportDate;
  final bool isCurrentlyLate;
  final List<Map<String, dynamic>> projects;
  final List<Map<String, dynamic>> tasks;
  final List<ReportModel> todayReports;

  const TodayReportContextModel({
    required this.today,
    required this.complianceStatus,
    required this.complianceLabel,
    this.reportDeadlineTime,
    this.graceMinutes = 60,
    this.minReportDate,
    this.isCurrentlyLate = false,
    this.projects = const [],
    this.tasks = const [],
    this.todayReports = const [],
  });

  factory TodayReportContextModel.fromJson(Map<String, dynamic> json) {
    final rawProjects = (json['projects'] as List<dynamic>?) ?? [];
    final rawTasks = (json['tasks'] as List<dynamic>?) ?? [];
    final rawReports = (json['today_reports'] as List<dynamic>?) ?? [];

    return TodayReportContextModel(
      today: json['today']?.toString() ?? '',
      complianceStatus: json['compliance_status']?.toString() ?? 'pending',
      complianceLabel: json['compliance_label']?.toString() ?? 'Pending',
      reportDeadlineTime: json['report_deadline_time']?.toString(),
      graceMinutes: (json['grace_minutes'] as num?)?.toInt() ?? 60,
      minReportDate: json['min_report_date']?.toString(),
      isCurrentlyLate: json['is_currently_late'] == true || json['is_currently_late'] == 1,
      projects: rawProjects.cast<Map<String, dynamic>>(),
      tasks: rawTasks.cast<Map<String, dynamic>>(),
      todayReports: rawReports
          .map((r) => ReportModel.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ComplianceEmployeeRow {
  final int id;
  final String fullName;
  final String? employeeCode;
  final String? email;
  final String? phone;
  final int? departmentId;
  final String? departmentName;
  final String? designation;
  final String? profilePhoto;
  final String? profilePhotoUrl;
  final String status; // 'submitted', 'submitted_late', 'pending', 'returned', 'not_due', 'exempt'
  final int reports;
  final String? lastSubmittedAt;
  final int pendingTasks;
  final bool required;
  final int returned;

  const ComplianceEmployeeRow({
    required this.id,
    required this.fullName,
    this.employeeCode,
    this.email,
    this.phone,
    this.departmentId,
    this.departmentName,
    this.designation,
    this.profilePhoto,
    this.profilePhotoUrl,
    required this.status,
    this.reports = 0,
    this.lastSubmittedAt,
    this.pendingTasks = 0,
    this.required = true,
    this.returned = 0,
  });

  bool get isSubmitted => status == 'submitted';
  bool get isLate => status == 'submitted_late';
  bool get isPending => status == 'pending';
  bool get isReturned => status == 'returned';
  bool get isNotDue => status == 'not_due';
  bool get isExempt => status == 'exempt';

  String get statusLabel {
    switch (status) {
      case 'submitted':
        return 'Submitted';
      case 'submitted_late':
        return 'Submitted Late';
      case 'pending':
        return 'Pending';
      case 'returned':
        return 'Returned';
      case 'not_due':
        return 'Not Due';
      case 'exempt':
        return 'Exempt';
      default:
        return status.replaceAll('_', ' ');
    }
  }

  factory ComplianceEmployeeRow.fromJson(Map<String, dynamic> json) {
    return ComplianceEmployeeRow(
      id: (json['id'] as num?)?.toInt() ?? 0,
      fullName: json['full_name']?.toString() ?? 'Unnamed Employee',
      employeeCode: json['employee_code']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      departmentId: (json['department_id'] as num?)?.toInt(),
      departmentName: json['department_name']?.toString(),
      designation: json['designation']?.toString(),
      profilePhoto: json['profile_photo']?.toString(),
      profilePhotoUrl: json['profile_photo_url']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      reports: (json['reports'] as num?)?.toInt() ?? 0,
      lastSubmittedAt: json['last_submitted_at']?.toString(),
      pendingTasks: (json['pending_tasks'] as num?)?.toInt() ?? 0,
      required: json['required'] == true || json['required'] == 1,
      returned: (json['returned'] as num?)?.toInt() ?? 0,
    );
  }
}

class ComplianceDayTrend {
  final String date;
  final int percent;
  final int required;
  final int compliant;

  const ComplianceDayTrend({
    required this.date,
    required this.percent,
    this.required = 0,
    this.compliant = 0,
  });

  String get dayLabel {
    try {
      final parts = date.split('-');
      if (parts.length == 3) {
        final dt = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final dayName = days[dt.weekday - 1];
        return '$dayName ${parts[2]}';
      }
    } catch (_) {}
    return date;
  }

  factory ComplianceDayTrend.fromJson(Map<String, dynamic> json) {
    return ComplianceDayTrend(
      date: json['date']?.toString() ?? '',
      percent: (json['percent'] as num?)?.toInt() ?? 0,
      required: (json['required'] as num?)?.toInt() ?? 0,
      compliant: (json['compliant'] as num?)?.toInt() ?? 0,
    );
  }
}

class ComplianceSummaryModel {
  final String date;
  final String? deadlineTime;
  final bool deadlinePassed;
  final bool isWorkingDay;
  final bool isHoliday;
  final int percent;
  final int required;
  final int compliant;
  final int submittedOnTime;
  final int submittedLate;
  final int pendingCount;
  final int returnedCount;
  final int notDueCount;
  final List<ComplianceEmployeeRow> rows;
  final List<ComplianceDayTrend> trend;

  const ComplianceSummaryModel({
    required this.date,
    this.deadlineTime,
    this.deadlinePassed = false,
    this.isWorkingDay = true,
    this.isHoliday = false,
    required this.percent,
    required this.required,
    required this.compliant,
    this.submittedOnTime = 0,
    this.submittedLate = 0,
    this.pendingCount = 0,
    this.returnedCount = 0,
    this.notDueCount = 0,
    this.rows = const [],
    this.trend = const [],
  });

  factory ComplianceSummaryModel.fromJson(Map<String, dynamic> json) {
    final date = json['date']?.toString() ?? '';
    final deadlineTime = json['deadline_time']?.toString();
    final deadlinePassed = json['deadline_passed'] == true;
    final isWorkingDay = json['is_working_day'] != false;
    final isHoliday = json['is_holiday'] == true;

    final summary = (json['summary'] is Map<String, dynamic>)
        ? json['summary'] as Map<String, dynamic>
        : json;

    final rawRows = (summary['rows'] as List<dynamic>?) ?? [];
    final rows = rawRows
        .map((r) => ComplianceEmployeeRow.fromJson(r as Map<String, dynamic>))
        .toList();

    final rawTrend = (json['trend_7_days'] as List<dynamic>?) ?? [];
    final trend = rawTrend
        .map((t) => ComplianceDayTrend.fromJson(t as Map<String, dynamic>))
        .toList();

    final kpis = summary['kpis'] as Map<String, dynamic>?;

    int percent = (kpis?['percent'] ?? summary['percent'] as num?)?.toInt() ?? 0;
    int required = (kpis?['required'] ?? summary['required'] as num?)?.toInt() ?? 0;
    int compliant = (kpis?['compliant'] ?? summary['compliant'] as num?)?.toInt() ?? 0;
    int submittedOnTime = (kpis?['submitted_on_time'] as num?)?.toInt() ?? 0;
    int submittedLate = (kpis?['submitted_late'] as num?)?.toInt() ?? 0;
    int pendingCount = (kpis?['pending'] as num?)?.toInt() ?? 0;
    int returnedCount = (kpis?['returned'] as num?)?.toInt() ?? 0;
    int notDueCount = (kpis?['not_due'] as num?)?.toInt() ?? 0;

    // Fallback: If kpis block wasn't present, calculate totals from rows
    if (kpis == null && rows.isNotEmpty) {
      submittedOnTime = 0;
      submittedLate = 0;
      pendingCount = 0;
      returnedCount = 0;
      notDueCount = 0;

      for (final r in rows) {
        if (r.isSubmitted) submittedOnTime++;
        if (r.isLate) submittedLate++;
        if (r.isPending) pendingCount++;
        if (r.isReturned) returnedCount++;
        if (r.isNotDue) notDueCount++;
      }
      compliant = submittedOnTime + submittedLate;
    }

    return ComplianceSummaryModel(
      date: date,
      deadlineTime: deadlineTime,
      deadlinePassed: deadlinePassed,
      isWorkingDay: isWorkingDay,
      isHoliday: isHoliday,
      percent: percent,
      required: required,
      compliant: compliant,
      submittedOnTime: submittedOnTime,
      submittedLate: submittedLate,
      pendingCount: pendingCount,
      returnedCount: returnedCount,
      notDueCount: notDueCount,
      rows: rows,
      trend: trend,
    );
  }
}

