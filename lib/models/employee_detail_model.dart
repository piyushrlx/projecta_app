class EmployeeKpis {
  final int assignedTasks;
  final int completedTasks;
  final int pendingTasks;
  final int overdueTasks;
  final int? complianceRate;
  final int reportsCount30d;

  const EmployeeKpis({
    this.assignedTasks = 0,
    this.completedTasks = 0,
    this.pendingTasks = 0,
    this.overdueTasks = 0,
    this.complianceRate,
    this.reportsCount30d = 0,
  });

  factory EmployeeKpis.fromJson(Map<String, dynamic> json) {
    return EmployeeKpis(
      assignedTasks: (json['assigned_tasks'] ?? 0) as int,
      completedTasks: (json['completed_tasks'] ?? 0) as int,
      pendingTasks: (json['pending_tasks'] ?? 0) as int,
      overdueTasks: (json['overdue_tasks'] ?? 0) as int,
      complianceRate: json['compliance_rate'] != null ? (json['compliance_rate'] as num).toInt() : null,
      reportsCount30d: (json['reports_count_30d'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'assigned_tasks': assignedTasks,
    'completed_tasks': completedTasks,
    'pending_tasks': pendingTasks,
    'overdue_tasks': overdueTasks,
    'compliance_rate': complianceRate,
    'reports_count_30d': reportsCount30d,
  };
}

class EmployeeTaskSummary {
  final int id;
  final String taskCode;
  final String title;
  final String status;
  final String priority;
  final String? deadline;
  final int progress;
  final String? projectName;
  final int? projectId;

  const EmployeeTaskSummary({
    required this.id,
    required this.taskCode,
    required this.title,
    required this.status,
    required this.priority,
    this.deadline,
    this.progress = 0,
    this.projectName,
    this.projectId,
  });

  factory EmployeeTaskSummary.fromJson(Map<String, dynamic> json) {
    return EmployeeTaskSummary(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      taskCode: (json['task_code'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      priority: (json['priority'] ?? 'medium').toString(),
      deadline: json['deadline']?.toString(),
      progress: (json['progress'] ?? 0) as int,
      projectName: json['project_name']?.toString(),
      projectId: json['project_id'] is int ? json['project_id'] as int : null,
    );
  }
}

class EmployeeProjectSummary {
  final int id;
  final String projectCode;
  final String name;
  final String status;
  final String? deadline;
  final String? memberRole;
  final String? managerName;

  const EmployeeProjectSummary({
    required this.id,
    required this.projectCode,
    required this.name,
    required this.status,
    this.deadline,
    this.memberRole,
    this.managerName,
  });

  factory EmployeeProjectSummary.fromJson(Map<String, dynamic> json) {
    return EmployeeProjectSummary(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      projectCode: (json['project_code'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      status: (json['status'] ?? 'active').toString(),
      deadline: json['deadline']?.toString(),
      memberRole: json['member_role']?.toString(),
      managerName: json['manager_name']?.toString(),
    );
  }
}

class EmployeeReportSummary {
  final int id;
  final String reportDate;
  final String workSummary;
  final int minutesSpent;
  final String status;
  final bool isLate;
  final String? submittedAt;
  final String? projectName;
  final String? taskTitle;

  const EmployeeReportSummary({
    required this.id,
    required this.reportDate,
    required this.workSummary,
    this.minutesSpent = 0,
    required this.status,
    this.isLate = false,
    this.submittedAt,
    this.projectName,
    this.taskTitle,
  });

  factory EmployeeReportSummary.fromJson(Map<String, dynamic> json) {
    return EmployeeReportSummary(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      reportDate: (json['report_date'] ?? '').toString(),
      workSummary: (json['work_summary'] ?? '').toString(),
      minutesSpent: (json['minutes_spent'] ?? 0) as int,
      status: (json['status'] ?? 'submitted').toString(),
      isLate: json['is_late'] == true || json['is_late'] == 1 || json['is_late'] == '1',
      submittedAt: json['submitted_at']?.toString(),
      projectName: json['project_name']?.toString(),
      taskTitle: json['task_title']?.toString(),
    );
  }
}

class EmployeeExemptionSummary {
  final int id;
  final String startDate;
  final String endDate;
  final String? reason;
  final String? reasonType;
  final String? approvedByName;

  const EmployeeExemptionSummary({
    required this.id,
    required this.startDate,
    required this.endDate,
    this.reason,
    this.reasonType,
    this.approvedByName,
  });

  factory EmployeeExemptionSummary.fromJson(Map<String, dynamic> json) {
    return EmployeeExemptionSummary(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      startDate: (json['start_date'] ?? '').toString(),
      endDate: (json['end_date'] ?? '').toString(),
      reason: json['reason']?.toString(),
      reasonType: json['reason_type']?.toString(),
      approvedByName: json['approved_by_name']?.toString(),
    );
  }
}

class EmployeeDetailModel {
  final int id;
  final String? employeeCode;
  final String username;
  final String email;
  final String fullName;
  final String? phone;
  final String? designation;
  final int? departmentId;
  final String? departmentName;
  final int? reportingManagerId;
  final String? reportingManagerName;
  final String role;
  final String adminScope;
  final List<int> adminDepartments;
  final String status;
  final String? joiningDate;
  final bool reportingRequired;
  final bool mustChangePassword;
  final List<int> workingDays;
  final String? profilePhotoUrl;
  final String? createdAt;
  final bool canManage;
  final EmployeeKpis kpis;
  final List<EmployeeTaskSummary> tasks;
  final List<EmployeeProjectSummary> projects;
  final List<EmployeeReportSummary> reports;
  final List<EmployeeExemptionSummary> exemptions;

  const EmployeeDetailModel({
    required this.id,
    this.employeeCode,
    required this.username,
    required this.email,
    required this.fullName,
    this.phone,
    this.designation,
    this.departmentId,
    this.departmentName,
    this.reportingManagerId,
    this.reportingManagerName,
    required this.role,
    this.adminScope = 'assigned',
    this.adminDepartments = const [],
    required this.status,
    this.joiningDate,
    this.reportingRequired = true,
    this.mustChangePassword = false,
    this.workingDays = const [1, 2, 3, 4, 5],
    this.profilePhotoUrl,
    this.createdAt,
    this.canManage = false,
    this.kpis = const EmployeeKpis(),
    this.tasks = const [],
    this.projects = const [],
    this.reports = const [],
    this.exemptions = const [],
  });

  bool get isActive => status == 'active';
  bool get isAdmin => role == 'admin' || role == 'super_admin';
  bool get isSuperAdmin => role == 'super_admin';
  bool get isStaff => role == 'staff';

  factory EmployeeDetailModel.fromJson(Map<String, dynamic> json) {
    final rawAdminDepts = json['admin_departments'];
    final List<int> parsedAdminDepts = rawAdminDepts is List
        ? rawAdminDepts.map((d) => (d as num).toInt()).toList()
        : [];

    final rawWorkingDays = json['working_days'];
    final List<int> parsedWorkingDays = rawWorkingDays is List
        ? rawWorkingDays.map((d) => (d as num).toInt()).toList()
        : [1, 2, 3, 4, 5];

    final rawTasks = json['tasks'];
    final List<EmployeeTaskSummary> parsedTasks = rawTasks is List
        ? rawTasks.map((t) => EmployeeTaskSummary.fromJson(t as Map<String, dynamic>)).toList()
        : [];

    final rawProjects = json['projects'];
    final List<EmployeeProjectSummary> parsedProjects = rawProjects is List
        ? rawProjects.map((p) => EmployeeProjectSummary.fromJson(p as Map<String, dynamic>)).toList()
        : [];

    final rawReports = json['reports'];
    final List<EmployeeReportSummary> parsedReports = rawReports is List
        ? rawReports.map((r) => EmployeeReportSummary.fromJson(r as Map<String, dynamic>)).toList()
        : [];

    final rawExemptions = json['exemptions'];
    final List<EmployeeExemptionSummary> parsedExemptions = rawExemptions is List
        ? rawExemptions.map((x) => EmployeeExemptionSummary.fromJson(x as Map<String, dynamic>)).toList()
        : [];

    return EmployeeDetailModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      employeeCode: json['employee_code']?.toString(),
      username: (json['username'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      fullName: (json['full_name'] ?? json['name'] ?? '').toString(),
      phone: json['phone']?.toString(),
      designation: json['designation']?.toString(),
      departmentId: json['department_id'] is int ? json['department_id'] as int : null,
      departmentName: json['department_name']?.toString(),
      reportingManagerId: json['reporting_manager_id'] is int ? json['reporting_manager_id'] as int : null,
      reportingManagerName: json['reporting_manager_name']?.toString(),
      role: (json['role'] ?? 'staff').toString(),
      adminScope: (json['admin_scope'] ?? 'assigned').toString(),
      adminDepartments: parsedAdminDepts,
      status: (json['status'] ?? 'active').toString(),
      joiningDate: json['joining_date']?.toString(),
      reportingRequired: json['reporting_required'] == true || json['reporting_required'] == 1,
      mustChangePassword: json['must_change_password'] == true || json['must_change_password'] == 1,
      workingDays: parsedWorkingDays,
      profilePhotoUrl: json['profile_photo_url']?.toString(),
      createdAt: json['created_at']?.toString(),
      canManage: json['can_manage'] == true || json['can_manage'] == 1,
      kpis: json['kpis'] is Map<String, dynamic>
          ? EmployeeKpis.fromJson(json['kpis'] as Map<String, dynamic>)
          : const EmployeeKpis(),
      tasks: parsedTasks,
      projects: parsedProjects,
      reports: parsedReports,
      exemptions: parsedExemptions,
    );
  }
}

