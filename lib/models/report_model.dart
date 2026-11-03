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

